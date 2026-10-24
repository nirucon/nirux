#!/bin/sh
# Validate the canonical fresh-install config with actual component binaries.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export XDG_CONFIG_HOME=$TEST/config
mkdir -p "$XDG_CONFIG_HOME/niruwm"
install -m 600 "$SOURCE/config.example.toml" "$XDG_CONFIG_HOME/niruwm/config.toml"
"${1:-niruwm}" --check-config
"${2:-nirubar}" --check-config

# NIRUX's example is not a copy of NIRUWM's: it selects the managed browser,
# the full module list, the LocalSend rule and the screenshot bindings. An
# update that overwrites it with the component example silently changes those
# defaults (0.11.1 shipped brave instead of helium that way), so pin the ones
# a user would notice.
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
EXAMPLE="$SOURCE/config.example.toml"
grep -qx 'browser = \["helium"\]' "$EXAMPLE" ||
  fail 'the managed browser default is not helium'
grep -q '^\[idle\]' "$EXAMPLE" ||
  fail 'the [idle] section is missing, so updates cannot migrate it'
grep -q 'nirushot --full' "$EXAMPLE" ||
  fail 'the screenshot binding does not use nirushot'

printf 'PASS: canonical config accepted by both components\n'
