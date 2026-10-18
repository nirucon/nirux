#!/bin/sh
# Test this checkout's installer against its pinned, real component releases.
# Only this not-yet-published NIRUX release is supplied as a local fixture.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state NIRUX_LIBRARY=1
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT/etc/pam.d" "$TEST/release"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
cp "$SOURCE/nirux" "$SOURCE/manifest" "$TEST/release/"
(cd "$TEST/release"; sha256sum nirux manifest > SHA256SUMS)
for include in system-auth common-auth common-account; do
  [ ! -f "/etc/pam.d/$include" ] || ln -s "/etc/pam.d/$include" "$ROOT/etc/pam.d/$include"
done
fetch() {
  case "$1" in
    "https://github.com/nirucon/nirux/releases/download/v$VERSION/"*) cp "$TEST/release/${1##*/}" "$2" ;;
    *) curl -fsSL --connect-timeout 20 --max-time 300 --retry 3 -o "$2" "$1" ;;
  esac
}
(install_or_update install --no-packages --display-manager startx --release "$VERSION")
status
doctor
sh "$SOURCE/tests/startx-smoke.sh" "$BIN" "$HOME"
(uninstall --purge)
[ ! -e "$BIN/niruwm" ]
[ ! -e "$ROOT/etc/pam.d/nirulock" ]
printf 'PASS: real pinned releases install, diagnose, launch through startx and uninstall\n'
