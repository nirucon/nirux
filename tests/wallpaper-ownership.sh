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
bundle=$TEST/pack.zip
python3 - "$bundle" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], 'w') as z:
    for colour in ('red', 'blue', 'green', 'noir'):
        for size in ('4k', '8k'):
            z.writestr(f'nirux-wallpaper-carl-larsson-{colour}-{size}.png', b'\x89PNG\r\n\x1a\nfixture')
PY
CARL_LARSSON_BUNDLE_BYTES=$(wc -c < "$bundle" | tr -d ' ')
CARL_LARSSON_BUNDLE_SHA256=$(sha256sum "$bundle" | cut -d ' ' -f1)
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
