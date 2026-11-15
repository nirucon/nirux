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

