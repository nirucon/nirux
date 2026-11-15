ensure_user_dirs() {
  # Use the user's existing XDG choices. On a fresh home, let xdg-user-dirs
  # create the locale-appropriate standard folders; never invent English aliases.
  [ -z "$ROOT" ] || return 0
  [ "${NIRUX_TEST_AS_ROOT:-0}" = 1 ] && return 0
  [ "$(id -u)" = 0 ] && return 0
  command -v xdg-user-dirs-update >/dev/null 2>&1 || return 0
  config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  if [ ! -f "$config_home/user-dirs.dirs" ]; then
    xdg-user-dirs-update >/dev/null 2>&1 || {
      say 'xdg-user-dirs-update failed; standard folders were not created'
      return 0
    }
  fi
  for role in DESKTOP DOCUMENTS DOWNLOAD MUSIC PICTURES VIDEOS; do
    dir=$(xdg-user-dir "$role" 2>/dev/null || :)
    [ -n "$dir" ] && [ "$dir" != "$HOME" ] || continue
    case "$role" in DESKTOP|TEMPLATES|PUBLICSHARE) continue ;; esac
    [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null || say "Could not create $dir"
  done
  # The NIRU desktop does not use a desktop folder, templates or a public
  # share by default. Disable those only when they are still the XDG defaults;
  # a custom path or a non-empty directory is left alone.
  for role in DESKTOP TEMPLATES PUBLICSHARE; do
    dir=$(xdg-user-dir "$role" 2>/dev/null || :)
    [ -n "$dir" ] && [ "$dir" != "$HOME" ] || continue
    case "$role:$dir" in
      DESKTOP:"$HOME/Desktop"|TEMPLATES:"$HOME/Templates"|PUBLICSHARE:"$HOME/Public") ;;
      *) continue ;;
    esac
    if xdg-user-dirs-update --set "$role" "$HOME" >/dev/null 2>&1; then
      if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null || :)" ]; then
        rmdir "$dir" 2>/dev/null || :
      fi
      say "Disabled unused XDG $role folder (set to \$HOME)."
    fi
  done
}

install_backlight_rule() {
  rule=$ROOT/etc/udev/rules.d/70-nirux-backlight.rules
  { say "# NIRUX owner: $PREFIX"; say 'SUBSYSTEM=="backlight", ACTION=="add|change", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod 0660 /sys/class/backlight/%k/brightness"'; } > "$WORK/backlight.rules"
  write_system "$rule" "$WORK/backlight.rules"
  as_root udevadm control --reload-rules >/dev/null 2>&1 || :
  as_root udevadm trigger --subsystem-match=backlight --action=change >/dev/null 2>&1 || :
}

ensure_video_group() {
  # brightnessctl's udev rule grants the video group write access to the
  # backlight. The install user already has sudo, so this does not add a new
  # privilege boundary. Never touch host groups in isolated tests or chroots.
  [ -z "$ROOT" ] || return 0
  [ "${NIRUX_TEST_AS_ROOT:-0}" = 1 ] && return 0
  getent group video >/dev/null 2>&1 || return 0
  command -v usermod >/dev/null 2>&1 || return 0
  target_user=${SUDO_USER:-$(id -un)}
  [ -n "$target_user" ] && [ "$target_user" != root ] || return 0
  if id -nG "$target_user" 2>/dev/null | tr ' ' '\n' | grep -qx video; then return 0; fi
  as_root usermod -aG video "$target_user" || return 0
  as_root udevadm trigger --subsystem-match=backlight --action=change >/dev/null 2>&1 || :
  say "Added $target_user to the video group for brightness; log out/in to activate it."
}

# On Void, elogind runs as a runit service, but the package also lets D-Bus
# start it on demand. At boot the greeter's PAM session asks for logind
# before runit has started elogind, D-Bus starts its own copy, and the runit
# service then fails and is restarted every second for as long as the
# machine runs. NIRUX installs a D-Bus activation file that takes precedence
# over the package's (/usr/local/share comes first) and asks runit to start
# the supervised service instead. Nothing running is restarted.
ELOGIND_ACTIVATE=/usr/libexec/nirux-elogind-activate
install_void_elogind_activation() {
  [ "$OS" = void ] || return 0
  [ -d "$ROOT/etc/sv/elogind" ] || return 0
  {
    say '#!/bin/sh'
    say "# NIRUX owner: $PREFIX"
    say '# D-Bus activation of org.freedesktop.login1: start the runit service,'
    say '# which then owns the name, rather than an unsupervised second elogind.'
    say 'if [ -e /var/service/elogind ]; then'
    say '  i=0'
    say '  while [ "$i" -lt 20 ]; do'
    say '    /usr/bin/sv start elogind >/dev/null 2>&1 && exit 0'
    say '    i=$((i + 1)); sleep 0.5'
    say '  done'
    say 'fi'
    say 'exec /usr/libexec/elogind/elogind --daemon'
  } > "$WORK/elogind-activate"
  write_system "$ROOT$ELOGIND_ACTIVATE" "$WORK/elogind-activate"
  as_root chmod 0755 "$ROOT$ELOGIND_ACTIVATE"
  {
    say "# NIRUX owner: $PREFIX"
    say '[D-BUS Service]'
    say 'Name=org.freedesktop.login1'
    say "Exec=$ELOGIND_ACTIVATE"
    say 'User=root'
  } > "$WORK/login1-service"
  write_system "$ROOT/usr/local/share/dbus-1/system-services/org.freedesktop.login1.service" "$WORK/login1-service"
}

remove_void_elogind_activation() {
  remove_system "$ROOT/usr/local/share/dbus-1/system-services/org.freedesktop.login1.service"
  remove_system "$ROOT$ELOGIND_ACTIVATE"
}

# Touchpads: tap with one finger to click, two to right-click and three for
# the middle button, scrolling with two fingers, on the login screen too.
# Only on machines with a touchpad; `niructl input` changes it per user.
TOUCHPAD_RULE=/etc/X11/xorg.conf.d/30-nirux-touchpad.conf
has_touchpad() {
  [ -n "${NIRUX_TEST_TOUCHPAD:-}" ] && { [ "$NIRUX_TEST_TOUCHPAD" = 1 ]; return; }
  grep -qiE '^N: Name=.*(touchpad|trackpad|clickpad)' /proc/bus/input/devices 2>/dev/null
}
install_touchpad_rule() {
  if ! has_touchpad; then
    remove_system "$ROOT$TOUCHPAD_RULE"
    return 0
  fi
  {
    say "# NIRUX owner: $PREFIX"
    say '# Tap to click (one finger left, two right, three middle), tap and drag,'
    say '# two-finger scrolling, and no taps while typing. Per user: niructl input.'
    say 'Section "InputClass"'
    say '    Identifier "NIRUX touchpad"'
    say '    MatchIsTouchpad "on"'
    say '    Driver "libinput"'
    say '    Option "Tapping" "on"'
    say '    Option "TappingButtonMap" "lrm"'
    say '    Option "TappingDrag" "on"'
    say '    Option "ScrollMethod" "twofinger"'
    say '    Option "DisableWhileTyping" "on"'
    say 'EndSection'
  } > "$WORK/touchpad.conf"
  as_root mkdir -p "$ROOT/etc/X11/xorg.conf.d"
  write_system "$ROOT$TOUCHPAD_RULE" "$WORK/touchpad.conf"
  as_root chmod 0644 "$ROOT$TOUCHPAD_RULE" || :
}

# Void: runit hands udevd over from the early boot to its supervised service.
# A device that appears in that gap, typically a sound card whose firmware
# loads late (Intel SOF), misses its udev rules and stays root-only, and
# PipeWire then only offers "Dummy Output". This service replays the sound,
# graphics and input events once udevd runs, then waits idle.
# Battery charge limit (default 80 %, [battery] charge_limit). The kernel
# exposes it as charge_control_end_threshold on laptops whose firmware
# supports it (ThinkPad, Framework, many Dell, ASUS and Lenovo; many HP
# models do not). This rule lets the user's primary group write it, so
# `niructl battery` sets it at every login without root.
BATTERY_RULE=/etc/udev/rules.d/90-nirux-battery.rules
has_battery_limit() {
  [ -n "${NIRUX_TEST_BATTERY:-}" ] && { [ "$NIRUX_TEST_BATTERY" = 1 ]; return; }
  for bat in /sys/class/power_supply/BAT*; do
    [ -e "$bat/charge_control_end_threshold" ] && return 0
  done
  return 1
}
# Whether every charge threshold file is writable for this user.
doctor_battery_writable() {
  [ -n "${NIRUX_TEST_BATTERY_WRITABLE:-}" ] && { [ "$NIRUX_TEST_BATTERY_WRITABLE" = 1 ]; return; }
  for bat in /sys/class/power_supply/BAT*; do
    [ ! -e "$bat/charge_control_end_threshold" ] || [ -w "$bat/charge_control_end_threshold" ] || return 1
  done
  return 0
}
# Whether a niructl watcher (e.g. "nightlight watch") runs on this display.
doctor_watcher_running() {
  for dw_pid in $(pgrep -u "$(id -u)" -x niructl 2>/dev/null); do
    dw_cmd=$(tr '\0' ' ' < "/proc/$dw_pid/cmdline" 2>/dev/null)
    case "$dw_cmd" in *"$1"*) ;; *) continue ;; esac
    dw_display=$(tr '\0' '\n' < "/proc/$dw_pid/environ" 2>/dev/null | sed -n 's/^DISPLAY=//p')
    [ -z "${DISPLAY:-}" ] || [ "$dw_display" = "$DISPLAY" ] || continue
    return 0
  done
  return 1
}
install_battery_rule() {
  if ! has_battery_limit; then
    remove_system "$ROOT$BATTERY_RULE"
    return 0
  fi
  battery_gid=$(id -g)
  {
    say "# NIRUX owner: $PREFIX"
    say '# Let the NIRUX user set the battery charge limit (niructl battery).'
    say "ACTION==\"add|change\", SUBSYSTEM==\"power_supply\", KERNEL==\"BAT*\", TEST==\"charge_control_end_threshold\", RUN+=\"/bin/sh -c 'for f in /sys%p/charge_control_end_threshold /sys%p/charge_control_start_threshold; do [ -e \$\$f ] && chgrp $battery_gid \$\$f && chmod g+w \$\$f; done; true'\""
  } > "$WORK/battery.rules"
  as_root mkdir -p "$ROOT/etc/udev/rules.d"
  write_system "$ROOT$BATTERY_RULE" "$WORK/battery.rules"
  as_root chmod 0644 "$ROOT$BATTERY_RULE" || :
  [ -z "$ROOT" ] && [ -z "${NIRUX_TEST_BATTERY:-}" ] || return 0
  as_root udevadm control --reload >/dev/null 2>&1 || :
  as_root udevadm trigger --action=change --subsystem-match=power_supply >/dev/null 2>&1 || :
  as_root udevadm settle --timeout=5 >/dev/null 2>&1 || :
  if [ -x "$PREFIX/bin/niructl" ]; then "$PREFIX/bin/niructl" battery apply >/dev/null 2>&1 || :; fi
}

UDEV_REPLAY_SV=/etc/sv/nirux-udev-replay
install_void_udev_replay() {
  [ "$OS" = void ] || return 0
  [ -d "$ROOT/etc/sv/udevd" ] || [ -n "${NIRUX_TEST_UDEV_REPLAY:-}" ] || return 0
  {
    say '#!/bin/sh'
    say "# NIRUX owner: $PREFIX"
    say '# Replay events of devices that appeared while udevd was handed over.'
    say 'sv check udevd >/dev/null 2>&1 || exit 1'
    say 'udevadm trigger --action=change --subsystem-match=sound --subsystem-match=drm --subsystem-match=input'
    say 'udevadm settle --timeout=10'
    say 'exec pause'
  } > "$WORK/udev-replay-run"
  as_root mkdir -p "$ROOT$UDEV_REPLAY_SV"
  write_system "$ROOT$UDEV_REPLAY_SV/run" "$WORK/udev-replay-run"
  as_root chmod 0755 "$ROOT$UDEV_REPLAY_SV/run"
  if [ ! -e "$ROOT/var/service/nirux-udev-replay" ] && [ ! -L "$ROOT/var/service/nirux-udev-replay" ]; then
    as_root mkdir -p "$ROOT/var/service"
    as_root ln -s "$UDEV_REPLAY_SV" "$ROOT/var/service/nirux-udev-replay" || :
  fi
}
remove_void_udev_replay() {
  if [ -L "$ROOT/var/service/nirux-udev-replay" ]; then as_root rm -f "$ROOT/var/service/nirux-udev-replay"; fi
  remove_system "$ROOT$UDEV_REPLAY_SV/run"
  as_root rmdir "$ROOT$UDEV_REPLAY_SV" 2>/dev/null || :
}

# Tailscale: install, start and log in, when chosen (choose_tailscale). Never
# in test roots. The login link is shown only on a terminal; without one, or
# when skipped, `sudo tailscale up` does it later.
tailscale_setup() {
  [ "$TAILSCALE_EFFECTIVE" = yes ] || return 0
  [ -z "$ROOT" ] || return 0
  [ "${NIRUX_TEST_AS_ROOT:-0}" = 1 ] && return 0
  if ! command -v tailscale >/dev/null 2>&1; then
    say 'Installing Tailscale...'
    case "$OS" in
      void) as_root xbps-install -Sy tailscale ;;
      arch) as_root pacman -S --needed --noconfirm tailscale ;;
      debian)
        codename=$(. /etc/os-release; printf '%s' "${VERSION_CODENAME:-trixie}")
        curl -fsSL "https://pkgs.tailscale.com/stable/debian/$codename.noarmor.gpg" -o "$WORK/tailscale.gpg" &&
          curl -fsSL "https://pkgs.tailscale.com/stable/debian/$codename.tailscale-keyring.list" -o "$WORK/tailscale.list" ||
          { say 'Tailscale: could not reach pkgs.tailscale.com; skipped (nirux update --tailscale yes tries again).'; return 0; }
        as_root install -m 0644 "$WORK/tailscale.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
        as_root install -m 0644 "$WORK/tailscale.list" /etc/apt/sources.list.d/tailscale.list
        as_root apt-get update -q >/dev/null &&
          as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -q tailscale
        ;;
    esac || { say 'Tailscale: the package could not be installed; skipped.'; return 0; }
  fi
  case "$OS" in
    void)
      if [ ! -e /var/service/tailscaled ] && [ ! -L /var/service/tailscaled ]; then
        as_root ln -s /etc/sv/tailscaled /var/service/tailscaled
      fi
      i=0; while [ "$i" -lt 20 ] && ! tailscale status >/dev/null 2>&1 && ! tailscale status 2>&1 | grep -q 'Logged out'; do i=$((i + 1)); sleep 0.5; done
      ;;
    *) as_root systemctl enable --now tailscaled.service >/dev/null 2>&1 || : ;;
  esac
  ts_user=${rule_user:-${SUDO_USER:-$(id -un)}}
  if tailscale status >/dev/null 2>&1; then
    as_root tailscale set --operator="$ts_user" >/dev/null 2>&1 || :
    say "Tailscale: connected as $(tailscale status --self --peers=false 2>/dev/null | awk 'NR == 1 {print $2}')."
    return 0
  fi
  if [ -t 0 ] && [ -t 1 ]; then
    say ''
    say 'Tailscale: open the link below on any device to add this computer to'
    say 'your network. It waits up to 5 minutes; Ctrl+C skips it (later: sudo tailscale up).'
    as_root tailscale up --operator="$ts_user" --timeout=5m || say 'Tailscale: not logged in yet; run sudo tailscale up later.'
  else
    say 'Tailscale is installed; log in with: sudo tailscale up'
  fi
}

