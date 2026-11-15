# ── What's new (docs: manual chapter 11) ────────────────────────────────────
WHATS_NEW=$STATE/whats-new
WHATS_NEW_SHOWN=$STATE/whats-new-shown
# changelog_highlights FILE FROM TO: the bold lead phrase (or else the first
# sentence) of every bullet in the entries newer than FROM up to TO, newest
# first, at most six lines.
changelog_highlights() {
  [ -f "$1" ] || return 0
  awk -v from="$2" -v to="$3" '
    function newer(a, b,    x, y, n, m, i) {
      n = split(a, x, "."); m = split(b, y, ".")
      for (i = 1; i <= (n > m ? n : m); i++) {
        if ((x[i] + 0) > (y[i] + 0)) return 1
        if ((x[i] + 0) < (y[i] + 0)) return 0
      }
      return 0
    }
    function flush(    t, lead) {
      if (!take || bullet == "") { bullet = ""; return }
      t = bullet; bullet = ""
      if (t ~ /^\*\*/) {
        lead = substr(t, 3); sub(/\*\*.*/, "", lead)
      } else {
        lead = t; sub(/\. .*/, "", lead)
      }
      gsub(/`/, "", lead); sub(/[.:]+$/, "", lead)
      if (length(lead) > 72) lead = substr(lead, 1, 69) "..."
      if (lead != "" && count < 6) { print lead; count++ }
    }
    /^## [0-9]/ {
      flush(); v = $2
      take = (from == "" || newer(v, from)) && (to == "" || !newer(v, to))
      next
    }
    /^- / { flush(); bullet = substr($0, 3); next }
    /^  [^ ]/ && bullet != "" { line = $0; sub(/^  /, "", line); bullet = bullet " " line; next }
    /^[[:space:]]*$/ { flush(); next }
    END { flush() }
  ' "$1"
}
# Called by an update that changed the NIRUX version (FROM -> TO).
whats_new_record() {
  wn_from=$1 wn_to=$2
  [ -n "$wn_from" ] && [ "$wn_from" != "$wn_to" ] || return 0
  wn_log=$WORK/download/nirux/CHANGELOG.md
  [ -f "$wn_log" ] || wn_log=$STATE/current/CHANGELOG.md
  mkdir -p "$STATE" || return 0
  {
    say "version $wn_to"
    say "from $wn_from"
    changelog_highlights "$wn_log" "$wn_from" "$wn_to"
  } > "$WHATS_NEW.$$" && mv -f "$WHATS_NEW.$$" "$WHATS_NEW" || rm -f "$WHATS_NEW.$$"
}
whats_new_lines() {
  sed '1,2d' "$WHATS_NEW" 2>/dev/null || :
}
whats_new_command() {
  wn_notify=0
  for wn_arg in "$@"; do
    case "$wn_arg" in
      --notify) wn_notify=1 ;;
      -h|--help) say 'usage: nirux whats-new [--notify]'; return 0 ;;
      *) die "unknown whats-new option: $wn_arg" ;;
    esac
  done
  wn_version=$(sed -n 's/^version //p' "$WHATS_NEW" 2>/dev/null | head -n 1)
  if [ "$wn_notify" = 0 ]; then
    if [ -n "$wn_version" ]; then
      say "NIRUX $wn_version: what's new (since $(sed -n 's/^from //p' "$WHATS_NEW" | head -n 1))"
      whats_new_lines | sed 's/^/  - /'
    else
      say "NIRUX $VERSION"
      changelog_highlights "$STATE/current/CHANGELOG.md" "" "$VERSION" | head -n 6 | sed 's/^/  - /'
    fi
    pending_status
    say 'Everything: nirux manual (and CHANGELOG.md in the release notes).'
    return 0
  fi
  # --notify: once per version, in a graphical session, never twice.
  [ -n "$wn_version" ] || return 0
  [ "$(cat "$WHATS_NEW_SHOWN" 2>/dev/null)" != "$wn_version" ] || return 0
  [ -n "${DISPLAY:-}" ] || return 0
  command -v notify-send >/dev/null 2>&1 || return 0
  wn_body=$(whats_new_lines | sed 's/^/• /')
  if [ -n "$(pending_lines)" ]; then
    wn_body="${wn_body:+$wn_body
}Run nirux update once to finish (system changes are waiting)."
  fi
  [ -n "$wn_body" ] || wn_body='See nirux manual for what changed.'
  say "$wn_version" > "$WHATS_NEW_SHOWN" || return 0
  wn_answer=$(timeout 900 notify-send -a NIRUX --action=manual='Open the manual' --wait \
    "NIRUX $wn_version: what's new" "$wn_body" 2>/dev/null) ||
    { notify-send -a NIRUX "NIRUX $wn_version: what's new" "$wn_body" >/dev/null 2>&1 || :; return 0; }
  if [ "$wn_answer" = manual ]; then manual_command manual; fi
  return 0
}

# ── After resume (docs: manual chapter 13) ──────────────────────────────────
# NIRUWM starts `nirux resume-check --notify` a few seconds after the machine
# wakes. User level only and bounded: the whole run stays under 20 seconds.
RESUME_LOG=${XDG_STATE_HOME:-$HOME/.local/state}/nirux/resume-check.log
resume_bounded() { rb_t=$1; shift; if command -v timeout >/dev/null 2>&1; then timeout "$rb_t" "$@"; else "$@"; fi; }
resume_left() { say $((RESUME_DEADLINE - $(date +%s))); }
resume_wifi_connected() {
  resume_bounded 3 nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^wifi:connected'
}
resume_network() {
  command -v nmcli >/dev/null 2>&1 || { RC_NET=skipped; return 0; }
  RC_NET=ok
  resume_bounded 5 nmcli networking connectivity check >/dev/null 2>&1 || :
  [ "$(resume_bounded 3 nmcli radio wifi 2>/dev/null)" = enabled ] || return 0
  resume_bounded 3 nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi || return 0
  # A wired link that works is enough; only a lone Wi-Fi is waited for.
  rn_i=0
  while [ "$rn_i" -lt "${NIRUX_RESUME_WAIT:-10}" ] && ! resume_wifi_connected; do
    [ "$(resume_left)" -gt 8 ] || break
    sleep 1; rn_i=$((rn_i + 1))
  done
  resume_wifi_connected && return 0
  if resume_bounded 3 nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^ethernet:connected'; then return 0; fi
  resume_bounded 3 nmcli radio wifi off >/dev/null 2>&1 || :
  sleep 1
  resume_bounded 3 nmcli radio wifi on >/dev/null 2>&1 || :
  rn_i=0
  while [ "$rn_i" -lt 6 ] && [ "$(resume_left)" -gt 1 ]; do
    if resume_wifi_connected; then RC_NET=wifi-reconnected; RC_SAY="${RC_SAY}Wi-Fi reconnected after sleep.
"; return 0; fi
    sleep 1; rn_i=$((rn_i + 1))
  done
  RC_NET=wifi-down
  RC_SAY="${RC_SAY}Wi-Fi did not reconnect after sleep; choose a network in the Wi-Fi menu.
"
}
resume_audio() {
  command -v wpctl >/dev/null 2>&1 || { RC_AUDIO=skipped; return 0; }
  if resume_bounded 3 wpctl status >/dev/null 2>&1; then RC_AUDIO=ok; return 0; fi
  if command -v systemctl >/dev/null 2>&1 && resume_bounded 3 systemctl --user cat wireplumber.service >/dev/null 2>&1; then
    resume_bounded 8 systemctl --user restart pipewire pipewire-pulse wireplumber >/dev/null 2>&1 || :
  else
    # Void: the session starts PipeWire itself (niruwm-session); restart only
    # this session's helpers, the same way.
    for ra_name in pipewire-pulse wireplumber pipewire; do
      for ra_pid in $(pgrep -u "$(id -u)" -x "$ra_name" 2>/dev/null); do
        ra_rt=$(tr '\0' '\n' < "/proc/$ra_pid/environ" 2>/dev/null | sed -n 's/^XDG_RUNTIME_DIR=//p')
        [ "$ra_rt" = "${XDG_RUNTIME_DIR:-}" ] || continue
        kill "$ra_pid" 2>/dev/null || :
      done
    done
    sleep 0.5
    for ra_name in pipewire wireplumber pipewire-pulse; do
      command -v "$ra_name" >/dev/null 2>&1 || continue
      doctor_spawn "$ra_name"
      [ "$ra_name" != pipewire ] || sleep 1
    done
  fi
  sleep 1
  if resume_bounded 3 wpctl status >/dev/null 2>&1; then
    RC_AUDIO=restarted; RC_SAY="${RC_SAY}Sound restarted after sleep.
"
  else
    RC_AUDIO=failed; RC_SAY="${RC_SAY}Sound did not come back after sleep; try: nirux doctor --fix
"
  fi
}
resume_screens() {
  RC_SCREENS=skipped
  [ -n "${DISPLAY:-}" ] && [ -x "$BIN/niructl" ] || return 0
  resume_bounded 3 "$BIN/niructl" display auto status 2>/dev/null | grep -q '^automatic: on' || return 0
  if resume_bounded 6 "$BIN/niructl" display auto run >/dev/null 2>&1; then RC_SCREENS=applied; else RC_SCREENS=failed; fi
}
resume_tailscale() {
  command -v tailscale >/dev/null 2>&1 || { RC_TS=skipped; return 0; }
  rt_i=0
  while :; do
    rt_out=$(resume_bounded 3 tailscale status 2>&1) && { RC_TS=ok; return 0; }
    case "$rt_out" in *'Logged out'*|*stopped*|*'NeedsLogin'*) RC_TS=off; return 0 ;; esac
    rt_i=$((rt_i + 1))
    [ "$rt_i" -lt 3 ] && [ "$(resume_left)" -gt 4 ] || break
    sleep 2
  done
  RC_TS=down
  RC_SAY="${RC_SAY}Tailscale is not connected after sleep.
"
}
resume_check_command() {
  rc_notify=0
  for rc_arg in "$@"; do
    case "$rc_arg" in
      --notify) rc_notify=1 ;;
      -h|--help) say 'usage: nirux resume-check [--notify]'; return 0 ;;
      *) die "unknown resume-check option: $rc_arg" ;;
    esac
  done
  RESUME_DEADLINE=$(( $(date +%s) + ${NIRUX_RESUME_SECONDS:-18} ))
  RC_SAY='' RC_NET=skipped RC_AUDIO=skipped RC_SCREENS=skipped RC_TS=skipped
  resume_network
  resume_audio
  resume_screens
  resume_tailscale
  rc_line="$(date '+%Y-%m-%d %H:%M:%S') network=$RC_NET audio=$RC_AUDIO screens=$RC_SCREENS tailscale=$RC_TS"
  mkdir -p "${RESUME_LOG%/*}" 2>/dev/null || :
  { tail -n 49 "$RESUME_LOG" 2>/dev/null || :; say "$rc_line"; } > "$RESUME_LOG.$$" 2>/dev/null &&
    mv -f "$RESUME_LOG.$$" "$RESUME_LOG" 2>/dev/null || rm -f "$RESUME_LOG.$$"
  if [ "$rc_notify" = 0 ]; then
    say "$rc_line"
    printf '%s' "$RC_SAY"
    return 0
  fi
  [ -n "$RC_SAY" ] && command -v notify-send >/dev/null 2>&1 || return 0
  rc_first=$(printf '%s' "$RC_SAY" | head -n 1)
  rc_rest=$(printf '%s' "$RC_SAY" | sed '1d')
  resume_bounded 5 notify-send -a NIRUX "$rc_first" "$rc_rest" >/dev/null 2>&1 || :
}

# ── nirux clean (docs: manual chapter 13) ───────────────────────────────────
# What can be freed, how much, one question, then the clean-up. Never user
# documents: caches, old packages, the journal above 200 MB, thumbnails, old
# NIRUX generations and snapshots beyond what NIRUX keeps, and trash older
# than 30 days. The root steps use the normal sudo prompt.
clean_kib() { du -skx "$@" 2>/dev/null | awk '{ s += $1 } END { print s + 0 }'; }
clean_human() { snapshot_human $(( ${1:-0} * 1024 )); }
clean_trash_old() { # list trash entries (info files) older than 30 days
  clean_trash=${XDG_DATA_HOME:-$HOME/.local/share}/Trash
  [ -d "$clean_trash/info" ] || return 0
  find "$clean_trash/info" -maxdepth 1 -type f -name '*.trashinfo' -mtime +30 2>/dev/null
}
clean_command() {
  cl_yes=0 cl_dry=0
  for cl_arg in "$@"; do
    case "$cl_arg" in
      --yes|-y) cl_yes=1 ;;
      --dry-run|-n) cl_dry=1 ;;
      -h|--help) say 'usage: nirux clean [--yes] [--dry-run]'; return 0 ;;
      *) die "unknown clean option: $cl_arg (nirux clean --help)" ;;
    esac
  done
  OS=$( (distro) 2>/dev/null ) || OS=unknown
  cl_root=${NIRUX_SYSTEM_ROOT:-}
  : > "${TMPDIR:-/tmp}/.nirux-clean.$$" || die 'could not create a temporary file'
  cl_plan=${TMPDIR:-/tmp}/.nirux-clean.$$
  cl_total=0
  cl_add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$cl_plan"; cl_total=$((cl_total + $2)); }
  case "$OS" in
    debian) cl_add pkg "$(clean_kib "$cl_root/var/cache/apt/archives")" 'package cache (apt-get clean)' ;;
    arch)
      if command -v paccache >/dev/null 2>&1; then cl_add pkg "$(clean_kib "$cl_root/var/cache/pacman/pkg")" 'old packages (paccache -rk1; up to this size)'
      else cl_add pkg "$(clean_kib "$cl_root/var/cache/pacman/pkg")" 'package cache (pacman -Sc; up to this size)'; fi ;;
    void) cl_add pkg "$(clean_kib "$cl_root/var/cache/xbps")" 'obsolete packages (xbps-remove -O; up to this size)' ;;
  esac
  if command -v journalctl >/dev/null 2>&1 && [ -d "$cl_root/run/systemd/system" ]; then
    cl_j=$(journalctl --disk-usage 2>/dev/null | sed -n 's/.* \([0-9.]*\)\([KMGT]\)B\{0,1\} .*/\1 \2/p' | head -n 1 |
      awk '{ m = ($2 == "K") ? 1 : ($2 == "M") ? 1024 : ($2 == "G") ? 1048576 : 1073741824; v = $1 * m - 204800; print (v > 0) ? int(v) : 0 }')
    [ "${cl_j:-0}" -gt 0 ] 2>/dev/null && cl_add journal "$cl_j" 'system journal above 200 MB'
  fi
  cl_thumbs=${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails
  [ -d "$cl_thumbs" ] && cl_add thumbs "$(clean_kib "$cl_thumbs")" "thumbnails ($cl_thumbs)"
  cl_gen=$(gc_generations "${NIRUX_KEEP_GENERATIONS:-5}" 1 2>/dev/null | sed -n 's/^remove //p' || :)
  if [ -n "$cl_gen" ]; then
    # shellcheck disable=SC2086 # one generation directory per word
    cl_add generations "$(cd "$STATE/generations" 2>/dev/null && clean_kib $cl_gen)" "old NIRUX generations ($(say $cl_gen | wc -w | tr -d ' '))"
  fi
  cl_trash_n=$(clean_trash_old | grep -c . || :)
  if [ "$cl_trash_n" -gt 0 ]; then
    cl_trash_kib=0
    for cl_info in $(clean_trash_old | sed 's|.*/||; s|\.trashinfo$||'); do
      cl_trash_kib=$((cl_trash_kib + $(clean_kib "$clean_trash/files/$cl_info")))
    done
    cl_add trash "$cl_trash_kib" "$cl_trash_n items in the trash older than 30 days"
  fi
  say 'nirux clean can free:'
  awk -F '\t' '{ printf "%s\t%s\n", $2, $3 }' "$cl_plan" | while IFS="$TAB" read -r cl_k cl_text; do
    printf '  %10s  %s\n' "$(clean_human "$cl_k")" "$cl_text"
  done
  say "  about $(clean_human "$cl_total") in all. Your own files are not touched."
  if [ "$cl_dry" = 1 ]; then rm -f "$cl_plan"; say 'Dry run: nothing was changed.'; return 0; fi
  if [ "$cl_yes" != 1 ]; then
    [ -t 0 ] || { rm -f "$cl_plan"; die 'nirux clean needs a terminal to ask, or --yes'; }
    if ! nirux_confirm 'Clean up now? Some steps ask for your sudo password. [y/N] '; then
      rm -f "$cl_plan"; say 'Nothing was changed.'; return 1
    fi
  fi
  cl_before=$(df -Pk / "$HOME" 2>/dev/null | awk 'NR > 1 && !seen[$1]++ { s += $4 } END { print s + 0 }')
  while IFS="$TAB" read -r cl_id _cl_k _cl_text; do
    case "$cl_id" in
      pkg)
        case "$OS" in
          debian) as_root apt-get clean || say 'could not clean the package cache' ;;
          arch)
            if command -v paccache >/dev/null 2>&1; then as_root paccache -rk1 || say 'paccache failed'
            else as_root pacman -Sc --noconfirm || say 'pacman -Sc failed'; fi ;;
          void) as_root xbps-remove -Oy || say 'xbps-remove -O failed' ;;
        esac ;;
      journal) as_root journalctl --vacuum-size=200M >/dev/null 2>&1 || say 'could not vacuum the journal' ;;
      thumbs) find "$cl_thumbs" -xdev -mindepth 1 -type f -delete 2>/dev/null || : ;;
      generations) gc_generations "${NIRUX_KEEP_GENERATIONS:-5}" 0 >/dev/null 2>&1 || say 'could not remove old generations' ;;
      trash)
        for cl_info in $(clean_trash_old); do
          cl_name=${cl_info##*/}; cl_name=${cl_name%.trashinfo}
          rm -rf "${clean_trash:?}/files/$cl_name" && rm -f "$cl_info"
        done ;;
    esac
  done < "$cl_plan"
  # Snapshots beyond [snapshots] keep (normally rotated already).
  snapshot_rotate >/dev/null 2>&1 || :
  rm -f "$cl_plan"
  cl_after=$(df -Pk / "$HOME" 2>/dev/null | awk 'NR > 1 && !seen[$1]++ { s += $4 } END { print s + 0 }')
  cl_freed=$((cl_after - cl_before))
  [ "$cl_freed" -gt 0 ] || cl_freed=0
  say "Done: $(clean_human "$cl_freed") freed."
  df -h / "$HOME" 2>/dev/null | awk 'NR == 1 || !seen[$1]++' | sed 's/^/  /'
}

