#!/bin/sh
# Build ./nirux from the parts in src/, in file-name order.
# The parts are the source; ./nirux is the file every host runs, every test
# loads and every release ships, so nothing outside this repository changes.
#   tools/build.sh          write ./nirux
#   tools/build.sh --check  fail when ./nirux differs from src/ (CI, release)
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
OUT=$ROOT/nirux
tmp=$(mktemp "$ROOT/.nirux.build.XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM
set -- "${1:-}"
for part in "$ROOT"/src/[0-9][0-9]-*.sh; do
  [ -f "$part" ] || { echo "build: no parts in $ROOT/src" >&2; exit 1; }
  # Every part ends with a newline, so parts never run into each other.
  [ -z "$(tail -c 1 "$part")" ] || { echo "build: $part does not end with a newline" >&2; exit 1; }
  cat "$part" >> "$tmp"
done
sh -n "$tmp" || { echo 'build: the joined script has a syntax error' >&2; exit 1; }
case "$1" in
  --check)
    if cmp -s "$tmp" "$OUT"; then echo 'build: nirux matches src/'; exit 0; fi
    echo 'build: nirux differs from src/: edit src/, then run tools/build.sh' >&2
    diff -u "$OUT" "$tmp" | head -n 40 >&2 || :
    exit 1 ;;
  '')
    chmod 755 "$tmp"; mv -f "$tmp" "$OUT"; trap - EXIT HUP INT TERM
    echo "build: wrote nirux ($(wc -l < "$OUT") lines from $(ls "$ROOT"/src/[0-9][0-9]-*.sh | wc -l) parts)" ;;
  *) echo 'usage: tools/build.sh [--check]' >&2; exit 2 ;;
esac
