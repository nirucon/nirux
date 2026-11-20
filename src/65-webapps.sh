# Web apps (docs: manual chapter 12, NIRUWEBAPP). A fresh install offers the
# NIRUWEBAPP catalogue sets and a Nextcloud address; an update never adds web
# apps unless --webapps or --nextcloud is given. Existing web apps are never
# changed: niruwebapp add skips a service that is already there.
#
# The set names mirror `niruwebapp catalog`; the question is asked before the
# new niruwebapp is installed, so it cannot be asked of the binary.
WEBAPPS_SETS='work ai google proton media other'
WEBAPPS_DEFAULT='ai media'
WEBAPPS_CHOICE=
WEBAPPS_EXPLICIT=0
WEBAPPS_EFFECTIVE=
WEBAPPS_NEXTCLOUD=

webapps_sets_text() {
  say '  work    Microsoft 365: Teams, Outlook, Outlook Calendar, Copilot, Loop, Planner, OneDrive'
  say '  ai      Claude, ChatGPT, Gemini, Grok, Gemini Notebook'
  say '  google  Gmail, Google Calendar, Google Drive'
  say '  proton  Proton Mail, Calendar, Drive and Pass'
  say '  media   YouTube, YouTube Music, SVT Play'
  say '  other   Spotify, Discord, GitHub, Excalidraw'
}

# Normalise a set list ("ai,media", "all", "none") to space-separated names,
# or fail on an unknown name.
webapps_normalise() {
  wn_list=$(printf '%s' "$1" | tr ',' ' ' | tr '[:upper:]' '[:lower:]')
  wn_out=
  for wn_word in $wn_list; do
    case "$wn_word" in
      none) say none; return 0 ;;
      all) wn_out=$WEBAPPS_SETS; continue ;;
    esac
    case " $WEBAPPS_SETS " in
      *" $wn_word "*) case " $wn_out " in *" $wn_word "*) ;; *) wn_out="${wn_out:+$wn_out }$wn_word" ;; esac ;;
      *) return 1 ;;
    esac
  done
  say "${wn_out:-none}"
}

webapps_choose() {
  wc_operation=$1
  if [ "$WEBAPPS_EXPLICIT" = 1 ]; then
    WEBAPPS_EFFECTIVE=$(webapps_normalise "$WEBAPPS_CHOICE") ||
      die "webapps must be none, all or sets from: $WEBAPPS_SETS"
  elif [ "$wc_operation" = install ] && [ -t 0 ]; then
    say 'Web apps open sites such as Teams or Gmail in their own windows (NIRUWEBAPP).'
    webapps_sets_text
    while :; do
      printf 'Which sets? Names separated by spaces, "all" or "none" [%s]: ' "$WEBAPPS_DEFAULT"
      IFS= read -r wc_answer || wc_answer=
      [ -n "$wc_answer" ] || wc_answer=$WEBAPPS_DEFAULT
      WEBAPPS_EFFECTIVE=$(webapps_normalise "$wc_answer") && break
      say "Unknown set. Choose from: $WEBAPPS_SETS"
    done
    if [ -z "$WEBAPPS_NEXTCLOUD" ]; then
      printf 'Your Nextcloud address, if you have one (empty skips): '
      IFS= read -r WEBAPPS_NEXTCLOUD || WEBAPPS_NEXTCLOUD=
    fi
  else
    # A noninteractive install adds nothing it was not asked for.
    WEBAPPS_EFFECTIVE=none
  fi
  [ "$WEBAPPS_EFFECTIVE" != none ] || WEBAPPS_EFFECTIVE=
  WEBAPPS_NEXTCLOUD=$(printf '%s' "$WEBAPPS_NEXTCLOUD" | tr -d '[:space:]')
  case "$WEBAPPS_NEXTCLOUD" in
    *[!A-Za-z0-9:/._~%?\&=+@-]*) die 'the Nextcloud address has characters a web address cannot have' ;;
  esac
}

# After the new programs are active: add the chosen sets, and on every
# install or update let niruwebapp move web apps off addresses a service has
# left. Failures never stop the install.
webapps_apply() {
  wa_bin=$BIN/niruwebapp
  [ -x "$wa_bin" ] || return 0
  wa_sets=${1:-}; wa_cloud=${2:-}
  if [ -n "$wa_sets" ]; then
    say "Adding web apps: $wa_sets"
    # shellcheck disable=SC2086 # one word per set
    "$wa_bin" add $wa_sets </dev/null | sed -n 's/^added /  added /p' ||
      say "Could not add every web app; run: nirux webapps add $wa_sets"
  fi
  if [ -n "$wa_cloud" ]; then
    "$wa_bin" add nextcloud --url "$wa_cloud" </dev/null | sed 's/^/  /' ||
      say "Could not add Nextcloud; run: nirux webapps add nextcloud --url ADDRESS"
  fi
  if [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/niruwebapp/apps.tsv" ]; then
    "$wa_bin" refresh >/dev/null 2>"$WORK/webapps-refresh" || :
    sed -n 's/^niruwebapp: /Web app /p' "$WORK/webapps-refresh" 2>/dev/null | grep ' moved from ' || :
  fi
}

# `nirux webapps [list | add SET|KEY... [--url URL] | check]`
webapps_command() {
  wa_bin=$BIN/niruwebapp
  [ -x "$wa_bin" ] || die 'niruwebapp is not installed; run nirux update'
  case "${1:-list}" in
    list|catalog) shift 2>/dev/null || :; "$wa_bin" catalog "$@" ;;
    add) shift; [ "$#" -gt 0 ] || die 'usage: nirux webapps add SET|KEY... [--url URL]'; "$wa_bin" add "$@" ;;
    check)
      [ -x "$CHECKUP_HELPER" ] || die 'the address check comes with the checkup; run nirux update'
      "$CHECKUP_HELPER" webapps-check "${XDG_DATA_HOME:-$HOME/.local/share}/niruwebapp/apps.tsv" ;;
    -h|--help) say 'usage: nirux webapps [list [SET...] | add SET|KEY... [--url URL] [--dry-run] | check]' ;;
    *) die "unknown webapps command: $1 (nirux webapps --help)" ;;
  esac
}
