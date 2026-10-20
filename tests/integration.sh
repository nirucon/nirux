#!/bin/sh
# Offline regression tests. No real packages, sudo or system files are changed.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state
export NIRUX_LIBRARY=1
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT/etc/pam.d" "$NIRUX_SYSTEM_ROOT/usr/share/xsessions"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
wm_version=$(awk '$1 == "niruwm" {print $2}' "$SOURCE/manifest")
bar_version=$(awk '$1 == "nirubar" {print $2}' "$SOURCE/manifest")
saver_version=$(awk '$1 == "niruscreensaver" {print $2}' "$SOURCE/manifest")
lock_version=$(awk '$1 == "nirulock" {print $2}' "$SOURCE/manifest")
launcher_version=$(awk '$1 == "nirulauncher" {print $2}' "$SOURCE/manifest")
notifier_version=$(awk '$1 == "nirunotify" {print $2}' "$SOURCE/manifest")
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
wallpaper_archive() {
  build=$TEST/wallpaper-build
  mkdir -p "$build/wallpaper"
  : > "$build/wallpaper/nirux-wallpaper-noir-4k.png"
  : > "$build/wallpaper/nirux-wallpaper-nord-4k.png"
  tar -cJf "$1" -C "$build" wallpaper
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
for os in arch void; do
  printf 'auth include system-auth\naccount include system-auth\n' > "$FIXTURE/nirulock/$lock_version/pam-$os"
done
printf 'auth include common-auth\naccount include common-account\n' > "$FIXTURE/nirulock/$lock_version/pam-debian"
for item in "niruwm/$wm_version" "nirubar/$bar_version" "niruscreensaver/$saver_version" "nirulock/$lock_version" "nirulauncher/$launcher_version" "nirunotify/$notifier_version"; do checksums "$FIXTURE/$item"; done
# 99.0.0 is a synthetic second release, never a real network dependency.
for release in "$VERSION" 99.0.0; do
  mkdir -p "$FIXTURE/nirux/$release"
  sed "s/^VERSION=$VERSION$/VERSION=$release/" "$SOURCE/nirux" > "$FIXTURE/nirux/$release/nirux"
  chmod +x "$FIXTURE/nirux/$release/nirux"
  sed "s/suite $VERSION/suite $release/" "$SOURCE/manifest" > "$FIXTURE/nirux/$release/manifest"
  cp "$SOURCE/config.example.toml" "$FIXTURE/nirux/$release/config.example.toml"
  cp "$SOURCE/appearance.example.toml" "$FIXTURE/nirux/$release/appearance.example.toml"
  wallpaper_archive "$FIXTURE/nirux/$release/nirux-wallpapers.tar.xz"
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
wallpaper_archive "$FIXTURE/nirux/99.2.0/nirux-wallpapers.tar.xz"
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
wallpaper_archive "$FIXTURE/nirux/99.3.0/nirux-wallpapers.tar.xz"
cat > "$FIXTURE/nirulib/1.0.0/nirulib" <<'EOF'
#!/bin/sh
[ "$1" = --version ] || exit 0
[ -f "$LIB_MARKER" ] || { echo 'fake-lib is missing' >&2; exit 1; }
echo 'NIRULIB 1.0.0'
EOF
chmod +x "$FIXTURE/nirulib/1.0.0/nirulib"
checksums "$FIXTURE/nirulib/1.0.0"
checksums "$FIXTURE/nirux/99.3.0"

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
add_missing_key "$config" monitors workspaces 9
cp "$config" "$TEST/once.toml"
add_missing_top_key "$config" enabled true
add_missing_key "$config" bar scale '"bar-only"'
add_missing_sections "$config" "$SOURCE/config.example.toml"
add_missing_key "$config" monitors workspaces 9
[ "$(sha256sum "$config" | cut -d' ' -f1)" = "$(sha256sum "$TEST/once.toml" | cut -d' ' -f1)" ] || fail 'config migration is not idempotent'
[ "$(stat -c %a "$config")" = 600 ] || fail 'config migration changed permissions'
grep -qx 'enabled = true' "$config" || fail 'nested key suppressed root default'
grep -qx 'scale = "bar-only"' "$config" || fail 'other table suppressed missing key'
grep -qx 'scale = "fit"' "$config" || fail 'existing setting overwritten'
[ "$(grep -c '^[[:space:]]*\[bar\]' "$config")" = 1 ] || fail 'duplicate commented table'
grep -qx 'workspaces = 9' "$config" || fail 'profile suppressed monitor default'

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
grep -qx 'workspaces = 9' "$i06/config/niruwm/config.toml" || fail 'missing monitor default was not added'
grep -qx 'title_delay_seconds = 0' "$i06/config/niruwm/config.toml" || fail 'bar key was not added to the real table'
grep -qx 'follow_theme = true' "$i06/config/niruwm/config.toml" || fail 'wallpaper follow_theme default was not added'
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
grep -qx 'workspaces = 9' "$i06/symlink/real/config.toml" || fail 'migration did not update the symlink target'
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

# Fresh-install key overrides must not bypass the explicit compatibility profile.
if grep -Eq '^action = ".*(nirupi|clip-menu|flameshot)' "$SOURCE/config.example.toml"; then
  fail 'canonical config overrides native defaults with absent helper scripts'
fi

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
  first=$(readlink "$STATE/current")
  operation install_or_update update --no-packages --release 99.0.0
  second=$(readlink "$STATE/current")
  [ "$first" != "$second" ] || fail 'no generation switch'
  [ "$(browser_policy)" = none ] || fail 'update did not preserve the browser opt-out'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'update removed theme wallpapers'
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
  for dir in niruwm niruui nirubar nirulauncher nirunotify; do
    [ -d "$XDG_CONFIG_HOME/$dir" ] || fail "normal uninstall removed $dir config"
  done
  [ -d "$XDG_STATE_HOME/nirulock" ] || fail 'normal uninstall removed lock state'
  [ -d "$XDG_STATE_HOME/niruscreensaver" ] || fail 'normal uninstall removed saver state'
  [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ] || fail 'normal uninstall removed theme wallpapers'
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
grep -q 'Staged components through the target installer handoff' "$TEST/newcomponent.log" || fail 'target installer handoff was not used'
[ -x "$BIN/nirufoo" ] || fail 'new component was not linked on the first update'
[ -x "$STATE/current/bin/nirufoo" ] || fail 'new component was not staged'
[ "$(readlink "$BIN/nirufoo")" = "$STATE/current/bin/nirufoo" ] || fail 'new component link is not generation-owned'
[ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = 99.2.0 ] || fail 'new component release was not activated'
grep -q 'nirufoo' "$STATE/current/bin/nirux" || fail 'installed installer does not know the new component'
operation rollback >/dev/null 2>&1 || fail 'rollback after a new component failed'
[ ! -e "$BIN/nirufoo" ] && [ ! -L "$BIN/nirufoo" ] || fail 'rollback left a front link for a component absent from the restored generation'
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
grep -q 'Staged components through the target installer handoff' "$TEST/libdep.log" || fail 'target installer handoff was not used for the dependency case'
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
NIRUX_LIBRARY=1 sh -c '
  . "$1"
  id() { printf "1000\n"; }
  sudo() { case "$*" in "-n true") return 0 ;; *) return 7 ;; esac; }
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
printf 'first\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
printf 'first\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-nord-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
wallpaper_dir=$XDG_PICTURES_DIR/Wallpapers/NIRU
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = first ] || fail 'theme wallpaper was not installed'
printf 'mine\n' > "$wallpaper_dir/nirux-wallpaper-noir-4k.png"
printf 'second\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-noir-4k.png"
printf 'second\n' > "$wallpaper_test/build/wallpaper/nirux-wallpaper-nord-4k.png"
tar -cJf "$WORK/download/nirux/nirux-wallpapers.tar.xz" -C "$wallpaper_test/build" wallpaper
install_wallpapers >/dev/null
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = mine ] || fail 'user-modified wallpaper was overwritten'
[ "$(cat "$wallpaper_dir/nirux-wallpaper-nord-4k.png")" = second ] || fail 'unmodified owned wallpaper was not updated'
remove_owned_wallpapers
[ "$(cat "$wallpaper_dir/nirux-wallpaper-noir-4k.png")" = mine ] || fail 'purge removed a user-modified wallpaper'
[ ! -e "$wallpaper_dir/nirux-wallpaper-nord-4k.png" ] || fail 'purge kept an unmodified owned wallpaper'

say 'PASS: install/update/rollback/purge on all three distro mappings, status purity, checksum failure, PAM includes, managed Helium policy, obsolete browser migration'
