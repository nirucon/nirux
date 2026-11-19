manifest_version() {
  value=$(awk -v n="$1" '$1 == n {print $2}' "$WORK/download/nirux/manifest")
  valid_version "$value" || die "invalid manifest entry: $1"
  say "$value"
}
component_files() {
  case "$1" in
    niruwm) say "niruwm niructl niruidle niruwm-session niruclipboard nirugestured" ;;
    *) say "$1" ;;
  esac
}
stage_component_assets() {
  component=$1
  component_version=$2
  case "$component" in
    niruwm) release_files niruwm "$component_version" niruwm niructl niruidle niruwm-session niruclipboard nirugestured ;;
    nirulock) release_files nirulock "$component_version" nirulock pam-arch pam-debian pam-void ;;
    nirux) : ;;
    *) release_files "$component" "$component_version" "$component" ;;
  esac
}
manifest_components() {
  awk '$1 != "schema" && $1 != "suite" {print $1}' "$WORK/download/nirux/manifest"
}
verify_staged_version() {
  staged_program=$1
  staged_version=$2
  [ -x "$WORK/generation/bin/$staged_program" ] || die "staged $staged_program is missing or not executable"
  staged_reported=$("$WORK/generation/bin/$staged_program" --version | awk '{print $2}')
  [ "$staged_reported" = "$staged_version" ] || die "$staged_program does not report expected version $staged_version"
}
stage_components() {
  stage_suite=$(manifest_version suite)
  # These components are part of the desktop contract even if a future manifest
  # adds more entries.
  for required in niruwm nirubar niruscreensaver nirulock nirulauncher nirunotify; do
    manifest_version "$required" >/dev/null
  done
  mkdir -p "$WORK/generation/bin"
  install -m 755 "$WORK/download/nirux/nirux" "$WORK/generation/bin/nirux"
  # The manifest, not a hardcoded list in the running installer, decides which
  # components this release contains. Unknown components use the convention of
  # one release asset with the component name.
  for component in $(manifest_components); do
    [ "$component" = nirux ] && continue
    component_version=$(manifest_version "$component")
    stage_component_assets "$component" "$component_version"
    for staged_program in $(component_files "$component"); do
      staged_source=$WORK/download/$component/$staged_program
      [ -f "$staged_source" ] || die "release $component $component_version is missing $staged_program"
      install -m 755 "$staged_source" "$WORK/generation/bin/$staged_program"
    done
  done
  cp "$WORK/download/nirux/manifest" "$WORK/generation/manifest"
  stage_manual "$stage_suite"
  [ -f "$WORK/download/nirulock/pam-$OS" ] || die "release nirulock is missing pam-$OS"
  cp "$WORK/download/nirulock/pam-$OS" "$WORK/generation/pam"
  verify_staged_version nirux "$stage_suite"
  # Running --version also catches missing loaders/shared libraries before activation.
  for component in $(manifest_components); do
    [ "$component" = nirux ] && continue
    component_version=$(manifest_version "$component")
    case "$component" in
      niruwm)
        verify_staged_version niruwm "$component_version"
        verify_staged_version niruidle "$component_version"
        verify_staged_version niruclipboard "$component_version"
        verify_staged_version nirugestured "$component_version"
        ;;
      *) verify_staged_version "$component" "$component_version" ;;
    esac
  done
}
stage_target_release() {
  [ "$1" = 1 ] || die "unsupported staging protocol: $1"
  [ -n "${NIRUX_STAGE_WORK:-}" ] || die 'staging work directory is missing'
  WORK=$NIRUX_STAGE_WORK
  OS=${NIRUX_PROVISION_OS:-$(distro)}
  [ "$(manifest_version schema)" = 1 ] || die "unsupported manifest schema"
  [ "$(manifest_version suite)" = "$VERSION" ] || die "target installer/manifest version mismatch"
  stage_components
}
apply_prepare_backup() {
  mkdir -p "$WORK/apply-backup" || die 'could not create the apply backup directory'
  APPLY_CONFIG_TARGET=$CONFDIR/config.toml
  APPLY_CONFIG_EXISTED=0
  if [ -e "$CONFDIR/config.toml" ] || [ -L "$CONFDIR/config.toml" ]; then
    if [ -L "$CONFDIR/config.toml" ]; then
      APPLY_CONFIG_TARGET=$(readlink -f "$CONFDIR/config.toml" 2>/dev/null || :)
      [ -n "$APPLY_CONFIG_TARGET" ] || die 'the configuration symlink does not resolve'
    fi
    cp -p "$APPLY_CONFIG_TARGET" "$WORK/apply-backup/config.toml" || \
      die 'could not back up the configuration before apply'
    APPLY_CONFIG_EXISTED=1
  fi
  APPLY_APPEARANCE_TARGET=$CONFDIR/appearance.toml
  APPLY_APPEARANCE_EXISTED=0
  if [ -e "$CONFDIR/appearance.toml" ] || [ -L "$CONFDIR/appearance.toml" ]; then
    if [ -L "$CONFDIR/appearance.toml" ]; then
      APPLY_APPEARANCE_TARGET=$(readlink -f "$CONFDIR/appearance.toml" 2>/dev/null || :)
      [ -n "$APPLY_APPEARANCE_TARGET" ] || die 'the appearance symlink does not resolve'
    fi
    cp -p "$APPLY_APPEARANCE_TARGET" "$WORK/apply-backup/appearance.toml" || \
      die 'could not back up the appearance file before apply'
    APPLY_APPEARANCE_EXISTED=1
  fi
}
apply_restore_config() {
  if [ "$APPLY_OK" = 1 ]; then
    rm -rf "$WORK/apply-backup"
    return 0
  fi
  if [ -n "${APPLY_CONFIG_TARGET:-}" ]; then
    if [ "${APPLY_CONFIG_EXISTED:-0}" = 1 ]; then
      cp -p "$WORK/apply-backup/config.toml" "$APPLY_CONFIG_TARGET" 2>/dev/null || :
    else
      rm -f "$APPLY_CONFIG_TARGET" 2>/dev/null || :
    fi
  fi
  if [ -n "${APPLY_APPEARANCE_TARGET:-}" ]; then
    if [ "${APPLY_APPEARANCE_EXISTED:-0}" = 1 ]; then
      cp -p "$WORK/apply-backup/appearance.toml" "$APPLY_APPEARANCE_TARGET" 2>/dev/null || :
    else
      rm -f "$APPLY_APPEARANCE_TARGET" 2>/dev/null || :
    fi
  fi
  rm -rf "$WORK/apply-backup"
  say 'Target apply failed; original configuration restored.' >&2
}
# A running installer from before snapshots hands over without one; the
# target then takes it before it changes anything.
apply_snapshot() {
  [ "$operation" = update ] && [ "${NIRUX_APPLY_SNAPSHOT:-}" != taken ] || return 0
  snapshot_guard update "$(installed_version)" "$RELEASE" ''
}
apply_target_release() {
  [ "$1" = 2 ] || die "unsupported apply protocol: $1"
  [ -n "${NIRUX_STAGE_WORK:-}" ] || die 'target apply work directory is missing'
  WORK=$NIRUX_STAGE_WORK
  OS=${NIRUX_APPLY_OS:-$(distro)}
  DM=${NIRUX_APPLY_DM:-keep}
  BROWSER_EFFECTIVE=${NIRUX_APPLY_BROWSER:-keep}
  LOCALSEND_EFFECTIVE=${NIRUX_APPLY_LOCALSEND:-yes}
  OPENCODE_EFFECTIVE=${NIRUX_APPLY_OPENCODE:-yes}
  TAILSCALE_EFFECTIVE=${NIRUX_APPLY_TAILSCALE:-keep}
  ICONS_EFFECTIVE=${NIRUX_APPLY_ICONS:-none}
  BROWSER_ADDON_EFFECTIVE=${NIRUX_APPLY_BROWSER_ADDON:-none}
  packages=${NIRUX_APPLY_PACKAGES:-1}
  operation=${NIRUX_APPLY_OPERATION:-update}
  RELEASE=${NIRUX_APPLY_RELEASE:-$(manifest_version suite)}
  [ "$(manifest_version schema)" = 1 ] || die 'unsupported manifest schema'
  [ "$(manifest_version suite)" = "$VERSION" ] || die 'target installer/manifest version mismatch'
  [ "$RELEASE" = "$VERSION" ] || die 'apply release does not match the target installer'
  [ -f "$WORK/generation/manifest" ] || die 'target apply has no staged generation'
  [ "$(awk '$1 == "suite" {print $2}' "$WORK/generation/manifest")" = "$RELEASE" ] || \
    die 'staged generation does not match the apply release'
  # The caller may predate an asset added by this target. The target owns the
  # new asset list and fetches/verifies anything it needs before changing user
  # or system files.
  release_optional_file nirux "$RELEASE" nirux-wallpapers.tar.xz
  release_optional_file nirux "$RELEASE" nirux-terminal.tar.xz
  release_optional_file nirux "$RELEASE" nirux-sounds.tar.xz
  release_optional_file nirux "$RELEASE" nirux-integration.tar.xz
  release_optional_file nirux "$RELEASE" CHANGELOG.md
  release_optional_file nirux "$RELEASE" niruwallpaper.desktop
  release_optional_file nirux "$RELEASE" niruwallpaper.png
  release_optional_file nirux "$RELEASE" nirudisplay.desktop
  release_optional_file nirux "$RELEASE" nirudisplay.png
  release_optional_file nirux "$RELEASE" niruthemeselector.desktop
  release_optional_file nirux "$RELEASE" niruthemeselector.png
  # The wallpaper policy is the running installer's answer. It is validated
  # here before any file changes, even when the target ships no wallpaper
  # files of its own.
  case "${NIRUX_APPLY_WALLPAPERS:-}" in
    ''|default|all) ;;
    *) die "invalid wallpaper choice: $NIRUX_APPLY_WALLPAPERS" ;;
  esac
  # A release without wallpaper files still accepts the policy, so the answer
  # outlives an update that lands between two releases carrying the set.
  wallpapers_policy=${NIRUX_APPLY_WALLPAPERS:-}
  if [ -z "$wallpapers_policy" ]; then
    wallpapers_policy_read
    wallpapers_policy=$wp_persisted
  fi
  [ -n "$wallpapers_policy" ] || wallpapers_policy=keep
  say "Applying NIRUX $RELEASE..."
  apply_snapshot
  apply_prepare_backup
  APPLY_OK=0
  trap 'apply_restore_config' EXIT INT TERM HUP
  browser_install
  hwvideo_apply
  browser_addon_apply "${NIRUX_APPLY_BROWSER_ADDON:-$(browser_addon_policy)}"
  if [ "$LOCALSEND_EFFECTIVE" = yes ]; then localsend_install; else localsend_remove_managed; fi
  if [ "$OPENCODE_EFFECTIVE" = yes ]; then opencode_install; else opencode_remove_managed; fi
  ensure_user_dirs
  say 'Installing configuration and desktop assets...'
  install_config
  install_wallpapers
  # Recorded once the assets are in place: a failure before this point leaves
  # the policy file untouched, and the running installer keeps its answer.
  if [ "$wallpapers_policy" != keep ]; then
    wp_persisted=$wallpapers_policy
    wallpapers_policy_write
  fi
  wallpapers_install_bundle
  if [ "$operation" = update ]; then wallpapers_refresh_installed || :; fi
  icons_apply
  install_terminal
  install_sounds
  prepare_pam
  install_greeters "$DM"
  boot_look_apply
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
  say 'Enabling session services...'
  enable_services
  install_touchpad_rule
  install_battery_rule
  install_void_udev_replay
  say 'Activating the new program generation...'
  wn_previous=$(installed_version)
  [ ! -f "$WORK/download/nirux/CHANGELOG.md" ] ||
    install -m 444 "$WORK/download/nirux/CHANGELOG.md" "$WORK/generation/CHANGELOG.md" || :
  activate
  [ "$operation" != update ] || whats_new_record "$wn_previous" "$VERSION"
  start_selected_dm
  APPLY_OK=1
  trap - EXIT INT TERM HUP
  rm -rf "$WORK/apply-backup"
  auto_finished
  apply_to_running_session 'Applied through the target installer.'
  refresh_running_theme
  tailscale_setup
}
# Re-apply the active theme after a wallpaper set becomes available. The
# installer may run from a real session (update/manual download), where the
# window manager is already using its earlier colour fallback. A fresh install
# without DISPLAY gets the files before its first session instead.
refresh_running_theme() {
  [ -n "${DISPLAY:-}" ] || return 0
  [ -x "$BIN/niructl" ] || return 0
  "$BIN/niructl" reload >/dev/null 2>&1 || :
}

# The optional theme wallpaper set is downloaded before a fresh session starts,
# so its images are present when NIRUWM first paints the desktop. On an update
# the current session is refreshed after the new generation is activated.
wallpapers_install_bundle() {
  [ "$wallpapers_policy" = all ] || return 0
  wp_install_work=$(mktemp -d "${TMPDIR:-/tmp}/nirux-wallpapers.XXXXXX") || wp_install_work=
  if [ -n "$wp_install_work" ] && WP_WORK=$wp_install_work wallpapers_download; then
    rm -rf "$wp_install_work"
    say 'Theme wallpapers installed.'
  elif [ -n "$wp_install_work" ]; then
    rm -rf "$wp_install_work"
    say 'The theme wallpapers could not be downloaded; the themes keep their background colours.'
    say 'Try again from the launcher under Wallpaper, or: nirux wallpapers download'
  else
    say 'Could not create a temporary directory for the wallpaper download.'
  fi
}
stage_release() {
  if [ -z "$RELEASE" ]; then
    say 'Checking the latest NIRUX release...'
    fetch https://api.github.com/repos/nirucon/nirux/releases/latest "$WORK/latest.json"
    RELEASE=$(sed -n 's/.*"tag_name": *"v\([0-9.]*\)".*/\1/p' "$WORK/latest.json" | head -n 1)
  fi
  say "Preparing NIRUX $RELEASE..."
  release_files nirux "$RELEASE" nirux manifest config.example.toml appearance.example.toml
  release_optional_file nirux "$RELEASE" nirux-wallpapers.tar.xz
  release_optional_file nirux "$RELEASE" nirux-terminal.tar.xz
  release_optional_file nirux "$RELEASE" nirux-sounds.tar.xz
  release_optional_file nirux "$RELEASE" nirux-integration.tar.xz
  release_optional_file nirux "$RELEASE" CHANGELOG.md
  release_optional_file nirux "$RELEASE" niruwallpaper.desktop
  release_optional_file nirux "$RELEASE" niruwallpaper.png
  release_optional_file nirux "$RELEASE" nirudisplay.desktop
  release_optional_file nirux "$RELEASE" nirudisplay.png
  release_optional_file nirux "$RELEASE" niruthemeselector.desktop
  release_optional_file nirux "$RELEASE" niruthemeselector.png
  [ "$(manifest_version schema)" = 1 ] || die "unsupported manifest schema"
  [ "$(manifest_version suite)" = "$RELEASE" ] || die "suite/manifest version mismatch"
  say 'Verifying the downloaded installer and checksums...'
  sh -n "$WORK/download/nirux/nirux"
  reported=$(sh "$WORK/download/nirux/nirux" --version | awk '{print $2}')
  [ "$reported" = "$RELEASE" ] || die 'installer/manifest version mismatch'
  APPLY_PROTOCOL=0
  apply_version=$(sh "$WORK/download/nirux/nirux" _apply-version 2>/dev/null || :)
  if [ "$apply_version" = 2 ]; then APPLY_PROTOCOL=2; fi
  # Packages come from the verified target installer and are provisioned before
  # any staged binary is executed. This lets a new shared-library dependency be
  # present when the new component is first started and version-checked. The
  # staged target resolves renames (Debian trixie's *t64 libraries) from this
  # machine's own package database, so its list is the one installed.
  if [ "$packages" = 1 ]; then
    say 'Checking required OS packages...'
    NIRUX_SYSTEM_ROOT=$ROOT NIRUX_PROVISION_OS=$OS NIRUX_PROVISION_DM=$DM NIRUX_PROVISION_BROWSER=$BROWSER_EFFECTIVE \
      sh "$WORK/download/nirux/nirux" _provision missing
  fi
  # A new target installer stages the release through a versioned handoff, so a
  # newly added component is included on the first update rather than one later.
  handoff=$(sh "$WORK/download/nirux/nirux" _handoff-version 2>/dev/null || :)
  if [ "$handoff" = 1 ]; then
    if ! NIRUX_STAGE_WORK=$WORK NIRUX_PROVISION_OS=$OS \
      sh "$WORK/download/nirux/nirux" _stage 1; then
      die 'target installer staging failed; current installation kept'
    fi
    say 'Staged components. Validating generation...'
    NIRUX_STAGE_COMPONENTS=1
  else
    stage_components
    NIRUX_STAGE_COMPONENTS=0
  fi
  [ -f "$WORK/generation/manifest" ] || die 'target installer produced no staged generation'
  [ "$(awk '$1 == "suite" {print $2}' "$WORK/generation/manifest")" = "$RELEASE" ] || \
    die 'staged generation does not match the requested release'
}
switch_link() {
  ln -s "$2" "$STATE/.$1.$$"
  mv -Tf "$STATE/.$1.$$" "$STATE/$1"
}
sync_front_links() {
  for front in "$BIN"/*; do
    [ -L "$front" ] || continue
    case "$(readlink "$front")" in
      "$STATE/current/bin/"*)
        program=${front##*/}
        [ -e "$STATE/current/bin/$program" ] || rm -f "$front"
        ;;
    esac
  done
}
activate() {
  mkdir -p "$STATE/generations" "$BIN"
  # Adopt a legacy flat installation without changing its active versions.
  if [ ! -L "$STATE/current" ]; then
    legacy=$STATE/generations/legacy-$(date +%s)-$$
    mkdir -p "$legacy/bin"
    for program in $PROGRAMS; do
      [ ! -f "$BIN/$program" ] || cp -pL "$BIN/$program" "$legacy/bin/$program"
    done
    switch_link current "$legacy"
  fi
  old=$(readlink "$STATE/current")
  generation=$STATE/generations/$RELEASE-${WORK##*.}
  mv "$WORK/generation" "$generation"
  # These front links stay constant; current is the single activation point.
  # Use the staged generation rather than this installer's old PROGRAMS list so
  # a component added by the target release is linked on the first update.
  for staged in "$generation/bin"/*; do
    [ -f "$staged" ] || continue
    program=${staged##*/}
    ln -s "$STATE/current/bin/$program" "$BIN/.$program.$$"
    mv -Tf "$BIN/.$program.$$" "$BIN/$program"
  done
  switch_link previous "$old"
  switch_link current "$generation"
  sync_front_links
  say "Activated NIRUX $RELEASE. Previous generation retained for nirux rollback."
  gc_generations "${NIRUX_KEEP_GENERATIONS:-5}" 0 || :
}
# Remove old program generations. Kept no matter what: current, previous (the
# rollback target) and any generation a running program still executes from,
# such as a session that has not logged out since an update. Of the rest, the
# KEEP newest stay. Only directories directly under generations/ are removed.
gc_generations() {
  gc_keep=$1; gc_dry=$2
  [ -d "$STATE/generations" ] || return 0
  # Physical path: /proc/PID/exe and readlink -f report resolved paths.
  gc_dir=$(cd "$STATE/generations" && pwd -P) || return 0
  case "$gc_keep" in ''|*[!0-9]*) die 'keep must be a number' ;; esac
  gc_current=$(readlink -f "$STATE/current" 2>/dev/null || :)
  gc_previous=$(readlink -f "$STATE/previous" 2>/dev/null || :)
  gc_running=$(for gc_exe in /proc/[0-9]*/exe; do readlink "$gc_exe" 2>/dev/null || :; done |
    sed -n "s#^\($gc_dir/[^/]*\)/.*#\1#p" | sort -u)
  gc_seen=0; gc_removed=0; gc_kept=0
  # Newest first by modification time; generation names never contain spaces.
  # shellcheck disable=SC2012
  gc_list=$(ls -1dt "$gc_dir"/*/ 2>/dev/null || :)
  for gc_gen in $gc_list; do
    gc_gen=${gc_gen%/}
    case "$gc_gen" in "$gc_dir"/*/*|"$gc_dir"/.*) continue ;; esac
    [ -d "$gc_gen" ] && [ ! -L "$gc_gen" ] || continue
    gc_seen=$((gc_seen + 1))
    gc_reason=
    if [ "$gc_gen" = "$gc_current" ]; then gc_reason=current
    elif [ "$gc_gen" = "$gc_previous" ]; then gc_reason=previous
    elif printf '%s\n' "$gc_running" | grep -qxF "$gc_gen"; then gc_reason=running
    elif [ "$gc_seen" -le "$gc_keep" ]; then gc_reason=recent
    fi
    if [ -n "$gc_reason" ]; then
      gc_kept=$((gc_kept + 1))
      [ "$gc_dry" = 1 ] && say "keep   ${gc_gen##*/} ($gc_reason)"
      continue
    fi
    if [ "$gc_dry" = 1 ]; then
      say "remove ${gc_gen##*/}"
    else
      rm -rf -- "$gc_gen"
    fi
    gc_removed=$((gc_removed + 1))
  done
  if [ "$gc_dry" = 1 ]; then
    say "Would remove $gc_removed of $gc_seen generations; $gc_kept kept."
  elif [ "$gc_removed" -gt 0 ]; then
    say "Removed $gc_removed old program generations; $gc_kept kept (current, previous, running and the $gc_keep newest)."
  fi
}
gc_command() {
  gc_keep=${NIRUX_KEEP_GENERATIONS:-5}; gc_dry=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --keep) shift; [ "$#" -gt 0 ] || die 'missing --keep value'; gc_keep=$1 ;;
      --dry-run|-n) gc_dry=1 ;;
      *) die "usage: nirux gc [--keep N] [--dry-run]" ;;
    esac
    shift
  done
  lock
  gc_generations "$gc_keep" "$gc_dry"
}
