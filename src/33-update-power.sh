update_power_log() {
  [ -n "${UPDATE_LOG:-}" ] || return 0
  mkdir -p "$(dirname "$UPDATE_LOG")" 2>/dev/null || return 0
  printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date)" "$*" \
    >>"$UPDATE_LOG" 2>/dev/null || :
}
update_power_plan() {
  case "$1" in
    debian)
      say '  1. apt-get update'
      say '  2. apt-get -y full-upgrade'
      ;;
    arch)
      say '  1. pacman -Syu --noconfirm'
      ;;
    void)
      say '  1. xbps-install -Suy'
      ;;
  esac
  say "  Next: $0 update"
  if [ -s "$EXTRAS_SELECTED" ]; then say "  Next: $0 extras update"; fi
  say "  Then: $UPDATE_POWER_VERB"
}
update_power_processes() {
  command -v pgrep >/dev/null 2>&1 || return 0
  for update_proc in apt-get apt dpkg pacman xbps-install unattended-upgr; do
    if pgrep -x "$update_proc" >/dev/null 2>&1; then
      die "another package-manager process is running: $update_proc"
    fi
  done
}
update_power_inhibit_start() {
  UPDATE_INHIBIT_PID=
  UPDATE_IDLE_FILE=
  UPDATE_IDLE_SAVED=0
  for update_tool in systemd-inhibit elogind-inhibit; do
    command -v "$update_tool" >/dev/null 2>&1 || continue
    "$update_tool" --what=idle:sleep --who=NIRUX --why='System update and power action' \
      --mode=block sleep 86400 >/dev/null 2>&1 &
    UPDATE_INHIBIT_PID=$!
    break
  done
  # On systems without systemd/elogind, NIRUWM's explicit idle marker is
  # the only portable way to prevent an idle suspend during a package write.
  if [ -z "$UPDATE_INHIBIT_PID" ] && command -v niructl >/dev/null 2>&1; then
    UPDATE_IDLE_FILE=${XDG_STATE_HOME:-$HOME/.local/state}/niruui/inhibit
    if [ -f "$UPDATE_IDLE_FILE" ]; then
      UPDATE_IDLE_SAVED_FILE=$WORK/nirux-idle-before
      mkdir -p "$WORK" 2>/dev/null || WORK=$(mktemp -d "${TMPDIR:-/tmp}/nirux-update.XXXXXX")
      cp "$UPDATE_IDLE_FILE" "$UPDATE_IDLE_SAVED_FILE" 2>/dev/null && UPDATE_IDLE_SAVED=1 || UPDATE_IDLE_SAVED=0
    fi
    niructl idle on >/dev/null 2>&1 || :
  fi
}
update_power_inhibit_stop() {
  if [ -n "${UPDATE_INHIBIT_PID:-}" ]; then
    kill "$UPDATE_INHIBIT_PID" 2>/dev/null || :
    wait "$UPDATE_INHIBIT_PID" 2>/dev/null || :
    UPDATE_INHIBIT_PID=
  fi
  if [ -n "${UPDATE_IDLE_FILE:-}" ] && command -v niructl >/dev/null 2>&1; then
    if [ "$UPDATE_IDLE_SAVED" = 1 ] && [ -f "${UPDATE_IDLE_SAVED_FILE:-}" ]; then
      mkdir -p "$(dirname "$UPDATE_IDLE_FILE")" 2>/dev/null || :
      cp "$UPDATE_IDLE_SAVED_FILE" "$UPDATE_IDLE_FILE" 2>/dev/null || :
    elif [ "$UPDATE_IDLE_SAVED" = 0 ]; then
      niructl idle off >/dev/null 2>&1 || :
    fi
    UPDATE_IDLE_FILE=
    UPDATE_IDLE_SAVED=0
  fi
}
update_power_cleanup() {
  update_power_inhibit_stop
  if [ "${UPDATE_LOCKED:-0}" = 1 ]; then
    rmdir "$UPDATE_LOCK_DIR" 2>/dev/null || :
    UPDATE_LOCKED=0
  fi
  if [ -n "${WORK:-}" ]; then
    rm -rf "$WORK"
    WORK=
  fi
  sudo_secret_forget
}
update_power_step() {
  # A nested `nirux update` has its own cleanup and may remove a borrowed
  # sudo-secret file. Recreate it from the already-held secret; never put the
  # password on a command line or in the environment.
  if [ -n "${SUDO_SECRET:-}" ] &&
     { [ -z "${SUDO_SECRET_FILE:-}" ] || [ ! -f "$SUDO_SECRET_FILE" ]; }; then
    sudo_secret_keep "$SUDO_SECRET" >/dev/null 2>&1 || :
  fi
  update_power_log "start: $*"
  if ! "$@"; then
    update_power_log "failed: $*"
    return 1
  fi
  update_power_log "ok: $*"
}
update_power_system() {
  case "$1" in
    debian)
      update_power_step as_root apt-get update || return 1
      # full-upgrade is required so kernels and dependency changes are included.
      update_power_step as_root apt-get -y full-upgrade || return 1
      ;;
    arch)
      # A full -Syu transaction; never refresh then install selected packages.
      update_power_step as_root pacman -Syu --noconfirm || return 1
      ;;
    void)
      update_power_step as_root xbps-install -Suy || return 1
      ;;
    *)
      return 1
      ;;
  esac
}
update_power_command() {
  UPDATE_ACTION=$1; shift
  case "$UPDATE_ACTION" in
    shutdown) UPDATE_POWER_VERB=poweroff; UPDATE_POWER_METHOD=PowerOff; UPDATE_POWER_LABEL='shut down' ;;
    reboot) UPDATE_POWER_VERB=reboot; UPDATE_POWER_METHOD=Reboot; UPDATE_POWER_LABEL='restart' ;;
    *) die 'update-power needs shutdown or reboot' ;;
  esac
  UPDATE_YES=0 UPDATE_DRY=0 UPDATE_NOPOWER=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes) UPDATE_YES=1 ;;
      --dry-run) UPDATE_DRY=1 ;;
      --no-power|--no-shutdown) UPDATE_NOPOWER=1 ;;
      --help|-h) say "Usage: nirux update-$UPDATE_ACTION [--yes] [--dry-run] [--no-power]"; return 0 ;;
      *) die "unknown option for update-$UPDATE_ACTION: $1" ;;
    esac
    shift
  done
  UPDATE_OS=$(distro)
  case "$UPDATE_OS" in
    debian|arch|void) ;;
    *) die "unsupported distribution for update-$UPDATE_ACTION: $UPDATE_OS" ;;
  esac
  UPDATE_LOG_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/nirux
  UPDATE_LOG=$UPDATE_LOG_DIR/update-power.log
  if [ "$UPDATE_DRY" = 1 ]; then
    say "NIRUX $VERSION"
    say "Distribution: $UPDATE_OS"
    say "Dry run: no packages will be changed and the machine will not $UPDATE_POWER_LABEL."
    update_power_plan "$UPDATE_OS"
    return 0
  fi
  [ -t 0 ] || [ "$UPDATE_YES" = 1 ] || die "run update-$UPDATE_ACTION in a terminal or pass --yes"
  if [ ! -t 0 ] && [ "$UPDATE_YES" = 1 ]; then
    say 'No terminal is attached. The package manager may still require input.'
  fi
  mkdir -p "$STATE" "$UPDATE_LOG_DIR"
  [ ! -d "$STATE/.lock" ] || die "another NIRUX operation is running ($STATE/.lock)"
  UPDATE_LOCK_DIR=$STATE/.update-$UPDATE_ACTION.lock
  mkdir "$UPDATE_LOCK_DIR" 2>/dev/null || die "update-$UPDATE_ACTION is already running"
  UPDATE_LOCKED=1
  WORK=$(mktemp -d "$STATE/.update-work.XXXXXX") || die 'cannot create update work directory'
  trap 'update_power_cleanup' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  update_power_log "begin update-$UPDATE_ACTION: distro=$UPDATE_OS"
  update_power_processes
  if [ "$UPDATE_YES" = 0 ]; then
    say "This will update all system packages, the kernel, NIRUX and selected extras,"
    say "then $UPDATE_POWER_LABEL the machine. A failed update will not trigger the power action."
    printf 'Continue? [y/N]: '
    IFS= read -r update_answer || update_answer=
    case "$update_answer" in
      [yY]*) ;;
      *) die 'cancelled' ;;
    esac
  fi
  update_power_inhibit_start
  # Prompt for sudo once before the long transaction. Package managers still
  # own their own conffile prompts in this terminal.
  if ! as_root true; then
    update_power_log 'failed: sudo authentication'
    die 'sudo authentication failed'
  fi
  say ''
  say "Updating system packages ($UPDATE_OS)…"
  if ! update_power_system "$UPDATE_OS"; then
    update_power_log 'failed: system package update'
    die 'system package update failed; the machine was not powered off'
  fi
  say ''
  say 'Updating NIRUX components…'
  # The machine powers off next: no restart of the running session first.
  update_session_restart=0
  [ "$UPDATE_NOPOWER" = 0 ] || update_session_restart=1
  if ! update_power_step env NIRUX_SESSION_RESTART="$update_session_restart" "$0" update; then
    update_power_log 'failed: NIRUX update'
    die 'NIRUX update failed; the machine was not powered off'
  fi
  if [ -s "$EXTRAS_SELECTED" ]; then
    say ''
    say 'Updating selected NIRUX extras…'
    if ! update_power_step "$0" extras update; then
      update_power_log 'failed: NIRUX extras update'
      die 'selected extras update failed; the machine was not powered off'
    fi
  fi
  update_power_log 'updates complete'
  if [ "$UPDATE_NOPOWER" = 1 ]; then
    say ''
    say "Updates completed. Power action skipped (--no-power)."
    update_power_log 'power action skipped by --no-power'
    return 0
  fi
  say ''
  say "Updates completed. $UPDATE_POWER_VERB in 5 seconds; press Ctrl+C to cancel."
  # Keep the terminal visible briefly so a late failure is readable and the
  # user can abort before the power request.
  sleep 5
  update_power_log "power: $UPDATE_POWER_VERB"
  if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
    update_power_step as_root systemctl "$UPDATE_POWER_VERB" || \
      die "updates completed, but $UPDATE_POWER_VERB failed; run it manually"
  elif command -v dbus-send >/dev/null 2>&1; then
    # elogind uses the same logind D-Bus interface. This also honours its
    # inhibitors; do not fall back to a forced shutdown if it is rejected.
    update_power_step as_root dbus-send --system --print-reply \
      --reply-timeout=120000 --dest=org.freedesktop.login1 \
      /org/freedesktop/login1 \
      "org.freedesktop.login1.Manager.$UPDATE_POWER_METHOD" boolean:true || \
      die "updates completed, but logind $UPDATE_POWER_VERB failed; run it manually"
  elif command -v shutdown >/dev/null 2>&1; then
    if [ "$UPDATE_ACTION" = reboot ]; then
      update_power_step as_root shutdown -r now || \
        die 'updates completed, but restart failed; run it manually'
    else
      update_power_step as_root shutdown -h now || \
        die 'updates completed, but shutdown failed; run it manually'
    fi
  elif command -v loginctl >/dev/null 2>&1 &&
       loginctl --help 2>/dev/null | grep -q "$UPDATE_POWER_VERB"; then
    update_power_step as_root loginctl "$UPDATE_POWER_VERB" || \
      die "updates completed, but $UPDATE_POWER_VERB failed; run it manually"
  else
    update_power_log 'failed: no power backend'
    die "updates completed, but no shutdown/reboot backend exists"
  fi
}

