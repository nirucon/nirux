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
  mkdir -p "$ROOT/var/lib/sddm" "$ROOT/usr/share/xsessions"
  chmod 750 "$ROOT/var/lib/sddm"
  # A fresh SDDM starts with an empty state; NIRUX names NIRUWM as its
  # remembered session so the login screen preselects it.
  : > "$ROOT/var/lib/sddm/state.conf"
  printf '[Desktop Entry]\nName=NIRUWM\n' > "$ROOT/usr/share/xsessions/niruwm.desktop"
  setup_dm_session
  state=$ROOT/var/lib/sddm/state.conf
  grep -qx 'Session=' "$state" && fail "$OS SDDM still empty" || :
  grep -qx "Session=/usr/share/xsessions/niruwm.desktop" "$state" ||
    fail "$OS SDDM does not preselect NIRUWM"
  [ "$(stat -c %a "$ROOT/var/lib/sddm")" = 750 ] || fail 'SDDM home permissions changed'
  first_sum=$(sha256sum "$state")
  setup_dm_session
  [ "$(sha256sum "$state")" = "$first_sum" ] || fail 'SDDM seeding is not idempotent'

  printf '[Other]\nSetting=keep\n' > "$state"
  setup_dm_session
  grep -qx 'Setting=keep' "$state" || fail 'unrelated setting overwritten'
  grep -qx "Session=/usr/share/xsessions/niruwm.desktop" "$state" ||
    fail 'SDDM preselect was not added to a file without [Last]'

  # An old remembered session is replaced by NIRUWM, and the user is kept.
  # SDDM writes a trailing space after the path on some machines.
  printf '[Last]\nUser=alice\nSession=/usr/share/xsessions/nirupi-dwm.desktop \n' > "$state"
  setup_dm_session
  [ "$(grep -c '^Session=' "$state")" = 1 ] || fail 'SDDM session line duplicated'
  grep -qx "Session=/usr/share/xsessions/niruwm.desktop" "$state" ||
    fail 'remembered session was not replaced'
  grep -qx 'User=alice' "$state" || fail 'SDDM user lost while setting the session'

  # Autologin keeps its remembered session: changing it would not change which
  # session starts, and the user's setup stays exactly as it was. SDDM keeps
  # the autologin choice in its own main configuration, not in state.conf.
  printf '[Last]\nUser=alice\nSession=/usr/share/xsessions/nirupi-dwm.desktop\n' > "$state"
  mkdir -p "$ROOT/etc/sddm.conf.d"
  printf '[Autologin]\nUser=alice\nSession=nirupi-dwm.desktop\n' > "$ROOT/etc/sddm.conf.d/autologin.conf"
  autologin_sum=$(sha256sum "$state")
  setup_dm_session
  [ "$(sha256sum "$state")" = "$autologin_sum" ] || fail 'autologin state was changed'
  rm -f "$ROOT/etc/sddm.conf.d/autologin.conf"

  # Every other remembered session is replaced too, and the rest of the file,
  # including later sections, is kept.
  printf '[Last]\nUser=alice\nSession=/usr/share/xsessions/xfce.desktop\n[Other]\nKeep=1\n' > "$state"
  setup_dm_session
  grep -qx "Session=/usr/share/xsessions/niruwm.desktop" "$state" ||
    fail 'remembered session was not replaced'
  grep -qx 'Keep=1' "$state" || fail 'unrelated setting lost while setting the session'
  grep -q 'xfce.desktop' "$state" && fail 'old session name survived' || :
  remembered_sum=$(sha256sum "$state")

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
