# ── The NIRUX boot look (nirusplash) ────────────────────────────────────────
# GRUB in the NIRUX look and the boot splash, where an encrypted disk asks for
# its password in the same style (docs: chapter 8). nirusplash is a manifest
# component: every install and update refreshes it in the colours of the
# active theme, unless it was turned off with `nirux boot off`. It never
# touches the boot loader binary, LUKS or the kernel; see its own README.
BOOT_SPLASH_SYSTEM=/usr/local/sbin/nirusplash
BOOT_SPLASH_STATE=/var/lib/nirusplash/state
BOOT_SPLASH_OFF=/var/lib/nirusplash/disabled

# The active theme's colours as "background foreground muted focus"; Noir when
# niructl cannot say.
boot_colours() {
  bc_ctl=$1
  bc_out=$("$bc_ctl" theme-catalog 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    t = [t for t in d["themes"] if t["id"] == d["active"]][0]["colors"]
    v = [t[k].lstrip("#") for k in ("background", "foreground", "muted", "focus")]
    assert all(len(x) == 6 and int(x, 16) >= 0 for x in v)
    print(" ".join(v))
except Exception:
    pass
' 2>/dev/null || :)
  [ -n "$bc_out" ] || bc_out='0f0f10 e5e5e5 a8a8a8 5a5a60'
  say "$bc_out"
}

boot_splash_state() { sed -n "s/^$1=//p" "$BOOT_SPLASH_STATE" 2>/dev/null | tail -1; }

# install/update: bring the boot look up to date. Never stops the update.
boot_look_apply() {
  bl_bin=$WORK/generation/bin/nirusplash
  [ -x "$bl_bin" ] || return 0
  # Never on a test system root (integration tests), only the real one.
  [ "${NIRUX_TEST_AS_ROOT:-0}" != 1 ] && [ -z "${ROOT:-}" ] || return 0
  if [ -f "$BOOT_SPLASH_OFF" ]; then
    say 'NIRUX boot look: off (nirux boot on turns it on)'
    return 0
  fi
  # Only GRUB machines (all that niruboot makes).
  [ -f /boot/grub/grub.cfg ] || as_root test -f /boot/grub/grub.cfg || return 0
  bl_ctl=$WORK/generation/bin/niructl
  [ -x "$bl_ctl" ] || bl_ctl=niructl
  # shellcheck disable=SC2046
  set -- $(boot_colours "$bl_ctl")
  bl_version=$("$bl_bin" --version | awk '{print $2}')
  if [ "$(boot_splash_state version)" = "$bl_version" ] &&
     [ "$(boot_splash_state colours)" = "$1,$2,$3,$4,d77a7a" ] &&
     same_file "$bl_bin" "$BOOT_SPLASH_SYSTEM" 2>/dev/null; then
    return 0
  fi
  say 'Updating the NIRUX boot look (GRUB and the boot splash)...'
  if as_root install -m 755 "$bl_bin" "$BOOT_SPLASH_SYSTEM" &&
     as_root "$BOOT_SPLASH_SYSTEM" install --if-enabled \
       --background "$1" --foreground "$2" --muted "$3" --focus "$4"; then
    :
  else
    say 'nirux: the NIRUX boot look was not changed; the boot is as it was (nirux boot doctor)' >&2
  fi
}

boot_splash_bin() {
  if [ -x "$BOOT_SPLASH_SYSTEM" ]; then say "$BOOT_SPLASH_SYSTEM"
  elif [ -x "$STATE/current/bin/nirusplash" ]; then say "$STATE/current/bin/nirusplash"
  else die 'nirusplash is not installed; run nirux update'
  fi
}

boot_command() {
  bc_sub=${1:-status}
  [ "$#" -eq 0 ] || shift
  case "$bc_sub" in
    status) "$(boot_splash_bin)" status "$@" ;;
    on|apply)
      bc_bin=$(boot_splash_bin)
      if [ -x "$STATE/current/bin/nirusplash" ] && [ "$bc_bin" != "$STATE/current/bin/nirusplash" ]; then
        as_root install -m 755 "$STATE/current/bin/nirusplash" "$BOOT_SPLASH_SYSTEM"
        bc_bin=$BOOT_SPLASH_SYSTEM
      fi
      # shellcheck disable=SC2046
      set -- $(boot_colours niructl)
      as_root "$bc_bin" install --background "$1" --foreground "$2" --muted "$3" --focus "$4" ;;
    off) as_root "$(boot_splash_bin)" remove ;;
    doctor) as_root "$(boot_splash_bin)" doctor ;;
    -h|--help|help)
      say 'usage: nirux boot [status|on|off|apply|doctor]'
      say '  on/apply  make the NIRUX GRUB menu and boot splash in the current theme'
      say '  off       put the plain boot back (updates leave it off)' ;;
    *) die "boot: unknown command $bc_sub (status, on, off, apply, doctor)" ;;
  esac
}

# uninstall: the plain boot comes back with the rest of the system.
boot_look_remove() {
  [ -x "$BOOT_SPLASH_SYSTEM" ] || return 0
  as_root "$BOOT_SPLASH_SYSTEM" remove || say 'nirux: nirusplash remove failed; run it by hand' >&2
  as_root rm -f "$BOOT_SPLASH_SYSTEM"
}
