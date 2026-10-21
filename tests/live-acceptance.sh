#!/bin/sh
# Read-only checks for an already running NIRUX X session.
# Run inside the session, or over SSH: the script discovers DISPLAY, XAUTHORITY
# and the session bus from the running NIRUWM process.
set -eu
PATH="$HOME/.local/bin:$PATH"
export PATH
failures=0
warnings=0
pass() { printf 'PASS: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }

if [ -z "${DISPLAY:-}" ]; then
  wm_pid=$(pgrep -u "$(id -u)" -x niruwm | head -1 || true)
  [ -n "$wm_pid" ] || { echo 'FAIL: no running NIRUWM and DISPLAY is unset' >&2; exit 1; }
  export DISPLAY
  DISPLAY=$(tr '\0' '\n' < "/proc/$wm_pid/environ" | sed -n 's/^DISPLAY=//p')
  XAUTHORITY=$(tr '\0' '\n' < "/proc/$wm_pid/environ" | sed -n 's/^XAUTHORITY=//p') || :
  DBUS_SESSION_BUS_ADDRESS=$(tr '\0' '\n' < "/proc/$wm_pid/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p') || :
  export DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS
fi
wm_pid=$(pgrep -u "$(id -u)" -x niruwm | head -1 || true)
[ -n "$wm_pid" ] || { echo 'FAIL: NIRUWM is not running'; exit 1; }

printf 'NIRUX live acceptance: DISPLAY=%s WM pid=%s\n' "$DISPLAY" "$wm_pid"
for program in nirux niruwm nirubar nirunotify niructl nirulock niruscreensaver; do
  if command -v "$program" >/dev/null 2>&1; then
    pass "$(command -v "$program") $("$program" --version 2>/dev/null | head -1)"
  else
    fail "$program is not in PATH"
  fi
done

if command -v xrandr >/dev/null 2>&1; then
  connected=$(xrandr --query 2>/dev/null | grep -c ' connected' || true)
  pass "connected displays: $connected"
  xrandr --query 2>/dev/null | sed -n '1p;/ connected/p'
  [ "$connected" -gt 1 ] || warn 'external display and hotplug path were not exercised'
else
  warn 'xrandr is unavailable'
fi

if [ -f /etc/polkit-1/rules.d/49-nirux-power.rules ]; then
  pass 'NIRUX local power rule is installed'
else
  fail 'NIRUX local power rule is missing'
fi
if command -v pkcheck >/dev/null 2>&1; then
  for action in power-off reboot suspend; do
    if pkcheck --action-id "org.freedesktop.login1.$action" --process "$wm_pid" >/dev/null 2>&1; then
      pass "local polkit authorisation: $action"
    else
      warn "local polkit needs authentication: $action"
    fi
  done
else
  warn 'pkcheck is unavailable; power authorisation not checked'
fi
if command -v loginctl >/dev/null 2>&1; then
  pass 'loginctl backend is available'
elif command -v systemctl >/dev/null 2>&1; then
  pass 'systemctl backend is available'
else
  fail 'no logind/elogind or systemd power backend'
fi

if command -v niructl >/dev/null 2>&1; then
  dnd=$(niructl dnd status 2>&1 || true)
  case "$dnd" in dnd\ *) pass "DND: $dnd" ;; *) fail "DND unavailable: $dnd" ;; esac
  night=$(niructl nightlight status 2>&1 || true)
  case "$night" in mode:*|current:*) pass "night light: $(printf '%s' "$night" | tr '\n' ' ')" ;; *) warn "night light status unavailable: $night" ;; esac
fi

if command -v wpctl >/dev/null 2>&1; then
  sinks=$(wpctl status 2>/dev/null | awk '/Sinks:/{s=1;next} /Sources:/{s=0} s && /\[vol:/{n++} END{print n+0}')
  sources=$(wpctl status 2>/dev/null | awk '/Sources:/{s=1;next} /Filters:/{s=0} s && /\[vol:/{n++} END{print n+0}')
  [ "$sinks" -gt 0 ] && pass "audio sinks: $sinks" || warn 'no audio sink is available'
  [ "$sources" -gt 0 ] && pass "audio sources: $sources" || warn 'no audio source is available'
else
  warn 'wpctl is unavailable; audio nodes not checked'
fi

for tool in systemd-inhibit elogind-inhibit; do
  command -v "$tool" >/dev/null 2>&1 || continue
  if "$tool" --list 2>/dev/null | grep -q 'NIRU.*sleep.*Lock before suspend'; then
    pass 'lock-before-suspend inhibitor is held'
  else
    warn 'lock-before-suspend inhibitor was not found'
  fi
  break
done

if command -v dbus-send >/dev/null 2>&1; then
  owner=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.GetNameOwner string:org.freedesktop.Notifications 2>/dev/null |
    sed -n 's/.*string "\(.*\)"/\1/p' | head -1)
  [ -n "$owner" ] && pass "notification owner: $owner" || fail 'no notification provider owns the session bus'
fi

for program in nirunotify niruidle nirubar nirulock; do
  if pgrep -u "$(id -u)" -x "$program" >/dev/null 2>&1; then
    pass "running $program"
  else
    warn "not running $program"
  fi
done

rss=$(ps -u "$(id -u)" -o rss= | awk '{s+=$1} END{print s+0}')
count=$(ps -u "$(id -u)" --no-headers | wc -l | tr -d ' ')
pass "process snapshot: $count processes, $((rss / 1024)) MiB RSS"
warn 'physical lock/unlock, suspend/resume, audible output and power-off still require an owner-present test'

printf 'SUMMARY: %s failures, %s warnings\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
