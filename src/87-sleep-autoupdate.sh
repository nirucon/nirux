# ── Nightly update and sleep hook installation (docs: manual chapter 11) ────
AUTOUPDATE_HELPER=/usr/libexec/nirux-autoupdate
SLEEP_HOOK_SYSTEMD=/usr/lib/systemd/system-sleep/nirux
# Void's elogind runs the hooks in /usr/libexec/elogind/system-sleep; other
# elogind builds use /usr/lib/elogind/system-sleep.
sleep_hook_dir() {
  if [ "${OS:-$(distro)}" = void ] && [ ! -d "$ROOT/run/systemd/system" ]; then
    for sh_dir in /usr/libexec/elogind/system-sleep /usr/lib/elogind/system-sleep /usr/lib64/elogind/system-sleep; do
      [ -d "$ROOT$sh_dir" ] && { say "$sh_dir"; return 0; }
    done
    for sh_dir in /usr/libexec/elogind /usr/lib/elogind; do
      [ -d "$ROOT$sh_dir" ] && { say "$sh_dir/system-sleep"; return 0; }
    done
    say /usr/libexec/elogind/system-sleep
  else
    say "${SLEEP_HOOK_SYSTEMD%/*}"
  fi
}
integration_file() { # NAME -> path of ./checkup/NAME from the release integration archive
  if_archive=$WORK/download/nirux/nirux-integration.tar.xz
  if [ -f "$if_archive" ] && [ ! -f "$WORK/checkup-integration/checkup/$1" ]; then
    mkdir -p "$WORK/checkup-integration"
    tar -xJf "$if_archive" -C "$WORK/checkup-integration" "./checkup/$1" 2>/dev/null || :
  fi
  [ -f "$WORK/checkup-integration/checkup/$1" ] || return 1
  say "$WORK/checkup-integration/checkup/$1"
}
install_sleep_hook() {
  sl_source=$(integration_file nirux-sleep) || return 0
  { say '#!/bin/sh'; say "# NIRUX owner: $PREFIX"; sed '1d' "$sl_source"; } > "$WORK/sleep-hook"
  sl_dir=$(sleep_hook_dir)
  write_system "$ROOT$sl_dir/nirux" "$WORK/sleep-hook"
  as_root chmod 0755 "$ROOT$sl_dir/nirux" || die 'could not secure the sleep hook'
}
remove_sleep_hook() {
  for sl_dir in "${SLEEP_HOOK_SYSTEMD%/*}" /usr/libexec/elogind/system-sleep /usr/lib/elogind/system-sleep /usr/lib64/elogind/system-sleep; do
    remove_system "$ROOT$sl_dir/nirux"
  done
}
# Every package name this NIRUX may install on this distribution: the runtime
# list (TLP or not), the browser libraries, the display managers, Papirus,
# Tailscale, the graphics drivers and the hardware video packages for Helium,
# with Debian's t64 library renames. The nightly update installs a package
# NIRUX asks for only when it is listed.
autoupdate_package_list() {
  {
    say curl ca-certificates tailscale
    distribution_packages_for "$1"
    browser_packages_for "$1"
    icons_packages_for "$1"
    hwvideo_packages_for "$1" all
    case "$1" in
      arch) say mesa sddm qt5-declarative lightdm lightdm-gtk-greeter greetd ;;
      debian) say libgl1-mesa-dri sddm lightdm lightdm-gtk-greeter greetd xserver-xorg-legacy libcups2 libcups2t64 libgtk-3-0 libgtk-3-0t64 libasound2 libasound2t64 ;;
      void) say mesa-dri sddm lightdm lightdm-gtk-greeter greetd ;;
    esac
  } | tr ' ' '\n' | awk -v os="$1" '
    /^[A-Za-z0-9][A-Za-z0-9+._-]*$/ { print; if (os == "debian" && $0 ~ /^lib/ && $0 !~ /t64$/) print $0 "t64" }' |
    LC_ALL=C sort -u
}
# Written only by an interactive update or install (with sudo), never by --auto.
install_autoupdate_packages() {
  [ "$NIRUX_AUTO" = 0 ] || return 0
  {
    say "# NIRUX owner: $PREFIX"
    say "# Packages the nightly update may install for NIRUX $VERSION on ${OS:-$(distro)}."
    say '# Replaced by every nirux update; do not edit.'
    autoupdate_package_list "${OS:-$(distro)}"
  } > "$WORK/autoupdate-packages"
  write_system "$ROOT/etc/nirux/autoupdate-packages" "$WORK/autoupdate-packages"
  as_root chmod 0644 "$ROOT/etc/nirux/autoupdate-packages" || die 'could not secure the nightly update package list'
}
install_autoupdate() {
  [ -n "${rule_user:-}" ] || return 0
  au_source=$(integration_file nirux-autoupdate) || return 0
  { say '#!/bin/sh'; say "# NIRUX owner: $PREFIX"; sed '1d' "$au_source"; } > "$WORK/autoupdate-helper"
  write_system "$ROOT$AUTOUPDATE_HELPER" "$WORK/autoupdate-helper"
  as_root chmod 0755 "$ROOT$AUTOUPDATE_HELPER" || die 'could not secure the autoupdate helper'
  install_autoupdate_packages
  au_conf=$ROOT/etc/nirux/autoupdate.conf
  if ! as_root test -f "$au_conf"; then
    {
      say "# NIRUX owner: $PREFIX"
      say '# NIRUX nightly update (nirux autoupdate --help). Edit with sudo, or use'
      say '# nirux autoupdate enable|disable.'
      say 'enabled=yes'
      say "user=$rule_user"
      say '# Local time; a run starts only when nobody is logged in.'
      say 'window=03:00-05:00'
      say '# discord: warnings, always or off (the webhook of nirux checkup discord set)'
      say 'discord=warnings'
    } > "$WORK/autoupdate-conf"
    write_system "$au_conf" "$WORK/autoupdate-conf"
  fi
  {
    say "# NIRUX owner: $PREFIX"
    say '# Only the root-owned nightly update helper, with fixed arguments.'
    say "$rule_user ALL=(root) NOPASSWD: $AUTOUPDATE_HELPER run-now, $AUTOUPDATE_HELPER enable, $AUTOUPDATE_HELPER disable"
  } > "$WORK/autoupdate-sudoers"
  if command -v visudo >/dev/null 2>&1; then
    visudo_out=$(visudo -cf "$WORK/autoupdate-sudoers" 2>&1) ||
      die "generated autoupdate sudoers rule is invalid; nothing was installed: $visudo_out"
  fi
  au_sudoers=$ROOT/etc/sudoers.d/zz-nirux-autoupdate
  if ! { [ -f "$au_sudoers" ] && [ "$(as_root cat "$au_sudoers" 2>/dev/null)" = "$(cat "$WORK/autoupdate-sudoers")" ]; }; then
    write_system "$au_sudoers" "$WORK/autoupdate-sudoers"
  fi
  as_root chmod 0440 "$au_sudoers" || die 'could not secure the autoupdate sudoers rule'
  if [ "${OS:-$(distro)}" = void ]; then
    {
      say '#!/bin/sh'
      say "# NIRUX owner: $PREFIX"
      say 'exec 2>&1'
      say "exec chpst -n 10 $AUTOUPDATE_HELPER loop"
    } > "$WORK/autoupdate-run"
    write_system "$ROOT/etc/sv/nirux-autoupdate/run" "$WORK/autoupdate-run"
    as_root chmod 0755 "$ROOT/etc/sv/nirux-autoupdate/run"
    [ -e "$ROOT/var/service/nirux-autoupdate" ] || [ -n "$ROOT" ] ||
      as_root ln -s /etc/sv/nirux-autoupdate "$ROOT/var/service/nirux-autoupdate"
  else
    {
      say "# NIRUX owner: $PREFIX"
      say '[Unit]'
      say 'Description=NIRUX nightly update (only when nobody is logged in)'
      say 'After=network-online.target'
      say 'Wants=network-online.target'
      say '[Service]'
      say 'Type=oneshot'
      say "ExecStart=$AUTOUPDATE_HELPER run --scheduled"
      say 'TimeoutStartSec=3h'
      say 'Nice=10'
      say 'IOSchedulingClass=best-effort'
      say 'IOSchedulingPriority=7'
    } > "$WORK/autoupdate-service"
    {
      say "# NIRUX owner: $PREFIX"
      say '[Unit]'
      say 'Description=NIRUX nightly update (03:00, no catch-up when missed)'
      say '[Timer]'
      say 'OnCalendar=*-*-* 03:00:00'
      say 'RandomizedDelaySec=30min'
      say 'Persistent=false'
      say '[Install]'
      say 'WantedBy=timers.target'
    } > "$WORK/autoupdate-timer"
    write_system "$ROOT/etc/systemd/system/nirux-autoupdate.service" "$WORK/autoupdate-service"
    write_system "$ROOT/etc/systemd/system/nirux-autoupdate.timer" "$WORK/autoupdate-timer"
    if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1; then
      as_root systemctl daemon-reload >/dev/null 2>&1 || :
      as_root systemctl enable --now nirux-autoupdate.timer >/dev/null 2>&1 ||
        say 'Could not enable the nightly update timer; run: sudo systemctl enable --now nirux-autoupdate.timer'
    fi
  fi
}
remove_autoupdate() {
  if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/nirux-autoupdate.timer ]; then
    as_root systemctl disable --now nirux-autoupdate.timer >/dev/null 2>&1 || :
  fi
  if [ -L "$ROOT/var/service/nirux-autoupdate" ]; then as_root rm -f "$ROOT/var/service/nirux-autoupdate"; fi
  remove_system "$ROOT/etc/sv/nirux-autoupdate/run"
  as_root rmdir "$ROOT/etc/sv/nirux-autoupdate" 2>/dev/null || :
  remove_system "$ROOT/etc/systemd/system/nirux-autoupdate.timer"
  remove_system "$ROOT/etc/systemd/system/nirux-autoupdate.service"
  remove_system "$ROOT/etc/sudoers.d/zz-nirux-autoupdate"
  remove_system "$ROOT/etc/nirux/autoupdate-packages"
  remove_system "$ROOT$AUTOUPDATE_HELPER"
}
# `nirux autoupdate status | last | enable | disable | run-now`
autoupdate_command() {
  au_conf=/etc/nirux/autoupdate.conf
  case "${1:-status}" in
    -h|--help)
      say 'usage: nirux autoupdate status | last | enable | disable | run-now'
      say 'The nightly update runs between 03:00 and 05:00 when nobody is logged in.'
      say "Settings: $au_conf (enabled, user, window, discord). Reports: /var/lib/nirux/autoupdate/"
      return 0 ;;
  esac
  [ -x "$AUTOUPDATE_HELPER" ] || die 'the nightly update is not installed yet; run nirux update'
  case "${1:-status}" in
    status)
      [ "$#" -le 1 ] || die 'usage: nirux autoupdate status'
      "$AUTOUPDATE_HELPER" status
      if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/nirux-autoupdate.timer ]; then
        systemctl list-timers nirux-autoupdate.timer --no-pager 2>/dev/null | sed -n '2p' | awk 'NF { print "Next run: " $1, $2, $3 }'
      elif [ -e /var/service/nirux-autoupdate ]; then
        say 'Next run: tonight in the window (runit service nirux-autoupdate)'
      fi
      pending_status ;;
    last) "$AUTOUPDATE_HELPER" last ;;
    enable|disable|run-now)
      [ "$#" = 1 ] || die "usage: nirux autoupdate $1"
      sudo "$AUTOUPDATE_HELPER" "$1" ;;
    *) die "unknown autoupdate command: $1 (nirux autoupdate --help)" ;;
  esac
}
