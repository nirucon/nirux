config_picture_paths() {
  pictures=$(pictures_directory)
  # shellcheck disable=SC2088 # literal default written into TOML
  case "$pictures" in
    "$HOME/Pictures") base='~/Pictures' ;;
    *) base=$pictures ;;
  esac
  printf '%s\n%s\n' "$base/Wallpapers" "$base/Wallpapers/NIRU"
}

fresh_config_source() {
  wallpaper_dir=$(config_picture_paths | sed -n '1p')
  theme_dir=$(config_picture_paths | sed -n '2p')
  if [ "${BROWSER_EFFECTIVE:-keep}" = none ]; then
    awk -v dir="$wallpaper_dir" -v theme="$theme_dir" '
      $0 == "browser = [\"helium\"]" {print "browser = []"; next}
      $0 ~ /^dir = / {print "dir = \"" dir "\""; next}
      $0 ~ /^theme_dir = / {print "theme_dir = \"" theme "\""; next}
      {print}
    ' "$1"
  else
    awk -v dir="$wallpaper_dir" -v theme="$theme_dir" '
      $0 ~ /^dir = / {print "dir = \"" dir "\""; next}
      $0 ~ /^theme_dir = / {print "theme_dir = \"" theme "\""; next}
      {print}
    ' "$1"
  fi
}

# 0.12.264: the night light follows the sun at 2700 K by default. A file that
# still has the old defaults (manual, 3400 K) gets the new ones once; after
# that, mode = "manual" is respected as a choice.
upgrade_nightlight_schedule() {
  file=$1
  nl_marker=$STATE/nightlight-solar-0.12.264
  [ -e "$nl_marker" ] && return 0
  mkdir -p "$STATE"
  if awk '
    /^[[:space:]]*\[nightlight\][[:space:]]*$/ { inside = 1; next }
    /^[[:space:]]*\[/ { inside = 0 }
    inside && /^mode = "manual"[[:space:]]*$/ { mode = 1 }
    inside && /^temperature = 3400[[:space:]]*$/ { temp = 1 }
    END { exit !(mode && temp) }
  ' "$file"; then
    mig_mode=$(stat -c %a "$file") || die "could not read permissions for $file"
    mig_tmp=$(mktemp "$file.nirux-nightlight.XXXXXX") || die "could not stage $file"
    awk '
      /^[[:space:]]*\[nightlight\][[:space:]]*$/ { inside = 1; print; next }
      /^[[:space:]]*\[/ { inside = 0 }
      inside && /^mode = "manual"[[:space:]]*$/ { print "mode = \"solar\""; next }
      inside && /^temperature = 3400[[:space:]]*$/ { print "temperature = 2700"; next }
      { print }
    ' "$file" > "$mig_tmp" && chmod "$mig_mode" "$mig_tmp" && mv -f "$mig_tmp" "$file" || {
      rm -f "$mig_tmp"
      die "could not update the night light in $file; original kept"
    }
    say 'Night light now follows the sun at 2700 K (Super+N switches it by hand; mode = "manual" turns the schedule off).'
  fi
  : > "$nl_marker"
}

# 0.12.272: the gradual night light (NIRUWM 0.30) is the default. A file whose
# [nightlight] still has the previous defaults (solar, 2700 K, on 20:00, off
# 07:00, day 6500 K; any location) is moved to gradual once, with its keys
# written; the file as it was is kept in NIRUWM's config history first, so
# `niructl config undo` goes back. Any other choice is left alone, and after
# the first run a change back to solar is never undone (marker file).
upgrade_nightlight_gradual() {
  file=$1 ng_original=${2:-$1}
  ng_marker=$STATE/nightlight-gradual-0.12.272
  [ -e "$ng_marker" ] && return 0
  mkdir -p "$STATE"
  if awk '
    function val(line) { sub(/^[^=]*=[[:space:]]*/, "", line); sub(/[[:space:]]*#.*$/, "", line); sub(/[[:space:]]+$/, "", line); return line }
    /^[[:space:]]*\[nightlight\][[:space:]]*(#.*)?$/ { inside = 1; seen = 1; next }
    /^[[:space:]]*\[/ { inside = 0 }
    inside && /^[[:space:]]*mode[[:space:]]*=/ { mode = val($0) }
    inside && /^[[:space:]]*temperature[[:space:]]*=/ { temp = val($0) }
    inside && /^[[:space:]]*on[[:space:]]*=/ { on = val($0) }
    inside && /^[[:space:]]*off[[:space:]]*=/ { off = val($0) }
    inside && /^[[:space:]]*day_temperature[[:space:]]*=/ { day = val($0) }
    END {
      # A missing key is the previous default.
      ok = seen && (mode == "\"solar\"" || mode == "") && (temp == "2700" || temp == "") &&
        (on == "\"20:00\"" || on == "") && (off == "\"07:00\"" || off == "") &&
        (day == "6500" || day == "")
      exit !ok
    }
  ' "$file"; then
    config_history_keep "$ng_original" || say 'nirux: warning: could not keep the old configuration in the history' >&2
    ng_mode=$(stat -c %a "$file") || die "could not read permissions for $file"
    ng_tmp=$(mktemp "$file.nirux-nightlight.XXXXXX") || die "could not stage $file"
    awk '
      /^[[:space:]]*\[nightlight\][[:space:]]*(#.*)?$/ { inside = 1; print; next }
      /^[[:space:]]*\[/ { inside = 0 }
      inside && /^[[:space:]]*mode[[:space:]]*=/ { print "mode = \"gradual\""; next }
      { print }
    ' "$file" > "$ng_tmp" && chmod "$ng_mode" "$ng_tmp" && mv -f "$ng_tmp" "$file" || {
      rm -f "$ng_tmp"
      die "could not update the night light in $file; original kept"
    }
    add_missing_key "$file" nightlight mode '"gradual"'
    add_missing_key "$file" nightlight start_temperature 4500
    add_missing_key "$file" nightlight not_before '"19:00"'
    add_missing_key "$file" nightlight deepest_at '"22:00"'
    say 'Night light is now gradual: from sunset (not before 19:00) it glides from 4500 K to 2700 K by 22:00 (niructl config undo goes back; mode = "solar" keeps the old schedule).'
  fi
  : > "$ng_marker"
}

# 0.12.289: the gradual night light is softer by default (NIRUWM 0.32): it
# glides from 5500 K to 3500 K instead of 4500 K to 2700 K. A gradual
# [nightlight] that still has the previous temperatures gets the new ones once,
# with the file as it was kept in the config history (`niructl config undo`).
# Any other temperature is a choice and is kept; the marker makes it once only.
upgrade_nightlight_softer() {
  file=$1 ns_original=${2:-$1}
  ns_marker=$STATE/nightlight-soft-0.12.289
  [ -e "$ns_marker" ] && return 0
  mkdir -p "$STATE"
  if awk '
    function val(line) { sub(/^[^=]*=[[:space:]]*/, "", line); sub(/[[:space:]]*#.*$/, "", line); sub(/[[:space:]]+$/, "", line); return line }
    /^[[:space:]]*\[nightlight\][[:space:]]*(#.*)?$/ { inside = 1; seen = 1; next }
    /^[[:space:]]*\[/ { inside = 0 }
    inside && /^[[:space:]]*mode[[:space:]]*=/ { mode = val($0) }
    inside && /^[[:space:]]*temperature[[:space:]]*=/ { temp = val($0) }
    inside && /^[[:space:]]*start_temperature[[:space:]]*=/ { start = val($0) }
    END {
      # A missing key is the previous default; 5500 is what an install that
      # lacked the key was just given.
      ok = seen && (mode == "\"gradual\"" || mode == "") && (temp == "2700" || temp == "") &&
        (start == "4500" || start == "5500" || start == "")
      exit !ok
    }
  ' "$file"; then
    config_history_keep "$ns_original" || say 'nirux: warning: could not keep the old configuration in the history' >&2
    ns_mode=$(stat -c %a "$file") || die "could not read permissions for $file"
    ns_tmp=$(mktemp "$file.nirux-nightlight.XXXXXX") || die "could not stage $file"
    awk '
      /^[[:space:]]*\[nightlight\][[:space:]]*(#.*)?$/ { inside = 1; print; next }
      /^[[:space:]]*\[/ { inside = 0 }
      inside && /^[[:space:]]*temperature[[:space:]]*=/ { print "temperature = 3500"; next }
      inside && /^[[:space:]]*start_temperature[[:space:]]*=/ { print "start_temperature = 5500"; next }
      { print }
    ' "$file" > "$ns_tmp" && chmod "$ns_mode" "$ns_tmp" && mv -f "$ns_tmp" "$file" || {
      rm -f "$ns_tmp"
      die "could not update the night light in $file; original kept"
    }
    add_missing_key "$file" nightlight temperature 3500
    add_missing_key "$file" nightlight start_temperature 5500
    say 'Night light is softer: it now glides from 5500 K to 3500 K (niructl config undo goes back; set temperature lower for a warmer night).'
  fi
  : > "$ns_marker"
}

# 0.12.266: the privacy dot (microphone, camera, screen recording in use) is
# added to an existing bar once, next to the recording module; removing it
# afterwards is respected.
upgrade_bar_privacy_module() {
  file=$1
  pv_marker=$STATE/bar-privacy-0.12.266
  [ -e "$pv_marker" ] && return 0
  mkdir -p "$STATE"
  pv_modules=$(awk '
    /^\[bar\]/ { inside = 1; next }
    inside && /^\[/ { inside = 0 }
    inside && /^modules *= *\[/ {
      line = $0
      while (line !~ /\]/ && (getline more) > 0) line = line " " more
      print line
      exit
    }
  ' "$file")
  if [ -n "$pv_modules" ] && ! printf '%s' "$pv_modules" | grep -q '"privacy"'; then
    if printf '%s' "$pv_modules" | grep -q '"recording"'; then
      pv_new=$(printf '%s' "$pv_modules" | sed 's/"recording"/"privacy", "recording"/')
    elif printf '%s' "$pv_modules" | grep -q '"volume"'; then
      pv_new=$(printf '%s' "$pv_modules" | sed 's/"volume"/"privacy", "volume"/')
    elif printf '%s' "$pv_modules" | grep -q '"clock"'; then
      pv_new=$(printf '%s' "$pv_modules" | sed 's/"clock"/"privacy", "clock"/')
    else
      pv_new=$(printf '%s' "$pv_modules" | sed 's/\]\([^]]*\)$/, "privacy"]\1/')
    fi
    pv_mode=$(stat -c %a "$file") || die "could not read permissions for $file"
    pv_tmp=$(mktemp "$file.nirux-privacy.XXXXXX") || die "could not stage $file"
    awk -v new="$pv_new" '
      /^\[bar\]/ { inside = 1; print; next }
      inside && /^\[/ { inside = 0 }
      inside && /^modules *= *\[/ {
        print new
        while ($0 !~ /\]/ && (getline more) > 0) { $0 = more }
        next
      }
      { print }
    ' "$file" > "$pv_tmp" && chmod "$pv_mode" "$pv_tmp" && mv -f "$pv_tmp" "$file" || {
      rm -f "$pv_tmp"
      die "could not add the privacy module to $file; original kept"
    }
    say 'Added the bar privacy dot (shows when the microphone, a camera or screen recording is in use).'
  fi
  : > "$pv_marker"
}

# 0.12.264: the battery charge limit is visible in the file, so it can be changed.
add_battery_section() {
  file=$1
  grep -q '^[[:space:]]*\[battery\][[:space:]]*$' "$file" && return 0
  printf '\n[battery]\n# Stop charging at this percentage; 100 means no limit. See: niructl battery status\ncharge_limit = 80\n' >> "$file"
}

upgrade_default_wallpaper_paths() {
  file=$1
  wallpaper_dir=$(config_picture_paths | sed -n '1p')
  theme_dir=$(config_picture_paths | sed -n '2p')
  # shellcheck disable=SC2088 # literal default in TOML
  [ "$wallpaper_dir" != '~/Pictures/Wallpapers' ] || return 0
  grep -qx 'dir = "~/Pictures/Wallpapers"' "$file" || return 0
  grep -qx 'theme_dir = "~/Pictures/Wallpapers/NIRU"' "$file" || return 0
  mig_mode=$(stat -c %a "$file") || die "could not read permissions for $file"
  mig_tmp=$(mktemp "$file.nirux-wallpaper.XXXXXX") || die "could not stage $file"
  awk -v dir="$wallpaper_dir" -v theme="$theme_dir" '
    $0 == "dir = \"~/Pictures/Wallpapers\"" {print "dir = \"" dir "\""; next}
    $0 == "theme_dir = \"~/Pictures/Wallpapers/NIRU\"" {print "theme_dir = \"" theme "\""; next}
    {print}
  ' "$file" > "$mig_tmp" && chmod "$mig_mode" "$mig_tmp" && mv -f "$mig_tmp" "$file" || {
    rm -f "$mig_tmp"
    die "could not update wallpaper paths in $file; original kept"
  }
  say "Updated default wallpaper paths for the XDG Pictures directory."
}
install_picom_config() {
  picom_conf=${XDG_CONFIG_HOME:-$HOME/.config}/picom.conf
  [ -e "$picom_conf" ] && { say "Keeping existing $picom_conf"; return 0; }
  command -v picom >/dev/null 2>&1 || return 0
  mkdir -p "$(dirname "$picom_conf")"
  cat > "$picom_conf" <<'EOF'
# NIRUX default compositor. Edit or remove this file freely.
backend = "glx";
vsync = true;
inactive-opacity = 0.94;
active-opacity = 1.0;
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.35;
EOF
  say "Created $picom_conf"
}

# NIRUX 0.12.278: the compositor draws on the graphics card. xrender drew
# every frame on the processor, inside Xorg: with empty workspaces (only the
# wallpaper) the screen stopped keeping up, so workspace changes looked
# ignored and the launcher stuttered. A picom.conf that NIRUX wrote, still on
# xrender and without a vsync line, moves to glx once; a copy is kept, and a
# later change back to xrender is never undone. NIRUWM 0.31.4 falls back to
# xrender by itself where glx cannot start.
migrate_picom_backend() {
  mpb_conf=${XDG_CONFIG_HOME:-$HOME/.config}/picom.conf
  mpb_marker=$STATE/picom-glx-0.12.278
  [ -f "$mpb_conf" ] && [ ! -L "$mpb_conf" ] || return 0
  [ ! -e "$mpb_marker" ] || return 0
  mkdir -p "$STATE" 2>/dev/null || return 0
  if ! grep -qx '# NIRUX default compositor. Edit or remove this file freely.' "$mpb_conf" ||
     ! grep -qx 'backend = "xrender";' "$mpb_conf" ||
     grep -q '^[[:space:]]*vsync' "$mpb_conf"; then
    : > "$mpb_marker"
    return 0
  fi
  cp -p "$mpb_conf" "$mpb_conf.bak-xrender-0.12.278" || return 0
  mpb_tmp=$(mktemp "$mpb_conf.nirux.XXXXXX") || return 0
  awk '$0 == "backend = \"xrender\";" { print "backend = \"glx\";"; print "vsync = true;"; next } { print }' "$mpb_conf" > "$mpb_tmp" &&
    chmod "$(stat -c %a "$mpb_conf")" "$mpb_tmp" && mv -f "$mpb_tmp" "$mpb_conf" || { rm -f "$mpb_tmp"; return 0; }
  : > "$mpb_marker"
  say "Compositor moved to the graphics card (glx); the previous picom.conf is $mpb_conf.bak-xrender-0.12.278. It applies at the next login."
}

install_config() {
  install_picom_config
  migrate_picom_backend
  cfg_example="$WORK/download/nirux/config.example.toml"
  [ -f "$cfg_example" ] || { say 'config example missing; user configuration unchanged'; return 0; }
  mkdir -p "$STATE"
  install -m 644 "$cfg_example" "$STATE/config.example.toml"
  mkdir -p "$CONFDIR"
  install_appearance || :
  cfg_file="$CONFDIR/config.toml"
  if [ ! -e "$cfg_file" ] && [ ! -L "$cfg_file" ]; then
    cfg_stage="$WORK/config.fresh"
    fresh_config_source "$cfg_example" > "$cfg_stage"
    install -m 644 "$cfg_stage" "$cfg_file"
    # A new file already has the gradual night light; a later change to
    # solar is a choice the 0.12.272 migration must not undo.
    : > "$STATE/nightlight-gradual-0.12.272"
    say "Created $cfg_file"
    install_appearance || :
    return 0
  fi
  say "Keeping existing $cfg_file"
  if [ -L "$cfg_file" ]; then
    cfg_target=$(readlink -f "$cfg_file" 2>/dev/null || :)
    if [ -z "$cfg_target" ] || [ ! -f "$cfg_target" ]; then
      die "$cfg_file is a symlink that does not resolve to a regular file; configuration migration stopped"
    fi
  else
    [ -f "$cfg_file" ] || die "$cfg_file is not a regular file; configuration migration stopped"
    cfg_target=$cfg_file
  fi
  cfg_mode=$(stat -c %a "$cfg_target") || die "could not read permissions for $cfg_target"
  cfg_candidate=$(mktemp "$(dirname "$cfg_target")/.$(basename "$cfg_target").nirux.XXXXXX") || \
    die "could not stage configuration next to $cfg_target"
  CONFIG_CANDIDATE=$cfg_candidate
  if ! cp -p "$cfg_target" "$cfg_candidate" || ! chmod u+w "$cfg_candidate"; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    die "could not stage configuration for $cfg_file"
  fi
  if config_errors "$cfg_candidate"; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    die "configuration migration stopped: unsupported or invalid TOML (original kept)"
  fi
  cfg_before=$(sha256sum "$cfg_candidate" | cut -d ' ' -f1)
  add_missing_sections "$cfg_candidate" "$cfg_example"
  add_missing_top_key "$cfg_candidate" restore_session false
  add_missing_top_key "$cfg_candidate" smart_gaps true
  add_missing_top_key "$cfg_candidate" weather_latitude 59.33
  add_missing_top_key "$cfg_candidate" weather_longitude 18.07
  add_missing_key "$cfg_candidate" nightlight mode '"gradual"'
  add_missing_key "$cfg_candidate" nightlight on '"20:00"'
  add_missing_key "$cfg_candidate" nightlight off '"07:00"'
  add_missing_key "$cfg_candidate" nightlight day_temperature 6500
  add_missing_key "$cfg_candidate" nightlight start_temperature 5500
  add_missing_key "$cfg_candidate" nightlight not_before '"19:00"'
  add_missing_key "$cfg_candidate" nightlight deepest_at '"22:00"'
  add_missing_key "$cfg_candidate" pip size 25
  add_missing_key "$cfg_candidate" pip corner '"bottom-right"'
  add_missing_key "$cfg_candidate" pip auto true
  add_missing_key "$cfg_candidate" brightness device '""'
  add_missing_key "$cfg_candidate" brightness step 5
  add_missing_key "$cfg_candidate" bar title_delay_seconds 0
  add_missing_key "$cfg_candidate" bar graph_width 24
  add_missing_key "$cfg_candidate" bar tray true
  upgrade_default_bar_modules "$cfg_candidate"
  add_missing_key "$cfg_candidate" wallpaper scale "\"fill\""
  add_missing_key "$cfg_candidate" wallpaper files "[]"
  add_missing_key "$cfg_candidate" wallpaper shuffle_on_start true
  add_missing_key "$cfg_candidate" wallpaper follow_theme true
  theme_dir=$(config_picture_paths | sed -n '2p')
  add_missing_key "$cfg_candidate" wallpaper theme_dir "\"$theme_dir\""
  add_missing_key "$cfg_candidate" monitors workspaces 10
  upgrade_default_workspaces "$cfg_candidate"
  upgrade_default_wallpaper_paths "$cfg_candidate"
  upgrade_nightlight_schedule "$cfg_candidate"
  upgrade_nightlight_gradual "$cfg_candidate" "$cfg_target"
  upgrade_nightlight_softer "$cfg_candidate" "$cfg_target"
  add_battery_section "$cfg_candidate"
  upgrade_bar_privacy_module "$cfg_candidate"
  add_localsend_rule "$cfg_candidate"
  upgrade_obsolete_default_browser "$cfg_candidate"
  upgrade_file_manager_binding "$cfg_candidate"
  upgrade_terminal_binding "$cfg_candidate"
  upgrade_terminal_commands "$cfg_candidate"
  add_missing_key "$cfg_candidate" bar follow_default_modules true
  follow_default_bar_modules "$cfg_candidate" "$cfg_example" "$cfg_target"
  cfg_after=$(sha256sum "$cfg_candidate" | cut -d ' ' -f1)
  if [ "$cfg_before" = "$cfg_after" ]; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    say 'No missing configuration settings; existing values unchanged.'
    return 0
  fi
  if config_errors "$cfg_candidate"; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    die "configuration migration stopped: candidate is not valid TOML (original kept)"
  fi
  if ! validate_config_candidate "$cfg_candidate"; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    die "configuration candidate was rejected; original kept"
  fi
  if ! chmod "$cfg_mode" "$cfg_candidate" || ! mv -f "$cfg_candidate" "$cfg_target"; then
    rm -f "$cfg_candidate"; CONFIG_CANDIDATE=
    die "could not activate $cfg_file; original kept"
  fi
  CONFIG_CANDIDATE=
  say "Migrated $cfg_file with missing defaults; existing values kept."
  return 0
}

