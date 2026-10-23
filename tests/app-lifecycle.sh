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
