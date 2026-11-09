#!/bin/sh
# The NIRUX manual (docs/manual): generated sections are current, every nirux
# subcommand of the usage text is documented, internal links and anchors
# resolve, `nirux manual` finds chapters and headings, and the release archive
# stages into a program generation. Offline.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
MANUAL=$SOURCE/docs/manual
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
failures=0
problem() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

[ -f "$MANUAL/README.md" ] || fail 'docs/manual/README.md is missing'

# 1. Generated sections and their vendored inputs.
sh "$SOURCE/tools/manual-gen.sh" --check || problem 'generated manual sections are stale (tools/manual-gen.sh)'

# The library: the same heading and anchor rules `nirux manual` uses.
# shellcheck disable=SC1091
NIRUX_LIBRARY=1 . "$SOURCE/nirux"
manual_headings "$MANUAL" > "$TEST/headings"

# 2. Every top-level command in the usage text has an entry in the command
# reference. A usage word counts when main() dispatches it.
commands=$(sh "$SOURCE/nirux" --help | sed -n 's/^ *\(Usage: \)\{0,1\}nirux //p' |
  tr '|' '\n' | awk '{ print $1 }' | grep -E '^[a-z][a-z-]*$' | sort -u)
labels=$(sed -n '/^main() {/,/^}/p' "$SOURCE/nirux" |
  sed -n 's/^    \([a-z|-]*\))[ ].*/\1/p; s/^    \([a-z|-]*\))$/\1/p' | tr '|' '\n' | sort -u)
count=0
for command in $commands; do
  printf '%s\n' "$labels" | grep -qx "$command" || continue
  count=$((count + 1))
  grep -q "\`nirux $command\b" "$MANUAL/16-commands.md" ||
    problem "nirux $command (usage text) has no entry in docs/manual/16-commands.md"
done
[ "$count" -ge 20 ] || problem "found only $count nirux commands in the usage text"

# 3. Links: chapter files exist, anchors exist, nothing points outside the
# manual (the installed copy has only docs/manual).
for file in "$MANUAL"/*.md; do
  name=${file##*/}
  awk '/^(```|~~~)/ { fence = !fence; next } !fence' "$file" | sed 's/`[^`]*`//g' |
    grep -o '\]([^)]*)' | sed 's/^](//; s/)$//; s/ .*//' > "$TEST/links" || :
  while read -r link; do
    case "$link" in
      http://*|https://*|mailto:*) continue ;;
      '') problem "$name: empty link"; continue ;;
    esac
    target=${link%%#*}
    anchor=
    case "$link" in *#*) anchor=${link#*#} ;; esac
    [ -n "$target" ] || target=$name
    case "$target" in
      */*|..*) problem "$name: link leaves the manual: $link"; continue ;;
    esac
    [ -f "$MANUAL/$target" ] || { problem "$name: broken link: $link"; continue; }
    if [ -n "$anchor" ]; then
      awk -F '\t' -v f="$target" -v a="$anchor" '$1 == f && $4 == a { found = 1 } END { exit !found }' \
        "$TEST/headings" || problem "$name: broken anchor: $link"
    fi
  done < "$TEST/links"
done
for chapter in "$MANUAL"/[0-9][0-9]-*.md; do
  grep -q "](${chapter##*/})" "$MANUAL/README.md" || problem "README.md does not list ${chapter##*/}"
  head -n 1 "$chapter" | grep -q '^# ' || problem "${chapter##*/} does not start with a # title"
done

# 4. House style: no long dashes in the written text (generated sections
# quote the components' own files).
for file in "$MANUAL"/*.md; do
  awk -v f="${file##*/}" '/^<!-- generated: / { g = 1 } /^<!-- end generated: / { g = 0 } !g { print f ":" FNR ": " $0 }' "$file"
done > "$TEST/text"
if grep "$(printf '\342\200\224')\|$(printf '\342\200\223')" "$TEST/text" > "$TEST/dashes"; then
  problem "long dashes in the manual: $(head -n 3 "$TEST/dashes")"
fi

# 5. nirux manual: path, list, topics, opening.
export NIRUX_MANUAL="$MANUAL"
[ "$(sh "$SOURCE/nirux" manual --path)" = "$MANUAL" ] || problem 'nirux manual --path'
chapters=$(ls "$MANUAL"/[0-9][0-9]-*.md | wc -l | tr -d ' ')
[ "$(sh "$SOURCE/nirux" manual --list | wc -l | tr -d ' ')" = "$chapters" ] || problem 'nirux manual --list'
sh "$SOURCE/nirux" manual --list | grep -q '^06  lock-and-screensaver' || problem 'nirux manual --list format'
where() { sh "$SOURCE/nirux" manual --where "$@" | cut -f 1 | sed "s|^$MANUAL/||"; }
expect() { # TOPIC FILE[:LINE]
  got=$(where "$1") || { problem "nirux manual --where '$1' failed"; return; }
  case "$got" in
    "$2"|"$2":*) ;;
    *) problem "nirux manual --where '$1' gave $got, expected $2" ;;
  esac
}
expect 06 06-lock-and-screensaver.md:1
expect 6 06-lock-and-screensaver.md:1
expect lock-and-screensaver 06-lock-and-screensaver.md:1
expect lås 06-lock-and-screensaver.md:1
expect hjälp README.md:1
expect kortkommandon 15-key-bindings.md:1
expect 'all key bindings' 15-key-bindings.md
expect 15-key-bindings#all-key-bindings 15-key-bindings.md
expect studioläge 10-sound-notifications-studio.md
expect 'Studio Mode' 10-sound-notifications-studio.md
expect scratchpads 03-workspaces-monitors-scratchpads.md
line=$(where 15-key-bindings#all-key-bindings | cut -d : -f 2)
[ "$(sed -n "${line}p" "$MANUAL/15-key-bindings.md")" = '## All key bindings' ] || problem 'heading line number'
if sh "$SOURCE/nirux" manual --where 'no such topic at all' >/dev/null 2>&1; then problem 'unknown topic accepted'; fi
if sh "$SOURCE/nirux" manual 'no such topic at all' >/dev/null 2>&1; then problem 'unknown topic opened'; fi
cat > "$TEST/viewer" <<'EOF'
#!/bin/sh
printf '%s|%s|%s\n' "$1" "$2" "$3" > "$VIEWER_LOG"
EOF
chmod 755 "$TEST/viewer"
VIEWER_LOG=$TEST/viewer.log NIRUX_MANUAL_VIEWER=$TEST/viewer sh "$SOURCE/nirux" manual
[ "$(cat "$TEST/viewer.log")" = "$MANUAL/README.md|1|" ] || problem "nirux manual opens $(cat "$TEST/viewer.log")"
VIEWER_LOG=$TEST/viewer.log NIRUX_MANUAL_VIEWER=$TEST/viewer sh "$SOURCE/nirux" manual studio mode
grep -q "^$MANUAL/10-sound-notifications-studio.md|[0-9]*|" "$TEST/viewer.log" || problem "nirux manual studio mode opens $(cat "$TEST/viewer.log")"
# Without a display and a terminal the path is printed.
out=$(env -u DISPLAY NIRUX_MANUAL_VIEWER= sh "$SOURCE/nirux" manual 01 < /dev/null)
[ "$out" = "$MANUAL/01-getting-started.md" ] || problem "nirux manual without a viewer printed $out"
unset NIRUX_MANUAL
# A checkout finds its own docs/manual.
[ "$(sh "$SOURCE/nirux" manual --path)" = "$MANUAL" ] || problem 'checkout manual not found'

# 6. The release archive (as .github/workflows/release.yml builds it) stages
# read-only into a generation, and a release without it still stages.
(cd "$SOURCE" && tar -cJf "$TEST/nirux-manual.tar.xz" -C docs manual)
tar -tJf "$TEST/nirux-manual.tar.xz" | grep -qx 'manual/README.md' || problem 'archive lacks manual/README.md'
WORK=$TEST/work
mkdir -p "$WORK/download/nirux" "$WORK/generation/bin"
cp "$TEST/nirux-manual.tar.xz" "$TEST/release-asset"
(cd "$TEST" && printf '%s  nirux-manual.tar.xz\n' "$(sha256sum release-asset | cut -d ' ' -f 1)") \
  > "$WORK/download/nirux/SHA256SUMS"
fetch() { cp "$TEST/release-asset" "$2"; }
stage_manual 0.0.1
[ -f "$WORK/generation/manual/README.md" ] || problem 'manual not staged into the generation'
[ ! -w "$WORK/generation/manual/README.md" ] || [ "$(id -u)" = 0 ] || problem 'staged manual is writable'
cmp -s "$WORK/generation/manual/15-key-bindings.md" "$MANUAL/15-key-bindings.md" || problem 'staged manual differs'
cp "$SOURCE/nirux" "$WORK/generation/bin/nirux"
[ "$(sh "$WORK/generation/bin/nirux" manual --path)" = "$WORK/generation/manual" ] || problem 'generation nirux does not find its manual'
rm -rf "$WORK/generation/manual"
: > "$WORK/download/nirux/SHA256SUMS"
rm -f "$WORK/download/nirux/nirux-manual.tar.xz"
stage_manual 0.0.1
[ ! -e "$WORK/generation/manual" ] || problem 'manual staged without a release asset'
chmod -R u+w "$WORK"

[ "$failures" = 0 ] || { printf '%s manual check(s) failed\n' "$failures" >&2; exit 1; }
printf 'manual: ok (%s chapters, %s nirux commands, %s headings)\n' "$chapters" "$count" "$(wc -l < "$TEST/headings" | tr -d ' ')"
