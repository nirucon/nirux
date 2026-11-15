sddm_qt_version() {
  if command -v sddm-greeter-qt6 >/dev/null 2>&1; then say 6; else say 5; fi
}
# Allow exactly one thing without a password: replacing the greeter's own
# background picture, which NIRUX owns and this user may write anyway.
#
# Earlier releases granted `NOPASSWD: $HOME/.local/bin/nirux ...`. That path is
# in the user's own installation, so the user could replace the program and have
# root run it: the argument restriction was no protection at all. The rule now
# names the fixed system path the gallery writes, so the grant can never reach
# a user-controlled executable.
# Wi-Fi control on a standalone wpa_supplicant system needs root for the
# control socket and rfkill. The grant names fixed system programs only; the
# user's own prefix can never match. NetworkManager systems use their normal
# D-Bus policy instead and do not need this rule.
install_wifi_rule() {
  [ -n "${rule_user:-}" ] || return 0
  wifi_source=$WORK/wifi-integration/polkit/nirux-wifi
  wifi_archive=$WORK/download/nirux/nirux-integration.tar.xz
  if [ -f "$wifi_archive" ]; then
    mkdir -p "$WORK/wifi-integration"
    tar -xJf "$wifi_archive" -C "$WORK/wifi-integration" ./polkit/nirux-wifi 2>/dev/null || :
  fi
  [ -f "$wifi_source" ] || {
    # Older release fixtures may not ship the helper; never retain a broad grant.
    remove_system "$ROOT/etc/sudoers.d/49-nirux-wifi"
    return 0
  }
  wifi_helper=$ROOT/usr/libexec/nirux-wifi
  {
    say '#!/usr/bin/python3'
    say "# NIRUX owner: $PREFIX"
    sed '1d' "$wifi_source"
  } > "$WORK/wifi-helper"
  write_system "$wifi_helper" "$WORK/wifi-helper"
  as_root chmod 0755 "$wifi_helper" || die 'could not secure Wi-Fi helper'
  {
    say "# NIRUX owner: $PREFIX"
    say '# Only the root-owned request validator is authorized, never raw wpa_cli.'
    say "$rule_user ALL=(root) NOPASSWD: /usr/libexec/nirux-wifi"
  } > "$WORK/wifi-sudoers"
  if command -v visudo >/dev/null 2>&1; then
    visudo_out=$(visudo -cf "$WORK/wifi-sudoers" 2>&1) ||
      die "generated Wi-Fi sudoers rule is invalid; nothing was installed: $visudo_out"
  fi
  # sudo and sudo-rs use the last matching rule, and files are read in name
  # order: a broad rule in a later file (Void's "wheel") would ask for a
  # password again. The zz- name sorts after those; 49- was the old name.
  remove_system "$ROOT/etc/sudoers.d/49-nirux-wifi"
  wifi_sudoers=$ROOT/etc/sudoers.d/zz-nirux-wifi
  if [ -f "$wifi_sudoers" ] && [ "$(as_root cat "$wifi_sudoers" 2>/dev/null)" = "$(cat "$WORK/wifi-sudoers")" ]; then
    :
  else
    write_system "$wifi_sudoers" "$WORK/wifi-sudoers"
  fi
  as_root chmod 0440 "$wifi_sudoers" || die 'could not secure the Wi-Fi sudoers rule'
}

# The weekly checkup (docs: manual chapter 11). The helper is installed
# root-owned in a system path and run by root from a systemd timer, or a
# runit service on Void; nothing in the user's prefix is ever run as root.
# The sudoers rule lets `nirux checkup` start exactly that helper.
CHECKUP_HELPER=/usr/libexec/nirux-checkup
install_checkup() {
  [ -n "${rule_user:-}" ] || return 0
  checkup_source=$WORK/checkup-integration/checkup/nirux-checkup
  checkup_archive=$WORK/download/nirux/nirux-integration.tar.xz
  if [ -f "$checkup_archive" ]; then
    mkdir -p "$WORK/checkup-integration"
    tar -xJf "$checkup_archive" -C "$WORK/checkup-integration" ./checkup/nirux-checkup 2>/dev/null || :
  fi
  [ -f "$checkup_source" ] || return 0
  {
    say '#!/bin/sh'
    say "# NIRUX owner: $PREFIX"
    sed '1d' "$checkup_source"
  } > "$WORK/checkup-helper"
  write_system "$ROOT$CHECKUP_HELPER" "$WORK/checkup-helper"
  as_root chmod 0755 "$ROOT$CHECKUP_HELPER" || die 'could not secure the checkup helper'
  # Settings are created once and then belong to the owner of the machine.
  checkup_conf=$ROOT/etc/nirux/checkup.conf
  if ! as_root test -f "$checkup_conf"; then
    {
      say "# NIRUX owner: $PREFIX"
      say '# NIRUX checkup settings (nirux checkup --help). Edit with sudo.'
      say 'enabled=yes'
      say '# discord: always, warnings or off (needs: nirux checkup discord set)'
      say 'discord=always'
      say '# clean: full (also unused packages and old kernels), safe or off'
      say 'clean=full'
      say 'disk_warn=85'
      say "user=$rule_user"
    } > "$WORK/checkup-conf"
    write_system "$checkup_conf" "$WORK/checkup-conf"
  fi
  {
    say "# NIRUX owner: $PREFIX"
    say '# Only the root-owned checkup helper, with fixed arguments.'
    say "$rule_user ALL=(root) NOPASSWD: $CHECKUP_HELPER run, $CHECKUP_HELPER run --dry-run"
  } > "$WORK/checkup-sudoers"
  if command -v visudo >/dev/null 2>&1; then
    visudo_out=$(visudo -cf "$WORK/checkup-sudoers" 2>&1) ||
      die "generated checkup sudoers rule is invalid; nothing was installed: $visudo_out"
  fi
  # Sorts after broad rules such as Void's "wheel" file (see install_wifi_rule).
  remove_system "$ROOT/etc/sudoers.d/49-nirux-checkup"
  checkup_sudoers=$ROOT/etc/sudoers.d/zz-nirux-checkup
  if ! { [ -f "$checkup_sudoers" ] && [ "$(as_root cat "$checkup_sudoers" 2>/dev/null)" = "$(cat "$WORK/checkup-sudoers")" ]; }; then
    write_system "$checkup_sudoers" "$WORK/checkup-sudoers"
  fi
  as_root chmod 0440 "$checkup_sudoers" || die 'could not secure the checkup sudoers rule'
  if [ "${OS:-$(distro)}" = void ]; then
    {
      say '#!/bin/sh'
      say "# NIRUX owner: $PREFIX"
      say 'exec 2>&1'
      say "exec chpst -n 19 $CHECKUP_HELPER loop"
    } > "$WORK/checkup-run"
    write_system "$ROOT/etc/sv/nirux-checkup/run" "$WORK/checkup-run"
    as_root chmod 0755 "$ROOT/etc/sv/nirux-checkup/run"
    [ -e "$ROOT/var/service/nirux-checkup" ] || [ -n "$ROOT" ] ||
      as_root ln -s /etc/sv/nirux-checkup "$ROOT/var/service/nirux-checkup"
  else
    {
      say "# NIRUX owner: $PREFIX"
      say '[Unit]'
      say 'Description=NIRUX weekly checkup'
      say 'After=network-online.target'
      say 'Wants=network-online.target'
      say '[Service]'
      say 'Type=oneshot'
      say "ExecStart=$CHECKUP_HELPER run"
      say 'Nice=19'
      say 'IOSchedulingClass=idle'
    } > "$WORK/checkup-service"
    {
      say "# NIRUX owner: $PREFIX"
      say '[Unit]'
      say 'Description=NIRUX weekly checkup (Monday 07:00, or at start when missed)'
      say '[Timer]'
      say 'OnCalendar=Mon *-*-* 07:00:00'
      say 'Persistent=true'
      say 'RandomizedDelaySec=120'
      say '[Install]'
      say 'WantedBy=timers.target'
    } > "$WORK/checkup-timer"
    write_system "$ROOT/etc/systemd/system/nirux-checkup.service" "$WORK/checkup-service"
    write_system "$ROOT/etc/systemd/system/nirux-checkup.timer" "$WORK/checkup-timer"
    if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1; then
      as_root systemctl daemon-reload >/dev/null 2>&1 || :
      as_root systemctl enable --now nirux-checkup.timer >/dev/null 2>&1 ||
        say 'Could not enable the checkup timer; run: sudo systemctl enable --now nirux-checkup.timer'
    fi
  fi
}

remove_checkup() {
  if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/nirux-checkup.timer ]; then
    as_root systemctl disable --now nirux-checkup.timer >/dev/null 2>&1 || :
  fi
  if [ -L "$ROOT/var/service/nirux-checkup" ]; then as_root rm -f "$ROOT/var/service/nirux-checkup"; fi
  remove_system "$ROOT/etc/sv/nirux-checkup/run"
  as_root rmdir "$ROOT/etc/sv/nirux-checkup" 2>/dev/null || :
  remove_system "$ROOT/etc/systemd/system/nirux-checkup.timer"
  remove_system "$ROOT/etc/systemd/system/nirux-checkup.service"
  remove_system "$ROOT/etc/sudoers.d/49-nirux-checkup"
  remove_system "$ROOT/etc/sudoers.d/zz-nirux-checkup"
  remove_system "$ROOT$CHECKUP_HELPER"
}

# `nirux checkup [--dry-run] | last | status | enable | disable | discord set|test`
checkup_command() {
  [ -x "$CHECKUP_HELPER" ] || die 'the checkup is not installed yet; run nirux update'
  case "${1:-run}" in
    run|--dry-run)
      if [ "${1:-}" = --dry-run ]; then sudo "$CHECKUP_HELPER" run --dry-run
      else sudo "$CHECKUP_HELPER" run; fi ;;
    last) "$CHECKUP_HELPER" last ;;
    status)
      enabled=$(sed -n 's/^enabled=//p' /etc/nirux/checkup.conf 2>/dev/null | tail -n 1)
      say "Checkup: ${enabled:-yes} (settings: /etc/nirux/checkup.conf)"
      if [ -f /var/lib/nirux/checkup/last-run ]; then
        say "Last run: $(date -d "@$(cat /var/lib/nirux/checkup/last-run)" '+%Y-%m-%d %H:%M')"
      else say 'Last run: never'; fi
      if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/nirux-checkup.timer ]; then
        systemctl list-timers nirux-checkup.timer --no-pager 2>/dev/null | sed -n '2p' | awk '{ print "Next run: " $1, $2, $3 }'
      elif [ -e /var/service/nirux-checkup ]; then
        say 'Next run: Monday 07:00 (runit service nirux-checkup)'
      fi
      if sudo -n test -s /etc/nirux/checkup-webhook 2>/dev/null; then say 'Discord: webhook set'; fi ;;
    enable|disable)
      value=yes; [ "$1" = enable ] || value=no
      lock
      as_root sed -i "s/^enabled=.*/enabled=$value/" /etc/nirux/checkup.conf
      say "Checkup ${1}d" ;;
    discord)
      case "${2:-}" in
        set) say 'Paste the Discord webhook URL and press Enter (empty removes it):'
             as_root "$CHECKUP_HELPER" webhook-set ;;
        test) as_root "$CHECKUP_HELPER" discord-test ;;
        *) die 'usage: nirux checkup discord set|test' ;;
      esac ;;
    -h|--help) say 'usage: nirux checkup [--dry-run] | last | status | enable | disable | discord set|test' ;;
    *) die "unknown checkup command: $1 (nirux checkup --help)" ;;
  esac
}

install_login_wallpaper_rule() {
  legacy_file=$ROOT/etc/sudoers.d/49-nirux-login-wallpaper
  # The unsafe rule from earlier releases goes first, whatever happens next: it
  # must not stay merely because writing its replacement failed.
  if as_root test -f "$legacy_file" && as_root grep -q 'login-wallpaper sync' "$legacy_file" 2>/dev/null; then
    say 'Withdrawing the previous passwordless login-wallpaper rule'
    as_root rm -f "$legacy_file"
  fi
  # One grant per greeter picture this release installed, and nothing else.
  # sudo matches a command by its exact arguments, and those name /usr/bin/install
  # with one staged file and one greeter path. No program from the user's own
  # prefix can ever match, which is what made the old rule unsafe.
  sddm_picture=$ROOT/usr/share/sddm/themes/nirux/background.png
  lightdm_picture=$ROOT/usr/share/nirux/greeter/login.png
  targets=
  [ ! -f "$sddm_picture" ] || targets="$targets /usr/share/sddm/themes/nirux/background.png:/usr/share/sddm/themes/nirux"
  [ ! -f "$lightdm_picture" ] || targets="$targets /usr/share/nirux/greeter/login.png:/usr/share/nirux/greeter"
  if [ -z "$targets" ] || [ -z "${rule_user:-}" ]; then
    # No greeter was installed here, or no desktop user could be named: keep no
    # grant that nothing needs.
    if as_root test -f "$legacy_file"; then as_root rm -f "$legacy_file"; fi
    return 0
  fi
  {
    say "# NIRUX owner: $PREFIX"
    say "# Lets a theme change copy the login screen picture without a password."
    say "# Each rule names /usr/bin/install, the staged picture and one greeter"
    say "# file, so nothing else can be run as root through it."
    for entry in $targets; do
      picture=${entry%%:*}
      directory=${entry#*:}
      say "$rule_user ALL=(root) NOPASSWD: /usr/bin/install -d -m 755 $directory"
      say "$rule_user ALL=(root) NOPASSWD: /usr/bin/install -m 644 -o root -g root /tmp/nirux-login-background.png $picture"
    done
  } > "$WORK/sudoers"
  if command -v visudo >/dev/null 2>&1; then
    tmp_check="$WORK/sudoers.check"
    cat "$WORK/sudoers" > "$tmp_check"
    visudo -cf "$tmp_check" >/dev/null 2>&1 ||
      die 'generated sudoers rule is invalid; nothing was installed'
    rm -f "$tmp_check"
  fi
  sudoers_file=$ROOT/etc/sudoers.d/49-nirux-login-wallpaper
  # write_system compares the file by reading it, and sudoers.d is closed to
  # this user, so an unchanged rule is compared by root and left alone.
  # Compare by reading, since sudoers.d is closed to this user.
  if [ -f "$sudoers_file" ] && [ "$(as_root cat "$sudoers_file" 2>/dev/null)" = "$(cat "$WORK/sudoers")" ]; then
    :
  else
    write_system "$sudoers_file" "$WORK/sudoers"
  fi
  # sudo ignores a writable file in sudoers.d, and does so silently.
  # write_system installs 0644, so this one needs its mode set explicitly.
  if [ "$(as_root stat -c %a "$sudoers_file" 2>/dev/null || :)" != 440 ]; then
    as_root chmod 0440 "$sudoers_file"
  fi
}

# Copy the login picture as root through the named grant. The picture is staged
# at the fixed path the rule names and removed again; nothing else is passed to
# root, so the grant cannot become "run this program as root".
install_login_picture() {
  source=$1
  target=$2
  if [ "$(id -u)" = 0 ]; then
    install -d -m 755 "$(dirname "$target")" && install -m 644 -o root -g root "$source" "$target"
    return
  fi
  stage=/tmp/nirux-login-background.png
  rm -f "$stage"
  ( umask 022; install -m 644 "$source" "$stage" ) || return 1
  # The rule names /usr/bin/install with these exact arguments; a PATH lookup
  # of bare `install` would not match it.
  if sudo -n /usr/bin/install -m 644 -o root -g root "$stage" "$target" 2>/dev/null; then
    rm -f "$stage"
    return 0
  fi
  rm -f "$stage"
  return 1
}

# gnome-keyring unlocks the login keyring with the password typed at NIRU
# Login, so apps such as the Nextcloud client remember their logins. Debian's
# greetd PAM file already has these lines; Arch's and Void's do not. Each line
# starts with "-", so PAM skips it on a machine without the module.
NIRUX_KEYRING_PAM_MARK='# NIRUX keyring:'
# True when FILE, or a PAM file it includes, already calls pam_gnome_keyring.
pam_has_keyring() {
  pam_depth=${2:-0}
  as_root test -f "$1" || return 1
  as_root grep -q 'pam_gnome_keyring\.so' "$1" 2>/dev/null && return 0
  [ "$pam_depth" -lt 3 ] || return 1
  for pam_include in $(as_root cat "$1" 2>/dev/null | awk '$1 == "@include" {print $2} $2 == "include" || $2 == "substack" {print $3}'); do
    pam_has_keyring "$ROOT/etc/pam.d/$pam_include" $((pam_depth + 1)) && return 0
  done
  return 1
}
# Append marked keyring lines to a PAM file that has none; FILE WHY LINE...
pam_keyring_add() {
  pam_file=$1 pam_why=$2; shift 2
  as_root test -f "$pam_file" || return 1
  pam_has_keyring "$pam_file" && return 1
  as_root cat "$pam_file" > "$WORK/keyring-pam" || return 1
  { say ''; say "$NIRUX_KEYRING_PAM_MARK $pam_why"; for pam_line in "$@"; do say "$pam_line"; done; } >> "$WORK/keyring-pam"
  as_root install -m 644 "$WORK/keyring-pam" "$pam_file"
}
# Remove only the lines pam_keyring_add wrote.
pam_keyring_strip() {
  as_root test -f "$1" || return 0
  as_root grep -qF "$NIRUX_KEYRING_PAM_MARK" "$1" 2>/dev/null || return 0
  as_root cat "$1" | awk -v mark="$NIRUX_KEYRING_PAM_MARK" '
    { line[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) if (index(line[i], mark) == 1) {
        drop[i] = 1
        if (i > 1 && line[i - 1] == "") drop[i - 1] = 1
        for (j = i + 1; j <= NR && line[j] ~ /pam_gnome_keyring\.so/; j++) drop[j] = 1
      }
      for (i = 1; i <= NR; i++) if (!(i in drop)) print line[i]
    }' > "$WORK/keyring-pam" || return 1
  as_root install -m 644 "$WORK/keyring-pam" "$1"
}
ensure_greetd_keyring_pam() {
  pam_keyring_add "$ROOT/etc/pam.d/greetd" 'unlock the login keyring with the login password' \
    '-auth       optional    pam_gnome_keyring.so' '-session    optional    pam_gnome_keyring.so auto_start' &&
    say 'NIRU Login unlocks the keyring at login'
  return 0
}
remove_greetd_keyring_pam() { pam_keyring_strip "$ROOT/etc/pam.d/greetd"; }
# passwd changes the login password; the keyring must follow it, or the next
# login cannot unlock the keyring and apps ask for the old password. Debian's
# common-password already does this; Arch's and Void's passwd do not.
ensure_passwd_keyring_pam() {
  pam_keyring_add "$ROOT/etc/pam.d/passwd" 'passwd also changes the login keyring password' \
    '-password   optional    pam_gnome_keyring.so' &&
    say 'passwd keeps the keyring password in step with the login password'
  return 0
}
remove_passwd_keyring_pam() { pam_keyring_strip "$ROOT/etc/pam.d/passwd"; }

