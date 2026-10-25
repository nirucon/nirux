#!/bin/sh
# Offline regression tests. No real packages, sudo or system files are changed.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1 NIRUX_TEST_AS_ROOT=1
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
fetch_version=$(awk '$1 == "nirufetch" {print $2}' "$SOURCE/manifest")
webapp_version=$(awk '$1 == "niruwebapp" {print $2}' "$SOURCE/manifest")
wallpaper_app_version=$(awk '$1 == "niruwallpaper" {print $2}' "$SOURCE/manifest")
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
      cp "$FIXTURE/$repo/$relative" "$2" ;;
    *) fail "unexpected fetch: $1" ;;
  esac
}
platform() { :; }
distro() { say "$TEST_OS"; }
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
    cp "$FIXTURE/$repo/$relative" "$out" ;;
  *) exit 22 ;;
esac
EOF
chmod +x "$TEST/bin/curl"
export FIXTURE
export PATH="$TEST/bin:$PATH"
fixture niruwm "$wm_version" niruwm niructl niruidle niruwm-session
# Executing the session script during status must be caught.
say 'touch "$HOME/session-was-started"' >> "$FIXTURE/niruwm/$wm_version/niruwm-session"
fixture nirubar "$bar_version" nirubar
fixture niruscreensaver "$saver_version" niruscreensaver
fixture nirulock "$lock_version" nirulock
fixture nirulauncher "$launcher_version" nirulauncher
fixture nirunotify "$notifier_version" nirunotify
fixture nirushot "$shot_version" nirushot
fixture nirufetch "$fetch_version" nirufetch
fixture niruwebapp "$webapp_version" niruwebapp
fixture niruwallpaper "$wallpaper_app_version" niruwallpaper niruwallpaper.desktop
# The icon is not a program, so it is not part of the fixture binary. It
# starts with the PNG signature, which an owner comment would break.
printf '\211PNG\r\n\032\n\0\0\0\rIHDR' > "$FIXTURE/niruwallpaper/$wallpaper_app_version/niruwallpaper.png"
for os in arch void; do
  printf 'auth include system-auth\naccount include system-auth\n' > "$FIXTURE/nirulock/$lock_version/pam-$os"
done
printf 'auth include common-auth\naccount include common-account\n' > "$FIXTURE/nirulock/$lock_version/pam-debian"
for item in "niruwm/$wm_version" "nirubar/$bar_version" "niruscreensaver/$saver_version" "nirulock/$lock_version" "nirulauncher/$launcher_version" "nirunotify/$notifier_version" "nirushot/$shot_version" "nirufetch/$fetch_version" "niruwebapp/$webapp_version" "niruwallpaper/$wallpaper_app_version"; do checksums "$FIXTURE/$item"; done
# 99.0.0 is a synthetic second release, never a real network dependency.
for release in "$VERSION" 99.0.0; do
  mkdir -p "$FIXTURE/nirux/$release"
  sed "s/^VERSION=$VERSION$/VERSION=$release/" "$SOURCE/nirux" > "$FIXTURE/nirux/$release/nirux"
  chmod +x "$FIXTURE/nirux/$release/nirux"
  sed "s/suite $VERSION/suite $release/" "$SOURCE/manifest" > "$FIXTURE/nirux/$release/manifest"
  cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/$release/config.example.toml"
  cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/$release/appearance.example.toml"
  wallpaper_app_assets "$FIXTURE/nirux/$release"
  wallpaper_archive "$FIXTURE/nirux/$release/nirux-wallpapers.tar.xz"
  terminal_archive "$FIXTURE/nirux/$release/nirux-terminal.tar.xz"
  integration_archive "$FIXTURE/nirux/$release/nirux-integration.tar.xz"
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
  -e 's/procps util-linux"/procps util-linux fake-lib"/' \
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
# the missing-only path without touching a package manager.
# shellcheck disable=SC2034 # read by missing_packages in the sourced nirux
OS=debian
package_present() { [ "$1" != "kitty" ]; }
missing=$(missing_packages)
[ "$missing" = "kitty" ] || fail "missing packages reported: $missing"
NIRUX_PACKAGES_DRY_RUN=1 NIRUX_PROVISION_OS=debian NIRUX_PROVISION_DM=keep \
  provision_packages missing > "$TEST/provision.log" 2>&1
grep -q 'would install missing: kitty' "$TEST/provision.log" || fail 'provision dry run did not report the missing package'
unset -f package_present
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
  status
  [ ! -e "$HOME/session-was-started" ] || fail 'status ran the session'
  [ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = "$VERSION" ] || fail 'wrong manifest'
  [ "$(browser_policy)" = none ] || fail 'browser opt-out was not persisted'
  grep -qx 'browser = \[\]' "$XDG_CONFIG_HOME/niruwm/config.toml" || fail 'fresh opt-out did not disable the managed browser default'
  [ ! -e "$BIN/helium" ] || fail 'browser was installed despite opt-out'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'theme wallpapers were not installed'
  [ -f "$XDG_CONFIG_HOME/kitty/kitty.conf" ] || fail 'kitty integration was not installed'
  [ -f "$XDG_CONFIG_HOME/nirux/theme/kitty.conf" ] || fail 'kitty theme was not generated'
  [ -f "$XDG_CONFIG_HOME/nirux/theme/fish.fish" ] || fail 'fish theme was not generated'
  grep -q 'NIRUX terminal integration' "$XDG_CONFIG_HOME/fish/config.fish" || fail 'fish integration block was not installed'
  [ -x "$BIN/nirux-theme-hook" ] || fail 'theme hook was not installed'
  session_desktop=$ROOT/usr/share/xsessions/niruwm.desktop
  grep -qxF "Exec=$BIN/niruwm-session" "$session_desktop" || fail 'display-manager session Exec must be an unquoted absolute path'
  ! grep -q '"' "$session_desktop" || fail 'display-manager session must not quote Exec'
  [ -f "$ROOT/etc/udev/rules.d/70-nirux-backlight.rules" ] || fail 'missing backlight udev rule'
  # The launcher entry must point at the generation link, not at a path the
  # user could replace, and the icon must come from the release.
  app_desktop=$ROOT/usr/share/applications/niruwallpaper.desktop
  grep -qxF "Exec=$BIN/niruwallpaper" "$app_desktop" || fail 'wallpaper app entry does not use the managed binary'
  icon=$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png
  [ -f "$icon" ] || fail 'wallpaper app icon was not installed'
  # The icon must stay a valid PNG: no comment may be put in front of it.
  [ "$(head -c 8 "$icon" | od -An -tx1 | tr -d ' \n')" = 89504e470d0a1a0a ] || fail 'installed wallpaper icon is not a PNG'
  cmp -s "$icon" "$FIXTURE/niruwallpaper/$wallpaper_app_version/niruwallpaper.png" || fail 'installed icon differs from the released icon'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruwallpaper.png || fail 'icon ownership was not recorded beside the file'
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
  operation uninstall
  [ ! -e "$BIN/niruwm" ] || fail 'program still installed'
  [ ! -e "$ROOT/etc/pam.d/nirulock" ] || fail 'owned PAM service remained'
  [ ! -e "$ROOT/usr/share/applications/niruwallpaper.desktop" ] || fail 'wallpaper app entry remained after uninstall'
  [ ! -e "$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png" ] || fail 'wallpaper app icon remained after uninstall'
  find "$ROOT" -name '*.sha256' -path '*nirux-owned*' | grep -q niruwallpaper.png && fail 'icon ownership record remained after uninstall'
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
(DM=auto; existing_dm() { :; }; choose_dm </dev/null; [ "$DM" = startx ]) || fail 'noninteractive default is not startx'
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
[ "$(readlink "$BIN/helium")" = "$STATE/browser-current/helium" ] || fail 'Helium link is not owned by the browser state'
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
remove_owned_wallpapers
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = mine ] || fail 'purge removed a user-modified wallpaper'
[ ! -e "$wallpaper_dir/nirux-wallpaper-nord-4k.png" ] || fail 'purge kept an unmodified owned wallpaper'

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
say 'PASS: install/update/rollback/purge on all three distro mappings, status purity, checksum failure, PAM includes, power rule, greeter themes, managed Helium policy, obsolete browser migration, target-owned apply'
