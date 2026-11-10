#!/bin/sh
# An update applies the new generation to the running session: NIRUWM 0.23.0
# and later restart in place (`niructl restart-wm`), an older manager gets the
# bar restart and a clear "log out once" message, and `nirux status` does not
# ask for a new login when the running manager can restart.
# niructl and niruwm are stand-ins; no session, display or host state is used.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system NIRUX_LIBRARY=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir -p "$BIN"
LOG=$TEST/niructl.log
export LOG
# A niructl whose running manager is described by $WM_MODE:
#   new     can restart in place
#   locked  can, but the screen is locked (the restart waits)
#   old     NIRUWM 0.22.x: restart-wm --check exits 3
#   broken  can, but the restart itself fails
cat > "$BIN/niructl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$LOG"
case "$1 ${2:-}" in
  "restart-wm --check")
    case "$WM_MODE" in old) echo "niructl: NIRUWM 0.22.4 cannot restart in place" >&2; exit 3 ;; esac
    exit 0 ;;
  "restart-wm ")
    case "$WM_MODE" in
      locked) echo "The screen is locked: NIRUWM restarts after it is unlocked."; exit 0 ;;
      broken) echo "the window manager did not answer the restart request" >&2; exit 1 ;;
    esac
    echo "Restarted in place: NIRUWM 0.23.0 -> NIRUWM 0.23.1"; exit 0 ;;
  "restart-bar ") exit 0 ;;
esac
exit 2
EOF
chmod 755 "$BIN/niructl"

run() {
  : > "$LOG"
  WM_MODE=$1 DISPLAY=${2-:0} apply_to_running_session 'Updated.' > "$TEST/out" 2>&1
}

run new
grep -q 'Restarted in place: NIRUWM 0.23.0 -> NIRUWM 0.23.1' "$TEST/out" || fail "in-place restart not reported: $(cat "$TEST/out")"
grep -q 'no logout is needed' "$TEST/out" || fail 'in-place restart still asks for a logout'
grep -qx 'restart-wm' "$LOG" || fail 'restart-wm was not run'
! grep -q 'restart-bar' "$LOG" || fail 'restart-bar run in addition to restart-wm'
if grep -qi 'log out' "$TEST/out"; then fail "message asks for a logout: $(cat "$TEST/out")"; fi
printf 'PASS: a capable session is restarted in place\n'

run locked
grep -q 'restarts after it is unlocked' "$TEST/out" || fail "locked deferral not reported: $(cat "$TEST/out")"
printf 'PASS: a locked screen defers the restart\n'

run old
grep -qx 'restart-bar' "$LOG" || fail 'old manager: bar not restarted'
! grep -qx 'restart-wm' "$LOG" || fail 'old manager was asked to restart in place'
grep -q 'older than 0.23.0: log out and back in once' "$TEST/out" || fail "old manager message: $(cat "$TEST/out")"
printf 'PASS: an older manager gets the bar restart and one logout\n'

run broken
grep -q 'niructl restart-wm failed' "$TEST/out" || fail "failed restart not reported: $(cat "$TEST/out")"
grep -qx 'restart-bar' "$LOG" || fail 'failed restart: no bar fallback'
printf 'PASS: a failed restart falls back to the bar\n'

run new ''
[ ! -s "$LOG" ] || fail 'niructl run without a display'
grep -q 'run niructl restart-wm in the NIRU session' "$TEST/out" || fail "no-display message: $(cat "$TEST/out")"
printf 'PASS: outside a session the command to run is named\n'

: > "$LOG"
WM_MODE=new DISPLAY=:0 NIRUX_SESSION_RESTART=0 apply_to_running_session 'Updated.' > "$TEST/out" 2>&1
[ ! -s "$LOG" ] || fail 'session restarted before a power action'
printf 'PASS: update-reboot and update-shutdown do not restart the session first\n'

# nirux status: the line for a running manager from an older generation.
for v in 0.22.4 0.23.0 0.24.1; do
  printf '#!/bin/sh\necho "NIRUWM %s"\n' "$v" > "$TEST/niruwm-$v"
  chmod 755 "$TEST/niruwm-$v"
done
running_wm_status "$TEST/niruwm-0.22.4" > "$TEST/out"
grep -q 'log out and back in once' "$TEST/out" || fail "0.22.4 status: $(cat "$TEST/out")"
for v in 0.23.0 0.24.1; do
  running_wm_status "$TEST/niruwm-$v" > "$TEST/out"
  grep -q 'niructl restart-wm activates the update without logging out' "$TEST/out" || fail "$v status: $(cat "$TEST/out")"
  if grep -qi 'log out and back' "$TEST/out"; then fail "$v status asks for a login"; fi
done
printf 'PASS: nirux status asks for a login only for a manager older than 0.23.0\n'

version_at_least 0.23.0 0.23.0 || fail 'equal versions'
version_at_least 0.23.10 0.23.9 || fail 'numeric compare'
version_at_least 1.0 0.23.0 || fail 'major version'
! version_at_least 0.22.99 0.23.0 || fail 'older minor'
printf 'PASS: version comparison\n'
