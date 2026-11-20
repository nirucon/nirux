# ── Sleep that saves to disk (nirusleep) ────────────────────────────────────
# After a while in suspend the laptop writes its memory to an encrypted swap
# file and switches off (docs: chapter 10). Off until `nirux hibernate on`:
# it needs a swap file the size of the memory and changes the initramfs and
# the kernel command line. nirusleep is a manifest component; while it is on,
# every update refreshes it and applies `[battery] hibernate_after_minutes`.
SLEEP_SYSTEM=/usr/local/sbin/nirusleep
SLEEP_STATE=/var/lib/nirusleep/state

sleep_state() { sed -n "s/^$1=//p" "$SLEEP_STATE" 2>/dev/null | tail -1; }

# Minutes of sleep before hibernating, from the NIRUWM configuration.
sleep_delay_config() {
  sd_ctl=${1:-niructl}
  sd_value=$("$sd_ctl" config get battery.hibernate_after_minutes 2>/dev/null | tail -1 || :)
  case "$sd_value" in ''|*[!0-9]*) sd_value=120 ;; esac
  say "$sd_value"
}

sleep_bin() {
  if [ -x "$STATE/current/bin/nirusleep" ]; then say "$STATE/current/bin/nirusleep"
  elif [ -x "$SLEEP_SYSTEM" ]; then say "$SLEEP_SYSTEM"
  else die 'nirusleep is not installed; run nirux update'
  fi
}

sleep_install_bin() {
  si_bin=$(sleep_bin)
  if [ "$si_bin" != "$SLEEP_SYSTEM" ] && ! same_file "$si_bin" "$SLEEP_SYSTEM" 2>/dev/null; then
    as_root install -m 755 "$si_bin" "$SLEEP_SYSTEM"
  fi
}

# install/update: only while it is on. Never stops the update.
sleep_apply() {
  sa_bin=$WORK/generation/bin/nirusleep
  [ -x "$sa_bin" ] || return 0
  [ "${NIRUX_TEST_AS_ROOT:-0}" != 1 ] && [ -z "${ROOT:-}" ] || return 0
  [ -f "$SLEEP_STATE" ] || return 0
  sa_ctl=$WORK/generation/bin/niructl
  [ -x "$sa_ctl" ] || sa_ctl=niructl
  sa_delay=$(sleep_delay_config "$sa_ctl")
  sa_version=$("$sa_bin" --version | awk '{print $2}')
  if [ "$(sleep_state version)" = "$sa_version" ] && [ "$(sleep_state delay)" = "$sa_delay" ] &&
     same_file "$sa_bin" "$SLEEP_SYSTEM" 2>/dev/null; then
    return 0
  fi
  say 'Updating sleep that saves to disk (nirusleep)...'
  if as_root install -m 755 "$sa_bin" "$SLEEP_SYSTEM" &&
     as_root "$SLEEP_SYSTEM" install --delay "$sa_delay"; then
    :
  else
    say 'nirux: nirusleep was not changed; sleep works as before (nirux hibernate doctor)' >&2
  fi
}

sleep_command() {
  sc_sub=${1:-status}
  [ "$#" -eq 0 ] || shift
  case "$sc_sub" in
    status) "$(sleep_bin)" status "$@" ;;
    on|apply)
      if [ "$sc_sub" = apply ] && [ ! -f "$SLEEP_STATE" ]; then
        die 'hibernate is off; nirux hibernate on turns it on'
      fi
      sleep_install_bin
      as_root "$SLEEP_SYSTEM" install --delay "$(sleep_delay_config)" "$@" ;;
    delay)
      [ "$#" -ge 1 ] || die 'usage: nirux hibernate delay MINUTES|2h (0: plain suspend)'
      sc_minutes=$1
      case "$sc_minutes" in
        *h) sc_minutes=$(( ${sc_minutes%h} * 60 )) ;;
        *min) sc_minutes=${sc_minutes%min} ;;
      esac
      case "$sc_minutes" in ''|*[!0-9]*) die "delay: not minutes: $1" ;; esac
      niructl config set battery.hibernate_after_minutes "$sc_minutes" --yes >/dev/null ||
        die 'could not save battery.hibernate_after_minutes'
      if [ -f "$SLEEP_STATE" ]; then
        sleep_install_bin
        as_root "$SLEEP_SYSTEM" delay "$sc_minutes"
      else
        say "saved: $sc_minutes min (used when nirux hibernate on turns it on)"
      fi ;;
    off) [ -x "$SLEEP_SYSTEM" ] || { say 'hibernate is off'; return 0; }
         as_root "$SLEEP_SYSTEM" remove ;;
    doctor) as_root "$(sleep_bin)" doctor ;;
    -h|--help|help)
      say 'usage: nirux hibernate [status|on|off|apply|delay MINUTES|doctor]'
      say '  on       an encrypted swap file; sleep turns into hibernation after the delay'
      say '  delay    minutes (or 2h) of sleep first; [battery] hibernate_after_minutes'
      say '  off      plain suspend again, the swap file removed' ;;
    *) die "hibernate: unknown command $sc_sub (status, on, off, apply, delay, doctor)" ;;
  esac
}

# uninstall: plain suspend comes back with the rest of the system.
sleep_remove() {
  [ -x "$SLEEP_SYSTEM" ] || return 0
  if [ -f "$SLEEP_STATE" ]; then
    as_root "$SLEEP_SYSTEM" remove || say 'nirux: nirusleep remove failed; run it by hand' >&2
  fi
  as_root rm -f "$SLEEP_SYSTEM"
}
