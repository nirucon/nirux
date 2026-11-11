#!/bin/sh
# Shared NIRUWM/NIRUBAR configuration contract. No X server or network needed.
set -eu
WM=${1:?usage: config-contract.sh NIRUWM NIRUBAR}
BAR=${2:?usage: config-contract.sh NIRUWM NIRUBAR}
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
mkdir -p "$TEST/home/.config/niruwm"
config=$TEST/home/.config/niruwm/config.toml
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

check() {
  name=$1
  expected=$2
  cp "$3" "$config"
  set +e
  XDG_CONFIG_HOME=$TEST/home/.config HOME=$TEST/home "$WM" --check-config >/dev/null 2>&1
  wm=$?
  XDG_CONFIG_HOME=$TEST/home/.config HOME=$TEST/home "$BAR" --check-config >/dev/null 2>&1
  bar=$?
  set -e
  if [ "$expected" = ok ]; then
    [ "$wm" = 0 ] || fail "$name: niruwm rejected a valid file"
    [ "$bar" = 0 ] || fail "$name: nirubar rejected a valid file"
  else
    [ "$wm" != 0 ] || fail "$name: niruwm accepted an invalid file"
    [ "$bar" != 0 ] || fail "$name: nirubar accepted an invalid file"
  fi
  [ "$wm" = "$bar" ] || fail "$name: validators disagree (niruwm=$wm nirubar=$bar)"
}

check canonical ok "$SOURCE/config.example.toml"
printf '%s\n' '[bar]' 'modules = ["clock", "future_module"]' > "$TEST/future.toml"
check future-module ok "$TEST/future.toml"
printf '%s\n' '[bar]' 'modules = ["microphone"]' 'microphone_visibility = "muted"' > "$TEST/mic.toml"
check microphone ok "$TEST/mic.toml"
printf '%s\n' '[bar]' 'microphone_visibility = "recording"' > "$TEST/mic-bad.toml"
check microphone-visibility bad "$TEST/mic-bad.toml"
printf '%s\n' '[bar]' 'date_format = "%Q"' > "$TEST/clock.toml"
check clock-format bad "$TEST/clock.toml"
printf '%s\n' '[bar]' 'tags = ["1","2","3","4","5","6","7","8","9","10"]' > "$TEST/tags.toml"
check tags ok "$TEST/tags.toml"
printf '%s\n' '[bar]' 'tags = ["1","2","3","4","5","6","7","8","9","10","11"]' > "$TEST/tags-too-many.toml"
check tags-too-many bad "$TEST/tags-too-many.toml"
printf '%s\n' '[bar]' 'modules = [""]' > "$TEST/module-empty.toml"
check module-empty bad "$TEST/module-empty.toml"
printf '%s\n' '[wallpaper]' 'mode = "bogus"' > "$TEST/wallpaper-mode.toml"
check wallpaper-mode bad "$TEST/wallpaper-mode.toml"
printf '%s\n' '[wallpaper]' 'scale = "bogus"' > "$TEST/wallpaper-scale.toml"
check wallpaper-scale bad "$TEST/wallpaper-scale.toml"
printf '%s\n' '[monitors]' 'workspaces = 0' > "$TEST/monitors.toml"
check monitors bad "$TEST/monitors.toml"
printf '%s\n' '[nightlight]' 'latitude = 91.0' > "$TEST/nightlight.toml"
check nightlight bad "$TEST/nightlight.toml"
printf '%s\n' '[scratchpad]' 'command = ["kitty"]' > "$TEST/scratchpad.toml"
check scratchpad bad "$TEST/scratchpad.toml"
printf '%s\n' '[[scratchpad.slot]]' 'number = 1' 'command = ["kitty", "--class", "scratch-btop", "-e", "btop"]' 'width = 0.8' '[[scratchpad.slot]]' 'number = 4' > "$TEST/scratch-slots.toml"
check scratchpad-slots ok "$TEST/scratch-slots.toml"
printf '%s\n' '[[scratchpad.slot]]' 'number = 10' > "$TEST/scratch-slot-number.toml"
check scratchpad-slot-number bad "$TEST/scratch-slot-number.toml"
printf '%s\n' '[[scratchpad.slot]]' 'number = 2' 'command = ["btop"]' > "$TEST/scratch-slot-class.toml"
check scratchpad-slot-class bad "$TEST/scratch-slot-class.toml"
printf '%s\n' '[[rules]]' 'workspace = 1' > "$TEST/rule.toml"
check rule bad "$TEST/rule.toml"
printf '%s\n' '[wallpaper]' 'enabled = true' 'theme_style = "signature"' > "$TEST/style.toml"
check wallpaper-style ok "$TEST/style.toml"
printf '%s\n' '[wallpaper]' 'theme_style = "photo"' > "$TEST/style-bad.toml"
check wallpaper-style-value bad "$TEST/style-bad.toml"
# Every key NIRUWM knows, as it writes them: a key the bar does not know
# makes the bar start without the user's settings.
printf '' > "$config"
XDG_CONFIG_HOME=$TEST/home/.config HOME=$TEST/home "$WM" --dump-config > "$TEST/dump.toml" ||
  fail 'niruwm --dump-config failed'
check every-niruwm-key ok "$TEST/dump.toml"
printf 'PASS: shared configuration fixtures agree in NIRUWM and NIRUBAR\n'
