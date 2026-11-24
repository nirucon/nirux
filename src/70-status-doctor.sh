enable_services() {
  if [ "$OS" = void ]; then
    install_void_elogind_activation
    for service in dbus elogind; do
      if [ -d "$ROOT/etc/sv/$service" ] && [ ! -e "$ROOT/var/service/$service" ] && [ ! -L "$ROOT/var/service/$service" ]; then
        as_root ln -s "/etc/sv/$service" "$ROOT/var/service/$service"
      fi
    done
    for service in bluetoothd power-profiles-daemon udisks2; do
      if [ "$service" = power-profiles-daemon ] && tlp_in_use; then continue; fi
      if [ -d "$ROOT/etc/sv/$service" ] && [ ! -e "$ROOT/var/service/$service" ] && [ ! -L "$ROOT/var/service/$service" ]; then
        as_root ln -s "/etc/sv/$service" "$ROOT/var/service/$service"
      fi
    done
  else
    case "$DM" in sddm|lightdm) as_root systemctl enable "$DM.service" ;; nirulogin) as_root systemctl enable greetd.service ;; esac
    for service in bluetooth.service power-profiles-daemon.service udisks2.service; do
      if [ "$service" = power-profiles-daemon.service ] && tlp_in_use; then continue; fi
      if [ -f "$ROOT/usr/lib/systemd/system/$service" ] ||
         [ -f "$ROOT/lib/systemd/system/$service" ]; then
        as_root systemctl enable "$service" >/dev/null 2>&1 || :
        as_root systemctl start "$service" >/dev/null 2>&1 || :
      fi
    done
  fi
  ensure_video_group
  install_backlight_rule
  ensure_passwd_keyring_pam
}
check_pam() {
  [ -f "$ROOT/etc/pam.d/nirulock" ] || { say 'missing PAM service'; return 1; }
  [ "$(stat -c %a "$ROOT/etc/pam.d/nirulock")" = 644 ] || { say 'incorrect PAM permissions'; return 1; }
  awk '$1 == "auth" {found=1} END {exit !found}' "$ROOT/etc/pam.d/nirulock" || { say 'PAM service has no authentication rules'; return 1; }
  for include in $(awk '$2 == "include" || $2 == "substack" {print $3}' "$ROOT/etc/pam.d/nirulock"); do
    [ -f "$ROOT/etc/pam.d/$include" ] || { say "missing PAM include: $include"; return 1; }
  done
}
browser_status() {
  policy=$(browser_policy)
  case "$policy" in
    none)
      say 'managed browser: Helium disabled by persistent opt-out'
      return 0
      ;;
    helium)
      browser=$(browser_path || :)
      if [ -z "$browser" ] || [ ! -x "$browser" ]; then
        say 'missing managed browser helium'
        return 1
      fi
      browser_version=$("$browser" --version 2>&1) || {
        say "broken managed browser helium: $browser_version"
        return 1
      }
      say "installed managed browser $browser_version"
      if browser_managed; then
        desktop=$(browser_desktop_file)
        if [ -f "$desktop" ] && grep -qF "Exec=$(browser_desktop_exec)" "$desktop"; then
          say 'installed Helium desktop entry'
        else
          say 'missing or different Helium desktop entry'
          return 1
        fi
      fi
      return 0
      ;;
  esac
  return 0
}
status() {
  result=0
  say "NIRUX $VERSION ($PREFIX)"
  for program in $PROGRAMS; do
    if [ ! -x "$BIN/$program" ]; then say "missing $program"; result=1; continue; fi
    case "$program" in
      niructl|niruwm-session) say "installed $program" ;;
      *)
        if version_text=$("$BIN/$program" --version 2>&1); then say "installed $version_text"
        else say "broken $program: $version_text"; result=1
        fi ;;
    esac
  done
  if [ -f "$ROOT/usr/share/xsessions/niruwm.desktop" ] && grep -qF "$BIN/niruwm-session" "$ROOT/usr/share/xsessions/niruwm.desktop"; then
    say 'installed display-manager session'
  else say 'missing or different display-manager session'; result=1
  fi
  if check_pam; then say 'PAM includes and permissions OK (password authentication not exercised)'; else result=1; fi
  if [ -f "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules" ] &&
     owned "$ROOT/etc/polkit-1/rules.d/49-nirux-power.rules"; then
    say 'installed local power polkit rule'
  elif [ -d "$ROOT/etc/polkit-1/rules.d" ] && [ ! -x "$ROOT/etc/polkit-1/rules.d" ]; then
    # Newer polkit keeps rules.d 0750 root:polkitd: an account cannot look
    # inside, so the rule can only be checked with sudo (nirux status as root).
    say 'local power polkit rule: not checked (rules.d is readable by root only)'
  else say 'missing local power polkit rule'; result=1; fi
  browser_status || result=1
  apps_status
  pending_status
  if [ -f "$EXTRAS_SELECTED" ] && [ -s "$EXTRAS_SELECTED" ]; then
    say "extras selected: $(tr '\n' ' ' < "$EXTRAS_SELECTED")"
  fi
  if [ -L "$STATE/current" ]; then say "generation: $(readlink "$STATE/current")"; fi
  if manual_path=$(manual_dir 2>/dev/null); then say "manual: $manual_path (nirux manual)"; fi
  # Installed and running can differ after an update. Report it without
  # treating a normal "log out to activate" state as a damaged installation.
  current_wm=$(readlink -f "$BIN/niruwm" 2>/dev/null || :)
  running_wm=
  for pid in $(pgrep -u "$(id -u)" -x niruwm 2>/dev/null || :); do
    candidate=$(readlink -f "/proc/$pid/exe" 2>/dev/null || :)
    if [ -n "$candidate" ]; then
      running_wm=$candidate
      break
    fi
  done
  if [ -n "$running_wm" ] && ! component_matches_running "$running_wm" "$current_wm"; then
    running_wm_status "$running_wm"
  elif [ -n "$running_wm" ]; then
    say "running WM: current binary"
  fi
  stale_bar=0
  current_bar=$(readlink -f "$BIN/nirubar" 2>/dev/null || :)
  for pid in $(pgrep -u "$(id -u)" -x nirubar 2>/dev/null || :); do
    running_bar=$(readlink -f "/proc/$pid/exe" 2>/dev/null || :)
    if [ -n "$running_bar" ] && ! component_matches_running "$running_bar" "$current_bar"; then
      stale_bar=1
    fi
  done
  if [ "$stale_bar" = 1 ]; then
    say "running bar: old generation; run niructl restart-bar"
  fi
  return "$result"
}
# The programs the user actually selected in the shared configuration.
configured_commands() {
  [ -x "$BIN/niruwm" ] || return 0
  "$BIN/niruwm" --dump-config 2>/dev/null | awk '
    /^(terminal|browser|launcher) = / {
      line = $0
      sub(/^[^=]*= */, "", line)
      gsub(/[]["]/, "", line)
      split(line, items, ",")
      split(items[1], words, " ")
      if (words[1] != "") print words[1]
    }
  ' | sort -u
}

# Problems doctor can repair itself, as space-separated ids in the order found.
DOCTOR_FIXES=
doctor_offer() {
  case " $DOCTOR_FIXES " in *" $1 "*) return 0 ;; esac
  DOCTOR_FIXES="${DOCTOR_FIXES:+$DOCTOR_FIXES }$1"
}
doctor_fix_text() {
  case "$1" in
    packages) say "install the missing NIRUX packages: $(required_missing_packages | tr '\n' ' ' | sed 's/ $//') (sudo)" ;;
    backlight) say 'install the NIRUX backlight rule and add you to the video group (sudo; the group applies at the next login)' ;;
    battery) say 'install the NIRUX battery rule so the charge limit can be set (sudo)' ;;
    bar) say 'restart NIRUBAR' ;;
    notify) say 'start NIRUNOTIFY for this session' ;;
    idle) say 'start niruidle (screen saver, idle lock) for this session' ;;
    nightlight) say 'start the night-light schedule for this session' ;;
    audio) say 'restart PipeWire and WirePlumber (user services)' ;;
    niruio) say 'apply the NIRUIO sound fixes: unmute, reset remembered mutes, ports and profiles (niruio doctor --fix)' ;;
    hwvideo) say 'install the hardware video packages and turn on hardware video decoding in Helium (sudo)' ;;
    widevine) say 'download the Widevine module from Google so Netflix and other protected video play in Helium' ;;
  esac
}
# Start a session helper detached from this shell, as the session would.
doctor_spawn() {
  if command -v setsid >/dev/null 2>&1; then
    setsid -f "$@" >/dev/null 2>&1 </dev/null
  else
    ("$@" >/dev/null 2>&1 </dev/null &)
  fi
}
doctor_fix_one() {
  case "$1" in
    packages) provision_packages missing ;;
    backlight) ensure_video_group; install_backlight_rule ;;
    battery) install_battery_rule ;;
    bar) "$BIN/niructl" restart-bar ;;
    notify) doctor_spawn "$BIN/nirunotify" ;;
    idle) doctor_spawn "$BIN/niruidle" ;;
    nightlight) doctor_spawn "$BIN/niructl" nightlight watch ;;
    audio) systemctl --user restart pipewire pipewire-pulse wireplumber ;;
    niruio) "$BIN/niruio" doctor --fix ;;
    hwvideo) OS=$(distro) && packages=1 && hwvideo_apply && [ -s "$STATE/helium-flags" ] ;;
    widevine) widevine_command on ;;
    *) return 1 ;;
  esac
}
doctor_apply_fixes() {
  if [ -z "$DOCTOR_FIXES" ]; then
    say 'Nothing for doctor --fix to repair.'
    return 0
  fi
  say ''
  say 'doctor --fix will:'
  for fix_id in $DOCTOR_FIXES; do say "  - $(doctor_fix_text "$fix_id")"; done
  if [ "$DOCTOR_YES" != 1 ]; then
    if [ ! -t 0 ]; then die 'doctor --fix needs a terminal to confirm, or --yes'; fi
    printf 'Apply these fixes? [y/N] '
    read -r fix_answer || fix_answer=
    case "$fix_answer" in y|Y|yes|YES|j|J|ja|JA) ;; *) say 'No changes made.'; return 1 ;; esac
  fi
  fix_failed=0
  for fix_id in $DOCTOR_FIXES; do
    if doctor_fix_one "$fix_id"; then
      say "fixed: $(doctor_fix_text "$fix_id")"
    else
      say "could not fix: $(doctor_fix_text "$fix_id")"
      fix_failed=1
    fi
  done
  say 'Run nirux doctor again to check the result.'
  return "$fix_failed"
}

doctor() {
  DOCTOR_FIX=0
  DOCTOR_YES=0
  for doctor_arg in "$@"; do
    case "$doctor_arg" in
      --fix) DOCTOR_FIX=1 ;;
      --yes|-y) DOCTOR_YES=1 ;;
      *) die "unknown doctor option: $doctor_arg (use --fix [--yes])" ;;
    esac
  done
  [ "$DOCTOR_FIX" = 1 ] || [ "$DOCTOR_YES" = 0 ] || die 'doctor --yes needs --fix'
  # Rules and packages are written through the same helpers as an install.
  [ "$DOCTOR_FIX" = 0 ] || lock
  DOCTOR_FIXES=
  result=0
  status || result=1
  say "selected prefix: $PREFIX"
  case ":$PATH:" in
    *":$BIN:"*) say "PATH includes selected prefix" ;;
    *) say "PATH does not include selected prefix (the session prepends it)" ;;
  esac
  for tool in startx Xorg xauth dbus-run-session fc-match fish brightnessctl gammastep notify-send; do
    if command -v "$tool" >/dev/null 2>&1; then say "available $tool"; else say "missing $tool"; result=1; fi
  done
  # The release's own package list, on a distribution NIRUX supports.
  if OS=$( (distro) 2>/dev/null ) && [ -n "$OS" ]; then
    doctor_missing=$(required_missing_packages | tr '\n' ' ' | sed 's/ $//')
    if [ -n "$doctor_missing" ]; then
      say "missing packages: $doctor_missing"
      result=1
      doctor_offer packages
    else
      say 'all NIRUX packages installed'
    fi
  fi
  # The login unlocks the keyring. A keyring installed during this session
  # (as by an update) starts at the next login, so only a note.
  if [ -n "${DISPLAY:-}" ] && command -v gnome-keyring-daemon >/dev/null 2>&1; then
    if pgrep -u "$(id -u)" -x gnome-keyring-d >/dev/null 2>&1; then
      say 'keyring running (apps keep their saved logins)'
    else
      say 'keyring not running yet: log out and in once, then apps such as Nextcloud keep their logins'
    fi
  fi
  if [ -d /sys/class/backlight ] && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
    if command -v brightnessctl >/dev/null 2>&1 && brightnessctl -m >/dev/null 2>&1; then
      say 'backlight readable through brightnessctl'
    else
      say 'backlight present but brightnessctl cannot read it (check udev/group permissions)'
      result=1
      doctor_offer backlight
    fi
  else say 'no backlight device (desktop or external display)'
  fi
  for tool in $(configured_commands); do
    if command -v "$tool" >/dev/null 2>&1 || [ -x "$BIN/$tool" ]; then
      say "available configured $tool"
    else
      say "missing configured $tool (selected in config.toml)"
      result=1
    fi
  done
  for tool in dunst picom feh maim slop xclip playerctl wpctl amixer bluetoothctl powerprofilesctl; do
    if command -v "$tool" >/dev/null 2>&1; then say "available optional $tool"; else say "missing optional $tool"; fi
  done
  if [ -n "${DISPLAY:-}" ] && command -v wpctl >/dev/null 2>&1; then
    if wpctl status 2>/dev/null | awk '/Sinks:/{inside=1;next} /Sources:/{inside=0} inside && /\*/{found=1} END{exit !found}'; then
      say 'audio default sink available'
    else
      say 'no default audio sink (PipeWire/WirePlumber)'; result=1
      # Only where PipeWire runs as systemd user services; elsewhere the
      # session starts it and a new login is the repair.
      if command -v systemctl >/dev/null 2>&1 && systemctl --user cat wireplumber.service >/dev/null 2>&1; then
        doctor_offer audio
      fi
    fi
  fi
  # NIRUIO follows the sound from the program to the device. Its most common
  # find is a media role WirePlumber remembers as muted (mpv tags the sound of
  # every video as "Movie"), which silences a whole kind of program. Only
  # where this user's PipeWire runs: without it (a container, a fresh SSH
  # login before the desktop) the check above already covers the session.
  if [ -x "$BIN/niruio" ] && [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pipewire-0" ]; then
    niruio_rc=0
    niruio_out=$("$BIN/niruio" doctor --brief 2>/dev/null) || niruio_rc=$?
    if [ -n "$niruio_out" ]; then
      printf '%s\n' "$niruio_out" | sed 's/^/sound: /'
      if printf '%s\n' "$niruio_out" | grep -q ' (fix: '; then doctor_offer niruio; fi
      [ "$niruio_rc" = 0 ] || result=1
    else
      say 'sound: niruio doctor found nothing to report'
    fi
  fi
  bluez_spa=
  for candidate in /usr/lib/spa-0.2/bluez5/libspa-bluez5.so /usr/lib64/spa-0.2/bluez5/libspa-bluez5.so /usr/lib/x86_64-linux-gnu/spa-0.2/bluez5/libspa-bluez5.so; do
    [ -f "$candidate" ] && bluez_spa="$candidate" && break
  done
  if [ -n "$bluez_spa" ]; then say "Bluetooth BlueZ SPA available ($bluez_spa)"; else say 'Bluetooth BlueZ SPA missing; install the distribution PipeWire BlueZ package'; result=1; fi
  hwvideo_doctor
  widevine_doctor
  for tool in ffmpeg slop maim; do
    if command -v "$tool" >/dev/null 2>&1; then say "capture dependency available: $tool"; else say "capture dependency missing: $tool"; result=1; fi
  done
  if command -v ffmpeg >/dev/null 2>&1 && ffmpeg -hide_banner -devices 2>/dev/null | grep -q x11grab; then say 'capture x11grab available'; else say 'capture x11grab missing'; result=1; fi
  if ls /dev/video* >/dev/null 2>&1; then say 'capture camera device available'; else say 'capture camera device missing'; fi
  for pair in 'niruwm --check-config' 'nirubar --check-config' 'niruidle --config' 'niruscreensaver --config' 'nirulock --config' 'nirulauncher --check-config' 'nirunotify --check-config'; do
    set -- $pair
    say "== $pair"
    if [ -x "$BIN/$1" ]; then "$BIN/$1" "$2" || result=1; else result=1; fi
  done
  if [ -n "${DISPLAY:-}" ]; then
    say '== live X session'
    # Session helpers are offered only for a session that runs and answers.
    doctor_live=0
    if "$BIN/niructl" status; then
      pgrep -u "$(id -u)" -x niruwm >/dev/null && doctor_live=1
    else
      result=1
    fi
    for program in niruwm nirubar; do
      if pgrep -u "$(id -u)" -x "$program" >/dev/null; then say "running $program"; else say "not running $program"; result=1; fi
    done
    if [ "$doctor_live" = 1 ] && ! pgrep -u "$(id -u)" -x nirubar >/dev/null; then doctor_offer bar; fi
    if command -v xprop >/dev/null 2>&1; then
      wm_id=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | sed -n 's/.*# //p')
      if [ -n "$wm_id" ]; then
        wm_name=$(xprop -id "$wm_id" _NET_WM_NAME 2>/dev/null | sed -n 's/.*= //p')
        say "X WM owner $wm_id ${wm_name:-}"
      else
        say "no X window manager owns _NET_SUPPORTING_WM_CHECK"; result=1
      fi
    fi
    if command -v xwininfo >/dev/null 2>&1; then
      bars=$(xwininfo -root -tree 2>/dev/null | grep -c 'NIRUBAR' || true)
      layouts=$(xprop -root _NIRUWM_MONITORS 2>/dev/null | grep -o '\\n' | wc -l | tr -d ' ')
      say "bar windows: $bars; monitor layouts published: $layouts"
      if [ "$bars" != "$layouts" ]; then say 'bar ownership does not match the published monitors'; result=1; [ "$doctor_live" = 0 ] || doctor_offer bar; fi
    fi
    if command -v dbus-send >/dev/null 2>&1; then
      owner=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetNameOwner string:org.freedesktop.Notifications 2>/dev/null | sed -n 's/.*string "\(.*\)"/\1/p' | head -n1)
      if [ -n "$owner" ]; then say "notifications owned by $owner"
      else
        say 'no notification daemon owns the session bus'
        [ "$doctor_live" = 0 ] || [ ! -x "$BIN/nirunotify" ] || doctor_offer notify
      fi
    fi
    # A schedule (gradual, solar or fixed) needs its watcher. NIRUWM 0.30 also
    # runs it, idle, in manual so a switch to a schedule needs no new login.
    doctor_nl_mode=$("$BIN/niructl" nightlight status 2>/dev/null | sed -n 's/^mode: //p' | head -n1)
    case "${doctor_nl_mode:-manual}" in
      manual) say 'night light: manual (Super+N)' ;;
      *)
        if doctor_watcher_running 'nightlight watch'; then
          say "night light: $doctor_nl_mode schedule running"
        else
          say "night light: $doctor_nl_mode schedule set but its watcher is not running"
          result=1
          [ "$doctor_live" = 0 ] || doctor_offer nightlight
        fi ;;
    esac
    if pgrep -u "$(id -u)" -x niruidle >/dev/null; then say 'idle provider niruidle is running'
    else
      say 'idle provider niruidle is not running'
      if [ "$doctor_live" = 1 ] && [ -x "$BIN/niruidle" ] && ! pgrep -u "$(id -u)" -x nirulock >/dev/null; then doctor_offer idle; fi
    fi
    if ls -d /sys/class/power_supply/BAT* >/dev/null 2>&1 && command -v niructl >/dev/null 2>&1; then
      niructl battery status 2>&1 | sed 's/^/battery: /'
    fi
  else say 'Live session check skipped: DISPLAY is unset (normal over SSH/TTY).'
  fi
  # A charge limit the hardware supports but this user cannot write.
  if has_battery_limit && ! doctor_battery_writable; then
    say 'battery: the charge limit is supported but not writable for you (udev rule missing)'
    result=1
    doctor_offer battery
  fi
  if [ "$DOCTOR_FIX" = 1 ]; then
    doctor_apply_fixes || result=1
  elif [ -n "$DOCTOR_FIXES" ]; then
    say ''
    say 'nirux doctor --fix can repair:'
    for fix_id in $DOCTOR_FIXES; do say "  - $(doctor_fix_text "$fix_id")"; done
  fi
  return "$result"
}
