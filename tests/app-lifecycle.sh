#!/bin/sh
# Managed optional-app lifecycle without downloading the real applications.
set -eu
SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
export NIRUX_PREFIX=$T/prefix
export NIRUX_SYSTEM_ROOT=$T/root
export NIRUX_LIBRARY=1
mkdir -p "$HOME" "$T/prefix/bin" "$T/prefix/share/applications"
# shellcheck source=/dev/null
. "$SOURCE/nirux"
STATE=$T/prefix/share/nirux
BIN=$T/prefix/bin
LOCALSEND_EXPLICIT=1 LOCALSEND_CHOICE=yes
OPENCODE_EXPLICIT=1 OPENCODE_CHOICE=no
choose_optional_apps install
[ "$(app_policy localsend)" = yes ] || { echo 'localsend opt-in was not recorded' >&2; exit 1; }
[ "$(app_policy opencode)" = no ] || { echo 'opencode opt-out was not recorded' >&2; exit 1; }

mkdir -p "$STATE/localsend/1.0"
: > "$STATE/localsend-version"
ln -s "$STATE/localsend/1.0/localsend_app" "$BIN/localsend"
printf '# NIRUX owner: %s\n[Desktop Entry]\n' "$NIRUX_PREFIX" > "$T/prefix/share/applications/localsend.desktop"
remove_app localsend
[ ! -e "$BIN/localsend" ] || { echo 'managed LocalSend link was not removed' >&2; exit 1; }
[ ! -e "$T/prefix/share/applications/localsend.desktop" ] || { echo 'owned LocalSend desktop entry was not removed' >&2; exit 1; }
[ ! -e "$STATE/localsend" ] || { echo 'managed LocalSend data was not removed' >&2; exit 1; }
[ "$(app_policy localsend)" = no ] || { echo 'LocalSend removal did not persist opt-out' >&2; exit 1; }

printf '#!/bin/sh\nexit 0\n' > "$BIN/opencode"
chmod +x "$BIN/opencode"
remove_app opencode
[ -x "$BIN/opencode" ] || { echo 'external OpenCode was removed' >&2; exit 1; }
[ "$(app_policy opencode)" = no ] || { echo 'OpenCode removal did not persist opt-out' >&2; exit 1; }
echo 'PASS: optional app choices, removal and external preservation'

# An old app version that still runs is never removed: Helium starts helper
# processes (the camera) from its own directory long after it started.
fail() { echo "$1" >&2; exit 1; }
mkdir -p "$T/fakebin"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/notices"\n' "$T" > "$T/fakebin/notify-send"
chmod +x "$T/fakebin/notify-send"
B=$STATE/browsers
mkdir -p "$B/helium-1.0" "$B/helium-2.0" "$B/helium-3.0"
# A copy of sh stands in for Helium (sleep may be a multi-call binary that
# will not run under another name); the trailing ':' keeps sh from exec'ing
# sleep, so the copy itself stays the running program.
cp "$(command -v sh)" "$B/helium-1.0/helium"
"$B/helium-1.0/helium" -c 'sleep 30; :' & RUNNING=$!
sleep 0.3
[ -n "$(app_dir_running "$B/helium-1.0")" ] || fail 'the stand-in Helium is not seen running'

OLD_PATH=$PATH
export PATH="$T/fakebin:$PATH" DBUS_SESSION_BUS_ADDRESS=unix:path=$T/bus
app_prune_versions "$B" "$B/helium-3.0" Helium 3.0 > "$T/prune.out" || fail 'prune failed'
export PATH="$OLD_PATH"; unset DBUS_SESSION_BUS_ADDRESS
[ -d "$B/helium-1.0" ] || fail 'the running Helium version was removed'
[ ! -e "$B/helium-2.0" ] || fail 'an unused old version was kept'
[ -d "$B/helium-3.0" ] || fail 'the new version was removed'
grep -q 'Keeping helium-1.0 while it runs; restart Helium to use 3.0' "$T/prune.out" || fail "message: $(cat "$T/prune.out")"
grep -q 'Restart Helium to finish its update' "$T/notices" 2>/dev/null || fail 'no restart notice was sent'
kill "$RUNNING"; wait "$RUNNING" 2>/dev/null || :
app_prune_versions "$B" "$B/helium-3.0" Helium 3.0 > "$T/prune.out" || fail 'second prune failed'
[ ! -e "$B/helium-1.0" ] || fail 'the old version stayed after it stopped'
[ -d "$B/helium-3.0" ] || fail 'the new version was removed later'
echo 'PASS: a running old app version is kept until it stops'
