# nirux fleet: see and update the NIRUX machines on this Tailscale network.
# Hosts come from `tailscale status --json` (Linux peers) or from [fleet] in
# ~/.config/nirux/fleet.toml. Every remote command is `sh -s` with the script on
# standard input, or a plain program path: the login shell on a host may be
# fish, which does not understand sh syntax in an ssh command line.
FLEET_CONFIG=$NIRUX_CONFIG/fleet.toml
FLEET_KNOWN=$STATE/fleet-known
# Settings waiting for a host that was offline: "HOST<TAB>KEY<TAB>VALUE<TAB>EPOCH".
FLEET_PENDING=$STATE/fleet-pending
FLEET_WORK=
fleet_usage() {
  say "Usage: nirux fleet [status] [--json]"
  say "       nirux fleet update HOST...|--all|--behind"
  say "       nirux fleet setup [HOST...]"
  say "       nirux fleet set KEY VALUE [HOST...]"
  say "       nirux fleet pending [apply|clear [HOST]]"
  say "KEY is a NIRUWM key such as idle.screensaver_timeout (niructl config set) or"
  say "screensaver.KEY for ~/.config/niruui/screensaver.toml (niruscreensaver --set)."
  say "A host that is offline gets the setting later: at the next nirux fleet command,"
  say "login or wake-up on this machine while it is online (nirux fleet pending)."
  say "Hosts: Linux peers from Tailscale that have NIRUX, or [fleet] hosts/exclude in $FLEET_CONFIG."
}
fleet_cleanup() { [ -z "$FLEET_WORK" ] || rm -rf "$FLEET_WORK"; }
fleet_work() {
  [ -z "$FLEET_WORK" ] || return 0
  FLEET_WORK=$(mktemp -d "${TMPDIR:-/tmp}/nirux-fleet.XXXXXX") || die 'could not create a temporary directory'
  trap fleet_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
}
# A host name goes to ssh as an argument, so it must look like one (and can
# never start with "-", which ssh would read as an option).
fleet_valid_host() {
  case "$1" in ''|-*|*[!A-Za-z0-9._@-]*) return 1 ;; *) return 0 ;; esac
}
# The strings of array KEY ($3) in table [$2] of TOML file $1, one per line.
# Arrays may span lines; an absent file or key prints nothing (the default).
fleet_config_list() { toml_list "$FLEET_CONFIG" fleet "$1"; }
toml_list() {
  [ -f "$1" ] || return 0
  awk -v table="$2" -v want="$3" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function emit(v) {
      while (match(v, /"[^"]*"|\047[^\047]*\047/)) {
        print substr(v, RSTART + 1, RLENGTH - 2); v = substr(v, RSTART + RLENGTH)
      }
    }
    { line = $0; sub(/#.*/, "", line) }
    collecting { buf = buf " " line; if (index(line, "]")) { emit(buf); collecting = 0 }; next }
    line ~ /^[[:space:]]*\[/ { s = line; gsub(/[][[:space:]]/, "", s); sec = s; next }
    sec != table { next }
    {
      eq = index(line, "="); if (eq == 0) next
      key = trim(substr(line, 1, eq - 1)); gsub(/"/, "", key)
      if (key != want) next
      buf = substr(line, eq + 1)
      if (index(buf, "]")) emit(buf); else collecting = 1
    }' "$1" 2>/dev/null || :
}
# Linux peers as "peer NAME ONLINE" and this machine as "self NAME 1".
# FLEET_NOTE says why Tailscale could not be used.
fleet_tailscale() {
  FLEET_NOTE=
  if ! command -v tailscale >/dev/null 2>&1; then FLEET_NOTE='tailscale is not installed'; return 1; fi
  if ! command -v python3 >/dev/null 2>&1; then FLEET_NOTE='python3 is missing, so tailscale status cannot be read'; return 1; fi
  if ! fleet_timeout 10 tailscale status --json > "$FLEET_WORK/tailscale.json" 2>/dev/null; then
    FLEET_NOTE='tailscale is not running'; return 1
  fi
  python3 -I -c '
import json, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    sys.exit(2)
if d.get("BackendState") != "Running":
    sys.exit(3)
def name(p):
    return (p.get("DNSName") or "").split(".")[0] or p.get("HostName") or ""
print("self\t%s\t1" % name(d.get("Self") or {}))
for p in sorted((d.get("Peer") or {}).values(), key=name):
    if (p.get("OS") or "").lower() == "linux" and name(p):
        print("peer\t%s\t%d" % (name(p), 1 if p.get("Online") else 0))
' < "$FLEET_WORK/tailscale.json" > "$FLEET_WORK/peers" 2>/dev/null || {
    FLEET_NOTE='tailscale is not running or not logged in'; return 1
  }
}
fleet_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$@"; else shift; "$@"; fi
}
# Runs on each host through `sh -s`. Prints key=value lines and never asks for
# anything: it only reads files and the process table.
fleet_probe_script() {
  cat <<'PROBE'
n=$HOME/.local/bin/nirux
if [ ! -e "$n" ]; then echo nirux=absent; exit 0; fi
echo nirux=present
echo "version=$(sed -n 's/^VERSION=//p' "$n" 2>/dev/null | head -n 1)"
gen=$(readlink -f "$HOME/.local/share/nirux/current" 2>/dev/null || :)
uid=$(id -u)
session=0 stale=
for p in niruwm nirubar; do
  for pid in $(pgrep -u "$uid" -x "$p" 2>/dev/null); do
    session=1
    exe=$(readlink "/proc/$pid/exe" 2>/dev/null) || continue
    [ -n "$gen" ] || { stale="$stale $p"; continue; }
    case "$exe" in "$gen"/*) continue ;; esac
    # A program the update did not change is the same file in the new
    # generation; only a different binary needs a new session.
    if [ -f "$exe" ] && [ -f "$gen/bin/$p" ] &&
       [ "$(sha256sum < "$exe" 2>/dev/null)" = "$(sha256sum < "$gen/bin/$p" 2>/dev/null)" ]; then continue; fi
    case "$stale " in *" $p "*) ;; *) stale="$stale $p" ;; esac
  done
done
echo "session=$session"
echo "relogin=${stale# }"
if pgrep -u "$uid" -x nirulock >/dev/null 2>&1; then echo locked=1; else echo locked=0; fi
# Health: disk use of the home file system, failed systemd units (system and
# user; none on runit), other seat0 sessions left over beside the one that
# runs niruwm, and whether locking can work (binary, PAM file, idle locker).
df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 { sub("%", "", $5); print "disk=" $5; print "disk_free_kib=" $4 }'
if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
  echo "failed=$(( $(systemctl --failed --no-legend --plain 2>/dev/null | grep -c .) + $(systemctl --user --failed --no-legend --plain 2>/dev/null | grep -c .) ))"
fi
wm=$(pgrep -u "$uid" -x niruwm 2>/dev/null | head -n 1)
if [ -n "$wm" ] && command -v loginctl >/dev/null 2>&1; then
  sid=$(cat "${NIRUX_FLEET_PROC:-/proc}/$wm/sessionid" 2>/dev/null)
  case "$sid" in ''|4294967295) ;; *)
    echo "stale_sessions=$(loginctl list-sessions --no-legend 2>/dev/null |
      awk -v u="$(id -un)" -v s="$sid" '$3 == u && $4 == "seat0" && $1 != s { n++ } END { print n + 0 }')" ;;
  esac
fi
lock=ok
if [ ! -x "${gen:-/nonexistent}/bin/nirulock" ] && ! command -v nirulock >/dev/null 2>&1; then lock=no-nirulock
elif [ ! -f "${NIRUX_FLEET_PAM:-/etc/pam.d/nirulock}" ]; then lock=no-pam
elif [ "$session" = 1 ] && ! grep -qs '^[[:space:]]*START_IDLE=["'\'']\{0,1\}0' "$HOME/.config/niruwm/session.conf" &&
     ! pgrep -u "$uid" -x niruidle >/dev/null 2>&1; then lock=no-idle
fi
echo "lock=$lock"
(. /etc/os-release 2>/dev/null; echo "distro=${ID:-unknown}${VERSION_ID:+ $VERSION_ID}")
echo "uptime=$(cut -d. -f1 /proc/uptime 2>/dev/null)"
echo "updated=$(stat -c %Y "$HOME/.local/share/nirux/current" 2>/dev/null)"
echo "extras=$(grep -c . "$HOME/.local/share/nirux/extras-selected" 2>/dev/null)"
echo "now=$(date +%s)"
PROBE
}
# Probe one host into $FLEET_WORK/probe.NAME; LOCAL=1 runs it here.
fleet_probe() {
  fleet_out=$FLEET_WORK/probe.$1
  fleet_rc=0
  if [ "$2" = 1 ]; then
    fleet_probe_script | sh -s > "$fleet_out" 2> "$fleet_out.err" || fleet_rc=$?
  else
    fleet_probe_script | fleet_timeout "$((${NIRUX_FLEET_TIMEOUT:-5} + 10))" \
      ssh -o BatchMode=yes -o ConnectTimeout="${NIRUX_FLEET_TIMEOUT:-5}" "$1" sh -s \
      > "$fleet_out" 2> "$fleet_out.err" || fleet_rc=$?
  fi
  echo "rc=$fleet_rc" >> "$fleet_out"
}
fleet_field() { sed -n "s/^$2=//p" "$FLEET_WORK/probe.$1" 2>/dev/null | head -n 1 | tr -d '|\t'; }
# 0 when version $1 is older than $2.
fleet_older() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, x, "."); nb = split(b, y, "."); n = na > nb ? na : nb
    for (i = 1; i <= n; i++) { if (x[i] + 0 < y[i] + 0) exit 0; if (x[i] + 0 > y[i] + 0) exit 1 }
    exit 1 }'
}
fleet_age() {
  [ -n "$1" ] || { say -; return; }
  fleet_s=$1
  if [ "$fleet_s" -lt 0 ] 2>/dev/null; then fleet_s=0; fi
  if [ "$fleet_s" -ge 86400 ]; then say "$((fleet_s / 86400))d$((fleet_s % 86400 / 3600))h"
  elif [ "$fleet_s" -ge 3600 ]; then say "$((fleet_s / 3600))h$((fleet_s % 3600 / 60))m"
  else say "$((fleet_s / 60))m"
  fi
}
# Decide the host list: "NAME ONLINE LOCAL" in $FLEET_WORK/hosts, where ONLINE
# is 1, 0 (Tailscale says offline) or ? (unknown, probe it).
fleet_hosts() {
  : > "$FLEET_WORK/hosts"
  : > "$FLEET_WORK/hidden-offline"
  FLEET_SELF=
  fleet_ts=0
  if fleet_tailscale; then
    fleet_ts=1
    FLEET_SELF=$(awk -F '\t' '$1 == "self" { print $2; exit }' "$FLEET_WORK/peers")
  fi
  fleet_config_list hosts > "$FLEET_WORK/cfg-hosts"
  fleet_config_list exclude > "$FLEET_WORK/cfg-exclude"
  FLEET_FROM=tailscale
  fleet_myname=$(uname -n)
  if [ -s "$FLEET_WORK/cfg-hosts" ]; then
    FLEET_FROM=config
    while read -r fleet_h; do
      fleet_valid_host "$fleet_h" || { say "nirux fleet: ignoring invalid host name in $FLEET_CONFIG: $fleet_h" >&2; continue; }
      fleet_on='?'
      if [ "$fleet_ts" = 1 ]; then
        fleet_on=$(awk -F '\t' -v h="${fleet_h#*@}" '$1 == "peer" && $2 == h { print $3; exit }' "$FLEET_WORK/peers")
        [ -n "$fleet_on" ] || fleet_on='?'
      fi
      fleet_local=0
      if { [ -n "$FLEET_SELF" ] && [ "${fleet_h#*@}" = "$FLEET_SELF" ]; } || [ "${fleet_h#*@}" = "$fleet_myname" ]; then
        fleet_local=1; fleet_on=1
      fi
      say "$fleet_h $fleet_on $fleet_local" >> "$FLEET_WORK/hosts"
    done < "$FLEET_WORK/cfg-hosts"
  elif [ "$fleet_ts" = 1 ]; then
    [ -z "$FLEET_SELF" ] || say "$FLEET_SELF 1 1" >> "$FLEET_WORK/hosts"
    while IFS="$(printf '\t')" read -r fleet_kind fleet_h fleet_on; do
      [ "$fleet_kind" = peer ] && fleet_valid_host "$fleet_h" || continue
      # An offline peer cannot be asked whether it has NIRUX; list it when it
      # was seen with NIRUX before, so a laptop that is away still shows up.
      if [ "$fleet_on" = 0 ] && ! awk -v h="$fleet_h" '$1 == h { f = 1 } END { exit !f }' "$FLEET_KNOWN" 2>/dev/null; then
        say "$fleet_h" >> "$FLEET_WORK/hidden-offline"
        continue
      fi
      say "$fleet_h $fleet_on 0" >> "$FLEET_WORK/hosts"
    done < "$FLEET_WORK/peers"
  else
    FLEET_FROM=none
  fi
  if [ -s "$FLEET_WORK/cfg-exclude" ]; then
    awk 'NR == FNR { x[$1] = 1; next } !($1 in x)' "$FLEET_WORK/cfg-exclude" "$FLEET_WORK/hosts" > "$FLEET_WORK/hosts.new"
    mv -f "$FLEET_WORK/hosts.new" "$FLEET_WORK/hosts"
    awk 'NR == FNR { x[$1] = 1; next } !($1 in x)' "$FLEET_WORK/cfg-exclude" "$FLEET_WORK/hidden-offline" > "$FLEET_WORK/hidden.new"
    mv -f "$FLEET_WORK/hidden.new" "$FLEET_WORK/hidden-offline"
  fi
}
fleet_num() { case "$1" in ''|*[!0-9]*) ;; *) say "$1" ;; esac; }
# Probe all hosts in parallel and the latest release once, then write one
# |-separated row per host to $FLEET_WORK/rows:
# name|local|state|version|latest|behind|relogin|session|locked|distro|uptime|updated|extras|last_version|last_seen|disk|disk_free_kib|failed|stale_sessions|lock
fleet_collect() {
  fleet_hosts
  (NIRUX_FETCH_ATTEMPTS=${NIRUX_FETCH_ATTEMPTS:-2}
   fetch https://api.github.com/repos/nirucon/nirux/releases/latest "$FLEET_WORK/latest.json") >/dev/null 2>&1 &
  while read -r fleet_h fleet_on fleet_local; do
    [ "$fleet_on" = 0 ] || fleet_probe "$fleet_h" "$fleet_local" &
  done < "$FLEET_WORK/hosts"
  wait
  FLEET_LATEST=$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][0-9.]*\)".*/\1/p' "$FLEET_WORK/latest.json" 2>/dev/null | head -n 1)
  fleet_now=$(date +%s)
  : > "$FLEET_WORK/rows"
  : > "$FLEET_WORK/hidden-nonirux"
  while read -r fleet_h fleet_on fleet_local; do
    fleet_classify "$fleet_h" "$fleet_on" "$fleet_local" "$FLEET_FROM"
  done < "$FLEET_WORK/hosts"
  fleet_remember
}
# Turn the probe of host $1 (Tailscale online state $2, local $3) into a row.
# With source $4 = tailscale, a host that answers without NIRUX is not part of
# the fleet and is only named below the table.
fleet_classify() {
  fleet_ver='' fleet_behind='' fleet_rel='' fleet_sess='' fleet_lock='' fleet_dist='' fleet_up='' fleet_upd='' fleet_ext=''
  fleet_lastv='' fleet_seen='' fleet_disk='' fleet_dfree='' fleet_failed='' fleet_stale='' fleet_lockok=''
  if [ "$2" = 0 ]; then
    fleet_state=offline
  else
    fleet_err=$FLEET_WORK/probe.$1.err
    fleet_present=$(fleet_field "$1" nirux)
    if [ "$fleet_present" = present ]; then
      fleet_state=online
      fleet_ver=$(fleet_field "$1" version)
      fleet_rel=$(fleet_field "$1" relogin)
      fleet_sess=$(fleet_field "$1" session)
      fleet_lock=$(fleet_field "$1" locked)
      fleet_dist=$(fleet_field "$1" distro)
      fleet_up=$(fleet_num "$(fleet_field "$1" uptime)")
      fleet_upd=$(fleet_num "$(fleet_field "$1" updated)")
      fleet_ext=$(fleet_num "$(fleet_field "$1" extras)")
      fleet_rnow=$(fleet_num "$(fleet_field "$1" now)")
      fleet_disk=$(fleet_num "$(fleet_field "$1" disk)")
      fleet_dfree=$(fleet_num "$(fleet_field "$1" disk_free_kib)")
      fleet_failed=$(fleet_num "$(fleet_field "$1" failed)")
      fleet_stale=$(fleet_num "$(fleet_field "$1" stale_sessions)")
      fleet_lockok=$(fleet_field "$1" lock | tr -cd 'a-z-')
      # Age on the host's own clock, so clock skew does not matter.
      if [ -n "$fleet_upd" ] && [ -n "$fleet_rnow" ]; then fleet_upd=$((fleet_rnow - fleet_upd)); else fleet_upd=; fi
      if [ -n "$FLEET_LATEST" ] && [ -n "$fleet_ver" ]; then
        if fleet_older "$fleet_ver" "$FLEET_LATEST"; then fleet_behind=1; else fleet_behind=0; fi
      fi
    elif [ "$fleet_present" = absent ]; then
      fleet_state=nonirux
    elif grep -qiE 'permission denied|host key verification failed|too many authentication' "$fleet_err" 2>/dev/null; then
      fleet_state=noaccess
    elif grep -qiE 'timed out|no route to host|could not resolve|name or service not known|network is unreachable' "$fleet_err" 2>/dev/null ||
         [ "$(fleet_field "$1" rc)" = 124 ] || [ "$2" != 1 ]; then
      fleet_state=offline
    else
      fleet_state=noaccess
    fi
  fi
  if [ "$fleet_state" = offline ]; then
    fleet_lastv=$(awk -v h="$1" '$1 == h { print $2 }' "$FLEET_KNOWN" 2>/dev/null | tail -n 1)
    fleet_seen=$(fleet_num "$(awk -v h="$1" '$1 == h { print $3 }' "$FLEET_KNOWN" 2>/dev/null | tail -n 1)")
    [ -z "$fleet_seen" ] || fleet_seen=$((fleet_now - fleet_seen))
  fi
  if [ "$fleet_state" = nonirux ] && [ "$4" = tailscale ]; then
    say "$1" >> "$FLEET_WORK/hidden-nonirux"; return 0
  fi
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$1" "$3" "$fleet_state" "$fleet_ver" "$FLEET_LATEST" \
    "$fleet_behind" "$fleet_rel" "$fleet_sess" "$fleet_lock" "$fleet_dist" "$fleet_up" "$fleet_upd" "$fleet_ext" \
    "$fleet_lastv" "$fleet_seen" "$fleet_disk" "$fleet_dfree" "$fleet_failed" "$fleet_stale" "$fleet_lockok" >> "$FLEET_WORK/rows"
}
# Remember the hosts seen with NIRUX: "NAME VERSION EPOCH".
fleet_remember() {
  awk -F '|' '$3 == "online" { print $1, $4 }' "$FLEET_WORK/rows" > "$FLEET_WORK/seen"
  [ -s "$FLEET_WORK/seen" ] || return 0
  mkdir -p "$STATE" 2>/dev/null || return 0
  { [ ! -f "$FLEET_KNOWN" ] || cat "$FLEET_KNOWN"; } |
    awk -v now="$fleet_now" 'NR == FNR { s[$1] = $2; next } !($1 in s) { print } END { for (h in s) print h, s[h], now }' \
      "$FLEET_WORK/seen" - | LC_ALL=C sort > "$FLEET_KNOWN.tmp.$$" &&
    mv -f "$FLEET_KNOWN.tmp.$$" "$FLEET_KNOWN" || rm -f "$FLEET_KNOWN.tmp.$$"
}
fleet_note() {
  if [ "$FLEET_FROM" = none ]; then
    say "Note: $FLEET_NOTE, and $FLEET_CONFIG lists no hosts."
    say "Add [fleet] hosts = [\"HOST\", ...] there, or start Tailscale."
  elif [ "$FLEET_FROM" = config ] && [ -n "$FLEET_NOTE" ]; then
    say "Note: $FLEET_NOTE; using the hosts in $FLEET_CONFIG."
  fi
}
fleet_status() {
  fleet_json=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --json) fleet_json=1 ;;
      --help|-h) fleet_usage; return 0 ;;
      *) die "unknown option for fleet status: $1" ;;
    esac
    shift
  done
  fleet_work
  fleet_collect
  if [ "$fleet_json" = 1 ]; then fleet_print_json; return 0; fi
  fleet_note
  fleet_apply_pending 1
  [ -s "$FLEET_WORK/rows" ] || { say 'No NIRUX hosts found.'; return 0; }
  fleet_print_table
  if [ -s "$FLEET_WORK/hidden-offline" ]; then
    say "Offline, never seen with NIRUX (not listed): $(tr '\n' ' ' < "$FLEET_WORK/hidden-offline")"
  fi
  if [ -s "$FLEET_WORK/hidden-nonirux" ]; then
    say "Reachable without NIRUX (not listed): $(tr '\n' ' ' < "$FLEET_WORK/hidden-nonirux")"
  fi
  if awk -F '|' '$3 == "noaccess" { f = 1 } END { exit !f }' "$FLEET_WORK/rows"; then
    say 'No access: no SSH key login from this machine. Run nirux fleet setup [HOST...],'
    say "or list a machine that is not a NIRUX desktop under exclude in $FLEET_CONFIG."
  fi
  [ -n "$FLEET_LATEST" ] || say 'Latest release unknown (GitHub could not be reached).'
  [ ! -s "$FLEET_PENDING" ] || say "Waiting for offline hosts: $(cut -f 1 "$FLEET_PENDING" | sort -u | tr '\n' ' ')(nirux fleet pending)"
}
# One short health summary from disk use %, free KiB, failed units, stale
# sessions and lock state: "ok" or the problems, comma separated.
fleet_health() {
  fleet_hp=
  if [ -n "$1" ] && { [ "$1" -ge "${NIRUX_FLEET_DISK_WARN:-90}" ] || { [ -n "$2" ] && [ "$2" -lt 5242880 ]; }; }; then
    fleet_hp="disk $1%"
  fi
  if [ -n "$3" ] && [ "$3" -gt 0 ]; then fleet_hp="${fleet_hp:+$fleet_hp, }$3 failed unit$( [ "$3" = 1 ] || say s)"; fi
  if [ -n "$4" ] && [ "$4" -gt 0 ]; then fleet_hp="${fleet_hp:+$fleet_hp, }$4 stale session$( [ "$4" = 1 ] || say s)"; fi
  case "$5" in
    ''|ok) ;;
    no-pam) fleet_hp="${fleet_hp:+$fleet_hp, }lock: no PAM file" ;;
    no-idle) fleet_hp="${fleet_hp:+$fleet_hp, }lock: niruidle not running" ;;
    no-nirulock) fleet_hp="${fleet_hp:+$fleet_hp, }lock: nirulock missing" ;;
    *) fleet_hp="${fleet_hp:+$fleet_hp, }lock: $5" ;;
  esac
  say "${fleet_hp:-ok}"
}
fleet_print_table() {
  {
    printf 'HOST\tSTATE\tNIRUX\tBEHIND\tRELOGIN\tLOCKED\tDISTRO\tUP\tUPDATED\tHEALTH\n'
    while IFS='|' read -r h loc st ver lat beh rel ses lck dis up upd ext lastv seen dsk dfr fai stl lok; do
      [ "$loc" = 1 ] && h="$h (this)"
      case "$st" in
        online)
          case "$beh" in 1) beh="yes ($lat)" ;; 0) beh=no ;; *) beh='?' ;; esac
          if [ -n "$rel" ]; then rel="yes: $rel"
          elif [ "$ses" = 1 ]; then rel=no
          else rel='no session'; fi
          [ "$lck" = 1 ] && lck=yes || lck=no
          printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$h" online "${ver:-?}" "$beh" "$rel" "$lck" "${dis:-?}" \
            "$(fleet_age "$up")" "$( [ -n "$upd" ] && say "$(fleet_age "$upd") ago" || say - )" \
            "$(fleet_health "$dsk" "$dfr" "$fai" "$stl" "$lok")" ;;
        offline)
          if [ -n "$lastv" ]; then
            printf '%s\t%s\t%s\t-\t-\t-\t-\t-\t%s\n' "$h" offline "($lastv)" "seen $(fleet_age "$seen") ago"
          else printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\n' "$h" offline; fi ;;
        noaccess) printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\n' "$h" 'no access (run nirux fleet setup)' ;;
        nonirux) printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\n' "$h" 'no NIRUX' ;;
      esac
    done < "$FLEET_WORK/rows"
  } | awk -F '\t' '
    { for (i = 1; i <= NF; i++) { c[NR, i] = $i; if (length($i) > w[i]) w[i] = length($i) } n = NR; if (NF > m) m = NF }
    END { for (r = 1; r <= n; r++) { line = ""
      for (i = 1; i <= m; i++) line = line (i < m ? sprintf("%-" (w[i] + 2) "s", c[r, i]) : c[r, i])
      print line } }'
}
fleet_json_value() {
  if [ -z "$2" ]; then printf 'null'; return; fi
  case "$1" in
    bool) [ "$2" = 1 ] && printf true || printf false ;;
    num) printf '%s' "$2" ;;
    str) sounds_json_string "$2" ;;
  esac
}
fleet_print_json() {
  printf '{"schema":1,"source":%s,' "$(sounds_json_string "$FLEET_FROM")"
  printf '"note":%s,' "$(fleet_json_value str "$FLEET_NOTE")"
  printf '"latest":%s,"hosts":[' "$(fleet_json_value str "$FLEET_LATEST")"
  fleet_sep=
  while IFS='|' read -r h loc st ver lat beh rel ses lck dis up upd ext lastv seen dsk dfr fai stl lok; do
    fleet_relb=
    if [ "$st" = online ]; then
      if [ -n "$rel" ]; then fleet_relb=1; else fleet_relb=0; fi
    fi
    fleet_progs=
    for fleet_p in $rel; do fleet_progs="${fleet_progs:+$fleet_progs,}$(sounds_json_string "$fleet_p")"; done
    [ "$st" = noaccess ] && st=no-access
    [ "$st" = nonirux ] && st=no-nirux
    printf '%s{"host":%s,"local":%s,"state":%s,"version":%s,"behind":%s,"relogin":%s,"relogin_programs":[%s],' \
      "$fleet_sep" "$(sounds_json_string "$h")" "$(fleet_json_value bool "$loc")" "$(sounds_json_string "$st")" \
      "$(fleet_json_value str "$ver")" "$(fleet_json_value bool "$beh")" "$(fleet_json_value bool "$fleet_relb")" "$fleet_progs"
    printf '"session":%s,"locked":%s,"distro":%s,"uptime_seconds":%s,"updated_seconds_ago":%s,"extras":%s,"last_version":%s,"last_seen_seconds_ago":%s' \
      "$(fleet_json_value bool "$ses")" "$(fleet_json_value bool "$lck")" "$(fleet_json_value str "$dis")" \
      "$(fleet_json_value num "$up")" "$(fleet_json_value num "$upd")" "$(fleet_json_value num "$ext")" \
      "$(fleet_json_value str "$lastv")" "$(fleet_json_value num "$seen")"
    if [ "$st" = online ]; then
      printf ',"health":{"summary":%s,"disk_percent":%s,"disk_free_kib":%s,"failed_units":%s,"stale_sessions":%s,"lock":%s}' \
        "$(sounds_json_string "$(fleet_health "$dsk" "$dfr" "$fai" "$stl" "$lok")")" "$(fleet_json_value num "$dsk")" \
        "$(fleet_json_value num "$dfr")" "$(fleet_json_value num "$fai")" "$(fleet_json_value num "$stl")" \
        "$(fleet_json_value str "$lok")"
    fi
    printf '}'
    fleet_sep=,
  done < "$FLEET_WORK/rows"
  printf ']}\n'
}
fleet_row_field() { awk -F '|' -v h="$1" -v f="$2" '$1 == h { print $f; exit }' "$FLEET_WORK/rows"; }
# Run a NIRUX command on a host with a terminal, so sudo asks there. The
# command is a plain program path relative to the remote home: no shell syntax.
fleet_run() {
  fleet_rh=$1; shift
  if [ "$(fleet_row_field "$fleet_rh" 2)" = 1 ]; then "$HOME/.local/bin/nirux" "$@"
  else ssh -t "$fleet_rh" .local/bin/nirux "$@"
  fi
}
fleet_update() {
  fleet_mode=
  fleet_targets=
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --all) fleet_mode=all ;;
      --behind) fleet_mode=behind ;;
      --help|-h) fleet_usage; return 0 ;;
      -*) die "unknown option for fleet update: $1" ;;
      *) fleet_valid_host "$1" || die "invalid host name: $1"; fleet_targets="$fleet_targets $1" ;;
    esac
    shift
  done
  [ -n "$fleet_mode" ] || [ -n "$fleet_targets" ] || die 'usage: nirux fleet update HOST...|--all|--behind'
  [ -z "$fleet_mode" ] || [ -z "$fleet_targets" ] || die 'give host names or --all/--behind, not both'
  [ -t 0 ] || say 'nirux fleet: not a terminal; sudo on the hosts may be unable to ask for a password.' >&2
  fleet_work
  say 'Checking the fleet...'
  fleet_collect
  fleet_note
  if [ -n "$fleet_mode" ]; then
    fleet_targets=$(awk -F '|' -v m="$fleet_mode" '$3 == "online" && (m == "all" || $6 == "1") { print $1 }' "$FLEET_WORK/rows" | tr '\n' ' ')
    [ "$fleet_mode" != behind ] || [ -n "$FLEET_LATEST" ] || die 'latest release unknown (GitHub could not be reached); name the hosts instead'
    [ -n "$fleet_targets" ] || { say "No online host to update (--$fleet_mode)."; return 0; }
  fi
  # A named host outside the discovered fleet is still checked before use.
  for fleet_h in $fleet_targets; do
    [ -z "$(fleet_row_field "$fleet_h" 1)" ] || continue
    fleet_probe "$fleet_h" 0
    fleet_classify "$fleet_h" '?' 0 config
  done
  fleet_failed='' fleet_done='' fleet_skipped=''
  for fleet_h in $fleet_targets; do
    fleet_st=$(fleet_row_field "$fleet_h" 3)
    case "$fleet_st" in
      online) ;;
      offline) say "== $fleet_h: offline, skipped"; fleet_skipped="$fleet_skipped $fleet_h"; continue ;;
      noaccess) say "== $fleet_h: no SSH access, skipped (run nirux fleet setup $fleet_h)"; fleet_skipped="$fleet_skipped $fleet_h"; continue ;;
      nonirux) say "== $fleet_h: NIRUX is not installed there, skipped"; fleet_skipped="$fleet_skipped $fleet_h"; continue ;;
      *) say "== $fleet_h: not a known fleet host, skipped"; fleet_skipped="$fleet_skipped $fleet_h"; continue ;;
    esac
    say "== $fleet_h: nirux update (from $(fleet_row_field "$fleet_h" 4))"
    fleet_ok=1
    fleet_run "$fleet_h" update || fleet_ok=0
    # `nirux update` does not touch extras; update the selected ones too, as
    # a normal update round does.
    if [ "$fleet_ok" = 1 ] && [ "$(fleet_row_field "$fleet_h" 13)" -gt 0 ] 2>/dev/null; then
      say "== $fleet_h: nirux extras update"
      fleet_run "$fleet_h" extras update || fleet_ok=0
    fi
    fleet_probe "$fleet_h" "$(fleet_row_field "$fleet_h" 2)"
    fleet_after=$(fleet_field "$fleet_h" version)
    fleet_rel=$(fleet_field "$fleet_h" relogin)
    if [ "$fleet_ok" = 1 ]; then
      fleet_done="$fleet_done $fleet_h"
      fleet_msg="== $fleet_h: updated, now ${fleet_after:-?}"
    else
      fleet_failed="$fleet_failed $fleet_h"
      fleet_msg="== $fleet_h: FAILED, still ${fleet_after:-?}"
    fi
    if [ -n "$fleet_rel" ]; then fleet_msg="$fleet_msg; relogin needed ($fleet_rel); nothing was logged out"
    elif [ "$(fleet_field "$fleet_h" session)" = 1 ]; then fleet_msg="$fleet_msg; running session is current"
    fi
    say "$fleet_msg"
  done
  say "Fleet update: updated:${fleet_done:- none}; failed:${fleet_failed:- none}; skipped:${fleet_skipped:- none}"
  [ -z "$fleet_failed" ]
}
fleet_setup() {
  fleet_targets=
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h) fleet_usage; return 0 ;;
      -*) die "unknown option for fleet setup: $1" ;;
      *) fleet_valid_host "$1" || die "invalid host name: $1"; fleet_targets="$fleet_targets $1" ;;
    esac
    shift
  done
  command -v ssh >/dev/null 2>&1 || die 'install ssh (the OpenSSH client) first'
  command -v ssh-copy-id >/dev/null 2>&1 || die 'ssh-copy-id is missing (it comes with the OpenSSH client)'
  fleet_work
  if [ -z "$fleet_targets" ]; then
    say 'Checking the fleet...'
    fleet_collect
    fleet_note
    fleet_targets=$(awk -F '|' '$3 == "noaccess" { print $1 }' "$FLEET_WORK/rows" | tr '\n' ' ')
    [ -n "$fleet_targets" ] || { say 'Every online host already accepts this key; nothing to set up.'; return 0; }
  fi
  fleet_key=$HOME/.ssh/id_ed25519
  say 'nirux fleet setup will:'
  if [ -f "$fleet_key.pub" ]; then say "  - use your existing key $fleet_key.pub"
  else say "  - create an ed25519 key $fleet_key (ssh-keygen asks for an optional passphrase)"; fi
  # shellcheck disable=SC2086 # one word per host
  say "  - copy the public key to: $(printf '%s ' $fleet_targets | sed 's/ $//')"
  say '    (ssh-copy-id asks for your password on each host once)'
  say '  - check that each host then accepts the key (ssh -o BatchMode=yes HOST true)'
  say 'It changes no Tailscale, sshd or PAM settings.'
  printf 'Continue? [y/N] '
  read -r fleet_answer || fleet_answer=
  case "$fleet_answer" in y|Y|yes|YES) ;; *) say 'Cancelled.'; return 1 ;; esac
  if [ ! -f "$fleet_key.pub" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$fleet_key" -C "$(id -un)@$(hostname 2>/dev/null || uname -n) nirux fleet" || die 'ssh-keygen failed'
  fi
  fleet_failed=
  for fleet_h in $fleet_targets; do
    say "== $fleet_h"
    if ssh-copy-id -i "$fleet_key.pub" "$fleet_h" &&
       ssh -o BatchMode=yes -o ConnectTimeout="${NIRUX_FLEET_TIMEOUT:-5}" "$fleet_h" true; then
      say "== $fleet_h: key login works"
    else
      say "== $fleet_h: FAILED (key login still does not work)"
      fleet_failed="$fleet_failed $fleet_h"
    fi
  done
  [ -z "$fleet_failed" ] || { say "Setup failed for:$fleet_failed"; return 1; }
  say 'All hosts accept the key. Try: nirux fleet status'
}
# Quote $1 for sh: the value travels to the host inside a script on stdin,
# never on the ssh command line, which a fish login shell would parse.
fleet_quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
# The script that sets KEY ($1) to VALUE ($2) on a host. The running session's
# DISPLAY is borrowed, so NIRUWM reloads at once even over SSH.
fleet_set_script() {
  case "$1" in
    screensaver.*) fs_cmd="\"\$HOME/.local/bin/niruscreensaver\" --set $(fleet_quote "${1#screensaver.}") $(fleet_quote "$2")" ;;
    *) fs_cmd="\"\$HOME/.local/bin/niructl\" config set $(fleet_quote "$1") $(fleet_quote "$2") --yes" ;;
  esac
  cat <<SCRIPT
if [ -z "\${DISPLAY:-}" ]; then
  wm=\$(pgrep -o -u "\$(id -u)" -x niruwm 2>/dev/null)
  if [ -n "\$wm" ] && [ -r "/proc/\$wm/environ" ]; then
    for v in DISPLAY XAUTHORITY; do
      x=\$(tr '\\0' '\\n' < "/proc/\$wm/environ" | sed -n "s/^\$v=//p" | head -n 1)
      [ -z "\$x" ] || export "\$v=\$x"
    done
  fi
fi
$fs_cmd < /dev/null
SCRIPT
}
# A KEY is section.key (or a top-level key) in bare TOML names.
fleet_valid_key() {
  case "$1" in ''|.*|*.|*..*|*[!A-Za-z0-9_.-]*) return 1 ;; *) return 0 ;; esac
}
# Set KEY ($3) to VALUE ($4) on host $1 (LOCAL $2 = 1 runs it here).
# The tool's own output is kept in $FLEET_WORK/set.$1 for a failure report.
fleet_set_one() {
  fs_out=$FLEET_WORK/set.$1
  if [ "$2" = 1 ]; then
    fleet_set_script "$3" "$4" | sh -s > "$fs_out" 2>&1
  else
    fleet_set_script "$3" "$4" | fleet_timeout 60 \
      ssh -o BatchMode=yes -o ConnectTimeout="${NIRUX_FLEET_TIMEOUT:-5}" "$1" sh -s > "$fs_out" 2>&1
  fi
}
fleet_set_failed() {
  say "== $1: FAILED: $(grep -v '^[-+@ ]' "$FLEET_WORK/set.$1" 2>/dev/null | grep . | tail -n 1)"
}
# Queue KEY=VALUE for an offline host; a newer value for the same key wins.
fleet_queue() {
  mkdir -p "$STATE" || return 1
  { [ ! -f "$FLEET_PENDING" ] || awk -F '\t' -v h="$1" -v k="$2" '!($1 == h && $2 == k)' "$FLEET_PENDING"
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(date +%s)"; } > "$FLEET_PENDING.tmp.$$" &&
    mv -f "$FLEET_PENDING.tmp.$$" "$FLEET_PENDING"
}
# Apply queued settings to the hosts in $FLEET_WORK/rows that are online now.
# QUIET ($1 = 1) prints only what was applied or failed.
fleet_apply_pending() {
  [ -s "$FLEET_PENDING" ] || return 0
  fp_keep=$FLEET_WORK/pending.keep
  : > "$fp_keep"
  fp_tab=$(printf '\t')
  while IFS="$fp_tab" read -r fp_h fp_k fp_v fp_t; do
    fp_state=$(fleet_row_field "$fp_h" 3)
    if [ "$fp_state" = online ]; then
      if fleet_set_one "$fp_h" "$(fleet_row_field "$fp_h" 2)" "$fp_k" "$fp_v"; then
        say "== $fp_h: $fp_k = $fp_v (waiting since it was offline)"
        continue
      fi
      fleet_set_failed "$fp_h"
    elif [ "$fp_state" = nonirux ]; then
      [ "${1:-0}" = 1 ] || say "== $fp_h: NIRUX is gone there; dropped $fp_k"
      continue
    fi
    printf '%s\t%s\t%s\t%s\n' "$fp_h" "$fp_k" "$fp_v" "$fp_t" >> "$fp_keep"
  done < "$FLEET_PENDING"
  if [ -s "$fp_keep" ]; then mv -f "$fp_keep" "$FLEET_PENDING"; else rm -f "$FLEET_PENDING" "$fp_keep"; fi
}
# At login and wake-up (NIRUWM's whats-new and resume-check hooks): deliver
# waiting settings in the background, logged to $STATE/fleet-pending.log.
fleet_pending_background() {
  [ -s "$FLEET_PENDING" ] || return 0
  fpb_self=$HOME/.local/bin/nirux
  [ -x "$fpb_self" ] || return 0
  (cd / && "$fpb_self" fleet pending apply --quiet >> "$STATE/fleet-pending.log" 2>&1 < /dev/null &) || :
}
fleet_set() {
  fs_key='' fs_value='' fs_hosts=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h) fleet_usage; return 0 ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  [ "$#" -ge 2 ] || die 'usage: nirux fleet set KEY VALUE [HOST...]'
  fs_key=$1 fs_value=$2; shift 2
  fleet_valid_key "$fs_key" || die "not a key: $fs_key (write section.key, for example idle.screensaver_timeout)"
  case "$fs_value" in *"$(printf '\t')"*|*"
"*) die 'a value cannot contain tabs or line breaks' ;; esac
  for fs_h in "$@"; do fleet_valid_host "$fs_h" || die "invalid host name: $fs_h"; fs_hosts="$fs_hosts $fs_h"; done
  fleet_work
  say 'Checking the fleet...'
  fleet_collect
  fleet_note
  fleet_apply_pending 1
  if [ -z "$fs_hosts" ]; then
    fs_hosts=$(awk -F '|' '$3 == "online" || $3 == "offline" || $3 == "noaccess" { print $1 }' "$FLEET_WORK/rows" | tr '\n' ' ')
    [ -n "$fs_hosts" ] || die 'no NIRUX hosts found (nirux fleet status)'
  fi
  for fs_h in $fs_hosts; do
    [ -z "$(fleet_row_field "$fs_h" 1)" ] || continue
    fleet_probe "$fs_h" 0
    fleet_classify "$fs_h" '?' 0 config
  done
  fs_done='' fs_queued='' fs_failed='' fs_skipped=''
  for fs_h in $fs_hosts; do
    case "$(fleet_row_field "$fs_h" 3)" in
      online)
        if fleet_set_one "$fs_h" "$(fleet_row_field "$fs_h" 2)" "$fs_key" "$fs_value"; then
          say "== $fs_h: $fs_key = $fs_value"
          fs_done="$fs_done $fs_h"
          # A value set now replaces an older one waiting for this host.
          if [ -f "$FLEET_PENDING" ]; then
            awk -F '\t' -v h="$fs_h" -v k="$fs_key" '!($1 == h && $2 == k)' "$FLEET_PENDING" > "$FLEET_PENDING.tmp.$$" &&
              mv -f "$FLEET_PENDING.tmp.$$" "$FLEET_PENDING"
          fi
        else
          fleet_set_failed "$fs_h"; fs_failed="$fs_failed $fs_h"
        fi ;;
      offline)
        fleet_queue "$fs_h" "$fs_key" "$fs_value" || die "could not write $FLEET_PENDING"
        say "== $fs_h: offline; set when it is next online"
        fs_queued="$fs_queued $fs_h" ;;
      noaccess) say "== $fs_h: no SSH access, skipped (nirux fleet setup $fs_h)"; fs_skipped="$fs_skipped $fs_h" ;;
      nonirux) say "== $fs_h: NIRUX is not installed there, skipped"; fs_skipped="$fs_skipped $fs_h" ;;
      *) say "== $fs_h: not a known fleet host, skipped"; fs_skipped="$fs_skipped $fs_h" ;;
    esac
  done
  say "Fleet set $fs_key: set:${fs_done:- none}; waiting:${fs_queued:- none}; failed:${fs_failed:- none}; skipped:${fs_skipped:- none}"
  [ -z "$fs_failed" ]
}
fleet_pending() {
  case "${1:-list}" in
    list)
      [ -s "$FLEET_PENDING" ] || { say 'No settings are waiting for an offline host.'; return 0; }
      say 'Waiting for these hosts to come online:'
      awk -F '\t' '{ printf "  %-16s %s = %s\n", $1, $2, $3 }' "$FLEET_PENDING" ;;
    apply)
      [ -s "$FLEET_PENDING" ] || return 0
      fleet_work
      fleet_collect
      fleet_apply_pending "$([ "${2:-}" = --quiet ] && echo 1 || echo 0)" ;;
    clear)
      [ -f "$FLEET_PENDING" ] || { say 'Nothing is waiting.'; return 0; }
      if [ -n "${2:-}" ]; then
        awk -F '\t' -v h="$2" '$1 != h' "$FLEET_PENDING" > "$FLEET_PENDING.tmp.$$" && mv -f "$FLEET_PENDING.tmp.$$" "$FLEET_PENDING"
        [ -s "$FLEET_PENDING" ] || rm -f "$FLEET_PENDING"
        say "Cleared the waiting settings for $2."
      else
        rm -f "$FLEET_PENDING"; say 'Cleared all waiting settings.'
      fi ;;
    *) die "unknown fleet pending command: $1 (apply or clear)" ;;
  esac
}
fleet_command() {
  fleet_action=${1:-status}
  [ "$#" = 0 ] || shift
  case "$fleet_action" in
    --json) fleet_status --json "$@" ;;
    status) fleet_status "$@" ;;
    update) fleet_update "$@" ;;
    setup) fleet_setup "$@" ;;
    set) fleet_set "$@" ;;
    pending) fleet_pending "$@" ;;
    --help|-h|help) fleet_usage ;;
    *) die "unknown fleet command: $fleet_action (status, update, setup, set or pending)" ;;
  esac
}
