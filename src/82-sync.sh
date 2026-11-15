# nirux sync: compare and copy user settings between NIRUX machines over the
# SSH access of nirux fleet. Items are named groups of paths relative to
# $HOME (default XDG layout on both ends). A transfer never deletes: files that
# only the receiving machine has are kept. niruwm's config.toml is never copied
# whole (it holds per-machine monitors and display settings); the theme item
# carries only its top-level `theme` key.
SYNC_ITEMS_ALL='quotes keys.d theme lock launcher sounds sid'
sync_item_roots() {
  case "$1" in
    quotes) say .config/niru/quotes.txt; say .config/niru/quotes ;;
    keys.d) say .config/niru/keys.d; say .local/share/niru/keys.d ;;
    theme) say .config/niruwm/themes; say .config/niruwm/theme-preferences.toml ;;
    lock) say .config/niruui/lock.toml; say .config/niruui/screensaver.toml; say .config/nirulock; say .config/niruscreensaver ;;
    launcher) say .config/nirulauncher; say .local/state/nirulauncher/favorites.tsv; say .local/state/nirulauncher/favorites-removed.tsv ;;
    sounds) say .config/nirux/sounds.toml; say .config/nirux/sounds ;;
    sid) say Music/SID ;;
    *) return 1 ;;
  esac
}
sync_usage() {
  say 'Usage: nirux sync status [HOST...] [--files]'
  say '       nirux sync push HOST...|--all [ITEM...] [--yes] [--dry-run]'
  say '       nirux sync pull HOST [ITEM...] [--yes] [--dry-run]'
  say '       nirux sync items'
  say "Items: $SYNC_ITEMS_ALL. Change the default set with [sync] items = [...] and"
  say "exclude = [...] (item names or paths relative to ~) in $SYNC_CONFIG."
  say 'Hosts and SSH access come from nirux fleet (nirux fleet setup).'
}
sync_items_list() {
  for sync_i in $SYNC_ITEMS_ALL; do
    printf '%-9s %s\n' "$sync_i" "$(sync_item_roots "$sync_i" | sed 's|^|~/|' | tr '\n' ' ')"
  done
  say 'theme     also the theme = "..." key of ~/.config/niruwm/config.toml (nothing else from that file)'
  say "Default: $(sync_default_items)"
  say 'Never synced: niruwm config.toml as a whole, display profiles (displays.toml, nirudisplay),'
  say 'secrets (token/password-like files), nirushare, state and caches.'
}
sync_default_items() {
  sync_cfg=$(toml_list "$SYNC_CONFIG" sync items | tr '\n' ' ')
  [ -n "$sync_cfg" ] || sync_cfg=$SYNC_ITEMS_ALL
  sync_out=
  for sync_i in $sync_cfg; do
    sync_item_roots "$sync_i" >/dev/null || { say "nirux sync: ignoring unknown item in $SYNC_CONFIG: $sync_i" >&2; continue; }
    toml_list "$SYNC_CONFIG" sync exclude | grep -qxF -- "$sync_i" && continue
    sync_out="$sync_out $sync_i"
  done
  say "${sync_out# }"
}
# Write the roots and path excludes of items $* to $FLEET_WORK/sync.roots and
# sync.exclude; SYNC_THEME=1 when the theme item is part of it.
sync_prepare() {
  : > "$FLEET_WORK/sync.roots"
  SYNC_THEME=0
  for sync_i in "$@"; do
    [ "$sync_i" != theme ] || SYNC_THEME=1
    sync_item_roots "$sync_i" | awk -v i="$sync_i" '{ print i "\t" $0 }' >> "$FLEET_WORK/sync.roots"
  done
  toml_list "$SYNC_CONFIG" sync exclude | awk '/\// { sub(/^~\//, ""); sub(/\/$/, ""); print }' > "$FLEET_WORK/sync.exclude"
}
sync_ssh() { ssh -o BatchMode=yes -o ConnectTimeout="${NIRUX_FLEET_TIMEOUT:-5}" "$@"; }
# Scan host $1 (LOCAL $2 = 1: this machine) into $FLEET_WORK/scan.$1.
sync_scan() {
  sync_o=$FLEET_WORK/scan.$1
  sync_rc=0
  if [ "$2" = 1 ]; then
    scan_script "$FLEET_WORK/sync.roots" "$FLEET_WORK/sync.exclude" 0 "$SYNC_THEME" | sh -s > "$sync_o" 2> "$sync_o.err" || sync_rc=$?
  else
    scan_script "$FLEET_WORK/sync.roots" "$FLEET_WORK/sync.exclude" 0 "$SYNC_THEME" |
      fleet_timeout "${NIRUX_SYNC_TIMEOUT:-600}" ssh -o BatchMode=yes -o ConnectTimeout="${NIRUX_FLEET_TIMEOUT:-5}" "$1" sh -s > "$sync_o" 2> "$sync_o.err" || sync_rc=$?
  fi
  echo "rc=$sync_rc" >> "$sync_o"
}
sync_field() { sed -n "s/^$2=//p" "$FLEET_WORK/scan.$1" 2>/dev/null | head -n 1; }
# The state of a scanned remote host: ok, nonirux, noaccess or offline.
sync_host_state() {
  sync_nx=$(sync_field "$1" nirux)
  if [ -n "$sync_nx" ] && [ "$(sync_field "$1" rc)" = 0 ]; then
    if [ "$sync_nx" = absent ]; then say nonirux; else say ok; fi
  elif grep -qiE 'permission denied|host key verification failed|too many authentication' "$FLEET_WORK/scan.$1.err" 2>/dev/null; then
    say noaccess
  else
    say offline
  fi
}
sync_host_problem() {
  case "$2" in
    nonirux) say "$1: NIRUX is not installed there" ;;
    noaccess) say "$1: no SSH key access (run nirux fleet setup $1)" ;;
    offline) say "$1: not reachable ($(grep -v '^$' "$FLEET_WORK/scan.$1.err" 2>/dev/null | tail -n 1))" ;;
  esac
}
sync_self_names() {
  uname -n
  [ -z "${FLEET_SELF:-}" ] || say "$FLEET_SELF"
}
sync_is_self() { sync_self_names | grep -qxF -- "${1#*@}"; }
# Host and item arguments: an argument naming an item is an item.
sync_args() {
  SYNC_HOSTS='' SYNC_ITEMS='' SYNC_YES=0 SYNC_DRY=0 SYNC_ALL=0 SYNC_FILES=0
  for sync_a in "$@"; do
    case "$sync_a" in
      --yes|-y) SYNC_YES=1 ;;
      --dry-run|-n) SYNC_DRY=1 ;;
      --all) SYNC_ALL=1 ;;
      --files) SYNC_FILES=1 ;;
      --help|-h) sync_usage; exit 0 ;;
      -*) die "unknown sync option: $sync_a" ;;
      *)
        if sync_item_roots "$sync_a" >/dev/null; then SYNC_ITEMS="$SYNC_ITEMS $sync_a"
        else fleet_valid_host "$sync_a" || die "invalid host name: $sync_a"; SYNC_HOSTS="$SYNC_HOSTS $sync_a"; fi ;;
    esac
  done
  SYNC_ITEMS=${SYNC_ITEMS# }
  [ -n "$SYNC_ITEMS" ] || SYNC_ITEMS=$(sync_default_items)
  [ -n "$SYNC_ITEMS" ] || die "no sync items selected (see $SYNC_CONFIG)"
}
# Online NIRUX fleet hosts other than this machine.
sync_fleet_hosts() {
  fleet_collect
  fleet_note >&2
  awk -F '|' '$2 != 1 && $3 == "online" { print $1 }' "$FLEET_WORK/rows" | tr '\n' ' '
  awk -F '|' '$2 != 1 && $3 != "online" { print $1 "|" $3 }' "$FLEET_WORK/rows" > "$FLEET_WORK/sync.skipped"
}
sync_local_note() {
  [ "$(sync_field "$SYNC_LOCAL" nirux)" = absent ] || return 0
  say "Note: NIRUX is not installed on this machine ($(uname -n)); its side of the comparison is empty,"
  say '      so everything on the other machine shows as only there. Pull would copy it here.'
}
# Print the status table for host $1 from $FLEET_WORK/diff.$1.
sync_print_status() {
  sync_d=$FLEET_WORK/diff.$1
  sync_how=tar; [ "$(sync_method "$1")" = rsync ] && sync_how=rsync
  if [ "${SYNC_HERE_NAME:-here}" = here ]; then say "== $1 (NIRUX $(sync_field "$1" nirux), transfer: $sync_how)"
  else say "== $1 compared with $SYNC_HERE_NAME (NIRUX $(sync_field "$1" nirux) and $(sync_field "$SYNC_HERE_NAME" nirux))"; fi
  {
    printf 'ITEM\tSAME\tCHANGED\tONLY HERE\tONLY THERE\tEXCLUDED\tHERE\tTHERE\n'
    for sync_i in $SYNC_ITEMS; do
      awk -F '\t' -v i="$sync_i" '
        $2 != i { next }
        $1 == "same" { s++; hb += $3; tb += $4 } $1 == "changed" { c++; hb += $3; tb += $4 }
        $1 == "here" { h++; hb += $3 } $1 == "there" { t++; tb += $4 } $1 ~ /^x/ { x++ }
        $1 == "theme" { if ($3 != $4) c++; else s++ }
        END { printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", i, s, c, h, t, x, hb, tb }' "$sync_d"
    done
  } | while IFS="$TAB" read -r c1 c2 c3 c4 c5 c6 c7 c8; do
    if [ "$c1" = ITEM ]; then printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$c7" "$c8"
    else printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$(snapshot_human "$c7")" "$(snapshot_human "$c8")"; fi
  done | awk -F '\t' '
    { for (i = 1; i <= NF; i++) { c[NR, i] = $i; if (length($i) > w[i]) w[i] = length($i) } n = NR; if (NF > m) m = NF }
    END { for (r = 1; r <= n; r++) { line = ""
      for (i = 1; i <= m; i++) line = line (i < m ? sprintf("%-" (w[i] + 2) "s", c[r, i]) : c[r, i])
      print "  " line } }'
  awk -F '\t' -v here="${SYNC_HERE_NAME:-here}" '$1 == "theme" && $3 != $4 { print "  theme: " here " " ($3 == "" ? "(none)" : $3) ", there " ($4 == "" ? "(none)" : $4) }' "$sync_d"
  awk -F '\t' -v all="$SYNC_FILES" '
    $1 == "changed" { l = "changed    " } $1 == "here" { l = "only here  " } $1 == "there" { l = "only there " }
    $1 == "xhere" { l = "excluded   " } $1 == "xthere" { l = "excluded   " }
    $1 == "same" || $1 == "theme" { next }
    { n[$2]++; if (all || n[$2] <= 8) print "  " $2 "\t" l $5 (($1 ~ /^x/) ? " (" $3 ")" : "") ; else more[$2]++ }
    END { for (i in more) print "  " i "\t... and " more[i] " more (--files lists all)" }' "$sync_d" |
    awk -F '\t' '{ printf "%-11s %s\n", $1, $2 }'
}
# rsync when both ends have it and NIRUX_SYNC_TRANSFER is not tar.
sync_method() {
  case "${NIRUX_SYNC_TRANSFER:-auto}" in
    tar) say tar; return ;;
    rsync|auto) ;;
    *) die 'NIRUX_SYNC_TRANSFER must be auto, rsync or tar' ;;
  esac
  if command -v rsync >/dev/null 2>&1 && [ "$(sync_field "$1" rsync)" = 1 ]; then say rsync
  elif [ "${NIRUX_SYNC_TRANSFER:-auto}" = rsync ]; then die "rsync is missing on $1 or here"
  else say tar; fi
}
sync_status() {
  sync_args "$@"
  fleet_work
  sync_prepare $SYNC_ITEMS
  : > "$FLEET_WORK/sync.skipped"
  if [ -z "$SYNC_HOSTS" ]; then
    say 'Checking the fleet...'
    SYNC_HOSTS=$(sync_fleet_hosts)
  else
    fleet_tailscale >/dev/null 2>&1 && FLEET_SELF=$(awk -F '\t' '$1 == "self" { print $2; exit }' "$FLEET_WORK/peers") || :
  fi
  SYNC_LOCAL=_here
  sync_scan "$SYNC_LOCAL" 1 &
  for sync_h in $SYNC_HOSTS; do
    if sync_is_self "$sync_h"; then say "$sync_h: this machine, skipped"; continue; fi
    sync_scan "$sync_h" 0 &
  done
  wait
  [ "$(sync_field "$SYNC_LOCAL" rc)" = 0 ] || die "could not scan this machine: $(cat "$FLEET_WORK/scan.$SYNC_LOCAL.err")"
  say "Items: $SYNC_ITEMS"
  # A machine without NIRUX (a server with SSH keys to the fleet) has nothing
  # to compare; with two or more hosts, they are compared with the first one.
  sync_ref=$SYNC_LOCAL SYNC_HERE_NAME=here
  if [ "$(sync_field "$SYNC_LOCAL" nirux)" = absent ]; then
    sync_ok_hosts=
    for sync_h in $SYNC_HOSTS; do
      sync_is_self "$sync_h" || [ "$(sync_host_state "$sync_h")" != ok ] || sync_ok_hosts="$sync_ok_hosts $sync_h"
    done
    # shellcheck disable=SC2086 # one word per host
    set -- $sync_ok_hosts
    if [ "$#" -ge 2 ]; then
      sync_ref=$1 SYNC_HERE_NAME=$1
      say "Note: NIRUX is not installed on this machine ($(uname -n)); comparing with $1 instead"
      say "      (ONLY HERE means only on $1). Push and pull always use this machine's files."
    else
      sync_local_note
    fi
  fi
  sync_found=0
  for sync_h in $SYNC_HOSTS; do
    sync_is_self "$sync_h" && continue
    [ "$sync_h" != "$sync_ref" ] || continue
    sync_st=$(sync_host_state "$sync_h")
    if [ "$sync_st" != ok ]; then say "== $(sync_host_problem "$sync_h" "$sync_st")"; continue; fi
    sync_found=1
    sync_compare "$FLEET_WORK/scan.$sync_ref" "$FLEET_WORK/scan.$sync_h" > "$FLEET_WORK/diff.$sync_h"
    sync_print_status "$sync_h"
  done
  while IFS='|' read -r sync_h sync_st; do
    [ -n "$sync_h" ] || continue
    case "$sync_st" in noaccess) sync_st="no SSH key access (run nirux fleet setup $sync_h)" ;; nonirux) sync_st='no NIRUX' ;; esac
    say "== $sync_h: $sync_st, skipped"
  done < "$FLEET_WORK/sync.skipped"
  [ "$sync_found" = 1 ] || [ -n "$SYNC_HOSTS" ] || say 'No other NIRUX host found (nirux fleet status).'
  return 0
}
# List what direction $2 (push|pull) would copy for host $1 into
# $FLEET_WORK/send.$1 and print the preview. Returns 1 when nothing differs.
sync_plan() {
  sync_d=$FLEET_WORK/diff.$1
  sync_compare "$FLEET_WORK/scan.$SYNC_LOCAL" "$FLEET_WORK/scan.$1" > "$sync_d"
  if [ "$2" = push ]; then sync_want='changed|here' sync_col=3; else sync_want='changed|there' sync_col=4; fi
  awk -F '\t' -v w="^($sync_want)\$" '$1 ~ w { print $5 }' "$sync_d" > "$FLEET_WORK/send.$1"
  awk -F '\t' '$1 == "changed" { print $5 }' "$sync_d" > "$FLEET_WORK/overwrite.$1"
  SYNC_THEME_VALUE=
  if [ "$2" = push ]; then
    SYNC_THEME_VALUE=$(awk -F '\t' '$1 == "theme" && $3 != $4 { print $3 }' "$sync_d")
  else
    SYNC_THEME_VALUE=$(awk -F '\t' '$1 == "theme" && $3 != $4 { print $4 }' "$sync_d")
  fi
  case "$SYNC_THEME_VALUE" in *[!A-Za-z0-9._-]*) say "  theme: ignoring an unusual theme name: $SYNC_THEME_VALUE"; SYNC_THEME_VALUE= ;; esac
  if [ ! -s "$FLEET_WORK/send.$1" ] && [ -z "$SYNC_THEME_VALUE" ]; then
    say "== $1: already in sync for: $SYNC_ITEMS"
    return 1
  fi
  if [ "$2" = push ]; then say "== push to $1 ($(sync_method "$1")):"; else say "== pull from $1 ($(sync_method "$1")):"; fi
  for sync_i in $SYNC_ITEMS; do
    awk -F '\t' -v i="$sync_i" -v w="^($sync_want)\$" -v col="$sync_col" '
      $2 == i && $1 ~ w { n++; b += $col; if ($1 == "changed") c++; else a++ }
      END { if (n) printf "%s\t%d\t%d\t%d\n", i, n, c, b }' "$sync_d"
  done | while IFS="$TAB" read -r sync_i sync_n sync_c sync_b; do
    say "  $sync_i: $sync_n files, $(snapshot_human "$sync_b") ($sync_c replace a different file, $((sync_n - sync_c)) new)"
  done
  if [ -n "$SYNC_THEME_VALUE" ]; then
    awk -F '\t' -v d="$2" '$1 == "theme" { print "  theme: set theme = \"" (d == "push" ? $3 : $4) "\" (now " ((d == "push" ? $4 : $3) == "" ? "none" : (d == "push" ? $4 : $3)) ") in niruwm config.toml; nothing else in that file changes" }' "$sync_d"
  fi
  head -n 12 "$FLEET_WORK/send.$1" | sed 's/^/    /'
  sync_total=$(grep -c . "$FLEET_WORK/send.$1" || :)
  [ "$sync_total" -le 12 ] || say "    ... and $((sync_total - 12)) more"
  sync_x=$(awk -F '\t' '$1 ~ /^x/ { n++ } END { print n + 0 }' "$sync_d")
  [ "$sync_x" = 0 ] || say "  not synced: $sync_x excluded files (secrets or [sync] exclude)"
  return 0
}
# The script that takes a snapshot on the receiving host before files are
# written: `nirux snapshot` with the overwritten paths included, or, with an
# older NIRUX there, a tarball of those paths. Paths come on lines after it.
sync_receiver_script() {
  cat <<SCRIPT
note='sync $2 $(uname -n | tr -cd 'A-Za-z0-9._-')'
SCRIPT
  cat <<'SCRIPT'
cd "$HOME" || exit 1
t=$(mktemp "${TMPDIR:-/tmp}/nirux-sync.XXXXXX") || exit 1
trap 'rm -f "$t" "$t.e"' EXIT
cat > "$t" <<'NIRUX_LIST_END'
SCRIPT
  cat "$1"
  cat <<'SCRIPT'
NIRUX_LIST_END
n=.local/bin/nirux
if [ -x "$n" ] && "$n" snapshot --help >/dev/null 2>&1; then
  if out=$("$n" snapshot --reason sync --note "$note" --include-from "$t" 2>&1); then
    echo "snapshot=$(printf '%s\n' "$out" | sed -n 's/^Snapshot: //p' | head -n 1)"
  else
    printf '%s\n' "$out" >&2; echo snapshot=failed
  fi
else
  while IFS= read -r p; do [ ! -f "$p" ] || printf '%s\n' "$p"; done < "$t" > "$t.e"
  if [ ! -s "$t.e" ]; then echo snapshot=none; exit 0; fi
  d=${XDG_STATE_HOME:-$HOME/.local/state}/nirux/sync-backups
  f=$d/$(date +%Y%m%d-%H%M%S)-before-sync.tar.gz
  if (umask 077; mkdir -p "$d" && tar -czf "$f" -T "$t.e"); then echo "snapshot=backup $f"; else echo snapshot=failed; fi
fi
SCRIPT
}
# Set the top-level theme key of niruwm's config.toml to $1, keeping the file,
# its link and its mode; the rest of the file is not touched.
theme_set_script() {
  printf "v='%s'\n" "$1"
  cat <<'SCRIPT'
cd "$HOME" || exit 1
f=.config/niruwm/config.toml
[ -f "$f" ] || { echo theme=noconfig; exit 0; }
awk -v v="$v" '
  !done && /^[[:space:]]*\[/ { print "theme = \"" v "\""; done = 1 }
  !done && /^[[:space:]]*theme[[:space:]]*=/ { print "theme = \"" v "\""; done = 1; next }
  { print }
  END { if (!done) print "theme = \"" v "\"" }' "$f" > "$f.nirux-sync.$$" &&
  cat "$f.nirux-sync.$$" > "$f" && rm -f "$f.nirux-sync.$$" && echo theme=ok || { rm -f "$f.nirux-sync.$$"; echo theme=failed; }
SCRIPT
}
sync_items_of() { # paths on stdin -> item names
  awk -F '\t' 'NR == FNR { r[$2] = $1; next }
    { for (p in r) if ($0 == p || index($0, p "/") == 1) print r[p] }' "$FLEET_WORK/sync.roots" - | LC_ALL=C sort -u
}
sync_item_advice() {
  for sync_i in $(cat); do
    case "$sync_i" in
      theme) say '  theme: run niructl reload in the NIRU session there (or log out and in)' ;;
      lock) say '  lock: used from the next lock or screensaver start' ;;
      quotes) say '  quotes: shown from the next lock or screensaver start' ;;
      launcher) say '  launcher: used the next time it opens' ;;
      sounds) say '  sounds: used from the next sound' ;;
      keys.d) say '  keys.d: shown the next time the key cheat sheet opens' ;;
      sid) say '  sid: available to the SID player right away' ;;
    esac
  done
}
# Hash check of the received files against the sender's scan.
sync_verify() { # SENDER-SCAN RECEIVER-SCAN LIST
  awk -F '\t' 'FNR == 1 { side++ } side == 1 && $1 == "f" { a[$5] = $3; next }
    side == 2 && $1 == "f" { b[$5] = $3; next }
    side == 3 { n++; if (!($0 in b) || a[$0] != b[$0]) { bad++; print "  not received: " $0 | "cat 1>&2" } }
    END { exit bad ? 1 : 0 }' "$1" "$2" "$3"
}
sync_push() {
  sync_args "$@"
  [ -n "$SYNC_HOSTS" ] || [ "$SYNC_ALL" = 1 ] || die 'usage: nirux sync push HOST...|--all [ITEM...]'
  [ -z "$SYNC_HOSTS" ] || [ "$SYNC_ALL" = 0 ] || die 'give host names or --all, not both'
  fleet_work
  sync_prepare $SYNC_ITEMS
  if [ "$SYNC_ALL" = 1 ]; then
    say 'Checking the fleet...'
    SYNC_HOSTS=$(sync_fleet_hosts)
    [ -n "$SYNC_HOSTS" ] || { say 'No other online NIRUX host to push to.'; return 0; }
  else
    fleet_tailscale >/dev/null 2>&1 && FLEET_SELF=$(awk -F '\t' '$1 == "self" { print $2; exit }' "$FLEET_WORK/peers") || :
  fi
  SYNC_LOCAL=_here
  sync_scan "$SYNC_LOCAL" 1 &
  for sync_h in $SYNC_HOSTS; do sync_is_self "$sync_h" || sync_scan "$sync_h" 0 & done
  wait
  [ "$(sync_field "$SYNC_LOCAL" rc)" = 0 ] || die 'could not scan this machine'
  say "Items: $SYNC_ITEMS"
  sync_targets='' sync_failed=''
  for sync_h in $SYNC_HOSTS; do
    if sync_is_self "$sync_h"; then say "== $sync_h: this machine, skipped"; continue; fi
    sync_st=$(sync_host_state "$sync_h")
    if [ "$sync_st" != ok ]; then say "== $(sync_host_problem "$sync_h" "$sync_st"), skipped"; continue; fi
    if sync_plan "$sync_h" push; then
      sync_targets="$sync_targets $sync_h"
      say "$SYNC_THEME_VALUE" > "$FLEET_WORK/theme.$sync_h"
    fi
  done
  [ -n "$sync_targets" ] || { say 'Nothing to push.'; return 0; }
  say 'Files that only the receiving machine has are kept. Each receiver takes a snapshot first.'
  if [ "$SYNC_DRY" = 1 ]; then say 'Dry run: nothing was copied.'; return 0; fi
  if [ "$SYNC_YES" != 1 ]; then
    nirux_confirm 'Push now? [y/N] ' || { say 'Cancelled; nothing was copied.'; return 1; }
  fi
  sync_done=
  for sync_h in $sync_targets; do
    sync_theme=$(cat "$FLEET_WORK/theme.$sync_h")
    sync_overwrite=$FLEET_WORK/overwrite.$sync_h
    [ -z "$sync_theme" ] || say .config/niruwm/config.toml >> "$sync_overwrite"
    sync_receiver_script "$sync_overwrite" from | sync_ssh "$sync_h" sh -s > "$FLEET_WORK/recv.$sync_h" 2>&1 || :
    sync_snap=$(sed -n 's/^snapshot=//p' "$FLEET_WORK/recv.$sync_h" | head -n 1)
    case "$sync_snap" in
      ''|failed) say "== $sync_h: FAILED: could not take a snapshot there; nothing was copied"
        sed 's/^/   /' "$FLEET_WORK/recv.$sync_h" | grep -v '^   snapshot=' || :
        sync_failed="$sync_failed $sync_h"; continue ;;
      none) say "== $sync_h: nothing there to back up (only new files)" ;;
      backup\ *) say "== $sync_h: older NIRUX without snapshots; backed up the files to replace: ${sync_snap#backup }" ;;
      *) say "== $sync_h: snapshot $sync_snap" ;;
    esac
    sync_ok=1
    if [ -s "$FLEET_WORK/send.$sync_h" ]; then
      if [ "$(sync_method "$sync_h")" = rsync ]; then
        ( cd "$HOME" && rsync -a --files-from="$FLEET_WORK/send.$sync_h" \
            -e "ssh -o BatchMode=yes -o ConnectTimeout=${NIRUX_FLEET_TIMEOUT:-5}" ./ "$sync_h:" ) || sync_ok=0
      else
        ( cd "$HOME" && tar -czf - -T "$FLEET_WORK/send.$sync_h" ) | sync_ssh "$sync_h" tar -xzf - || sync_ok=0
      fi
    fi
    if [ -n "$sync_theme" ]; then
      sync_t=$(theme_set_script "$sync_theme" | sync_ssh "$sync_h" sh -s 2>/dev/null | sed -n 's/^theme=//p')
      case "$sync_t" in
        ok) say "== $sync_h: theme set to $sync_theme" ;;
        noconfig) say "== $sync_h: no niruwm config.toml there; theme not set" ;;
        *) say "== $sync_h: could not set the theme"; sync_ok=0 ;;
      esac
    fi
    if [ -s "$FLEET_WORK/send.$sync_h" ]; then
      sync_scan "$sync_h" 0
      sync_verify "$FLEET_WORK/scan.$SYNC_LOCAL" "$FLEET_WORK/scan.$sync_h" "$FLEET_WORK/send.$sync_h" || sync_ok=0
    fi
    if [ "$sync_ok" = 1 ]; then
      say "== $sync_h: pushed $(grep -c . "$FLEET_WORK/send.$sync_h" || :) files"
      sync_done="$sync_done $sync_h"
      { cat "$FLEET_WORK/send.$sync_h"; [ -z "$sync_theme" ] || say .config/niruwm/themes; } | sync_items_of | sync_item_advice
    else
      say "== $sync_h: FAILED (the snapshot there has the state before)"
      sync_failed="$sync_failed $sync_h"
    fi
  done
  say "Sync push: done:${sync_done:- none}; failed:${sync_failed:- none}"
  [ -z "$sync_failed" ]
}
sync_pull() {
  sync_args "$@"
  [ "$SYNC_ALL" = 0 ] || die 'pull takes one host, not --all'
  set -- $SYNC_HOSTS
  [ "$#" = 1 ] || die 'usage: nirux sync pull HOST [ITEM...]'
  sync_h=$1
  fleet_work
  sync_prepare $SYNC_ITEMS
  fleet_tailscale >/dev/null 2>&1 && FLEET_SELF=$(awk -F '\t' '$1 == "self" { print $2; exit }' "$FLEET_WORK/peers") || :
  sync_is_self "$sync_h" && die "$sync_h is this machine"
  SYNC_LOCAL=_here
  sync_scan "$SYNC_LOCAL" 1 &
  sync_scan "$sync_h" 0 &
  wait
  [ "$(sync_field "$SYNC_LOCAL" rc)" = 0 ] || die 'could not scan this machine'
  sync_st=$(sync_host_state "$sync_h")
  [ "$sync_st" = ok ] || die "$(sync_host_problem "$sync_h" "$sync_st")"
  say "Items: $SYNC_ITEMS"
  sync_local_note
  sync_plan "$sync_h" pull || return 0
  sync_theme=$SYNC_THEME_VALUE
  say 'Files that only this machine has are kept. A snapshot of this machine is taken first.'
  if [ "$SYNC_DRY" = 1 ]; then say 'Dry run: nothing was copied.'; return 0; fi
  if [ "$SYNC_YES" != 1 ]; then
    nirux_confirm 'Pull now? [y/N] ' || { say 'Cancelled; nothing was copied.'; return 1; }
  fi
  sync_overwrite=$FLEET_WORK/overwrite.$sync_h
  [ -z "$sync_theme" ] || say .config/niruwm/config.toml >> "$sync_overwrite"
  snapshot_create sync '' '' "sync pull from $sync_h" "$sync_overwrite" || die 'could not take a snapshot here; nothing was copied'
  sync_stage=$FLEET_WORK/stage
  mkdir -p "$sync_stage"
  if [ -s "$FLEET_WORK/send.$sync_h" ]; then
    if [ "$(sync_method "$sync_h")" = rsync ]; then
      rsync -a --files-from="$FLEET_WORK/send.$sync_h" \
        -e "ssh -o BatchMode=yes -o ConnectTimeout=${NIRUX_FLEET_TIMEOUT:-5}" "$sync_h:" "$sync_stage/" || die "could not copy from $sync_h; nothing was changed here"
    else
      { cat <<'SCRIPT'
cd "$HOME" || exit 1
t=$(mktemp "${TMPDIR:-/tmp}/nirux-sync.XXXXXX") || exit 1
trap 'rm -f "$t"' EXIT
cat > "$t" <<'NIRUX_LIST_END'
SCRIPT
        cat "$FLEET_WORK/send.$sync_h"
        say NIRUX_LIST_END
        say 'tar -czf - -T "$t"'
      } | sync_ssh "$sync_h" sh -s | tar -xzf - -C "$sync_stage" || die "could not copy from $sync_h; nothing was changed here"
    fi
    # Only the planned files leave the staging directory, after a hash check.
    while IFS= read -r sync_p; do
      [ -f "$sync_stage/$sync_p" ] || die "$sync_p did not arrive; nothing was changed here"
      sync_sum=$(sha256sum < "$sync_stage/$sync_p" | cut -c 1-64)
      awk -F '\t' -v p="$sync_p" -v s="$sync_sum" '$1 == "f" && $5 == p { ok = ($3 == s) } END { exit !ok }' "$FLEET_WORK/scan.$sync_h" ||
        die "$sync_p changed during the copy; nothing was changed here (run the pull again)"
    done < "$FLEET_WORK/send.$sync_h"
    sync_failed=0
    while IFS= read -r sync_p; do
      mkdir -p "$(dirname "$HOME/$sync_p")" && cp -p "$sync_stage/$sync_p" "$HOME/$sync_p" ||
        { say "nirux: could not write $sync_p" >&2; sync_failed=1; }
    done < "$FLEET_WORK/send.$sync_h"
    [ "$sync_failed" = 0 ] || die 'some files were not written; nirux restore brings back the state before'
  fi
  if [ -n "$sync_theme" ]; then
    case "$(theme_set_script "$sync_theme" | sh -s | sed -n 's/^theme=//p')" in
      ok) say "Theme set to $sync_theme." ;;
      noconfig) say 'No niruwm config.toml here; theme not set.' ;;
      *) die 'could not set the theme' ;;
    esac
  fi
  say "Pulled $(grep -c . "$FLEET_WORK/send.$sync_h" || :) files from $sync_h. Undo with: nirux restore (the snapshot above)."
  { cat "$FLEET_WORK/send.$sync_h"; [ -z "$sync_theme" ] || say .config/niruwm/themes; } | sync_items_of | sync_item_advice
}
sync_command() {
  sync_action=${1:-status}
  [ "$#" = 0 ] || shift
  case "$sync_action" in
    status) sync_status "$@" ;;
    push) sync_push "$@" ;;
    pull) sync_pull "$@" ;;
    items) sync_items_list ;;
    --help|-h|help) sync_usage ;;
    *) die "unknown sync command: $sync_action (status, push, pull or items)" ;;
  esac
}
