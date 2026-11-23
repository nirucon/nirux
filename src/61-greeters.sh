install_nirulogin() {
  [ -x "$WORK/generation/bin/nirulogin" ] || die 'staged nirulogin is missing'
  greeter_user=
  for candidate in _greetd greeter _greeter; do
    getent passwd "$candidate" >/dev/null 2>&1 && { greeter_user=$candidate; break; }
  done
  [ -n "$greeter_user" ] || die 'greetd greeter user is missing'
  as_root install -m 755 "$WORK/generation/bin/nirulogin" "$ROOT/usr/local/bin/nirulogin"
  { say '#!/bin/sh'; say 'set -eu'; say 'layout=${NIRULOGIN_LAYOUT:-se}'; say 'setxkbmap -layout "$layout" 2>/dev/null || :'; say 'session=${NIRULOGIN_SESSION:-}'; say 'case "$session" in ""|/usr/local/bin/nirulogin-session) session=$HOME/.local/bin/niruwm-session ;; esac'; say 'exec "$session"'; } > "$WORK/nirulogin-session"
  as_root install -m 755 "$WORK/nirulogin-session" "$ROOT/usr/local/bin/nirulogin-session"
  as_root install -d -m 755 "$ROOT/etc/nirulogin"
  as_root install -d -o "$greeter_user" -g "$(id -gn "$greeter_user")" -m 700 "$ROOT/var/lib/nirulogin"
  if ! as_root test -f "$ROOT/etc/nirulogin/layouts"; then
    { say "# NIRULOGIN owner: $PREFIX"; say '# Keyboard layouts offered at the login screen; the first is the default.'; say '# Add or remove XKB layout codes here. Examples: se, us, gb, de, fr.'; say 'se'; say 'us'; } > "$WORK/nirulogin-layouts"
    write_system "$ROOT/etc/nirulogin/layouts" "$WORK/nirulogin-layouts"
  fi
  { say 'polkit.addRule(function(action, subject) {'; say '    if (!subject.local || !subject.active) return;'; say '    if (subject.user != "_greetd" && subject.user != "greeter" && subject.user != "_greeter") return;'; say '    var allowed = ["org.freedesktop.login1.power-off", "org.freedesktop.login1.reboot"];'; say '    if (allowed.indexOf(action.id) >= 0) return polkit.Result.YES;'; say '    var others = ["org.freedesktop.login1.power-off-multiple-sessions", "org.freedesktop.login1.reboot-multiple-sessions"];'; say '    if (others.indexOf(action.id) >= 0) return polkit.Result.AUTH_ADMIN;'; say '});'; } > "$WORK/nirulogin-power.rules"
  as_root install -D -m 0644 "$WORK/nirulogin-power.rules" "$ROOT/etc/polkit-1/rules.d/49-nirulogin-power.rules"
  as_root install -d -m 755 "$ROOT/etc/greetd"
  if as_root test -f "$ROOT/etc/X11/Xwrapper.config" &&
     ! as_root test -f "$ROOT/etc/X11/Xwrapper.config.before-nirulogin"; then
    as_root cp -a "$ROOT/etc/X11/Xwrapper.config" "$ROOT/etc/X11/Xwrapper.config.before-nirulogin"
  fi
  # Xorg.wrap skips comment lines, so the file carries the owner line that lets
  # uninstall recognise and remove it.
  { say "# NIRUX owner: $PREFIX"; say 'allowed_users=anybody'; say 'needs_root_rights=yes'; } > "$WORK/Xwrapper.config"
  write_system "$ROOT/etc/X11/Xwrapper.config" "$WORK/Xwrapper.config"
  if as_root test -f "$ROOT/etc/greetd/config.toml" &&
     ! as_root test -f "$ROOT/etc/greetd/config.toml.before-nirulogin" &&
     ! as_root grep -q '^# NIRULOGIN owner:' "$ROOT/etc/greetd/config.toml" 2>/dev/null; then
    as_root cp -a "$ROOT/etc/greetd/config.toml" "$ROOT/etc/greetd/config.toml.before-nirulogin"
  fi
  # The greeter runs startx with HOME=/var/lib/greetd, so xauth must be able to
  # write there. A greetd package that was purged and installed again gets a
  # new greeter uid while the old home stays behind with the old owner; xauth
  # then waits forever for its lock and no login screen appears (seen on
  # Debian). Make the home exist and belong to the current greeter account.
  greeter_home=$ROOT/var/lib/greetd
  as_root install -d -m 700 "$greeter_home"
  if greeter_uid=$(id -u "$greeter_user" 2>/dev/null) &&
     [ "$(as_root stat -c %u "$greeter_home" 2>/dev/null || :)" != "$greeter_uid" ]; then
    as_root chown -R "$greeter_user:$(id -gn "$greeter_user")" "$greeter_home"
  fi
  { say "# NIRULOGIN owner: $PREFIX"; say '[terminal]'; say 'vt = 7'; say ''; say '[general]'; say 'source_profile = false'; say ''; say '[default_session]'; say "command = \"env HOME=/var/lib/greetd /usr/bin/startx /usr/local/bin/nirulogin -- :0 vt7\""; say "user = \"$greeter_user\""; } > "$WORK/nirulogin-greetd.toml"
  write_system "$ROOT/etc/greetd/config.toml" "$WORK/nirulogin-greetd.toml"
  ensure_greetd_keyring_pam
  if [ "$OS" = void ]; then
    [ -d "$ROOT/etc/sv/greetd" ] || die 'missing greetd runit service'
  else
    if as_root test -L "$ROOT/etc/systemd/system/display-manager.service" &&
       ! as_root test -f "$ROOT/etc/nirulogin-previous-display-manager"; then
      as_root readlink "$ROOT/etc/systemd/system/display-manager.service" > "$WORK/previous-dm"
      write_system "$ROOT/etc/nirulogin-previous-display-manager" "$WORK/previous-dm"
    fi
    if [ "$(readlink "$ROOT/etc/systemd/system/display-manager.service" 2>/dev/null)" != /lib/systemd/system/greetd.service ]; then
      as_root rm -f "$ROOT/etc/systemd/system/display-manager.service"
      as_root ln -s /lib/systemd/system/greetd.service "$ROOT/etc/systemd/system/display-manager.service"
    fi
  fi
  say 'Installed NIRU Login greeter'
}

install_greeters() {
  greeter_dm=${1:-keep}
  # `keep` must still install a themed greeter on the display manager the
  # machine actually uses. Looking only for NIRUX's own files meant that a
  # machine whose greeter was never installed stayed without a theme and
  # without the theme wallpaper forever: every update asked for "keep", found
  # nothing of its own, and did nothing.
  case "$greeter_dm" in
    keep)
      if [ -f "$ROOT/etc/greetd/config.toml" ] && owned "$ROOT/etc/greetd/config.toml"; then
        greeter_dm=nirulogin
      elif [ -f "$ROOT/etc/sddm.conf.d/50-nirux.conf" ] && owned "$ROOT/etc/sddm.conf.d/50-nirux.conf"; then
        greeter_dm=sddm
      elif [ -f "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" ] &&
           owned "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf"; then
        greeter_dm=lightdm
      else
        # No NIRUX greeter yet: adopt the display manager in use, never a
        # different one. `existing_dm` reports what is installed.
        case "$(existing_dm)" in
          nirulogin|sddm|lightdm) greeter_dm=$(existing_dm) ;;
          greetd) greeter_dm=nirulogin ;;
        esac
      fi
      ;;
  esac

  archive=$WORK/download/nirux/nirux-integration.tar.xz
  [ -f "$archive" ] || return 0
  unpack=$WORK/integration-unpack
  rm -rf "$unpack"
  mkdir -p "$unpack" || die 'could not create the integration extraction directory'
  tar -xJf "$archive" -C "$unpack" || die 'could not extract the NIRUX integration assets'
  [ -f "$unpack/polkit/49-nirux-power.rules" ] || die 'integration archive is missing the power rule'
  login_wallpaper_source=$(selected_login_wallpaper || theme_login_wallpaper || :)
  if [ -n "$login_wallpaper_source" ]; then
    is_png "$login_wallpaper_source" || die "selected login wallpaper is not a PNG: $login_wallpaper_source"
    say "Using selected login wallpaper: $login_wallpaper_source"
  else
    login_wallpaper_source=$unpack/background.png
  fi
  [ -f "$login_wallpaper_source" ] || die "login wallpaper not found: $login_wallpaper_source"
  # The installing account can already use sudo, so it is also trusted for the
  # local power menu even when sudo comes from a sudoers rule rather than a
  # wheel/sudo group membership. Remote sessions remain excluded.
  rule_user=${SUDO_USER:-$(id -un)}
  if [ -d "$PREFIX" ]; then
    prefix_owner=$(stat -c '%U' "$PREFIX" 2>/dev/null || :)
    [ -z "$prefix_owner" ] || [ "$prefix_owner" = root ] || rule_user=$prefix_owner
  fi
  case "$rule_user" in *[!A-Za-z0-9._-]*) rule_user= ;; esac
  { say "// NIRUX owner: $PREFIX"; sed "s/__NIRUX_USER__/$rule_user/g" "$unpack/polkit/49-nirux-power.rules"; } > "$WORK/power.rules"
  write_system "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules" "$WORK/power.rules"

  case "$greeter_dm" in
    nirulogin)
      install_nirulogin
      ;;
    sddm)
      for file in theme.conf arrow.png; do
        [ -f "$unpack/sddm/$file" ] || die "integration archive is missing sddm/$file"
        write_system "$ROOT/usr/share/sddm/themes/nirux/$file" "$unpack/sddm/$file"
      done
      [ -f "$unpack/sddm/metadata.desktop" ] || die 'integration archive is missing sddm/metadata.desktop'
      # Trixie supplies only sddm-greeter-qt6. Without QtVersion, SDDM
      # assumes Qt5 and silently replaces the NIRUX theme with its fallback.
      { say "# NIRUX owner: $PREFIX"; sed '/^QtVersion=/d' "$unpack/sddm/metadata.desktop"; say "QtVersion=$(sddm_qt_version)"; } > "$WORK/sddm-metadata.desktop"
      write_system "$ROOT/usr/share/sddm/themes/nirux/metadata.desktop" "$WORK/sddm-metadata.desktop"
      write_system "$ROOT/usr/share/sddm/themes/nirux/background.png" "$login_wallpaper_source"
      [ -f "$unpack/sddm/Main.qml" ] || die 'integration archive is missing sddm/Main.qml'
      { say "// NIRUX owner: $PREFIX"; cat "$unpack/sddm/Main.qml"; } > "$WORK/sddm-Main.qml"
      write_system "$ROOT/usr/share/sddm/themes/nirux/Main.qml" "$WORK/sddm-Main.qml"
      { say "# NIRUX owner: $PREFIX"; say '[Theme]'; say 'Current=nirux'; } > "$WORK/sddm-nirux.conf"
      write_system "$ROOT/etc/sddm.conf.d/50-nirux.conf" "$WORK/sddm-nirux.conf"
      say 'Installed NIRUX SDDM greeter'
      ;;
    lightdm)
      [ -f "$unpack/lightdm/50-nirux.conf" ] || die 'integration archive is missing the LightDM greeter config'
      [ -f "$unpack/gtk/index.theme" ] || die 'integration archive is missing the GTK theme'
      [ -f "$unpack/gtk/gtk-3.0/gtk.css" ] || die 'integration archive is missing the GTK stylesheet'
      as_root install -d -m 755 "$ROOT/usr/share/nirux/greeter"
      write_system "$ROOT/usr/share/nirux/greeter/login.png" "$login_wallpaper_source"
      [ ! -f "$ROOT/usr/share/nirux/greeter/rooted-in-less.png" ] || as_root rm -f "$ROOT/usr/share/nirux/greeter/rooted-in-less.png"
      { say "# NIRUX owner: $PREFIX"; sed 's|^background=.*|background=/usr/share/nirux/greeter/login.png|' "$unpack/lightdm/50-nirux.conf"; } > "$WORK/lightdm-nirux.conf"
      write_system "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" \
        "$WORK/lightdm-nirux.conf"
      { say "# NIRUX owner: $PREFIX"; cat "$unpack/gtk/index.theme"; } > "$WORK/gtk-index.theme"
      write_system "$ROOT/usr/share/themes/NIRU/index.theme" "$WORK/gtk-index.theme"
      { say "/* NIRUX owner: $PREFIX */"; cat "$unpack/gtk/gtk-3.0/gtk.css"; } > "$WORK/gtk.css"
      write_system "$ROOT/usr/share/themes/NIRU/gtk-3.0/gtk.css" "$WORK/gtk.css"
      say 'Installed NIRUX LightDM GTK greeter'
      ;;
  esac
  # The login screen follows the theme without a password: the grant names the
  # picture file the greeter above actually installed.
  install_login_wallpaper_rule
  rm -rf "$unpack"
}

# Restore the X wrapper policy NIRU Login replaced. A saved copy that only
# holds NIRUX's own policy came from an earlier release and is dropped; the
# distribution default (console users only) then applies again.
restore_xwrapper() {
  xwrapper=$ROOT/etc/X11/Xwrapper.config
  for saved in "$xwrapper.before-nirulogin" "$xwrapper.nirux-backup"; do
    as_root test -f "$saved" || continue
    if nirux_xwrapper "$saved"; then
      as_root rm -f "$saved"
    elif as_root test -f "$xwrapper" && { owned_system "$xwrapper" || nirux_xwrapper "$xwrapper"; }; then
      as_root mv -f "$saved" "$xwrapper"
    fi
  done
  if as_root test -f "$xwrapper" && { owned_system "$xwrapper" || nirux_xwrapper "$xwrapper"; }; then
    as_root rm -f "$xwrapper"
  fi
}
# The X wrapper policy NIRU Login writes, also as releases before the owner
# line wrote it: exactly these two settings and nothing else.
nirux_xwrapper() {
  [ "$(as_root grep -v '^#' "$1" 2>/dev/null | grep -c .)" = 2 ] &&
    as_root grep -qx 'allowed_users=anybody' "$1" 2>/dev/null &&
    as_root grep -qx 'needs_root_rights=yes' "$1" 2>/dev/null
}

remove_greeters() {
  dm_link=$ROOT/etc/systemd/system/display-manager.service
  nirulogin_installed=0
  if { [ -f "$ROOT/etc/greetd/config.toml" ] && owned "$ROOT/etc/greetd/config.toml"; } ||
     [ -f "$ROOT/usr/local/bin/nirulogin" ]; then
    nirulogin_installed=1
  fi
  # Give greetd back the configuration it had before NIRU Login. When there is
  # none, NIRUX installed greetd only to run NIRU Login: an enabled greetd with
  # no configuration cannot start, so it is disabled below.
  greetd_restored=0
  if [ -f "$ROOT/etc/greetd/config.toml" ] && owned "$ROOT/etc/greetd/config.toml"; then
    if as_root test -f "$ROOT/etc/greetd/config.toml.before-nirulogin"; then
      as_root mv -f "$ROOT/etc/greetd/config.toml.before-nirulogin" "$ROOT/etc/greetd/config.toml"
      greetd_restored=1
    elif as_root test -f "$ROOT/etc/greetd/config.toml.nirux-backup" &&
         ! nirux_written "$ROOT/etc/greetd/config.toml.nirux-backup"; then
      as_root mv -f "$ROOT/etc/greetd/config.toml.nirux-backup" "$ROOT/etc/greetd/config.toml"
      greetd_restored=1
    else
      as_root rm -f "$ROOT/etc/greetd/config.toml"
    fi
    # write_system kept a second copy of the same original.
    as_root rm -f "$ROOT/etc/greetd/config.toml.nirux-backup"
  fi
  previous_dm=
  if [ -f "$ROOT/etc/nirulogin-previous-display-manager" ]; then
    previous_dm=$(as_root cat "$ROOT/etc/nirulogin-previous-display-manager" 2>/dev/null || :)
  fi
  case "$previous_dm" in
    */lightdm.service|*/sddm.service|*/gdm.service|*/gdm3.service)
      as_root rm -f "$dm_link"
      as_root ln -s "$previous_dm" "$dm_link"
      ;;
    *)
      if [ "$nirulogin_installed" = 1 ] && [ "$greetd_restored" = 0 ]; then
        if [ -L "$dm_link" ] && [ "$(basename "$(readlink "$dm_link")")" = greetd.service ]; then
          as_root rm -f "$dm_link"
        fi
        if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
          as_root systemctl disable greetd.service >/dev/null 2>&1 || :
        fi
        if [ -L "$ROOT/var/service/greetd" ]; then as_root rm -f "$ROOT/var/service/greetd"; fi
        say 'NIRU Login removed and greetd disabled; the current login screen keeps running until the next boot.'
        say 'After that, log in on a text console or enable the display manager you want.'
      elif [ "$greetd_restored" = 1 ]; then
        say 'Restored the previous greetd configuration.'
      fi
      ;;
  esac
  as_root rm -f "$ROOT/etc/nirulogin-previous-display-manager"
  if [ "$nirulogin_installed" = 1 ]; then restore_xwrapper; fi
  if [ "$nirulogin_installed" = 1 ]; then remove_greetd_keyring_pam; fi
  if [ -f "$ROOT/usr/local/bin/nirulogin" ]; then as_root rm -f "$ROOT/usr/local/bin/nirulogin"; fi
  if [ -f "$ROOT/usr/local/bin/nirulogin-session" ]; then as_root rm -f "$ROOT/usr/local/bin/nirulogin-session"; fi
  as_root rm -rf "$ROOT/var/lib/nirulogin"
  if [ -f "$ROOT/etc/nirulogin/layouts" ] && owned "$ROOT/etc/nirulogin/layouts"; then
    as_root rm -f "$ROOT/etc/nirulogin/layouts"
    as_root rmdir "$ROOT/etc/nirulogin" 2>/dev/null || :
  fi
  # The rules directory is 0750 root:polkitd, so only root can see the file.
  if as_root test -f "$ROOT/etc/polkit-1/rules.d/49-nirulogin-power.rules"; then as_root rm -f "$ROOT/etc/polkit-1/rules.d/49-nirulogin-power.rules"; fi
  remove_system "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules"
  remove_system "$ROOT/etc/sudoers.d/49-nirux-login-wallpaper"
  remove_system "$ROOT/etc/sudoers.d/49-nirux-wifi"
  remove_system "$ROOT/etc/sudoers.d/zz-nirux-wifi"
  remove_system "$ROOT/usr/libexec/nirux-wifi"
  remove_checkup
  remove_autoupdate
  remove_sleep_hook
  remove_void_elogind_activation
  remove_void_udev_replay
  remove_passwd_keyring_pam
  remove_system "$ROOT$TOUCHPAD_RULE"
  remove_system "$ROOT$BATTERY_RULE"
  remove_system "$ROOT/etc/sddm.conf.d/50-nirux.conf"
  remove_system "$ROOT/etc/lightdm/lightdm.conf.d/50-nirux-session.conf"
  if [ -f "$ROOT/usr/share/sddm/themes/nirux/Main.qml" ] &&
     owned "$ROOT/usr/share/sddm/themes/nirux/Main.qml"; then
    as_root rm -rf "$ROOT/usr/share/sddm/themes/nirux"
  fi
  remove_system "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf"
  if [ -f "$ROOT/usr/share/themes/NIRU/index.theme" ] &&
     owned "$ROOT/usr/share/themes/NIRU/index.theme"; then
    as_root rm -rf "$ROOT/usr/share/themes/NIRU"
  fi
  # /usr/share/nirux is NIRUX's own directory; saved copies of earlier greeter
  # pictures go with it.
  for file in rooted-in-less.png login.png rooted-in-less.png.nirux-backup login.png.nirux-backup; do
    if [ -f "$ROOT/usr/share/nirux/greeter/$file" ]; then
      as_root rm -f "$ROOT/usr/share/nirux/greeter/$file"
    fi
  done
  as_root rmdir "$ROOT/usr/share/nirux/greeter" "$ROOT/usr/share/nirux" 2>/dev/null || :
}

register_session() {
  { say "# NIRUX owner: $PREFIX"; say '[Desktop Entry]'; say 'Name=NIRUWM'; say 'Type=Application'; say "Exec=$BIN/niruwm-session"; say 'DesktopNames=NIRUWM'; } > "$WORK/session.desktop"
  write_system "$ROOT/usr/share/xsessions/niruwm.desktop" "$WORK/session.desktop"
}
# The wallpaper window is launched from NIRULAUNCHER and from the app menu. Its
# entry and icon come from the release so they stay in step with the binary
# that actually reports the version.
install_wallpaper_app() {
  # A release older than the app's first published assets has the program but
  # not its entry and icon. Skipping them is correct; failing would make the
  # installer refuse a release that is otherwise fine.
  [ -f "$WORK/download/nirux/niruwallpaper.desktop" ] || return 0
  [ -f "$WORK/download/nirux/niruwallpaper.png" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=niruwallpaper$|Exec=$BIN/niruwallpaper|" \
      "$WORK/download/nirux/niruwallpaper.desktop"; } > "$WORK/niruwallpaper.desktop"
  # The icon is a PNG, so it is installed byte for byte and its ownership is
  # recorded beside it: a comment in front of the PNG header would make it an
  # invalid image.
  write_system "$ROOT/usr/share/applications/niruwallpaper.desktop" "$WORK/niruwallpaper.desktop"
  write_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png" "$WORK/download/nirux/niruwallpaper.png"
}
remove_wallpaper_app() {
  remove_system "$ROOT/usr/share/applications/niruwallpaper.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/niruwallpaper.png"
  # The directories themselves belong to the package manager. Removing one that
  # happens to be empty would delete a system directory NIRUX never owned, and
  # the hicolor theme is shared with every other application.
}
# NIRUFM, the file manager: its entry and pixel icon come with its release.
install_file_manager_app() {
  fm_dir=$WORK/download/nirufm
  [ -f "$fm_dir/nirufm.desktop" ] || return 0
  [ -f "$fm_dir/nirufm.svg" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=nirufm |Exec=$BIN/nirufm |" "$fm_dir/nirufm.desktop"; } > "$WORK/nirufm.desktop"
  write_system "$ROOT/usr/share/applications/nirufm.desktop" "$WORK/nirufm.desktop"
  # The icon is installed byte for byte; its ownership is recorded beside it.
  write_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/nirufm.svg" "$fm_dir/nirufm.svg"
}
remove_file_manager_app() {
  remove_system "$ROOT/usr/share/applications/nirufm.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/nirufm.svg"
}
# NIRUTERM, the terminal: entry and pixel icon from its release. kitty stays
# the terminal of Super+Enter until the owner switches.
install_terminal_app() {
  term_dir=$WORK/download/niruterm
  [ -f "$term_dir/niruterm.desktop" ] || return 0
  [ -f "$term_dir/niruterm.svg" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=niruterm$|Exec=$BIN/niruterm|" "$term_dir/niruterm.desktop"; } > "$WORK/niruterm.desktop"
  write_system "$ROOT/usr/share/applications/niruterm.desktop" "$WORK/niruterm.desktop"
  write_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/niruterm.svg" "$term_dir/niruterm.svg"
}
remove_terminal_app() {
  remove_system "$ROOT/usr/share/applications/niruterm.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/niruterm.svg"
}
# The NIRUCLIP editor: entry and pixel icon from its release, so videos get
# "Open with NIRUCLIP Editor" and the launcher lists it.
install_video_editor_app() {
  clip_dir=$WORK/download/niruclip
  [ -f "$clip_dir/niruclip-edit.desktop" ] || return 0
  [ -f "$clip_dir/niruclip.svg" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=niruclip |Exec=$BIN/niruclip |" "$clip_dir/niruclip-edit.desktop"; } > "$WORK/niruclip-edit.desktop"
  write_system "$ROOT/usr/share/applications/niruclip-edit.desktop" "$WORK/niruclip-edit.desktop"
  write_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/niruclip.svg" "$clip_dir/niruclip.svg"
}
remove_video_editor_app() {
  remove_system "$ROOT/usr/share/applications/niruclip-edit.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/scalable/apps/niruclip.svg"
}
# Folders opened by other programs ("show in folder", xdg-open DIR) go to
# NIRUFM, unless the user chose a file manager other than pcmanfm or NIRUORG,
# the two it replaced.
file_manager_default() {
  [ -x "$BIN/nirufm" ] || return 0
  command -v xdg-mime >/dev/null 2>&1 || return 0
  fm_now=$(xdg-mime query default inode/directory 2>/dev/null || :)
  case "$fm_now" in
    nirufm.desktop) return 0 ;;
    ''|pcmanfm*.desktop|niruorg*.desktop) xdg-mime default nirufm.desktop inode/directory 2>/dev/null || : ;;
    *) return 0 ;;
  esac
}
# NIRU Display is the graphical monitor editor. Its entry and icon travel with
# the component release so they cannot drift from the binary's version.
install_display_app() {
  [ -f "$WORK/download/nirux/nirudisplay.desktop" ] || return 0
  [ -f "$WORK/download/nirux/nirudisplay.png" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=nirudisplay$|Exec=$BIN/nirudisplay|" \
      "$WORK/download/nirux/nirudisplay.desktop"; } > "$WORK/nirudisplay.desktop"
  write_system "$ROOT/usr/share/applications/nirudisplay.desktop" "$WORK/nirudisplay.desktop"
  write_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/nirudisplay.png" "$WORK/download/nirux/nirudisplay.png"
}
remove_display_app() {
  remove_system "$ROOT/usr/share/applications/nirudisplay.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/nirudisplay.png"
}
# NIRU Theme Selector is the graphical appearance entry point. It is optional
# only in the sense that an older release may lack its desktop assets.
install_theme_selector_app() {
  [ -f "$WORK/download/nirux/niruthemeselector.desktop" ] || return 0
  [ -f "$WORK/download/nirux/niruthemeselector.png" ] || return 0
  { say "# NIRUX owner: $PREFIX"; sed "s|^Exec=niruthemeselector$|Exec=$BIN/niruthemeselector|" \
      "$WORK/download/nirux/niruthemeselector.desktop"; } > "$WORK/niruthemeselector.desktop"
  write_system "$ROOT/usr/share/applications/niruthemeselector.desktop" "$WORK/niruthemeselector.desktop"
  write_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/niruthemeselector.png" "$WORK/download/nirux/niruthemeselector.png"
}
remove_theme_selector_app() {
  remove_system "$ROOT/usr/share/applications/niruthemeselector.desktop"
  remove_binary "$ROOT/usr/share/icons/hicolor/256x256/apps/niruthemeselector.png"
}
# Registration only makes NIRUWM available. Debian's Default Xsession (and
# other desktops on Arch/Void) can otherwise win the first-login selection.
# Only an explicit install selects defaults; keep/update never change them.
setup_dm_session() {
  [ "$operation" = install ] || return 0
  case "$DM" in
    lightdm)
      { say "# NIRUX owner: $PREFIX"; say '[Seat:*]'; say 'user-session=niruwm'; } > "$WORK/lightdm-session.conf"
      write_system "$ROOT/etc/lightdm/lightdm.conf.d/50-nirux-session.conf" "$WORK/lightdm-session.conf"
      ;;
    sddm|keep)
      # `keep` means an existing display manager, which may be SDDM.
      [ "$DM" = sddm ] || [ -d "$ROOT/var/lib/sddm" ] || [ -f "$ROOT/usr/bin/sddm" ] || return 0
      forget_sddm_session
      ;;
  esac
}

# SDDM keeps the last chosen session in its own state file, so a machine that
# used another desktop keeps preselecting it after NIRUX is installed, and a
# machine that has used NIRUX can be left on an old NIRUPI entry. On install
# NIRUX therefore names the NIRUWM session as the remembered one: the login
# screen preselects it, every installed session stays in its list, and a
# session chosen later at the login screen is remembered as usual.
#
# Autologin, the remembered user, the theme and every other setting are left
# exactly as they are. The file lives in /var/lib/sddm, which is not world
# readable; when it cannot be read the choice is simply not changed, and the
# session list offered by SDDM is unaffected either way.
sddm_session_entry() {
  # SDDM finds a session by its path under /usr/share (the root prefix is a
  # test-only redirect), and a plain file name works too.
  if [ -f "$ROOT/usr/share/xsessions/niruwm.desktop" ]; then
    say /usr/share/xsessions/niruwm.desktop
  else
    say niruwm.desktop
  fi
}
forget_sddm_session() {
  sddm_state=$ROOT/var/lib/sddm/state.conf
  as_root test -f "$sddm_state" || return 0
  sddm_wanted=$(sddm_session_entry)
  sddm_text=
  if as_root test -s "$sddm_state"; then
    sddm_text=$(as_root cat "$sddm_state" 2>/dev/null) || sddm_text=read-failed
  fi
  if [ "$sddm_text" = read-failed ]; then
    say 'SDDM state is not readable; its session choice was left unchanged'
    return 0
  fi
  printf '%s\n' "$sddm_text" > "$WORK/sddm-state.original"
  sddm_remembered=$(awk '
    /^[[:space:]]*\[/ { last = ($0 ~ /^[[:space:]]*\[Last\][[:space:]]*$/) }
    last && /^[[:space:]]*Session[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, ""); print; exit
    }
  ' "$WORK/sddm-state.original")
  # SDDM writes a trailing space after the path.
  while [ "${sddm_remembered% }" != "$sddm_remembered" ]; do sddm_remembered=${sddm_remembered% }; done
  # An unreadable file was skipped above; an empty one carries no text, so it
  # still gets the [Last] section below.
  if [ "$sddm_text" != read-failed ] && [ "${sddm_remembered##*/}" = "${sddm_wanted##*/}" ]; then
    say 'SDDM already preselects NIRUWM'
    return 0
  fi
  # Autologin is configured in SDDM's own main configuration, not in the
  # state file. When it is on, a remembered session is not what starts the
  # machine, and the user's setup is left exactly as it is.
  sddm_autologin=0
  for sddm_conf in "$ROOT/etc/sddm.conf" "$ROOT"/etc/sddm.conf.d/*.conf; do
    [ -f "$sddm_conf" ] || continue
    if as_root grep -q '^[[:space:]]*User[[:space:]]*=[[:space:]]*[^[:space:]]' \
        "$sddm_conf" 2>/dev/null; then
      sddm_autologin=1
    fi
  done
  if [ "$sddm_autologin" = 1 ]; then
    say 'SDDM autologin is configured; its remembered session was left unchanged'
    return 0
  fi
  # The remembered session is replaced in place under [Last]. A file with no
  # [Last] section gets one first, and everything else is kept byte for byte.
  awk -v wanted="$sddm_wanted" '
    /^[[:space:]]*\[Last\][[:space:]]*$/ { inlast = 1; seen = 1; print; if (!placed) { print "Session=" wanted; placed = 1 }; next }
    /^[[:space:]]*\[/ { inlast = 0; print; next }
    inlast && /^[[:space:]]*Session[[:space:]]*=/ { next }
    { print }
    END {
      if (!seen) { print ""; print "[Last]"; print "Session=" wanted }
      else if (!placed) { print "Session=" wanted }
    }
  ' "$WORK/sddm-state.original" > "$WORK/sddm-state" || return 0
  # What was written is read back before it replaces the real file: a mistake
  # here would stop the login screen from starting.
  [ "$(awk -F= '
    /^[[:space:]]*\[/ { inlast = ($0 ~ /^[[:space:]]*\[Last\][[:space:]]*$/) }
    inlast && /^[[:space:]]*Session[[:space:]]*=/ { gsub(/[[:space:]]+$/, "", $2); print $2 }
  ' "$WORK/sddm-state" | head -n 1)" = "$sddm_wanted" ] || \
    die 'could not prepare the SDDM session choice; nothing was changed'
  sddm_mode=644
  sddm_owner=$(as_root stat -c %u:%g "$sddm_state" 2>/dev/null || :)
  as_root cp -p "$sddm_state" "$sddm_state.nirux-backup" 2>/dev/null || :
  as_root install -m "$sddm_mode" "$WORK/sddm-state" "$sddm_state" || return 0
  [ -z "$sddm_owner" ] || as_root chown "$sddm_owner" "$sddm_state" 2>/dev/null || :
  if [ -n "$sddm_remembered" ]; then
    say "SDDM now preselects NIRUWM (was ${sddm_remembered##*/}); every session stays in its list"
  else
    say 'SDDM now preselects NIRUWM; every session stays in its list'
  fi
}

setup_startx() {
  # Never replace a valid user's xinitrc. A legacy NIRUPI/dwm file is known to
  # point at a session that this suite no longer installs, so it is backed up
  # and replaced; an arbitrary custom xinitrc is still preserved.
  legacy=0
  if [ -f "$HOME/.xinitrc" ] && ! owned "$HOME/.xinitrc"; then
    if grep -Eqi 'nirupi|dwm-session|dwm-status|exec[^#]*/dwm' "$HOME/.xinitrc"; then
      legacy=1
    fi
  fi
  if { [ ! -e "$HOME/.xinitrc" ] && [ ! -L "$HOME/.xinitrc" ]; } ||
     { [ -f "$HOME/.xinitrc" ] && owned "$HOME/.xinitrc"; } ||
     [ "$legacy" = 1 ]; then
    if [ "$legacy" = 1 ]; then
      [ -e "$HOME/.xinitrc.nirux-backup" ] || cp -p "$HOME/.xinitrc" "$HOME/.xinitrc.nirux-backup"
      say "Replaced legacy NIRUPI/dwm ~/.xinitrc; backup: $HOME/.xinitrc.nirux-backup"
    fi
    { say '#!/bin/sh'; say "# NIRUX owner: $PREFIX"; say "exec \"$BIN/niruwm-session\""; } > "$WORK/xinitrc"
    install -m 755 "$WORK/xinitrc" "$HOME/.xinitrc"
  fi
  say "From a local TTY: startx $BIN/niruwm-session"
  say "If ~/.xinitrc selects NIRU, plain startx works too. Existing custom ~/.xinitrc files are preserved."
}

# Start a selected display manager only after the session entry and the active
# generation exist. Package installation must never start it early.
start_selected_dm() {
  [ "$operation" = install ] || return 0
  case "$DM" in sddm|lightdm|nirulogin) ;; *) return 0 ;; esac
  dm_service=$DM
  [ "$DM" = nirulogin ] && dm_service=greetd
  if [ "$OS" = void ]; then
    # Linking into runsvdir starts the service immediately, unlike systemctl
    # enable. Do this after activate, never while the generation is staged.
    [ -d "$ROOT/etc/sv/$dm_service" ] || die "missing runit service for $dm_service"
    [ -e "$ROOT/var/service/$dm_service" ] || [ -L "$ROOT/var/service/$dm_service" ] ||
      as_root ln -s "/etc/sv/$dm_service" "$ROOT/var/service/$dm_service"
    return 0
  fi
  case "$OS" in arch|debian) ;; *) return 0 ;; esac
  dm_unit=$dm_service.service
  [ "$DM" = nirulogin ] && dm_unit=greetd.service
  if ! as_root systemctl is-active --quiet "$dm_unit" 2>/dev/null; then
    as_root systemctl start "$dm_unit" >/dev/null 2>&1 ||
      say "Could not start $DM; reboot to use it"
  fi
}

