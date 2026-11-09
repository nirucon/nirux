#!/bin/sh
# Regenerate the generated sections of the NIRUX manual (docs/manual/).
#
#   tools/manual-gen.sh             rewrite the generated sections from the
#                                   vendored inputs (offline)
#   tools/manual-gen.sh --check     exit 1 when a generated section or the
#                                   vendored inputs are stale (offline; CI)
#   tools/manual-gen.sh --refresh   fetch the inputs for the versions pinned in
#                                   the manifest, then regenerate (network)
#
# The inputs live in tools/manual-inputs/:
#   VERSIONS       the component versions (and the hash of config.example.toml)
#                  the inputs were taken from; --check compares it with manifest
#   keys.md        `niructl keys --markdown` for a fresh NIRUX configuration
#                  (NIRUWM's defaults plus this repository's config.example.toml)
#   niructl-usage.txt  the usage text `niructl` prints without arguments
#   config/REPO/FILE   the example configuration files of the components
#
# --refresh downloads niructl from the pinned NIRUWM release and checks it
# against that release's SHA256SUMS. NIRUCTL=/path/to/niructl uses a local
# build instead; it must be built from the pinned NIRUWM version.
#
# A generated section is everything between
#   <!-- generated: NAME (tools/manual-gen.sh; do not edit by hand) -->
#   <!-- end generated: NAME -->
# in a chapter. Edit the text around the markers, never inside them.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
MANUAL=$ROOT/docs/manual
INPUTS=$ROOT/tools/manual-inputs
MODE=generate
case "${1:-}" in
  '') ;;
  --check) MODE=check ;;
  --refresh) MODE=refresh ;;
  -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) printf 'manual-gen: unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
die() { printf 'manual-gen: %s\n' "$*" >&2; exit 1; }

# Component example files: REPO PATH-IN-REPO INSTALLED-PATH READ-BY
# The nirux files are read from this repository, the others are vendored.
CONFIG_FILES='nirux config.example.toml ~/.config/niruwm/config.toml niruwm,nirubar,niruidle,niructl
nirux appearance.example.toml ~/.config/niruwm/appearance.toml the_whole_suite
nirux sounds.example.toml ~/.config/nirux/sounds.toml nirux,nirunotify
nirux displays.example.toml ~/.config/niruwm/displays.toml niruwm,niructl,nirudisplay
nirubar weather.example.toml ~/.config/nirubar/config.toml nirubar
nirulauncher config.example.toml ~/.config/nirulauncher/config.toml nirulauncher
nirunotify config.example.toml ~/.config/nirunotify/config.toml nirunotify
nirulock config.example.toml ~/.config/niruui/lock.toml nirulock
niruscreensaver config.example.toml ~/.config/niruui/screensaver.toml niruscreensaver
nirushare docs/webhooks.example.toml ~/.config/nirushare/webhooks.toml nirushare'

manifest_version() { awk -v n="$1" '$1 == n {print $2}' "$ROOT/manifest"; }
vendored_repos() { printf '%s\n' "$CONFIG_FILES" | awk '$1 != "nirux" {print $1}' | sort -u; }
hash_of() { sha256sum "$1" | cut -d ' ' -f 1; }
example_source() { # REPO PATH
  if [ "$1" = nirux ]; then say_path=$ROOT/$2; else say_path=$INPUTS/config/$1/${2##*/}; fi
  printf '%s\n' "$say_path"
}

# ── Refresh: fetch the inputs for the pinned versions ─────────────────────────
fetch() { curl -fsSL --retry 3 --connect-timeout 20 -o "$2" "$1"; }
refresh() {
  wm=$(manifest_version niruwm)
  [ -n "$wm" ] || die 'manifest has no niruwm'
  mkdir -p "$INPUTS/config"
  if [ -n "${NIRUCTL:-}" ]; then
    niructl=$NIRUCTL
  else
    base=https://github.com/nirucon/niruwm/releases/download/v$wm
    fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "could not download NIRUWM $wm SHA256SUMS"
    fetch "$base/niructl" "$TMP/niructl" || die "could not download NIRUWM $wm niructl"
    expected=$(awk '$2 == "niructl" {print $1}' "$TMP/SHA256SUMS")
    [ "${#expected}" = 64 ] && [ "$(hash_of "$TMP/niructl")" = "$expected" ] || \
      die 'niructl checksum mismatch'
    chmod 755 "$TMP/niructl"
    niructl=$TMP/niructl
  fi
  # niructl has no --version without a display; the checksum identifies a
  # downloaded one, and a local build is taken on trust.
  [ -z "${NIRUCTL:-}" ] || printf 'manual-gen: using %s as NIRUWM %s\n' "$NIRUCTL" "$wm" >&2
  # A fresh NIRUX configuration: NIRUWM defaults plus config.example.toml, and
  # no keys registered by extras.
  home=$TMP/home
  mkdir -p "$home/.config/niruwm" "$home/.local/share"
  cp "$ROOT/config.example.toml" "$home/.config/niruwm/config.toml"
  HOME=$home XDG_CONFIG_HOME=$home/.config XDG_DATA_HOME=$home/.local/share \
    "$niructl" keys --markdown > "$TMP/keys.md" || die 'niructl keys --markdown failed'
  grep -q '^| Keys | Action |' "$TMP/keys.md" || die 'niructl keys --markdown printed no table'
  "$niructl" > "$TMP/usage.txt" 2>&1 < /dev/null || :
  grep -q 'Usage: niructl' "$TMP/usage.txt" || die 'niructl printed no usage text'
  sed 's/^niructl: //' "$TMP/usage.txt" > "$INPUTS/niructl-usage.txt"
  cp "$TMP/keys.md" "$INPUTS/keys.md"
  {
    printf '# Inputs of the generated manual sections (tools/manual-gen.sh --refresh)\n'
    printf 'niruwm %s\n' "$wm"
    for repo in $(vendored_repos); do
      version=$(manifest_version "$repo")
      [ -n "$version" ] || die "manifest has no $repo"
      printf '%s %s\n' "$repo" "$version"
    done
    printf 'config.example.toml %s\n' "$(hash_of "$ROOT/config.example.toml")"
  } > "$TMP/VERSIONS"
  printf '%s\n' "$CONFIG_FILES" | while read -r repo path _installed _readers; do
    [ "$repo" != nirux ] || continue
    version=$(manifest_version "$repo")
    mkdir -p "$INPUTS/config/$repo"
    fetch "https://raw.githubusercontent.com/nirucon/$repo/v$version/$path" \
      "$INPUTS/config/$repo/${path##*/}" || die "could not download $repo $version $path"
  done
  mv "$TMP/VERSIONS" "$INPUTS/VERSIONS"
  printf 'manual-gen: inputs refreshed for NIRUWM %s\n' "$wm"
}

# ── Section generators (stdout) ───────────────────────────────────────────────
gen_keys() {
  printf 'The key bindings of a fresh NIRUX installation: NIRUWM %s defaults with\n' \
    "$(awk '$1 == "niruwm" {print $2}' "$INPUTS/VERSIONS")"
  printf 'the `[[keys]]` of the NIRUX `config.example.toml`. Your own `[[keys]]` and the keys\n'
  printf 'that extras register are added on top; `Super+F1` shows the keys in effect.\n\n'
  # niructl prints level-3 headings; under the chapter's level-2 heading they
  # stay level 3.
  cat "$INPUTS/keys.md"
}
gen_niructl() {
  printf 'Every form `niructl` accepts, from its usage text (NIRUWM %s). Run `niructl`\n' \
    "$(awk '$1 == "niruwm" {print $2}' "$INPUTS/VERSIONS")"
  printf 'without arguments to print it.\n\n'
  # The usage text separates commands with " | "; a bare "|" separates the
  # alternatives of one command. "output" continues the wallpaper command.
  tr '\n' ' ' < "$INPUTS/niructl-usage.txt" | sed 's/^ *Usage: niructl //; s/  */ /g; s/ *$//' |
    awk 'BEGIN { RS = " [|] " }
      {
        entry = $0
        gsub(/^ +| +$/, "", entry)
        if (entry == "") next
        split(entry, word, " ")
        if (word[1] == "output" && last == "wallpaper") entry = "wallpaper " entry
        else last = word[1]
        printf "- `niructl %s`\n", entry
      }'
}
md_escape() { sed 's/|/\\|/g'; }
gen_config_table() { # FILE
  # One row per key: the section, the key, the value the example sets (or
  # shows commented out), and the first sentence of the description above it:
  # the comment lines from the last one that starts a sentence.
  awk '
    function flush_note() { nc = 0 }
    function note(   i, s, j) {
      if (nc == 0) return ""
      if (c[nc] ~ /^[A-Z].*[.]$/) i = nc
      else for (i = nc; i > 1; i--)
        if (c[i] ~ /^[A-Z]/ && c[i - 1] ~ /[.:)]$/) break
      s = ""
      for (j = i; j <= nc; j++) s = s " " c[j]
      gsub(/^ +| +$/, "", s)
      j = index(s, ". ")
      if (j > 0) s = substr(s, 1, j)
      if (length(s) > 140) s = substr(s, 1, 137) "..."
      return s
    }
    function cell(s) { gsub(/\|/, "\\|", s); gsub(/`/, "", s); return s }
    function row(key, value, optional,   v) {
      if (section == "keys") { flush_note(); return }
      sub(/[ \t]+#.*$/, "", value)
      gsub(/^ +| +$/, "", value)
      if (length(value) > 60) value = substr(value, 1, 57) "..."
      v = value == "" ? "" : "`" cell(value) "`"
      if (optional) v = v " (commented example)"
      printf "| `%s` | `%s` | %s | %s |\n", (section == "" ? "(top level)" : "[" section "]"), key, v, cell(note())
      rows++
      flush_note()
    }
    BEGIN { section = ""; nc = 0; rows = 0 }
    /^[ \t]*$/ { flush_note(); next }
    /^\[\[?[A-Za-z0-9_.-]+\]\]?[ \t]*(#.*)?$/ {
      s = $0; sub(/[ \t]*#.*$/, "", s); gsub(/[][]/, "", s); section = s; flush_note(); next
    }
    /^#[ \t]*\[\[?[A-Za-z0-9_.-]+\]\]?[ \t]*$/ {
      s = $0; sub(/^#[ \t]*/, "", s); gsub(/[][ \t]/, "", s); section = s; flush_note(); next
    }
    /^[A-Za-z0-9_-]+[ \t]*=/ {
      key = $0; sub(/[ \t]*=.*/, "", key); value = $0; sub(/^[^=]*=/, "", value)
      row(key, value, 0); next
    }
    /^#[ \t]?[A-Za-z0-9_-]+[ \t]*=[ \t]*([-"[{0-9]|true|false)/ {
      line = $0; sub(/^#[ \t]?/, "", line)
      key = line; sub(/[ \t]*=.*/, "", key); value = line; sub(/^[^=]*=/, "", value)
      row(key, value, 1); next
    }
    /^#/ {
      line = $0; sub(/^#+[ \t]?/, "", line)
      if (line ~ /^(─|-|=)/ || line ~ /─/) { flush_note(); next }
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line != "") c[++nc] = line
      next
    }
    { flush_note() }
    END { if (rows == 0) print "| | | | |" }
  ' "$1"
}
gen_config() {
  printf 'The example configuration files of NIRUX %s and its components, with every\n' \
    "$(manifest_version suite)"
  printf 'key they set or show. A value marked *commented example* is off by default:\n'
  printf 'remove the `#` to use it. The full annotated file follows each table.\n\n'
  printf '| File | Read by | Example from |\n|---|---|---|\n'
  printf '%s\n' "$CONFIG_FILES" | while read -r repo path installed readers; do
    if [ "$repo" = nirux ]; then from="nirux $(manifest_version suite)"
    else from="$repo $(awk -v n="$repo" '$1 == n {print $2}' "$INPUTS/VERSIONS")"; fi
    readers=$(printf '%s' "$readers" | sed 's/,/, /g; s/_/ /g')
    printf '| [`%s`](#%s) | %s | %s `%s` |\n' "$installed" \
      "$(printf '%s' "$installed" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9 _-]//g; s/ /-/g')" \
      "$readers" "$from" "${path##*/}"
  done
  printf '%s\n' "$CONFIG_FILES" | while read -r repo path installed _readers; do
    source=$(example_source "$repo" "$path")
    [ -f "$source" ] || die "missing example: $source (run tools/manual-gen.sh --refresh)"
    printf '\n### %s\n\n' "$installed"
    printf '| Section | Key | Example value | Meaning |\n|---|---|---|---|\n'
    gen_config_table "$source"
    printf '\n<details><summary>The annotated example file (%s)</summary>\n\n' "${path##*/}"
    printf '```toml\n'
    cat "$source"
    printf '```\n\n</details>\n'
  done
}

# Replace the body of every marked section NAME in FILE with the output of
# gen_NAME, writing the result to OUT.
splice() { # FILE OUT
  cp "$1" "$TMP/splice.in"
  for name in $(sed -n 's/^<!-- generated: \([a-z-]*\) .*-->$/\1/p' "$1"); do
    case "$name" in
      keys) gen_keys > "$TMP/body" ;;
      niructl) gen_niructl > "$TMP/body" ;;
      config) gen_config > "$TMP/body" ;;
      *) die "$1: unknown generated section: $name" ;;
    esac
    grep -q "^<!-- end generated: $name -->\$" "$TMP/splice.in" || die "$1: no end marker for $name"
    awk -v name="$name" -v body="$TMP/body" '
      $0 ~ "^<!-- generated: " name " " { print; print ""; while ((getline line < body) > 0) print line; print ""; skip = 1; next }
      $0 == "<!-- end generated: " name " -->" { skip = 0 }
      !skip { print }
    ' "$TMP/splice.in" > "$TMP/splice.out"
    mv "$TMP/splice.out" "$TMP/splice.in"
  done
  mv "$TMP/splice.in" "$2"
}

inputs_current() {
  status=0
  [ -f "$INPUTS/VERSIONS" ] || { printf 'manual-gen: tools/manual-inputs/VERSIONS is missing\n' >&2; return 1; }
  for repo in niruwm $(vendored_repos); do
    pinned=$(manifest_version "$repo")
    have=$(awk -v n="$repo" '$1 == n {print $2}' "$INPUTS/VERSIONS")
    if [ "$pinned" != "$have" ]; then
      printf 'manual-gen: inputs are from %s %s, the manifest pins %s\n' "$repo" "${have:-none}" "$pinned" >&2
      status=1
    fi
  done
  have=$(awk '$1 == "config.example.toml" {print $2}' "$INPUTS/VERSIONS")
  if [ "$have" != "$(hash_of "$ROOT/config.example.toml")" ]; then
    printf 'manual-gen: config.example.toml changed since the key bindings were generated\n' >&2
    status=1
  fi
  return "$status"
}

case "$MODE" in
  refresh) refresh ;;
esac
stale=0
if [ "$MODE" = check ]; then
  inputs_current || stale=1
fi
for chapter in "$MANUAL"/*.md; do
  grep -q '^<!-- generated: ' "$chapter" || continue
  splice "$chapter" "$TMP/out.md"
  if [ "$MODE" = check ]; then
    if ! cmp -s "$chapter" "$TMP/out.md"; then
      printf 'manual-gen: %s is stale:\n' "docs/manual/${chapter##*/}" >&2
      diff -u "$chapter" "$TMP/out.md" | head -n 20 >&2 || :
      stale=1
    fi
  elif ! cmp -s "$chapter" "$TMP/out.md"; then
    cp "$TMP/out.md" "$chapter"
    printf 'manual-gen: updated docs/manual/%s\n' "${chapter##*/}"
  fi
done
if [ "$stale" = 1 ]; then
  printf 'manual-gen: run tools/manual-gen.sh --refresh (new pins) or tools/manual-gen.sh\n' >&2
  exit 1
fi
