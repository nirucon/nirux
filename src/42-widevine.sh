# ── Widevine in Helium: Netflix and other protected video (docs: manual chapter 11)
# Helium ships without Google's Widevine module (CDM), so Netflix, Disney+,
# Max, Prime Video and Spotify on the web refuse to play. Helium does load a
# module named by a hint file in its profile,
#   ~/.config/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm
# containing {"Path":"DIR"}, where DIR holds manifest.json and
# _platform_specific/linux_x64/libwidevinecdm.so (Helium 0.22, tested with
# EME requestMediaKeySystemAccess and createMediaKeys).
#
# NIRUX takes the module the way Firefox does: Mozilla's update service names
# the current Linux module on Google's servers with its SHA-512, NIRUX
# downloads and checks it, unpacks it below $STATE/widevine/VERSION and writes
# the hint. Helium itself is not changed, managed by NIRUX or not. Google does
# not allow the module to be redistributed, so it is fetched from Google on
# each computer and never put in a NIRUX release.
#
# On by default (owner decision 2026-11-24) until Helium ships its own DRM
# support; nirux widevine off removes it. A hint that points to another
# module that exists (one the user set up) is left alone. Never fails an
# update: offline, the module already installed stays.
WIDEVINE_UPDATE_URL=${NIRUX_WIDEVINE_UPDATE_URL:-https://aus5.mozilla.org/update/3/GMP/140.0/20250101000000/%PLATFORM%/en-US/release/Linux/default/default/update.xml}
WIDEVINE_DIR=$STATE/widevine
widevine_profile() { say "${XDG_CONFIG_HOME:-$HOME/.config}/net.imput.helium"; }
widevine_hint() { say "$(widevine_profile)/WidevineCdm/latest-component-updated-widevine-cdm"; }

widevine_policy() {
  wp_value=
  [ ! -f "$STATE/widevine-policy" ] || \
    wp_value=$(awk '$1 == "widevine" && ($2 == "on" || $2 == "off") {print $2; exit}' "$STATE/widevine-policy")
  say "${wp_value:-on}"
}
widevine_policy_set() {
  mkdir -p "$STATE" || die 'could not create the NIRUX state directory'
  printf '# NIRUX owner: %s\nwidevine %s\n' "$PREFIX" "$1" > "$STATE/.widevine-policy.$$" || \
    die 'could not stage the Widevine setting'
  mv -f "$STATE/.widevine-policy.$$" "$STATE/widevine-policy" || \
    die 'could not persist the Widevine setting'
}

# The platform names: Mozilla's and the module's own directory.
widevine_platform() {
  case "${NIRUX_WIDEVINE_ARCH:-$(uname -m)}" in
    x86_64) WV_MOZ=Linux_x86_64-gcc3; WV_SUB=linux_x64 ;;
    aarch64|arm64) WV_MOZ=Linux_aarch64-gcc3; WV_SUB=linux_arm64 ;;
    *) return 1 ;;
  esac
}

# The module directory the hint names, or nothing.
widevine_hint_path() {
  [ -f "$(widevine_hint)" ] || return 0
  sed -n 's/.*"Path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$(widevine_hint)" | head -n 1
}
widevine_module_ok() {
  [ -n "$1" ] && [ -f "$1/manifest.json" ] && [ -f "$1/_platform_specific/$WV_SUB/libwidevinecdm.so" ]
}
widevine_version_of() {
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9.]*\)".*/\1/p' "$1/manifest.json" 2>/dev/null | head -n 1
}
# The hint is ours when it names a directory below $WIDEVINE_DIR.
widevine_hint_ours() {
  case "$(widevine_hint_path)" in "$WIDEVINE_DIR"/?*) return 0 ;; *) return 1 ;; esac
}

# Reads Mozilla's answer in $1: sets WV_VERSION, WV_URL, WV_MIRROR, WV_SHA512.
widevine_parse() {
  wv_line=$(tr '\n' ' ' < "$1" | sed 's/<addon /\n<addon /g' | grep 'id="gmp-widevinecdm"' | head -n 1)
  WV_VERSION=$(printf '%s' "$wv_line" | sed -n 's/.* version="\([0-9.]*\)".*/\1/p')
  WV_MIRROR=$(printf '%s' "$wv_line" | sed -n 's/.*<mirror URL="\([^"]*\)".*/\1/p')
  wv_hash_fn=$(printf '%s' "$wv_line" | sed -n 's/.* hashFunction="\([a-z0-9]*\)".*/\1/p')
  WV_SHA512=$(printf '%s' "$wv_line" | sed -n 's/.* hashValue="\([0-9a-fA-F]*\)".*/\1/p')
  # The first URL= in the line is the addon's own (the mirror follows it).
  WV_URL=$(printf '%s' "$wv_line" | sed -n 's/^<addon [^>]* URL="\([^"]*\)".*/\1/p')
  valid_version "$WV_VERSION" || return 1
  [ "$wv_hash_fn" = sha512 ] && [ "${#WV_SHA512}" = 128 ] || return 1
  case "$WV_URL" in https://*) ;; file://*) [ -n "${NIRUX_WIDEVINE_UPDATE_URL:-}" ] || return 1 ;; *) return 1 ;; esac
  case "$WV_MIRROR" in https://*|'') ;; *) WV_MIRROR= ;; esac
  return 0
}

# Download, check and unpack version $WV_VERSION into $WIDEVINE_DIR/$WV_VERSION.
# The file is a CRX3: "Cr24", format 3, a header of N bytes, then a zip.
widevine_download() {
  wd_tmp=$WORK/widevine
  rm -rf "$wd_tmp"; mkdir -p "$wd_tmp" || return 1
  fetch "$WV_URL" "$wd_tmp/cdm.crx3" 2>/dev/null || \
    { [ -n "$WV_MIRROR" ] && fetch "$WV_MIRROR" "$wd_tmp/cdm.crx3" 2>/dev/null; } || \
    { WV_REASON='the download from Google failed'; return 1; }
  wd_sum=$(sha512sum "$wd_tmp/cdm.crx3" | cut -d ' ' -f1)
  [ "$wd_sum" = "$(printf '%s' "$WV_SHA512" | tr 'A-F' 'a-f')" ] || \
    { WV_REASON='the download does not match its checksum'; rm -rf "$wd_tmp"; return 1; }
  [ "$(head -c 4 "$wd_tmp/cdm.crx3")" = Cr24 ] || { WV_REASON='the download is not a CRX3 file'; return 1; }
  wd_header=$(od -An -tu4 -j8 -N4 "$wd_tmp/cdm.crx3" | tr -d ' ')
  case "$wd_header" in ''|*[!0-9]*) WV_REASON='the download has no CRX3 header'; return 1 ;; esac
  tail -c +$((12 + wd_header + 1)) "$wd_tmp/cdm.crx3" > "$wd_tmp/cdm.zip" || return 1
  mkdir -p "$wd_tmp/unpack"
  unzip -q -o "$wd_tmp/cdm.zip" -d "$wd_tmp/unpack" >/dev/null 2>&1 || \
    { WV_REASON='the download could not be unpacked'; return 1; }
  widevine_module_ok "$wd_tmp/unpack" || { WV_REASON="the download has no $WV_SUB module"; return 1; }
  [ "$(widevine_version_of "$wd_tmp/unpack")" = "$WV_VERSION" ] || \
    { WV_REASON='the module reports another version'; return 1; }
  chmod -R go-w "$wd_tmp/unpack"
  mkdir -p "$WIDEVINE_DIR" || return 1
  rm -rf "${WIDEVINE_DIR:?}/.$WV_VERSION.$$" "${WIDEVINE_DIR:?}/$WV_VERSION"
  mv "$wd_tmp/unpack" "$WIDEVINE_DIR/.$WV_VERSION.$$" && \
    mv "$WIDEVINE_DIR/.$WV_VERSION.$$" "$WIDEVINE_DIR/$WV_VERSION" || return 1
  rm -rf "$wd_tmp"
}

widevine_write_hint() {
  case "$1" in *'"'*|*'\'*) return 1 ;; esac
  wh_hint=$(widevine_hint)
  mkdir -p "${wh_hint%/*}" || return 1
  printf '{"Path":"%s"}' "$1" > "$wh_hint.nirux.$$" && mv -f "$wh_hint.nirux.$$" "$wh_hint"
}

# Keep the module the hint names and the newest other one (a running Helium
# may still use it until it restarts); remove the rest.
widevine_prune() {
  wp_keep=$1; wp_spare=
  for wp_dir in $(for wp_d in "$WIDEVINE_DIR"/[0-9]*; do [ -d "$wp_d" ] && say "${wp_d##*/}"; done | sort -t. -k1,1nr -k2,2nr -k3,3nr -k4,4nr); do
    [ "$WIDEVINE_DIR/$wp_dir" != "$wp_keep" ] || continue
    if [ -z "$wp_spare" ]; then wp_spare=$wp_dir; continue; fi
    rm -rf "${WIDEVINE_DIR:?}/$wp_dir"
  done
}

widevine_remove() {
  if widevine_hint_ours; then rm -f "$(widevine_hint)"; fi
  rm -rf "$WIDEVINE_DIR"
}

widevine_helium_present() {
  browser_path >/dev/null 2>&1 || [ -d "$(widevine_profile)" ]
}

# Called on install and update after the browser. Never fails the update.
widevine_apply() {
  WV_REASON=
  if [ "$(widevine_policy)" = off ]; then widevine_remove; return 0; fi
  widevine_helium_present || return 0
  widevine_platform || { say "Widevine in Helium: not available for $(uname -m)"; return 0; }
  wa_current=$(widevine_hint_path)
  if [ -n "$wa_current" ] && ! widevine_hint_ours && widevine_module_ok "$wa_current"; then
    say "Widevine in Helium: using your own module at $wa_current"
    return 0
  fi
  [ -n "${WORK:-}" ] || return 0
  mkdir -p "$WORK" || return 0
  wa_have=
  widevine_hint_ours && widevine_module_ok "$wa_current" && wa_have=$(widevine_version_of "$wa_current")
  wa_url=$(say "$WIDEVINE_UPDATE_URL" | sed "s|%PLATFORM%|$WV_MOZ|")
  if ! fetch "$wa_url" "$WORK/widevine-update.xml" 2>/dev/null || ! widevine_parse "$WORK/widevine-update.xml"; then
    if [ -n "$wa_have" ]; then say "Widevine in Helium: $wa_have (could not check for a newer module)"
    else say 'Widevine in Helium: not installed (the module list could not be read; nirux update tries again)'; fi
    return 0
  fi
  wa_dir=$WIDEVINE_DIR/$WV_VERSION
  if [ "$wa_have" = "$WV_VERSION" ]; then
    say "Widevine in Helium: $WV_VERSION is current"
    return 0
  fi
  if ! widevine_module_ok "$wa_dir" || [ "$(widevine_version_of "$wa_dir")" != "$WV_VERSION" ]; then
    say "Downloading the Widevine module $WV_VERSION from Google"
    if ! widevine_download; then
      say "nirux: Widevine $WV_VERSION not installed: ${WV_REASON:-download failed}" >&2
      return 0
    fi
  fi
  widevine_write_hint "$wa_dir" || { say 'nirux: could not write the Widevine hint for Helium' >&2; return 0; }
  widevine_prune "$wa_dir"
  if pgrep -u "$(id -u)" -x helium >/dev/null 2>&1; then
    say "Widevine in Helium: $WV_VERSION installed; quit and start Helium (every window) to play Netflix and other protected video"
  else
    say "Widevine in Helium: $WV_VERSION installed (Netflix and other protected video)"
  fi
}

widevine_doctor() {
  if [ "$(widevine_policy)" = off ]; then say 'widevine: off (nirux widevine on turns it on)'; return 0; fi
  widevine_helium_present || { say 'widevine: Helium is not installed'; return 0; }
  widevine_platform || { say "widevine: not available for $(uname -m)"; return 0; }
  wd_path=$(widevine_hint_path)
  if widevine_module_ok "$wd_path"; then
    if widevine_hint_ours; then say "widevine: $(widevine_version_of "$wd_path") on, Netflix and other protected video play in Helium"
    else say "widevine: Helium uses your own module $(widevine_version_of "$wd_path") at $wd_path"; fi
  else
    say 'widevine: not installed, so Netflix and other protected video do not play in Helium'
    doctor_offer widevine
  fi
}

widevine_command() {
  [ "$#" -le 1 ] || die 'usage: nirux widevine [status|on|off]'
  case "${1:-status}" in
    status) widevine_doctor ;;
    on)
      widevine_policy_set on
      wc_work=$(mktemp -d "${TMPDIR:-/tmp}/nirux-widevine.XXXXXX") || die 'could not create a work directory'
      wc_saved=${WORK:-}; WORK=$wc_work
      widevine_apply
      WORK=$wc_saved; rm -rf "$wc_work"
      widevine_module_ok "$(widevine_hint_path)" || die 'Widevine is on, but the module could not be installed yet; nirux update tries again'
      ;;
    off)
      widevine_policy_set off
      widevine_remove
      say 'Widevine removed from Helium. Quit and start Helium to drop it; nirux widevine on brings it back.'
      ;;
    *) die 'widevine must be status, on or off' ;;
  esac
}
