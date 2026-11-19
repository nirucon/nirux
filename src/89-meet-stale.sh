# ── nirux stale: programs that still run an old version (docs: chapter 11) ──
# After an update, a program keeps running the version it started from. That
# is fine until it starts a helper from files that are gone (Helium's camera
# in Teams). `nirux stale` names them; NIRUBAR's restart module shows them.
#
# One line per stale program: "NAME<TAB>PROGRAM<TAB>RESTART" where RESTART is
# auto (NIRUX restarts it in place), relogin (a session helper: log out and in)
# or manual (an app: close all its windows and open it again).
stale_name() {
  case "$1" in
    niruwm) say NIRUWM ;; nirubar) say NIRUBAR ;; helium|helium_*) say Helium ;;
    niructl) say 'NIRUCTL helpers' ;;
    localsend_app|localsend) say LocalSend ;; opencode) say OpenCode ;;
    *) say "$1" | tr '[:lower:]' '[:upper:]' ;;
  esac
}
stale_scan() {
  ss_proc=${NIRUX_PROC:-/proc}
  ss_gen=$(readlink -f "$STATE/current" 2>/dev/null || :)
  ss_gens=$(cd "$STATE/generations" 2>/dev/null && pwd -P || :)
  ss_browser=$(readlink -f "$STATE/browser-current" 2>/dev/null || :)
  ss_localsend=$(readlink -f "$STATE/localsend/current" 2>/dev/null || :)
  ss_opencode=$(readlink -f "$STATE/opencode/current" 2>/dev/null || :)
  ss_state=$(cd "$STATE" 2>/dev/null && pwd -P || say "$STATE")
  for ss_exe in "$ss_proc"/[0-9]*/exe; do
    ss_target=$(readlink "$ss_exe" 2>/dev/null) || continue
    ss_deleted=0
    case "$ss_target" in *" (deleted)") ss_deleted=1; ss_target=${ss_target% (deleted)} ;; esac
    ss_prog=${ss_target##*/}
    # The lock screen that is up now is the one running process of NIRULOCK;
    # the next lock starts the new version by itself.
    [ "$ss_prog" != nirulock ] || continue
    # Helium's crash reporter is part of Helium.
    case "$ss_prog" in helium_*) ss_prog=helium ;; esac
    case "$ss_target" in
      "$ss_gens"/*|"$ss_state"/generations/*)
        ss_dir=${ss_target%/bin/*}
        [ "$ss_dir" != "$ss_target" ] || continue
        if [ "$ss_deleted" = 0 ] && [ "$ss_dir" = "$ss_gen" ]; then continue; fi
        # A program the update did not change is the same file in the new
        # generation: it needs no restart.
        if [ "$ss_deleted" = 0 ] && [ -f "$ss_gen/bin/$ss_prog" ] &&
           [ "$(sha256sum < "$ss_target" 2>/dev/null)" = "$(sha256sum < "$ss_gen/bin/$ss_prog" 2>/dev/null)" ]; then
          continue
        fi
        case "$ss_prog" in niruwm|nirubar) ss_how=auto ;; *) ss_how=relogin ;; esac ;;
      "$ss_state"/browsers/*)
        case "$ss_target" in "$ss_browser"/*) [ "$ss_deleted" = 1 ] || continue ;; esac
        ss_how=manual ;;
      "$ss_state"/localsend/*)
        case "$ss_target" in "$ss_localsend"/*) [ "$ss_deleted" = 1 ] || continue ;; esac
        ss_how=manual ;;
      "$ss_state"/opencode/*)
        case "$ss_target" in "$ss_opencode"/*) [ "$ss_deleted" = 1 ] || continue ;; esac
        ss_how=manual ;;
      *) continue ;;
    esac
    printf '%s\t%s\t%s\n' "$(stale_name "$ss_prog")" "$ss_prog" "$ss_how"
  done | sort -u
}
stale_json() {
  printf '{"stale":['
  stale_scan | awk -F '\t' 'BEGIN { sep = "" } { gsub(/["\\]/, "", $0); printf "%s{\"name\":\"%s\",\"program\":\"%s\",\"restart\":\"%s\"}", sep, $1, $2, $3; sep = "," }'
  printf ']}\n'
}
stale_restart() {
  sr_list=$(stale_scan)
  [ -n "$sr_list" ] || { say 'Nothing runs an old version.'; return 0; }
  sr_manual='' sr_relogin=''
  sr_tab=$(printf '\t')
  while IFS="$sr_tab" read -r sr_name sr_prog sr_how; do
    case "$sr_how" in
      auto)
        case "$sr_prog" in
          nirubar) say "Restarting $sr_name"; niructl restart-bar >/dev/null 2>&1 || say "  could not restart $sr_name" ;;
          niruwm) say "Restarting $sr_name in place (windows stay)"; niructl restart-wm >/dev/null 2>&1 || say "  could not restart $sr_name" ;;
        esac ;;
      relogin) sr_relogin="$sr_relogin $sr_name" ;;
      manual) sr_manual="$sr_manual $sr_name" ;;
    esac
  done <<EOF
$sr_list
EOF
  sr_text=
  [ -z "$sr_manual" ] || sr_text="Close all windows of${sr_manual} and open again to finish the update."
  [ -z "$sr_relogin" ] || sr_text="${sr_text:+$sr_text }Log out and in once for${sr_relogin}."
  [ -n "$sr_text" ] || return 0
  say "$sr_text"
  if command -v notify-send >/dev/null 2>&1; then
    timeout 5 notify-send -a NIRUX "Restart to finish the update" "$sr_text" >/dev/null 2>&1 || :
  fi
}
stale_command() {
  case "${1:-}" in
    '') sc_list=$(stale_scan)
        if [ -z "$sc_list" ]; then say 'Nothing runs an old version.'; return 0; fi
        say 'Running an old version:'
        printf '%s\n' "$sc_list" | awk -F '\t' '{
          how = ($3 == "auto") ? "nirux stale restart restarts it" : ($3 == "relogin") ? "log out and in" : "close all its windows and open it again"
          printf "  %-16s %s\n", $1, how }' ;;
    --json) stale_json ;;
    restart) stale_restart ;;
    -h|--help) say 'usage: nirux stale [--json] | stale restart' ;;
    *) die "unknown stale option: $1 (nirux stale --help)" ;;
  esac
}

# ── nirux meet-check: ready for a call? (docs: chapter 10) ──────────────────
# Camera, microphone, speakers, stale apps and the way to Teams, in a few
# seconds. Nothing is recorded or kept: one camera frame and two seconds of
# microphone level are read and thrown away.
MC_PROBLEMS=0
mc_line() { # STATUS TEXT: ok, warn or fail
  case "$1" in
    ok) say "  ok    $2" ;;
    warn) say "  note  $2" ;;
    *) say "  FAIL  $2"; MC_PROBLEMS=$((MC_PROBLEMS + 1)) ;;
  esac
  MC_SUMMARY="${MC_SUMMARY}$1|$2
"
}
mc_json_field() { # JSON FILE, python expression on d
  python3 -I -c 'import json, sys
try:
    d = json.load(open(sys.argv[1]))
    v = eval(sys.argv[2], {"d": d})
    print("" if v is None else v)
except Exception:
    pass' "$1" "$2" 2>/dev/null
}
mc_camera() {
  mc_dev=
  for mc_v in /sys/class/video4linux/video*; do
    [ -e "$mc_v" ] || continue
    mc_node=/dev/${mc_v##*/}
    if command -v v4l2-ctl >/dev/null 2>&1; then
      v4l2-ctl -d "$mc_node" --info 2>/dev/null | grep -A1 'Device Caps' | grep -q 'Video Capture' || continue
      # An infrared face-login camera gives grey frames only: not for calls.
      v4l2-ctl -d "$mc_node" --list-formats 2>/dev/null | grep -qE "'(YUYV|MJPG|NV12|H264)'" || continue
    fi
    mc_dev=$mc_node
    mc_name=$(cat "$mc_v/name" 2>/dev/null); mc_name=${mc_name%%:*}
    break
  done
  if [ -z "$mc_dev" ]; then mc_line fail 'camera: none found (is it switched off with a key or a shutter?)'; return; fi
  mc_users=$(fuser "$mc_dev" 2>/dev/null | tr -s ' ')
  if [ -n "$mc_users" ]; then
    mc_line ok "camera: $mc_name, in use now (by $(ps -o comm= -p ${mc_users# } 2>/dev/null | head -n 1))"
    return
  fi
  if ! command -v ffmpeg >/dev/null 2>&1; then mc_line warn "camera: $mc_name found (ffmpeg missing, no test picture)"; return; fi
  if timeout 8 ffmpeg -hide_banner -loglevel error -f v4l2 -i "$mc_dev" -frames:v 1 -f null - >/dev/null 2>&1; then
    mc_line ok "camera: $mc_name gives a picture"
  else
    mc_line fail "camera: $mc_name gives no picture (busy, blocked or switched off)"
  fi
}
mc_audio() {
  if ! command -v niructl >/dev/null 2>&1; then mc_line warn 'sound: niructl missing, not checked'; return; fi
  mc_status=$WORK/meet-audio.json
  if ! niructl audio status --json > "$mc_status" 2>/dev/null; then mc_line fail 'sound: the sound server does not answer'; return; fi
  mc_in=$(mc_json_field "$mc_status" 'd["input"]["name"]')
  mc_in_muted=$(mc_json_field "$mc_status" 'd["input"]["muted"]')
  mc_in_pct=$(mc_json_field "$mc_status" 'd["input"]["percent"]')
  mc_out=$(mc_json_field "$mc_status" 'd["output"]["name"]')
  mc_out_muted=$(mc_json_field "$mc_status" 'd["output"]["muted"]')
  mc_out_pct=$(mc_json_field "$mc_status" 'd["output"]["percent"]')
  if [ -z "$mc_out" ]; then mc_line fail 'speakers: no output device'
  elif [ "$mc_out_muted" = True ]; then mc_line fail "speakers: $mc_out is muted"
  elif [ "${mc_out_pct:-0}" -lt 10 ] 2>/dev/null; then mc_line warn "speakers: $mc_out at ${mc_out_pct} %, very low"
  else mc_line ok "speakers: $mc_out at ${mc_out_pct} %"
  fi
  if [ -z "$mc_in" ]; then mc_line fail 'microphone: none found'; return; fi
  if [ "$mc_in_muted" = True ]; then mc_line fail "microphone: $mc_in is muted"; return; fi
  mc_test=$WORK/meet-mic.json
  if timeout 8 niructl audio mic-test 2 --json > "$mc_test" 2>/dev/null; then
    mc_verdict=$(mc_json_field "$mc_test" 'd["verdict"]')
    mc_peak=$(mc_json_field "$mc_test" 'd["peak_dbfs"]')
    mc_dead=$(awk -v p="${mc_peak:--120}" 'BEGIN { print (p <= -90) ? 1 : 0 }')
    case "$mc_verdict" in
      "too quiet") if [ "$mc_dead" = 1 ]; then
          mc_line fail "microphone: $mc_in at ${mc_in_pct} % gives digital silence (peak ${mc_peak} dBFS): wrong input, or switched off"
        else
          mc_line warn "microphone: $mc_in at ${mc_in_pct} % works but heard little (peak ${mc_peak} dBFS); say something during the check to test your level"
        fi ;;
      "too hot") mc_line warn "microphone: $mc_in at ${mc_in_pct} % is very loud (peak ${mc_peak} dBFS); lower it if others hear distortion" ;;
      '') mc_line ok "microphone: $mc_in at ${mc_in_pct} %" ;;
      *) mc_line ok "microphone: $mc_in at ${mc_in_pct} % ($mc_verdict)" ;;
    esac
  else
    mc_line warn "microphone: $mc_in at ${mc_in_pct} % (level test failed)"
  fi
}
mc_stale() {
  mc_apps=$(stale_scan | awk -F '\t' '$3 == "manual" { printf "%s%s", sep, $1; sep = ", " }')
  if [ -n "$mc_apps" ]; then
    mc_line fail "apps: $mc_apps still run(s) an old version; close all its windows and open it again (the camera may not start)"
  else
    mc_line ok 'apps: nothing runs an old version'
  fi
}
mc_network() {
  if ! command -v curl >/dev/null 2>&1; then mc_line warn 'network: curl missing, not checked'; return; fi
  mc_host=${NIRUX_MEET_URL:-https://teams.microsoft.com}
  mc_time=$(curl -sS -o /dev/null --connect-timeout 5 --max-time 8 -w '%{time_connect}' "$mc_host" 2>/dev/null) || mc_time=
  if [ -z "$mc_time" ]; then mc_line fail "network: ${mc_host#https://} cannot be reached"; return; fi
  mc_ms=$(awk -v t="$mc_time" 'BEGIN { printf "%d", t * 1000 }')
  if [ "$mc_ms" -gt 250 ]; then mc_line warn "network: ${mc_host#https://} answers slowly (${mc_ms} ms)"
  else mc_line ok "network: ${mc_host#https://} in ${mc_ms} ms"
  fi
}
meet_check_command() {
  mc_notify=0
  for mc_arg in "$@"; do
    case "$mc_arg" in
      --notify) mc_notify=1 ;;
      -h|--help) say 'usage: nirux meet-check [--notify]'; return 0 ;;
      *) die "unknown meet-check option: $mc_arg" ;;
    esac
  done
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/nirux-meet.XXXXXX") || die 'could not create a temporary directory'
  trap 'rm -rf "$WORK"' EXIT
  MC_SUMMARY=
  say 'Ready for a call?'
  mc_camera
  mc_audio
  mc_stale
  mc_network
  if [ "$MC_PROBLEMS" = 0 ]; then
    say 'Ready for the meeting.'
    mc_sound=meet-ready mc_title='Ready for the meeting'
  else
    say "$MC_PROBLEMS problem(s) found."
    mc_sound=meet-problem mc_title="$MC_PROBLEMS problem(s) before the meeting"
  fi
  "$0" sounds play "$mc_sound" >/dev/null 2>&1 || :
  if [ "$mc_notify" = 1 ] && command -v notify-send >/dev/null 2>&1; then
    mc_body=$(printf '%s' "$MC_SUMMARY" | awk -F '|' '$1 != "ok" { print ($1 == "fail" ? "✗ " : "• ") $2 } $1 == "ok" { ok++ } END { if (ok) print "✓ " ok " checks ok" }')
    timeout 5 notify-send -a NIRUX "$mc_title" "$mc_body" >/dev/null 2>&1 || :
  fi
  [ "$MC_PROBLEMS" = 0 ]
}
