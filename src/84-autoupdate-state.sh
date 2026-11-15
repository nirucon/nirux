# ── The nightly update: nirux update --auto (docs: manual chapter 11) ───────
# The root helper /usr/libexec/nirux-autoupdate runs this as the user, with no
# terminal and no password. Everything that needs root is checked here as the
# user; a step that would change the system is not run but written to
# $PENDING_SYSTEM ("Run nirux update once to finish"), and packages the
# release needs go to $WANTED_PACKAGES, which the root helper installs from
# the distribution's repositories before it runs this update once more.
#
# Root-only files (sudoers rules, a polkit directory) cannot be read by the
# user, so every file NIRUX installs through sudo is recorded in $SYSTEM_SUMS
# (SHA-256 and path). Unchanged files are then recognised without reading them.
system_sum_note() {
  ssn_src='' ssn_dst=''
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d) return 0 ;;
      -m|-o|-g) shift ;;
      -*) ;;
      *) if [ -z "$ssn_src" ]; then ssn_src=$1; else ssn_dst=$1; fi ;;
    esac
    shift
  done
  [ -n "$ssn_dst" ] && [ -f "$ssn_src" ] || return 0
  ssn_sum=$(sha256sum "$ssn_src" 2>/dev/null | cut -d ' ' -f1) || return 0
  mkdir -p "$STATE" 2>/dev/null || return 0
  {
    awk -v p="$ssn_dst" '{ q = $0; sub(/^[^ ]* /, "", q); if (q != p) print }' "$SYSTEM_SUMS" 2>/dev/null || :
    say "$ssn_sum $ssn_dst"
  } > "$SYSTEM_SUMS.$$" && mv -f "$SYSTEM_SUMS.$$" "$SYSTEM_SUMS" || rm -f "$SYSTEM_SUMS.$$"
  return 0
}
# Is FILE known to hold exactly SOURCE (or, without SOURCE, any recorded file)?
system_sum_known() {
  ssk_line=$(awk -v p="$1" '{ q = $0; sub(/^[^ ]* /, "", q); if (q == p) { print $1; exit } }' "$SYSTEM_SUMS" 2>/dev/null) || ssk_line=
  [ -n "$ssk_line" ] || return 1
  [ -n "${2:-}" ] || return 0
  [ "$ssk_line" = "$(sha256sum "$2" 2>/dev/null | cut -d ' ' -f1)" ]
}
auto_pending() {
  mkdir -p "$STATE" 2>/dev/null || return 0
  grep -qxF -- "$1" "$PENDING_SYSTEM" 2>/dev/null || say "$1" >> "$PENDING_SYSTEM"
}
# The last path argument of a command, which is what it changes.
auto_last_path() {
  alp=
  for alp_arg in "$@"; do case "$alp_arg" in -*) ;; *) alp=$alp_arg ;; esac; done
  say "$alp"
}
auto_mode_of() { stat -c %a "$1" 2>/dev/null | sed 's/^0*//'; }
# as_root in --auto mode. Reading commands run as the user; a change that is
# already in place succeeds without root; anything else is recorded as pending
# and reported as done, so the rest of the update goes on.
auto_root() {
  ar_cmd=$1
  case "$ar_cmd" in
    test|grep|cat|stat|readlink|sha256sum|id) "$@"; return ;;
    true) return 1 ;;
    rmdir|udevadm) return 0 ;;
    systemctl)
      ar_now=0 ar_unit=
      for ar_arg in "$@"; do
        case "$ar_arg" in --now) ar_now=1 ;; systemctl|-*) ;; *) ar_unit=$ar_arg ;; esac
      done
      case "${2:-}" in
        is-active|is-enabled|status|cat|show|list-timers|list-units) "$@"; return ;;
        daemon-reload) return 0 ;;
        enable)
          systemctl is-enabled --quiet "$ar_unit" 2>/dev/null &&
            { [ "$ar_now" = 0 ] || systemctl is-active --quiet "$ar_unit" 2>/dev/null; } && return 0 ;;
        start) systemctl is-active --quiet "$ar_unit" 2>/dev/null && return 0 ;;
        disable) systemctl is-enabled --quiet "$ar_unit" 2>/dev/null || return 0 ;;
      esac
      auto_pending "systemctl $2 $ar_unit"
      return 0 ;;
    chmod)
      ar_want=$(say "$2" | sed 's/^0*//')
      [ "$(auto_mode_of "$3")" = "$ar_want" ] && return 0
      if ! stat "$3" >/dev/null 2>&1 && system_sum_known "$3"; then return 0; fi
      auto_pending "set the mode of $3 to $2"
      return 0 ;;
    mkdir) [ -d "$(auto_last_path "$@")" ] && return 0 ;;
    install)
      ar_dir=0 ar_mode='' ar_src='' ar_dst=''
      shift
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -d) ar_dir=1 ;;
          -m) ar_mode=$(say "$2" | sed 's/^0*//'); shift ;;
          -o|-g) shift ;;
          -*) ;;
          *) if [ "$ar_dir" = 1 ]; then [ -d "$1" ] || ar_dst=$1
             elif [ -z "$ar_src" ]; then ar_src=$1; else ar_dst=$1; fi ;;
        esac
        shift
      done
      if [ "$ar_dir" = 1 ]; then
        [ -z "$ar_dst" ] && return 0
        auto_pending "create $ar_dst"
        return 0
      fi
      if [ -r "$ar_dst" ] && same_file "$ar_src" "$ar_dst" &&
         { [ -z "$ar_mode" ] || [ "$(auto_mode_of "$ar_dst")" = "$ar_mode" ]; }; then
        return 0
      fi
      if [ ! -r "$ar_dst" ] && system_sum_known "$ar_dst" "$ar_src"; then return 0; fi
      auto_pending "update $ar_dst"
      return 0 ;;
    ln)
      ar_dst=$(auto_last_path "$@")
      ar_src=
      for ar_arg in "$@"; do
        case "$ar_arg" in ln|-*) ;; *) [ -n "$ar_src" ] || ar_src=$ar_arg ;; esac
      done
      [ -L "$ar_dst" ] && [ "$(readlink "$ar_dst")" = "$ar_src" ] && return 0
      auto_pending "link $ar_dst"
      return 0 ;;
    rm)
      ar_any=
      for ar_arg in "$@"; do
        case "$ar_arg" in rm|-*) ;; *) if [ -e "$ar_arg" ] || [ -L "$ar_arg" ]; then ar_any=$ar_arg; fi ;; esac
      done
      [ -z "$ar_any" ] && return 0
      auto_pending "remove $ar_any"
      return 0 ;;
    cp|mv|chown|sed|usermod|tee) auto_pending "$ar_cmd $(auto_last_path "$@")"; return 0 ;;
    apt-get|env|pacman|xbps-install|xbps-remove) auto_pending 'install system packages'; return 0 ;;
  esac
  auto_pending "$ar_cmd $(auto_last_path "$@")"
  return 0
}
# Start of a full --auto run: what the last run left is worked out again.
auto_reset() {
  [ "$NIRUX_AUTO" = 1 ] || return 0
  rm -f "$PENDING_SYSTEM" "$WANTED_PACKAGES"
}
# A normal update did everything with sudo; nothing is waiting any more.
auto_finished() {
  [ "$NIRUX_AUTO" = 1 ] || rm -f "$PENDING_SYSTEM" "$WANTED_PACKAGES"
}
# Packages a release needs, for the root helper to install. Names only.
auto_want_packages() {
  mkdir -p "$STATE" || return 1
  for awp in "$@"; do
    case "$awp" in ''|-*|[!A-Za-z0-9]*|*[!A-Za-z0-9+._-]*) continue ;; esac
    grep -qxF -- "$awp" "$WANTED_PACKAGES" 2>/dev/null || say "$awp" >> "$WANTED_PACKAGES"
  done
  say "Packages for the nightly update to install: $*"
}
# One line per waiting item, for status, the bar and the what's-new notice.
pending_lines() {
  if [ -s "$WANTED_PACKAGES" ]; then say "install packages: $(tr '\n' ' ' < "$WANTED_PACKAGES" | sed 's/ $//')"; fi
  if [ -s "$PENDING_SYSTEM" ]; then cat "$PENDING_SYSTEM"; fi
  return 0
}
pending_status() {
  pending_lines > "${TMPDIR:-/tmp}/.nirux-pending.$$" 2>/dev/null || :
  if [ -s "${TMPDIR:-/tmp}/.nirux-pending.$$" ]; then
    say "pending system changes ($(grep -c . "${TMPDIR:-/tmp}/.nirux-pending.$$")): run nirux update once to finish"
    head -n 8 "${TMPDIR:-/tmp}/.nirux-pending.$$" | sed 's/^/  /'
  fi
  rm -f "${TMPDIR:-/tmp}/.nirux-pending.$$"
}

