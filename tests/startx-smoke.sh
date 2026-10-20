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
# Wallpaper choices and settings: the extra NIRUX images must be listed and
# selectable, and the status must reflect each change.
if [ -x "$BIN/niructl" ]; then
  wallpaper_list=$("$BIN/niructl" wallpaper list)
  printf '%s\n' "$wallpaper_list" | grep -q 'Håvamål 19' || {
    printf 'extra NIRUX wallpaper was not listed\n' >&2
    exit 1
  }
  extra=$(printf '%s\n' "$wallpaper_list" | awk -F '\t' '$1 == "Håvamål 19" {print $2; exit}')
  [ -f "$extra" ] || { printf 'listed extra wallpaper is missing\n' >&2; exit 1; }
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
