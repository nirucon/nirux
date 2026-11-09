#!/bin/sh
# fetch() must retry a GitHub download with a new query on every attempt:
# GitHub caches a failed response (a 504) per URL, so retrying the same URL
# fails the same way. Other URLs keep their exact address.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
mkdir -p "$TEST/bin"
# A curl that fails until attempt $FAIL_UNTIL and logs every URL it was given.
cat > "$TEST/bin/curl" <<'CURL'
#!/bin/sh
out= url=
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    --connect-timeout|--max-time|--retry) shift 2 ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
printf '%s\n' "$url" >> "$LOG"
n=$(wc -l < "$LOG")
[ "$n" -gt "$FAIL_UNTIL" ] || exit 22
printf 'payload\n' > "$out"
CURL
cat > "$TEST/bin/sleep" <<'SLEEP'
#!/bin/sh
exit 0
SLEEP
chmod +x "$TEST/bin/curl" "$TEST/bin/sleep"
export PATH="$TEST/bin:$PATH" HOME="$TEST/home" NIRUX_LIBRARY=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# Three failures, then success: four attempts, four different queries.
export LOG="$TEST/log1" FAIL_UNTIL=3
fetch https://github.com/nirucon/niruwm/releases/download/v1.0.0/niruwm "$TEST/out1" 2>/dev/null ||
  fail "download did not recover after three failures"
[ "$(cat "$TEST/out1")" = payload ] || fail "payload missing"
[ "$(wc -l < "$LOG")" = 4 ] || fail "expected 4 attempts, got $(wc -l < "$LOG")"
[ "$(sort -u "$LOG" | wc -l)" = 4 ] || fail "an attempt reused a URL (cached 504 would repeat)"
grep -qv '^https://github.com/nirucon/niruwm/releases/download/v1.0.0/niruwm?nirux=' "$LOG" &&
  fail "an attempt changed the asset path"

# The API and tag archives get fresh queries too.
export LOG="$TEST/log2" FAIL_UNTIL=1
fetch https://api.github.com/repos/nirucon/nirux/releases/latest "$TEST/out2" 2>/dev/null || fail "api retry"
[ "$(sort -u "$LOG" | wc -l)" = 2 ] || fail "api attempts reused a URL"

# Other hosts keep their exact URL.
export LOG="$TEST/log3" FAIL_UNTIL=1
fetch https://opencode.ai/files/bin/1.0/opencode.tar.gz "$TEST/out3" 2>/dev/null || fail "plain retry"
[ "$(sort -u "$LOG")" = https://opencode.ai/files/bin/1.0/opencode.tar.gz ] || fail "a non-GitHub URL was changed"

# Persistent failure: gives up after NIRUX_FETCH_ATTEMPTS, returns non-zero,
# leaves no partial file.
export LOG="$TEST/log4" FAIL_UNTIL=999 NIRUX_FETCH_ATTEMPTS=3
printf partial > "$TEST/out4"
if fetch https://github.com/nirucon/x/releases/download/v1/x "$TEST/out4" 2>/dev/null; then
  fail "a persistent failure reported success"
fi
[ "$(wc -l < "$LOG")" = 3 ] || fail "expected 3 attempts before giving up"
[ ! -e "$TEST/out4" ] || fail "a failed download left a file behind"
printf 'fetch-retry: ok\n'
