# ── Bar modules follow the NIRUX default (docs: manual chapter 4) ───────────
# [bar] follow_default_modules = true (the default): `nirux update` sets
# `modules` to the list of the shipped example when it differs. The file as it
# was is kept in NIRUWM's config history first, so `niructl config undo`
# brings the old list back; false keeps your own list.
bar_modules_line() {
  awk '
    /^\[bar\]/ { inside = 1; next }
    inside && /^\[/ { inside = 0 }
    inside && /^modules *= *\[/ {
      line = $0
      while (line !~ /\]/ && (getline more) > 0) line = line " " more
      sub(/[[:space:]]*#.*$/, "", line)
      print line
      exit
    }
  ' "$1"
}
bar_modules_norm() { tr -d ' \t' | sed 's/,]/]/'; }
config_history_keep() { # FILE: copy into NIRUWM's history unless an identical copy is there
  ch_dir=${XDG_STATE_HOME:-$HOME/.local/state}/niruwm/config-history
  mkdir -p "$ch_dir" || return 1
  for ch_old in "$ch_dir"/*.toml; do
    [ -f "$ch_old" ] || continue
    same_file "$1" "$ch_old" && return 0
  done
  ch_stamp=$(date +%Y%m%d-%H%M%S)
  ch_n=0
  while [ -e "$ch_dir/$ch_stamp-$(printf '%02d' "$ch_n").toml" ]; do ch_n=$((ch_n + 1)); done
  cp "$1" "$ch_dir/.$$.tmp" && mv -f "$ch_dir/.$$.tmp" "$ch_dir/$ch_stamp-$(printf '%02d' "$ch_n").toml"
}
follow_default_bar_modules() {
  fd_file=$1 fd_example=$2 fd_original=$3
  [ "$(toml_value "$fd_file" bar follow_default_modules)" != false ] || return 0
  fd_want=$(bar_modules_line "$fd_example")
  fd_have=$(bar_modules_line "$fd_file")
  [ -n "$fd_want" ] && [ -n "$fd_have" ] || return 0
  [ "$(say "$fd_want" | bar_modules_norm)" != "$(say "$fd_have" | bar_modules_norm)" ] || return 0
  config_history_keep "$fd_original" || say 'nirux: warning: could not keep the old configuration in the history' >&2
  fd_mode=$(stat -c %a "$fd_file") || die "could not read permissions for $fd_file"
  fd_tmp=$(mktemp "$fd_file.nirux-follow.XXXXXX") || die "could not stage $fd_file"
  awk -v new="$fd_want" '
    /^\[bar\]/ { inside = 1; print; next }
    inside && /^\[/ { inside = 0 }
    inside && /^modules *= *\[/ {
      print new
      while ($0 !~ /\]/ && (getline more) > 0) { $0 = more }
      next
    }
    { print }
  ' "$fd_file" > "$fd_tmp" && chmod "$fd_mode" "$fd_tmp" && mv -f "$fd_tmp" "$fd_file" || {
    rm -f "$fd_tmp"
    die "could not update the bar modules in $fd_file; original kept"
  }
  say 'Bar modules set to the NIRUX default list (niructl config undo goes back; [bar] follow_default_modules = false keeps your own list).'
}

# ── Apps outside the package manager (docs: manual chapter 11) ──────────────
# Helium, LocalSend and OpenCode follow their newest stable upstream release
# when it publishes a checksum for the archive: GitHub's asset digest, or the
# npm registry's integrity for OpenCode 2. The answer is cached for an hour.
# The pins above stay the minimum: nothing is installed below them, and when
# the lookup, the checksum or the download fails the installed version (or
# the pin) is kept. NIRUX_APPS=pinned (nirux update --apps pinned) never asks.
APPS_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/nirux/apps-latest
apps_mode() { case "${NIRUX_APPS:-latest}" in pinned) say pinned ;; *) say latest ;; esac; }
# A bounded request to an upstream API (tests replace this function).
apps_api() {
  command -v curl >/dev/null 2>&1 || return 1
  curl -fsSL --proto '=https' --connect-timeout 10 --max-time 20 -o "$2" "$1" 2>/dev/null
}
# app_github_latest JSON TAG-PREFIX ASSET-FORMAT: "VERSION sha256:HEX" of the
# release, or nothing. The asset name is built here, never taken from JSON.
app_github_latest() {
  agl_tokens=$(tr -d '\n\r' < "$1" | grep -oE '"(tag_name|name|digest|prerelease|draft)": *("[^"]*"|true|false)') || return 1
  agl_tag=$(say "$agl_tokens" | sed -n 's/^"tag_name": *"\(.*\)"$/\1/p' | head -n 1)
  say "$agl_tokens" | grep -qE '^"(prerelease|draft)": *true' && return 1
  agl_version=${agl_tag#"$2"}
  valid_version "$agl_version" || return 1
  # shellcheck disable=SC2059 # the format is a fixed asset pattern
  agl_asset=$(printf "$3" "$agl_version")
  agl_digest=$(say "$agl_tokens" | awk -v want="$agl_asset" '
    /^"name":/ { n = $0; sub(/^"name": *"/, "", n); sub(/"$/, "", n); cur = n; next }
    /^"digest":/ && cur == want { d = $0; sub(/^"digest": *"/, "", d); sub(/"$/, "", d); print d; exit }')
  case "$agl_digest" in sha256:*) ;; *) return 1 ;; esac
  agl_hex=${agl_digest#sha256:}
  [ "${#agl_hex}" = 64 ] || return 1
  case "$agl_hex" in *[!0-9a-f]*) return 1 ;; esac
  say "$agl_version sha256:$agl_hex"
}
# OpenCode 2: the version opencode.ai's own installer uses, and the sha512 of
# that version's npm package.
app_opencode_latest() {
  aol_tmp=$1
  apps_api https://opencode.ai/update/api/latest/cli/npm "$aol_tmp/meta" || return 1
  aol_version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$aol_tmp/meta" | head -n 1)
  aol_package=$(sed -n 's/.*"package": *"\([^"]*\)".*/\1/p' "$aol_tmp/meta" | head -n 1)
  valid_version "$aol_version" || return 1
  case "$aol_package" in @opencode/cli) aol_scope=@opencode ;; @opencode-ai/cli) aol_scope=@opencode-ai ;; *) return 1 ;; esac
  apps_api "https://registry.npmjs.org/$aol_scope%2fcli-linux-x64/$aol_version" "$aol_tmp/npm" || return 1
  grep -q "\"name\": *\"$aol_scope/cli-linux-x64\"" "$aol_tmp/npm" || return 1
  grep -q "\"version\": *\"$aol_version\"" "$aol_tmp/npm" || return 1
  aol_b64=$(sed -n 's/.*"integrity": *"sha512-\([A-Za-z0-9+\/=]*\)".*/\1/p' "$aol_tmp/npm" | head -n 1)
  [ -n "$aol_b64" ] || return 1
  aol_hex=$(say "$aol_b64" | base64 -d 2>/dev/null | od -An -v -tx1 | tr -d ' \n')
  [ "${#aol_hex}" = 128 ] || return 1
  say "$aol_version sha512:$aol_hex $aol_scope"
}
# app_latest APP: sets AL_VERSION, AL_DIGEST (ALGO:HEX) and AL_EXTRA.
app_latest() {
  AL_VERSION='' AL_DIGEST='' AL_EXTRA=''
  [ "$(apps_mode)" = latest ] || return 1
  al_now=$(date +%s)
  al_line=$(awk -v a="$1" '$1 == a { line = $0 } END { print line }' "$APPS_CACHE" 2>/dev/null) || al_line=
  al_when=$(say "$al_line" | awk '{ print $2 }')
  case "$al_when" in ''|*[!0-9]*) al_when=0 ;; esac
  if [ "$al_when" -gt 0 ] && [ $((al_now - al_when)) -lt "${NIRUX_APPS_CACHE_SECONDS:-3600}" ] && [ "$al_when" -le "$al_now" ]; then
    al_result=$(say "$al_line" | cut -d ' ' -f 3-)
  else
    al_tmp=$(mktemp -d "${TMPDIR:-/tmp}/nirux-apps.XXXXXX") || return 1
    al_result=
    case "$1" in
      helium)
        apps_api https://api.github.com/repos/imputnet/helium-linux/releases/latest "$al_tmp/json" &&
          al_result=$(app_github_latest "$al_tmp/json" '' 'helium-%s-x86_64_linux.tar.xz') ;;
      localsend)
        apps_api https://api.github.com/repos/localsend/localsend/releases/latest "$al_tmp/json" &&
          al_result=$(app_github_latest "$al_tmp/json" v 'LocalSend-%s-linux-x86-64.tar.gz') ;;
      opencode) al_result=$(app_opencode_latest "$al_tmp") ;;
    esac
    rm -rf "$al_tmp"
    [ -n "$al_result" ] || al_result=-
    mkdir -p "${APPS_CACHE%/*}" 2>/dev/null &&
      { awk -v a="$1" '$1 != a' "$APPS_CACHE" 2>/dev/null || :; say "$1 $al_now $al_result"; } > "$APPS_CACHE.$$" &&
      mv -f "$APPS_CACHE.$$" "$APPS_CACHE" 2>/dev/null || rm -f "$APPS_CACHE.$$"
  fi
  [ "$al_result" != - ] && [ -n "$al_result" ] || return 1
  AL_VERSION=$(say "$al_result" | awk '{ print $1 }')
  AL_DIGEST=$(say "$al_result" | awk '{ print $2 }')
  AL_EXTRA=$(say "$al_result" | awk '{ print $3 }')
  valid_version "$AL_VERSION" && [ -n "$AL_DIGEST" ]
}
# app_upstream APP PIN: true when a verified upstream release newer than PIN
# exists (AL_* describe it). OpenCode stays on the pin's major version.
app_upstream() {
  app_latest "$1" || return 1
  [ "$AL_VERSION" != "$2" ] && version_at_least "$AL_VERSION" "$2" || return 1
  if [ "$1" = opencode ] && [ "${AL_VERSION%%.*}" != "${2%%.*}" ]; then return 1; fi
  return 0
}
# app_digest_ok FILE ALGO:HEX
app_digest_ok() {
  case "$2" in
    sha256:*) [ "$(sha256sum "$1" 2>/dev/null | cut -d ' ' -f1)" = "${2#sha256:}" ] ;;
    sha512:*) [ "$(sha512sum "$1" 2>/dev/null | cut -d ' ' -f1)" = "${2#sha512:}" ] ;;
    *) return 1 ;;
  esac
}
# app_keep APP INSTALLED PIN: an installed version at or above the pin stays.
app_keep() {
  [ -n "$2" ] && version_at_least "$2" "$3" || return 1
  say "Keeping $1 $2 (the upstream release could not be used; the minimum is $3)."
}
# Installed and newest versions of the apps, for nirux status.
apps_status() {
  for as_app in helium localsend opencode; do
    case "$as_app" in
      helium) browser_managed || continue; as_inst=$(browser_installed_version || :); as_pin=$HELIUM_VERSION ;;
      localsend) as_inst=$(localsend_installed_version 2>/dev/null || :); [ -n "$as_inst" ] || continue; as_pin=$LOCALSEND_VERSION ;;
      opencode) opencode_managed || continue; as_inst=$(opencode_installed_version 2>/dev/null || :); as_pin=$OPENCODE_VERSION ;;
    esac
    if [ "$(apps_mode)" = pinned ]; then as_latest="pinned $as_pin (NIRUX_APPS=pinned)"
    elif app_latest "$as_app"; then as_latest="latest $AL_VERSION"
    else as_latest="latest unknown (pin $as_pin)"; fi
    say "app $as_app: installed ${as_inst:-unknown}, $as_latest"
  done
}

