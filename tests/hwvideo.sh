#!/bin/sh
# Hardware video decoding in Helium: GPU detection (single, hybrid, NVIDIA),
# the verification gate (vainfo profiles, Vulkan device, device-select layer),
# the flags file and the generated launcher. Offline: sysfs, /dev/dri, vainfo,
# vulkaninfo and the package database are fixtures; nothing is installed.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state NIRUX_LIBRARY=1
export NIRUX_SYSFS_DRM=$TEST/sys/class/drm NIRUX_SYSFS_PCI=$TEST/sys/bus/pci/devices NIRUX_DEV_DRI=$TEST/dev/dri
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT" "$TEST/bin" "$TEST/work" "$NIRUX_DEV_DRI" "$NIRUX_SYSFS_DRM" "$NIRUX_SYSFS_PCI"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
WORK=$TEST/work
OS=debian
NIRUX_AUTO=0
packages=1

# A GPU: PCI address, vendor, device, kernel driver, render node, boot_vga,
# connector status (or none).
gpu() {
  pci=$1; dev=$TEST/sys/devices/pci0000:00/$pci
  mkdir -p "$dev/drm/$5" "$TEST/sys/bus/pci/drivers/$4"
  printf '%s\n' "$2" > "$dev/vendor"; printf '%s\n' "$3" > "$dev/device"
  [ "$6" = - ] || printf '%s\n' "$6" > "$dev/boot_vga"
  ln -sfn "$TEST/sys/bus/pci/drivers/$4" "$dev/driver"
  ln -sfn "$dev" "$NIRUX_SYSFS_PCI/$pci"
  card=card$CARDS; CARDS=$((CARDS + 1))
  mkdir -p "$NIRUX_SYSFS_DRM/$card"
  ln -sfn "$dev" "$NIRUX_SYSFS_DRM/$card/device"
  if [ "$7" != none ]; then
    mkdir -p "$NIRUX_SYSFS_DRM/$card-DP-1"; printf '%s\n' "$7" > "$NIRUX_SYSFS_DRM/$card-DP-1/status"
  fi
  : > "$NIRUX_DEV_DRI/$5"
}
CARDS=0
reset_gpus() {
  CARDS=0
  rm -rf "$TEST/sys" "$NIRUX_DEV_DRI"
  mkdir -p "$NIRUX_SYSFS_DRM" "$NIRUX_SYSFS_PCI" "$NIRUX_DEV_DRI"
}
# vainfo prints the profiles in $TEST/vainfo-<node>; vulkaninfo the devices
# in $TEST/vulkan.
cat > "$TEST/bin/vainfo" <<EOF
#!/bin/sh
node=\$(basename "\$4")
[ -f "$TEST/vainfo-\$node" ] || { echo 'vaInitialize failed' >&2; exit 1; }
cat "$TEST/vainfo-\$node"
EOF
cat > "$TEST/bin/vulkaninfo" <<EOF
#!/bin/sh
cat "$TEST/vulkan" 2>/dev/null
EOF
chmod +x "$TEST/bin/vainfo" "$TEST/bin/vulkaninfo"
PATH=$TEST/bin:$PATH
amd_profiles() {
  cat > "$TEST/vainfo-$1" <<'EOF'
vainfo: Driver version: Mesa Gallium driver 25.0.7 for AMD Radeon 890M (radeonsi)
vainfo: Supported profile and entrypoints
      VAProfileH264High               :	VAEntrypointVLD
      VAProfileH264High               :	VAEntrypointEncSlice
      VAProfileHEVCMain               :	VAEntrypointVLD
      VAProfileVP9Profile0            :	VAEntrypointVLD
      VAProfileAV1Profile0            :	VAEntrypointVLD
      VAProfileNone                   :	VAEntrypointVideoProc
EOF
}
vulkan_devices() {
  : > "$TEST/vulkan"
  for vd in "$@"; do
    printf 'GPU:\n\tvendorID           = %s\n\tdeviceID           = %s\n' "${vd%:*}" "${vd#*:}" >> "$TEST/vulkan"
  done
}
# Every hardware video package is installed unless listed in $TEST/absent.
: > "$TEST/absent"
present() { ! grep -qxF -- "$1" "$TEST/absent"; }
NIRUX_PACKAGE_QUERY=present
install_packages() { say "would install: $1" >> "$TEST/installed"; }

# A managed Helium whose executable prints its arguments and environment.
mkdir -p "$STATE/browsers/helium-1/" "$BIN"
cat > "$STATE/browsers/helium-1/helium" <<'EOF'
#!/bin/sh
for a in "$@"; do printf 'arg %s\n' "$a"; done
printf 'env %s\n' "${MESA_VK_DEVICE_SELECT:-}"
EOF
chmod +x "$STATE/browsers/helium-1/helium"
ln -sfn "$STATE/browsers/helium-1" "$STATE/browser-current"
# An old release linked the executable; that link counts as managed.
ln -sfn "$STATE/browser-current/helium" "$BIN/helium"
browser_managed || fail 'the legacy Helium link is not recognised as managed'
browser_write_launcher
[ -f "$BIN/helium" ] && [ ! -L "$BIN/helium" ] || fail 'the launcher did not replace the legacy link'
browser_managed || fail 'the generated launcher is not recognised as managed'
browser_write_launcher
"$BIN/helium" --version | grep -qx 'arg --version' || fail 'the launcher without flags changed the arguments'

# 1. One AMD GPU (niruxwork-like): verified, flags written, launcher uses them.
gpu 0000:c4:00.0 0x1002 0x150e amdgpu renderD128 - connected
amd_profiles renderD128
vulkan_devices 0x1002:0x150e
hwvideo_apply > "$TEST/out" 2>&1 || fail 'hwvideo_apply failed'
grep -q 'Hardware video in Helium: on (AMD amdgpu, H264 HEVC VP9 AV1' "$TEST/out" || { cat "$TEST/out"; fail 'AMD was not turned on'; }
grep -qx 'gpu 0000:c4:00.0' "$STATE/helium-flags" || fail 'the flags do not name the GPU'
grep -qx 'arg --use-angle=vulkan' "$STATE/helium-flags" || fail 'the Vulkan ANGLE flag is missing'
grep -qx 'arg --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks' "$STATE/helium-flags" ||
  fail 'the feature list is wrong'
! grep -q 'MESA_VK_DEVICE_SELECT\|VaapiOnNvidiaGPUs\|disable-gpu-sandbox\|no-sandbox\|AcceleratedVideoEncoder' "$STATE/helium-flags" ||
  fail 'a single AMD GPU got a flag it must not have'
"$BIN/helium" https://example.org > "$TEST/run"
[ "$(sed -n 1p "$TEST/run")" = 'arg --use-angle=vulkan' ] || fail 'the flags do not come first'
grep -qx 'arg --render-node-override=/dev/dri/renderD128' "$TEST/run" || fail 'the render node was not resolved at start'
[ "$(grep '^arg' "$TEST/run" | tail -n 1)" = 'arg https://example.org' ] || fail "the user's argument is not last"
grep -qx 'env ' "$TEST/run" || fail 'a single GPU must not pin a Vulkan device'
before=$(sha256sum "$STATE/helium-flags")
hwvideo_apply > /dev/null 2>&1
[ "$(sha256sum "$STATE/helium-flags")" = "$before" ] || fail 'a second apply changed the flags'
# The GPU the flags were made for is gone (an unplugged eGPU): plain start.
mv "$NIRUX_SYSFS_PCI/0000:c4:00.0" "$TEST/gone"
"$BIN/helium" x > "$TEST/run"
[ "$(grep -c '^arg' "$TEST/run")" = 1 ] || fail 'flags for a missing GPU were used'
mv "$TEST/gone" "$NIRUX_SYSFS_PCI/0000:c4:00.0"
hwvideo_doctor > "$TEST/doctor"
grep -q '^hardware video: GPU AMD 0x150e (amdgpu, 0000:c4:00.0, /dev/dri/renderD128), setting auto$' "$TEST/doctor" || { cat "$TEST/doctor"; fail 'doctor GPU line'; }
grep -q '^hardware video: VA-API ok, decodes H264 HEVC VP9 AV1; Vulkan sees the GPU$' "$TEST/doctor" || fail 'doctor VA-API line'
grep -q '^hardware video: Helium flags enabled (--use-angle=vulkan --enable-features=' "$TEST/doctor" || fail 'doctor flags line'

# 2. Turned off in browser.toml: the flags go away.
mkdir -p "$NIRUX_CONFIG"
printf '[browser]\nhardware_video = "off"\n' > "$NIRUX_CONFIG/browser.toml"
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'hardware_video = "off" kept the flags'
grep -q 'off (turned off' "$TEST/out" || fail 'off was not reported'
printf '[browser]\nhardware_video = "sometimes"\n' > "$NIRUX_CONFIG/browser.toml"
[ "$(hwvideo_mode 2>/dev/null)" = auto ] || fail 'an invalid value is not treated as auto'
rm -f "$NIRUX_CONFIG/browser.toml"

# 3. The gate: no decode profiles, no Vulkan device, missing packages.
printf 'vainfo: Driver version: Mesa Gallium driver\n      VAProfileNone : VAEntrypointVideoProc\n' > "$TEST/vainfo-renderD128"
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'a driver without decode profiles was enabled'
grep -q 'reports no H264/VP9/AV1/HEVC decoding' "$TEST/out" || fail 'missing profiles were not explained'
amd_profiles renderD128
vulkan_devices 0x10005:0x0000
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'a GPU without a Vulkan driver was enabled'
grep -q 'Vulkan has no driver for this AMD GPU' "$TEST/out" || fail 'the missing Vulkan driver was not explained'
vulkan_devices 0x1002:0x150e
printf 'vainfo\nmesa-va-drivers\n' > "$TEST/absent"
# doctor outside an install has no $OS yet (niruxwork, 0.12.270 + this branch).
(unset OS; distro() { say debian; }; hwvideo_doctor) > "$TEST/doctor" 2>&1
grep -qx 'hardware video: missing packages: vainfo mesa-va-drivers' "$TEST/doctor" || { cat "$TEST/doctor"; fail 'doctor without $OS lost the missing packages'; }
: > "$TEST/installed"
hwvideo_apply > /dev/null 2>&1
grep -qx 'would install: vainfo mesa-va-drivers' "$TEST/installed" || fail 'missing packages were not installed'
NIRUX_AUTO=1
WANTED_PACKAGES=$STATE/wanted-packages
# The nightly run never turns the flags on for the first time.
rm -f "$STATE/helium-flags" "$WANTED_PACKAGES"
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'the nightly update turned the flags on by itself'
[ ! -s "$WANTED_PACKAGES" ] || fail 'the nightly update asked for packages before the flags were on'
grep -q 'available, not on yet' "$TEST/out" || fail 'the nightly update did not say how to turn it on'
# Once on (here: an earlier manual run), the nightly run keeps it current.
printf '# on\n' > "$STATE/helium-flags"
hwvideo_apply > /dev/null 2>&1
grep -qx vainfo "$WANTED_PACKAGES" && grep -qx mesa-va-drivers "$WANTED_PACKAGES" ||
  fail 'the nightly update did not ask for the packages'
NIRUX_AUTO=0
packages=0
: > "$TEST/installed"
hwvideo_apply > "$TEST/out" 2>&1
[ ! -s "$TEST/installed" ] || fail '--no-packages installed packages'
grep -q 'not installed (--no-packages): vainfo mesa-va-drivers' "$TEST/out" || fail '--no-packages was not reported'
packages=1
: > "$TEST/absent"

# 4. Hybrid desktop (othala-like): an idle Intel iGPU and the AMD card that
# drives the display. AMD is chosen and Vulkan is pinned to it.
reset_gpus
gpu 0000:00:02.0 0x8086 0x9be6 i915 renderD128 - disconnected
gpu 0000:03:00.0 0x1002 0x73FF amdgpu renderD129 1 connected
amd_profiles renderD129
vulkan_devices 0x1002:0x73ff 0x8086:0x9be6
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'several GPUs were enabled without the device-select layer'
grep -q 'no Mesa device-select layer' "$TEST/out" || fail 'the missing layer was not explained'
mkdir -p "$NIRUX_SYSTEM_ROOT/usr/share/vulkan/implicit_layer.d"
: > "$NIRUX_SYSTEM_ROOT/usr/share/vulkan/implicit_layer.d/VkLayer_MESA_device_select.json"
hwvideo_apply > /dev/null 2>&1
grep -qx 'gpu 0000:03:00.0' "$STATE/helium-flags" || fail 'the display GPU was not chosen'
grep -qx 'env MESA_VK_DEVICE_SELECT=1002:73ff!' "$STATE/helium-flags" || fail 'Vulkan is not pinned to the chosen GPU'
"$BIN/helium" > "$TEST/run"
grep -qx 'arg --render-node-override=/dev/dri/renderD129' "$TEST/run" || fail 'VA-API is not pinned to the chosen GPU'
grep -qx 'env 1002:73ff!' "$TEST/run" || fail 'the launcher did not export the Vulkan device'
hwvideo_doctor | grep -q ', 1 of 2 GPUs), setting auto$' || fail 'doctor does not say which of two GPUs'

# 5. Intel laptop: the iGPU drives the panel, an NVIDIA dGPU is idle.
reset_gpus
gpu 0000:00:02.0 0x8086 0x46a6 xe renderD128 1 connected
gpu 0000:01:00.0 0x10de 0x25a0 nvidia renderD129 - none
cp "$TEST/vainfo-renderD129" "$TEST/vainfo-renderD128"
vulkan_devices 0x10de:0x25a0 0x8086:0x46a6
hwvideo_apply > /dev/null 2>&1
grep -qx 'gpu 0000:00:02.0' "$STATE/helium-flags" || fail 'the Intel iGPU was not chosen over NVIDIA'

# 6. NVIDIA alone: off by default, opt-in with "on".
reset_gpus
gpu 0000:01:00.0 0x10de 0x2484 nvidia renderD128 1 connected
cp "$TEST/vainfo-renderD129" "$TEST/vainfo-renderD128" 2>/dev/null || amd_profiles renderD128
vulkan_devices 0x10de:0x2484
hwvideo_apply > "$TEST/out" 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'NVIDIA was enabled by default'
grep -q 'NVIDIA is off by default' "$TEST/out" || fail 'the NVIDIA default was not explained'
printf '[browser]\nhardware_video = "on"\n' > "$NIRUX_CONFIG/browser.toml"
hwvideo_apply > /dev/null 2>&1
grep -qx 'arg --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs' "$STATE/helium-flags" ||
  fail 'the NVIDIA opt-in flags are wrong'
grep -qx 'env LIBVA_DRIVER_NAME=nvidia' "$STATE/helium-flags" || fail 'the NVIDIA VA-API driver is not selected'
rm -f "$NIRUX_CONFIG/browser.toml"
reset_gpus
gpu 0000:01:00.0 0x10de 0x1c82 nouveau renderD128 1 connected
printf '[browser]\nhardware_video = "on"\n' > "$NIRUX_CONFIG/browser.toml"
hwvideo_apply > /dev/null 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'nouveau was enabled'
rm -f "$NIRUX_CONFIG/browser.toml"

# 7. No GPU, a virtual GPU, an unmanaged Helium, removal.
reset_gpus
hwvideo_apply | grep -q 'off (no GPU with a render node)' || fail 'no GPU was not reported'
gpu 0000:00:01.0 0x1af4 0x1050 virtio-pci renderD128 1 connected
hwvideo_apply | grep -q 'off (no supported GPU' || fail 'a virtual GPU was not refused'
reset_gpus
gpu 0000:c4:00.0 0x1002 0x150e amdgpu renderD128 - connected
amd_profiles renderD128
vulkan_devices 0x1002:0x150e
hwvideo_apply > /dev/null 2>&1
[ -s "$STATE/helium-flags" ] || fail 'flags missing before the removal test'
rm -f "$BIN/helium"; printf '#!/bin/sh\n' > "$BIN/helium"; chmod +x "$BIN/helium"
hwvideo_apply > /dev/null 2>&1
[ ! -e "$STATE/helium-flags" ] || fail 'an unmanaged Helium kept NIRUX flags'
hwvideo_doctor | grep -q 'Helium is not managed by NIRUX' || fail 'doctor does not mention the unmanaged Helium'
rm -f "$BIN/helium"
browser_write_launcher
hwvideo_apply > /dev/null 2>&1
browser_remove_managed
[ ! -e "$BIN/helium" ] && [ ! -e "$STATE/helium-flags" ] || fail 'removing Helium left the launcher or its flags'

# 8. The nightly update may install the hardware video packages.
for os in debian arch void; do
  list=$(autoupdate_package_list "$os")
  # shellcheck disable=SC2046 # fixed package names, one per word
  for pkg in $(hwvideo_packages_for "$os" all); do
    printf '%s\n' "$list" | grep -qxF -- "$pkg" || fail "$pkg is not in the $os nightly allowlist"
  done
done
[ "$(hwvideo_packages_for arch amd | tr '\n' ' ')" = 'libva-utils vulkan-tools vulkan-mesa-implicit-layers mesa vulkan-radeon ' ] ||
  fail 'the Arch AMD packages changed'
[ "$(hwvideo_packages_for void intel | tr '\n' ' ')" = 'libva-utils Vulkan-Tools mesa-vulkan-overlay-layer intel-media-driver mesa-vulkan-intel ' ] ||
  fail 'the Void Intel packages changed'
say 'hardware video tests passed'
