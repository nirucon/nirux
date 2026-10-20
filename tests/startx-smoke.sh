#!/bin/sh
# Exercise the generated xinitrc through real startx/xinit, using Xvfb as the
# server so this can run without a GPU or a local TTY in an isolated container.
set -eu
BIN=${1:?usage: startx-smoke.sh BINDIR HOME}
export HOME=${2:?missing test home}
export XDG_CONFIG_HOME=$HOME/.config XAUTHORITY=$HOME/.Xauthority DISPLAY=:97
export PATH=$BIN:$PATH
cleanup() {
  "$BIN/niructl" quit >/dev/null 2>&1 || :
  [ -z "${START:-}" ] || kill "$START" 2>/dev/null || :
}
trap cleanup EXIT INT TERM
startx -- "$(command -v Xvfb)" :97 -screen 0 1280x800x24 -nolisten tcp > "$HOME/startx-test.log" 2>&1 &
START=$!
i=0
while [ "$i" -lt 100 ]; do
  if xwininfo -root -tree 2>/dev/null | grep -q NIRUBAR; then break; fi
  i=$((i + 1)); sleep 0.1
done
if [ "$i" = 100 ]; then cat "$HOME/startx-test.log"; exit 1; fi
"$BIN/niructl" status
"$BIN/niructl" restart-bar
# Theme-follow wallpaper: only assert when NIRUX installed the assets and a
# real wallpaper setter is present. The WM must change the root pixmap.
if [ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-nord-4k.png" ] && command -v feh >/dev/null 2>&1; then
  before=$(xprop -root _XROOTPMAP_ID 2>/dev/null || :)
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
fi
if command -v maim >/dev/null 2>&1; then
  maim "$HOME/startx-screenshot.png"
  [ -s "$HOME/startx-screenshot.png" ] || { printf 'maim produced no screenshot\n' >&2; exit 1; }
fi
"$BIN/niructl" quit
wait "$START"
START=
printf 'PASS: startx uses generated xinitrc; WM/bar start, restart and exit\n'
