# Configuration migration deliberately supports a small, explicit TOML subset:
# comments and blank lines, bare or quoted keys, [tables] and [[arrays]], plus
# scalar, string, multiline string, array and inline-table values. Dotted keys,
# duplicate tables/keys and any line that is not a header or assignment stop the
# migration instead of guessing. The original file is only replaced after a
# staged candidate parses in both niruwm and nirubar.
config_scan() {
  awk '
function trim(s) {
  sub(/^[ \t]+/, "", s)
  sub(/[ \t\r]+$/, "", s)
  return s
}
function fail(msg) {
  printf "E\t%d\t%s\n", NR, msg
}
function escaped(s, pos,    n, c) {
  n = 0
  pos--
  while (pos > 0) {
    c = substr(s, pos, 1)
    if (c != "\\") break
    n++
    pos--
  }
  return n % 2
}
function unquote(k,    qc, body, i, c, out) {
  k = trim(k)
  if (k == "") return "\001"
  qc = substr(k, 1, 1)
  if (length(k) >= 2 && (qc == "\"" || qc == "\047") && substr(k, length(k), 1) == qc) {
    body = substr(k, 2, length(k) - 2)
    if (qc == "\047") return body
    out = ""
    for (i = 1; i <= length(body); i++) {
      c = substr(body, i, 1)
      if (c != "\\") { out = out c; continue }
      i++
      if (i > length(body)) return "\001"
      c = substr(body, i, 1)
      if (c == "n") out = out "\n"
      else if (c == "t") out = out "\t"
      else if (c == "r") out = out "\r"
      else if (c == "b") out = out "\b"
      else if (c == "f") out = out "\f"
      else if (c == "\\") out = out "\\"
      else if (c == "\"") out = out "\""
      else return "\001"
    }
    return out
  }
  if (k ~ /^[A-Za-z0-9_-]+$/) return k
  return "\001"
}
function normalize_table(s,    n, i, c, qc, start, seg, out, segs) {
  n = length(s)
  qc = ""
  start = 1
  out = ""
  segs = 0
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (qc != "") {
      if (qc == "\"" && c == "\\") { i++; continue }
      if (c == qc) qc = ""
      continue
    }
    if (c == "\"" || c == "\047") { qc = c; continue }
    if (c == ".") {
      seg = unquote(substr(s, start, i - start))
      if (seg == "\001") return "\001"
      out = out (segs ? "." : "") seg
      segs++
      start = i + 1
    }
  }
  if (qc != "") return "\001"
  seg = unquote(substr(s, start))
  if (seg == "\001") return "\001"
  out = out (segs ? "." : "") seg
  return out
}
function header_end(s, start, aot,    n, i, c, qc) {
  n = length(s)
  qc = ""
  for (i = start; i <= n; i++) {
    c = substr(s, i, 1)
    if (qc != "") {
      if (qc == "\"" && c == "\\") { i++; continue }
      if (c == qc) qc = ""
      continue
    }
    if (c == "\"" || c == "\047") { qc = c; continue }
    if (aot && substr(s, i, 2) == "]]") return i
    if (!aot && c == "]") return i
  }
  return 0
}
function find_equal(s,    n, i, c, qc) {
  n = length(s)
  qc = ""
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (qc != "") {
      if (qc == "\"" && c == "\\") { i++; continue }
      if (c == qc) qc = ""
      continue
    }
    if (c == "\"" || c == "\047") { qc = c; continue }
    if (c == "=") return i
  }
  return 0
}
function scan_value(s,    n, i, c) {
  n = length(s)
  i = 1
  while (i <= n) {
    if (ml != "") {
      if (substr(s, i, 3) == ml && (ml != "\"\"\"" || !escaped(s, i))) {
        ml = ""
        i += 3
        continue
      }
      i++
      continue
    }
    c = substr(s, i, 1)
    if (q != "") {
      if (q == "\"" && c == "\\") { i += 2; continue }
      if (c == q) q = ""
      i++
      continue
    }
    if (c == "\"") {
      if (substr(s, i, 3) == "\"\"\"") { ml = "\"\"\""; i += 3; continue }
      q = "\""
      i++
      continue
    }
    if (c == "\047") {
      if (substr(s, i, 3) == "\047\047\047") { ml = "\047\047\047"; i += 3; continue }
      q = "\047"
      i++
      continue
    }
    if (c == "#") return
    if (c == "[") { ad++; i++; continue }
    if (c == "]") {
      ad--
      if (ad < 0) { fail("unexpected ] in value"); ad = 0 }
      i++
      continue
    }
    if (c == "{") { bd++; i++; continue }
    if (c == "}") {
      bd--
      if (bd < 0) { fail("unexpected } in value"); bd = 0 }
      i++
      continue
    }
    i++
  }
  if (q != "") {
    fail("unterminated string")
    q = ""
  }
}
{
  line = $0
  sub(/\r$/, "", line)
  if (ml != "" || q != "" || ad > 0 || bd > 0) {
    scan_value(line)
    next
  }
  lead = line
  sub(/^[ \t]+/, "", lead)
  if (lead == "" || substr(lead, 1, 1) == "#") next
  if (substr(lead, 1, 1) == "[") {
    aot = 0
    start = 2
    if (substr(lead, 1, 2) == "[[") { aot = 1; start = 3 }
    end = header_end(lead, start, aot)
    if (end == 0) { fail("unterminated table header"); next }
    body = substr(lead, start, end - start)
    rest = trim(substr(lead, end + (aot ? 2 : 1)))
    if (rest != "" && substr(rest, 1, 1) != "#") { fail("unexpected text after table header"); next }
    t = normalize_table(body)
    if (t == "\001" || t == "") { fail("unsupported table name"); next }
    if (aot) {
      aot_count[t]++
      ctx = t
      printf "H\t%d\t%s\taot\n", NR, t
    } else {
      if (seen_table[t]) fail("duplicate table [" t "]")
      seen_table[t] = 1
      ctx = t
      printf "H\t%d\t%s\ttable\n", NR, t
    }
    next
  }
  eq = find_equal(lead)
  if (eq == 0) { fail("unsupported line (expected key = value)"); next }
  key = unquote(substr(lead, 1, eq - 1))
  if (key == "\001" || key == "") { fail("unsupported key"); next }
  kid = ctx SUBSEP key
  if (ctx != "" && aot_count[ctx] > 0) kid = kid SUBSEP aot_count[ctx]
  if (seen_key[kid]) fail("duplicate key " key)
  seen_key[kid] = 1
  printf "K\t%d\t%s\t%s\n", NR, ctx, key
  scan_value(substr(lead, eq + 1))
  next
}
END {
  if (ml != "") fail("unterminated multiline string")
  if (q != "") fail("unterminated string")
  if (ad > 0) fail("unterminated array")
  if (bd > 0) fail("unterminated inline table")
}
  ' "$1"
}

config_errors() {
  config_scan "$1" | awk -F '\t' '
    $1 == "E" { printf "line %s: %s\n", $2, $3; found = 1 }
    END { exit !found }
  '
}

config_has_section() {
  config_scan "$1" | awk -F '\t' -v wanted="$2" '
    $1 == "H" && $3 == wanted && $4 == "table" { found = 1 }
    END { exit !found }
  '
}

config_has_key() {
  config_scan "$1" | awk -F '\t' -v wanted_ctx="$2" -v wanted_key="$3" '
    $1 == "K" && $3 == wanted_ctx && $4 == wanted_key { found = 1 }
    END { exit !found }
  '
}

config_header_line() {
  config_scan "$1" | awk -F '\t' -v wanted="$2" '
    $1 == "H" && $3 == wanted && $4 == "table" { print $2; exit }
  '
}

config_next_header_line() {
  config_scan "$1" | awk -F '\t' -v after="$2" '
    $1 == "H" && $2 > after { print $2; exit }
  '
}

insert_config_line() {
  mig_file=$1
  mig_after=$2
  mig_text=$3
  mig_mode=$(stat -c %a "$mig_file") || die "could not read permissions for $mig_file"
  mig_tmp=$(mktemp "$mig_file.nirux.XXXXXX") || die "could not stage $mig_file"
  CONFIG_TMP=$mig_tmp
  if ! cp -p "$mig_file" "$mig_tmp"; then
    rm -f "$mig_tmp"; CONFIG_TMP=
    die "could not stage $mig_file"
  fi
  if ! chmod u+w "$mig_tmp"; then
    rm -f "$mig_tmp"; CONFIG_TMP=
    die "could not stage $mig_file"
  fi
  if awk -v n="$mig_after" -v text="$mig_text" '
    NR == 1 && n == 0 { print text }
    { print }
    NR == n && n > 0 { print text }
    END { if (NR == 0 && n == 0) print text }
  ' "$mig_file" > "$mig_tmp" &&
     chmod "$mig_mode" "$mig_tmp" &&
     mv -f "$mig_tmp" "$mig_file"; then
    CONFIG_TMP=
  else
    rm -f "$mig_tmp"; CONFIG_TMP=
    die "could not update $mig_file; original kept"
  fi
}

# Create the shared configuration on a fresh install, or append settings a new
# release introduced. Existing values are never rewritten.
add_missing_sections() {
  mig_file=$1
  mig_example=$2
  mig_added=""
  for mig_section in nightlight brightness wallpaper autostart monitors idle bar pip; do
    if config_has_section "$mig_file" "$mig_section"; then continue; fi
    mig_block=$(awk -v s="[$mig_section]" '
      $0 == s {found=1; print; next}
      found && /^[[:space:]]*\[/ {exit}
      found {print}
    ' "$mig_example")
    [ -n "$mig_block" ] || continue
    {
      printf '\n# Added by NIRUX; values are defaults.\n'
      printf '%s\n' "$mig_block"
    } >> "$mig_file"
    mig_added="$mig_added $mig_section"
  done
  [ -z "$mig_added" ] || say "Added missing config sections:$mig_added"
}

add_missing_top_key() {
  mig_file=$1
  mig_key=$2
  mig_value=$3
  if config_has_key "$mig_file" "" "$mig_key"; then return 0; fi
  mig_first=$(config_scan "$mig_file" | awk -F '\t' '$1 == "H" { print $2; exit }')
  if [ -n "$mig_first" ]; then
    mig_after=$(awk -v last="$((mig_first - 1))" 'NR <= last && NF { line = NR } END { print line + 0 }' "$mig_file")
  else
    mig_after=$(awk 'NF { line = NR } END { print line + 0 }' "$mig_file")
  fi
  insert_config_line "$mig_file" "$mig_after" "$mig_key = $mig_value"
}

add_missing_key() {
  mig_file=$1
  mig_section=$2
  mig_key=$3
  mig_value=$4
  if config_has_key "$mig_file" "$mig_section" "$mig_key"; then return 0; fi
  mig_header=$(config_header_line "$mig_file" "$mig_section")
  [ -n "$mig_header" ] || return 0
  mig_next=$(config_next_header_line "$mig_file" "$mig_header")
  if [ -n "$mig_next" ]; then
    mig_after=$(awk -v first="$((mig_header + 1))" -v last="$((mig_next - 1))" '
      NR >= first && NR <= last && NF { line = NR }
      END { print line + 0 }
    ' "$mig_file")
  else
    mig_after=$(awk -v first="$((mig_header + 1))" 'NR >= first && NF { line = NR } END { print line + 0 }' "$mig_file")
  fi
  [ "$mig_after" -gt 0 ] || mig_after=$mig_header
  insert_config_line "$mig_file" "$mig_after" "$mig_key = $mig_value"
}

# A newer release can add a bar module that an existing configuration does not
# mention, and the bar then never shows it. Add a module the shipped default
# has and the user's list does not. A hand-written list is their choice, so
# only a list that is still the previous default is extended.
upgrade_default_bar_modules() {
  mig_file=$1
  # Join the modules list onto one line, whether it is written on one or many.
  mig_modules=$(awk '
    /^\[bar\]/ { inside = 1; next }
    inside && /^\[/ { inside = 0 }
    inside && /^modules *= *\[/ {
      line = $0
      while (line !~ /\]/ && (getline more) > 0) line = line " " more
      print line
      exit
    }
  ' "$mig_file")
  [ -n "$mig_modules" ] || return 0
  mig_add=""
  mig_tail=0
  mig_restart=
  for mig_module in layout display quicksettings niruxupdate scratchpad dictation; do
    case "$mig_modules" in
      *"\"$mig_module\""*) continue ;;
    esac
    printf '%s' "$mig_modules" | grep -q '"workspaces"' || continue
    mig_add="$mig_add $mig_module"
  done
  # Tailscale is a peer list, so it belongs immediately left of network.
  if ! printf '%s' "$mig_modules" | grep -q '"tailscale"' &&
     printf '%s' "$mig_modules" | grep -q '"network"'; then
    mig_modules=$(printf '%s' "$mig_modules" | sed 's/"network"/"tailscale", "network"/')
    mig_tail=1
  fi
  # The restart module (NIRUBAR 0.31) sits right after niruxupdate. It is
  # added once: a list it was removed from stays without it.
  mig_marker=$STATE/bar-module-restart-added
  if [ ! -e "$mig_marker" ] && ! printf '%s' "$mig_modules" | grep -q '"restart"' &&
     printf '%s' "$mig_modules" | grep -q '"niruxupdate"'; then
    mig_modules=$(printf '%s' "$mig_modules" | sed 's/"niruxupdate"/"niruxupdate", "restart"/')
    mig_tail=1
    mig_restart=1
  fi
  [ -n "$mig_add" ] || [ "$mig_tail" = 1 ] || return 0
  if [ -n "$mig_add" ]; then
    mig_extra=$(printf '%s' "$mig_add" | sed 's/^ //; s/ /", "/g; s/^/"/; s/$/"/')
    # `niruxupdate` belongs with the status group on the right, so it goes
    # before the clock rather than next to the workspaces.
    if printf '%s' "$mig_modules" | grep -q '"clock"'; then
      mig_new=$(printf '%s' "$mig_modules" |
        sed "s/\"clock\"/$mig_extra, \"clock\"/")
    else
      mig_new=$(printf '%s' "$mig_modules" |
        sed "s/\(\"workspaces\"\)/\1, $mig_extra/")
    fi
  else
    mig_new=$mig_modules
  fi
  mig_mode=$(stat -c %a "$mig_file" 2>/dev/null) || mig_mode=644
  mig_tmp=$(mktemp "$mig_file.nirux-modules.XXXXXX") || return 0
  # Replace the whole list, however many lines it spans, with the new one.
  awk -v new="$mig_new" '
    /^\[bar\]/ { inside = 1; print; next }
    inside && /^\[/ { inside = 0 }
    inside && /^modules *= *\[/ {
      print new
      while ($0 !~ /\]/ && (getline more) > 0) { $0 = more }
      next
    }
    { print }
  ' "$mig_file" > "$mig_tmp" || { rm -f "$mig_tmp"; return 0; }
  if chmod "$mig_mode" "$mig_tmp" && mv -f "$mig_tmp" "$mig_file"; then
    say "Added bar module(s):$mig_add${mig_restart:+ restart}"
    [ -z "${mig_restart:-}" ] || { mkdir -p "$STATE" && : > "$mig_marker"; } 2>/dev/null || :
  else
    rm -f "$mig_tmp"
  fi
}

validate_config_candidate() {
  mig_candidate=$1
  if [ -n "${WORK:-}" ]; then
    mig_validator_root=$WORK/config-validate
    rm -rf "$mig_validator_root"
    mkdir -p "$mig_validator_root/niruwm"
  else
    mig_validator_root=$(mktemp -d "${TMPDIR:-/tmp}/nirux-config.XXXXXX") || return 1
    mkdir -p "$mig_validator_root/niruwm"
  fi
  if [ -d "$CONFDIR/themes" ]; then
    ln -s "$CONFDIR/themes" "$mig_validator_root/niruwm/themes" 2>/dev/null || :
  fi
  cp "$mig_candidate" "$mig_validator_root/niruwm/config.toml" || {
    rm -rf "$mig_validator_root"; return 1
  }
  for mig_program in niruwm nirubar; do
    if [ -n "${WORK:-}" ] && [ -x "$WORK/generation/bin/$mig_program" ]; then
      mig_validator=$WORK/generation/bin/$mig_program
    elif [ -x "$BIN/$mig_program" ]; then
      mig_validator=$BIN/$mig_program
    else
      say "cannot validate the configuration: $mig_program is not available"
      rm -rf "$mig_validator_root"
      return 1
    fi
    if ! XDG_CONFIG_HOME="$mig_validator_root" "$mig_validator" --check-config >/dev/null 2>"$mig_validator_root/$mig_program.err"; then
      mig_reason=$(sed -n '1p' "$mig_validator_root/$mig_program.err")
      say "configuration candidate rejected by $mig_program${mig_reason:+: $mig_reason}"
      rm -rf "$mig_validator_root"
      return 1
    fi
  done
  rm -rf "$mig_validator_root"
  return 0
}

appearance_has_old_noir_defaults() {
  awk '
    /^[[:space:]]*\[colors\][[:space:]]*$/ { in_colors = 1; next }
    /^[[:space:]]*\[/ { in_colors = 0 }
    in_colors && /^[[:space:]]*[a-z_]+[[:space:]]*=/ {
      line = $0
      sub(/#.*/, "", line)
      split(line, parts, "=")
      key = parts[1]
      value = parts[2]
      gsub(/[[:space:]"]/, "", key)
      gsub(/[[:space:]"]/, "", value)
      found[key] = tolower(value)
      count++
    }
    END {
      expected["background"]="0f0f10"; expected["surface"]="161618";
      expected["foreground"]="e5e5e5"; expected["muted"]="a8a8a8";
      expected["border"]="2a2a2d"; expected["focus"]="5a5a60";
      expected["accent"]="5a5a60"; expected["selected"]="26262a";
      expected["success"]="8fbf7f"; expected["warning"]="d7b36a";
      expected["error"]="d77a7a"; expected["disabled"]="5a5a5e";
      if (count != 12) exit 1
      for (key in expected) if (found[key] != expected[key]) exit 1
      exit 0
    }
  ' "$1"
}
migrate_appearance_defaults() {
  appearance_file=$1
  [ -f "$appearance_file" ] || return 0
  appearance_has_old_noir_defaults "$appearance_file" || return 0
  appearance_mode=$(stat -c %a "$appearance_file") || die "could not read permissions for $appearance_file"
  appearance_tmp=$(mktemp "$appearance_file.nirux.XXXXXX") || die "could not stage $appearance_file"
  cp -p "$appearance_file" "$appearance_tmp" || { rm -f "$appearance_tmp"; die "could not stage $appearance_file"; }
  if ! awk '
    /^[[:space:]]*\[colors\][[:space:]]*$/ {
      print "# Colours are intentionally not overridden; the selected NIRU theme wins."
      skip = 1
      next
    }
    /^[[:space:]]*\[/ { skip = 0 }
    !skip { print }
  ' "$appearance_file" > "$appearance_tmp" ||
     ! chmod "$appearance_mode" "$appearance_tmp" ||
     ! mv -f "$appearance_tmp" "$appearance_file"; then
    rm -f "$appearance_tmp"
    die "could not migrate $appearance_file; original kept"
  fi
  say "Updated the old Noir appearance override so built-in themes keep their colours."
}
install_appearance() {
  appearance_example="$WORK/download/nirux/appearance.example.toml"
  [ -f "$appearance_example" ] || return 0
  mkdir -p "$CONFDIR"
  appearance_file="$CONFDIR/appearance.toml"
  if [ ! -e "$appearance_file" ] && [ ! -L "$appearance_file" ]; then
    install -m 644 "$appearance_example" "$appearance_file"
    say "Created $appearance_file"
  elif [ -f "$appearance_file" ]; then
    migrate_appearance_defaults "$appearance_file"
  fi
  return 0
}

browser_available() {
  command -v "$1" >/dev/null 2>&1 || [ -x "$BIN/$1" ]
}
# NIRUFM replaced pcmanfm (0.12.317): the default Super+Shift+F binding is
# moved along; a binding the user changed to something else is kept.
upgrade_file_manager_binding() {
  grep -qx 'action = "start pcmanfm"' "$1" || return 0
  # No check for the nirufm program: the configuration is installed before
  # the new generation is linked, and every release since 0.12.317 has it.
  fm_mode=$(stat -c %a "$1") || die "could not read permissions for $1"
  fm_tmp=$(mktemp "$1.nirux-fm.XXXXXX") || die "could not stage $1"
  if awk '$0 == "action = \"start pcmanfm\"" {print "action = \"start nirufm\""; next} {print}' "$1" > "$fm_tmp" &&
     chmod "$fm_mode" "$fm_tmp" && mv -f "$fm_tmp" "$1"; then
    say 'Super+Shift+F now opens NIRUFM (it was pcmanfm).'
  else
    rm -f "$fm_tmp"
    die "could not update the file manager binding in $1; original kept"
  fi
}
upgrade_obsolete_default_browser() {
  [ "${BROWSER_EFFECTIVE:-keep}" = helium ] || return 0
  browser_available brave && return 0
  grep -qx 'browser = \["brave"\]' "$1" || return 0
  mig_mode=$(stat -c %a "$1") || die "could not read permissions for $1"
  mig_tmp=$(mktemp "$1.nirux-browser.XXXXXX") || die "could not stage $1"
  if awk '$0 == "browser = [\"brave\"]" {print "browser = [\"helium\"]"; next} {print}' "$1" > "$mig_tmp" &&
     chmod "$mig_mode" "$mig_tmp" && mv -f "$mig_tmp" "$1"; then
    say 'Updated the obsolete default browser from brave to helium; custom selections are unchanged.'
  else
    rm -f "$mig_tmp"
    die "could not update the default browser in $1; original kept"
  fi
}
add_localsend_rule() {
  grep -q '^class = "localsend"' "$1" && return 0
  printf '\n[[rules]]\nclass = "localsend"\nfloating = true\ncenter = true\n' >> "$1"
  say 'Added the default LocalSend floating/centered rule.'
}

upgrade_default_workspaces() {
  # Older NIRUX examples used nine workspaces and nine tags. Expand only the
  # exact old defaults; custom counts, names and monitor profiles are kept.
  grep -qx 'workspaces = 9' "$1" || return 0
  grep -q '^\[\[monitors\.profiles\]\]' "$1" && return 0
  mig_mode=$(stat -c %a "$1") || die "could not read permissions for $1"
  mig_tmp=$(mktemp "$1.nirux-workspaces.XXXXXX") || die "could not stage $1"
  if awk '
    $0 == "workspaces = 9" {print "workspaces = 10"; next}
    $0 == "tags = [\"1\", \"2\", \"3\", \"4\", \"5\", \"6\", \"7\", \"8\", \"9\"]" {
      print "tags = [\"1\", \"2\", \"3\", \"4\", \"5\", \"6\", \"7\", \"8\", \"9\", \"10\"]"; next
    }
    {print}
  ' "$1" > "$mig_tmp" && chmod "$mig_mode" "$mig_tmp" && mv -f "$mig_tmp" "$1"; then
    say 'Expanded the default workspace set from nine to ten; custom profiles are unchanged.'
  else
    rm -f "$mig_tmp"
    die "could not update the default workspace set in $1; original kept"
  fi
}

