#!/bin/sh
# First-install package hooks, system-bus policies and X11 input coldplug.
# All service/device commands are mocked; no host state is changed.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system NIRUX_LIBRARY=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
same_file() {
  [ "$(sha256sum "$1" | cut -d ' ' -f1)" = "$(sha256sum "$2" | cut -d ' ' -f1)" ]
}
as_root() { "$@"; }
export OS=debian
mkdir -p "$ROOT/usr/sbin"
policy=$ROOT/usr/sbin/policy-rc.d
expect_status() (
  expected=$1; shift
  actual=0
  "$@" || actual=$?
  [ "$actual" = "$expected" ] || fail "expected $expected, got $actual: $*"
)

disable_service_starts
for service in lightdm sddm display-manager lightdm.service sddm.service display-manager.service /etc/init.d/lightdm; do
  expect_status 101 "$policy" "$service" start
  expect_status 101 "$policy" --quiet "$service" restart
done
for service in dbus dbus.service polkit polkit.service rtkit-daemon bluetooth; do
  expect_status 0 "$policy" "$service" reload
  expect_status 0 "$policy" --quiet "$service" start
done
restore_policy
[ ! -e "$policy" ] || fail 'temporary policy not removed'

# Delegate unrelated services to the administrator's policy verbatim, even
# when its saved pathname contains spaces and quotes. Restore mode/content.
mkdir -p "$TEST/tmp dir'quoted"
export TMPDIR="$TEST/tmp dir'quoted" POLICY_LOG=$TEST/policy.log
cat > "$policy" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$POLICY_LOG"
exit 104
EOF
chmod 750 "$policy"
cp -p "$policy" "$TEST/original-policy"
disable_service_starts
expect_status 101 "$policy" lightdm.service start
expect_status 104 "$policy" --quiet dbus reload 2
printf '%s\n' --quiet dbus reload 2 > "$TEST/policy-expected"
same_file "$POLICY_LOG" "$TEST/policy-expected" || fail 'original policy arguments changed'
restore_policy
same_file "$policy" "$TEST/original-policy" || fail 'original policy not restored'
[ "$(stat -c %a "$policy")" = 750 ] || fail 'policy mode not restored'
unset TMPDIR

# Both successful and failed apt operations restore policy; only success
# reaches live runtime refresh, after the original policy is back in place.
(
  refresh_runtime_state() {
    same_file "$policy" "$TEST/original-policy" || fail 'runtime refresh precedes policy restoration'
    : > "$TEST/refreshed"
  }
  as_root() {
    case "$1" in
      apt-get) return 0 ;;
      env)
        expect_status 101 "$policy" lightdm start
        expect_status 104 "$policy" dbus reload
        return "${APT_RESULT:-0}"
        ;;
      *) "$@" ;;
    esac
  }
  install_packages kitty
  [ -f "$TEST/refreshed" ] || fail 'successful apt did not refresh runtime'
  rm "$TEST/refreshed"
  APT_RESULT=17
  export APT_RESULT
  expect_status 17 install_packages kitty
  [ ! -e "$TEST/refreshed" ] || fail 'failed apt refreshed runtime'
  same_file "$policy" "$TEST/original-policy" || fail 'failed apt left temporary policy'
)

# Make optional tool discovery deterministic, independently of the host.
mkdir -p "$TEST/bin"
for tool in dbus-send udevadm; do
  printf '#!/bin/sh\nexit 99\n' > "$TEST/bin/$tool"
  chmod +x "$TEST/bin/$tool"
done
PATH=$TEST/bin:$PATH
export PATH
as_root() {
  printf '%s\n' "$*" >> "$TEST/runtime.log"
  case "$1" in
    test) return "${NO_DAEMONS:-0}" ;;
    dbus-send) return "${BUS_RESULT:-0}" ;;
    udevadm) return "${UDEV_RESULT:-0}" ;;
    *) fail "unexpected runtime command: $*" ;;
  esac
}
for OS in debian arch void; do
  ROOT=
  : > "$TEST/runtime.log"
  refresh_runtime_state
  cat > "$TEST/runtime-expected" <<'EOF'
test -S /run/dbus/system_bus_socket
dbus-send --system --type=method_call --print-reply --reply-timeout=5000 --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig
test -S /run/udev/control
udevadm control --reload-rules
udevadm trigger --action=change --subsystem-match=input
udevadm settle --timeout=10
EOF
  same_file "$TEST/runtime.log" "$TEST/runtime-expected" || fail "$OS refresh sequence changed"

  # Containers/early Void boots need no reload when daemons have not started.
  : > "$TEST/runtime.log"
  NO_DAEMONS=1 refresh_runtime_state
  [ "$(wc -l < "$TEST/runtime.log")" = 2 ] || fail 'commands sent to absent daemons'

  # A temporary system root must never refresh the real host.
  ROOT=$TEST/offline
  : > "$TEST/runtime.log"
  refresh_runtime_state
  [ ! -s "$TEST/runtime.log" ] || fail 'offline system root touched host runtime'
done
ROOT=
bus_failure() ( BUS_RESULT=1; refresh_runtime_state; )
udev_failure() ( UDEV_RESULT=1; refresh_runtime_state; )
expect_status 1 bus_failure
expect_status 1 udev_failure
printf 'PASS: selective Debian DM policy, original-policy delegation/restoration, apt failure handling, and D-Bus/input refresh on Debian/Arch/Void\n'
