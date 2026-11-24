#!/bin/sh
# shellcheck disable=SC2034 # variables are read by the sourced nirux functions
# Widevine in Helium: the module named by Mozilla's update list is downloaded,
# checked (SHA-512), unpacked from its CRX3 and named in Helium's hint file;
# a current module is not downloaded again, a bad download changes nothing,
# a module the user set up is left alone, a stale hint is replaced, old
# versions are pruned to the current one plus one, and nirux widevine off
# removes everything NIRUX put there. Offline: the list and the module are
# local files.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state NIRUX_LIBRARY=1
export NIRUX_WIDEVINE_UPDATE_URL="file://$TEST/feed/%PLATFORM%.xml" NIRUX_WIDEVINE_ARCH=x86_64
export NIRUX_FETCH_ATTEMPTS=1
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT" "$TEST/bin" "$TEST/work" "$TEST/feed"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
WORK=$TEST/work
# A Helium on PATH (not managed by NIRUX: the hint works for any Helium).
printf '#!/bin/sh\necho "Helium 0.22.2.1"\n' > "$TEST/bin/helium"; chmod +x "$TEST/bin/helium"
PATH=$TEST/bin:$PATH
HINT=$XDG_CONFIG_HOME/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm

# A module VERSION as Google ships it: a CRX3 header in front of a zip.
module() {
  m=$TEST/build-$1; rm -rf "$m"; mkdir -p "$m/_platform_specific/linux_x64"
  printf '{\n  "name": "WidevineCdm",\n  "version": "%s"\n}\n' "$1" > "$m/manifest.json"
  printf 'fake cdm %s\n' "$1" > "$m/_platform_specific/linux_x64/libwidevinecdm.so"
  (cd "$m" && zip -q -r "$TEST/m.zip" manifest.json _platform_specific)
  { printf 'Cr24\003\000\000\000\005\000\000\000HEADR'; cat "$TEST/m.zip"; } > "$TEST/feed/cdm-$1.crx3"
  rm -f "$TEST/m.zip"
}
# Mozilla's answer naming VERSION, with its checksum (or $2 instead).
feed() {
  sum=${2:-$(sha512sum "$TEST/feed/cdm-$1.crx3" | cut -d ' ' -f1)}
  cat > "$TEST/feed/Linux_x86_64-gcc3.xml" <<EOF
<?xml version="1.0"?>
<updates>
    <addons>
        <addon id="gmp-gmpopenh264" URL="https://example.invalid/openh264.zip" hashFunction="sha512" hashValue="$sum" size="1" version="2.6.0"/>
        <addon id="gmp-widevinecdm" URL="file://$TEST/feed/cdm-$1.crx3" hashFunction="sha512" hashValue="$sum" size="1" version="$1">
            <mirror URL="https://example.invalid/mirror.crx3"/>
        </addon>
    </addons>
</updates>
EOF
}
hint_path() { sed -n 's/.*"Path":"\([^"]*\)".*/\1/p' "$HINT"; }

# 1. On by default: downloaded, unpacked, named in the hint.
module 4.10.3050.0; feed 4.10.3050.0
[ "$(widevine_policy)" = on ] || fail 'Widevine is not on by default'
out=$(widevine_apply 2>&1)
printf '%s\n' "$out" | grep -q 'Widevine in Helium: 4.10.3050.0 installed' || fail "first apply: $out"
[ "$(hint_path)" = "$STATE/widevine/4.10.3050.0" ] || fail "hint names $(hint_path)"
[ -f "$STATE/widevine/4.10.3050.0/_platform_specific/linux_x64/libwidevinecdm.so" ] || fail 'module not unpacked'
widevine_doctor | grep -q 'widevine: 4.10.3050.0 on' || fail "doctor: $(widevine_doctor)"
[ ! -e "$WORK/widevine" ] || fail 'download directory left behind'

# 2. Current: nothing is downloaded again.
rm -f "$TEST/feed/cdm-4.10.3050.0.crx3"
out=$(widevine_apply 2>&1)
printf '%s\n' "$out" | grep -q '4.10.3050.0 is current' || fail "second apply: $out"

# 3. A newer module with a wrong checksum changes nothing.
module 4.10.3100.0; feed 4.10.3100.0 "$(printf '%0128d' 0)"
out=$(widevine_apply 2>&1)
printf '%s\n' "$out" | grep -q 'does not match its checksum' || fail "bad checksum: $out"
[ "$(hint_path)" = "$STATE/widevine/4.10.3050.0" ] || fail 'a bad download changed the hint'
[ ! -e "$STATE/widevine/4.10.3100.0" ] || fail 'a bad download was installed'

# 4. Newer and good: installed; the previous one is kept as the spare.
feed 4.10.3100.0
out=$(widevine_apply 2>&1)
printf '%s\n' "$out" | grep -q '4.10.3100.0 installed' || fail "update: $out"
[ "$(hint_path)" = "$STATE/widevine/4.10.3100.0" ] || fail 'hint not moved to the new module'
[ -d "$STATE/widevine/4.10.3050.0" ] || fail 'the previous module was not kept'

# 5. One more: the oldest goes, current plus one stay.
module 4.10.3200.0; feed 4.10.3200.0
widevine_apply >/dev/null 2>&1
[ "$(hint_path)" = "$STATE/widevine/4.10.3200.0" ] || fail 'third module not used'
[ -d "$STATE/widevine/4.10.3100.0" ] && [ ! -e "$STATE/widevine/4.10.3050.0" ] || \
  fail "prune kept: $(ls "$STATE/widevine")"

# 6. Offline: the installed module stays and the update goes on.
rm -f "$TEST/feed/Linux_x86_64-gcc3.xml"
out=$(widevine_apply 2>&1) || fail 'offline apply failed the update'
printf '%s\n' "$out" | grep -q 'could not check for a newer module' || fail "offline: $out"
[ "$(hint_path)" = "$STATE/widevine/4.10.3200.0" ] || fail 'offline changed the hint'

# 7. The user's own module is left alone; a stale hint is replaced.
own=$TEST/own-cdm; mkdir -p "$own/_platform_specific/linux_x64"
printf '{"version": "4.10.2830.0"}\n' > "$own/manifest.json"; : > "$own/_platform_specific/linux_x64/libwidevinecdm.so"
printf '{"Path":"%s"}' "$own" > "$HINT"
feed 4.10.3200.0
out=$(widevine_apply 2>&1)
printf '%s\n' "$out" | grep -q "using your own module at $own" || fail "own module: $out"
[ "$(hint_path)" = "$own" ] || fail 'the user hint was replaced'
widevine_doctor | grep -q 'uses your own module 4.10.2830.0' || fail "doctor own: $(widevine_doctor)"
printf '{"Path":"%s"}' "$TEST/gone" > "$HINT"
widevine_apply >/dev/null 2>&1
[ "$(hint_path)" = "$STATE/widevine/4.10.3200.0" ] || fail 'a stale hint was not replaced'

# 8. Off removes the module and our hint, and stays off.
out=$(widevine_command off 2>&1)
[ "$(widevine_policy)" = off ] || fail 'off was not kept'
[ ! -e "$HINT" ] && [ ! -e "$STATE/widevine" ] || fail 'off left the module or the hint'
widevine_apply >/dev/null 2>&1
[ ! -e "$HINT" ] || fail 'an update brought Widevine back while off'
widevine_doctor | grep -q 'widevine: off' || fail "doctor off: $(widevine_doctor)"
# Off does not touch a hint the user wrote.
printf '{"Path":"%s"}' "$own" > "$HINT"
widevine_command off >/dev/null 2>&1
[ "$(hint_path)" = "$own" ] || fail 'off removed the user hint'
rm -f "$HINT"

# 9. On again installs at once.
out=$(widevine_command on 2>&1) || fail "on: $out"
[ "$(widevine_policy)" = on ] && [ "$(hint_path)" = "$STATE/widevine/4.10.3200.0" ] || fail "on did not install: $out"

# 10. No Helium at all: nothing is downloaded.
rm -rf "$XDG_CONFIG_HOME/net.imput.helium" "$STATE/widevine" "$TEST/bin/helium"
PATH=$TEST/bin:/usr/bin:/bin
out=$(widevine_apply 2>&1)
[ -z "$out" ] && [ ! -e "$STATE/widevine" ] || fail "no Helium: $out"

echo 'PASS: Widevine download, checksum, CRX3 unpack, hint, update, prune, offline, own module, off and on'
