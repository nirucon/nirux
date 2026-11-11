#!/bin/sh
# Native private fixture; no real user's wallpapers or external downloads.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home XDG_PICTURES_DIR=$TEST/pictures NIRUX_PREFIX=$TEST/prefix
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state
export NIRUX_LIBRARY=1
. "$SOURCE/nirux"
mkdir -p "$HOME" "$TEST/source" "$TEST/work" "$STATE"
bundle=$TEST/pack.tar.xz
mkdir -p "$TEST/extras"
for colour in red blue green noir; do
  for size in 4k 8k; do
    printf '\211PNG\r\n\032\nfixture\n' > "$TEST/extras/nirux-wallpaper-carl-larsson-$colour-$size.png"
  done
done
tar -C "$TEST/extras" -cJf "$bundle" .
WALLPAPER_EXTRA_ASSETS="nirux-wallpaper-carl-larsson-extras.tar.xz $(wc -c < "$bundle" | tr -d ' ') $(sha256sum "$bundle" | cut -d ' ' -f1)"
fetch() { cp "$bundle" "$2"; }
destination=$(wallpaper_destination)
mkdir -p "$destination"
modified=nirux-wallpaper-carl-larsson-red-4k.png
unmanaged=nirux-wallpaper-carl-larsson-blue-4k.png
printf 'personal modification\n' > "$destination/$modified"
printf 'personal unmanaged image\n' > "$destination/$unmanaged"
printf '%064d  %s\n' 0 "$modified" > "$(wallpaper_manifest)"
WP_WORK=$TEST/work wallpapers_download_pack carl-larsson
wallpapers_remove
[ "$(cat "$destination/$modified")" = 'personal modification' ]
[ "$(cat "$destination/$unmanaged")" = 'personal unmanaged image' ]
printf '%s\n' 'PASS: downloads do not adopt user bytes into removal ownership'

# A theme picture that NIRUX installed in an older version is replaced on
# update; one the user changed is kept; an up-to-date theme is not fetched.
rm -rf "$destination" "$(wallpaper_manifest)" "$TEST/work"
mkdir -p "$destination" "$TEST/work" "$TEST/nord"
printf 'old nord 4k\n' > "$destination/nirux-wallpaper-nord-4k.png"
printf 'my own nord 8k\n' > "$destination/nirux-wallpaper-nord-8k.png"
{ printf '%s  %s\n' "$(sha256sum "$destination/nirux-wallpaper-nord-4k.png" | cut -d ' ' -f1)" nirux-wallpaper-nord-4k.png
  printf '%064d  %s\n' 0 nirux-wallpaper-nord-8k.png; } > "$(wallpaper_manifest)"
for size in 4k 8k; do printf '\211PNG\r\n\032\nnew nord %s\n' "$size" > "$TEST/nord/nirux-wallpaper-nord-$size.png"; done
tar -C "$TEST/nord" -cJf "$TEST/nord.tar.xz" nirux-wallpaper-nord-4k.png nirux-wallpaper-nord-8k.png
nord_bytes=$(wc -c < "$TEST/nord.tar.xz" | tr -d ' ')
nord_sha=$(sha256sum "$TEST/nord.tar.xz" | cut -d ' ' -f1)
WALLPAPER_THEME_ASSETS="nirux-wallpaper-nord.tar.xz $nord_bytes $nord_sha v1.2.0"
WALLPAPER_THEME_PNGS="nirux-wallpaper-nord-4k.png $(sha256sum "$TEST/nord/nirux-wallpaper-nord-4k.png" | cut -d ' ' -f1)
nirux-wallpaper-nord-8k.png $(sha256sum "$TEST/nord/nirux-wallpaper-nord-8k.png" | cut -d ' ' -f1)"
WALLPAPER_OPTIONAL_THEMES=nord
fetched=
fetch() { fetched=$1; cp "$TEST/nord.tar.xz" "$2"; }
refresh_running_theme() { :; }
wallpaper_theme_outdated nord
wallpapers_refresh_installed > "$TEST/refresh.log"
grep -q 'new nord 4k' "$destination/nirux-wallpaper-nord-4k.png"
[ "$(cat "$destination/nirux-wallpaper-nord-8k.png")" = 'my own nord 8k' ]
! wallpaper_theme_outdated nord
fetched=
wallpapers_refresh_installed > "$TEST/refresh2.log"
[ ! -s "$TEST/refresh2.log" ]
[ "$(wallpaper_asset_release nirux-wallpaper-nord.tar.xz)" = v1.2.0 ]
[ "$(wallpaper_asset_release nirux-wallpaper-satie-extras.tar.xz)" = v1.0.0 ]
printf '%s\n' 'PASS: an older NIRUX theme picture is replaced on update, a changed one kept'
