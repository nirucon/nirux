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
printf 'PASS: canonical config accepted by both components\n'
