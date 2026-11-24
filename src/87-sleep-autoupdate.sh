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

# ── Behind after a night away (docs: manual chapter 11) ─────────────────────
# A laptop that sleeps or is off between 03:00 and 05:00 misses the nightly
# update, night after night. At login and after a wake-up (NIRUWM's hooks)
# this asks GitHub at most every six hours and, when NIRUX or a selected
# extra is behind, says so once per version, with *Update now*, which runs
# the nightly update at once (`nirux autoupdate run-now`, allowed without a
# password).
UPDATE_CHECK_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/nirux/latest-release
UPDATE_CHECK_SEEN=$STATE/update-check-notified
UPDATE_CHECK_FIRST=$STATE/update-check-first-seen
update_check_latest() {
  uc_now=$(date +%s)
  uc_age=$((uc_now - $(stat -c %Y "$UPDATE_CHECK_CACHE" 2>/dev/null || echo 0)))
  if [ "$uc_age" -ge "${NIRUX_UPDATE_CHECK_SECONDS:-21600}" ]; then
    mkdir -p "${UPDATE_CHECK_CACHE%/*}" 2>/dev/null || :
    uc_tmp=$UPDATE_CHECK_CACHE.$$
    if (NIRUX_FETCH_ATTEMPTS=1 NIRUX_MIRROR_ATTEMPTS=1 fetch https://api.github.com/repos/nirucon/nirux/releases/latest "$uc_tmp") >/dev/null 2>&1; then
      uc_tag=$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][0-9.]*\)".*/\1/p' "$uc_tmp" | head -n 1)
      [ -n "$uc_tag" ] && say "$uc_tag" > "$UPDATE_CHECK_CACHE"
    fi
    rm -f "$uc_tmp"
  fi
  head -n 1 "$UPDATE_CHECK_CACHE" 2>/dev/null || :
}
# "name version" for each selected extra whose installed version is not the pin.
update_check_extras() {
  [ -f "$EXTRAS_SELECTED" ] || return 0
  while read -r uce_name; do
    [ -n "$uce_name" ] || continue
    uce_pin=$(extras_row "$uce_name" 2>/dev/null | awk '{print $3}') || continue
    [ -n "$uce_pin" ] || continue
    [ "$(extras_installed_version "$uce_name" 2>/dev/null || :)" = "$uce_pin" ] || say "$uce_name $uce_pin"
  done < "$EXTRAS_SELECTED"
}
update_check_command() {
  uc_notify=0
  for uc_arg in "$@"; do
    case "$uc_arg" in
      --notify) uc_notify=1 ;;
      -h|--help) say 'usage: nirux update-check [--notify]'; return 0 ;;
      *) die "unknown update-check option: $uc_arg" ;;
    esac
  done
  uc_latest=$(update_check_latest)
  uc_core=''
  if [ -n "$uc_latest" ] && fleet_older "$VERSION" "$uc_latest"; then
    uc_core="NIRUX $uc_latest is out; this computer has $VERSION."
  fi
  uc_extras=$(update_check_extras | paste -sd ',' - | sed 's/,/, /g')
  uc_body=$uc_core
  [ -z "$uc_extras" ] || uc_body="${uc_body:+$uc_body
}Extras waiting: $uc_extras."
  if [ "$uc_notify" = 0 ]; then
    if [ -n "$uc_body" ]; then say "$uc_body"; else say "NIRUX ${VERSION} and the selected extras are current${uc_latest:+ (latest release $uc_latest)}."; fi
    return 0
  fi
  [ -n "$uc_body" ] && [ -n "${DISPLAY:-}" ] && command -v notify-send >/dev/null 2>&1 || return 0
  uc_key=$(printf '%s|%s' "$uc_latest" "$uc_extras")
  # A release out since this afternoon is the nightly update's job: tell only
  # when it has been waiting for more than a night (30 hours) and still is.
  uc_first_key=$(sed -n 1p "$UPDATE_CHECK_FIRST" 2>/dev/null || :)
  uc_first_at=$(sed -n 2p "$UPDATE_CHECK_FIRST" 2>/dev/null || :)
  if [ "$uc_first_key" != "$uc_key" ] || [ -z "$uc_first_at" ]; then
    mkdir -p "$STATE" 2>/dev/null || :
    printf '%s\n%s\n' "$uc_key" "$(date +%s)" > "$UPDATE_CHECK_FIRST" 2>/dev/null || :
    uc_first_at=$(date +%s)
  fi
  if [ -x "$AUTOUPDATE_HELPER" ] && [ $(( $(date +%s) - uc_first_at )) -lt "${NIRUX_UPDATE_CHECK_WAIT:-108000}" ]; then
    return 0
  fi
  # Once per state: a new release or another extra is told again.
  [ "$(cat "$UPDATE_CHECK_SEEN" 2>/dev/null)" != "$uc_key" ] || return 0
  mkdir -p "$STATE" 2>/dev/null || :
  printf '%s\n' "$uc_key" > "$UPDATE_CHECK_SEEN" 2>/dev/null || :
  if [ -x "$AUTOUPDATE_HELPER" ]; then
    uc_answer=$(timeout 3600 notify-send -a NIRUX --action=update='Update now' --wait \
      "NIRUX update waiting" "$uc_body
It missed the nightly update. Update now, or leave it locked tonight." 2>/dev/null) || uc_answer=''
  else
    notify-send -a NIRUX "NIRUX update waiting" "$uc_body
Run in a terminal: nirux update; nirux extras update" >/dev/null 2>&1 || :
    return 0
  fi
  [ "$uc_answer" = update ] || return 0
  notify-send -a NIRUX "Updating NIRUX" "System packages, NIRUX and extras. You can keep working." >/dev/null 2>&1 || :
  if sudo -n "$AUTOUPDATE_HELPER" run-now >/dev/null 2>&1; then
    notify-send -a NIRUX "NIRUX is up to date" "New NIRUWM programs start after niructl restart-wm or the next login." >/dev/null 2>&1 || :
  else
    notify-send -a NIRUX -u critical "NIRUX update did not finish" "See: nirux autoupdate last" >/dev/null 2>&1 || :
  fi
}
# Started from the login and wake-up hooks, never in their way.
update_check_background() {
  ucb_self=$HOME/.local/bin/nirux
  [ -x "$ucb_self" ] || return 0
  (cd / && "$ucb_self" update-check --notify >/dev/null 2>&1 < /dev/null &) || :
}
