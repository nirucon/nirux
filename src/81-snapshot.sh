# nirux snapshot / restore: the user's suite configuration as a tarball in
# ~/.local/state/nirux/snapshots, taken before every update and on request.
# A snapshot holds MANIFEST (metadata, roots and one line per file with its
# hash and size) and home/ (the files, by path relative to $HOME). Programs are
# not part of it: nirux rollback switches program generations.
SNAPSHOT_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/nirux/snapshots
SNAPSHOT_CONFIG=$NIRUX_CONFIG/snapshots.toml
SYNC_CONFIG=$NIRUX_CONFIG/sync.toml
SNAPSHOT_MAX_BYTES=16777216
SNAPSHOT_KEEP_DEFAULT=3
TAB=$(printf '\t')
# Scalar KEY of [SECTION] in FILE, unquoted; nothing when absent.
toml_value() {
  [ -f "$1" ] || return 0
  awk -v table="$2" -v want="$3" '
    { line = $0; sub(/^[[:space:]]*#.*/, "", line); sub(/[[:space:]]+#[^"\047]*$/, "", line) }
    line ~ /^[[:space:]]*\[/ { s = line; gsub(/[][[:space:]]/, "", s); sec = s; next }
    sec != table { next }
    {
      eq = index(line, "="); if (eq == 0) next
      key = substr(line, 1, eq - 1); gsub(/[[:space:]"]/, "", key)
      if (key != want) next
      v = substr(line, eq + 1); sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
      if (v ~ /^".*"$/ || v ~ /^\047.*\047$/) v = substr(v, 2, length(v) - 2)
      print v; exit
    }' "$1" 2>/dev/null || :
}
# A path below $HOME as a relative path, for the snapshot layout.
home_rel() {
  case "$1" in "$HOME"/?*) say "${1#"$HOME"/}" ;; *) return 1 ;; esac
}
snapshot_keep() {
  snap_keep=$(toml_value "$SNAPSHOT_CONFIG" snapshots keep)
  case "$snap_keep" in
    ''|*[!0-9]*|0) say "$SNAPSHOT_KEEP_DEFAULT" ;;
    *) say "$snap_keep" ;;
  esac
}
snapshot_strict() {
  [ "${NIRUX_SNAPSHOT_STRICT:-}" = 1 ] || [ "$(toml_value "$SNAPSHOT_CONFIG" snapshots strict)" = true ]
}
# What a snapshot covers: "snapshot<TAB>PATH" relative to $HOME. Every config
# directory of the suite and of the extras NIRUX installs, the files NIRUX
# writes into (picom, kitty, fish), registered keys and launcher favourites.
# nirushare is left out: its config holds an upload token.
snapshot_roots() {
  snap_c=$(home_rel "${XDG_CONFIG_HOME:-$HOME/.config}" || say .config)
  snap_d=$(home_rel "${XDG_DATA_HOME:-$HOME/.local/share}" || say .local/share)
  snap_s=$(home_rel "${XDG_STATE_HOME:-$HOME/.local/state}" || say .local/state)
  for snap_p in niruwm niruui nirubar nirulauncher nirunotify nirulock niruscreensaver niruclip nirushot \
    niruwallpaper nirudisplay niruthemeselector nirux niru NIRU \
    $(extras_table | awk '{ print $1 }'); do
    printf 'snapshot\t%s/%s\n' "$snap_c" "$snap_p"
  done
  for snap_p in picom.conf kitty/kitty.conf fish/config.fish; do printf 'snapshot\t%s/%s\n' "$snap_c" "$snap_p"; done
  printf 'snapshot\t%s/niru/keys.d\n' "$snap_d"
  printf 'snapshot\t%s/nirulauncher/favorites.tsv\n' "$snap_s"
  printf 'snapshot\t%s/nirulauncher/favorites-removed.tsv\n' "$snap_s"
}
# A shell script, for `sh -s` here or on another host, that lists the regular
# files under the roots in $1 (ITEM<TAB>PATH relative to $HOME) as
#   f<TAB>ITEM<TAB>SHA256<TAB>BYTES<TAB>PATH   or   x<TAB>ITEM<TAB>REASON<TAB>PATH
# A file is excluded (x) when a prefix in $2 matches, when its name or content
# looks like a secret, or when it is larger than $3 bytes (0: no limit; item
# "include" has none). With $4 = 1 it adds t<TAB>theme<TAB>NAME, the theme key
# of niruwm's config.toml. First come nirux=, snapshot=, rsync= and host= lines.
# Hashing is batched with find -exec ... +, so a large music folder is cheap.
scan_script() {
  printf 'max=%s\ntheme=%s\n' "$3" "$4"
  cat <<'SCAN'
cd "$HOME" || exit 1
t=$(mktemp -d "${TMPDIR:-/tmp}/nirux-scan.XXXXXX") || exit 1
trap 'rm -rf "$t"' EXIT
if [ -e .local/bin/nirux ]; then
  echo "nirux=$(sed -n 's/^VERSION=//p' .local/bin/nirux 2>/dev/null | head -n 1)"
  if .local/bin/nirux snapshot --help >/dev/null 2>&1; then echo snapshot=1; else echo snapshot=0; fi
else
  echo nirux=absent
fi
if command -v rsync >/dev/null 2>&1; then echo rsync=1; else echo rsync=0; fi
echo "host=$(uname -n)"
cat > "$t/roots" <<'NIRUX_ROOTS_END'
SCAN
  cat "$1"
  say NIRUX_ROOTS_END
  say "cat > \"\$t/exclude\" <<'NIRUX_EXCLUDE_END'"
  cat "$2"
  say NIRUX_EXCLUDE_END
  cat <<'SCAN'
tab=$(printf '\t')
: > "$t/sha"; : > "$t/size"; : > "$t/secret"
while IFS="$tab" read -r item path; do
  [ -e "$path" ] || continue
  find -H "$path" -type f -exec sha256sum {} + >> "$t/sha" 2>/dev/null
  find -H "$path" -type f -exec wc -c {} + >> "$t/size" 2>/dev/null
  find -H "$path" -type f -size -1024k -exec grep -liE '(token|secret|passw(or)?d|api[_-]?key|private[_-]?key).?[[:space:]]*[:=][[:space:]]*.?[A-Za-z0-9+/_.=-]{8,}' {} + >> "$t/secret" 2>/dev/null
done < "$t/roots"
awk -F "$tab" -v max="$max" -v tab="$tab" '
  FILENAME == ARGV[1] { if ($2 != "") { n++; root[n] = $2; ritem[n] = $1 }; next }
  FILENAME == ARGV[2] { if ($0 != "") { ne++; ex[ne] = $0 }; next }
  FILENAME == ARGV[3] { secret[$0] = 1; next }
  FILENAME == ARGV[4] {
    l = $0; sub(/^[[:space:]]+/, "", l); sp = index(l, " ")
    if (sp) size[substr(l, sp + 1)] = substr(l, 1, sp - 1)
    next
  }
  {
    if (substr($0, 1, 1) == "\\") next
    h = substr($0, 1, 64); p = substr($0, 67)
    if (p == "" || index(p, tab) || seen[p]++) next
    best = 0; bl = 0
    for (i = 1; i <= n; i++) {
      r = root[i]
      if ((p == r || index(p, r "/") == 1) && length(r) > bl) { best = i; bl = length(r) }
    }
    if (!best) next
    it = ritem[best]; why = ""
    for (i = 1; i <= ne; i++) if (p == ex[i] || index(p, ex[i] "/") == 1) why = "excluded"
    b = p; sub(/.*\//, "", b); b = tolower(b)
    if (why == "" && (b ~ /token|secret|credential|password|passwd/ || b ~ /\.(pem|key|gpg|kdbx|p12)$/ || b ~ /^id_(rsa|dsa|ecdsa|ed25519)/)) why = "secret"
    if (why == "" && (p in secret)) why = "secret"
    if (why == "" && max > 0 && it != "include" && size[p] + 0 > max) why = "large"
    if (why != "") print "x" tab it tab why tab p
    else print "f" tab it tab h tab (size[p] + 0) tab p
  }' "$t/roots" "$t/exclude" "$t/secret" "$t/size" "$t/sha"
if [ "$theme" = 1 ] && [ -f .config/niruwm/config.toml ]; then
  v=$(awk '/^[[:space:]]*\[/ { exit } /^[[:space:]]*theme[[:space:]]*=/ { sub(/^[^=]*=[[:space:]]*"/, ""); sub(/".*/, ""); print; exit }' .config/niruwm/config.toml)
  printf 't\ttheme\t%s\n' "$v"
fi
SCAN
}
snapshot_human() {
  awk -v b="${1:-0}" 'BEGIN {
    if (b < 1024) printf "%d B\n", b
    else if (b < 1048576) printf "%.1f KiB\n", b / 1024
    else if (b < 1073741824) printf "%.1f MiB\n", b / 1048576
    else printf "%.1f GiB\n", b / 1073741824 }'
}
# "SEQ<TAB>ID" for every snapshot, oldest first.
snapshot_index() {
  for snap_a in "$SNAPSHOT_DIR"/*.tar.gz; do
    [ -f "$snap_a" ] || continue
    snap_i=${snap_a##*/}; snap_i=${snap_i%.tar.gz}
    snap_q=$(sed -n 's/^seq //p' "$SNAPSHOT_DIR/$snap_i.manifest" 2>/dev/null | head -n 1)
    case "$snap_q" in ''|*[!0-9]*) snap_q=0 ;; esac
    printf '%s\t%s\n' "$snap_q" "$snap_i"
  done | LC_ALL=C sort -t "$TAB" -k1,1n -k2,2
}
snapshot_rotate() {
  snap_keep=$(snapshot_keep)
  snap_total=$(snapshot_index | grep -c . || :)
  [ "$snap_total" -gt "$snap_keep" ] || return 0
  snapshot_index | head -n "$((snap_total - snap_keep))" | while IFS="$TAB" read -r _snap_seq snap_old; do
    rm -f "$SNAPSHOT_DIR/$snap_old.tar.gz" "$SNAPSHOT_DIR/$snap_old.manifest"
    say "Removed old snapshot $snap_old (keeping $snap_keep)."
  done
}
# snapshot_create REASON FROM TO NOTE [INCLUDE-FILE]: take a snapshot and print
# "Snapshot: ID". INCLUDE-FILE lists extra paths relative to $HOME (sync uses
# it for the files it is about to overwrite, music included). Runs in a
# subshell and returns 1 on failure; it never ends the caller.
snapshot_create() (
  snap_fail() { say "nirux: snapshot failed: $*" >&2; exit 1; }
  snap_reason=$1 snap_from=$2 snap_to=$3 snap_note=$4 snap_include=${5:-}
  for snap_tool in tar gzip sha256sum find; do
    command -v "$snap_tool" >/dev/null 2>&1 || snap_fail "$snap_tool is missing"
  done
  snap_t=$(mktemp -d "${TMPDIR:-/tmp}/nirux-snapshot.XXXXXX") || snap_fail 'no temporary directory'
  trap 'rm -rf "$snap_t"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  snapshot_roots > "$snap_t/roots"
  if [ -n "$snap_include" ]; then
    while IFS= read -r snap_p; do
      case "/$snap_p/" in //|*/../*|*/./*|///*) snap_fail "invalid include path: $snap_p" ;; esac
      printf 'include\t%s\n' "$snap_p" >> "$snap_t/roots"
    done < "$snap_include"
  fi
  : > "$snap_t/exclude"
  scan_script "$snap_t/roots" "$snap_t/exclude" "$SNAPSHOT_MAX_BYTES" 0 | sh -s > "$snap_t/scan" ||
    snap_fail 'could not list the configuration files'
  awk -F '\t' '$1 == "f" { print $5 }' "$snap_t/scan" > "$snap_t/files"
  snap_files=$(grep -c . "$snap_t/files" || :)
  if [ "$snap_files" = 0 ]; then
    say 'Snapshot: none (no NIRUX configuration files here)'
    exit 0
  fi
  mkdir -p "$snap_t/stage/home" || snap_fail 'no staging directory'
  while IFS= read -r snap_p; do
    mkdir -p "$snap_t/stage/home/${snap_p%/*}" && cp -p "$HOME/$snap_p" "$snap_t/stage/home/$snap_p" ||
      snap_fail "could not copy $snap_p"
  done < "$snap_t/files"
  snap_bytes=$(awk -F '\t' '$1 == "f" { s += $4 } END { print s + 0 }' "$snap_t/scan")
  snap_ts=$(date +%Y%m%d-%H%M%S)
  snap_from=$(printf '%s' "$snap_from" | tr -cd 'A-Za-z0-9._-')
  snap_to=$(printf '%s' "$snap_to" | tr -cd 'A-Za-z0-9._-')
  case "$snap_reason" in
    update) snap_base="$snap_ts-${snap_from:-unknown}-to-${snap_to:-unknown}" ;;
    manual) snap_base="$snap_ts-manual" ;;
    restore) snap_base="$snap_ts-before-restore" ;;
    sync) snap_base="$snap_ts-before-sync" ;;
    *) snap_base="$snap_ts-$(printf '%s' "$snap_reason" | tr -cd 'a-z0-9-')" ;;
  esac
  ( umask 077; mkdir -p "$SNAPSHOT_DIR" ) || snap_fail "could not create $SNAPSHOT_DIR"
  snap_id=$snap_base snap_n=1
  while [ -e "$SNAPSHOT_DIR/$snap_id.tar.gz" ]; do snap_n=$((snap_n + 1)); snap_id=$snap_base-$snap_n; done
  snap_seq=$(cat "$SNAPSHOT_DIR/.seq" 2>/dev/null || :)
  case "$snap_seq" in ''|*[!0-9]*) snap_seq=$(snapshot_index | tail -n 1 | cut -f 1) ;; esac
  snap_seq=$((${snap_seq:-0} + 1))
  say "$snap_seq" > "$SNAPSHOT_DIR/.seq" || snap_fail "could not write $SNAPSHOT_DIR/.seq"
  {
    say 'nirux-snapshot 1'
    say "id $snap_id"
    say "seq $snap_seq"
    say "created $(date '+%Y-%m-%d %H:%M:%S %z')"
    say "host $(uname -n)"
    say "nirux $VERSION"
    say "reason $snap_reason"
    say "from $snap_from"
    say "to $snap_to"
    say "note $(printf '%s' "$snap_note" | tr -d '\000-\037')"
    say "files $snap_files"
    say "bytes $snap_bytes"
    awk -F '\t' '{ print "root " $2 }' "$snap_t/roots"
    grep "^[fx]$TAB" "$snap_t/scan" || :
  } > "$snap_t/stage/MANIFEST" || snap_fail 'could not write the manifest'
  ( umask 077; tar -czf "$SNAPSHOT_DIR/.$snap_id.tmp" -C "$snap_t/stage" MANIFEST home ) ||
    { rm -f "$SNAPSHOT_DIR/.$snap_id.tmp"; snap_fail 'could not write the archive (disk full?)'; }
  mv -f "$SNAPSHOT_DIR/.$snap_id.tmp" "$SNAPSHOT_DIR/$snap_id.tar.gz" || snap_fail 'could not store the archive'
  snap_archive=$(wc -c < "$SNAPSHOT_DIR/$snap_id.tar.gz" | tr -d ' ')
  { cat "$snap_t/stage/MANIFEST"; say "archive_bytes $snap_archive"; } > "$SNAPSHOT_DIR/$snap_id.manifest" ||
    snap_fail 'could not write the manifest'
  chmod 600 "$SNAPSHOT_DIR/$snap_id.tar.gz" "$SNAPSHOT_DIR/$snap_id.manifest" 2>/dev/null || :
  say "Snapshot: $snap_id"
  say "  $snap_files files, $(snapshot_human "$snap_bytes") ($(snapshot_human "$snap_archive") compressed): $SNAPSHOT_DIR/$snap_id.tar.gz"
  awk -F '\t' '$1 == "x" { print "  not included (" $3 "): " $4 }' "$snap_t/scan"
  snap_share=${XDG_CONFIG_HOME:-$HOME/.config}/nirushare
  [ ! -d "$snap_share" ] || say "  not included (holds an upload token): $snap_share"
  snapshot_rotate
)
# Before an update: a failed snapshot warns and the update goes on, unless
# [snapshots] strict = true (or NIRUX_SNAPSHOT_STRICT=1) makes it stop.
snapshot_guard() {
  say 'Saving a snapshot of your NIRUX configuration...'
  if snapshot_create "$@"; then return 0; fi
  if snapshot_strict; then
    die "the configuration snapshot failed and snapshots are strict ($SNAPSHOT_CONFIG); nothing was changed"
  fi
  say "nirux: warning: no configuration snapshot was taken; continuing. To stop instead, set [snapshots] strict = true in $SNAPSHOT_CONFIG." >&2
}
installed_version() {
  inst_v=$(sed -n 's/^VERSION=//p' "$BIN/nirux" 2>/dev/null | head -n 1)
  say "${inst_v:-$VERSION}"
}
snapshot_usage() {
  say 'Usage: nirux snapshot [--note TEXT]'
  say '       nirux snapshot list'
  say '       nirux restore [ID|latest] [--dry-run] [--yes]'
  say "Snapshots: $SNAPSHOT_DIR (keep $(snapshot_keep); [snapshots] keep = N and strict = true in $SNAPSHOT_CONFIG)."
}
snapshot_list() {
  snapshot_index > "${TMPDIR:-/tmp}/.nirux-snapshots.$$" || :
  if [ ! -s "${TMPDIR:-/tmp}/.nirux-snapshots.$$" ]; then
    rm -f "${TMPDIR:-/tmp}/.nirux-snapshots.$$"
    say "No snapshots in $SNAPSHOT_DIR."; return 0
  fi
  {
    printf 'ID\tCREATED\tFILES\tSIZE\tNOTE\n'
    while IFS="$TAB" read -r _snap_seq snap_i; do
      snap_m=$SNAPSHOT_DIR/$snap_i.manifest
      snap_note=$(sed -n 's/^note //p' "$snap_m" 2>/dev/null | head -n 1)
      [ -n "$snap_note" ] || snap_note=$(sed -n 's/^reason //p' "$snap_m" 2>/dev/null | head -n 1)
      printf '%s\t%s\t%s\t%s\t%s\n' "$snap_i" \
        "$(sed -n 's/^created \([^ ]* [0-9:]*\).*/\1/p' "$snap_m" 2>/dev/null | head -n 1)" \
        "$(sed -n 's/^files //p' "$snap_m" 2>/dev/null | head -n 1)" \
        "$(snapshot_human "$(wc -c < "$SNAPSHOT_DIR/$snap_i.tar.gz" | tr -d ' ')")" "${snap_note:--}"
    done < "${TMPDIR:-/tmp}/.nirux-snapshots.$$"
  } | awk -F '\t' '
    { for (i = 1; i <= NF; i++) { c[NR, i] = $i; if (length($i) > w[i]) w[i] = length($i) } n = NR }
    END { for (r = 1; r <= n; r++) { line = ""
      for (i = 1; i <= 5; i++) line = line (i < 5 ? sprintf("%-" (w[i] + 2) "s", c[r, i]) : c[r, i])
      print line } }'
  rm -f "${TMPDIR:-/tmp}/.nirux-snapshots.$$"
  say "Restore with: nirux restore ID|latest [--dry-run]"
}
snapshot_command() {
  case "${1:-}" in
    list) [ "$#" = 1 ] || die 'usage: nirux snapshot list'; snapshot_list; return ;;
    --help|-h|help) snapshot_usage; return 0 ;;
  esac
  snap_note='' snap_reason=manual snap_inc=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --note) [ "$#" -ge 2 ] || die 'missing --note text'; snap_note=$2; shift ;;
      --reason) [ "$#" -ge 2 ] || die 'missing --reason word'; snap_reason=$2; shift
        case "$snap_reason" in ''|*[!a-z-]*) die 'reason must be lower-case letters' ;; esac ;;
      --include-from) [ "$#" -ge 2 ] || die 'missing --include-from file'; snap_inc=$2; shift
        [ -f "$snap_inc" ] || die "no such file: $snap_inc" ;;
      *) die "unknown snapshot option: $1 (see nirux snapshot --help)" ;;
    esac
    shift
  done
  snapshot_create "$snap_reason" '' '' "$snap_note" "$snap_inc" || die 'snapshot failed'
}
# Ask a y/N question; without a terminal the answer comes from standard input
# and is not echoed, so the next output starts on a new line.
nirux_confirm() {
  printf '%s' "$1"
  read -r confirm_answer || confirm_answer=
  [ -t 0 ] || say ''
  case "$confirm_answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}
# What to reload after configuration files changed; paths on standard input.
config_reload_advice() {
  awk '
    /(^|\/)(niruwm|nirubar)\// || /niru\/keys\.d\// { a["Window manager, bar, theme: run niructl reload in the NIRU session (or log out and in)."] = 1; next }
    /(^|\/)(niruui|nirulock|niruscreensaver)\// || /niru\/quotes/ || /(^|\/)Music\/SID\// { a["Lock and screensaver: used from the next lock or screensaver start."] = 1; next }
    /nirulauncher\// { a["Launcher: used the next time it opens."] = 1; next }
    /nirunotify\// { a["Notifications: log out and in (nirunotify reads its config at start)."] = 1; next }
    /picom\.conf$/ { a["Compositor: log out and in to restart picom."] = 1; next }
    /(^|\/)(kitty|fish)\// || /(^|\/)nirux\/(theme|fish)\// { a["Terminal: open a new kitty window."] = 1; next }
    /(^|\/)nirux\/sounds/ { a["Sounds: used from the next sound."] = 1; next }
    { a["Other programs: restart them to read the restored files."] = 1 }
    END { for (k in a) print "  " k }' | LC_ALL=C sort
}
snapshot_resolve() {
  [ -d "$SNAPSHOT_DIR" ] || die "no snapshots yet ($SNAPSHOT_DIR); take one with: nirux snapshot"
  case "$1" in
    ''|latest) snap_id=$(snapshot_index | tail -n 1 | cut -f 2) ;;
    *[!A-Za-z0-9._-]*) die "invalid snapshot id: $1" ;;
    *)
      if [ -f "$SNAPSHOT_DIR/$1.tar.gz" ]; then snap_id=$1
      else
        snap_id=$(snapshot_index | cut -f 2 | grep -F -- "$1" || :)
        [ "$(printf '%s\n' "$snap_id" | grep -c . || :)" -le 1 ] || die "several snapshots match $1; give the full id (nirux snapshot list)"
      fi ;;
  esac
  [ -n "$snap_id" ] && [ -f "$SNAPSHOT_DIR/$snap_id.tar.gz" ] || die "no snapshot ${1:-latest} (nirux snapshot list)"
}
# Compare scans $1 (here, or the snapshot) and $2 (there, or now). One line per
# path: same|changed|here|there<TAB>ITEM<TAB>BYTES-HERE<TAB>BYTES-THERE<TAB>PATH,
# xhere|xthere<TAB>ITEM<TAB>REASON<TAB>-<TAB>PATH, and theme<TAB>theme<TAB>HERE<TAB>THERE.
sync_compare() {
  awk -F '\t' '
    FNR == 1 { side++ }
    side == 1 && $1 == "f" { lh[$5] = $3; ls[$5] = $4; li[$5] = $2; next }
    side == 1 && $1 == "x" { lx[$4] = $2 "\t" $3; next }
    side == 1 && $1 == "t" { lt = $3; ht = 1; next }
    side == 2 && $1 == "f" { rh[$5] = $3; rs[$5] = $4; ri[$5] = $2; next }
    side == 2 && $1 == "x" { rx[$4] = $2 "\t" $3; next }
    side == 2 && $1 == "t" { rt = $3; ht = 1; next }
    END {
      for (p in lh) {
        if (p in rh) st = (lh[p] == rh[p]) ? "same" : "changed"; else st = "here"
        print st "\t" li[p] "\t" ls[p] "\t" ((p in rs) ? rs[p] : 0) "\t" p
      }
      for (p in rh) if (!(p in lh)) print "there\t" ri[p] "\t0\t" rs[p] "\t" p
      for (p in lx) print "xhere\t" lx[p] "\t-\t" p
      for (p in rx) if (!(p in lx)) print "xthere\t" rx[p] "\t-\t" p
      if (ht) print "theme\ttheme\t" lt "\t" rt "\t-"
    }' "$1" "$2" | LC_ALL=C sort -t "$TAB" -k2,2 -k5,5
}
restore_command() {
  rest_id='' rest_dry=0 rest_yes=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run|-n) rest_dry=1 ;;
      --yes|-y) rest_yes=1 ;;
      --help|-h) snapshot_usage; return 0 ;;
      -*) die "unknown restore option: $1" ;;
      *) [ -z "$rest_id" ] || die 'restore takes one snapshot id'; rest_id=$1 ;;
    esac
    shift
  done
  snapshot_resolve "$rest_id"
  rest_id=$snap_id
  lock
  rest_dir=$WORK/restore
  mkdir -p "$rest_dir" || die 'could not create a work directory'
  tar -xzf "$SNAPSHOT_DIR/$rest_id.tar.gz" -C "$rest_dir" || die "could not read snapshot $rest_id"
  [ "$(head -n 1 "$rest_dir/MANIFEST" 2>/dev/null)" = 'nirux-snapshot 1' ] || die "$rest_id is not a NIRUX snapshot"
  # The current state of the same roots, scanned the same way.
  sed -n 's/^root //p' "$rest_dir/MANIFEST" | awk '{ print "now\t" $0 }' > "$WORK/restore-roots"
  : > "$WORK/restore-exclude"
  scan_script "$WORK/restore-roots" "$WORK/restore-exclude" 0 0 | sh -s > "$WORK/restore-now" || die 'could not read the current configuration'
  grep "^f$TAB" "$rest_dir/MANIFEST" > "$WORK/restore-snap" || :
  sync_compare "$WORK/restore-snap" "$WORK/restore-now" > "$WORK/restore-diff"
  say "Snapshot $rest_id"
  sed -n 's/^created /  created: /p; s/^reason /  reason:  /p; s/^note \(..*\)/  note:    \1/p' "$rest_dir/MANIFEST"
  awk -F '\t' '$1 == "changed" || $1 == "here" { print $5 }' "$WORK/restore-diff" > "$WORK/restore-list"
  rest_n=$(grep -c . "$WORK/restore-list" || :)
  rest_same=$(grep -c "^same$TAB" "$WORK/restore-diff" || :)
  rest_new=$(grep -c "^there$TAB" "$WORK/restore-diff" || :)
  while IFS="$TAB" read -r rest_st _rest_item _rest_a _rest_b rest_p; do
    case "$rest_st" in
      changed)
        rest_diff=
        if command -v diff >/dev/null 2>&1; then
          rest_plus=$(diff "$HOME/$rest_p" "$rest_dir/home/$rest_p" 2>/dev/null | grep -c '^>' || :)
          rest_minus=$(diff "$HOME/$rest_p" "$rest_dir/home/$rest_p" 2>/dev/null | grep -c '^<' || :)
          rest_diff=" (+$rest_plus -$rest_minus lines)"
        fi
        say "  restore   $rest_p$rest_diff" ;;
      here)
        if [ -e "$HOME/$rest_p" ]; then say "  restore   $rest_p"
        else say "  recreate  $rest_p (missing now)"; fi ;;
      there) say "  keep      $rest_p (newer than the snapshot; kept)" ;;
    esac
  done < "$WORK/restore-diff"
  say "$rest_n to restore, $rest_same unchanged, $rest_new newer files kept."
  if [ "$rest_n" = 0 ]; then say "Your configuration already matches $rest_id; nothing to restore."; return 0; fi
  if [ "$rest_dry" = 1 ]; then say 'Dry run: nothing was changed.'; return 0; fi
  if [ "$rest_yes" != 1 ]; then
    nirux_confirm 'Restore these files? A snapshot of the current state is taken first. [y/N] ' || { say 'Cancelled; nothing was changed.'; return 1; }
  fi
  snapshot_create restore '' '' "before restoring $rest_id" || die 'could not take the safety snapshot; nothing was restored'
  rest_failed=0
  while IFS= read -r rest_p; do
    mkdir -p "$(dirname "$HOME/$rest_p")" && cp -p "$rest_dir/home/$rest_p" "$HOME/$rest_p" ||
      { say "nirux: could not restore $rest_p" >&2; rest_failed=1; }
  done < "$WORK/restore-list"
  [ "$rest_failed" = 0 ] || die 'some files were not restored; the safety snapshot above has the state before'
  say "Restored $rest_n files from $rest_id. Undo with: nirux restore (the safety snapshot is the latest)."
  say 'To use them:'
  config_reload_advice < "$WORK/restore-list"
}

