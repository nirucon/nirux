# Root-only files (sudoers rules, polkit rules in a 0750 directory) cannot be
# read or even tested by the desktop user, so ownership is also checked through
# the privilege boundary that installed them. Without this, uninstall silently
# kept every NIRUX sudoers and polkit rule.
owned_system() {
  owned "$1" && return 0
  as_root grep -qxF "# NIRUX owner: $PREFIX" "$1" 2>/dev/null ||
    as_root grep -qxF "// NIRUX owner: $PREFIX" "$1" 2>/dev/null ||
    as_root grep -q '^# NIRULOGIN owner:' "$1" 2>/dev/null
}
# A saved copy written by any NIRUX installation (another prefix, a test
# candidate, an older release) is NIRUX's own and is never restored. Seen on a
# Debian host: uninstall put back a broad passwordless wpa_cli rule.
nirux_written() {
  as_root grep -qE '^(# |// |/\* )NIRUX owner:|^# NIRULOGIN owner:|^# Installed by nirux\.' "$1" 2>/dev/null
}
remove_system() {
  if ! as_root test -f "$1" 2>/dev/null; then
    # An older release could leave its own rule saved as a backup with no
    # file beside it; that backup is NIRUX's and goes too.
    if as_root test -f "$1.nirux-backup" && nirux_written "$1.nirux-backup"; then
      as_root rm -f "$1.nirux-backup"
    fi
    return 0
  fi
  owned_system "$1" || return 0
  # A backup that is itself a NIRUX file came from an earlier release (for
  # example the withdrawn login-wallpaper sudoers rule) and must not return.
  if as_root test -f "$1.nirux-backup" && ! nirux_written "$1.nirux-backup"; then
    as_root mv -f "$1.nirux-backup" "$1"
  else
    as_root rm -f "$1" "$1.nirux-backup"
  fi
}
remove_app() {
  app=${1:-}
  [ "$#" = 1 ] || die 'remove needs helium, localsend or opencode'
  case "$app" in
    helium)
      browser_remove_managed
      browser_policy_set none
      say 'Removed managed Helium. External Helium installations were not touched.'
      ;;
    localsend)
      localsend_remove_managed
      app_policy_set localsend no
      say 'Removed managed LocalSend. External installations were not touched.'
      ;;
    opencode)
      opencode_remove_managed
      app_policy_set opencode no
      say 'Removed managed OpenCode. External installations were not touched.'
      ;;
    *) die 'remove needs helium, localsend or opencode' ;;
  esac
}

uninstall() {
  purge=0
  for option in "$@"; do case "$option" in --purge) purge=1 ;; *) die "unknown option: $option" ;; esac; done
  lock
  extras_left=
  if [ -f "$EXTRAS_SELECTED" ]; then
    # The loop's status is its last test; a missing extra must not end uninstall.
    extras_left=$(extras_table | while read -r name _repo _version _sha; do
      if extras_installed_version "$name" >/dev/null 2>&1; then printf '%s ' "$name"; fi
    done) || extras_left=
  fi
  remove_system "$ROOT/usr/share/xsessions/niruwm.desktop"
  remove_wallpaper_app
  remove_display_app
  remove_theme_selector_app
  remove_system "$ROOT/etc/pam.d/nirulock"
  remove_system "$ROOT/etc/udev/rules.d/70-nirux-backlight.rules"
  remove_greeters
  boot_look_remove
  sleep_remove
  for program in $PROGRAMS; do
    if [ -L "$BIN/$program" ] && [ "$(readlink "$BIN/$program")" = "$STATE/current/bin/$program" ]; then rm -f "$BIN/$program"; fi
  done
  if [ -f "$HOME/.xinitrc" ] && owned "$HOME/.xinitrc"; then rm -f "$HOME/.xinitrc"; fi
  localsend_remove_managed
  opencode_remove_managed
  browser_remove_managed
  browser_remove_policy
  browser_addon_remove
  rm -f "$STATE/localsend-policy" "$STATE/opencode-policy"
  remove_terminal
  if [ "$purge" = 1 ]; then
    remove_owned_wallpapers
    rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/niruwm" "${XDG_CONFIG_HOME:-$HOME/.config}/niruui" \
      "${XDG_CONFIG_HOME:-$HOME/.config}/nirubar" "${XDG_CONFIG_HOME:-$HOME/.config}/nirulauncher" \
      "${XDG_CONFIG_HOME:-$HOME/.config}/nirunotify" "${XDG_CONFIG_HOME:-$HOME/.config}/nirux" \
      "${XDG_STATE_HOME:-$HOME/.local/state}/niruwm" "${XDG_STATE_HOME:-$HOME/.local/state}/nirulock" \
      "${XDG_STATE_HOME:-$HOME/.local/state}/niruscreensaver" \
      "${XDG_CACHE_HOME:-$HOME/.cache}/nirubar"
  fi
  rm -rf "$STATE/generations"
  rm -f "$STATE/current" "$STATE/previous"
  # Purge also forgets every remembered choice (browser, apps, icons,
  # wallpapers, extras selection) and the installed sound pack.
  if [ "$purge" = 1 ]; then rm -rf "$STATE"; fi
  say 'NIRU removed. OS packages retained. An already running session exits normally on logout.'
  if [ -n "$extras_left" ]; then
    say "Extras are separate and still installed: $extras_left"
    say 'Remove them from a NIRUX checkout with ./nirux extras uninstall NAME, or with their own uninstall.sh.'
  fi
}
repair_session() {
  lock
  setup_startx
  forget_sddm_session
  say 'Session repair complete. Log out/in, or run startx from a TTY.'
}

repair_wallpaper() {
  source=$STATE/config.example.toml
  [ -f "$source" ] || source=$(dirname "$0")/config.example.toml
  [ -f "$source" ] || die "config example not found: $source (run nirux update)"
  snapshot_guard reset-config '' '' 'before reset-config'
  target=$CONFDIR/config.toml
  [ -f "$target" ] || die "config not found: $target"
  wallpaper_dir=$(config_picture_paths | sed -n '1p')
  theme_dir=$(config_picture_paths | sed -n '2p')
  # shellcheck disable=SC2088 # compare the literal TOML default
  case "$theme_dir" in
    "~/"*) theme_path=$HOME/${theme_dir#~/} ;;
    *) theme_path=$theme_dir ;;
  esac
  backup=$target.nirux-wallpaper-backup
  cp -p "$target" "$backup" || die "could not back up $target"
  tmp=$(mktemp "$(dirname "$target")/.config.toml.wallpaper.XXXXXX") || die 'could not stage config'
  awk -v dir="$wallpaper_dir" -v theme="$theme_dir" '
    /^\[/ { in_wallpaper = ($0 == "[wallpaper]") }
    in_wallpaper && /^dir[[:space:]]*=/ { printf "dir = \"%s\"\n", dir; next }
    in_wallpaper && /^theme_dir[[:space:]]*=/ { printf "theme_dir = \"%s\"\n", theme; next }
    { print }
  ' "$target" > "$tmp" || { rm -f "$tmp"; die 'could not update wallpaper paths'; }
  if ! same_file "$target" "$tmp"; then
    mode=$(stat -c %a "$target") || mode=644
    chmod "$mode" "$tmp" && mv -f "$tmp" "$target" || { rm -f "$tmp"; die 'could not activate wallpaper paths'; }
    say "Updated wallpaper paths for the XDG Pictures directory."
  else
    rm -f "$tmp"
    say 'Wallpaper paths already match the XDG Pictures directory.'
  fi
  find "$theme_path" -maxdepth 1 -name 'nirux-wallpaper-*.png' -print 2>/dev/null | head -3 || :
  say "Backup: $backup"
}

reset_config() {
  source=$STATE/config.example.toml
  if [ ! -f "$source" ] && [ -f "$(dirname "$0")/config.example.toml" ]; then
    source=$(dirname "$0")/config.example.toml
  fi
  [ -f "$source" ] || die "config example not found: $source (run nirux update)"
  snapshot_guard reset-config '' '' 'before reset-config'
  target=$CONFDIR/config.toml
  if [ -L "$target" ]; then
    resolved=$(readlink -f "$target" 2>/dev/null || :)
    [ -n "$resolved" ] && [ -f "$resolved" ] || die "$target is a broken symlink"
    target=$resolved
  fi
  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ]; then
    backup=$target.nirux-backup
    cp -p "$target" "$backup" || die "could not back up $target"
    mode=$(stat -c %a "$target") || die "could not read permissions for $target"
  else
    backup=
    mode=644
  fi
  temp=$(mktemp "$(dirname "$target")/.config.toml.nirux.XXXXXX") || die 'could not stage configuration'
  cp "$source" "$temp" && chmod "$mode" "$temp" && mv -f "$temp" "$target" || {
    rm -f "$temp"
    die "could not reset $target; original kept"
  }
  [ -z "$backup" ] || say "Backup: $backup"
  say "Reset $target to the NIRUX example."
  if [ -n "${DISPLAY:-}" ] && "$BIN/niructl" reload; then
    say 'Configuration reloaded.'
  else
    say 'Log out/in or run: niructl reload'
  fi
}

rollback() {
  lock
  [ -L "$STATE/previous" ] || die 'no previous generation'
  previous=$(readlink "$STATE/previous")
  [ -x "$previous/bin/niruwm" ] || die 'previous generation is incomplete'
  current=$(readlink "$STATE/current")
  switch_link current "$previous"
  switch_link previous "$current"
  sync_front_links
  # NIRULOGIN is a system entry point, not only a user-prefix generation
  # binary. Keep the real greeter in step with the generation being restored.
  if [ -x "$STATE/current/bin/nirulogin" ] && as_root test -w /usr/local/bin; then
    as_root install -m 755 "$STATE/current/bin/nirulogin" /usr/local/bin/nirulogin
  fi
  say 'Previous program generation restored. System packages and PAM configuration are not rolled back.'
  say 'Log out and back in to use the restored WM and session (or run niructl restart-wm in it, when both generations have NIRUWM 0.23.0 or later).'
  say 'Configuration files are not part of a rollback: see nirux snapshot list and nirux restore.'
}
# --auto: when the latest release is the installed one, only the apps that
# follow upstream are updated; no new generation and no snapshot.
auto_current_release() {
  if [ -z "$RELEASE" ]; then
    fetch https://api.github.com/repos/nirucon/nirux/releases/latest "$WORK/latest.json" || return 1
    RELEASE=$(sed -n 's/.*"tag_name": *"v\([0-9.]*\)".*/\1/p' "$WORK/latest.json" | head -n 1)
  fi
  [ -n "$RELEASE" ] && [ "$RELEASE" = "$(installed_version)" ] && [ -L "$STATE/current" ] || return 1
  say "NIRUX $RELEASE is current; checking the apps."
  browser_install
  hwvideo_apply
  if [ "$LOCALSEND_EFFECTIVE" = yes ]; then localsend_install; fi
  if [ "$OPENCODE_EFFECTIVE" = yes ]; then opencode_install; fi
  return 0
}
install_or_update() {
  operation=$1; shift
  packages=1; DM=auto; RELEASE=${NIRUX_RELEASE:-}
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --minimal|--no-packages) packages=0 ;;
      --full) packages=1 ;;
      --display-manager) shift; [ "$#" -gt 0 ] || die 'missing display-manager value'; DM=$1 ;;
      --browser) shift; [ "$#" -gt 0 ] || die 'missing browser value'; BROWSER_CHOICE=$1; BROWSER_EXPLICIT=1 ;;
      --browser-addon) shift; [ "$#" -gt 0 ] || die 'missing browser-addon value'; BROWSER_ADDON_CHOICE=$1; BROWSER_ADDON_EXPLICIT=1 ;;
      --wallpapers) shift; [ "$#" -gt 0 ] || die 'missing wallpapers value'; WALLPAPER_CHOICE=$1 ;;
      --localsend) shift; [ "$#" -gt 0 ] || die 'missing localsend value'; LOCALSEND_CHOICE=$1; LOCALSEND_EXPLICIT=1 ;;
      --opencode) shift; [ "$#" -gt 0 ] || die 'missing opencode value'; OPENCODE_CHOICE=$1; OPENCODE_EXPLICIT=1 ;;
      --tailscale) shift; [ "$#" -gt 0 ] || die 'missing tailscale value'; TAILSCALE_CHOICE=$1; TAILSCALE_EXPLICIT=1 ;;
      --icons) shift; [ "$#" -gt 0 ] || die 'missing icons value'; ICONS_CHOICE=$1; ICONS_EXPLICIT=1 ;;
      --release) shift; [ "$#" -gt 0 ] || die 'missing release version'; RELEASE=${1#v} ;;
      --apps) shift; [ "$#" -gt 0 ] || die 'missing apps value'
        case "$1" in latest|pinned) NIRUX_APPS=$1; export NIRUX_APPS ;; *) die 'apps must be latest or pinned' ;; esac ;;
      --auto) NIRUX_AUTO=1; export NIRUX_AUTO ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done
  case "${WALLPAPER_CHOICE:-}" in
    ''|all|default) ;;
    *) die 'wallpapers must be all or default' ;;
  esac
  [ "$NIRUX_AUTO" = 0 ] || [ "$operation" = update ] || die '--auto is for nirux update only'
  # The nightly update never waits for an answer.
  [ "$NIRUX_AUTO" = 0 ] || exec </dev/null
  case "$operation" in
    update) say "Updating NIRUX... please hold. Checking packages, releases and components." ;;
    install) say "Installing NIRUX... please hold. Checking packages and releases." ;;
  esac
  OS=$(distro)
  platform
  if [ "$operation" = install ]; then choose_dm; else DM=keep; fi
  choose_browser "$operation"
  browser_addon_choose
  choose_optional_apps "$operation"
  icons_choose "$operation"
  lock
  case "$BROWSER_EFFECTIVE" in
    helium|none)
      if [ "$operation" = install ] || [ "$BROWSER_EXPLICIT" = 1 ]; then
        browser_policy_set "$BROWSER_EFFECTIVE"
      fi
      ;;
  esac
  if [ "$BROWSER_EXPLICIT" = 1 ] && [ "$BROWSER_EFFECTIVE" = none ]; then
    browser_remove_managed
  fi
  if [ "$LOCALSEND_EXPLICIT" = 1 ] && [ "$LOCALSEND_EFFECTIVE" = no ]; then
    localsend_remove_managed
  fi
  if [ "$OPENCODE_EXPLICIT" = 1 ] && [ "$OPENCODE_EFFECTIVE" = no ]; then
    opencode_remove_managed
  fi
  # The bootstrap install has to include curl before any release can be
  # downloaded. Updates skip this and let the newly verified release provision
  # its own package list below.
  if [ "$operation" = install ] && [ "$packages" = 1 ]; then install_packages; fi
  if [ "$NIRUX_AUTO" = 1 ] && auto_current_release; then return 0; fi
  auto_reset
  stage_release
  # The configuration as it was before this update. The target installer of a
  # newer release takes it itself when the running one predates snapshots.
  if [ "$operation" = update ]; then snapshot_guard update "$(installed_version)" "$RELEASE" ''; fi
  # The wallpaper set is a question for this terminal, so the running
  # installer asks it and the staged target carries out the answer. It is asked
  # when the target can read the staged wallpaper files (an install or a
  # rollback to a release that ships them) and the ten themes are incomplete.
  wallpaper_decision=
  if [ "$APPLY_PROTOCOL" = 0 ] || [ "$NIRUX_STAGE_COMPONENTS" = 1 ]; then
    wallpaper_bundle_decision
    wallpaper_decision=$wp_decision
  fi
  if [ "$APPLY_PROTOCOL" = 2 ]; then
    if ! NIRUX_PREFIX=$PREFIX NIRUX_SYSTEM_ROOT=$ROOT NIRUX_STAGE_WORK=$WORK \
      NIRUX_APPLY_RELEASE=$RELEASE NIRUX_APPLY_OS=$OS \
      NIRUX_APPLY_DM=$DM NIRUX_APPLY_BROWSER=$BROWSER_EFFECTIVE \
      NIRUX_APPLY_LOCALSEND=$LOCALSEND_EFFECTIVE NIRUX_APPLY_OPENCODE=$OPENCODE_EFFECTIVE \
      NIRUX_APPLY_TAILSCALE=$TAILSCALE_EFFECTIVE \
      NIRUX_APPLY_OPERATION=$operation NIRUX_APPLY_WALLPAPERS="${wallpaper_decision:-}" \
      NIRUX_APPLY_ICONS="${ICONS_EFFECTIVE:-none}" \
      NIRUX_APPLY_BROWSER_ADDON="${BROWSER_ADDON_EFFECTIVE:-none}" \
      NIRUX_APPLY_PACKAGES="$packages" NIRUX_APPLY_SNAPSHOT=taken \
      NIRUX_SUDO_SECRET_FILE=${SUDO_SECRET_FILE:-} \
      sh "$WORK/download/nirux/nirux" _apply 2; then
      die 'target installer apply failed; current installation kept'
    fi
    return 0
  fi
  browser_install
  hwvideo_apply
  browser_addon_apply "$BROWSER_ADDON_EFFECTIVE"
  if [ "$LOCALSEND_EFFECTIVE" = yes ]; then localsend_install; else localsend_remove_managed; fi
  if [ "$OPENCODE_EFFECTIVE" = yes ]; then opencode_install; else opencode_remove_managed; fi
  ensure_user_dirs
  # Configuration and system integration must succeed before switching the
  # active programs. A rejected configuration leaves the old generation intact.
  install_config
  install_wallpapers
  select_wallpaper_bundle
  wallpapers_policy=${wallpaper_decision:-}
  wallpapers_install_bundle
  if [ "$operation" = update ]; then wallpapers_refresh_installed || :; fi
  icons_apply
  install_terminal
  prepare_pam
  install_greeters "$DM"
  # A session with no NIRUX greeter still must not keep a grant from a release
  # that installed one; the helper writes nothing when no greeter is present.
  [ -n "${rule_user:-}" ] || rule_user=${SUDO_USER:-$(id -un)}
  install_wifi_rule
  install_checkup
  install_autoupdate
  install_sleep_hook
  install_login_wallpaper_rule
  install_wallpaper_app
  install_display_app
  install_theme_selector_app
  register_session
  setup_dm_session
  setup_startx
  enable_services
  install_touchpad_rule
  install_battery_rule
  install_void_udev_replay
  activate
  start_selected_dm
  auto_finished
  apply_to_running_session 'Updated.'
  refresh_running_theme
  tailscale_setup
}
