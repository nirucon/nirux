#!/bin/sh
# Offline first-login defaults and service ordering. Never touches the host.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
as_root() { "$@"; }
systemctl() {
  printf '%s\n' "$*" >> "$TEST/services.log"
  case "$1" in
    is-active) return 1 ;;
    start) [ -f "$TEST/activated" ] || fail 'display manager started before activation' ;;
  esac
}

for OS in debian arch void; do
  # No side effects at all for a fresh startx/keep install or any update.
  ROOT=$TEST/untouched-$OS
  WORK=$TEST/untouched-work-$OS
  mkdir -p "$WORK"
  for DM in startx keep; do
    export operation=install
    setup_dm_session
    start_selected_dm
  done
  for DM in lightdm sddm; do
    export operation=update
    setup_dm_session
    start_selected_dm
  done
  [ ! -e "$ROOT" ] || fail "$OS keep/startx/update changed system defaults"

  ROOT=$TEST/$OS
  WORK=$TEST/work-$OS
  mkdir -p "$WORK" "$ROOT/var/service" "$ROOT/etc/sv/lightdm" "$ROOT/etc/sv/sddm"
  export operation=install
  DM=lightdm
  register_session
  grep -qx "Exec=$BIN/niruwm-session" "$ROOT/usr/share/xsessions/niruwm.desktop" || fail 'wrong session command'
  setup_dm_session
  lightdm_conf=$ROOT/etc/lightdm/lightdm.conf.d/50-nirux-session.conf
  grep -qx 'user-session=niruwm' "$lightdm_conf" || fail "$OS LightDM has no default"
  owned "$lightdm_conf" || fail 'LightDM default is not owned'
  setup_dm_session
  [ ! -e "$lightdm_conf.nirux-backup" ] || fail 'owned config backed up again'

  DM=sddm
  mkdir -p "$ROOT/var/lib/sddm"
  chmod 750 "$ROOT/var/lib/sddm"
  setup_dm_session
  state=$ROOT/var/lib/sddm/state.conf
  grep -qx 'Session=/usr/share/xsessions/niruwm.desktop' "$state" || fail "$OS SDDM has no default"
  [ "$(stat -c %a "$ROOT/var/lib/sddm")" = 750 ] || fail 'SDDM home permissions changed'
  first_sum=$(sha256sum "$state")
  setup_dm_session
  [ "$(sha256sum "$state")" = "$first_sum" ] || fail 'SDDM seeding is not idempotent'

  printf '[Other]\nSession=keep\n' > "$state"
  setup_dm_session
  grep -qx '\[Last\]' "$state" || fail 'missing Last section not added'
  grep -qx 'Session=keep' "$state" || fail 'unrelated session overwritten'

  # Empty sessions are filled without losing users, unrelated sections or mode.
  cat > "$state" <<'EOF'
[Last]
User=alice
Session=
[Other]
Session=not-the-login-session
Value=keep
EOF
  chmod 600 "$state"
  setup_dm_session
  grep -qx 'User=alice' "$state" || fail 'SDDM user lost'
  grep -qx 'Session=not-the-login-session' "$state" || fail 'unrelated section changed'
  grep -qx 'Value=keep' "$state" || fail 'unrelated value lost'
  [ "$(stat -c %a "$state")" = 600 ] || fail 'SDDM state mode changed'
  grep -qx 'Session=/usr/share/xsessions/niruwm.desktop' "$state" || fail 'empty session was not seeded'

  # A genuine remembered session is never replaced, including the first entry.
  printf '[Last]\nUser=alice\nSession=/usr/share/xsessions/xfce.desktop\n' > "$state"
  remembered_sum=$(sha256sum "$state")
  setup_dm_session
  [ "$(sha256sum "$state")" = "$remembered_sum" ] || fail 'remembered session overwritten'

  # An existing manager kept through auto, startx, and updates remain untouched.
  for DM in keep startx; do
    export operation=install
    setup_dm_session
    [ "$(sha256sum "$state")" = "$remembered_sum" ] || fail "$DM changed SDDM state"
  done
  for DM in lightdm sddm; do
    export operation=update
    printf 'admin-owned setting\n' > "$lightdm_conf"
    setup_dm_session
    grep -qx 'admin-owned setting' "$lightdm_conf" || fail 'update changed LightDM defaults'
    [ "$(sha256sum "$state")" = "$remembered_sum" ] || fail 'update changed remembered session'
  done

  # Explicit install backs up and uninstall restores a pre-existing drop-in.
  export operation=install
  DM=lightdm
  setup_dm_session
  remove_system "$lightdm_conf"
  grep -qx 'admin-owned setting' "$lightdm_conf" || fail 'LightDM admin config not restored'

  # Service enable alone must not launch a display manager on Void/runit.
  for DM in lightdm sddm; do
    rm -f "$TEST/activated" "$TEST/services.log"
    enable_services
    [ ! -L "$ROOT/var/service/$DM" ] || fail 'runit DM enabled before activate'
    : > "$TEST/activated"
    start_selected_dm
    if [ "$OS" = void ]; then
      [ "$(readlink "$ROOT/var/service/$DM")" = "/etc/sv/$DM" ] || fail 'runit DM not enabled after activate'
    else
      grep -qx "start $DM.service" "$TEST/services.log" || fail 'systemd DM not started'
    fi
  done
  remove_system "$ROOT/usr/share/xsessions/niruwm.desktop"
done

grep -qx 'default-session=niruwm' "$SOURCE/greeters/lightdm/50-nirux.conf" || fail 'GTK greeter has no default'
grep -Fq 'Qt.resolvedUrl(config.background)' "$SOURCE/greeters/sddm/Main.qml" || fail 'SDDM background resolves relative to the shared component'
grep -Fq 'Qt.resolvedUrl("arrow.png")' "$SOURCE/greeters/sddm/Main.qml" || fail 'SDDM arrow resolves relative to the shared component'

# Both installer paths must use the same defaults and start ordering. In the
# handoff path, the downloaded target installer owns these decisions.
for path in apply_target_release install_or_update; do
  body=$(sed -n "/^$path() {/,/^}/p" "$SOURCE/nirux")
  printf '%s\n' "$body" | awk '
    /^  register_session$/ { registered = NR }
    /^  setup_dm_session$/ { defaults = NR }
    /^  activate$/ { activated = NR }
    /^  start_selected_dm$/ { started = NR }
    END { exit !(registered && defaults > registered && activated > defaults && started > activated) }
  ' || fail "$path has unsafe session/start ordering"
done
printf 'PASS: LightDM/SDDM defaults, remembered sessions, keep/update preservation and systemd/runit start ordering on Debian/Arch/Void\n'
