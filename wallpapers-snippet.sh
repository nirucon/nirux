
# ── Optional theme wallpaper set ────────────────────────────────────────────
# NIRUX ships only the default theme's wallpaper with its release. The other
# nine themes are a 326 MB set served by the project's own Nextcloud, so a
# routine GitHub release stays small and every update does not re-download it.
# A theme without its image paints its own background colour, so nothing looks
# broken while the set is absent.
WALLPAPER_BUNDLE_URL=https://nextcloud.nirucon.se/s/2b9MX7GZKpLsyGx/download
WALLPAPER_BUNDLE_SHA256=4dd71b0510b7aca125feb6b6fa111fea6b0d1f7f80c8b7ff54b8e4ef4d2fd0a9
WALLPAPER_BUNDLE_BYTES=326176620
WALLPAPER_THEMES='noir nord satie carl-larsson forest-vigil blood-of-urdr root-and-stone blue-horizon the-norns winter-nights'

wallpaper_destination() {
  printf '%s\n' "$(pictures_directory)/Wallpapers/NIRU"
}

# How many of the ten themes have a 4k wallpaper installed.
wallpaper_theme_count() {
  wp_count=0
  wp_dir=$(wallpaper_destination)
  for wp_theme in $WALLPAPER_THEMES; do
    [ -f "$wp_dir/nirux-wallpaper-$wp_theme-4k.png" ] && wp_count=$((wp_count + 1))
  done
  printf '%s\n' "$wp_count"
}

wallpapers_status() {
  wp_dir=$(wallpaper_destination)
  wp_have=$(wallpaper_theme_count)
  say "Theme wallpapers: $wp_have of 10 installed in $wp_dir"
  if [ "$wp_have" -eq 10 ]; then
    say 'Every theme has its wallpaper; nothing to download.'
    return 0
  fi
  say ''
  say 'A theme without its wallpaper uses its own background colour, so the'
  say 'desktop still matches the theme. Download all ten (4k and 8k, ~311 MB):'
  say ''
  say '    nirux wallpapers download'
  say ''
  say 'The same action is offered in the launcher under Wallpaper.'
}

fetch_wallpaper_bundle() {
  wp_zip=$WORK/nirux-wallpapers.zip
  rm -f "$wp_zip"
  fetch "$WALLPAPER_BUNDLE_URL" "$wp_zip" ||
    die 'could not download the wallpaper set; check the network connection'
  wp_size=$(wc -c < "$wp_zip" | tr -d ' ')
  [ "$wp_size" = "$WALLPAPER_BUNDLE_BYTES" ] ||
    die "the download was incomplete ($wp_size of $WALLPAPER_BUNDLE_BYTES bytes); run the command again"
  wp_sum=$(sha256sum "$wp_zip" | cut -d ' ' -f1)
  [ "$wp_sum" = "$WALLPAPER_BUNDLE_SHA256" ] ||
    die 'the download did not match its checksum; nothing was installed'
  say 'Download verified.'
}

wallpapers_download() {
  wp_dir=$(wallpaper_destination)
  if [ "$(wallpaper_theme_count)" -eq 10 ]; then
    say 'All ten theme wallpapers are already installed.'
    return 0
  fi
  mkdir -p "$WORK" 2>/dev/null || :
  say 'Downloading the NIRUX theme wallpapers (~311 MB) from nextcloud.nirucon.se...'
  fetch_wallpaper_bundle
  command -v unzip >/dev/null 2>&1 ||
    die 'unzip is needed to install the wallpaper set'
  # Stage everything first: a truncated archive must never leave a half-written
  # set that looks installed.
  wp_stage=$WORK/wallpapers-stage
  rm -rf "$wp_stage"
  mkdir -p "$wp_stage" || die 'could not create the staging directory'
  unzip -q -o "$WORK/nirux-wallpapers.zip" -d "$wp_stage" ||
    die 'could not extract the wallpaper set'
  [ -n "$(find "$wp_stage" -name 'nirux-wallpaper-*.png' -print -quit)" ] ||
    die 'the wallpaper set contained no PNG files'

  mkdir -p "$wp_dir" || die "could not create $wp_dir"
  wp_manifest=$(wallpaper_manifest)
  : > "$wp_manifest.new"
  wp_installed=0
  for wp_src in "$wp_stage"/nirux-wallpaper-*.png; do
    [ -f "$wp_src" ] || continue
    wp_name=${wp_src##*/}
    wp_target=$wp_dir/$wp_name
    if [ -f "$wp_target" ]; then
      wp_old=$(awk -v n="$wp_name" '$2 == n {print $1; exit}' "$wp_manifest" 2>/dev/null)
      wp_cur=$(sha256sum "$wp_target" | cut -d ' ' -f1)
      if [ -z "$wp_old" ] || [ "$wp_cur" != "$wp_old" ]; then
        say "Keeping your own $wp_target"
        printf '%s  %s\n' "$wp_cur" "$wp_name" >> "$wp_manifest.new"
        continue
      fi
    fi
    install -m 644 "$wp_src" "$wp_target" || die "could not install $wp_target"
    printf '%s  %s\n' "$(sha256sum "$wp_target" | cut -d ' ' -f1)" "$wp_name" \
      >> "$wp_manifest.new"
    wp_installed=$((wp_installed + 1))
  done
  # Keep any previously recorded file this set did not mention.
  if [ -f "$wp_manifest" ]; then
    while IFS= read -r wp_line; do
      wp_name=${wp_line#*  }
      [ -n "$wp_name" ] || continue
      grep -q "  $wp_name\$" "$wp_manifest.new" && continue
      [ -f "$wp_dir/$wp_name" ] || continue
      printf '%s\n' "$wp_line" >> "$wp_manifest.new"
    done < "$wp_manifest"
  fi
  chmod 644 "$wp_manifest.new" 2>/dev/null || :
  mv -f "$wp_manifest.new" "$wp_manifest" || die 'could not record the installed wallpapers'
  rm -rf "$wp_stage" "$WORK/nirux-wallpapers.zip"
  say "Installed $wp_installed wallpaper file(s) in $wp_dir"
  say "Themes available now: $(wallpaper_theme_count) of 10"
  say 'Switch theme to see them: niructl theme niru-nord'
}

wallpapers_remove() {
  wp_dir=$(wallpaper_destination)
  wp_manifest=$(wallpaper_manifest)
  if [ ! -f "$wp_manifest" ]; then
    say 'No NIRUX-installed wallpapers are recorded.'
    return 0
  fi
  wp_removed=0
  : > "$wp_manifest.new"
  while IFS= read -r wp_line; do
    wp_old=${wp_line%%  *}
    wp_name=${wp_line#*  }
    [ -n "$wp_old" ] && [ -n "$wp_name" ] || continue
    # The default theme's wallpaper ships with every release; keep it so a
    # fresh look still works with no network at all.
    case "$wp_name" in
      nirux-wallpaper-noir-4k.png|nirux-wallpaper-noir-8k.png)
        printf '%s\n' "$wp_line" >> "$wp_manifest.new"
        continue
        ;;
    esac
    wp_target=$wp_dir/$wp_name
    if [ ! -f "$wp_target" ]; then
      continue
    fi
    wp_cur=$(sha256sum "$wp_target" | cut -d ' ' -f1)
    if [ "$wp_cur" = "$wp_old" ]; then
      rm -f "$wp_target" && wp_removed=$((wp_removed + 1))
    else
      say "Keeping $wp_target; it was modified"
      printf '%s\n' "$wp_line" >> "$wp_manifest.new"
    fi
  done < "$wp_manifest"
  mv -f "$wp_manifest.new" "$wp_manifest" 2>/dev/null || :
  say "Removed $wp_removed downloaded wallpaper file(s)."
  say 'The default theme keeps its wallpaper; other themes now use their background colour.'
}
