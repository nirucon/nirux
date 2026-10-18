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
fixture niruwm 0.16.3 niruwm niructl niruidle niruwm-session
# Executing the session script during status must be caught.
say 'touch "$HOME/session-was-started"' >> "$FIXTURE/niruwm/0.16.3/niruwm-session"
fixture nirubar 0.16.4 nirubar
fixture niruscreensaver 0.7.0 niruscreensaver
fixture nirulock 0.16.3 nirulock
for os in arch void; do
  printf 'auth include system-auth\naccount include system-auth\n' > "$FIXTURE/nirulock/0.16.3/pam-$os"
done
printf 'auth include common-auth\naccount include common-account\n' > "$FIXTURE/nirulock/0.16.3/pam-debian"
for item in niruwm/0.16.3 nirubar/0.16.4 niruscreensaver/0.7.0 nirulock/0.16.3; do checksums "$FIXTURE/$item"; done
for release in 0.5.0 0.5.1; do
  mkdir -p "$FIXTURE/nirux/$release"
  sed "s/^VERSION=0.5.0$/VERSION=$release/" "$SOURCE/nirux" > "$FIXTURE/nirux/$release/nirux"
  chmod +x "$FIXTURE/nirux/$release/nirux"
  sed "s/suite 0.5.0/suite $release/" "$SOURCE/manifest" > "$FIXTURE/nirux/$release/manifest"
  checksums "$FIXTURE/nirux/$release"
done

for TEST_OS in arch debian void; do
  # Separate installations exercise each distribution's integration and cleanup.
  PREFIX=$TEST/$TEST_OS; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
  touch "$ROOT/etc/pam.d/system-auth" "$ROOT/etc/pam.d/common-auth" "$ROOT/etc/pam.d/common-account"
  operation install_or_update install --no-packages --display-manager startx --release 0.5.0
  status
  [ ! -e "$HOME/session-was-started" ] || fail 'status ran the session'
  [ "$(awk '$1 == "suite" {print $2}' "$STATE/current/manifest")" = 0.5.0 ] || fail 'wrong manifest'
  first=$(readlink "$STATE/current")
  operation install_or_update update --release 0.5.1
  second=$(readlink "$STATE/current")
  [ "$first" != "$second" ] || fail 'no generation switch'
  operation rollback
  [ "$(readlink "$STATE/current")" = "$first" ] || fail 'rollback did not restore the generation'
  # Uninstall preserves unowned user files, even when purging settings.
  say 'my existing desktop' > "$HOME/.xinitrc"
  mkdir -p "$XDG_CONFIG_HOME/niruui" "$XDG_STATE_HOME/nirulock"
  operation uninstall --purge
  [ ! -e "$BIN/niruwm" ] || fail 'program still installed'
  [ ! -e "$ROOT/etc/pam.d/nirulock" ] || fail 'owned PAM service remained'
  [ ! -d "$XDG_STATE_HOME/nirulock" ] || fail 'purge missed lock state'
  [ "$(cat "$HOME/.xinitrc")" = 'my existing desktop' ] || fail 'existing xinitrc was changed'
done

# A corrupt late download must leave the active installation unchanged.
TEST_OS=arch; PREFIX=$TEST/failure; BIN=$PREFIX/bin; STATE=$PREFIX/share/nirux
operation install_or_update install --no-packages --display-manager startx --release 0.5.0
before=$(readlink "$STATE/current")
say corrupt >> "$FIXTURE/nirulock/0.16.3/nirulock"
set +e
(set -e; install_or_update update --release 0.5.1) > "$TEST/failure.log" 2>&1
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
