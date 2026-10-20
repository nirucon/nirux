#!/bin/sh
# Download the pinned Helium release into a clean user prefix, then start it as
# a normal user with the Chromium sandbox enabled. Run as the normal login user,
# not as root; containers are supporting evidence, not a physical desktop test.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state NIRUX_LIBRARY=1
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT" "$TEST/work"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
# shellcheck disable=SC2034 # read by browser_install in the sourced installer
WORK=$TEST/work
platform
# shellcheck disable=SC2034 # read by browser_install in the sourced installer
BROWSER_EFFECTIVE=helium
browser_policy_set helium
browser_install
"$BIN/helium" --version | grep -q "Helium $HELIUM_VERSION"
set +e
timeout 60 "$BIN/helium" --headless=new --disable-gpu --disable-dev-shm-usage \
  --no-first-run --no-default-browser-check --user-data-dir="$TEST/profile" \
  --dump-dom about:blank > "$TEST/dom" 2> "$TEST/stderr"
rc=$?
set -e
if [ "$rc" != 0 ]; then
  cat "$TEST/stderr" >&2
  exit 1
fi
grep -qi '<html' "$TEST/dom"
if grep -q 'No usable sandbox' "$TEST/stderr"; then
  cat "$TEST/stderr" >&2
  exit 1
fi
printf 'PASS: pinned Helium starts as a normal user with the sandbox enabled\n'
