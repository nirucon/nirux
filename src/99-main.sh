main() {
  # The bootstrap keeps the one sudo password in a private file, never in the
  # environment: a program NIRUX starts can read its own environment, and a
  # process listing would show an exported secret. The target installer is
  # passed only the file's location, and any part of an install that runs in a
  # subshell reads the same file, so the password is not lost between steps.
  #
  # The copy is per process: a subshell must not delete the file its caller is
  # still using, so only the process that created it removes it.
  if [ -n "${NIRUX_SUDO_SECRET_FILE:-}" ]; then
    SUDO_SECRET_FILE=$NIRUX_SUDO_SECRET_FILE
    SUDO_SECRET_BORROWED=1
  fi
  if [ -n "${NIRUX_SUDO_PASSWORD:-}" ]; then sudo_secret_keep "$NIRUX_SUDO_PASSWORD"; fi
  unset NIRUX_SUDO_PASSWORD
  # A subshell of an install (or a function inside one) inherits the location,
  # not the password.
  [ -n "$SUDO_SECRET" ] || sudo_secret_file || :
  if [ -n "$SUDO_SECRET" ] && [ "$(id -u)" != 0 ] &&
     ! sudo -n id -u >/dev/null 2>&1; then
    if sudo_refresh; then
      SUDO_ASK_LATER=1
      start_sudo_keepalive
    fi
  fi
  case "${1:-}" in
    install|update) install_or_update "$@" ;;
    _provision) shift; provision_packages "$@" ;;
    _handoff-version) say 1 ;;
    _apply-version) say 2 ;;
    _apply) shift; [ "$#" = 1 ] || die 'apply takes one protocol version'; apply_target_release "$1" ;;
    _stage) shift; [ "$#" = 1 ] || die 'staging takes one protocol version'; stage_target_release "$1" ;;
    remove) shift; [ "$#" = 1 ] || die 'remove needs helium, localsend or opencode'; lock; remove_app "$1" ;;
    uninstall) shift; uninstall "$@" ;;
    rollback) [ "$#" = 1 ] || die 'rollback takes no arguments'; rollback ;;
    gc) shift; gc_command "$@" ;;
    login-wallpaper) shift; login_wallpaper "$@" ;;
    wallpapers) shift; wallpapers "$@" ;;
    layout) shift; layout "$@" ;;
    reset-config) [ "$#" = 1 ] || die 'reset-config takes no arguments'; reset_config ;;
    repair-session) [ "$#" = 1 ] || die 'repair-session takes no arguments'; repair_session ;;
    repair-wallpaper) [ "$#" = 1 ] || die 'repair-wallpaper takes no arguments'; repair_wallpaper ;;
    sounds) shift; sounds_command "$@" ;;
    browser-addon)
      [ "$#" = 2 ] || die 'usage: nirux browser-addon bonjourr|none|status'
      case "$2" in
        status) browser_addon_status ;;
        bonjourr|none) browser_addon_policy_set "$2"; browser_addon_apply "$2" ;;
        *) die 'browser-addon must be bonjourr, none or status' ;;
      esac ;;
    extras) shift; extras_command "$@" ;;
    fleet) shift; fleet_command "$@" ;;
    sync) shift; sync_command "$@" ;;
    snapshot) shift; snapshot_command "$@" ;;
    checkup) shift; checkup_command "$@" ;;
    autoupdate) shift; autoupdate_command "$@" ;;
    whats-new) shift; whats_new_command "$@" ;;
    stale) shift; stale_command "$@" ;;
    meet-check) shift; meet_check_command "$@" ;;
    boot) shift; boot_command "$@" ;;
    resume-check) shift; resume_check_command "$@" ;;
    clean) shift; clean_command "$@" ;;
    restore) shift; restore_command "$@" ;;
    backup) shift; backup_command "$@" ;;
    migrate) shift; migrate_command "$@" ;;
    update-shutdown) shift; update_power_command shutdown "$@" ;;
    update-reboot) shift; update_power_command reboot "$@" ;;
    manual) manual_command "$@" ;;
    status) [ "$#" = 1 ] || die "$1 takes no arguments"; status ;;
    doctor) shift; doctor "$@" ;;
    --version) say "NIRUX $VERSION" ;;
    --help|help) usage ;;
    '') usage; exit 2 ;;
    *) die "unknown command: $1" ;;
  esac
}
[ "${NIRUX_LIBRARY:-0}" = 1 ] || main "$@"
