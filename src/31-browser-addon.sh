browser_addon_policy() {
  if [ -f "$STATE/browser-addon-policy" ]; then
    value=$(awk '$1 == "addon" && ($2 == "bonjourr" || $2 == "none") {print $2; exit}' "$STATE/browser-addon-policy")
    [ -n "$value" ] || value=none
    say "$value"
  else
    say none
  fi
}

browser_addon_policy_set() {
  mkdir -p "$STATE"
  printf '# NIRUX owner: %s
addon %s
' "$PREFIX" "$1" > "$STATE/.browser-addon-policy.$$" || \
    die 'could not stage the browser addon policy'
  mv -f "$STATE/.browser-addon-policy.$$" "$STATE/browser-addon-policy" || \
    die 'could not persist the browser addon policy'
}

browser_bonjourr_preset() {
  preset_dir=$STATE/browser-presets
  preset=$preset_dir/bonjourr-nirux.json
  mkdir -p "$preset_dir" || die 'could not create the browser preset directory'
  cat > "$preset.tmp.$$" <<'JSON'
{
  "about": {
    "browser": "chrome",
    "version": "22.3.0"
  },
  "lang": "en",
  "dateformat": "eu",
  "dark": "dark",
  "pagegap": 1,
  "pagewidth": 1600,
  "time": true,
  "showall": false,
  "quicklinks": true,
  "linkstyle": "medium",
  "linktitles": true,
  "linkbackgrounds": false,
  "linksrow": 5,
  "linkgroups": {
    "on": true,
    "selected": "default",
    "groups": [
      "default"
    ],
    "pinned": [],
    "synced": []
  },
  "textShadow": 0.18,
  "backgrounds": {
    "type": "color",
    "color": "#0f0f10",
    "fadein": 0,
    "blur": 0,
    "bright": 0.8,
    "frequency": "hour",
    "texture": {
      "type": "none"
    }
  },
  "clock": {
    "size": 1.1,
    "ampm": false,
    "analog": false,
    "seconds": false,
    "ampmlabel": false,
    "worldclocks": false,
    "timezone": "auto"
  },
  "weather": {
    "unit": "metric",
    "show_unit": false,
    "moreinfo": "none",
    "forecast": "auto",
    "temperature": "actual",
    "geolocation": "approximate"
  },
  "quotes": {
    "on": false,
    "author": false,
    "frequency": "day"
  },
  "notes": {
    "on": false
  },
  "searchbar": {
    "on": false
  },
  "pomodoro": {
    "on": false
  },
  "supporters": {
    "enabled": false
  },
  "greeting": "",
  "greetingsmode": "auto",
  "greetingscustom": {
    "morning": "",
    "afternoon": "",
    "evening": "",
    "night": ""
  },
  "font": {
    "family": "Noto Sans",
    "size": "14",
    "system": true,
    "color": "#eceff4",
    "weightlist": [],
    "weight": "300"
  },
  "linksnirux1": {
    "_id": "linksnirux1",
    "parent": "default",
    "order": 1,
    "title": "NIRUX",
    "url": "https://github.com/nirucon/nirux"
  },
  "linksnirux2": {
    "_id": "linksnirux2",
    "parent": "default",
    "order": 2,
    "title": "NIRUCLIP",
    "url": "https://github.com/nirucon/niruclip"
  },
  "linksnirux3": {
    "_id": "linksnirux3",
    "parent": "default",
    "order": 3,
    "title": "NIRUPRES",
    "url": "https://github.com/nirucon/nirupres"
  }
}
JSON
  mv -f "$preset.tmp.$$" "$preset" || die 'could not publish the Bonjourr preset'
  say "$preset"
}

browser_addon_apply() {
  addon=${1:-$(browser_addon_policy)}
  case "$addon" in
    none)
      remove_binary "$BROWSER_ADDON_POLICY"
      return 0 ;;
    bonjourr) ;;
    *) die "unknown browser addon: $addon" ;;
  esac
  if ! browser_path >/dev/null 2>&1; then
    say 'Bonjourr is requested but Helium is not installed; browser policy skipped.'
    return 0
  fi
  preset=$(browser_bonjourr_preset)
  mkdir -p "$WORK" 2>/dev/null || :
  policy_tmp=$(mktemp "${TMPDIR:-/tmp}/nirux-bonjourr.XXXXXX") || die 'could not create browser policy temp file'
  printf '%s\n' "{\"ExtensionInstallForcelist\":[\"$BROWSER_ADDON_BONJOURR_ID;https://clients2.google.com/service/update2/crx\"]}" > "$policy_tmp"
  write_binary "$BROWSER_ADDON_POLICY" "$policy_tmp"
  rm -f "$policy_tmp"
  say "Bonjourr enabled for Helium. Preset: $preset"
  say 'Restart Helium; the extension is force-installed by its managed policy.'
}

browser_addon_remove() {
  remove_binary "$BROWSER_ADDON_POLICY"
  rm -f "$STATE/browser-addon-policy"
  rm -rf "$STATE/browser-presets"
}

browser_addon_choose() {
  if [ "$BROWSER_ADDON_EXPLICIT" = 1 ] && [ "$BROWSER_ADDON_CHOICE" != keep ]; then
    BROWSER_ADDON_EFFECTIVE=$BROWSER_ADDON_CHOICE
  elif [ "$operation" = update ]; then
    BROWSER_ADDON_EFFECTIVE=$(browser_addon_policy)
  elif [ -t 0 ]; then
    say 'Install Bonjourr (new-tab page) in Helium with a NIRUX preset? [y/N]'
    printf 'Install Bonjourr [y/N]: '
    IFS= read -r addon_answer || addon_answer=no
    case "$addon_answer" in [yY]*) BROWSER_ADDON_EFFECTIVE=bonjourr ;; *) BROWSER_ADDON_EFFECTIVE=none ;; esac
  else
    BROWSER_ADDON_EFFECTIVE=none
  fi
  case "$BROWSER_ADDON_EFFECTIVE" in bonjourr|none) ;; *) die 'browser-addon must be bonjourr, none or keep' ;; esac
  if [ "$BROWSER_ADDON_EXPLICIT" = 1 ] || [ "$operation" = install ]; then
    browser_addon_policy_set "$BROWSER_ADDON_EFFECTIVE"
  fi
}


# ── Microsoft 365 in Helium ─────────────────────────────────────────────────
# Helium blocks third-party cookies and pop-ups. Teams, Outlook and the other
# Microsoft 365 web apps renew their sign-in in a hidden frame from
# login.microsoftonline.com and fall back to a pop-up, so a blocked frame shows
# "sign in again" and the button then does nothing. This managed policy lets
# only Microsoft's own sign-in and Microsoft 365 sites keep their cookies and
# open pop-ups, keeps Teams' and Outlook's storage unpartitioned, and lets
# Teams use the microphone, camera and notifications without asking each time.
# Every other site keeps Helium's defaults. Opt-in: nirux browser-m365 on.
BROWSER_M365_POLICY=$ROOT/etc/chromium/policies/managed/nirux-m365.json

browser_m365_policy() {
  value=
  [ ! -f "$STATE/browser-m365" ] || \
    value=$(awk '$1 == "m365" && ($2 == "on" || $2 == "off") {print $2; exit}' "$STATE/browser-m365")
  say "${value:-off}"
}

browser_m365_policy_set() {
  mkdir -p "$STATE"
  printf '# NIRUX owner: %s\nm365 %s\n' "$PREFIX" "$1" > "$STATE/.browser-m365.$$" || \
    die 'could not stage the Microsoft 365 browser setting'
  mv -f "$STATE/.browser-m365.$$" "$STATE/browser-m365" || \
    die 'could not persist the Microsoft 365 browser setting'
}

browser_m365_json() {
  cat <<'JSON'
{
  "CookiesAllowedForUrls": [
    "[*.]microsoftonline.com", "[*.]microsoft.com", "[*.]cloud.microsoft",
    "[*.]microsoft365.com", "[*.]office.com", "[*.]office.net",
    "[*.]office365.com", "[*.]live.com", "[*.]sharepoint.com",
    "[*.]onenote.com", "[*.]msauth.net", "[*.]msftauth.net",
    "[*.]msauthimages.net", "[*.]msftauthimages.net", "[*.]skype.com",
    "[*.]sfbassets.com", "[*.]teams.microsoft.com"
  ],
  "PopupsAllowedForUrls": [
    "[*.]cloud.microsoft", "[*.]microsoft.com", "[*.]microsoftonline.com",
    "[*.]microsoft365.com", "[*.]office.com", "[*.]live.com",
    "[*.]sharepoint.com"
  ],
  "ThirdPartyStoragePartitioningBlockedForOrigins": [
    "https://teams.cloud.microsoft", "https://teams.microsoft.com",
    "https://outlook.cloud.microsoft", "https://outlook.office.com",
    "https://m365.cloud.microsoft", "https://www.office.com"
  ],
  "NotificationsAllowedForUrls": [
    "https://teams.cloud.microsoft", "https://teams.microsoft.com",
    "https://outlook.cloud.microsoft", "https://outlook.office.com"
  ],
  "AudioCaptureAllowedUrls": [
    "https://teams.cloud.microsoft", "https://teams.microsoft.com"
  ],
  "VideoCaptureAllowedUrls": [
    "https://teams.cloud.microsoft", "https://teams.microsoft.com"
  ]
}
JSON
}

browser_m365_apply() {
  m365=${1:-$(browser_m365_policy)}
  case "$m365" in
    off) remove_binary "$BROWSER_M365_POLICY"; return 0 ;;
    on) ;;
    *) die "unknown Microsoft 365 browser setting: $m365" ;;
  esac
  policy_tmp=$(mktemp "${TMPDIR:-/tmp}/nirux-m365.XXXXXX") || die 'could not create browser policy temp file'
  browser_m365_json > "$policy_tmp"
  write_binary "$BROWSER_M365_POLICY" "$policy_tmp"
  rm -f "$policy_tmp"
}

browser_m365_status() {
  say "microsoft 365 sign-in: $(browser_m365_policy)"
  if [ -f "$BROWSER_M365_POLICY" ]; then say "policy: $BROWSER_M365_POLICY"; else say 'policy: not installed'; fi
}

# write_binary keeps its ownership record in $WORK, which only an install or
# update sets up. A direct browser command gets its own for the call.
browser_command_work() {
  [ -z "$WORK" ] || return 0
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/nirux-browser.XXXXXX") || die 'could not create a work directory'
  BROWSER_COMMAND_WORK=$WORK
}

browser_command_work_done() {
  [ -z "${BROWSER_COMMAND_WORK:-}" ] || rm -rf "$BROWSER_COMMAND_WORK"
  BROWSER_COMMAND_WORK=
}

browser_m365_command() {
  [ "$#" = 1 ] || die 'usage: nirux browser-m365 on|off|status'
  [ "$1" = status ] || browser_command_work
  case "$1" in
    status) browser_m365_status ;;
    on|off)
      # Install or remove the policy first: a failed sudo leaves the old choice.
      browser_m365_apply "$1"
      browser_m365_policy_set "$1"
      if [ "$1" = on ]; then
        say 'Microsoft 365 sign-in allowed in Helium. Quit and start Helium once (every window) to load it.'
      else
        say 'Microsoft 365 sign-in policy removed. Restart Helium to drop it.'
      fi ;;
    *) die 'browser-m365 must be on, off or status' ;;
  esac
  browser_command_work_done
}

browser_m365_remove() {
  remove_binary "$BROWSER_M365_POLICY"
  rm -f "$STATE/browser-m365"
}
