# nirux manual: the manual of this release, installed in the program
# generation (current/manual), so it matches the installed programs and works
# offline. A checkout of the repository uses its own docs/manual.
manual_usage() {
  say 'Usage: nirux manual [TOPIC]   open the manual (the index, or the chapter or heading TOPIC)'
  say '       nirux manual --list    list the chapters'
  say '       nirux manual --path    print the directory of the installed manual'
  say '       nirux manual --where TOPIC   print FILE:LINE of the heading TOPIC opens'
  say 'TOPIC is a chapter number or name (06, lock), a heading (scratchpads, "studio mode"),'
  say 'CHAPTER#ANCHOR, or a Swedish word such as lås, skärmdump or studioläge.'
  say 'The manual opens in NIRUNOTE when it is installed, else with xdg-open, else in less.'
}
manual_dir() {
  manual_self=$(readlink -f "$0" 2>/dev/null || say "$0")
  manual_self=${manual_self%/*}
  for manual_candidate in "${NIRUX_MANUAL:-}" "$manual_self/../manual" \
    "$manual_self/docs/manual" "$STATE/current/manual"; do
    [ -n "$manual_candidate" ] || continue
    if [ -f "$manual_candidate/README.md" ]; then
      (CDPATH='' cd -- "$manual_candidate" && pwd)
      return 0
    fi
  done
  return 1
}
manual_chapters() { # DIR -> FILE<TAB>TITLE, in order
  for manual_file in "$1"/[0-9][0-9]-*.md; do
    [ -f "$manual_file" ] || continue
    printf '%s\t%s\n' "${manual_file##*/}" "$(sed -n 's/^# //p' "$manual_file" | head -n 1)"
  done
}
# Every heading outside code blocks: FILE<TAB>LINE<TAB>LEVEL<TAB>ANCHOR<TAB>TEXT,
# with GitHub's anchors (lowercase, punctuation dropped, spaces to hyphens,
# -1, -2 ... for repeats within a file).
manual_headings() { # DIR
  for manual_file in "$1"/README.md "$1"/[0-9][0-9]-*.md; do
    [ -f "$manual_file" ] || continue
    LC_ALL=C awk -v file="${manual_file##*/}" '
      /^(```|~~~)/ { fence = !fence; next }
      fence || !/^#+ / { next }
      {
        level = index($0, " ") - 1
        text = substr($0, level + 2)
        sub(/[ \t]+#*[ \t]*$/, "", text)
        anchor = tolower(text)
        gsub(/`/, "", anchor)
        gsub(/[^a-z0-9 _\200-\377-]/, "", anchor)
        gsub(/ /, "-", anchor)
        if (anchor in seen) { n = seen[anchor] + 1; seen[anchor] = n; anchor = anchor "-" n }
        else seen[anchor] = 0
        gsub(/`/, "", text)
        printf "%s\t%d\t%d\t%s\t%s\n", file, NR, level, anchor, text
      }' "$manual_file"
  done
}
# Swedish (and a few English) words for chapters and headings.
manual_alias() {
  case "$1" in
    hjälp|hjalp|index|innehåll|contents|toc) say README.md ;;
    'kom igång'|'komma igång'|start|introduktion|intro) say 01 ;;
    fönster|fonster|layout|layouter|tiling) say 02 ;;
    arbetsytor|arbetsyta|skrivbord|skärmar|monitorer) say 03 ;;
    scratchpad|scratchpads) say scratchpads ;;
    panel|panelen|statusrad|snabbinställningar|kalender) say 04 ;;
    startmeny|programstartare|sök|sok) say 05 ;;
    lås|las|låsskärm|lasskarm|lock|skärmsläckare|skarmslackare|skärmsläckaren) say 06 ;;
    skärmdump|skarmdump|skärmbild|screenshot|screenshots|inspelning|skärminspelning) say 07 ;;
    tema|teman|bakgrund|bakgrundsbild|bakgrunder|wallpaper) say 08 ;;
    skärm|skarm|bildskärm|bildskärmar|displays|display) say 09 ;;
    ljud|mikrofon|aviseringar|notiser|stör\ ej) say 10 ;;
    studioläge|studiolage|studio) say 'studio mode' ;;
    uppdatera|uppdatering|uppdateringar|update|updates|återställ|rollback) say 11 ;;
    extra|tillägg) say 12 ;;
    felsökning|felsokning|problem|troubleshooting) say 13 ;;
    inställningar|installningar|konfiguration|config|configuration) say 14 ;;
    tangenter|kortkommandon|snabbtangenter|keys|keybindings|tangentbord) say 15 ;;
    kommandon|commands|niructl) say 16 ;;
    *) return 1 ;;
  esac
}
# Resolve TOPIC to FILE<TAB>LINE<TAB>HEADING (LINE 1 and no heading for a whole chapter).
manual_resolve() { # DIR TOPIC
  mr_dir=$1
  mr_topic=$(printf '%s' "$2" | tr 'A-Z' 'a-z' | sed 's/^ *//; s/ *$//')
  if mr_alias=$(manual_alias "$mr_topic"); then mr_topic=$mr_alias; fi
  [ -n "$mr_topic" ] || mr_topic=README.md
  mr_anchor=
  case "$mr_topic" in
    *#*) mr_anchor=${mr_topic#*#}; mr_topic=${mr_topic%%#*} ;;
  esac
  mr_file=
  case "$mr_topic" in
    readme|readme.md|'') mr_file=README.md ;;
    [0-9]|[0-9][0-9])
      mr_number=$(printf '%02d' "${mr_topic#0}")
      for mr_candidate in "$mr_dir/$mr_number"-*.md; do
        [ -f "$mr_candidate" ] && mr_file=${mr_candidate##*/}
      done ;;
    *)
      for mr_candidate in "$mr_dir/$mr_topic" "$mr_dir/$mr_topic.md" "$mr_dir"/[0-9][0-9]-"$mr_topic".md; do
        [ -f "$mr_candidate" ] && { mr_file=${mr_candidate##*/}; break; }
      done ;;
  esac
  if [ -n "$mr_file" ] && [ -z "$mr_anchor" ]; then
    printf '%s\t1\t\n' "$mr_file"
    return 0
  fi
  # A named chapter with an anchor, then an exact anchor or heading anywhere,
  # then a chapter title, then a heading that contains the words.
  manual_headings "$mr_dir" | LC_ALL=C awk -F '\t' -v file="$mr_file" -v anchor="$mr_anchor" -v topic="$mr_topic" '
    function out(i) { printf "%s\t%s\t%s\n", f[i], l[i], t[i]; found = 1; exit }
    { n++; f[n] = $1; l[n] = $2; lv[n] = $3; a[n] = $4; t[n] = $5; lt[n] = tolower($5) }
    END {
      if (file != "") {
        for (i = 1; i <= n; i++) if (f[i] == file && a[i] == anchor) out(i)
        exit 1
      }
      key = topic; gsub(/ /, "-", key)
      for (i = 1; i <= n; i++) if (a[i] == key || lt[i] == topic) out(i)
      for (i = 1; i <= n; i++) if (lv[i] == 1 && index(lt[i], topic)) out(i)
      for (i = 1; i <= n; i++) if (index(lt[i], topic)) out(i)
      exit 1
    }'
}
manual_open() { # FILE LINE HEADING
  if [ -n "${NIRUX_MANUAL_VIEWER:-}" ]; then
    # A test or a user override: VIEWER FILE LINE HEADING.
    exec $NIRUX_MANUAL_VIEWER "$1" "$2" "$3"
  fi
  if [ -n "${DISPLAY:-}" ] && command -v nirunote >/dev/null 2>&1; then
    [ -z "$3" ] || say "Opening the manual at: $3"
    # FILE first: NIRUNOTE before 0.7 ignores the flags and still opens it.
    if [ -n "$3" ]; then nohup nirunote "$1" --read-only --heading "$3" >/dev/null 2>&1 &
    else nohup nirunote "$1" --read-only >/dev/null 2>&1 &
    fi
    return 0
  fi
  if [ -n "${DISPLAY:-}" ] && command -v xdg-open >/dev/null 2>&1; then
    [ -z "$3" ] || say "Opening the manual at: $3"
    nohup xdg-open "$1" >/dev/null 2>&1 &
    return 0
  fi
  if [ -t 1 ] && command -v less >/dev/null 2>&1; then
    exec less -R "+$2" "$1"
  fi
  say "$1"
}
manual_command() {
  shift
  case "${1:-}" in
    -h|--help) manual_usage; return 0 ;;
  esac
  manual=$(manual_dir) || die 'the manual is not installed; it ships with NIRUX releases after 0.12.245 (nirux update)'
  case "${1:-}" in
    --path) [ "$#" = 1 ] || die 'manual --path takes no arguments'; say "$manual" ;;
    --list) [ "$#" = 1 ] || die 'manual --list takes no arguments'
      manual_chapters "$manual" | awk -F '\t' '{ printf "%-2s  %-40s %s\n", substr($1, 1, 2), substr($1, 4, length($1) - 6), $2 }' ;;
    --where)
      shift; [ "$#" -gt 0 ] || die 'manual --where needs a topic'
      found=$(manual_resolve "$manual" "$*") || die "no chapter or heading matches: $*"
      printf '%s\n' "$found" | awk -F '\t' -v dir="$manual" '{ printf "%s/%s:%s\t%s\n", dir, $1, $2, $3 }' ;;
    -*) die "unknown manual option: $1 (see nirux manual --help)" ;;
    *)
      if [ "$#" = 0 ]; then found=$(printf 'README.md\t1\t\n')
      else
        found=$(manual_resolve "$manual" "$*") || {
          say "nirux: no chapter or heading matches: $*" >&2
          say 'Chapters (nirux manual --list):' >&2
          manual_chapters "$manual" | cut -f 2 | sed 's/^/  /' >&2
          exit 1
        }
      fi
      manual_open "$manual/$(printf '%s' "$found" | cut -f 1)" \
        "$(printf '%s' "$found" | cut -f 2)" "$(printf '%s' "$found" | cut -f 3)" ;;
  esac
}
# Extract nirux-manual.tar.xz of the release into the staged generation, read
# only, next to the programs it describes. A release without it stays valid.
stage_manual() {
  release_optional_file nirux "$1" nirux-manual.tar.xz
  manual_archive=$WORK/download/nirux/nirux-manual.tar.xz
  [ -f "$manual_archive" ] || return 0
  manual_unpack=$WORK/manual-unpack
  rm -rf "$manual_unpack"
  mkdir -p "$manual_unpack" || die 'could not create the manual extraction directory'
  tar -xJf "$manual_archive" -C "$manual_unpack" || die 'could not extract the manual archive'
  [ -f "$manual_unpack/manual/README.md" ] || die 'manual archive is incomplete'
  rm -rf "$WORK/generation/manual"
  cp -R "$manual_unpack/manual" "$WORK/generation/manual" || die 'could not stage the manual'
  find "$WORK/generation/manual" -type d -exec chmod 755 {} + 
  find "$WORK/generation/manual" -type f -exec chmod 444 {} +
  rm -rf "$manual_unpack"
}
