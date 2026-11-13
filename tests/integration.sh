#!/bin/sh
# Offline regression tests. No real packages, sudo or system files are changed.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1 NIRUX_TEST_AS_ROOT=1
# Offline tests must not fetch the optional wallpaper release assets. An
# explicit choice still overrides this when a test exercises it.
export NIRUX_WALLPAPERS=default
# Apps keep their pins; the upstream lookup is tested with its own fixture.
export NIRUX_APPS=pinned
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT/etc/pam.d" "$NIRUX_SYSTEM_ROOT/usr/share/xsessions"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
wm_version=$(awk '$1 == "niruwm" {print $2}' "$SOURCE/manifest")
bar_version=$(awk '$1 == "nirubar" {print $2}' "$SOURCE/manifest")
saver_version=$(awk '$1 == "niruscreensaver" {print $2}' "$SOURCE/manifest")
lock_version=$(awk '$1 == "nirulock" {print $2}' "$SOURCE/manifest")
launcher_version=$(awk '$1 == "nirulauncher" {print $2}' "$SOURCE/manifest")
notifier_version=$(awk '$1 == "nirunotify" {print $2}' "$SOURCE/manifest")
shot_version=$(awk '$1 == "nirushot" {print $2}' "$SOURCE/manifest")
clip_version=$(awk '$1 == "niruclip" {print $2}' "$SOURCE/manifest")
fetch_version=$(awk '$1 == "nirufetch" {print $2}' "$SOURCE/manifest")
webapp_version=$(awk '$1 == "niruwebapp" {print $2}' "$SOURCE/manifest")
wallpaper_app_version=$(awk '$1 == "niruwallpaper" {print $2}' "$SOURCE/manifest")
display_app_version=$(awk '$1 == "nirudisplay" {print $2}' "$SOURCE/manifest")
theme_selector_version=$(awk '$1 == "niruthemeselector" {print $2}' "$SOURCE/manifest")
login_version=$(awk '$1 == "nirulogin" {print $2}' "$SOURCE/manifest")
share_version=$(awk '$1 == "nirushare" {print $2}' "$SOURCE/manifest")
FIXTURE=$TEST/releases
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
no_config_candidates() {
  for leftover in "$1"/.*.nirux.*; do
    [ ! -e "$leftover" ] || return 1
  done
}
fetch() {
  case "$1" in
    https://github.com/nirucon/*/releases/download/v*)
      relative=${1#https://github.com/nirucon/}
      repo=${relative%%/*}
      relative=${relative#*/releases/download/v}
      relative=${relative%%\?*}
      cp "$FIXTURE/$repo/$relative" "$2" ;;
    *) fail "unexpected fetch: $1" ;;
  esac
}
platform() { :; }
distro() { say "$TEST_OS"; }
export NIRUX_TEST_TOUCHPAD=1 NIRUX_TEST_UDEV_REPLAY=1 NIRUX_TEST_BATTERY=1
as_root() { "$@"; }
operation() { ( "$@" ); }

make_binary() {
  { say '#!/bin/sh'; say "printf '%s\\n' '$2 $3'"; } > "$1"
  chmod +x "$1"
}
fixture() {
  repo=$1; ver=$2; shift 2
  mkdir -p "$FIXTURE/$repo/$ver"
  for asset in "$@"; do make_binary "$FIXTURE/$repo/$ver/$asset" "$asset" "$ver"; done
}
checksums() { (cd "$1"; sha256sum ./* | sed 's@  ./@  @' > SHA256SUMS); }
# The desktop entry and icon are release assets like any other. The tests build
# a placeholder so they never depend on a checkout of another repository.
wallpaper_app_assets() {
  printf '[Desktop Entry]\nType=Application\nName=NIRU Wallpaper\nExec=niruwallpaper\n' > "$1/niruwallpaper.desktop"
  printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$1/niruwallpaper.png"
}
display_app_assets() {
  printf '[Desktop Entry]\nType=Application\nName=NIRU Display\nExec=nirudisplay\n' > "$1/nirudisplay.desktop"
  printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$1/nirudisplay.png"
}
theme_selector_assets() {
  printf '[Desktop Entry]\nType=Application\nName=NIRU Theme Selector\nExec=niruthemeselector\n' > "$1/niruthemeselector.desktop"
  printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$1/niruthemeselector.png"
}
wallpaper_archive() {
  build=$TEST/wallpaper-build
  mkdir -p "$build/wallpaper"
  printf '\211PNG\r\n\032\n' > "$build/wallpaper/nirux-wallpaper-noir-4k.png"
  printf '\211PNG\r\n\032\n' > "$build/wallpaper/nirux-wallpaper-nord-4k.png"
  tar -cJf "$1" -C "$build" wallpaper
}
terminal_archive() {
  ( cd "$SOURCE" && tar -cJf "$1" terminal )
}
integration_archive() {
  build=$TEST/integration-build
  rm -rf "$build"
  mkdir -p "$build/polkit"
  cp -R "$SOURCE/greeters/." "$build/"
  cp "$SOURCE/polkit/49-nirux-power.rules" "$build/polkit/"
  cp "$SOURCE/polkit/nirux-wifi" "$build/polkit/"
  mkdir -p "$build/checkup"
  cp "$SOURCE/checkup/nirux-checkup" "$SOURCE/checkup/nirux-autoupdate" "$SOURCE/checkup/nirux-sleep" "$build/checkup/"
  cp "$SOURCE/wallpaper/nirux-wallpaper-noir-4k.png" "$build/background.png"
  tar -cJf "$1" -C "$build" .
}
# The target installer runs in a separate process. Give it the same offline
# release fixture through a curl shim; the parent test shell keeps its fetch().
mkdir -p "$TEST/bin"
cat > "$TEST/bin/curl" <<'EOF'
#!/bin/sh
out=; url=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
[ -n "$out" ] && [ -n "$url" ] || exit 22
case "$url" in
  https://github.com/nirucon/*/releases/download/v*)
    relative=${url#https://github.com/nirucon/}
    repo=${relative%%/*}
    relative=${relative#*/releases/download/v}
    relative=${relative%%\?*}
    cp "$FIXTURE/$repo/$relative" "$out" ;;
  *) exit 22 ;;
esac
EOF
chmod +x "$TEST/bin/curl"
export FIXTURE
export PATH="$TEST/bin:$PATH"
fixture niruwm "$wm_version" niruwm niructl niruidle niruwm-session niruclipboard nirugestured
# Executing the session script during status must be caught.
say 'touch "$HOME/session-was-started"' >> "$FIXTURE/niruwm/$wm_version/niruwm-session"
fixture nirubar "$bar_version" nirubar
fixture niruscreensaver "$saver_version" niruscreensaver
fixture nirulock "$lock_version" nirulock
fixture nirulauncher "$launcher_version" nirulauncher
fixture nirulogin "$login_version" nirulogin
fixture nirushare "$share_version" nirushare
fixture nirunotify "$notifier_version" nirunotify
fixture nirushot "$shot_version" nirushot
fixture niruclip "$clip_version" niruclip
fixture nirufetch "$fetch_version" nirufetch
fixture niruwebapp "$webapp_version" niruwebapp
fixture niruwallpaper "$wallpaper_app_version" niruwallpaper niruwallpaper.desktop
# The icon is not a program, so it is not part of the fixture binary. It
# starts with the PNG signature, which an owner comment would break.
printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$FIXTURE/niruwallpaper/$wallpaper_app_version/niruwallpaper.png"
fixture nirudisplay "$display_app_version" nirudisplay nirudisplay.desktop
printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$FIXTURE/nirudisplay/$display_app_version/nirudisplay.png"
fixture niruthemeselector "$theme_selector_version" niruthemeselector niruthemeselector.desktop
printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$FIXTURE/niruthemeselector/$theme_selector_version/niruthemeselector.png"
for os in arch void; do
  printf 'auth include system-auth\naccount include system-auth\n' > "$FIXTURE/nirulock/$lock_version/pam-$os"
done
printf 'auth include common-auth\naccount include common-account\n' > "$FIXTURE/nirulock/$lock_version/pam-debian"
for item in "niruwm/$wm_version" "nirubar/$bar_version" "niruscreensaver/$saver_version" "nirulock/$lock_version" "nirulauncher/$launcher_version" "nirulogin/$login_version" "nirushare/$share_version" "nirunotify/$notifier_version" "nirushot/$shot_version" "niruclip/$clip_version" "nirufetch/$fetch_version" "niruwebapp/$webapp_version" "niruwallpaper/$wallpaper_app_version" "nirudisplay/$display_app_version" "niruthemeselector/$theme_selector_version"; do checksums "$FIXTURE/$item"; done
# 99.0.0 is a synthetic second release, never a real network dependency.
for release in "$VERSION" 99.0.0; do
  mkdir -p "$FIXTURE/nirux/$release"
  sed "s/^VERSION=$VERSION$/VERSION=$release/" "$SOURCE/nirux" > "$FIXTURE/nirux/$release/nirux"
  chmod +x "$FIXTURE/nirux/$release/nirux"
  sed "s/suite $VERSION/suite $release/" "$SOURCE/manifest" > "$FIXTURE/nirux/$release/manifest"
  cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/$release/config.example.toml"
  cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/$release/appearance.example.toml"
  wallpaper_app_assets "$FIXTURE/nirux/$release"
  display_app_assets "$FIXTURE/nirux/$release"
  theme_selector_assets "$FIXTURE/nirux/$release"
  wallpaper_archive "$FIXTURE/nirux/$release/nirux-wallpapers.tar.xz"
  terminal_archive "$FIXTURE/nirux/$release/nirux-terminal.tar.xz"
  integration_archive "$FIXTURE/nirux/$release/nirux-integration.tar.xz"
  printf '# Changelog\n\n## 99.0.0 (2026-11-13)\n\n- **Test highlight one.** More words.\n- Plain bullet sentence. Second sentence.\n\n## %s (2026-11-12)\n\n- **Older entry.**\n' "$VERSION" > "$FIXTURE/nirux/$release/CHANGELOG.md"
  checksums "$FIXTURE/nirux/$release"
done
# 99.2.0 adds a synthetic component. The running installer does not know its
# name; the target installer handoff and manifest-driven staging must install it.
mkdir -p "$FIXTURE/nirux/99.2.0" "$FIXTURE/nirufoo/1.0.0"
sed -e "s/^VERSION=$VERSION$/VERSION=99.2.0/" \
  -e 's/^PROGRAMS="\(.*\)"$/PROGRAMS="\1 nirufoo"/' \
  "$SOURCE/nirux" > "$FIXTURE/nirux/99.2.0/nirux"
chmod +x "$FIXTURE/nirux/99.2.0/nirux"
sed "s/suite $VERSION/suite 99.2.0/" "$SOURCE/manifest" > "$FIXTURE/nirux/99.2.0/manifest"
say 'nirufoo 1.0.0' >> "$FIXTURE/nirux/99.2.0/manifest"
cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/99.2.0/config.example.toml"
cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/99.2.0/appearance.example.toml"
wallpaper_app_assets "$FIXTURE/nirux/99.2.0"
wallpaper_archive "$FIXTURE/nirux/99.2.0/nirux-wallpapers.tar.xz"
terminal_archive "$FIXTURE/nirux/99.2.0/nirux-terminal.tar.xz"
make_binary "$FIXTURE/nirufoo/1.0.0/nirufoo" nirufoo 1.0.0
checksums "$FIXTURE/nirufoo/1.0.0"
checksums "$FIXTURE/nirux/99.2.0"
# 99.3.0 adds a component that only starts after its new package dependency has
# been provisioned. This fails if binaries are executed before provisioning.
mkdir -p "$FIXTURE/nirux/99.3.0" "$FIXTURE/nirulib/1.0.0"
sed -e "s/^VERSION=$VERSION$/VERSION=99.3.0/" \
  -e 's/^PROGRAMS="\(.*\)"$/PROGRAMS="\1 nirulib"/' \
  -e 's/bluez power-profiles-daemon/bluez fake-lib power-profiles-daemon/' \
  -e 's/bluez libspa-0.2-bluetooth power-profiles-daemon/bluez libspa-0.2-bluetooth fake-lib power-profiles-daemon/' \
  -e 's/bluez kitty fish/bluez fake-lib kitty fish/' \
  -e 's/libgtk-3-0 bluez kitty fish; do/libgtk-3-0 bluez fake-lib kitty fish; do/' \
  "$SOURCE/nirux" > "$FIXTURE/nirux/99.3.0/nirux"
chmod +x "$FIXTURE/nirux/99.3.0/nirux"
sed "s/suite $VERSION/suite 99.3.0/" "$SOURCE/manifest" > "$FIXTURE/nirux/99.3.0/manifest"
say 'nirulib 1.0.0' >> "$FIXTURE/nirux/99.3.0/manifest"
cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/99.3.0/config.example.toml"
cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/99.3.0/appearance.example.toml"
wallpaper_app_assets "$FIXTURE/nirux/99.3.0"
wallpaper_archive "$FIXTURE/nirux/99.3.0/nirux-wallpapers.tar.xz"
terminal_archive "$FIXTURE/nirux/99.3.0/nirux-terminal.tar.xz"
cat > "$FIXTURE/nirulib/1.0.0/nirulib" <<'EOF'
#!/bin/sh
[ "$1" = --version ] || exit 0
[ -f "$LIB_MARKER" ] || { echo 'fake-lib is missing' >&2; exit 1; }
echo 'NIRULIB 1.0.0'
EOF
chmod +x "$FIXTURE/nirulib/1.0.0/nirulib"
checksums "$FIXTURE/nirulib/1.0.0"
checksums "$FIXTURE/nirux/99.3.0"

# S03 fixtures: a target release that adds a config key, a wallpaper asset and
# a component, applied by the target installer rather than the older caller.
make_apply_target() {
  release=$1; fail=$2
  dir=$FIXTURE/nirux/$release
  mkdir -p "$dir"
  sed -e "s/^VERSION=$VERSION$/VERSION=$release/" \
    -e 's/^PROGRAMS="\(.*\)"$/PROGRAMS="\1 nirunew"/' \
    "$SOURCE/nirux" > "$dir/nirux"
  sed -i '/add_missing_top_key "\$cfg_candidate" restore_session false/a\
  add_missing_top_key "$cfg_candidate" newfeature true' "$dir/nirux"
  if [ "$fail" = 1 ]; then
    sed -i '/^  install_config$/a\
  [ "${NIRUX_SIMULATE_APPLY_FAIL:-0}" = 1 ] \&\& die "simulated target apply failure"' "$dir/nirux"
  fi
  chmod +x "$dir/nirux"
  sed "s/suite $VERSION/suite $release/" "$SOURCE/manifest" > "$dir/manifest"
  say 'nirunew 1.0.0' >> "$dir/manifest"
  cp "$SOURCE/config.example.toml" "$dir/config.example.toml"
  sed -i '/^theme = "niru-noir"$/a newfeature = true' "$dir/config.example.toml"
  cp "$SOURCE/appearance.example.toml" "$dir/appearance.example.toml"
  wallpaper_app_assets "$dir"
  build=$TEST/apply-wallpaper-$release
  rm -rf "$build"
  mkdir -p "$build/wallpaper"
  printf '\211PNG\r\n\032\n' > "$build/wallpaper/nirux-wallpaper-noir-4k.png"
  printf '\211PNG\r\n\032\n' > "$build/wallpaper/nirux-wallpaper-test-4k.png"
  tar -cJf "$dir/nirux-wallpapers.tar.xz" -C "$build" wallpaper
  terminal_archive "$dir/nirux-terminal.tar.xz"
  checksums "$dir"
}
make_apply_target 99.4.0 0
make_apply_target 99.4.1 1
# 99.5.0 adds an asset the caller does not know about. Only the target apply
# can fetch and install it, proving the target owns new asset semantics.
mkdir -p "$FIXTURE/nirux/99.5.0" "$TEST/asset-build"
sed -e "s/^VERSION=$VERSION$/VERSION=99.5.0/" "$SOURCE/nirux" > "$FIXTURE/nirux/99.5.0/nirux"
sed -i '/^  install_terminal$/a\
  release_optional_file nirux "$RELEASE" nirux-marker.tar.xz\
  tar -xJf "$WORK/download/nirux/nirux-marker.tar.xz" -C "$HOME"' "$FIXTURE/nirux/99.5.0/nirux"
chmod +x "$FIXTURE/nirux/99.5.0/nirux"
sed "s/suite $VERSION/suite 99.5.0/" "$SOURCE/manifest" > "$FIXTURE/nirux/99.5.0/manifest"
cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/99.5.0/config.example.toml"
cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/99.5.0/appearance.example.toml"
wallpaper_app_assets "$FIXTURE/nirux/99.5.0"
wallpaper_archive "$FIXTURE/nirux/99.5.0/nirux-wallpapers.tar.xz"
terminal_archive "$FIXTURE/nirux/99.5.0/nirux-terminal.tar.xz"
printf 'target-owned asset\n' > "$TEST/asset-build/nirux-target-asset-marker"
tar -cJf "$FIXTURE/nirux/99.5.0/nirux-marker.tar.xz" -C "$TEST/asset-build" nirux-target-asset-marker
checksums "$FIXTURE/nirux/99.5.0"
mkdir -p "$FIXTURE/nirunew/1.0.0"
make_binary "$FIXTURE/nirunew/1.0.0/nirunew" nirunew 1.0.0
checksums "$FIXTURE/nirunew/1.0.0"

# Provisioning uses the new release's package list, not the caller's. Exercise
# the missing-only path without touching a package manager. The list comes
# from packages_for, so a stand-in there keeps the test independent of the
# package query while still seeing exactly one missing package.
# shellcheck disable=SC2034 # read by required_missing_packages in the sourced nirux
OS=debian
missing_in_test() { [ "${1:-}" != "curl" ]; }
packages_for() { say "curl ca-certificates"; }
internal_package_query missing_in_test
NIRUX_PACKAGES_DRY_RUN=1 NIRUX_PROVISION_OS=debian NIRUX_PROVISION_DM=keep \
  provision_packages missing > "$TEST/provision.log" 2>&1
grep -q 'would install missing: curl' "$TEST/provision.log" ||
  fail 'provision dry run did not report the missing package'
all_present() { :; }
internal_package_query all_present
NIRUX_PACKAGES_DRY_RUN=1 NIRUX_PROVISION_OS=debian provision_packages missing >/dev/null 2>&1

# A renamed Debian library is asked for under the name this machine uses.
# The name comes from the package database: the plain name is what the release
# asks for, and only a true rename (the plain name missing, the suffixed one
# present) changes it.
_debian_t64_name() { if [ "${1:-}" = libgtk-3-0 ]; then echo libgtk-3-0t64; fi; }
resolved=$(_debian_t64_name libgtk-3-0)
[ "$resolved" = "libgtk-3-0t64" ] ||
  fail 'the rename helper no longer names the t64 package'
[ -z "$(_debian_t64_name bluez)" ] || fail 'the rename helper renamed an unchanged package' 

# shellcheck disable=SC2034 # read by resolved_missing_packages
unset NIRUX_PACKAGE_MAP
# shellcheck disable=SC2034 # read by distribution_package_present
NIRUX_PACKAGE_QUERY=
# The real list again, read from the installer source.
eval "$(sed -n '/^packages_for() {/,/^}/p' "$SOURCE/nirux")"
for os in arch debian void; do
  (
    OS=$os
    packages_for "$OS"
  ) | grep -qw bluez || fail "bluez missing from $os package list"
  (
    OS=$os
    packages_for "$OS"
  ) | grep -qw power-profiles-daemon || fail "power-profiles-daemon missing from $os package list"
done
(
  OS=arch
  packages_for "$OS"
) | grep -qw bluez-utils || fail 'bluez-utils missing from arch package list'

# Arch missing-only provisioning must not create a partial upgrade by syncing
# databases without upgrading the installed system.
(
  export OS=arch
  pacman() { printf '%s\n' "$*"; }
  install_packages kitty
) > "$TEST/arch-packages.log"
grep -qx -- '-S --needed --noconfirm kitty' "$TEST/arch-packages.log" || fail 'unsafe Arch missing-package command'

# NIRULOCK's pause music needs sidplayfp: a distribution package on Debian and
# Void, AUR only on Arch, where it is built and never fatal.
for os in debian void; do
  ( OS=$os; packages_for "$OS" ) | grep -qw sidplayfp || fail "sidplayfp missing from $os package list"
done
( OS=arch; packages_for "$OS" ) | grep -qw sidplayfp && fail 'sidplayfp is not an Arch repository package'
if command -v sidplayfp >/dev/null 2>&1; then
  say 'skip: sidplayfp is installed on this machine; AUR provisioning tests need it absent'
else
  aur=$TEST/aur
  mkdir -p "$aur"
  (
    OS=debian; SIDPLAYFP_AUR_MARKER=$aur/marker
    as_root() { printf 'root %s\n' "$*" >> "$aur/debian.log"; }
    provision_sidplayfp_aur
  )
  [ ! -s "$aur/debian.log" ] || fail 'sidplayfp AUR provisioning ran on Debian'
  # makepkg as the user in a login shell, then pacman -U as root.
  (
    OS=arch; SIDPLAYFP_AUR_MARKER=$aur/marker
    distribution_package_present() { return 1; }
    id() { say 1000; } # the distro CI containers run as root
    as_root() { printf 'root %s\n' "$*" >> "$aur/makepkg.log"; }
    git() { printf 'git %s\n' "$*" >> "$aur/makepkg.log"; mkdir -p "$6"; }
    bash() {
      printf 'bash %s\n' "$1" >> "$aur/makepkg.log"
      : > "$4/sidplayfp-3.2.3-1-x86_64.pkg.tar.zst"
      : > "$4/sidplayfp-debug-3.2.3-1-x86_64.pkg.tar.zst"
    }
    provision_sidplayfp_aur
  ) > "$aur/makepkg.out" 2>&1 || fail 'sidplayfp makepkg provisioning failed'
  grep -q '^root pacman -S --needed --noconfirm base-devel git libsidplayfp .* perl$' "$aur/makepkg.log" ||
    fail 'sidplayfp build dependencies (perl included) were not installed'
  grep -q '^git clone --quiet --depth 1 https://aur.archlinux.org/sidplayfp.git ' "$aur/makepkg.log" ||
    fail 'sidplayfp was not cloned from the AUR'
  grep -qx 'bash -lc' "$aur/makepkg.log" || fail 'makepkg did not run in a login shell'
  grep -q '^root pacman -U --needed --noconfirm .*/sidplayfp-3.2.3-1-x86_64.pkg.tar.zst$' "$aur/makepkg.log" ||
    fail 'the built sidplayfp package was not installed'
  grep -q 'sidplayfp-debug' "$aur/makepkg.log" && fail 'the debug package was installed'
  # An installed AUR helper is used instead of makepkg.
  (
    OS=arch; SIDPLAYFP_AUR_MARKER=$aur/marker
    distribution_package_present() { return 1; }
    id() { say 1000; } # the distro CI containers run as root
    as_root() { printf 'root %s\n' "$*" >> "$aur/helper.log"; }
    paru() { printf 'paru %s\n' "$*" >> "$aur/helper.log"; }
    provision_sidplayfp_aur
  ) > /dev/null 2>&1
  grep -qx 'paru -S --needed --noconfirm sidplayfp' "$aur/helper.log" || fail 'the AUR helper was not used'
  grep -q '^root' "$aur/helper.log" && fail 'makepkg ran although the AUR helper succeeded'
  # A failed build warns, is not fatal and is not retried by every update.
  (
    OS=arch; SIDPLAYFP_AUR_MARKER=$aur/marker
    distribution_package_present() { return 1; }
    id() { say 1000; } # the distro CI containers run as root
    as_root() { :; }
    yay() { return 1; }
    git() { return 1; }
    provision_sidplayfp_aur
    say "status $?"
    git() { printf 'retried\n' >> "$aur/retry.log"; return 1; }
    provision_sidplayfp_aur
  ) > "$aur/fail.out" 2>&1 || fail 'a failed sidplayfp build was fatal'
  grep -q 'status 0' "$aur/fail.out" || fail 'a failed sidplayfp build returned an error'
  grep -q 'warning: sidplayfp could not be installed from the AUR' "$aur/fail.out" || fail 'a failed sidplayfp build did not warn'
  [ -f "$aur/marker" ] || fail 'a failed sidplayfp build was not remembered'
  [ ! -e "$aur/retry.log" ] || fail 'a failed sidplayfp build was retried by the next update'
  (
    OS=arch; SIDPLAYFP_AUR_MARKER=$aur/root-marker
    distribution_package_present() { return 1; }
    id() { say 0; }
    git() { printf 'built as root\n' >> "$aur/root.log"; return 1; }
    provision_sidplayfp_aur
  ) > "$aur/root.out" 2>&1 || fail 'sidplayfp provisioning as root was fatal'
  [ ! -e "$aur/root.log" ] || fail 'makepkg was run as root'
  grep -q 'makepkg does not run as root' "$aur/root.out" || fail 'root sidplayfp provisioning did not warn'
  (
    OS=arch
    # shellcheck disable=SC2034 # read by sidplayfp_aur_marker
    SIDPLAYFP_AUR_MARKER=$aur/none
    distribution_package_present() { return 1; }
    id() { say 1000; } # the distro CI containers run as root
    NIRUX_PACKAGES_DRY_RUN=1 provision_sidplayfp_aur
  ) | grep -qx 'would build sidplayfp from the AUR' || fail 'dry run did not report the sidplayfp AUR build'
fi

# TOML keys are scoped to tables. A same-named key in a different table must
# neither suppress a new setting nor be overwritten. Accept indented headers
# with comments and preserve private config permissions and idempotence.
config=$TEST/migration.toml
cat > "$config" <<'EOF'
theme = "niru-nord"
  [wallpaper] # user settings
files = ["my wallpaper.png"]
scale = "fit"
  [bar] # keep this comment
enabled = false
[[monitors.profiles]]
name = "eDP-1"
workspaces = ["web", "code"]
EOF
chmod 600 "$config"
add_missing_top_key "$config" enabled true
add_missing_key "$config" bar scale '"bar-only"'
add_missing_key "$config" wallpaper scale '"fill"'
add_missing_sections "$config" "$SOURCE/config.example.toml"
add_missing_key "$config" monitors workspaces 10
cp "$config" "$TEST/once.toml"
add_missing_top_key "$config" enabled true
add_missing_key "$config" bar scale '"bar-only"'
add_missing_sections "$config" "$SOURCE/config.example.toml"
add_missing_key "$config" monitors workspaces 10
[ "$(sha256sum "$config" | cut -d' ' -f1)" = "$(sha256sum "$TEST/once.toml" | cut -d' ' -f1)" ] || fail 'config migration is not idempotent'
[ "$(stat -c %a "$config")" = 600 ] || fail 'config migration changed permissions'
grep -qx 'enabled = true' "$config" || fail 'nested key suppressed root default'
grep -qx 'scale = "bar-only"' "$config" || fail 'other table suppressed missing key'
grep -qx 'scale = "fit"' "$config" || fail 'existing setting overwritten'
[ "$(grep -c '^[[:space:]]*\[bar\]' "$config")" = 1 ] || fail 'duplicate commented table'
grep -qx 'workspaces = 10' "$config" || fail 'profile suppressed monitor default'

# I06: quoted keys and multiline values are scanned, and a staged candidate is
# validated by both components before it can replace the user file.
i06=$TEST/i06
mkdir -p "$i06/work/download/nirux" "$i06/work/generation/bin" "$i06/config/niruwm"
cp "$SOURCE/config.example.toml" "$i06/work/download/nirux/config.example.toml"
for program in niruwm nirubar; do
  cat > "$i06/work/generation/bin/$program" <<'EOF'
#!/bin/sh
[ "$1" = --check-config ] || exit 0
printf '%s\n' "$1" >> "$VALIDATOR_LOG"
grep -q 'REJECT_CANDIDATE' "$XDG_CONFIG_HOME/niruwm/config.toml" && exit 1
exit 0
EOF
  chmod +x "$i06/work/generation/bin/$program"
done
cat > "$i06/config/niruwm/config.toml" <<'EOF'
theme = "niru-noir"
"weather_latitude" = 1.0
font_path = """
[bar]
scale = "not-a-real-setting"
"""
terminal = [
  "kitty",
]
  [wallpaper] # user settings
files = ["my wallpaper.png"]
scale = "fit"
  [bar] # keep this comment
enabled = false
[nightlight]
temperature = 3400
mode = "manual"
[[monitors.profiles]]
name = "eDP-1"
workspaces = ["web", "code"]
EOF
chmod 640 "$i06/config/niruwm/config.toml"
(
  WORK=$i06/work CONFDIR=$i06/config/niruwm VALIDATOR_LOG=$i06/validators.log
  export WORK CONFDIR VALIDATOR_LOG
  install_config
) > "$i06/install.log" 2>&1 || fail 'quoted/multiline config migration failed'
[ "$(stat -c %a "$i06/config/niruwm/config.toml")" = 640 ] || fail 'migration changed config permissions'
[ "$(config_scan "$i06/config/niruwm/config.toml" | awk -F '\t' '$1 == "H" && $3 == "bar" && $4 == "table" { n++ } END { print n + 0 }')" = 1 ] || fail 'multiline value created a duplicate table'
[ "$(grep -c 'weather_latitude' "$i06/config/niruwm/config.toml")" = 1 ] || fail 'quoted key was duplicated'
grep -qx 'enabled = false' "$i06/config/niruwm/config.toml" || fail 'existing bar value was overwritten'
grep -qx 'scale = "fit"' "$i06/config/niruwm/config.toml" || fail 'existing wallpaper value was overwritten'
grep -qx 'workspaces = 10' "$i06/config/niruwm/config.toml" || fail 'missing monitor default was not added'
grep -qx 'title_delay_seconds = 0' "$i06/config/niruwm/config.toml" || fail 'bar key was not added to the real table'
grep -qx 'follow_theme = true' "$i06/config/niruwm/config.toml" || fail 'wallpaper follow_theme default was not added'
grep -q '^\[autostart\]' "$i06/config/niruwm/config.toml" || fail 'autostart section was not added'
grep -qx 'theme_dir = "~/Pictures/Wallpapers/NIRU"' "$i06/config/niruwm/config.toml" || fail 'wallpaper theme_dir default was not added'
grep -q 'scale = "not-a-real-setting"' "$i06/config/niruwm/config.toml" || fail 'multiline string was changed'
[ "$(wc -l < "$i06/validators.log")" = 2 ] || fail 'candidate was not validated by both components'
grep -qx 'mode = "solar"' "$i06/config/niruwm/config.toml" || fail 'old default night light was not moved to the solar schedule'
grep -qx 'temperature = 2700' "$i06/config/niruwm/config.toml" || fail 'old default night light temperature was not changed'
grep -qx 'charge_limit = 80' "$i06/config/niruwm/config.toml" || fail 'battery section was not added'
printf '[nightlight]\nmode = "manual"\ntemperature = 3400\n' > "$i06/nightlight-again.toml"
upgrade_nightlight_schedule "$i06/nightlight-again.toml" >/dev/null
grep -qx 'mode = "manual"' "$i06/nightlight-again.toml" || fail 'the night light migration ran twice'
# The privacy dot goes next to the recording module once; a later removal stays.
rm -f "$STATE/bar-privacy-0.12.266"
printf '[bar]\nmodules = [\n  "workspaces", "recording",\n  "clock"]\n\n[other]\nx = 1\n' > "$i06/privacy.toml"
upgrade_bar_privacy_module "$i06/privacy.toml" >/dev/null
grep -q '"privacy", "recording"' "$i06/privacy.toml" || fail 'privacy module was not added next to recording'
grep -qx 'x = 1' "$i06/privacy.toml" || fail 'privacy migration damaged the next table'
[ "$(grep -c 'modules' "$i06/privacy.toml")" = 1 ] || fail 'privacy migration duplicated the modules list'
printf '[bar]\nmodules = ["workspaces", "clock"]\n' > "$i06/privacy-removed.toml"
upgrade_bar_privacy_module "$i06/privacy-removed.toml" >/dev/null
grep -q 'privacy' "$i06/privacy-removed.toml" && fail 'the privacy migration ran twice'
rm -f "$STATE/bar-privacy-0.12.266"
upgrade_bar_privacy_module "$i06/privacy-removed.toml" >/dev/null
grep -q '"privacy", "clock"' "$i06/privacy-removed.toml" || fail 'privacy module was not added before the clock'

# A symlinked config keeps its link and updates the resolved target atomically.
mkdir -p "$i06/symlink/niruwm" "$i06/symlink/real"
cat > "$i06/symlink/real/config.toml" <<'EOF'
theme = "niru-noir"
EOF
chmod 640 "$i06/symlink/real/config.toml"
ln -s "$i06/symlink/real/config.toml" "$i06/symlink/niruwm/config.toml"
(
  WORK=$i06/work CONFDIR=$i06/symlink/niruwm VALIDATOR_LOG=$i06/symlink.log
  export WORK CONFDIR VALIDATOR_LOG
  install_config
) > "$i06/symlink.out" 2>&1 || fail 'symlinked config migration failed'
[ -L "$i06/symlink/niruwm/config.toml" ] || fail 'migration replaced the config symlink'
grep -qx 'workspaces = 10' "$i06/symlink/real/config.toml" || fail 'migration did not update the symlink target'
[ "$(stat -c %a "$i06/symlink/real/config.toml")" = 640 ] || fail 'symlink target permissions changed'

# Unsupported or invalid input stops before the original file changes.
mkdir -p "$i06/duplicate/niruwm" "$i06/reject/niruwm"
cat > "$i06/duplicate/niruwm/config.toml" <<'EOF'
theme = "niru-noir"
[bar]
enabled = true
[bar]
tray = true
EOF
duplicate_sum=$(sha256sum "$i06/duplicate/niruwm/config.toml" | cut -d' ' -f1)
set +e
(
  WORK=$i06/work CONFDIR=$i06/duplicate/niruwm VALIDATOR_LOG=$i06/duplicate.log
  export WORK CONFDIR VALIDATOR_LOG
  install_config
) > "$i06/duplicate.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'duplicate-table migration succeeded'
[ "$(sha256sum "$i06/duplicate/niruwm/config.toml" | cut -d' ' -f1)" = "$duplicate_sum" ] || fail 'duplicate-table migration changed the original'
grep -q 'duplicate table' "$i06/duplicate.log" || fail 'duplicate table was not diagnosed'
no_config_candidates "$i06/duplicate/niruwm" || fail 'duplicate-table rejection left a candidate'

cat > "$i06/reject/niruwm/config.toml" <<'EOF'
theme = "niru-noir"
# REJECT_CANDIDATE
EOF
reject_sum=$(sha256sum "$i06/reject/niruwm/config.toml" | cut -d' ' -f1)
set +e
(
  WORK=$i06/work CONFDIR=$i06/reject/niruwm VALIDATOR_LOG=$i06/reject.log
  export WORK CONFDIR VALIDATOR_LOG
  install_config
) > "$i06/reject.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'component-rejected migration succeeded'
[ "$(sha256sum "$i06/reject/niruwm/config.toml" | cut -d' ' -f1)" = "$reject_sum" ] || fail 'component-rejected migration changed the original'
grep -q 'rejected by niruwm' "$i06/reject.log" || fail 'component rejection was not diagnosed'
no_config_candidates "$i06/reject/niruwm" || fail 'component rejection left a candidate'

# A failed activation write leaves the original file intact.
mkdir -p "$i06/interrupt/niruwm"
cat > "$i06/interrupt/niruwm/config.toml" <<'EOF'
theme = "niru-noir"
EOF
interrupt_sum=$(sha256sum "$i06/interrupt/niruwm/config.toml" | cut -d' ' -f1)
set +e
(
  WORK=$i06/work CONFDIR=$i06/interrupt/niruwm VALIDATOR_LOG=$i06/interrupt.log
  export WORK CONFDIR VALIDATOR_LOG
  mv() { last=; for arg in "$@"; do last=$arg; done; case "$last" in */config.toml) return 1 ;; *) command mv "$@" ;; esac; }
  install_config
) > "$i06/interrupt.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'failed activation write succeeded'
[ "$(sha256sum "$i06/interrupt/niruwm/config.toml" | cut -d' ' -f1)" = "$interrupt_sum" ] || fail 'failed activation write changed the original'
grep -q 'could not activate' "$i06/interrupt.log" || fail 'failed activation write was not diagnosed'
no_config_candidates "$i06/interrupt/niruwm" || fail 'failed activation write left a candidate'

for TEST_OS in arch debian void; do
  # Separate installations exercise each distribution's integration and cleanup.
  PREFIX=$TEST/$TEST_OS; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
  touch "$ROOT/etc/pam.d/system-auth" "$ROOT/etc/pam.d/common-auth" "$ROOT/etc/pam.d/common-account"
  operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
  [ -x "$ROOT/usr/libexec/nirux-wifi" ] || fail 'restricted Wi-Fi helper was not installed'
  # K7/K8: the nightly update helper, its settings, the fixed sudoers rule,
  # its schedule on this init system, and the root sleep hook.
  [ -x "$ROOT/usr/libexec/nirux-autoupdate" ] || fail "$TEST_OS: nightly update helper was not installed"
  grep -qxF "# NIRUX owner: $PREFIX" "$ROOT/usr/libexec/nirux-autoupdate" || fail 'nightly update helper has no owner line'
  grep -qx 'enabled=yes' "$ROOT/etc/nirux/autoupdate.conf" || fail 'nightly update is not on by default'
  grep -qx "user=$(id -un)" "$ROOT/etc/nirux/autoupdate.conf" || fail 'nightly update settings name no user'
  grep -q "NOPASSWD: /usr/libexec/nirux-autoupdate run-now, /usr/libexec/nirux-autoupdate enable, /usr/libexec/nirux-autoupdate disable\$" \
    "$ROOT/etc/sudoers.d/zz-nirux-autoupdate" || fail 'nightly update sudoers rule is not fixed-argument'
  [ "$(stat -c %a "$ROOT/etc/sudoers.d/zz-nirux-autoupdate")" = 440 ] || fail 'nightly update sudoers rule is not 0440'
  allow=$ROOT/etc/nirux/autoupdate-packages
  [ "$(stat -c %a "$allow")" = 644 ] || fail "$TEST_OS: the nightly package allowlist is not 0644"
  for allowed_pkg in curl kitty tailscale papirus-icon-theme sddm; do
    grep -qx "$allowed_pkg" "$allow" || fail "$TEST_OS: $allowed_pkg is missing from the nightly package allowlist"
  done
  case "$TEST_OS" in
    debian) grep -qx libgtk-3-0t64 "$allow" && grep -qx libnss3 "$allow" || fail 'debian: browser libraries missing from the allowlist' ;;
    void) grep -qx libXcomposite "$allow" || fail 'void: browser libraries missing from the allowlist' ;;
    arch) grep -qx pacman-contrib "$allow" || fail 'arch: pacman-contrib missing from the allowlist' ;;
  esac
  if [ "$TEST_OS" = void ]; then
    grep -q 'nirux-autoupdate loop' "$ROOT/etc/sv/nirux-autoupdate/run" || fail 'void: no runit loop for the nightly update'
    [ -x "$ROOT/usr/libexec/elogind/system-sleep/nirux" ] || fail 'void: elogind sleep hook missing'
  else
    grep -qx 'OnCalendar=\*-\*-\* 03:00:00' "$ROOT/etc/systemd/system/nirux-autoupdate.timer" || fail 'nightly timer is not at 03:00'
    grep -qx 'RandomizedDelaySec=30min' "$ROOT/etc/systemd/system/nirux-autoupdate.timer" || fail 'nightly timer has no random delay'
    grep -qx 'Persistent=false' "$ROOT/etc/systemd/system/nirux-autoupdate.timer" || fail 'nightly timer catches up missed runs'
    grep -qx 'ExecStart=/usr/libexec/nirux-autoupdate run --scheduled' "$ROOT/etc/systemd/system/nirux-autoupdate.service" || fail 'nightly service runs the wrong command'
    [ -x "$ROOT/usr/lib/systemd/system-sleep/nirux" ] || fail "$TEST_OS: systemd sleep hook missing"
  fi
  status
  [ ! -e "$HOME/session-was-started" ] || fail 'status ran the session'
  [ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = "$VERSION" ] || fail 'wrong manifest'
  [ "$(browser_policy)" = none ] || fail 'browser opt-out was not persisted'
  grep -qx 'browser = \[\]' "$XDG_CONFIG_HOME/niruwm/config.toml" || fail 'fresh opt-out did not disable the managed browser default'
  [ ! -e "$BIN/helium" ] || fail 'browser was installed despite opt-out'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'theme wallpapers were not installed'
  mkdir -p "$XDG_CONFIG_HOME/niruwm/themes"
  printf 'name = "User Test"\nbackground = "101010"\nforeground = "eeeeee"\nmuted = "999999"\nborder = "333333"\nfocus = "4488cc"\n' > "$XDG_CONFIG_HOME/niruwm/themes/user-test.toml"
  printf 'hidden = ["niru-satie"]\n' > "$XDG_CONFIG_HOME/niruwm/theme-preferences.toml"
  [ -f "$XDG_CONFIG_HOME/kitty/kitty.conf" ] || fail 'kitty integration was not installed'
  [ -f "$XDG_CONFIG_HOME/nirux/theme/kitty.conf" ] || fail 'kitty theme was not generated'
  [ -f "$XDG_CONFIG_HOME/nirux/theme/fish.fish" ] || fail 'fish theme was not generated'
  grep -q 'NIRUX terminal integration' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'fish integration block was not installed'
  [ -x "$BIN/nirux-theme-hook" ] || fail 'theme hook was not installed'
  session_desktop=$ROOT/usr/share/xsessions/niruwm.desktop
  grep -qxF "Exec=$BIN/niruwm-session" "$session_desktop" || fail 'display-manager session Exec must be an unquoted absolute path'
  ! grep -q '"' "$session_desktop" || fail 'display-manager session must not quote Exec'
  [ -f "$ROOT/etc/udev/rules.d/70-nirux-backlight.rules" ] || fail 'missing backlight udev rule'
  grep -q '"Tapping" "on"' "$ROOT/etc/X11/xorg.conf.d/30-nirux-touchpad.conf" || fail 'touchpad tapping rule missing'
  grep -q '"TappingButtonMap" "lrm"' "$ROOT/etc/X11/xorg.conf.d/30-nirux-touchpad.conf" || fail 'two-finger tap is not a right click'
  grep -q 'charge_control_end_threshold' "$ROOT/etc/udev/rules.d/90-nirux-battery.rules" || fail 'battery charge limit rule missing'
  grep -q "chgrp $(id -g) " "$ROOT/etc/udev/rules.d/90-nirux-battery.rules" || fail 'battery rule does not name the user group'
  if [ "$TEST_OS" = void ]; then
    grep -q 'subsystem-match=sound' "$ROOT/etc/sv/nirux-udev-replay/run" || fail 'Void udev replay service missing'
    [ -x "$ROOT/etc/sv/nirux-udev-replay/run" ] || fail 'Void udev replay service is not executable'
    [ -L "$ROOT/var/service/nirux-udev-replay" ] || fail 'Void udev replay service is not enabled'
  else
    [ ! -e "$ROOT/etc/sv/nirux-udev-replay" ] || fail 'udev replay service outside Void'
  fi
  [ "$(app_policy tailscale)" = yes ] || fail 'a noninteractive install did not choose Tailscale'
  # The launcher entry must point at the generation link, not at a path the
  # user could replace, and the icon must come from the release.
  app_desktop=$ROOT/usr/share/applications/niruwallpaper.desktop
  grep -qxF "Exec=$BIN/niruwallpaper" "$app_desktop" || fail 'wallpaper app entry does not use the managed binary'
  icon=$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png
  [ -f "$icon" ] || fail 'wallpaper app icon was not installed'
  # The icon must stay a valid PNG: no comment may be put in front of it.
  [ "$(head -c 8 "$icon" | od -An -tx1 | tr -d ' \n')" = 89504e470d0a1a0a ] || fail 'installed wallpaper icon is not a PNG'
  # Arch's base image carries neither `cmp` nor `diff`, so the bytes are
  # compared by checksum, which every distribution has.
  [ "$(sha256sum "$icon" | cut -d ' ' -f1)" = \
    "$(sha256sum "$FIXTURE/niruwallpaper/$wallpaper_app_version/niruwallpaper.png" | cut -d ' ' -f1)" ] ||
    fail 'installed icon differs from the released icon'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruwallpaper.png || fail 'icon ownership was not recorded beside the file'
  display_desktop=$ROOT/usr/share/applications/nirudisplay.desktop
  grep -qxF "Exec=$BIN/nirudisplay" "$display_desktop" || fail 'display app entry does not use the managed binary'
  display_icon=$ROOT/usr/share/icons/hicolor/256x256/apps/nirudisplay.png
  [ -f "$display_icon" ] || fail 'display app icon was not installed'
  [ "$(head -c 8 "$display_icon" | od -An -tx1 | tr -d ' \n')" = 89504e470d0a1a0a ] || fail 'installed display icon is not a PNG'
  [ "$(sha256sum "$display_icon" | cut -d ' ' -f1)" = \
    "$(sha256sum "$FIXTURE/nirudisplay/$display_app_version/nirudisplay.png" | cut -d ' ' -f1)" ] ||
    fail 'installed display icon differs from the released icon'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q nirudisplay.png || fail 'display icon ownership was not recorded beside the file'
  theme_desktop=$ROOT/usr/share/applications/niruthemeselector.desktop
  grep -qxF "Exec=$BIN/niruthemeselector" "$theme_desktop" || fail 'theme selector entry does not use the managed binary'
  theme_icon=$ROOT/usr/share/icons/hicolor/256x256/apps/niruthemeselector.png
  [ -f "$theme_icon" ] || fail 'theme selector icon was not installed'
  [ "$(head -c 8 "$theme_icon" | od -An -tx1 | tr -d ' \n')" = 89504e470d0a1a0a ] || fail 'installed theme selector icon is not a PNG'
  [ "$(sha256sum "$theme_icon" | cut -d ' ' -f1)" = \
    "$(sha256sum "$FIXTURE/niruthemeselector/$theme_selector_version/niruthemeselector.png" | cut -d ' ' -f1)" ] ||
    fail 'installed theme selector icon differs from the released icon'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruthemeselector.png || fail 'theme selector icon ownership was not recorded beside the file'
  first=$(readlink "$STATE/current")
  operation install_or_update update --no-packages --release 99.0.0
  second=$(readlink "$STATE/current")
  [ "$first" != "$second" ] || fail 'no generation switch'
  [ "$(browser_policy)" = none ] || fail 'update did not preserve the browser opt-out'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'update removed theme wallpapers'
  [ "$(grep -c '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/fish/config.fish")" = 1 ] || fail 'fish integration block was duplicated'
  operation rollback
  [ "$(readlink "$STATE/current")" = "$first" ] || fail 'rollback did not restore the generation'
  # Normal uninstall keeps settings; purge removes only the documented
  # suite-owned config/state/cache directories. Unowned files stay.
  say 'my existing desktop' > "$HOME/.xinitrc"
  mkdir -p "$XDG_CONFIG_HOME/niruui" "$XDG_CONFIG_HOME/nirubar" \
    "$XDG_CONFIG_HOME/nirulauncher" "$XDG_CONFIG_HOME/nirunotify" \
    "$XDG_STATE_HOME/nirulock" "$XDG_STATE_HOME/niruscreensaver" \
    "$HOME/.cache/nirubar"
  say stale > "$HOME/.cache/nirubar/updates"
  # A remembered extras selection (normal on a real machine) must not stop
  # uninstall: 0.12.223 exited there when the last listed extra was missing.
  mkdir -p "$(dirname "$EXTRAS_SELECTED")"; printf 'niruflow\n' > "$EXTRAS_SELECTED"
  operation uninstall
  rm -f "$EXTRAS_SELECTED"
  [ ! -e "$BIN/niruwm" ] || fail 'program still installed'
  [ ! -e "$ROOT/etc/X11/xorg.conf.d/30-nirux-touchpad.conf" ] || fail 'touchpad rule remained after uninstall'
  [ ! -e "$ROOT/etc/udev/rules.d/90-nirux-battery.rules" ] || fail 'battery rule remained after uninstall'
  [ ! -e "$ROOT/etc/sv/nirux-udev-replay" ] && [ ! -L "$ROOT/var/service/nirux-udev-replay" ] || fail 'udev replay service remained after uninstall'
  [ ! -e "$ROOT/etc/pam.d/nirulock" ] || fail 'owned PAM service remained'
  [ ! -e "$ROOT/usr/libexec/nirux-autoupdate" ] && [ ! -e "$ROOT/etc/sudoers.d/zz-nirux-autoupdate" ] ||
    fail 'nightly update helper or its sudoers rule remained after uninstall'
  [ ! -e "$ROOT/etc/nirux/autoupdate-packages" ] || fail 'nightly package allowlist remained after uninstall'
  [ ! -e "$ROOT/etc/systemd/system/nirux-autoupdate.timer" ] && [ ! -e "$ROOT/etc/sv/nirux-autoupdate/run" ] ||
    fail 'nightly update schedule remained after uninstall'
  [ ! -e "$ROOT/usr/lib/systemd/system-sleep/nirux" ] && [ ! -e "$ROOT/usr/libexec/elogind/system-sleep/nirux" ] ||
    fail 'sleep hook remained after uninstall'
  [ ! -e "$ROOT/usr/share/applications/niruwallpaper.desktop" ] || fail 'wallpaper app entry remained after uninstall'
  [ ! -e "$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png" ] || fail 'wallpaper app icon remained after uninstall'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruwallpaper.png && fail 'icon ownership record remained after uninstall'
  [ ! -e "$ROOT/usr/share/applications/nirudisplay.desktop" ] || fail 'display app entry remained after uninstall'
  [ ! -e "$ROOT/usr/share/icons/hicolor/256x256/apps/nirudisplay.png" ] || fail 'display app icon remained after uninstall'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q nirudisplay.png && fail 'display icon ownership record remained after uninstall'
  [ ! -e "$ROOT/usr/share/applications/niruthemeselector.desktop" ] || fail 'theme selector entry remained after uninstall'
  [ ! -e "$ROOT/usr/share/icons/hicolor/256x256/apps/niruthemeselector.png" ] || fail 'theme selector icon remained after uninstall'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruthemeselector.png && fail 'theme selector icon ownership record remained after uninstall'
  # The directories belong to the package manager. Uninstall removes the files
  # it installed, never a shared directory, even when it is empty.
  [ -d "$ROOT/usr/share/applications" ] || fail 'uninstall removed the shared application directory'
  [ -d "$ROOT/usr/share/icons/hicolor" ] || fail 'uninstall removed the shared icon theme directory'
  for dir in niruwm niruui nirubar nirulauncher nirunotify; do
    [ -d "$XDG_CONFIG_HOME/$dir" ] || fail "normal uninstall removed $dir config"
  done
  [ -d "$XDG_STATE_HOME/nirulock" ] || fail 'normal uninstall removed lock state'
  [ -d "$XDG_STATE_HOME/niruscreensaver" ] || fail 'normal uninstall removed saver state'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'normal uninstall removed theme wallpapers'
  [ -f "$XDG_CONFIG_HOME/niruwm/themes/user-test.toml" ] || fail 'normal uninstall removed a user theme'
  [ -f "$XDG_CONFIG_HOME/niruwm/theme-preferences.toml" ] || fail 'normal uninstall removed theme preferences'
  [ ! -e "$XDG_CONFIG_HOME/nirux" ] || fail 'normal uninstall left terminal config'
  [ ! -e "$BIN/nirux-theme-hook" ] || fail 'normal uninstall left the theme hook'
  operation uninstall --purge
  [ ! -e "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'purge kept an unmodified theme wallpaper'
  for dir in niruwm niruui nirubar nirulauncher nirunotify; do
    [ ! -d "$XDG_CONFIG_HOME/$dir" ] || fail "purge missed $dir config"
  done
  for dir in nirulock niruscreensaver; do
    [ ! -d "$XDG_STATE_HOME/$dir" ] || fail "purge missed $dir state"
  done
  [ ! -d "$HOME/.cache/nirubar" ] || fail 'purge missed bar cache'
  [ "$(cat "$HOME/.xinitrc")" = 'my existing desktop' ] || fail 'existing xinitrc was changed'
done

# I07: a component that only exists in the target release is staged by the
# target installer and linked on the first update.
TEST_OS=arch; PREFIX=$TEST/newcomponent; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
operation install_or_update update --no-packages --release 99.2.0 > "$TEST/newcomponent.log" 2>&1 || \
  fail 'first update with a new component failed'
grep -q 'Staged components. Validating generation' "$TEST/newcomponent.log" || fail 'target installer handoff was not used'
[ -x "$BIN/nirufoo" ] || fail 'new component was not linked on the first update'
[ -x "$STATE/current/bin/nirufoo" ] || fail 'new component was not staged'
[ "$(readlink "$BIN/nirufoo")" = "$STATE/current/bin/nirufoo" ] || fail 'new component link is not generation-owned'
[ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = 99.2.0 ] || fail 'new component release was not activated'
grep -q 'nirufoo' "$STATE/current/bin/nirux" || fail 'installed installer does not know the new component'
operation rollback >/dev/null 2>&1 || fail 'rollback after a new component failed'
[ ! -e "$BIN/nirufoo" ] && [ ! -L "$BIN/nirufoo" ] || fail 'rollback left a front link for a component absent from the restored generation'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"

# S03: one update to a synthetic target that adds a config key, wallpaper asset
# and component. The target installer owns config/integration/activation.
TEST_OS=arch; PREFIX=$TEST/apply-one; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
[ ! -e "$BIN/nirunew" ] || fail 'synthetic component existed before the target update'
! grep -qx 'newfeature = true' "$XDG_CONFIG_HOME/niruwm/config.toml" || fail 'synthetic config key existed before the target update'
before=$(readlink "$STATE/current")
operation install_or_update update --no-packages --release 99.4.0 > "$TEST/apply-one.log" 2>&1 || \
  fail 'one-update target apply failed'
[ "$(readlink "$STATE/current")" != "$before" ] || fail 'target apply did not switch generation'
[ -x "$BIN/nirunew" ] || fail 'target apply did not link the new component'
grep -qx 'newfeature = true' "$XDG_CONFIG_HOME/niruwm/config.toml" || fail 'target apply did not add the new config key'
[ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-test-4k.png" ] || fail 'target apply did not install the new wallpaper asset'
grep -q 'Applied through the target installer' "$TEST/apply-one.log" || fail 'target apply was not used'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"

# S03: a new asset known only to the target installer must still be fetched.
TEST_OS=arch; PREFIX=$TEST/apply-asset; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
rm -f "$HOME/nirux-target-asset-marker"
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
operation install_or_update update --no-packages --release 99.5.0 > "$TEST/apply-asset.log" 2>&1 || \
  fail 'target-owned new asset update failed'
[ -f "$HOME/nirux-target-asset-marker" ] || fail 'target apply did not fetch its new asset'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"
rm -f "$HOME/nirux-target-asset-marker"

# S03 failure injection: a target apply that fails after changing config must
# restore the original config and leave the active generation untouched.
TEST_OS=arch; PREFIX=$TEST/apply-fail; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
before=$(readlink "$STATE/current")
before_sum=$(sha256sum "$XDG_CONFIG_HOME/niruwm/config.toml" | cut -d' ' -f1)
set +e
( export NIRUX_SIMULATE_APPLY_FAIL=1
  install_or_update update --no-packages --release 99.4.1
) > "$TEST/apply-fail.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'injected target apply failure succeeded'
[ "$(readlink "$STATE/current")" = "$before" ] || fail 'failed target apply changed the active generation'
[ "$(sha256sum "$XDG_CONFIG_HOME/niruwm/config.toml" | cut -d' ' -f1)" = "$before_sum" ] || fail 'failed target apply changed the original config'
! grep -qx 'newfeature = true' "$XDG_CONFIG_HOME/niruwm/config.toml" || fail 'failed target apply left the new config key'
grep -q 'simulated target apply failure' "$TEST/apply-fail.log" || fail 'target apply failure was not reported'
grep -q 'original configuration restored' "$TEST/apply-fail.log" || fail 'target apply did not restore the original config'
grep -q 'target installer apply failed' "$TEST/apply-fail.log" || fail 'caller did not report the failed target apply'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"


# Package policy: --no-packages must not invoke the package manager even when
# the optional Papirus theme is persisted as the user's choice.
icon_test=$TEST/icon-policy
mkdir -p "$icon_test/root/usr/share/icons" "$icon_test/home"
(
  # shellcheck disable=SC2034 # read by icons_apply from the sourced installer
  ROOT=$icon_test/root HOME=$icon_test/home OS=debian packages=0 ICONS_EFFECTIVE=papirus
  install_packages() { : > "$icon_test/package-called"; }
  icons_apply > "$icon_test/log" 2>&1
)
[ ! -e "$icon_test/package-called" ] || fail 'no-packages invoked the package manager for Papirus'
grep -q 'skipping the optional icon theme' "$icon_test/log" || fail 'no-packages did not explain the skipped icon theme'


# Browser addon policy is explicit, dependency-aware and removable.
addon_test=$TEST/browser-addon
mkdir -p "$addon_test/bin" "$addon_test/state" "$addon_test/system" "$addon_test/work"
cat > "$addon_test/bin/helium" <<'EOF'
#!/bin/sh
printf 'Helium 99.9.9 (test)\n'
EOF
chmod +x "$addon_test/bin/helium"
(
  ROOT=$addon_test/system STATE=$addon_test/state BIN=$addon_test/bin WORK=$addon_test/work
  # shellcheck disable=SC2034 # read by browser_addon_apply in the sourced installer
  BROWSER_ADDON_POLICY=$addon_test/system/etc/chromium/policies/managed/nirux-bonjourr.json
  PREFIX=$addon_test/prefix
  browser_addon_apply bonjourr > "$addon_test/apply.log" 2>&1
)
policy=$addon_test/system/etc/chromium/policies/managed/nirux-bonjourr.json
[ -f "$policy" ] || fail 'browser addon policy was not written'
grep -q 'ExtensionInstallForcelist' "$policy" || fail 'browser addon policy has no force-install list'
[ -f "$addon_test/state/browser-presets/bonjourr-nirux.json" ] || fail 'Bonjourr preset was not written'
grep -q '"lang": "en"' "$addon_test/state/browser-presets/bonjourr-nirux.json" || fail 'Bonjourr preset is not English'
grep -q '"ampm": false' "$addon_test/state/browser-presets/bonjourr-nirux.json" || fail 'Bonjourr preset is not 24-hour'
grep -q '"linkgroups"' "$addon_test/state/browser-presets/bonjourr-nirux.json" || fail 'Bonjourr preset has no link group'
grep -q '"parent": "default"' "$addon_test/state/browser-presets/bonjourr-nirux.json" || fail 'Bonjourr links are not in the default group'
embedded_preset=$addon_test/embedded-bonjourr.json
awk '/cat > "\$preset\.tmp\.\$\$" <<.JSON./ {flag=1; next} /^JSON$/ {flag=0} flag' "$SOURCE/nirux" > "$embedded_preset"
[ "$(cksum < "$embedded_preset")" = "$(cksum < "$SOURCE/browser/bonjourr-nirux.json")" ] || fail 'embedded Bonjourr preset differs from the canonical file'
(
  ROOT=$addon_test/system STATE=$addon_test/state BIN=$addon_test/bin WORK=$addon_test/work
  # shellcheck disable=SC2034 # read by browser_addon_apply in the sourced installer
  BROWSER_ADDON_POLICY=$addon_test/system/etc/chromium/policies/managed/nirux-bonjourr.json
  PREFIX=$addon_test/prefix
  browser_addon_apply none >/dev/null 2>&1
)
[ ! -e "$policy" ] || fail 'browser addon policy survived removal'
rm -rf "$addon_test"

extras_test=$TEST/extras
mkdir -p "$extras_test/state" "$extras_test/home"
HOME=$extras_test/home XDG_STATE_HOME=$extras_test/state "$SOURCE/nirux" extras list > "$extras_test/list"
grep -q 'niruflow' "$extras_test/list" || fail 'extras list omitted niruflow'
grep -q 'niruorg' "$extras_test/list" || fail 'extras list omitted niruorg'
grep -q 'nirudictate' "$extras_test/list" || fail 'extras list omitted nirudictate'
# NIRUAMP installs a stale NPLAY first through a recursive call; POSIX sh has no
# locals, so the outer call must not reuse NPLAY's row afterwards (0.12.217 bug:
# NPLAY was installed twice and NIRUAMP never).
# Extras installers run with bash; minimal CI images (Void) have none.
if command -v bash >/dev/null 2>&1; then
for extra in nplay:1.0.0 niruamp:2.0.0; do
  extra_name=${extra%:*}; extra_version=${extra#*:}
  mkdir -p "$extras_test/src/$extra_name-$extra_version"
  cat > "$extras_test/src/$extra_name-$extra_version/install.sh" <<EOF
mkdir -p "\$HOME/.local/bin"
printf '#!/bin/sh\necho "$extra_name $extra_version"\n' > "\$HOME/.local/bin/$extra_name"
chmod +x "\$HOME/.local/bin/$extra_name"
echo "$extra_name" >> "\$HOME/install-order"
EOF
  tar -czf "$extras_test/$extra_name.tar.gz" -C "$extras_test/src" "$extra_name-$extra_version"
done
(
  HOME=$extras_test/home STATE=$extras_test/state
  # shellcheck disable=SC2034 # read by extras_select in the sourced installer
  EXTRAS_SELECTED=$STATE/extras-selected
  extras_fixture=$extras_test
  extras_table() {
    printf 'nplay nplay 1.0.0 %s\n' "$(sha256sum "$extras_fixture/nplay.tar.gz" | awk '{print $1}')"
    printf 'niruamp niruamp 2.0.0 %s\n' "$(sha256sum "$extras_fixture/niruamp.tar.gz" | awk '{print $1}')"
  }
  fetch() { cp "$extras_fixture/$(basename "$(dirname "$(dirname "$(dirname "$(dirname "$1")")")")").tar.gz" "$2"; }
  # shellcheck disable=SC2034 # read by extras_install_one in the sourced installer
  extras_sudo_shim() { EXTRAS_SHIM_PATH=; }
  extras_install_one niruamp >/dev/null 2>&1
) || fail 'installing NIRUAMP with a stale NPLAY failed'
[ "$(cat "$extras_test/home/install-order" 2>/dev/null | tr '\n' ' ')" = 'nplay niruamp ' ] || fail "NIRUAMP dependency install order wrong: $(cat "$extras_test/home/install-order" 2>/dev/null | tr '\n' ' ')"
grep -qx niruamp "$extras_test/state/extras-selected" || fail 'NIRUAMP was not selected after installing'
# Without a terminal the vendor installer is told that asking for the extra
# was the consent; `extras uninstall` runs the extra's own uninstaller with
# --purge passed on, then forgets the selection.
mkdir -p "$extras_test/src/nirugame-3.0.0"
cat > "$extras_test/src/nirugame-3.0.0/install.sh" <<'EOS'
mkdir -p "$HOME/.local/bin"; printf '#!/bin/sh\necho "nirugame 3.0.0"\n' > "$HOME/.local/bin/nirugame"; chmod +x "$HOME/.local/bin/nirugame"
echo "consent=${NIRUX_ASSUME_YES:-unset}" > "$HOME/consent"
EOS
cat > "$extras_test/src/nirugame-3.0.0/uninstall.sh" <<'EOS'
rm -f "$HOME/.local/bin/nirugame"; echo "args=$*" > "$HOME/uninstall-args"
EOS
tar -czf "$extras_test/nirugame.tar.gz" -C "$extras_test/src" nirugame-3.0.0
(
  HOME=$extras_test/home STATE=$extras_test/state
  # shellcheck disable=SC2034 # read by extras_select in the sourced installer
  EXTRAS_SELECTED=$STATE/extras-selected
  extras_fixture=$extras_test
  extras_table() { printf 'nirugame nirugame 3.0.0 %s\n' "$(sha256sum "$extras_fixture/nirugame.tar.gz" | awk '{print $1}')"; }
  fetch() { cp "$extras_fixture/nirugame.tar.gz" "$2"; }
  # shellcheck disable=SC2034 # read by extras_install_one in the sourced installer
  extras_sudo_shim() { EXTRAS_SHIM_PATH=; }
  extras_install_one nirugame < /dev/null >/dev/null 2>&1
  grep -qx nirugame "$EXTRAS_SELECTED"
  extras_uninstall nirugame --purge < /dev/null >/dev/null 2>&1
) || fail 'extras install/uninstall round trip failed'
[ "$(cat "$extras_test/home/consent")" = consent=1 ] || fail 'an unattended extras install did not pass NIRUX_ASSUME_YES'
[ "$(cat "$extras_test/home/uninstall-args")" = args=--purge ] || fail 'extras uninstall did not pass --purge'
[ ! -e "$extras_test/home/.local/bin/nirugame" ] || fail 'extras uninstall left the program'
if grep -qx nirugame "$extras_test/state/extras-selected"; then fail 'extras uninstall kept the selection'; fi
fi
rm -rf "$extras_test"

# Uninstall removes root-only NIRUX files (sudoers, polkit rules), never brings
# back a backed-up older NIRUX rule, restores greetd's own configuration and
# the X wrapper policy, and disables a greetd that only NIRU Login used.
un=$TEST/uninstall-root
(
  ROOT=$un PREFIX=$TEST/uninstall-prefix
  mkdir -p "$ROOT/etc/sudoers.d" "$ROOT/etc/polkit-1/rules.d" "$ROOT/etc/greetd" "$ROOT/etc/X11" \
    "$ROOT/etc/systemd/system" "$ROOT/usr/local/bin" "$ROOT/var/service"
  printf '# NIRUX owner: %s\nniru ALL=(root) NOPASSWD: /usr/libexec/nirux-wifi\n' "$PREFIX" > "$ROOT/etc/sudoers.d/49-nirux-wifi"
  printf '# NIRUX owner: %s\nniru ALL=(root) NOPASSWD: /usr/libexec/nirux-wifi\n' "$PREFIX" > "$ROOT/etc/sudoers.d/zz-nirux-wifi"
  printf '# NIRUX owner: %s\nniru ALL=(root) NOPASSWD: /old/unsafe login-wallpaper sync\n' "$PREFIX" > "$ROOT/etc/sudoers.d/49-nirux-login-wallpaper.nirux-backup"
  printf '# NIRUX owner: %s\nniru ALL=(root) NOPASSWD: /usr/bin/install x\n' "$PREFIX" > "$ROOT/etc/sudoers.d/49-nirux-login-wallpaper"
  printf 'admin rule\n' > "$ROOT/etc/sudoers.d/00_admin"
  # An orphaned backup of an older NIRUX rule (seen on a Void host).
  mkdir -p "$ROOT/etc/sudoers.d/orphan"
  printf '# NIRUX owner: %s\nold rule\n' "$PREFIX" > "$ROOT/etc/sudoers.d/orphan/rule.nirux-backup"
  remove_system "$ROOT/etc/sudoers.d/orphan/rule"
  [ ! -e "$ROOT/etc/sudoers.d/orphan/rule.nirux-backup" ] || fail 'uninstall left an orphaned NIRUX backup'
  # A rule saved from another NIRUX installation is never put back.
  printf '# NIRUX owner: %s\nniru ALL=(root) NOPASSWD: NEW\n' "$PREFIX" > "$ROOT/etc/sudoers.d/orphan/wifi"
  printf '# NIRUX owner: temporary candidate test\nniru ALL=(root) NOPASSWD: /usr/sbin/wpa_cli\n' > "$ROOT/etc/sudoers.d/orphan/wifi.nirux-backup"
  remove_system "$ROOT/etc/sudoers.d/orphan/wifi"
  if [ -e "$ROOT/etc/sudoers.d/orphan/wifi" ] || [ -e "$ROOT/etc/sudoers.d/orphan/wifi.nirux-backup" ]; then fail 'uninstall restored a rule saved from another NIRUX installation'; fi
  printf 'admin original\n' > "$ROOT/etc/sudoers.d/orphan/keep.nirux-backup"
  remove_system "$ROOT/etc/sudoers.d/orphan/keep"
  [ -f "$ROOT/etc/sudoers.d/orphan/keep.nirux-backup" ] || fail 'uninstall removed an administrator backup'
  rm -rf "$ROOT/etc/sudoers.d/orphan"
  printf '// NIRUX owner: %s\npolkit.addRule(function(){});\n' "$PREFIX" > "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules"
  printf 'polkit.addRule(function(){});\n' > "$ROOT/etc/polkit-1/rules.d/49-nirulogin-power.rules"
  printf '# NIRULOGIN owner: %s\n[default_session]\n' "$PREFIX" > "$ROOT/etc/greetd/config.toml"
  printf 'allowed_users=anybody\nneeds_root_rights=yes\n' > "$ROOT/etc/X11/Xwrapper.config"
  printf 'allowed_users=anybody\nneeds_root_rights=yes\n' > "$ROOT/etc/X11/Xwrapper.config.before-nirulogin"
  : > "$ROOT/usr/local/bin/nirulogin"
  mkdir -p "$ROOT/usr/share/nirux/greeter"; : > "$ROOT/usr/share/nirux/greeter/login.png.nirux-backup"
  ln -s /lib/systemd/system/greetd.service "$ROOT/etc/systemd/system/display-manager.service"
  printf '/lib/systemd/system/greetd.service\n' > "$ROOT/etc/nirulogin-previous-display-manager"
  ln -s /etc/sv/greetd "$ROOT/var/service/greetd"
  remove_greeters > "$TEST/uninstall-greeters.log"
  for f in sudoers.d/49-nirux-wifi sudoers.d/zz-nirux-wifi sudoers.d/49-nirux-login-wallpaper sudoers.d/49-nirux-login-wallpaper.nirux-backup \
    polkit-1/rules.d/49-nirux-power.rules polkit-1/rules.d/49-nirulogin-power.rules greetd/config.toml \
    X11/Xwrapper.config X11/Xwrapper.config.before-nirulogin systemd/system/display-manager.service nirulogin-previous-display-manager; do
    if [ -e "$ROOT/etc/$f" ] || [ -L "$ROOT/etc/$f" ]; then fail "uninstall left /etc/$f"; fi
  done
  [ -f "$ROOT/etc/sudoers.d/00_admin" ] || fail 'uninstall removed an administrator sudoers rule'
  [ ! -e "$ROOT/usr/share/nirux" ] || fail 'uninstall left /usr/share/nirux with a saved greeter picture'
  [ ! -L "$ROOT/var/service/greetd" ] || fail 'uninstall left greetd enabled on runit without a configuration'
  grep -q 'greetd disabled' "$TEST/uninstall-greeters.log" || fail 'uninstall did not say that greetd was disabled'
  # A greetd configured before NIRU Login gets its configuration back and stays enabled.
  printf '# NIRULOGIN owner: %s\n' "$PREFIX" > "$ROOT/etc/greetd/config.toml"
  printf '[default_session]\ncommand = "agreety --cmd /bin/sh"\n' > "$ROOT/etc/greetd/config.toml.before-nirulogin"
  cp "$ROOT/etc/greetd/config.toml.before-nirulogin" "$ROOT/etc/greetd/config.toml.nirux-backup"
  printf '# NIRUX owner: %s\nallowed_users=anybody\nneeds_root_rights=yes\n' "$PREFIX" > "$ROOT/etc/X11/Xwrapper.config"
  printf 'allowed_users=console\n' > "$ROOT/etc/X11/Xwrapper.config.before-nirulogin"
  ln -s /lib/systemd/system/greetd.service "$ROOT/etc/systemd/system/display-manager.service"
  remove_greeters >/dev/null
  grep -q agreety "$ROOT/etc/greetd/config.toml" || fail 'uninstall did not restore the previous greetd configuration'
  [ ! -e "$ROOT/etc/greetd/config.toml.nirux-backup" ] || fail 'uninstall left a duplicate greetd backup'
  [ -L "$ROOT/etc/systemd/system/display-manager.service" ] || fail 'uninstall disabled a greetd that had its own configuration'
  [ "$(cat "$ROOT/etc/X11/Xwrapper.config")" = allowed_users=console ] || fail 'uninstall did not restore the X wrapper policy'
) || fail 'uninstall cleanup checks failed'
rm -rf "$un"

# NIRU Login: a greetd home left behind by a purged package (old greeter uid)
# is handed to the current greeter account, so startx/xauth can write there.
gl=$TEST/greeter-home
(
  ROOT=$gl/root WORK=$gl/work OS=debian PREFIX=$TEST/greeter-prefix
  mkdir -p "$WORK/generation/bin" "$ROOT/var/lib/greetd" "$ROOT/etc/systemd/system" "$ROOT/lib/systemd/system" "$ROOT/usr/local/bin"
  printf '#!/bin/sh\n' > "$WORK/generation/bin/nirulogin"; chmod +x "$WORK/generation/bin/nirulogin"
  getent() { [ "$1 $2" = "passwd _greetd" ]; }
  id() { case "$1" in -u) echo 4242 ;; -gn) echo _greetd ;; *) command id "$@" ;; esac; }
  chown() { printf '%s\n' "$*" >> "$gl/chown.log"; }
  # shellcheck disable=SC2086 # test paths have no spaces
  install() { args=; while [ "$#" -gt 0 ]; do case "$1" in -o|-g) shift 2 ;; *) args="$args $1"; shift ;; esac; done; command install $args; }
  install_nirulogin >/dev/null
  grep -qx -- "-R _greetd:_greetd $ROOT/var/lib/greetd" "$gl/chown.log"
) || fail 'NIRU Login did not hand a stale greetd home to the current greeter account'
rm -rf "$gl"

# Unattended without a password: the extras get a sudo that refuses at once
# instead of real sudo failing (and counting toward pam_faillock) per call.
if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" != 0 ]; then
  shim=$TEST/shim-test
  mkdir -p "$shim"
  (
    # shellcheck disable=SC2034 # read by the sourced installer
    SUDO_SECRET=''
    # shellcheck disable=SC2034 # read by the sourced installer
    SUDO_SECRET_FILE=''
    extras_sudo_shim "$shim" < /dev/null
    [ "$EXTRAS_SHIM_PATH" = "$shim/.sudo:" ]
  ) || fail 'no refusing sudo for an unattended extra without a password'
  grep -q 'no terminal to ask for the password' "$shim/.sudo/sudo" || fail 'refusing sudo has no explanation'
  rm -rf "$shim"
fi

# I07: a new shared-library dependency is provisioned before staged components
# are executed. The synthetic component fails its version check without it.
TEST_OS=debian; PREFIX=$TEST/libdep; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
mkdir -p "$TEST/pkgbin"
cat > "$TEST/pkgbin/sudo" <<'EOF'
#!/bin/sh
[ "$1" = "-n" ] && shift
[ "$1" = "true" ] && exit 0
exec "$@"
EOF
cat > "$TEST/pkgbin/dpkg-query" <<'EOF'
#!/bin/sh
name=
for arg in "$@"; do name=$arg; done
[ "$name" = fake-lib ] && exit 1
printf 'install ok installed\n'
EOF
cat > "$TEST/pkgbin/apt-get" <<'EOF'
#!/bin/sh
[ -n "$LIB_MARKER" ] || exit 1
touch "$LIB_MARKER"
EOF
chmod +x "$TEST/pkgbin/sudo" "$TEST/pkgbin/dpkg-query" "$TEST/pkgbin/apt-get"
LIB_MARKER=$TEST/lib-marker
rm -f "$LIB_MARKER"
export LIB_MARKER
saved_path=$PATH
PATH="$TEST/pkgbin:$PATH"
set +e
(set -e; install_or_update update --release 99.3.0) > "$TEST/libdep.log" 2>&1
rc=$?
set -e
PATH=$saved_path
unset LIB_MARKER
[ "$rc" = 0 ] || { cat "$TEST/libdep.log" >&2; fail 'missing-library update failed'; }
[ -f "$TEST/lib-marker" ] || fail 'new package dependency was not provisioned'
[ -x "$BIN/nirulib" ] || fail 'shared-library-dependent component was not linked'
grep -q 'Staged components. Validating generation' "$TEST/libdep.log" || fail 'target installer handoff was not used for the dependency case'
grep -q 'Installing missing debian packages: fake-lib' "$TEST/libdep.log" || fail 'missing dependency was not provisioned before staging'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"

# A rejected config migration must not switch the active generation.
TEST_OS=arch; PREFIX=$TEST/config-reject; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
before=$(readlink "$STATE/current")
mkdir -p "$XDG_CONFIG_HOME/niruwm"
cat > "$XDG_CONFIG_HOME/niruwm/config.toml" <<'EOF'
theme = "niru-noir"
[bar]
enabled = true
[bar]
tray = true
EOF
config_sum=$(sha256sum "$XDG_CONFIG_HOME/niruwm/config.toml" | cut -d' ' -f1)
set +e
(set -e; install_or_update update --no-packages --release 99.0.0) > "$TEST/config-reject.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'unsafe config migration update succeeded'
[ "$(readlink "$STATE/current")" = "$before" ] || fail 'rejected config changed the active generation'
[ "$(sha256sum "$XDG_CONFIG_HOME/niruwm/config.toml" | cut -d' ' -f1)" = "$config_sum" ] || fail 'rejected config changed the user file'
grep -q 'duplicate table' "$TEST/config-reject.log" || fail 'rejected config was not diagnosed'
no_config_candidates "$XDG_CONFIG_HOME/niruwm" || fail 'rejected config left a candidate'
operation uninstall --purge >/dev/null 2>&1 || :

# A corrupt late download must leave the active installation unchanged.
TEST_OS=arch; PREFIX=$TEST/failure; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --browser none --display-manager startx --release "$VERSION"
before=$(readlink "$STATE/current")
say corrupt >> "$FIXTURE/nirulock/$lock_version/nirulock"
set +e
(set -e; install_or_update update --no-packages --release 99.0.0) > "$TEST/failure.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'corrupt download succeeded'
[ "$(readlink "$STATE/current")" = "$before" ] || fail 'failed download changed current'
grep -q 'checksum mismatch' "$TEST/failure.log" || fail 'checksum failure was not diagnosed'

# Missing PAM includes must be visible in diagnostics.
rm "$ROOT/etc/pam.d/system-auth"
if check_pam; then fail 'missing PAM include accepted'; fi
for os in arch debian void; do
  case "$(packages_for "$os")" in *xidlehook*) fail 'obsolete mandatory xidlehook' ;; esac
done
(DM=auto; existing_dm() { say lightdm; }; choose_dm; [ "$DM" = keep ]) || fail 'existing display manager was not kept'
for default_os in arch debian void; do TEST_OS=$default_os; OS=$default_os; (DM=auto; existing_dm() { :; }; choose_dm </dev/null; [ "$DM" = nirulogin ]) || fail "noninteractive $default_os default is not nirulogin"; done
# Sudo validation can succeed while the privileged command fails. Preserve
# that command's error status (the old implementation incorrectly returned 0).
set +e
NIRUX_LIBRARY=1 NIRUX_TEST_AS_ROOT=0 sh -c '
  . "$1"
  id() { printf "1000\n"; }
  sudo() { case "$*" in "-n id -u"*) return 0 ;; *) return 7 ;; esac; }
  as_root false
' test "$SOURCE/nirux"
rc=$?
set -e
[ "$rc" = 7 ] || fail "sudo error was lost: $rc"

# A configured program that is not installed must be visible and fail doctor.
doctor_dir=$TEST/doctor
mkdir -p "$doctor_dir/bin"
cat > "$doctor_dir/bin/niruwm" <<'EOF'
#!/bin/sh
if [ "$1" = --dump-config ]; then
  printf 'browser = ["missing-browser-for-test"]\n'
  exit 0
fi
echo 'NIRUWM 0.0.0'
EOF
chmod +x "$doctor_dir/bin/niruwm"
set +e
(
  BIN=$doctor_dir/bin PREFIX=$doctor_dir STATE=$doctor_dir/share/nirux
  doctor
) > "$doctor_dir/doctor.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'doctor succeeded with a missing configured program'
grep -q 'missing configured missing-browser-for-test' "$doctor_dir/doctor.log" || fail 'missing configured program was not reported'

# doctor --fix: offers are collected once each, listed, and applied only with
# --yes or a confirmed terminal; session helpers start detached.
fix_dir=$TEST/doctor-fix
mkdir -p "$fix_dir/bin"
cat > "$fix_dir/bin/niructl" <<EOF
#!/bin/sh
printf '%s\n' "niructl \$*" >> "$fix_dir/calls"
EOF
chmod +x "$fix_dir/bin/niructl"
set +e
(
  BIN=$fix_dir/bin
  doctor_spawn() { printf 'spawn %s\n' "$*" >> "$fix_dir/calls"; }
  DOCTOR_FIXES=
  doctor_offer bar
  doctor_offer nightlight
  doctor_offer bar
  [ "$DOCTOR_FIXES" = 'bar nightlight' ] || { echo "offers: $DOCTOR_FIXES"; exit 9; }
  DOCTOR_YES=1
  doctor_apply_fixes
) > "$fix_dir/fix.log" 2>&1
rc=$?
set -e
[ "$rc" = 0 ] || { cat "$fix_dir/fix.log"; fail "doctor --fix failed: $rc"; }
grep -qx "niructl restart-bar" "$fix_dir/calls" || fail 'doctor --fix did not restart the bar'
grep -qx "spawn $fix_dir/bin/niructl nightlight watch" "$fix_dir/calls" || fail 'doctor --fix did not start the night-light watcher'
grep -q 'fixed: restart NIRUBAR' "$fix_dir/fix.log" || fail 'doctor --fix did not report its fix'
# Without a terminal and without --yes nothing is changed.
rm -f "$fix_dir/calls"
set +e
(
  BIN=$fix_dir/bin
  # shellcheck disable=SC2034 # read by doctor_apply_fixes
  DOCTOR_FIXES=bar DOCTOR_YES=0
  doctor_apply_fixes
) < /dev/null > "$fix_dir/noyes.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'doctor --fix ran without confirmation'
[ ! -e "$fix_dir/calls" ] || fail 'doctor --fix changed something without confirmation'
grep -q 'needs a terminal to confirm, or --yes' "$fix_dir/noyes.log" || fail 'doctor --fix did not explain --yes'
# --yes alone is refused, and an unknown option too.
( doctor --yes ) >/dev/null 2>&1 && fail 'doctor accepted --yes without --fix'
( doctor --frobnicate ) >/dev/null 2>&1 && fail 'doctor accepted an unknown option'
# A supported but unwritable charge limit is offered as the battery fix.
( export NIRUX_TEST_BATTERY=1 NIRUX_TEST_BATTERY_WRITABLE=0; doctor_battery_writable ) && fail 'unwritable battery limit reported as writable'
( export NIRUX_TEST_BATTERY_WRITABLE=1; doctor_battery_writable ) || fail 'writable battery limit reported as unwritable'

# S02: managed Helium policy, download verification, version replacement,
# corrupt-download preservation and owned opt-out removal. The archive is a
# synthetic fixture with a matching temporary checksum; no browser is launched.
browser_test=$TEST/browser
PREFIX=$browser_test/prefix; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
WORK=$browser_test/work; XDG_CONFIG_HOME=$browser_test/config
mkdir -p "$BIN" "$STATE" "$WORK" "$XDG_CONFIG_HOME"
BROWSER_EFFECTIVE=helium
browser_unmanaged() { return 1; }
make_helium_archive() {
  version=$1; archive=$2
  build=$TEST/helium-build-$version
  rm -rf "$build"
  mkdir -p "$build/helium-$version-x86_64_linux"
  cat > "$build/helium-$version-x86_64_linux/helium" <<EOF
#!/bin/sh
if [ "\$1" = --version ]; then printf 'Helium $version (test)\\n'; fi
exit 0
EOF
  chmod +x "$build/helium-$version-x86_64_linux/helium"
  : > "$build/helium-$version-x86_64_linux/product_logo_256.png"
  printf '%s\n' '[Desktop Entry]' 'Name=Helium' 'Type=Application' 'Exec=helium %U' 'Icon=helium' \
    > "$build/helium-$version-x86_64_linux/helium.desktop"
  tar -cJf "$archive" -C "$build" "helium-$version-x86_64_linux"
}
FAKE_ARCHIVE=
FETCHES=0
fetch() { cp "$FAKE_ARCHIVE" "$2"; FETCHES=$((FETCHES + 1)); }
HELIUM_VERSION=99.9.9
make_helium_archive "$HELIUM_VERSION" "$TEST/helium-99.9.9.tar.xz"
FAKE_ARCHIVE=$TEST/helium-99.9.9.tar.xz
# shellcheck disable=SC2034 # read by browser_install_archive in the sourced installer
HELIUM_SHA256=$(sha256sum "$FAKE_ARCHIVE" | cut -d' ' -f1)
browser_policy_set helium
browser_install > "$browser_test/install-first.log" 2>&1 || { cat "$browser_test/install-first.log" >&2; fail 'managed Helium install failed'; }
[ -x "$BIN/helium" ] || fail 'Helium front link was not created'
[ "$("$BIN/helium" --version)" = 'Helium 99.9.9 (test)' ] || fail 'installed Helium version is wrong'
browser_launcher_owned "$BIN/helium" || fail 'Helium launcher is not owned by NIRUX'
grep -qF "exec '$STATE/browser-current/helium'" "$BIN/helium" || fail 'Helium launcher does not start the managed browser state'
desktop=$PREFIX/share/applications/helium.desktop
grep -qF "Exec=\"$BIN/helium\"" "$desktop" || fail 'Helium desktop entry does not use the managed command'
browser_install > "$browser_test/install-second.log" 2>&1 || fail 'reusing the installed Helium failed'
[ "$FETCHES" = 1 ] || fail 'an unchanged Helium version was downloaded again'
HELIUM_VERSION=99.9.10
make_helium_archive "$HELIUM_VERSION" "$TEST/helium-99.9.10.tar.xz"
FAKE_ARCHIVE=$TEST/helium-99.9.10.tar.xz
# shellcheck disable=SC2034 # read by browser_install_archive in the sourced installer
HELIUM_SHA256=$(sha256sum "$FAKE_ARCHIVE" | cut -d' ' -f1)
browser_install > "$browser_test/install-update.log" 2>&1 || fail 'Helium update failed'
[ "$("$BIN/helium" --version)" = 'Helium 99.9.10 (test)' ] || fail 'Helium update did not activate the new version'
[ ! -e "$STATE/browsers/helium-99.9.9" ] || fail 'old Helium version was not removed'
HELIUM_VERSION=99.9.11
cp "$TEST/helium-99.9.10.tar.xz" "$TEST/helium-corrupt.tar.xz"
printf 'corrupt\n' >> "$TEST/helium-corrupt.tar.xz"
FAKE_ARCHIVE=$TEST/helium-corrupt.tar.xz
# shellcheck disable=SC2034 # read by browser_install_archive in the sourced installer
HELIUM_SHA256=$(sha256sum "$TEST/helium-99.9.10.tar.xz" | cut -d' ' -f1)
set +e
( browser_install ) > "$browser_test/install-corrupt.log" 2>&1
rc=$?
set -e
[ "$rc" != 0 ] || fail 'corrupt Helium download succeeded'
grep -q 'checksum mismatch' "$browser_test/install-corrupt.log" || fail 'corrupt Helium download was not diagnosed'
[ "$("$BIN/helium" --version)" = 'Helium 99.9.10 (test)' ] || fail 'corrupt download replaced the active browser'
mkdir -p "$XDG_CONFIG_HOME/net.imput.helium"
say 'keep my profile' > "$XDG_CONFIG_HOME/net.imput.helium/Preferences"
# shellcheck disable=SC2034 # read by browser_remove_managed in the sourced installer
BROWSER_EFFECTIVE=none
browser_remove_managed
[ ! -e "$BIN/helium" ] || fail 'owned browser link survived opt-out removal'
[ ! -e "$desktop" ] || fail 'owned browser desktop entry survived opt-out removal'
[ "$(cat "$XDG_CONFIG_HOME/net.imput.helium/Preferences")" = 'keep my profile' ] || fail 'browser profile was removed'
mkdir -p "$browser_test/migrate"
printf 'theme = "niru-noir"\nbrowser = ["brave"]\n' > "$browser_test/migrate/brave.toml"
# shellcheck disable=SC2034 # read by upgrade_obsolete_default_browser in the sourced installer
BROWSER_EFFECTIVE=helium
browser_available() { return 1; }
upgrade_obsolete_default_browser "$browser_test/migrate/brave.toml"
grep -qx 'browser = \["helium"\]' "$browser_test/migrate/brave.toml" || fail 'obsolete default brave browser was not migrated'
printf 'theme = "niru-noir"\nbrowser = ["firefox"]\n' > "$browser_test/migrate/custom.toml"
upgrade_obsolete_default_browser "$browser_test/migrate/custom.toml"
grep -qx 'browser = \["firefox"\]' "$browser_test/migrate/custom.toml" || fail 'custom browser selection was overwritten'
# shellcheck disable=SC2034 # read by fresh_config_source in the sourced installer
BROWSER_EFFECTIVE=none
fresh_config_source "$SOURCE/config.example.toml" | grep -qx 'browser = \[\]' || fail 'fresh opt-out config kept the Helium default'
# shellcheck disable=SC2034 # read by fresh_config_source in the sourced installer
BROWSER_EFFECTIVE=helium
fresh_config_source "$SOURCE/config.example.toml" | grep -qx 'browser = \["helium"\]' || fail 'fresh default config does not select Helium'
# Theme wallpapers: updates replace untouched NIRUX files, never a user edit,
# and purge removes only the unmodified owned copies.
wallpaper_test=$TEST/wallpapers
HOME=$wallpaper_test/home
XDG_PICTURES_DIR=$wallpaper_test/pictures
WORK=$wallpaper_test/work
STATE=$wallpaper_test/state
mkdir -p "$HOME" "$XDG_PICTURES_DIR" "$WORK/download/nirux" "$STATE" "$wallpaper_test/build/wallpaper"
printf '\211PNG\r\n\032\nfirst\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
printf '\211PNG\r\n\032\nfirst\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-nord-4k.png"
printf '\211PNG\r\n\032\nold\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-old-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
wallpaper_dir=$XDG_PICTURES_DIR/Wallpapers/NIRU
is_png "$wallpaper_dir/nirux-wallpaper-noir-4k.png" || fail 'theme wallpaper was not installed'
# A new default-theme image in a later release must replace the installed one:
# that is how a redesigned noir wallpaper reaches a machine. Do this while the
# file is still unmodified, before the edit below makes it the user's.
printf '\211PNG\r\n\032\nredesigned\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
grep -q redesigned "$wallpaper_dir/nirux-wallpaper-noir-4k.png" ||
  fail 'a new default-theme wallpaper did not replace the owned one'
printf '\211PNG\r\n\032\nfirst\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
printf 'mine\n' > "$wallpaper_dir/nirux-wallpaper-noir-4k.png"
printf '\211PNG\r\n\032\nsecond\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
printf '\211PNG\r\n\032\nsecond\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-nord-4k.png"
rm -f "$wallpaper_test/build/wallpaper/nirux-wallpaper-old-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = mine ] || fail 'user-modified wallpaper was overwritten'
is_png "$wallpaper_dir/nirux-wallpaper-nord-4k.png" || fail 'unmodified owned wallpaper was not updated'
grep -q second "$wallpaper_dir/nirux-wallpaper-nord-4k.png" || fail 'unmodified owned wallpaper content was not updated'
[ ! -e "$wallpaper_dir/nirux-wallpaper-old-4k.png" ] || fail 'superseded owned wallpaper was not removed'
# A theme installed with `nirux wallpapers download` is still owned and still
# wanted. An update ships only the default theme, so it must not delete the rest.
printf '\211PNG\r\n\032\ndownloaded\n' > "$wallpaper_dir/nirux-wallpaper-satie-4k.png"
printf '%s  %s\n' "$(sha256sum "$wallpaper_dir/nirux-wallpaper-satie-4k.png" | cut -d ' ' -f1)" \
  nirux-wallpaper-satie-4k.png >> "$STATE/wallpapers.sha256"
install_wallpapers >/dev/null
[ -e "$wallpaper_dir/nirux-wallpaper-satie-4k.png" ] ||
  fail 'an update removed a downloaded theme wallpaper'
grep -q 'nirux-wallpaper-satie-4k.png' "$STATE/wallpapers.sha256" ||
  fail 'an update dropped a downloaded theme from the manifest'
# The NIRUX Signature pictures (`nirux wallpapers download signature`) too.
printf '\211PNG\r\n\032\nsignature\n' > "$wallpaper_dir/nirux-wallpaper-signature-nord-4k.png"
printf '%s  %s\n' "$(sha256sum "$wallpaper_dir/nirux-wallpaper-signature-nord-4k.png" | cut -d ' ' -f1)" \
  nirux-wallpaper-signature-nord-4k.png >> "$STATE/wallpapers.sha256"
install_wallpapers >/dev/null
[ -e "$wallpaper_dir/nirux-wallpaper-signature-nord-4k.png" ] ||
  fail 'an update removed a downloaded Signature wallpaper'
# The optional Carl Larsson and Erik Satie colour packs must survive a normal
# release update that only ships the default theme.
for extra_pack in carl-larsson satie; do
  for extra_colour in red blue green noir; do
    for extra_size in 4k 8k; do
      extra_name=nirux-wallpaper-$extra_pack-$extra_colour-$extra_size.png
      printf '\211PNG\r\n\032\ndownloaded\n' > "$wallpaper_dir/$extra_name"
      printf '%s  %s\n' "$(sha256sum "$wallpaper_dir/$extra_name" | cut -d ' ' -f1)" \
        "$extra_name" >> "$STATE/wallpapers.sha256"
    done
  done
done
[ "$(wallpaper_extra_count)" = 16 ] || fail 'extra wallpaper count was wrong'
install_wallpapers >/dev/null
for extra_pack in carl-larsson satie; do
  for extra_colour in red blue green noir; do
    for extra_size in 4k 8k; do
      extra_name=nirux-wallpaper-$extra_pack-$extra_colour-$extra_size.png
      [ -f "$wallpaper_dir/$extra_name" ] ||
        fail "an update removed $extra_name"
    done
  done
done
# `nirux layout` reaches NIRUWM's display profiles and refuses a partial call.
# Run in a subshell so a `die` inside the sourced installer ends only this
# call, not the test run.
expect_layout_failure() {
  actual=0
  ( layout "$@" >/dev/null 2>&1 ) || actual=$?
  [ "$actual" = 1 ] || fail "expected layout to refuse '$*', got $actual"
}
layout_test=$TEST/layout
mkdir -p "$layout_test"
cat > "$layout_test/niructl" <<EOF
#!/bin/sh
printf '%s\\n' "\$*" >> "$layout_test/log"
EOF
chmod 755 "$layout_test/niructl"
BIN=$layout_test
expect_layout_failure save
expect_layout_failure apply
expect_layout_failure rotate HDMI-1
expect_layout_failure turns
layout save Desk >/dev/null
layout rotate DisplayPort-5 inverted >/dev/null
layout apply Desk >/dev/null
layout auto >/dev/null
printf '%s\n' 'display save Desk' 'display rotate DisplayPort-5 inverted' \
  'display apply Desk' 'display auto' > "$layout_test/expected"
if [ "$(cat "$layout_test/log")" != "$(cat "$layout_test/expected")" ]; then
  cat "$layout_test/log" >&2
  fail 'nirux layout did not pass the call through'
fi

remove_owned_wallpapers
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = mine ] || fail 'purge removed a user-modified wallpaper'
[ ! -e "$wallpaper_dir/nirux-wallpaper-nord-4k.png" ] || fail 'purge kept an unmodified owned wallpaper'

# The theme wallpaper question belongs to the terminal that started the
# command. It is asked when the set is incomplete and never when it is there.
rm -rf "$wallpaper_dir"
mkdir -p "$wallpaper_dir"
rm -f "$STATE/wallpaper-bundle-policy"
# A fresh unattended install gets the complete set by default.
# shellcheck disable=SC2034 # read by wallpaper_bundle_decision
operation=install
unset NIRUX_WALLPAPERS
wallpaper_bundle_decision </dev/null
[ "$wp_decision" = all ] ||
  fail 'an unattended install did not choose the complete wallpaper set'
# shellcheck disable=SC2034 # read by wallpaper_bundle_decision
operation=update
# stdin is not a terminal in the test run, so nothing is asked for a default
# policy.
wallpaper_bundle_decision
[ -z "$wp_decision" ] || fail 'an update asked about wallpapers without a terminal'
# A terminal is only asked when a theme is missing its wallpaper.
printf 'y\n' > "$TEST/answer"
if [ -t 0 ]; then
  wallpaper_bundle_decision < "$TEST/answer"
  [ "$wp_decision" = all ] ||
    fail 'an incomplete update did not offer the wallpaper set'
fi
# An unattended run states its answer instead of being asked.
# shellcheck disable=SC2034 # read by wallpaper_bundle_decision
NIRUX_WALLPAPERS=all
wallpaper_bundle_decision < /dev/null
[ "$wp_decision" = all ] ||
  fail 'an explicit wallpaper choice was not carried'
# shellcheck disable=SC2034 # read by wallpaper_bundle_decision
NIRUX_WALLPAPERS=none
wallpaper_bundle_decision < /dev/null
[ "$wp_decision" = default ] ||
  fail 'an explicit opt-out did not record the default set'
unset NIRUX_WALLPAPERS
for wp_theme in $WALLPAPER_THEMES; do
  printf '\211PNG\r\n\032\n%s\n' "$wp_theme" > "$wallpaper_dir/nirux-wallpaper-$wp_theme-4k.png"
done
wallpaper_bundle_decision < "$TEST/answer" 2>/dev/null
[ -z "$wp_decision" ] ||
  fail 'a complete set was offered again on update'
# The target records the answer the running installer worked out.
# shellcheck disable=SC2034 # read by wallpapers_policy_write
wp_persisted=all
wallpapers_policy_write
grep -qx 'wallpapers all' "$STATE/wallpaper-bundle-policy" || fail 'wallpaper answer was not recorded'
wallpapers_policy_read
[ "$wp_persisted" = all ] || fail 'the recorded answer was not read back'
# Without a policy file nothing is remembered, so the next install asks.
rm -f "$STATE/wallpaper-bundle-policy"
wallpapers_policy_read
[ -z "$wp_persisted" ] || fail 'a missing policy file was read as an answer'

# Terminal integration preserves existing kitty/fish config: one managed block,
# idempotent updates, and block-only removal on uninstall.
terminal_test=$TEST/terminal-home
HOME=$terminal_test
XDG_CONFIG_HOME=$terminal_test/.config
PREFIX=$terminal_test/.local
BIN=$PREFIX/bin
STATE=$PREFIX/share/nirux
CONFDIR=$XDG_CONFIG_HOME/niruwm
WORK=$terminal_test/work
mkdir -p "$HOME/.config/kitty" "$HOME/.config/fish" "$CONFDIR" "$BIN" "$STATE" "$WORK/download/nirux"
printf 'font_size 13\n' > "$XDG_CONFIG_HOME/kitty/kitty.conf"
printf 'set -g fish_greeting "hi"\n' > "$XDG_CONFIG_HOME/fish/config.fish"
printf 'theme = "niru-nord"\n' > "$CONFDIR/config.toml"
( cd "$SOURCE" && tar -cJf "$WORK/download/nirux/nirux-terminal.tar.xz" terminal )
install_terminal >/dev/null
grep -qx 'font_size 13' "$XDG_CONFIG_HOME/kitty/kitty.conf" || fail 'existing kitty setting was removed'
grep -q '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/kitty/kitty.conf" || fail 'kitty integration block was not added'
grep -q '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'fish integration block was not added'
grep -q 'fish_greeting "hi"' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'existing fish setting was removed'
[ -f "$XDG_CONFIG_HOME/kitty/kitty.conf.nirux-backup" ] || fail 'kitty config was not backed up'
[ -f "$XDG_CONFIG_HOME/fish/config.fish.nirux-backup" ] || fail 'fish config was not backed up'
install_terminal >/dev/null
[ "$(grep -c '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/kitty/kitty.conf")" = 1 ] || fail 'kitty integration block was duplicated'
[ "$(grep -c '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/fish/config.fish")" = 1 ] || fail 'fish integration block was duplicated'
remove_terminal
grep -qx 'font_size 13' "$XDG_CONFIG_HOME/kitty/kitty.conf" || fail 'uninstall removed a user kitty setting'
grep -q 'fish_greeting "hi"' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'uninstall removed a user fish setting'
! grep -q '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/kitty/kitty.conf" || fail 'uninstall left the kitty block'
! grep -q '^# NIRUX terminal integration (managed)$' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'uninstall left the fish block'
[ ! -e "$XDG_CONFIG_HOME/nirux" ] || fail 'uninstall left NIRUX terminal config'

# The old appearance example hardcoded Noir colours and made every built-in
# theme look Noir in the bar. It is migrated only when all old defaults match.
appearance_test=$TEST/appearance
mkdir -p "$appearance_test"
cat > "$appearance_test/old.toml" <<'EOF'
schema = 1
[colors]
background = "0f0f10"
surface = "161618"
foreground = "e5e5e5"
muted = "a8a8a8"
border = "2a2a2d"
focus = "5a5a60"
accent = "5a5a60"
selected = "26262a"
success = "8fbf7f"
warning = "d7b36a"
error = "d77a7a"
disabled = "5a5a5e"
[font]
size = 15.0
EOF
migrate_appearance_defaults "$appearance_test/old.toml" >/dev/null
! grep -q '^\[colors\]' "$appearance_test/old.toml" || fail 'old Noir appearance defaults were not migrated'
grep -qx 'size = 15.0' "$appearance_test/old.toml" || fail 'appearance migration removed typography'
cat > "$appearance_test/custom.toml" <<'EOF'
schema = 1
[colors]
background = "101010"
surface = "161618"
foreground = "e5e5e5"
muted = "a8a8a8"
border = "2a2a2d"
focus = "5a5a60"
accent = "5a5a60"
selected = "26262a"
success = "8fbf7f"
warning = "d7b36a"
error = "d77a7a"
disabled = "5a5a5e"
EOF
migrate_appearance_defaults "$appearance_test/custom.toml" >/dev/null
grep -qx 'background = "101010"' "$appearance_test/custom.toml" || fail 'custom appearance colour was removed'

# Greeter integration and the power polkit rule are installed from the
# target-owned archive. Verify both display-manager themes and owned removal
# without touching the host system.
(
  saved_root=$ROOT
  saved_work=$WORK
  ROOT=$TEST/greeter-root
  WORK=$TEST/greeter-work
  rm -rf "$ROOT" "$WORK"
  mkdir -p "$WORK/download/nirux"
  cp "$FIXTURE/nirux/$VERSION/nirux-integration.tar.xz" "$WORK/download/nirux/"
  sddm_qt_version() { say 5; }
  install_greeters sddm
  grep -qx 'QtVersion=5' "$ROOT/usr/share/sddm/themes/nirux/metadata.desktop" || fail 'Qt5 SDDM metadata missing'
  sddm_qt_version() { say 6; }
  install_greeters sddm
  grep -qx 'QtVersion=6' "$ROOT/usr/share/sddm/themes/nirux/metadata.desktop" || fail 'Qt6 SDDM metadata missing'
  [ -f "$ROOT/usr/share/sddm/themes/nirux/Main.qml" ] || fail 'missing SDDM QML theme'
  grep -q '^// NIRUX owner: ' "$ROOT/usr/share/sddm/themes/nirux/Main.qml" || fail 'SDDM theme is not owned'
  # The login screen shows the session NIRUX preselects, not an older one.
  grep -q 'var preferred = "NIRUWM"' "$ROOT/usr/share/sddm/themes/nirux/Main.qml" ||
    fail 'SDDM theme does not preselect NIRUWM'
  # sudoers.d is closed to the user: an unchanged rule is compared by root,
  # so a second install does not print a permission error.
  sudoers=$ROOT/etc/sudoers.d/49-nirux-login-wallpaper
  [ -f "$sudoers" ] || fail 'login wallpaper rule missing'
  chmod 0440 "$sudoers"
  # The rule may only name a program root can trust. Earlier releases granted
  # `NOPASSWD: <prefix>/nirux ...`, and that prefix belongs to the user, so the
  # user could replace the program and have root run it. The grant must name
  # /usr/bin/install with exact arguments instead.
  if grep -q 'login-wallpaper sync' "$sudoers"; then
    fail 'the unsafe login-wallpaper grant from an earlier release is still installed'
  fi
  grep -v '^#' "$sudoers" | grep -q 'login-wallpaper' &&
    fail 'rule mentions the removed subcommand'
  grep -v '^#' "$sudoers" | grep -v '^[[:space:]]*$' |
    grep -qv "/usr/bin/install" &&
    fail 'login wallpaper rule names something other than /usr/bin/install'
  grep -q "/usr/bin/install -m 644 -o root -g root /tmp/nirux-login-background.png /usr/share/sddm/themes/nirux/background.png" "$sudoers" ||
    fail 'login wallpaper rule does not name the SDDM picture exactly'
  # Nothing in the rule may point into the user's own installation.
  [ "$(grep -v '^#' "$sudoers" | grep -c "$BIN")" = 0 ] ||
    fail 'login wallpaper rule names the user installation'
  [ "$(stat -c %a "$sudoers")" = 440 ] || fail 'login wallpaper rule must be mode 0440'
  grep -qx 'Current=nirux' "$ROOT/etc/sddm.conf.d/50-nirux.conf" || fail 'SDDM theme was not selected'
  grep -q 'subject.isInGroup("wheel")' "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules" || fail 'missing power polkit rule'
  grep -Fq "subject.user == \"$(id -un)\"" "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules" || fail 'power rule does not trust the installing account'
  [ -f "$ROOT/usr/share/sddm/themes/nirux/background.png" ] || fail 'missing SDDM background'
  install_greeters lightdm
  [ -f "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" ] || fail 'missing LightDM greeter config'
  [ -f "$ROOT/usr/share/themes/NIRU/gtk-3.0/gtk.css" ] || fail 'missing NIRU GTK theme'
  [ -f "$ROOT/usr/share/nirux/greeter/login.png" ] || fail 'missing LightDM background'
  grep -qx 'background=/usr/share/nirux/greeter/login.png' "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" || fail 'LightDM background path is wrong'
  grep -qx 'position=50%,center 68%,center' "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" || fail 'LightDM login window is not centred at 68%'
  ! grep -q '~clock' "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" || fail 'LightDM still shows the off-centre panel clock'
  remove_greeters
  [ ! -e "$ROOT/usr/share/sddm/themes/nirux" ] || fail 'greeter removal left the SDDM theme'
  [ ! -e "$ROOT/usr/share/themes/NIRU" ] || fail 'greeter removal left the GTK theme'
  [ ! -e "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules" ] || fail 'greeter removal left the power rule'
  ROOT=$saved_root
  WORK=$saved_work
)

# A release that has the wallpaper program but not its launcher entry and icon
# must still install. The assets were added after the program, so an older
# release legitimately lacks them and the installer must not refuse it.
(
  PREFIX=$TEST/no-desktop-app; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
  # A private system root: the shared one already holds the entry from the
  # earlier installs, which would make this check meaningless.
  ROOT=$TEST/no-desktop-app-system
  download=$TEST/no-desktop-app-download
  mkdir -p "$download"
  cp "$FIXTURE/nirux/$VERSION/nirux" "$FIXTURE/nirux/$VERSION/manifest" \
    "$FIXTURE/nirux/$VERSION/SHA256SUMS" "$download/"
  rm -f "$download/niruwallpaper.desktop" "$download/niruwallpaper.png"
  sed -i '/niruwallpaper.desktop/d; /niruwallpaper.png/d' "$download/SHA256SUMS"
  WORK=$download
  install_wallpaper_app
  # Without the guard the function writes an empty file built from a missing
  # source, so an entry whose only line is the owner comment is the failure.
  if [ -e "$ROOT/usr/share/applications/niruwallpaper.desktop" ]; then
    [ "$(grep -vc '^# NIRUX owner:' "$ROOT/usr/share/applications/niruwallpaper.desktop")" -gt 0 ] ||
      fail 'a release without the entry installed an empty one'
    fail 'a release without the entry installed one anyway'
  fi
)

sh "$SOURCE/tests/app-lifecycle.sh"
sh "$SOURCE/tests/legacy-session.sh"
sh "$SOURCE/tests/display-manager.sh"
sh "$SOURCE/tests/runtime-state.sh"
# I08: generation garbage collection keeps current, previous, running and the
# newest N; nothing else under generations/ survives.
PREFIX=$TEST/gc; STATE=$PREFIX/share/nirux
mkdir -p "$STATE/generations"
for gc_i in 1 2 3 4 5 6 7 8; do
  mkdir -p "$STATE/generations/0.0.$gc_i-T/bin"
  touch -d "2026-01-0$gc_i 12:00" "$STATE/generations/0.0.$gc_i-T"
done
ln -s "$STATE/generations/0.0.8-T" "$STATE/current"
ln -s "$STATE/generations/0.0.2-T" "$STATE/previous"
cp "$(command -v sleep)" "$STATE/generations/0.0.3-T/bin/sleep"
"$STATE/generations/0.0.3-T/bin/sleep" 30 & gc_pid=$!
sleep 0.3
gc_generations 3 1 > "$TEST/gc-dry.log"
[ "$(find "$STATE/generations" -mindepth 1 -maxdepth 1 | wc -l)" = 8 ] || fail 'gc --dry-run removed a generation'
grep -q 'keep   0.0.3-T (running)' "$TEST/gc-dry.log" || fail 'gc does not protect a generation a program runs from'
gc_generations 3 0 >/dev/null
kill "$gc_pid" 2>/dev/null || :; wait "$gc_pid" 2>/dev/null || :
gc_left=$(cd "$STATE/generations" && ls -1 | tr '\n' ' ')
[ "$gc_left" = '0.0.2-T 0.0.3-T 0.0.6-T 0.0.7-T 0.0.8-T ' ] || fail "gc kept the wrong generations: $gc_left"
[ -d "$(readlink -f "$STATE/current")" ] && [ -d "$(readlink -f "$STATE/previous")" ] || fail 'gc broke current or previous'
rm -rf "$PREFIX"

# The release fixture again (the Helium tests above replaced fetch).
fetch() {
  case "$1" in
    https://github.com/nirucon/*/releases/download/v*)
      relative=${1#https://github.com/nirucon/}
      repo=${relative%%/*}
      relative=${relative#*/releases/download/v}
      relative=${relative%%\?*}
      cp "$FIXTURE/$repo/$relative" "$2" ;;
    *) return 1 ;;
  esac
}
BROWSER_EFFECTIVE=keep
export NIRUX_WALLPAPERS=default
# A test above corrupted the NIRULOCK fixture on purpose.
make_binary "$FIXTURE/nirulock/$lock_version/nirulock" nirulock "$lock_version"
checksums "$FIXTURE/nirulock/$lock_version"
# Files an earlier test prefix left in the shared test root.
grep -rlE '^(# |// |/\* )NIRUX owner:' "$ROOT" 2>/dev/null | while read -r leftover; do rm -f "$leftover"; done
touch "$ROOT/etc/pam.d/system-auth" "$ROOT/etc/pam.d/common-auth" "$ROOT/etc/pam.d/common-account"
# K7: `nirux update --auto` never asks for sudo. Changes already in place pass;
# a system file that would change is listed in pending-system and left alone.
TEST_OS=debian; PREFIX=$TEST/auto; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
PENDING_SYSTEM=$STATE/pending-system; WANTED_PACKAGES=$STATE/wanted-packages; SYSTEM_SUMS=$STATE/system-sums
WHATS_NEW=$STATE/whats-new
# shellcheck disable=SC2034 # read by whats_new_command in the sourced nirux
WHATS_NEW_SHOWN=$STATE/whats-new-shown
operation install_or_update install --no-packages --browser none --localsend no --opencode no --display-manager startx --release "$VERSION" >/dev/null
# An update keeps the display manager and would adopt one the test machine
# itself has installed (existing_dm looks in PATH); name none.
mkdir -p "$ROOT/etc/systemd/system"
ln -sfn /lib/systemd/system/nirux-test-none.service "$ROOT/etc/systemd/system/display-manager.service"
[ -s "$SYSTEM_SUMS" ] || fail 'files installed through sudo were not recorded'
pam_before=$(sha256sum "$ROOT/etc/pam.d/nirulock" | cut -d' ' -f1)
say '# changed by hand' >> "$ROOT/etc/pam.d/nirulock"
# --auto never replaces the package allowlist (it is not reported either).
say extra-by-test >> "$ROOT/etc/nirux/autoupdate-packages"
allow_sum=$(sha256sum "$ROOT/etc/nirux/autoupdate-packages" | cut -d' ' -f1)
pam_changed=$(sha256sum "$ROOT/etc/pam.d/nirulock" | cut -d' ' -f1)
first=$(readlink "$STATE/current")
set +e
(
  eval "$(sed -n '/^as_root() {/,/^}/p' "$SOURCE/nirux")"
  export NIRUX_TEST_AS_ROOT=0
  sudo() { echo "sudo was called: $*" >&2; exit 97; }
  install_or_update update --auto --no-packages --release 99.0.0
) > "$TEST/auto.log" 2>&1
rc=$?
set -e
[ "$rc" = 0 ] || { cat "$TEST/auto.log" >&2; fail 'update --auto failed'; }
grep -q 'sudo was called' "$TEST/auto.log" && fail 'update --auto used sudo'
[ "$(readlink "$STATE/current")" != "$first" ] || fail 'update --auto did not activate the new generation'
[ "$(sha256sum "$ROOT/etc/pam.d/nirulock" | cut -d' ' -f1)" = "$pam_changed" ] || fail 'update --auto changed a system file'
grep -qx "update $ROOT/etc/pam.d/nirulock" "$PENDING_SYSTEM" || { cat "$PENDING_SYSTEM" >&2; fail 'the changed system file is not pending'; }
[ "$(grep -c . "$PENDING_SYSTEM")" = 1 ] || { cat "$PENDING_SYSTEM" >&2; fail 'unchanged system integration was reported as pending'; }
[ "$(sha256sum "$ROOT/etc/nirux/autoupdate-packages" | cut -d' ' -f1)" = "$allow_sum" ] || fail 'update --auto rewrote the package allowlist'
status > "$TEST/auto-status.log" 2>&1 || :
grep -q 'pending system changes (1): run nirux update once to finish' "$TEST/auto-status.log" || fail 'status does not show pending system changes'
# What's new: the highlights of every entry newer than the old version.
grep -qx 'version 99.0.0' "$WHATS_NEW" || fail 'whats-new was not recorded for the new version'
grep -qx "from $VERSION" "$WHATS_NEW" || fail 'whats-new does not name the old version'
grep -qx 'Test highlight one' "$WHATS_NEW" || fail 'whats-new misses the bold lead phrase'
grep -qx 'Plain bullet sentence' "$WHATS_NEW" || fail 'whats-new misses the first sentence of a plain bullet'
grep -q 'Older entry' "$WHATS_NEW" && fail 'whats-new included an entry that was already installed'
[ -f "$STATE/current/CHANGELOG.md" ] || fail 'the changelog is not kept in the generation'
mkdir -p "$TEST/notifybin"
cat > "$TEST/notifybin/notify-send" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$NOTIFY_LOG"
EOF
chmod +x "$TEST/notifybin/notify-send"
NOTIFY_LOG=$TEST/notify.log; export NOTIFY_LOG
(PATH="$TEST/notifybin:$PATH" DISPLAY=:99 whats_new_command --notify)
(PATH="$TEST/notifybin:$PATH" DISPLAY=:99 whats_new_command --notify)
[ "$(grep -c "NIRUX 99.0.0: what's new" "$NOTIFY_LOG")" = 1 ] || fail 'whats-new --notify did not show exactly one notice'
grep -q 'Run nirux update once to finish' "$NOTIFY_LOG" || fail 'whats-new notice does not mention pending system changes'
grep -q -- "--action=manual=Open the manual" "$NOTIFY_LOG" || fail 'whats-new notice has no manual action'
whats_new_command | grep -q 'Test highlight one' || fail 'whats-new does not print the highlights'
# Same release again: apps only, no new generation, pending list kept.
second=$(readlink "$STATE/current")
(
  eval "$(sed -n '/^as_root() {/,/^}/p' "$SOURCE/nirux")"
  export NIRUX_TEST_AS_ROOT=0
  install_or_update update --auto --no-packages --release 99.0.0
) > "$TEST/auto-again.log" 2>&1 || { cat "$TEST/auto-again.log" >&2; fail 'a current update --auto failed'; }
grep -q 'NIRUX 99.0.0 is current' "$TEST/auto-again.log" || fail 'a current update --auto did not short-cut'
[ "$(readlink "$STATE/current")" = "$second" ] || fail 'a current update --auto made a new generation'
[ -s "$PENDING_SYSTEM" ] || fail 'a current update --auto forgot the pending changes'
# A normal update applies the file and clears the list.
operation install_or_update update --no-packages --release 99.0.0 >/dev/null 2>&1
[ "$(sha256sum "$ROOT/etc/pam.d/nirulock" | cut -d' ' -f1)" = "$pam_before" ] || fail 'a normal update did not restore the system file'
[ ! -e "$PENDING_SYSTEM" ] || fail 'a normal update left the pending list'
grep -qx extra-by-test "$ROOT/etc/nirux/autoupdate-packages" && fail 'a normal update did not replace the package allowlist'
operation uninstall --purge >/dev/null 2>&1 || :
rm -rf "$PREFIX"
rm -f "$ROOT/etc/systemd/system/display-manager.service"

# K7: auto_root on its own. Unreadable root-only files count as unchanged when
# the recorded checksum matches what would be written.
PREFIX=$TEST/autoroot; STATE=$PREFIX/share/nirux; PENDING_SYSTEM=$STATE/pending-system; SYSTEM_SUMS=$STATE/system-sums
mkdir -p "$STATE" "$TEST/ar"
say same > "$TEST/ar/src"; cp "$TEST/ar/src" "$TEST/ar/dst"; chmod 644 "$TEST/ar/dst"
auto_root install -m 644 "$TEST/ar/src" "$TEST/ar/dst"
auto_root chmod 0644 "$TEST/ar/dst"
auto_root install -d -m 755 "$TEST/ar"
auto_root rm -f "$TEST/ar/absent"
auto_root udevadm control --reload
[ ! -s "$PENDING_SYSTEM" ] || { cat "$PENDING_SYSTEM" >&2; fail 'auto_root reported a change that is already in place'; }
auto_root chmod 0600 "$TEST/ar/dst"
grep -qx "set the mode of $TEST/ar/dst to 0600" "$PENDING_SYSTEM" || fail 'auto_root did not report a mode change'
[ "$(stat -c %a "$TEST/ar/dst")" = 644 ] || fail 'auto_root changed a mode'
rm -f "$PENDING_SYSTEM"
system_sum_note install -m 440 "$TEST/ar/src" "$TEST/ar/secret"
if [ "$(id -u)" != 0 ]; then
  cp "$TEST/ar/src" "$TEST/ar/secret"; chmod 000 "$TEST/ar/secret"
  auto_root install -m 440 "$TEST/ar/src" "$TEST/ar/secret"
  [ ! -s "$PENDING_SYSTEM" ] || fail 'auto_root did not use the recorded checksum of an unreadable file'
  say other > "$TEST/ar/src2"
  auto_root install -m 440 "$TEST/ar/src2" "$TEST/ar/secret"
  grep -qx "update $TEST/ar/secret" "$PENDING_SYSTEM" || fail 'auto_root missed a change to an unreadable file'
  chmod 600 "$TEST/ar/secret"
fi
rm -f "$PENDING_SYSTEM"
# Packages the release needs are listed for the root helper, not installed.
WANTED_PACKAGES=$STATE/wanted-packages
(
  # shellcheck disable=SC2034 # read by provision_packages in the sourced nirux
  OS=debian NIRUX_AUTO=1
  wanted_query() { [ "$1" = curl ]; }
  packages_for() { say "curl fake-one fake-two"; }
  internal_package_query wanted_query
  install_packages() { fail 'auto provisioning installed packages'; }
  NIRUX_PROVISION_OS=debian NIRUX_PACKAGE_MAP=none provision_packages missing
) > "$TEST/wanted.log" 2>&1 || { cat "$TEST/wanted.log" >&2; fail 'auto provisioning failed'; }
[ "$(tr '\n' ' ' < "$WANTED_PACKAGES")" = 'fake-one fake-two ' ] || fail "wanted packages: $(cat "$WANTED_PACKAGES" 2>/dev/null)"
pending_lines | grep -qx 'install packages: fake-one fake-two' || fail 'wanted packages are not shown as pending'
rm -rf "$PREFIX"

# K5: changelog highlights keep at most six lines, newest first.
{
  say '## 9.9.3 (x)'; say ''
  for n in 1 2 3 4; do say "- **Three $n.** words"; done
  say '  continued `code`.'
  say ''; say '## 9.9.2 (x)'; say ''
  for n in 1 2 3; do say "- Two $n plain. More."; done
  say ''; say '## 9.9.1 (x)'; say ''; say '- **One.**'
} > "$TEST/changelog.md"
changelog_highlights "$TEST/changelog.md" 9.9.1 9.9.3 > "$TEST/highlights"
[ "$(grep -c . "$TEST/highlights")" = 6 ] || fail 'changelog highlights are not limited to six lines'
[ "$(head -n 1 "$TEST/highlights")" = 'Three 1' ] || fail 'changelog highlights do not start with the newest entry'
grep -qx 'Two 2 plain' "$TEST/highlights" || fail 'changelog highlights lost a plain bullet'
grep -q 'One' "$TEST/highlights" && fail 'changelog highlights included the installed version'

# K5: [bar] follow_default_modules keeps modules on the shipped list; the
# old file goes to NIRUWM's config history once; false keeps your list.
fd=$TEST/follow; mkdir -p "$fd"
printf '[bar]\nmodules = ["workspaces", "clock"]\n' > "$fd/config.toml"
cp "$fd/config.toml" "$fd/original.toml"
(
  XDG_STATE_HOME=$fd/state
  follow_default_bar_modules "$fd/config.toml" "$SOURCE/config.example.toml" "$fd/original.toml"
  follow_default_bar_modules "$fd/config.toml" "$SOURCE/config.example.toml" "$fd/original.toml"
) > "$fd/log"
[ "$(bar_modules_line "$fd/config.toml")" = "$(bar_modules_line "$SOURCE/config.example.toml")" ] || fail 'bar modules did not follow the default list'
grep -q '"disk", "quicksettings"' "$fd/config.toml" || fail 'followed list lacks the disk module'
[ "$(find "$fd/state/niruwm/config-history" -name '*-[0-9][0-9].toml' | wc -l)" = 1 ] || fail 'the old configuration was not kept exactly once'
# Arch's base image has no `cmp`: compare by checksum.
[ "$(sha256sum "$fd/original.toml" | cut -d ' ' -f1)" = \
  "$(sha256sum "$(find "$fd/state/niruwm/config-history" -name '*.toml' | head -n 1)" | cut -d ' ' -f1)" ] ||
  fail 'the history copy differs from the old file'
[ "$(grep -c 'Bar modules set to the NIRUX default list' "$fd/log")" = 1 ] || fail 'following the default was not announced once'
printf '[bar]\nfollow_default_modules = false\nmodules = ["workspaces", "clock"]\n' > "$fd/mine.toml"
(XDG_STATE_HOME=$fd/state2; follow_default_bar_modules "$fd/mine.toml" "$SOURCE/config.example.toml" "$fd/mine.toml")
grep -qx 'modules = \["workspaces", "clock"\]' "$fd/mine.toml" || fail 'follow_default_modules = false was not respected'
printf '[bar]\nmodules = ["workspaces", "clock"]\n' > "$fd/addkey.toml"
add_missing_key "$fd/addkey.toml" bar follow_default_modules true
grep -qx 'follow_default_modules = true' "$fd/addkey.toml" || fail 'follow_default_modules was not added to [bar]'

# K6: apps follow verified upstream releases, never below the pin and never
# without a checksum; the lookup is cached.
apps=$TEST/apps; mkdir -p "$apps"
APPS_CACHE=$apps/cache
cat > "$apps/helium.json" <<'EOF'
{"tag_name": "1.2.3.4", "name": "1.2.3.4", "draft": false, "prerelease": false, "author": {"login": "x"},
 "assets": [{"name": "helium-1.2.3.4-x86_64_linux.tar.xz.asc", "digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111"},
            {"name": "helium-1.2.3.4-x86_64_linux.tar.xz", "uploader": {"login": "y"}, "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}],
 "body": "text \"name\": \"helium-1.2.3.4-x86_64_linux.tar.xz\""}
EOF
[ "$(app_github_latest "$apps/helium.json" '' 'helium-%s-x86_64_linux.tar.xz')" = "1.2.3.4 sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ] ||
  fail 'the GitHub asset digest was not found'
sed 's/"prerelease": false/"prerelease": true/' "$apps/helium.json" > "$apps/pre.json"
app_github_latest "$apps/pre.json" '' 'helium-%s-x86_64_linux.tar.xz' >/dev/null && fail 'a prerelease was accepted'
sed 's/"digest": "sha256:a*"//' "$apps/helium.json" > "$apps/nodigest.json"
app_github_latest "$apps/nodigest.json" '' 'helium-%s-x86_64_linux.tar.xz' >/dev/null && fail 'a release without a digest was accepted'
api_calls=0
apps_api() { api_calls=$((api_calls + 1)); cp "$apps/helium.json" "$2"; }
NIRUX_APPS=latest app_latest helium || fail 'app_latest failed on a good release'
NIRUX_APPS=latest app_latest helium || fail 'app_latest failed from the cache'
[ "$api_calls" = 1 ] || fail "the upstream answer was not cached ($api_calls requests)"
NIRUX_APPS=latest app_upstream helium 1.2.3.0 || fail 'a newer upstream release was not used'
NIRUX_APPS=latest app_upstream helium 1.2.4 && fail 'an upstream release below the pin was used'
NIRUX_APPS=pinned app_latest helium && fail 'NIRUX_APPS=pinned asked upstream'
# OpenCode 2: the version from opencode.ai, the sha512 from npm.
oc_tgz=$apps/oc.tgz
mkdir -p "$apps/ocpkg/package/bin"
printf '#!/bin/sh\necho "opencode v2.9.1"\n' > "$apps/ocpkg/package/bin/opencode"; chmod +x "$apps/ocpkg/package/bin/opencode"
tar -czf "$oc_tgz" -C "$apps/ocpkg" package
# The raw digest as octal escapes (POSIX printf has no \x), then base64.
oc_octal=$(sha512sum "$oc_tgz" | cut -d' ' -f1 | awk '{
  for (i = 1; i <= length($0); i += 2) {
    v = (index("0123456789abcdef", substr($0, i, 1)) - 1) * 16 + index("0123456789abcdef", substr($0, i + 1, 1)) - 1
    printf "\\%03o", v
  } }')
# shellcheck disable=SC2059 # the format is the escaped digest
oc_b64=$(printf "$oc_octal" | base64 | tr -d '\n')
apps_api() {
  case "$1" in
    https://opencode.ai/update/api/latest/cli/npm) printf '{"channel":"latest","version":"2.9.1","metadata":{"package":"@opencode/cli"}}' > "$2" ;;
    https://registry.npmjs.org/@opencode%2fcli-linux-x64/2.9.1) printf '{"name":"@opencode/cli-linux-x64","version":"2.9.1","dist":{"integrity":"sha512-%s"}}' "$oc_b64" > "$2" ;;
    *) return 1 ;;
  esac
}
rm -f "$APPS_CACHE"
NIRUX_APPS=latest app_upstream opencode 2.2.7 || fail 'the OpenCode 2 upstream release was not found'
[ "$AL_EXTRA" = @opencode ] || fail 'the OpenCode npm scope was not kept'
app_digest_ok "$oc_tgz" "$AL_DIGEST" || fail 'the npm sha512 integrity does not verify the package'
NIRUX_APPS=latest app_upstream opencode 1.9.0 && fail 'OpenCode moved to another major version'
# Helium end to end: the newer upstream archive is installed when it verifies;
# a wrong digest falls back to the pin.
(
  PREFIX=$apps/prefix; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux; WORK=$apps/work
  mkdir -p "$WORK" "$BIN"
  # shellcheck disable=SC2034 # read by browser_install in the sourced nirux
  BROWSER_EFFECTIVE=helium; HELIUM_VERSION=99.9.10
  browser_unmanaged() { return 1; }
  make_helium_archive 99.9.20 "$apps/up.tar.xz"
  make_helium_archive 99.9.10 "$apps/pin.tar.xz"
  # shellcheck disable=SC2034 # read by browser_install in the sourced nirux
  HELIUM_SHA256=$(sha256sum "$apps/pin.tar.xz" | cut -d' ' -f1)
  up_sum=$(sha256sum "$apps/up.tar.xz" | cut -d' ' -f1)
  fetch() { case "$1" in *99.9.20*) cp "$apps/up.tar.xz" "$2" ;; *99.9.10*) cp "$apps/pin.tar.xz" "$2" ;; *) return 1 ;; esac; }
  rm -f "$APPS_CACHE"
  apps_api() { sed "s/1\.2\.3\.4/99.9.20/g; s/sha256:a*\"/sha256:$UPSUM\"/" "$apps/helium.json" > "$2"; }
  UPSUM=$up_sum NIRUX_APPS=latest browser_install > "$apps/up.log" 2>&1 || { cat "$apps/up.log" >&2; exit 1; }
  [ "$("$BIN/helium" --version)" = 'Helium 99.9.20 (test)' ] || { echo 'upstream Helium was not installed' >&2; exit 1; }
  # A broken upstream checksum: the newer installed one is kept (never a downgrade).
  rm -f "$APPS_CACHE"
  UPSUM=$(printf '%064d' 0) NIRUX_APPS=latest browser_install > "$apps/bad.log" 2>&1 || { cat "$apps/bad.log" >&2; exit 1; }
  [ "$("$BIN/helium" --version)" = 'Helium 99.9.20 (test)' ] || { echo 'an installed newer Helium was replaced' >&2; exit 1; }
) || fail 'Helium did not follow upstream safely'
unset -f apps_api 2>/dev/null || :
eval "$(sed -n '/^apps_api() {/,/^}/p' "$SOURCE/nirux")"

# K5: resume-check reconnects a lone Wi-Fi, restarts sound and logs every run.
rc_bin=$TEST/resumebin; mkdir -p "$rc_bin"
cat > "$rc_bin/nmcli" <<'EOF'
#!/bin/sh
echo "nmcli $*" >> "$RC_CALLS"
case "$*" in
  'networking connectivity check') echo none ;;
  'radio wifi') echo enabled ;;
  'radio wifi on') touch "$RC_STATE/wifi-on" ;;
  '-t -f TYPE device') echo wifi ;;
  '-t -f TYPE,STATE device') if [ -e "$RC_STATE/wifi-on" ]; then echo wifi:connected; else echo wifi:disconnected; fi ;;
esac
exit 0
EOF
cat > "$rc_bin/wpctl" <<'EOF'
#!/bin/sh
[ -e "$RC_STATE/audio-ok" ]
EOF
cat > "$rc_bin/systemctl" <<'EOF'
#!/bin/sh
echo "systemctl $*" >> "$RC_CALLS"
case "$*" in *restart*) touch "$RC_STATE/audio-ok" ;; esac
exit 0
EOF
cat > "$rc_bin/tailscale" <<'EOF'
#!/bin/sh
echo 'Logged out.'; exit 1
EOF
cp "$TEST/notifybin/notify-send" "$rc_bin/notify-send"
chmod +x "$rc_bin"/*
RC_CALLS=$TEST/rc-calls RC_STATE=$TEST/rc-state; mkdir -p "$RC_STATE"; export RC_CALLS RC_STATE
: > "$NOTIFY_LOG"
(PATH="$rc_bin:$PATH" XDG_STATE_HOME=$TEST/rc-xdg NIRUX_RESUME_WAIT=1 RESUME_LOG=$TEST/rc-xdg/nirux/resume-check.log resume_check_command --notify)
grep -q 'radio wifi off' "$RC_CALLS" && grep -q 'radio wifi on' "$RC_CALLS" || fail 'resume-check did not switch the Wi-Fi radio off and on'
grep -q 'systemctl --user restart pipewire pipewire-pulse wireplumber' "$RC_CALLS" || fail 'resume-check did not restart the sound services'
grep -q 'Wi-Fi reconnected after sleep' "$NOTIFY_LOG" || fail 'resume-check did not report the Wi-Fi fix'
grep -q 'Sound restarted after sleep' "$NOTIFY_LOG" || fail 'resume-check did not report the sound fix'
grep -q 'network=wifi-reconnected audio=restarted screens=skipped tailscale=off' "$TEST/rc-xdg/nirux/resume-check.log" || fail 'resume-check did not log the run'
# Nothing to fix: no notice.
: > "$NOTIFY_LOG"
(PATH="$rc_bin:$PATH" NIRUX_RESUME_WAIT=1 RESUME_LOG=$TEST/rc-xdg/nirux/resume-check.log resume_check_command --notify)
[ ! -s "$NOTIFY_LOG" ] || fail 'resume-check notified although nothing was wrong'
for _ in $(seq 1 60); do say "old run" >> "$TEST/rc-xdg/nirux/resume-check.log"; done
(PATH="$rc_bin:$PATH" NIRUX_RESUME_WAIT=1 RESUME_LOG=$TEST/rc-xdg/nirux/resume-check.log resume_check_command >/dev/null)
[ "$(wc -l < "$TEST/rc-xdg/nirux/resume-check.log")" = 50 ] || fail 'resume-check keeps more than 50 runs'

# K5: nirux clean --dry-run lists what can go and changes nothing.
cl_home=$TEST/cleanhome; mkdir -p "$cl_home/.cache/thumbnails/normal"
say x > "$cl_home/.cache/thumbnails/normal/a.png"
(HOME=$cl_home XDG_CACHE_HOME=$cl_home/.cache XDG_DATA_HOME=$cl_home/.local/share TEST_OS=debian clean_command --dry-run) > "$TEST/clean.log"
grep -q 'nirux clean can free:' "$TEST/clean.log" || fail 'clean does not list what it can free'
grep -q 'thumbnails' "$TEST/clean.log" || fail 'clean does not offer the thumbnails'
[ -f "$cl_home/.cache/thumbnails/normal/a.png" ] || fail 'clean --dry-run deleted a file'
(HOME=$cl_home XDG_CACHE_HOME=$cl_home/.cache TEST_OS=debian clean_command </dev/null) >/dev/null 2>&1 && fail 'clean without a terminal or --yes did not refuse'

# K8: the sleep hook goes where this init system runs it.
sh_root=$TEST/sleeproot; mkdir -p "$sh_root/usr/libexec/elogind"
[ "$(ROOT=$sh_root OS=void sleep_hook_dir)" = /usr/libexec/elogind/system-sleep ] || fail 'void: wrong elogind sleep hook directory'
[ "$(ROOT=$sh_root OS=debian sleep_hook_dir)" = /usr/lib/systemd/system-sleep ] || fail 'debian: wrong systemd sleep hook directory'

say 'PASS: install/update/rollback/purge, generation gc on all three distro mappings, status purity, checksum failure, PAM includes, power rule, greeter themes, managed Helium policy, obsolete browser migration, target-owned apply'
