#!/bin/sh
# nirux stale: which running programs are on an old version, from a fake
# /proc (NIRUX_PROC) whose exe links point into a fake NIRUX state.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home NIRUX_PREFIX=$T/prefix NIRUX_SYSTEM_ROOT=$T/root NIRUX_LIBRARY=1
mkdir -p "$HOME" "$T/prefix/bin"
# shellcheck source=/dev/null
. "$SOURCE/nirux"
STATE=$T/prefix/share/nirux
fail() { echo "FAIL: $1" >&2; exit 1; }
G=$STATE/generations
mkdir -p "$G/1-old/bin" "$G/2-new/bin" "$STATE/browsers/helium-1" "$STATE/browsers/helium-2" "$STATE/opencode/9"
for p in niruwm nirubar niruidle nirulock niructl; do printf '%s new\n' "$p" > "$G/2-new/bin/$p"; done
printf 'niruwm old\n' > "$G/1-old/bin/niruwm"
printf 'nirubar new\n' > "$G/1-old/bin/nirubar"      # unchanged by the update
printf 'niruidle old\n' > "$G/1-old/bin/niruidle"
printf 'nirulock old\n' > "$G/1-old/bin/nirulock"    # the lock that is up now
ln -s "$G/2-new" "$STATE/current"
ln -s "$STATE/browsers/helium-2" "$STATE/browser-current"
ln -s "$STATE/opencode/9" "$STATE/opencode/current"
P=$T/proc
proc() { mkdir -p "$P/$1"; ln -s "$2" "$P/$1/exe"; }
proc 10 "$G/1-old/bin/niruwm"
proc 11 "$G/1-old/bin/nirubar"
proc 12 "$G/1-old/bin/niruidle"
proc 13 "$G/1-old/bin/nirulock"
proc 14 "$STATE/browsers/helium-1/helium (deleted)"
proc 15 "$STATE/browsers/helium-1/helium_crashpad_handler (deleted)"
proc 16 "$STATE/browsers/helium-2/helium"
proc 17 "$STATE/opencode/9/opencode"
proc 18 /usr/bin/bash
export NIRUX_PROC=$P
out=$(stale_scan)
[ "$out" = "Helium	helium	manual
NIRUIDLE	niruidle	relogin
NIRUWM	niruwm	auto" ] || fail "stale list: $out"
json=$(stale_json)
[ "$json" = '{"stale":[{"name":"Helium","program":"helium","restart":"manual"},{"name":"NIRUIDLE","program":"niruidle","restart":"relogin"},{"name":"NIRUWM","program":"niruwm","restart":"auto"}]}' ] || fail "json: $json"
stale_command | grep -q 'NIRUWM *nirux stale restart restarts it' || fail 'human list'
rm -rf "$P"; mkdir -p "$P"; proc 20 "$G/2-new/bin/niruwm"
[ "$(stale_json)" = '{"stale":[]}' ] || fail 'a current session is reported stale'
stale_command | grep -q 'Nothing runs an old version' || fail 'empty message'
echo 'stale: OK'
