#!/bin/sh
# NIRUX 0.12.272: the gradual night light (NIRUWM 0.30) becomes the default.
# A [nightlight] that still has the previous defaults moves to gradual once,
# with the new keys and a copy in the config history; other choices are kept,
# and a change back to solar after the first run is never undone.
# Offline: nothing outside a temporary HOME is touched.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
HISTORY=$XDG_STATE_HOME/niruwm/config-history
MARKER=$STATE/nightlight-gradual-0.12.272
history_count() { find "$HISTORY" -name '*.toml' 2>/dev/null | wc -l; }
key() { toml_value "$1" nightlight "$2"; }
fresh() { rm -f "$MARKER"; }

# 1. The previous defaults, in any location, with other sections around.
fresh
cat > "$TEST/old.toml" <<'TOML'
theme = "niru-noir"

[nightlight]
latitude = 57.7
longitude = 11.97
temperature = 2700
mode = "solar"
on = "20:00"
off = "07:00"
day_temperature = 6500

[brightness]
step = 5
TOML
cp "$TEST/old.toml" "$TEST/old.orig"
upgrade_nightlight_gradual "$TEST/old.toml" "$TEST/old.orig" > "$TEST/out.log"
[ "$(key "$TEST/old.toml" mode)" = gradual ] || fail "previous defaults were not moved to gradual"
[ "$(key "$TEST/old.toml" start_temperature)" = 4500 ] || fail "start_temperature was not written"
[ "$(key "$TEST/old.toml" not_before)" = 19:00 ] || fail "not_before was not written"
[ "$(key "$TEST/old.toml" deepest_at)" = 22:00 ] || fail "deepest_at was not written"
[ "$(key "$TEST/old.toml" latitude)" = 57.7 ] || fail "the location was changed"
[ "$(toml_value "$TEST/old.toml" brightness step)" = 5 ] || fail "another section was changed"
[ "$(grep -c '^start_temperature' "$TEST/old.toml")" = 1 ] || fail "start_temperature written twice"
awk '/^\[brightness\]/ { b = 1 } /^start_temperature/ && b { bad = 1 } END { exit bad }' "$TEST/old.toml" ||
  fail "a new key landed outside [nightlight]"
[ "$(history_count)" -ge 1 ] || fail "the old file was not kept in the config history"
grep -rqx 'mode = "solar"' "$HISTORY" || fail "the history copy is not the file as it was"
grep -q 'Night light is now gradual' "$TEST/out.log" || fail "the change was not reported"
[ -e "$MARKER" ] || fail "the migration did not leave its marker"

# 2. Once only: a change back to solar after the first run stays.
sed 's/^mode = "gradual"/mode = "solar"/' "$TEST/old.toml" > "$TEST/back.toml"
upgrade_nightlight_gradual "$TEST/back.toml" > /dev/null
[ "$(key "$TEST/back.toml" mode)" = solar ] || fail "a change back to solar was undone"

# 3. Other choices are not changed (and the marker is still set afterwards).
for variant in 'mode = "fixed"' 'mode = "manual"' 'temperature = 3000' 'on = "21:00"' \
               'off = "06:30"' 'day_temperature = 6000'; do
  fresh
  name=${variant%% *}
  {
    printf '[nightlight]\n'
    for line in 'temperature = 2700' 'mode = "solar"' 'on = "20:00"' 'off = "07:00"' 'day_temperature = 6500'; do
      if [ "${line%% *}" = "$name" ]; then printf '%s\n' "$variant"; else printf '%s\n' "$line"; fi
    done
  } > "$TEST/choice.toml"
  cp "$TEST/choice.toml" "$TEST/choice.before"
  upgrade_nightlight_gradual "$TEST/choice.toml" > /dev/null
  same_file "$TEST/choice.toml" "$TEST/choice.before" || fail "a chosen $variant was changed"
  [ -e "$MARKER" ] || fail "no marker after a kept choice ($variant)"
done

# 4. Missing keys count as the previous defaults (an older file).
fresh
printf '[nightlight]\nmode = "solar" # follows the sun\n' > "$TEST/short.toml"
upgrade_nightlight_gradual "$TEST/short.toml" > /dev/null
[ "$(key "$TEST/short.toml" mode)" = gradual ] || fail "a short solar section was not moved"
[ "$(key "$TEST/short.toml" deepest_at)" = 22:00 ] || fail "deepest_at missing in a short section"

# 5. No [nightlight] section: nothing to move (the section is added from the
#    example elsewhere, which already says gradual).
fresh
printf 'theme = "niru-noir"\n' > "$TEST/none.toml"
cp "$TEST/none.toml" "$TEST/none.before"
upgrade_nightlight_gradual "$TEST/none.toml" > /dev/null
same_file "$TEST/none.toml" "$TEST/none.before" || fail "a file without [nightlight] was changed"

# 6. The shipped example is gradual with the new keys.
for k in start_temperature not_before deepest_at; do
  [ -n "$(key "$SOURCE/config.example.toml" "$k")" ] || fail "config.example.toml lacks $k"
done
[ "$(key "$SOURCE/config.example.toml" mode)" = gradual ] || fail "config.example.toml is not gradual"

printf 'nightlight-gradual: ok\n'
