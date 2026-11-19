terminal_config_home() {
  say "${XDG_CONFIG_HOME:-$HOME/.config}/nirux"
}
append_managed_block() {
  block_target=$1
  block_source=$2
  block_start='# NIRUX terminal integration (managed)'
  block_end='# End NIRUX terminal integration'
  block_dir=$(dirname "$block_target")
  mkdir -p "$block_dir" || die "could not create $block_dir"
  block_tmp=$(mktemp "$block_dir/.nirux-block.XXXXXX") || die "could not stage $block_target"
  if [ -e "$block_target" ]; then
    [ -f "$block_target" ] || die "$block_target is not a regular file"
    block_mode=$(stat -c %a "$block_target") || die "could not read permissions for $block_target"
    if grep -qF "$block_start" "$block_target"; then
      awk -v s="$block_start" -v e="$block_end" '
        $0 == s {skip = 1; next}
        $0 == e {skip = 0; next}
        !skip {print}
      ' "$block_target" > "$block_tmp" || die "could not stage $block_target"
    else
      [ -f "$block_target.nirux-backup" ] || cp -p "$block_target" "$block_target.nirux-backup" || \
        die "could not back up $block_target"
      cp -p "$block_target" "$block_tmp" || die "could not stage $block_target"
    fi
  else
    block_mode=644
    printf '# NIRUX owner: %s\n' "$PREFIX" > "$block_tmp"
  fi
  [ ! -s "$block_tmp" ] || printf '\n' >> "$block_tmp"
  cat "$block_source" >> "$block_tmp" || die "could not append the terminal block to $block_target"
  chmod "$block_mode" "$block_tmp" || die "could not set permissions on $block_target"
  mv -f "$block_tmp" "$block_target" || die "could not update $block_target"
}
remove_managed_block() {
  block_target=$1
  [ -f "$block_target" ] || return 0
  block_start='# NIRUX terminal integration (managed)'
  block_end='# End NIRUX terminal integration'
  grep -qF "$block_start" "$block_target" || return 0
  block_dir=$(dirname "$block_target")
  block_tmp=$(mktemp "$block_dir/.nirux-block.XXXXXX") || die "could not stage $block_target"
  block_mode=$(stat -c %a "$block_target") || die "could not read permissions for $block_target"
  awk -v s="$block_start" -v e="$block_end" '
    $0 == s {skip = 1; next}
    $0 == e {skip = 0; next}
    !skip {print}
  ' "$block_target" > "$block_tmp" || die "could not stage $block_target"
  chmod "$block_mode" "$block_tmp" || die "could not set permissions on $block_target"
  mv -f "$block_tmp" "$block_target" || die "could not update $block_target"
}
sounds_apps_block() {
  cat <<'EOF'

# Per-app notification sounds. The key is the app name a notification is sent
# with (see `nirunotify --history`), compared case-insensitively. The value is
# a sound name, which plays NAME.ogg from ~/.config/nirux/sounds or the NIRUX
# sounds; a file path (absolute or ~/...); "default" for the normal
# notification sound; or "off" to keep the notification silent.
[sounds.apps]
thunderbird = "mail"
signal = "chat"
EOF
}

# Sound events and their categories. Every event can be replaced by
# ~/.config/nirux/sounds/EVENT.ogg. An event is on when [sounds] enabled, its
# category's `enabled` and its own key are all true. The event key is read
# from the category table first, then from [sounds] (where startup, update,
# shutdown and notification have always lived), then from the default.
SOUNDS_CATEGORIES='system notifications feedback power devices dictation network'

sounds_category_events() {
  case "$1" in
    system) say 'startup update shutdown auth-fail lock unlock lock-typing meet-ready meet-problem' ;;
    notifications) say 'notification timer-done reminder' ;;
    feedback) say 'volume-up volume-down volume-limit mute unmute brightness-up brightness-down screenshot mic-mute mic-unmute record-start record-stop' ;;
    power) say 'power-plug power-unplug battery-low battery-critical battery-full' ;;
    devices) say 'device-connect device-disconnect' ;;
    dictation) say 'dictation-start dictation-stop dictation-done dictation-error' ;;
    network) say 'network-down network-up' ;;
  esac
}

sounds_category() {
  case "$1" in
    startup|update|shutdown|auth-fail|lock|unlock|lock-typing|meet-ready|meet-problem) say system ;;
    notification|timer-done|reminder) say notifications ;;
    volume-up|volume-down|volume-limit|mute|unmute|brightness-up|brightness-down|screenshot) say feedback ;;
    mic-mute|mic-unmute|record-start|record-stop) say feedback ;;
    power-plug|power-unplug|battery-low|battery-critical|battery-full) say power ;;
    device-connect|device-disconnect) say devices ;;
    dictation-start|dictation-stop|dictation-done|dictation-error) say dictation ;;
    network-down|network-up) say network ;;
    *) return 1 ;;
  esac
}

sounds_event_default() {
  case "$1" in
    brightness-up|brightness-down|battery-full|lock|unlock|dictation-done) say false ;;
    *) say true ;;
  esac
}

sounds_all_events() {
  for sounds_ae_cat in $SOUNDS_CATEGORIES; do sounds_category_events "$sounds_ae_cat"; done | tr '\n' ' '
}

sounds_category_block() {
  case "$1" in
    system) cat <<'EOF'

# System sounds. startup, update and shutdown are switched in [sounds] above.
[sounds.system]
enabled = true
auth-fail = true
lock = false
unlock = false
# Typewriter keys while you type the password in NIRULOCK.
lock-typing = true
# The result of `nirux meet-check`: ready for a call, or something to fix.
meet-ready = true
meet-problem = true
EOF
    ;;
    notifications) cat <<'EOF'

# Notification sounds (the notification key in [sounds] above and the app
# sounds in [sounds.apps]), the bar timer and calendar reminders. Do Not
# Disturb silences notifications and reminders; a timer you set still sounds.
[sounds.notifications]
enabled = true
timer-done = true
reminder = true
EOF
    ;;
    feedback) cat <<'EOF'

# Feedback for keys you press. Volume ticks play on the new level, so you
# hear how loud it is; holding a key plays at most one tick per rate_limit_ms.
[sounds.feedback]
enabled = true
volume-up = true
volume-down = true
volume-limit = true
mute = true
unmute = true
brightness-up = false
brightness-down = false
screenshot = true
# The microphone muted and live again (niructl audio mic-mute).
mic-mute = true
mic-unmute = true
# A screen recording (NIRUCLIP) starts and stops.
record-start = true
record-stop = true
rate_limit_ms = 80
EOF
    ;;
    power) cat <<'EOF'

# Charger and battery. battery-low and battery-critical sound once per
# discharge when the battery falls to the given percentage.
[sounds.power]
enabled = true
power-plug = true
power-unplug = true
battery-low = true
battery-critical = true
battery-full = false
battery_low_percent = 20
battery_critical_percent = 5
battery_full_percent = 100
EOF
    ;;
    devices) cat <<'EOF'

# Devices that come and go: USB, audio devices, monitors and, if you want,
# Bluetooth links. A burst (a dock) is one sound per debounce_ms.
[sounds.devices]
enabled = true
device-connect = true
device-disconnect = true
usb = true
audio = true
displays = true
bluetooth = false
debounce_ms = 1500
EOF
    ;;
    dictation) cat <<'EOF'

# NIRUDICTATE (an extra): start and stop of a dictation, the text being
# inserted, and a dictation that failed. Silent without NIRUDICTATE.
[sounds.dictation]
enabled = true
dictation-start = true
dictation-stop = true
dictation-done = false
dictation-error = true
EOF
    ;;
    network) cat <<'EOF'

# The connection is lost (no default route for a few seconds) and back.
# Never at login or right after a resume, and a flapping link is one sound.
[sounds.network]
enabled = true
network-down = true
network-up = true
EOF
    ;;
  esac
}

sounds_ensure_config() {
  if [ -f "$SOUNDS_CONFIG" ]; then
    sounds_migrate
    return 0
  fi
  mkdir -p "$NIRUX_CONFIG" || return 0
  {
    cat <<'EOF'
[sounds]
enabled = true
volume = 35
startup = true
notification = true
update = true
shutdown = true
notification_cooldown_ms = 2500
notification_exclude_apps = ["nplay", "spotify"]
respect_mute = true
EOF
    for sounds_cat in $SOUNDS_CATEGORIES; do sounds_category_block "$sounds_cat"; done
    sounds_apps_block
  } > "$SOUNDS_CONFIG.tmp.$$"
  mv -f "$SOUNDS_CONFIG.tmp.$$" "$SOUNDS_CONFIG" 2>/dev/null || rm -f "$SOUNDS_CONFIG.tmp.$$"
}

sounds_has_table() {
  grep -q "^[[:space:]]*\[$(printf '%s' "$1" | sed 's/\./\\./g')\][[:space:]]*\(#.*\)\{0,1\}$" "$SOUNDS_CONFIG" 2>/dev/null
}

# Events added to a category table after it was first written. A table that
# already exists gains these keys once, with their defaults, so they can be
# seen and switched in the file; a key that is set anywhere stays as it is.
SOUNDS_ADDED_EVENTS='meet-ready meet-problem timer-done reminder mic-mute mic-unmute record-start record-stop'

# Print the config with each missing added event key inserted after the last
# key of its existing table. With CHECK=1, print nothing and succeed only when
# a key is missing.
sounds_insert_keys() {
  sounds_ik_spec=
  for sounds_ik in $SOUNDS_ADDED_EVENTS; do
    sounds_ik_spec="$sounds_ik_spec sounds.$(sounds_category "$sounds_ik")=$sounds_ik=$(sounds_event_default "$sounds_ik")"
  done
  awk -v spec="$sounds_ik_spec" -v check="$1" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function header(line,   s) { s = line; sub(/^[[:space:]]*\[/, "", s); sub(/\][[:space:]]*(#.*)?$/, "", s); return trim(s) }
    function keyof(line,   k) { k = trim(substr(line, 1, index(line, "=") - 1)); gsub(/^"|"$/, "", k); return tolower(k) }
    function flush() { if (sec in add) { printf "%s", add[sec]; delete add[sec] } printf "%s", held; held = "" }
    NR == FNR {
      if ($0 ~ /^[[:space:]]*\[/) { sec = header($0); tables[sec] = 1; next }
      if (FNR == 1) sec = "sounds"
      if (index($0, "=") > 0) have[sec SUBSEP keyof($0)] = 1
      next
    }
    FNR == 1 {
      n = split(spec, items, " ")
      for (i = 1; i <= n; i++) {
        split(items[i], f, "=")
        if ((f[1] in tables) && !((f[1] SUBSEP f[2]) in have) && !(("sounds" SUBSEP f[2]) in have)) {
          add[f[1]] = add[f[1]] f[2] " = " f[3] "\n"; missing = 1
        }
      }
      if (check) exit !missing
      sec = "sounds"; held = ""
    }
    /^[[:space:]]*\[/ { flush(); sec = header($0); print; next }
    /^[[:space:]]*(#.*)?$/ { held = held $0 "\n"; next }
    { printf "%s", held; held = ""; print }
    END { if (check) exit !missing; flush() }
  ' "$SOUNDS_CONFIG" "$SOUNDS_CONFIG" 2>/dev/null
}

# Older configurations lack [sounds.apps] and the category tables. Each
# missing table is appended once with its defaults; a table that exists, even
# an empty one, is the user's choice and keeps its keys, gaining only the
# events added since (SOUNDS_ADDED_EVENTS). Keys already in [sounds] keep their
# meaning, because they are read before the defaults.
sounds_migrate() {
  [ -f "$SOUNDS_CONFIG" ] || return 0
  sounds_missing=
  for sounds_cat in $SOUNDS_CATEGORIES; do
    sounds_has_table "sounds.$sounds_cat" || sounds_missing="$sounds_missing $sounds_cat"
  done
  sounds_has_table sounds.apps && sounds_need_apps=0 || sounds_need_apps=1
  sounds_insert_keys 1 && sounds_need_keys=1 || sounds_need_keys=0
  [ -n "$sounds_missing" ] || [ "$sounds_need_apps" = 1 ] || [ "$sounds_need_keys" = 1 ] || return 0
  sounds_mig=$SOUNDS_CONFIG.tmp.$$
  if {
    sounds_insert_keys 0
    for sounds_cat in $sounds_missing; do sounds_category_block "$sounds_cat"; done
    [ "$sounds_need_apps" = 0 ] || sounds_apps_block
  } > "$sounds_mig" 2>/dev/null; then
    cp -p "$SOUNDS_CONFIG" "$SOUNDS_CONFIG.bak" 2>/dev/null || :
    mv -f "$sounds_mig" "$SOUNDS_CONFIG" 2>/dev/null || rm -f "$sounds_mig"
  else
    rm -f "$sounds_mig"
  fi
}

# Read KEY from TABLE ("sounds" or "sounds.apps"). Keys before the first table
# header count as [sounds], so a hand-written file without a header still works.
# Keys are compared case-insensitively and may be quoted; a quoted value keeps
# everything between its quotes, an unquoted value ends at a # comment.
sounds_table_value() {
  [ -f "$SOUNDS_CONFIG" ] || return 0
  awk -v want="$1" -v k="$2" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    BEGIN { sec = "sounds"; k = tolower(k) }
    /^[[:space:]]*\[/ {
      s = $0; sub(/^[[:space:]]*\[/, "", s); sub(/\][[:space:]]*(#.*)?$/, "", s)
      sec = trim(s); next
    }
    sec != want { next }
    {
      eq = index($0, "="); if (eq == 0) next
      key = trim(substr($0, 1, eq - 1)); gsub(/^"|"$/, "", key)
      if (tolower(key) != k) next
      v = trim(substr($0, eq + 1))
      if (substr(v, 1, 1) == "\"") {
        v = substr(v, 2); q = index(v, "\""); if (q > 0) v = substr(v, 1, q - 1)
      } else if (substr(v, 1, 1) != "[") {
        sub(/[[:space:]]*#.*$/, "", v)
      }
      print v; exit
    }' "$SOUNDS_CONFIG" 2>/dev/null || :
}

sounds_value() {
  sounds_found=$(sounds_table_value sounds "$1")
  if [ -n "$sounds_found" ]; then say "$sounds_found"; else say "$2"; fi
}

sounds_enabled() {
  [ "${NIRUX_SOUNDS:-}" = off ] && return 1
  [ "$(sounds_value enabled true)" = true ]
}

sounds_category_enabled() {
  [ "$(sounds_table_value "sounds.$1" enabled)" != false ]
}

# The event's own switch, true or false, ignoring the category and [sounds].
sounds_event_setting() {
  sounds_es_cat=$(sounds_category "$1") || { say false; return 0; }
  sounds_es=$(sounds_table_value "sounds.$sounds_es_cat" "$1")
  [ -n "$sounds_es" ] || sounds_es=$(sounds_table_value sounds "$1")
  [ -n "$sounds_es" ] || sounds_es=$(sounds_event_default "$1")
  say "$sounds_es"
}

sounds_event_enabled() {
  sounds_enabled || return 1
  sounds_ee_cat=$(sounds_category "$1") || return 1
  sounds_category_enabled "$sounds_ee_cat" || return 1
  [ "$(sounds_event_setting "$1")" = true ]
}

# A category table may set its own volume; otherwise [sounds] volume applies.
sounds_volume_for() {
  sounds_vf=
  sounds_vf_cat=$(sounds_category "$1" 2>/dev/null || :)
  [ -z "$sounds_vf_cat" ] || sounds_vf=$(sounds_table_value "sounds.$sounds_vf_cat" volume)
  [ -n "$sounds_vf" ] || sounds_vf=$(sounds_value volume 35)
  case "$sounds_vf" in ''|*[!0-9]*) sounds_vf=35 ;; esac
  [ "$sounds_vf" -ge 1 ] || sounds_vf=1
  [ "$sounds_vf" -le 100 ] || sounds_vf=100
  say "$sounds_vf"
}

sounds_muted() {
  [ "$(sounds_value respect_mute true)" = true ] || return 1
  command -v wpctl >/dev/null 2>&1 || return 1
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q '\[MUTED\]'
}

# Sets sounds_now (milliseconds, or empty). It does not print: the result used
# to travel through `say` in a command substitution, and a failed printf there
# (seen as "printf: I/O error" on a CI runner) left it empty, which skipped the
# rate limit and let a held key tick twice.
sounds_now_ms() {
  sounds_now=$(date +%s%3N 2>/dev/null || :)
  case "$sounds_now" in ''|*[!0-9]*) sounds_now= ;; esac
}

# True when STAMP is older than MS milliseconds (or missing); then renew it.
sounds_stamp_ok() {
  sounds_stamp=$1
  sounds_cd=$2
  sounds_now_ms
  [ -n "$sounds_now" ] || return 0
  if [ -f "$sounds_stamp" ]; then
    sounds_prev=$(cat "$sounds_stamp" 2>/dev/null || :)
    case "$sounds_prev" in ''|*[!0-9]*) sounds_prev=0 ;; esac
    # A clock that stepped back (NTP, a VM, resume) leaves a stamp in the
    # future; that must not silence every sound until the clock catches up.
    sounds_age=$((sounds_now - sounds_prev))
    [ "$sounds_age" -ge 0 ] && [ "$sounds_age" -lt "$sounds_cd" ] && return 1
  fi
  mkdir -p "$(dirname "$sounds_stamp")" 2>/dev/null || :
  printf '%s\n' "$sounds_now" > "$sounds_stamp" 2>/dev/null || :
  return 0
}

# Each notification sound has its own rate limit, so a chat message right after
# a mail still sounds. The plain notification keeps its historical stamp file.
# Held keys are limited per event by [sounds.feedback] rate_limit_ms.
sounds_cooldown() {
  case "$1" in
    notification)
      sounds_cd=$(sounds_value notification_cooldown_ms 2500)
      case "$sounds_cd" in ''|*[!0-9]*) sounds_cd=2500 ;; esac
      case "${2:-notification}" in
        notification) sounds_stamp=$SOUNDS_STATE/.notification-stamp ;;
        *) sounds_stamp=$SOUNDS_STATE/.notification-stamp-$(printf '%s' "$2" | tr -c 'A-Za-z0-9_-' '_') ;;
      esac
      sounds_stamp_ok "$sounds_stamp" "$sounds_cd" ;;
    volume-up|volume-down|volume-limit|mute|unmute|brightness-up|brightness-down|mic-mute|mic-unmute)
      sounds_cd=$(sounds_table_value sounds.feedback rate_limit_ms)
      case "$sounds_cd" in ''|*[!0-9]*) sounds_cd=80 ;; esac
      sounds_stamp_ok "$SOUNDS_STATE/.feedback-stamp-$1" "$sounds_cd" ;;
    *) return 0 ;;
  esac
}

sounds_app_key() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/\.desktop$//'
}

sounds_app_excluded() {
  sounds_app=$1
  [ -n "$sounds_app" ] || return 1
  sounds_app=$(sounds_app_key "$sounds_app")
  sounds_excluded=$(sounds_value notification_exclude_apps '["nplay", "spotify"]')
  [ "$sounds_excluded" = "[]" ] && return 1
  for sounds_item in $(printf '%s' "$sounds_excluded" | tr -d '[]"' | tr ',' ' '); do
    sounds_item=$(printf '%s' "$sounds_item" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$sounds_item" ] || continue
    [ "$sounds_app" = "$sounds_item" ] && return 0
  done
  return 1
}

# The configured choice for an app: empty when the app has no entry.
sounds_app_choice() {
  [ -n "$1" ] || return 0
  sounds_table_value sounds.apps "$(sounds_app_key "$1")"
}

# Resolve a sound name or path to a readable file. A name is looked up in the
# user's sound directory first, then in the NIRUX sounds.
sounds_file_for() {
  case "$1" in
    \~/*) sounds_candidate=$HOME/${1#\~/}; [ -r "$sounds_candidate" ] && say "$sounds_candidate" ;;
    /*) [ -r "$1" ] && say "$1" ;;
    *[!A-Za-z0-9_-]*|'') : ;;
    *)
      if [ -r "$NIRUX_CONFIG/sounds/$1.ogg" ]; then say "$NIRUX_CONFIG/sounds/$1.ogg"
      elif [ -r "$SOUNDS_STATE/$1.ogg" ]; then say "$SOUNDS_STATE/$1.ogg"
      fi ;;
  esac
  return 0
}

# The file for EVENT: the user's EVENT.ogg, then (for the volume ticks with a
# LEVEL) the NIRUX tick for the nearest 10 % step, then the NIRUX EVENT.ogg.
sounds_event_file() {
  if [ -r "$NIRUX_CONFIG/sounds/$1.ogg" ]; then say "$NIRUX_CONFIG/sounds/$1.ogg"; return 0; fi
  case "$1:${2:-}" in
    volume-up:[0-9]*|volume-down:[0-9]*)
      case "$2" in *[!0-9]*) : ;; *)
        sounds_lv=${2#"${2%%[!0]*}"}
        case "$sounds_lv" in '') sounds_lv=0 ;; ????*) sounds_lv=100 ;; esac
        sounds_step=$(( (sounds_lv + 5) / 10 * 10 ))
        [ "$sounds_step" -le 100 ] || sounds_step=100
        sounds_level_file=$SOUNDS_STATE/levels/$1-$(printf '%03d' "$sounds_step").ogg
        if [ -r "$sounds_level_file" ]; then say "$sounds_level_file"; return 0; fi ;;
      esac ;;
  esac
  [ -r "$SOUNDS_STATE/$1.ogg" ] && say "$SOUNDS_STATE/$1.ogg"
  return 0
}

# Print "NAME FILE" for a notification from APP, or nothing when the app is
# silenced. A missing app sound falls back to the normal notification sound.
sounds_notification_target() {
  sounds_default_file=$(sounds_event_file notification)
  [ -n "$sounds_default_file" ] || sounds_default_file=$SOUNDS_STATE/notification.ogg
  sounds_choice=$(sounds_app_choice "$1")
  case "$sounds_choice" in
    off|none|silent) return 0 ;;
    ''|default|notification) say "notification $sounds_default_file"; return 0 ;;
  esac
  sounds_target=$(sounds_file_for "$sounds_choice")
  if [ -n "$sounds_target" ]; then
    case "$sounds_choice" in
      */*) say "$(sounds_app_key "$1") $sounds_target" ;;
      *) say "$sounds_choice $sounds_target" ;;
    esac
  else
    say "notification $sounds_default_file"
  fi
}

# Play EVENT [APP [LEVEL]]. SOUNDS_FORCE=1 (nirux sounds test) also plays an
# event that is switched off; mute and the global switch still apply.
sounds_play() {
  sounds_event=$1
  sounds_app=${2:-}
  sounds_level=${3:-}
  sounds_name=$sounds_event
  sounds_category "$sounds_event" >/dev/null || return 0
  if [ "${SOUNDS_FORCE:-0}" = 1 ]; then
    sounds_enabled || return 0
  else
    sounds_event_enabled "$sounds_event" || return 0
  fi
  # NIRUNOTIFY decides Do Not Disturb before it asks for a notification sound;
  # a reminder played here is held back the same way. A timer you set sounds.
  if [ "$sounds_event" = reminder ] && [ "${SOUNDS_FORCE:-0}" != 1 ] && sounds_dnd_on; then
    return 0
  fi
  if [ "$sounds_event" = notification ]; then
    sounds_app_excluded "$sounds_app" && return 0
    sounds_pick=$(sounds_notification_target "$sounds_app")
    [ -n "$sounds_pick" ] || return 0
    sounds_name=${sounds_pick%% *}
    sounds_file=${sounds_pick#* }
  else
    sounds_file=$(sounds_event_file "$sounds_event" "$sounds_level")
  fi
  sounds_cooldown "$sounds_event" "$sounds_name" || return 0
  sounds_muted && return 0
  [ -n "$sounds_file" ] && [ -f "$sounds_file" ] || return 0
  sounds_vol=$(sounds_volume_for "$sounds_event")
  sounds_vol01=$(awk -v v="$sounds_vol" 'BEGIN {printf "%.2f", v/100}')
  if command -v pw-play >/dev/null 2>&1; then
    pw-play --volume="$sounds_vol01" "$sounds_file" >/dev/null 2>&1 &
  elif command -v paplay >/dev/null 2>&1; then
    paplay --volume="$((sounds_vol * 65536 / 100))" "$sounds_file" >/dev/null 2>&1 &
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet -volume "$sounds_vol" "$sounds_file" >/dev/null 2>&1 &
  elif command -v mpv >/dev/null 2>&1; then
    mpv --no-video --really-quiet --volume="$sounds_vol" "$sounds_file" >/dev/null 2>&1 &
  fi
  return 0
}

# Set KEY = VALUE inside TABLE, keeping every other line. A missing key is
# added at the end of its table; a missing table is appended.
sounds_table_set() {
  sounds_ensure_config
  sounds_tmp=$SOUNDS_CONFIG.tmp.$$
  if awk -v want="$1" -v k="$2" -v line="$3" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function flush() { if (sec == want && !done && line != "") { print line; done = 1 } }
    BEGIN { sec = "sounds"; lk = tolower(k) }
    /^[[:space:]]*\[/ {
      s = $0; sub(/^[[:space:]]*\[/, "", s); sub(/\][[:space:]]*(#.*)?$/, "", s)
      flush(); sec = trim(s); if (sec == want) seen = 1; print; next
    }
    sec == want && index($0, "=") > 0 {
      key = trim(substr($0, 1, index($0, "=") - 1)); gsub(/^"|"$/, "", key)
      if (tolower(key) == lk) { if (!done && line != "") print line; done = 1; next }
    }
    { print }
    END {
      flush()
      if (!done && line != "") { if (!seen && want != "sounds") print "\n[" want "]"; print line }
    }' "$SOUNDS_CONFIG" > "$sounds_tmp"; then
    mv -f "$sounds_tmp" "$SOUNDS_CONFIG"
  else
    rm -f "$sounds_tmp"; return 1
  fi
}

sounds_set() {
  sounds_table_set sounds "$1" "$1 = $2"
}

# Switch EVENT to VALUE where its key already lives: the category table, or
# [sounds] for the keys that were always there; a new key goes into the
# category table.
sounds_event_set() {
  sounds_set_cat=$(sounds_category "$1")
  if [ -z "$(sounds_table_value "sounds.$sounds_set_cat" "$1")" ] && [ -n "$(sounds_table_value sounds "$1")" ]; then
    sounds_table_set sounds "$1" "$1 = $2"
  else
    sounds_table_set "sounds.$sounds_set_cat" "$1" "$1 = $2"
  fi
}

sounds_app_list() {
  [ -f "$SOUNDS_CONFIG" ] || return 0
  awk '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    /^[[:space:]]*\[/ { s = $0; sub(/^[[:space:]]*\[/, "", s); sub(/\][[:space:]]*(#.*)?$/, "", s); sec = trim(s); next }
    sec == "sounds.apps" && index($0, "=") > 0 && $0 !~ /^[[:space:]]*#/ {
      key = trim(substr($0, 1, index($0, "=") - 1)); gsub(/^"|"$/, "", key); print key
    }' "$SOUNDS_CONFIG" 2>/dev/null || :
}

sounds_onoff() { if [ "$1" = true ]; then say on; else say off; fi; }

# Whether NIRUNOTIFY's Do Not Disturb is on right now; off when it cannot tell.
sounds_dnd_on() {
  command -v nirunotify >/dev/null 2>&1 || return 1
  if command -v timeout >/dev/null 2>&1; then
    sounds_dnd=$(timeout 1 nirunotify --dnd status 2>/dev/null) || return 1
  else
    sounds_dnd=$(nirunotify --dnd status 2>/dev/null) || return 1
  fi
  case "$sounds_dnd" in *' on'*|on) return 0 ;; esac
  return 1
}

sounds_status() {
  sounds_ensure_config
  sounds_enabled && sounds_global=on || sounds_global=off
  say "Sounds: $sounds_global · volume $(sounds_value volume 35)% · config $SOUNDS_CONFIG"
  for sounds_cat in $SOUNDS_CATEGORIES; do
    sounds_category_enabled "$sounds_cat" && sounds_cat_on=on || sounds_cat_on=off
    sounds_note=
    if [ "$sounds_cat" = notifications ]; then
      if sounds_dnd_on; then sounds_note=' · silent now: Do Not Disturb is on'
      else sounds_note=' · silent while Do Not Disturb is on'
      fi
    fi
    say "$sounds_cat: $sounds_cat_on$sounds_note"
    for sounds_event in $(sounds_category_events "$sounds_cat"); do
      say "  $sounds_event: $(sounds_onoff "$(sounds_event_setting "$sounds_event")")"
    done
  done
  say "notification sound excluded for: $(sounds_value notification_exclude_apps '["nplay", "spotify"]')"
  sounds_apps=$(sounds_app_list)
  [ -n "$sounds_apps" ] || return 0
  say "app sounds:"
  for sounds_entry in $sounds_apps; do
    sounds_choice=$(sounds_app_choice "$sounds_entry")
    case "$sounds_choice" in
      off|none|silent) sounds_note='silent' ;;
      ''|default|notification) sounds_note='notification sound' ;;
      *)
        sounds_target=$(sounds_file_for "$sounds_choice")
        if [ -n "$sounds_target" ]; then sounds_note=$sounds_target
        else sounds_note='missing; plays the notification sound'; fi ;;
    esac
    say "  $sounds_entry = $sounds_choice ($sounds_note)"
  done
}

# Every event with its category, whether it plays, and the file it plays.
sounds_list() {
  sounds_ensure_config
  printf '%-14s %-18s %-4s %s\n' CATEGORY EVENT ON FILE
  for sounds_cat in $SOUNDS_CATEGORIES; do
    for sounds_event in $(sounds_category_events "$sounds_cat"); do
      sounds_event_enabled "$sounds_event" && sounds_on=on || sounds_on=off
      sounds_file=$(sounds_event_file "$sounds_event")
      case "$sounds_file" in
        '') sounds_file='(missing)' ;;
        "$NIRUX_CONFIG"/*) sounds_file="$sounds_file (yours)" ;;
      esac
      printf '%-14s %-18s %-4s %s\n' "$sounds_cat" "$sounds_event" "$sounds_on" "$sounds_file"
    done
  done
}

sounds_json_string() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037')"
}

# Machine-readable status for NIRULAUNCHER and scripts. Schema 1; the
# categories object and the events beyond the first four are additions.
sounds_status_json() {
  sounds_ensure_config
  sounds_enabled && sounds_global=true || sounds_global=false
  sounds_vol=$(sounds_value volume 35)
  case "$sounds_vol" in ''|*[!0-9]*) sounds_vol=35 ;; esac
  printf '{"schema":1,"enabled":%s,"volume":%s,"config":%s,"events":{' \
    "$sounds_global" "$sounds_vol" "$(sounds_json_string "$SOUNDS_CONFIG")"
  sounds_sep=
  for sounds_event in $(sounds_all_events); do
    [ "$(sounds_event_setting "$sounds_event")" = true ] && sounds_on=true || sounds_on=false
    printf '%s"%s":%s' "$sounds_sep" "$sounds_event" "$sounds_on"; sounds_sep=,
  done
  printf '},"categories":{'
  sounds_sep=
  for sounds_cat in $SOUNDS_CATEGORIES; do
    sounds_category_enabled "$sounds_cat" && sounds_on=true || sounds_on=false
    printf '%s"%s":{"enabled":%s,"events":[' "$sounds_sep" "$sounds_cat" "$sounds_on"; sounds_sep=,
    sounds_sep2=
    for sounds_event in $(sounds_category_events "$sounds_cat"); do
      printf '%s"%s"' "$sounds_sep2" "$sounds_event"; sounds_sep2=,
    done
    printf ']}'
  done
  printf '},"exclude":['
  sounds_sep=
  for sounds_item in $(sounds_value notification_exclude_apps '["nplay", "spotify"]' | tr -d '[]"' | tr ',' ' '); do
    printf '%s%s' "$sounds_sep" "$(sounds_json_string "$sounds_item")"; sounds_sep=,
  done
  printf '],"apps":['
  sounds_sep=
  for sounds_entry in $(sounds_app_list); do
    sounds_choice=$(sounds_app_choice "$sounds_entry")
    sounds_target=
    case "$sounds_choice" in
      off|none|silent) sounds_state=silent ;;
      ''|default|notification) sounds_state=default ;;
      *)
        sounds_target=$(sounds_file_for "$sounds_choice")
        if [ -n "$sounds_target" ]; then sounds_state=ok; else sounds_state=missing; fi ;;
    esac
    printf '%s{"app":%s,"sound":%s,"state":"%s","file":%s}' "$sounds_sep" \
      "$(sounds_json_string "$sounds_entry")" "$(sounds_json_string "$sounds_choice")" \
      "$sounds_state" "$(sounds_json_string "$sounds_target")"
    sounds_sep=,
  done
  printf ']}\n'
}

sounds_app_command() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || die 'usage: nirux sounds app APP [SOUND|PATH|default|off|remove]'
  sounds_entry=$(sounds_app_key "$1")
  case "$sounds_entry" in ''|*[!a-z0-9._-]*) die 'app name may contain letters, digits, ".", "_" and "-"' ;; esac
  if [ "$#" = 1 ]; then
    sounds_choice=$(sounds_app_choice "$sounds_entry")
    say "$sounds_entry = ${sounds_choice:-default}"
    return 0
  fi
  case "$2" in
    remove) sounds_table_set sounds.apps "$sounds_entry" ''; say "$sounds_entry: removed"; return 0 ;;
    off|none|silent|default|notification) sounds_value_new=$2 ;;
    \~/*|/*)
      case "$2" in *'"'*|*'\'*) die 'sound path must not contain quotes or backslashes' ;; esac
      sounds_value_new=$2 ;;
    *[!A-Za-z0-9_-]*|'') die 'sound must be a name (letters, digits, "_", "-"), a path, default, off or remove' ;;
    *) sounds_value_new=$2 ;;
  esac
  sounds_table_set sounds.apps "$sounds_entry" "$sounds_entry = \"$sounds_value_new\""
  say "$sounds_entry = $sounds_value_new"
  case "$sounds_value_new" in
    off|none|silent|default|notification) : ;;
    *) [ -n "$(sounds_file_for "$sounds_value_new")" ] || say "note: no sound file found yet for $sounds_value_new; the notification sound plays until it exists" ;;
  esac
}

sounds_is_category() {
  case " $SOUNDS_CATEGORIES " in *" $1 "*) return 0 ;; esac
  return 1
}

SOUNDS_USAGE='usage: nirux sounds [status [--json]|list|on|off|toggle EVENT|CATEGORY|app APP [SOUND]|test EVENT [--app NAME] [--level N]|play EVENT [--app NAME] [--level N]]'

sounds_command() {
  sounds_action=${1:-status}
  case "$sounds_action" in
    status)
      case "${2:-}" in
        '') sounds_status ;;
        --json) sounds_status_json ;;
        *) die 'usage: nirux sounds status [--json]' ;;
      esac ;;
    list) [ "$#" = 1 ] || die 'usage: nirux sounds list'; sounds_list ;;
    on) sounds_set enabled true; say 'Sounds enabled' ;;
    off) sounds_set enabled false; say 'Sounds disabled' ;;
    toggle)
      [ "$#" = 2 ] || die "usage: nirux sounds toggle EVENT|CATEGORY (events: $(sounds_all_events)categories: $SOUNDS_CATEGORIES)"
      sounds_ensure_config
      if sounds_is_category "$2"; then
        sounds_category_enabled "$2" && sounds_next=false || sounds_next=true
        sounds_table_set "sounds.$2" enabled "enabled = $sounds_next"
        say "$2: $(sounds_onoff "$sounds_next")"
      elif sounds_category "$2" >/dev/null; then
        [ "$(sounds_event_setting "$2")" = true ] && sounds_next=false || sounds_next=true
        sounds_event_set "$2" "$sounds_next"
        say "$2: $(sounds_onoff "$sounds_next")"
      else
        die "unknown sound event or category: $2"
      fi ;;
    app) shift; sounds_app_command "$@" ;;
    test|play)
      shift
      [ "$#" -ge 1 ] || die "usage: nirux sounds $sounds_action EVENT [--app NAME] [--level N]"
      sounds_event=$1
      shift
      sounds_category "$sounds_event" >/dev/null || die "unknown sound event: $sounds_event (see nirux sounds list)"
      sounds_app=
      sounds_level=
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --app) [ "$#" -ge 2 ] || die '--app needs a name'; sounds_app=$2; shift 2 ;;
          --level)
            [ "$#" -ge 2 ] || die '--level needs a percentage'
            case "$2" in ''|*[!0-9]*) die '--level needs a percentage' ;; esac
            sounds_level=$2; shift 2 ;;
          *) die "unknown sound option: $1" ;;
        esac
      done
      if [ "$sounds_action" = test ]; then
        sounds_cooldown() { return 0; }
        SOUNDS_FORCE=1
        sounds_event_enabled "$sounds_event" || say "note: $sounds_event is off; it plays here as a test only"
      fi
      sounds_play "$sounds_event" "$sounds_app" "$sounds_level" ;;
    *) die "$SOUNDS_USAGE" ;;
  esac
}

install_sounds() {
  sounds_archive=$WORK/download/nirux/nirux-sounds.tar.xz
  [ -f "$sounds_archive" ] || return 0
  sounds_unpack=$WORK/sounds-unpack
  rm -rf "$sounds_unpack"
  mkdir -p "$sounds_unpack" || die 'could not create sounds extraction directory'
  tar -xJf "$sounds_archive" -C "$sounds_unpack" || die 'could not extract sounds archive'
  [ -f "$sounds_unpack/sounds/startup.ogg" ] || die 'sounds archive is incomplete'
  mkdir -p "$SOUNDS_STATE"
  cp -f "$sounds_unpack"/sounds/*.ogg "$SOUNDS_STATE"/ || die 'could not install sounds'
  chmod 644 "$SOUNDS_STATE"/*.ogg
  # The volume ticks for each 10 % step, picked by nirunotify.
  if [ -d "$sounds_unpack/sounds/levels" ]; then
    mkdir -p "$SOUNDS_STATE/levels"
    cp -f "$sounds_unpack"/sounds/levels/*.ogg "$SOUNDS_STATE/levels"/ || die 'could not install sounds'
    chmod 644 "$SOUNDS_STATE"/levels/*.ogg
  fi
  sounds_ensure_config
  rm -rf "$sounds_unpack"
}

install_terminal() {
  terminal_archive=$WORK/download/nirux/nirux-terminal.tar.xz
  [ -f "$terminal_archive" ] || return 0
  [ -n "${HOME:-}" ] || return 0
  terminal_unpack=$WORK/terminal-unpack
  rm -rf "$terminal_unpack"
  mkdir -p "$terminal_unpack" || die 'could not create the terminal extraction directory'
  tar -xJf "$terminal_archive" -C "$terminal_unpack" || die 'could not extract the terminal archive'
  [ -f "$terminal_unpack/terminal/kitty.conf" ] || die 'terminal archive is incomplete'
  mkdir -p "$STATE"
  rm -rf "$STATE/terminal"
  cp -R "$terminal_unpack/terminal" "$STATE/terminal" || die 'could not install terminal templates'
  chmod 755 "$STATE/terminal/nirux-theme-hook"
  mkdir -p "$BIN"
  ln -s "$STATE/terminal/nirux-theme-hook" "$BIN/.nirux-theme-hook.$$" || die 'could not link the theme hook'
  mv -Tf "$BIN/.nirux-theme-hook.$$" "$BIN/nirux-theme-hook" || die 'could not activate the theme hook'

  terminal_config=$(terminal_config_home)
  mkdir -p "$terminal_config/fish" "$terminal_config/theme" || die 'could not create NIRUX config directories'
  install -m 644 "$STATE/terminal/fish/nirux.fish" "$terminal_config/fish/nirux.fish" || \
    die 'could not install the fish integration'
  fish_config=${XDG_CONFIG_HOME:-$HOME/.config}/fish
  mkdir -p "$fish_config/completions" || die 'could not create the fish completions directory'
  for completion in nirux niructl; do
    {
      printf '# NIRUX owner: %s\n' "$PREFIX"
      cat "$STATE/terminal/fish/completions/$completion.fish"
    } > "$WORK/$completion.fish"
    write_prefix_file "$fish_config/completions/$completion.fish" "$WORK/$completion.fish"
  done

  kitty_config=${XDG_CONFIG_HOME:-$HOME/.config}/kitty
  mkdir -p "$kitty_config" || die 'could not create the kitty config directory'
  kitty_file=$kitty_config/kitty.conf
  if { [ ! -e "$kitty_file" ] && [ ! -L "$kitty_file" ]; } || \
     { [ -f "$kitty_file" ] && owned "$kitty_file"; }; then
    sed "s|@NIRUX_CONFIG_HOME@|${XDG_CONFIG_HOME:-$HOME/.config}|g" \
      "$STATE/terminal/kitty.conf" > "$WORK/kitty.conf"
    {
      printf '# NIRUX owner: %s\n' "$PREFIX"
      cat "$WORK/kitty.conf"
    } > "$WORK/kitty-owned.conf"
    install -m 644 "$WORK/kitty-owned.conf" "$kitty_file" || die 'could not install kitty.conf'
  else
    {
      printf '# NIRUX terminal integration (managed)\n'
      printf 'shell fish\n'
      printf 'include %s/nirux/theme/kitty.conf\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
      printf '# End NIRUX terminal integration\n'
    } > "$WORK/kitty-block"
    append_managed_block "$kitty_file" "$WORK/kitty-block"
  fi

  {
    printf '# NIRUX terminal integration (managed)\n'
    printf 'if test -r $__fish_config_dir/../nirux/fish/nirux.fish\n'
    printf '    source $__fish_config_dir/../nirux/fish/nirux.fish\n'
    printf 'end\n'
    printf '# End NIRUX terminal integration\n'
  } > "$WORK/fish-block"
  append_managed_block "$fish_config/config.fish" "$WORK/fish-block"

  "$BIN/nirux-theme-hook" || die 'could not generate the terminal theme'
  rm -rf "$terminal_unpack"
  say "Installed NIRUX kitty/fish integration (theme: $(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFDIR/config.toml" | head -n 1))"
}
remove_terminal() {
  [ -n "${HOME:-}" ] || return 0
  terminal_config=$(terminal_config_home)
  kitty_file=${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf
  remove_managed_block "$kitty_file"
  if [ -f "$kitty_file" ] && owned "$kitty_file"; then rm -f "$kitty_file"; fi
  fish_file=${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish
  remove_managed_block "$fish_file"
  if [ -f "$fish_file" ] && owned "$fish_file"; then rm -f "$fish_file"; fi
  remove_prefix_file "${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions/nirux.fish"
  remove_prefix_file "${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions/niructl.fish"
  rm -rf "$terminal_config"
  if [ -L "$BIN/nirux-theme-hook" ]; then
    case "$(readlink "$BIN/nirux-theme-hook")" in
      "$STATE/terminal/nirux-theme-hook") rm -f "$BIN/nirux-theme-hook" ;;
    esac
  fi
  rm -rf "$STATE/terminal"
}
