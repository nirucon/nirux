pictures_directory() {
  if [ -n "${XDG_PICTURES_DIR:-}" ]; then
    say "$XDG_PICTURES_DIR"; return 0
  fi
  if command -v xdg-user-dir >/dev/null 2>&1; then
    pictures=$(xdg-user-dir PICTURES 2>/dev/null || :)
    if [ -n "$pictures" ] && [ "$pictures" != "$HOME" ]; then
      say "$pictures"; return 0
    fi
  fi
  say "$HOME/Pictures"
}
wallpaper_manifest() {
  say "$STATE/wallpapers.sha256"
}
wallpapers_lock() {
  [ "${WP_LOCKED_STATE:-}" != "$STATE" ] || return 0
  mkdir -p "$STATE" || die 'could not create wallpaper state directory'
  exec 9>"$STATE/wallpapers.lock"
  flock -w 5 9 || die 'another wallpaper operation is running; try again shortly'
  WP_LOCKED_STATE=$STATE
}
install_wallpapers() {
  wallpapers_lock
  archive=$WORK/download/nirux/nirux-wallpapers.tar.xz
  [ -f "$archive" ] || return 0
  [ -n "${HOME:-}" ] || return 0
  unpack=$WORK/wallpapers-unpack
  rm -rf "$unpack"
  mkdir -p "$unpack" || die 'could not create the wallpaper extraction directory'
  tar -xJf "$archive" -C "$unpack" || die 'could not extract the wallpaper archive'
  destination=$(pictures_directory)/Wallpapers/NIRU
  mkdir -p "$destination" || die "could not create $destination"
  manifest=$(wallpaper_manifest)
  previous=$WORK/wallpapers-previous.manifest
  next=$WORK/wallpapers-next.manifest
  rm -f "$previous" "$next"
  [ ! -f "$manifest" ] || cp -p "$manifest" "$previous"
  : > "$next"
  found=0
  for source in "$unpack"/wallpaper/*.png; do
    [ -f "$source" ] || continue
    found=1
    name=${source##*/}
    new_hash=$(sha256sum "$source" | cut -d ' ' -f1)
    target=$destination/$name
    old_hash=
    [ ! -f "$previous" ] || old_hash=$(awk -v n="$name" '$2 == n {print $1; exit}' "$previous")
    if [ -f "$target" ]; then
      current_hash=$(sha256sum "$target" | cut -d ' ' -f1)
      if [ "$current_hash" = "$new_hash" ]; then
        printf '%s  %s\n' "$new_hash" "$name" >> "$next"
        continue
      fi
      if [ -z "$old_hash" ] || [ "$current_hash" != "$old_hash" ]; then
        say "Keeping modified wallpaper $target"
        continue
      fi
    fi
    install -m 644 "$source" "$target" || die "could not install $target"
    printf '%s  %s\n' "$new_hash" "$name" >> "$next"
  done
  if [ "$found" = 1 ]; then
    if [ -f "$previous" ]; then
      while IFS= read -r line; do
        old_hash=${line%%  *}
        name=${line#*  }
        [ -n "$old_hash" ] && [ -n "$name" ] || continue
        grep -q "  $name$" "$next" && continue
        target=$destination/$name
        [ -f "$target" ] || continue
        # A release carries only the default theme. The other nine may have
        # been installed with `nirux wallpapers download`; those are still
        # owned and still wanted, so an update keeps them and their hash.
        # Only the ten known theme names are protected: a file a release really
        # supersedes is still removed.
        keep=0
        case "${name#nirux-wallpaper-}" in
          noir-[48]k.png|nord-[48]k.png|satie-[48]k.png) keep=1 ;;
          carl-larsson-[48]k.png|forest-vigil-[48]k.png|blood-of-urdr-[48]k.png) keep=1 ;;
          root-and-stone-[48]k.png|blue-horizon-[48]k.png) keep=1 ;;
          the-norns-[48]k.png|winter-nights-[48]k.png) keep=1 ;;
          carl-larsson-red-[48]k.png|carl-larsson-blue-[48]k.png|carl-larsson-green-[48]k.png|carl-larsson-noir-[48]k.png) keep=1 ;;
          satie-red-[48]k.png|satie-blue-[48]k.png|satie-green-[48]k.png|satie-noir-[48]k.png) keep=1 ;;
          # NIRUX Signature (`nirux wallpapers download signature`).
          signature-*-4k.png) keep=1 ;;
        esac
        if [ "$keep" = 1 ]; then
          printf '%s  %s\n' "$old_hash" "$name" >> "$next"
          continue
        fi
        current_hash=$(sha256sum "$target" | cut -d ' ' -f1)
        if [ "$current_hash" = "$old_hash" ]; then
          rm -f "$target" || die "could not remove superseded wallpaper $target"
          say "Removed superseded wallpaper $target"
        else
          say "Keeping modified wallpaper $target"
        fi
      done < "$previous"
    fi
    chmod 644 "$next" 2>/dev/null || :
    mv -f "$next" "$manifest" || die 'could not record the installed wallpapers'
    say "Installed NIRUX theme wallpapers in $destination"
  else
    rm -f "$next"
    say 'wallpaper archive contained no PNG files'
  fi
  rm -rf "$unpack"
}
remove_owned_wallpapers() {
  wallpapers_lock
  manifest=$(wallpaper_manifest)
  [ -f "$manifest" ] || return 0
  destination=$(pictures_directory)/Wallpapers/NIRU
  while IFS= read -r line; do
    hash=${line%%  *}
    name=${line#*  }
    [ -n "$hash" ] && [ -n "$name" ] || continue
    target=$destination/$name
    [ -f "$target" ] || continue
    current_hash=$(sha256sum "$target" | cut -d ' ' -f1)
    [ "$current_hash" = "$hash" ] || continue
    rm -f "$target"
  done < "$manifest"
  rmdir "$destination" 2>/dev/null || :
  rm -f "$manifest"
}
