#!/bin/sh
# Exercise the generated xinitrc through real startx/xinit, using Xvfb as the
# server so this can run without a GPU or a local TTY in an isolated container.
set -eu
BIN=${1:?usage: startx-smoke.sh BINDIR HOME}
export HOME=${2:?missing test home}
export XDG_CONFIG_HOME=$HOME/.config XAUTHORITY=$HOME/.Xauthority DISPLAY=:97
export XDG_RUNTIME_DIR=$HOME/runtime
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export PATH=$BIN:$PATH
cleanup() {
  "$BIN/niructl" quit >/dev/null 2>&1 || :
  [ -z "${START:-}" ] || kill "$START" 2>/dev/null || :
}
trap cleanup EXIT INT TERM
# Configure two autostart entries on different workspaces before starting X.
# The sequence must launch them in workspace order and return to workspace 1.
autostart_cfg=$XDG_CONFIG_HOME/niruwm/config.toml
autostart_tmp=$(mktemp)
awk '
  /^\[autostart\]$/ { inside = 1 }
  inside && /^enabled[[:space:]]*=/ { print "enabled = true"; next }
  inside && /^settle_seconds[[:space:]]*=/ { print "settle_seconds = 1"; inside = 0; next }
  { print }
' "$autostart_cfg" > "$autostart_tmp"
mv "$autostart_tmp" "$autostart_cfg"
cat >> "$autostart_cfg" <<EOF
[[autostart.apps]]
workspace = 2
command = ["sh", "-c", "niructl status >> '$HOME/autostart-2'"]
[[autostart.apps]]
workspace = 1
command = ["sh", "-c", "niructl status >> '$HOME/autostart-1'"]
EOF

startx -- "$(command -v Xvfb)" :97 -screen 0 1280x800x24 -nolisten tcp > "$HOME/startx-test.log" 2>&1 &
START=$!
i=0
while [ "$i" -lt 100 ]; do
  if xwininfo -root -tree 2>/dev/null | grep -q NIRUBAR; then break; fi
  i=$((i + 1)); sleep 0.1
done
if [ "$i" = 100 ]; then cat "$HOME/startx-test.log"; exit 1; fi
if [ -x "$BIN/nirunotify" ]; then
  i=0
  while [ "$i" -lt 100 ]; do
    "$BIN/nirunotify" --history 2>/dev/null | grep -q 'Welcome to NIRUX' && break
    i=$((i + 1)); sleep 0.1
  done
  [ "$i" -lt 100 ] || {
    printf 'startx welcome notification did not appear\n' >&2
    "$BIN/nirunotify" --count 2>&1 >&2 || :
    pgrep -a nirunotify >&2 || :
    [ ! -f "$HOME/.local/state/niruwm/session.log" ] || tail -30 "$HOME/.local/state/niruwm/session.log" >&2
    exit 1
  }
fi
i=0
while [ "$i" -lt 100 ]; do
  if [ -f "$HOME/autostart-1" ] && [ -f "$HOME/autostart-2" ]; then break; fi
  i=$((i + 1)); sleep 0.1
done
[ -f "$HOME/autostart-1" ] && [ -f "$HOME/autostart-2" ] || {
  printf 'autostart entries did not run\n' >&2
  [ ! -f "$HOME/.local/state/niruwm/session.log" ] || tail -40 "$HOME/.local/state/niruwm/session.log" >&2
  exit 1
}
sleep 2.5
autostart_status=$("$BIN/niructl" status)
printf '%s\n' "$autostart_status" | grep -q 'tag=1' || {
  printf 'autostart did not return to workspace 1\n' >&2
  exit 1
}
grep -q 'tag=2' "$HOME/autostart-2" || { printf 'autostart ran on the wrong workspace\n' >&2; exit 1; }
grep -q 'tag=1' "$HOME/autostart-1" || { printf 'autostart ran on the wrong workspace\n' >&2; exit 1; }
# Provider-aware DND must reach the running native notifier.
if [ -x "$BIN/nirunotify" ]; then
  "$BIN/niructl" dnd status | grep -qx 'dnd off' || {
    "$BIN/niructl" dnd status >&2 || :
    printf 'native DND is not off at session start\n' >&2
    exit 1
  }
  "$BIN/niructl" dnd toggle >/dev/null
  "$BIN/niructl" dnd status | grep -qx 'dnd on' || {
    printf 'niructl did not reach the native DND provider\n' >&2
    exit 1
  }
  "$BIN/niructl" dnd toggle >/dev/null
fi
"$BIN/niructl" status
"$BIN/niructl" restart-bar
# Theme-follow wallpaper: only assert when NIRUX installed the assets and a
# real wallpaper setter is present. The WM must change the root pixmap.
if [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-nord-4k.png" ] && command -v feh >/dev/null 2>&1; then
  before=$(xprop -root _XROOTPMAP_ID 2>/dev/null || :)
  kitty_before=$(sha256sum "$XDG_CONFIG_HOME/nirux/theme/kitty.conf" 2>/dev/null | cut -d' ' -f1 || :)
  fish_before=$(sha256sum "$XDG_CONFIG_HOME/nirux/theme/fish.fish" 2>/dev/null | cut -d' ' -f1 || :)
  "$BIN/niructl" theme niru-nord
  after=$(xprop -root _XROOTPMAP_ID 2>/dev/null || :)
  [ -n "$before" ] && [ -n "$after" ] && [ "$before" != "$after" ] || {
    printf 'theme change did not replace the root wallpaper\n' >&2
    exit 1
  }
  sleep 0.5
  xwininfo -root -tree 2>/dev/null | grep -q NIRUBAR || {
    printf 'bar disappeared after the theme change\n' >&2
    exit 1
  }
  kitty_after=$(sha256sum "$XDG_CONFIG_HOME/nirux/theme/kitty.conf" 2>/dev/null | cut -d' ' -f1 || :)
  fish_after=$(sha256sum "$XDG_CONFIG_HOME/nirux/theme/fish.fish" 2>/dev/null | cut -d' ' -f1 || :)
  if [ -n "$kitty_before" ] && [ -n "$kitty_after" ]; then
    [ "$kitty_before" != "$kitty_after" ] || {
      printf 'terminal theme did not follow the theme change\n' >&2
      exit 1
    }
  fi
  if [ -n "$fish_before" ] && [ -n "$fish_after" ]; then
    [ "$fish_before" != "$fish_after" ] || {
      printf 'fish theme did not follow the theme change\n' >&2
      exit 1
    }
  fi
fi
if command -v maim >/dev/null 2>&1; then
  maim "$HOME/startx-screenshot.png"
  [ -s "$HOME/startx-screenshot.png" ] || { printf 'maim produced no screenshot\n' >&2; exit 1; }
fi
# Wallpaper choices and settings: a theme wallpaper must be listed and
# selectable, and the status must reflect each change.
if [ -x "$BIN/niructl" ]; then
  wallpaper_list=$("$BIN/niructl" wallpaper list)
  printf '%s\n' "$wallpaper_list" | grep -q 'Niru Nord' || {
    printf 'theme wallpaper was not listed\n' >&2
    exit 1
  }
  extra=$(printf '%s\n' "$wallpaper_list" | awk -F '\t' '$1 == "Niru Nord" {print $2; exit}')
  [ -f "$extra" ] || { printf 'listed theme wallpaper is missing\n' >&2; exit 1; }
  before_pixmap=$(xprop -root _XROOTPMAP_ID 2>/dev/null || :)
  "$BIN/niructl" wallpaper set "$extra"
  sleep 0.3
  after_pixmap=$(xprop -root _XROOTPMAP_ID 2>/dev/null || :)
  [ -n "$before_pixmap" ] && [ -n "$after_pixmap" ] && [ "$before_pixmap" != "$after_pixmap" ] || {
    printf 'wallpaper selection did not replace the root pixmap\n' >&2
    exit 1
  }
  "$BIN/niructl" wallpaper mode fixed
  "$BIN/niructl" wallpaper rotation 30
  "$BIN/niructl" wallpaper scale fit
  "$BIN/niructl" wallpaper follow-theme off
  wallpaper_status=$("$BIN/niructl" wallpaper status)
  printf '%s\n' "$wallpaper_status" | grep -qx 'mode=fixed' || { printf 'wallpaper mode was not saved\n' >&2; exit 1; }
  printf '%s\n' "$wallpaper_status" | grep -qx 'rotation_minutes=30' || { printf 'wallpaper rotation was not saved\n' >&2; exit 1; }
  printf '%s\n' "$wallpaper_status" | grep -qx 'scale=fit' || { printf 'wallpaper scale was not saved\n' >&2; exit 1; }
  printf '%s\n' "$wallpaper_status" | grep -qx 'follow_theme=false' || { printf 'wallpaper follow-theme was not saved\n' >&2; exit 1; }
  printf '%s\n' "$wallpaper_status" | grep -qx "file=$extra" || { printf 'wallpaper file was not saved\n' >&2; exit 1; }
fi
"$BIN/niructl" quit
wait "$START"
START=
printf 'PASS: startx uses generated xinitrc; WM/bar start, restart and exit\n'
