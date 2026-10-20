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
  checksums "$FIXTURE/nirux/$release"
done

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

# Fresh-install key overrides must not bypass the explicit compatibility profile.
if grep -Eq '^action = ".*(nirupi|clip-menu|flameshot)' "$SOURCE/config.example.toml"; then
  fail 'canonical config overrides native defaults with absent helper scripts'
fi

for TEST_OS in arch debian void; do
  # Separate installations exercise each distribution's integration and cleanup.
  PREFIX=$TEST/$TEST_OS; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
  touch "$ROOT/etc/pam.d/system-auth" "$ROOT/etc/pam.d/common-auth" "$ROOT/etc/pam.d/common-account"
  operation install_or_update install --no-packages --display-manager startx --release "$VERSION"
  status
  [ ! -e "$HOME/session-was-started" ] || fail 'status ran the session'
  [ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = "$VERSION" ] || fail 'wrong manifest'
  first=$(readlink "$STATE/current")
  operation install_or_update update --no-packages --release 99.0.0
  second=$(readlink "$STATE/current")
  [ "$first" != "$second" ] || fail 'no generation switch'
  operation rollback
  [ "$(readlink "$STATE/current")" = "$first" ] || fail 'rollback did not restore the generation'
  # Uninstall preserves unowned user files, even when purging settings.
  say 'my existing desktop' > "$HOME/.xinitrc"
  mkdir -p "$XDG_CONFIG_HOME/niruui" "$XDG_STATE_HOME/nirulock" "$HOME/.cache/nirubar"
  say stale > "$HOME/.cache/nirubar/updates"
  operation uninstall --purge
  [ ! -e "$BIN/niruwm" ] || fail 'program still installed'
  [ ! -e "$ROOT/etc/pam.d/nirulock" ] || fail 'owned PAM service remained'
  [ ! -d "$XDG_STATE_HOME/nirulock" ] || fail 'purge missed lock state'
  [ "$(cat "$HOME/.xinitrc")" = 'my existing desktop' ] || fail 'existing xinitrc was changed'
done

# A corrupt late download must leave the active installation unchanged.
TEST_OS=arch; PREFIX=$TEST/failure; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --display-manager startx --release "$VERSION"
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
say 'PASS: install/update/rollback/purge on all three distro mappings, status purity, checksum failure, PAM includes'
