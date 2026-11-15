login_wallpaper_config() {
  say "${XDG_CONFIG_HOME:-$HOME/.config}/nirux/login-wallpaper"
}

configured_theme() {
  theme_file=$CONFDIR/config.toml
  theme=
  [ ! -f "$theme_file" ] || theme=$(sed -n 's/^[[:space:]]*theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$theme_file" | head -n 1)
  [ -n "$theme" ] || theme=niru-noir
  say "$theme"
}

theme_login_wallpaper() {
  theme=$(configured_theme)
  case "$theme" in
    niru-*) name=${theme#niru-} ;;
    *) name=$theme ;;
  esac
  base=$(pictures_directory)/Wallpapers/NIRU
  # The login screen shows the same picture style as the desktop.
  style=
  [ ! -f "$CONFDIR/config.toml" ] ||
    style=$(sed -n 's/^[[:space:]]*theme_style[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFDIR/config.toml" | head -n 1)
  if [ "$style" = signature ] && [ -f "$base/nirux-wallpaper-signature-$name-4k.png" ] &&
     is_png "$base/nirux-wallpaper-signature-$name-4k.png"; then
    say "$base/nirux-wallpaper-signature-$name-4k.png"; return 0
  fi
  for candidate in "$base/nirux-wallpaper-$name-4k.png" "$base/nirux-wallpaper-$name-8k.png" "$base/nirux-wallpaper-$name.png"; do
    if [ -f "$candidate" ] && is_png "$candidate"; then say "$candidate"; return 0; fi
  done
  for candidate in "$base/nirux-wallpaper-noir-4k.png" "$base/nirux-wallpaper-noir-8k.png"; do
    if [ -f "$candidate" ] && is_png "$candidate"; then say "$candidate"; return 0; fi
  done
  return 1
}

default_login_wallpaper() {
  theme_login_wallpaper
}

selected_login_wallpaper() {
  file=$(login_wallpaper_config)
  [ -f "$file" ] || return 1
  selected=$(sed -n '1p' "$file")
  [ -n "$selected" ] && [ -f "$selected" ] || return 1
  say "$selected"
}

is_png() {
  [ "$(od -An -tx1 -N8 "$1" 2>/dev/null | tr -d ' \n')" = "89504e470d0a1a0a" ]
}

apply_login_wallpaper() {
  login_source=$1
  [ -f "$login_source" ] || die "login wallpaper not found: $login_source"
  is_png "$login_source" || die "login wallpaper must be a PNG: $login_source"
  applied=0
  if [ -f "$ROOT/usr/share/sddm/themes/nirux/Main.qml" ] &&
     owned "$ROOT/usr/share/sddm/themes/nirux/Main.qml"; then
    install_login_picture "$login_source" "$ROOT/usr/share/sddm/themes/nirux/background.png" || \
      die 'could not copy the login picture; is the NIRUX login rule installed?' 
    applied=1
  fi
  if [ -f "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" ] &&
     owned "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf"; then
    install_login_picture "$login_source" "$ROOT/usr/share/nirux/greeter/login.png" || \
      die 'could not copy the login picture; is the NIRUX login rule installed?' 
    tmp=$(mktemp)
    sed 's|^background=.*|background=/usr/share/nirux/greeter/login.png|' \
      "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" > "$tmp"
    write_system "$ROOT/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-nirux.conf" "$tmp"
    rm -f "$tmp"
    applied=1
  fi
  [ "$applied" = 1 ] || die 'no NIRUX SDDM or LightDM greeter is installed; run nirux install --display-manager sddm|lightdm'
  say "Login wallpaper applied from $login_source. It appears at the next greeter start."
}

login_wallpaper() {
  action=${1:-list}
  destination=$(pictures_directory)/Wallpapers/NIRU
  selected=$(selected_login_wallpaper || :)
  case "$action" in
    list)
      [ -d "$destination" ] || die "wallpaper directory not found: $destination"
      found=0
      for file in "$destination"/*.png; do
        [ -f "$file" ] || continue
        found=1
        if [ "$file" = "$selected" ]; then printf '* %s\n' "${file##*/}"
        else printf '  %s\n' "${file##*/}"; fi
      done
      [ "$found" = 1 ] || die "no PNG wallpapers in $destination"
      default_wallpaper=$(default_login_wallpaper || :)
      say "Current: ${selected:-$default_wallpaper}"
      ;;
    set)
      [ "$#" = 2 ] || die 'login-wallpaper set needs one PNG filename or path'
      login_source=$2
      case "$login_source" in
        */*) : ;;
        *) login_source=$destination/$login_source ;;
      esac
      [ -f "$login_source" ] || die "login wallpaper not found: $login_source"
      apply_login_wallpaper "$login_source"
      mkdir -p "$(dirname "$(login_wallpaper_config)")"
      printf '%s\n' "$login_source" > "$(login_wallpaper_config)"
      ;;
    sync)
      # Follow the theme that is now selected. Called by the theme hook so the
      # greeter background changes with the desktop wallpaper instead of
      # keeping the picture from the last `nirux update`. A wallpaper the user
      # chose explicitly with `login-wallpaper set` is never overridden.
      #
      # It runs under sudo, where HOME is root's, so the desktop user's own
      # configuration and Pictures directory are read through SUDO_USER.
      [ "$#" = 1 ] || die 'login-wallpaper sync takes no arguments'
      sync_user=${SUDO_USER:-}
      if [ -n "$sync_user" ] && [ "$sync_user" != root ]; then
        sync_home=$(getent passwd "$sync_user" 2>/dev/null | cut -d: -f6)
        if [ -n "$sync_home" ] && [ -d "$sync_home" ]; then
          HOME=$sync_home
          export HOME
          # PREFIX and CONFDIR are derived from HOME at startup; re-derive them
          # so ownership checks recognise files the desktop user's install wrote.
          PREFIX=${NIRUX_PREFIX:-$HOME/.local}
          BIN=$PREFIX/bin
          STATE=$PREFIX/share/nirux
          CONFDIR=${XDG_CONFIG_HOME:-$HOME/.config}/niruwm
        fi
      fi
      [ -f "$(login_wallpaper_config)" ] && return 0
      login_source=$(theme_login_wallpaper || :)
      [ -n "$login_source" ] || return 0
      [ -f "$login_source" ] || return 0
      apply_login_wallpaper "$login_source"
      ;;
    reset)
      [ "$#" = 1 ] || die 'login-wallpaper reset takes no arguments'
      login_source=$(default_login_wallpaper)
      [ -f "$login_source" ] || die "default login wallpaper not found: $login_source"
      apply_login_wallpaper "$login_source"
      rm -f "$(login_wallpaper_config)"
      ;;
    *) die 'login-wallpaper needs list, set FILE or reset' ;;
  esac
}

# ── Optional theme wallpaper set ────────────────────────────────────────────
# NIRUX ships only the default Noir wallpaper with its release. The other nine
# theme wallpapers, plus the optional colour packs, are published as GitHub
# release assets in nirucon/nirux-wallpapers. A theme without its image paints
# its own background colour, so nothing looks broken while a pack is absent.
WALLPAPER_RELEASE=v1.0.0
WALLPAPER_OPTIONAL_THEMES='nord satie carl-larsson forest-vigil blood-of-urdr root-and-stone blue-horizon the-norns winter-nights'
WALLPAPER_THEMES='noir nord satie carl-larsson forest-vigil blood-of-urdr root-and-stone blue-horizon the-norns winter-nights'
# Archive bytes and SHA-256 are pinned here, and the wallpaper release when it
# is not WALLPAPER_RELEASE: v1.2.0 restyled seven themes in the same colours. The optional assets live outside
# the NIRUX release so the core desktop update stays small and does not fetch
# hundreds of megabytes on machines that already have their wallpapers.
WALLPAPER_THEME_ASSETS='
nirux-wallpaper-nord.tar.xz 47263024 ce11b7b52919451990211ca74cf868b023fba436cb323d3f996e55b34290d307 v1.2.0
nirux-wallpaper-satie.tar.xz 37974168 d8122198e69e8d2dc9ec69f56701fdcc19f9f05876c60d3bf0106ab9f2c50118
nirux-wallpaper-carl-larsson.tar.xz 38690916 1d6415e8c296ef4bfb776422fa0bf65eeda9d1fd5f46eb4df17ffd30fbc013a2
nirux-wallpaper-forest-vigil.tar.xz 36412768 6e20c50cd1806c139c4e93a0abd725bf3143ef1fe2b0a34bd9baa64cb6998bf4 v1.2.0
nirux-wallpaper-blood-of-urdr.tar.xz 57054300 93440cc8ef8d0236d240c829b22d36daf116453cf569f3f83a5018c769dbea7a v1.2.0
nirux-wallpaper-root-and-stone.tar.xz 46011164 0789d03ba203adc9b31490a478955f6759c0d7e27a1eec064b052a9caebe3914 v1.2.0
nirux-wallpaper-blue-horizon.tar.xz 43933788 0c0b8f97e2385f7d1cee375f2ac78792e8d61bf32074def9e736f717737c7392 v1.2.0
nirux-wallpaper-the-norns.tar.xz 38644648 9d80195428faa54ab7ed9922caae596664439083981280e2904891106a4b7537 v1.2.0
nirux-wallpaper-winter-nights.tar.xz 27967420 ed60d052b6ac826a1531b977324e931cc469e961113cf9f5c3b3c4f0ac6a0b69 v1.2.0
'
WALLPAPER_EXTRA_ASSETS='
nirux-wallpaper-carl-larsson-extras.tar.xz 182739720 c2225a723d74963ee03a7861cbadceec0221cbf4a83764ed48e596d9c09a6feb
nirux-wallpaper-satie-extras.tar.xz 83893724 5ce97288cc819af72dde4ddc2edd3ba9c5c9d075bdcc424bce3de0f06080310f
'
WALLPAPER_EXTRA_COLOURS='red blue green noir'
# NIRUX Signature: the Noir photograph toned in each theme's colours (4K, one
# archive). It is published in a later wallpaper release than the theme packs,
# which stay where they are, so only this archive is new to download.
WALLPAPER_SIGNATURE_RELEASE=v1.1.0
WALLPAPER_SIGNATURE_ASSET='nirux-wallpaper-signature.tar.xz 48883084 ead39530a7f942498e532ede999f77efb804c878ccc6d9425875709ed3ed6d8e'

# The current theme pictures, for themes whose pictures changed after they
# were first published. A NIRUX-installed picture with another checksum is an
# older version and is replaced on update; a picture changed by the user is kept.
WALLPAPER_THEME_PNGS='
nirux-wallpaper-blood-of-urdr-4k.png c14f24d968cd7ef2a95eedda45ddd48089f5583505fc85779146e69fc1e734b6
nirux-wallpaper-blood-of-urdr-8k.png 6a48ba4bebfe279a44135ecb61f1b87f67676ff75605acb2e79186c98da4de4b
nirux-wallpaper-blue-horizon-4k.png 04ba33f8b5fbd949408cfc9eabb046daf7d2a57aa9bc86f028a6eb34487e6d46
nirux-wallpaper-blue-horizon-8k.png 352ef9ae5787f888985e39977edff96e83d71cefc4f2c69eef605f7c153f27ec
nirux-wallpaper-forest-vigil-4k.png e74ddaf2b2bbe668fc7713b08ccea526bcb34d8dfa9e39ef45e4aad60377651b
nirux-wallpaper-forest-vigil-8k.png 290f0913568bf2f8642a9d4f33084ae2e97287de380bb04d97ceb47383912ba0
nirux-wallpaper-nord-4k.png 38638b9a782f789ad6c29f754b472cd9c06e9fb99b3c4fb68a912406cf232e19
nirux-wallpaper-nord-8k.png a78f8a97c0dc8f59ec4de8196ce4c3fc5553f2b6b85f5574bf4c512ea5e7cef2
nirux-wallpaper-root-and-stone-4k.png 55511dec2a3fead40925c608dc273b123e40bbd6bc3fa6182ca2a2e868b03676
nirux-wallpaper-root-and-stone-8k.png b790334ed7f611817ca224925f810fd5ded04f407d3f33e92e4b206cdd4fb6fa
nirux-wallpaper-the-norns-4k.png e0efb519362314c453a9bfeb12cb2084000c6a1d0c130af45cc5bc741ca58e63
nirux-wallpaper-the-norns-8k.png 5c61fad4970aa97b820c3d4736b991722a863da25f02b576ed0444e8c4eebd49
nirux-wallpaper-winter-nights-4k.png 6d0cc2d5c77ec18035531a29f6dd1f50ce81018cc84240261b98c14717c1b9f3
nirux-wallpaper-winter-nights-8k.png d65b88d94bedc677f27fcb9616314378e8393f8c6ab9f8e2cd8dd07a95320bb7
'

wallpaper_asset_release() {
  printf '%s\n' "$WALLPAPER_THEME_ASSETS" | awk -v n="$1" -v d="$WALLPAPER_RELEASE" '$1 == n {print ($4 != "" ? $4 : d); found=1} END {if (!found) print d}'
}

# True when a theme's pictures are NIRUX's own but an older version.
wallpaper_theme_outdated() {
  wp_od_dir=$(wallpaper_destination)
  wp_od_manifest=$(wallpaper_manifest)
  for wp_od_size in 4k 8k; do
    wp_od_name=nirux-wallpaper-$1-$wp_od_size.png
    wp_od_want=$(printf '%s\n' "$WALLPAPER_THEME_PNGS" | awk -v n="$wp_od_name" '$1 == n {print $2; exit}')
    [ -n "$wp_od_want" ] || continue
    [ -f "$wp_od_dir/$wp_od_name" ] || continue
    wp_od_cur=$(sha256sum "$wp_od_dir/$wp_od_name" | cut -d ' ' -f1)
    [ "$wp_od_cur" != "$wp_od_want" ] || continue
    wp_od_rec=$(awk -v n="$wp_od_name" '$2 == n {print $1; exit}' "$wp_od_manifest" 2>/dev/null)
    [ "$wp_od_cur" = "$wp_od_rec" ] && return 0
  done
  return 1
}

# On update: new versions of the theme pictures you already have.
wallpapers_refresh_installed() {
  wp_rf_themes=
  for wp_rf in $WALLPAPER_OPTIONAL_THEMES; do
    if wallpaper_theme_installed "$wp_rf" && wallpaper_theme_outdated "$wp_rf"; then
      wp_rf_themes="$wp_rf_themes $wp_rf"
    fi
  done
  [ -n "$wp_rf_themes" ] || return 0
  say "New versions of theme wallpapers:$wp_rf_themes"
  wp_rf_work=$(mktemp -d "${TMPDIR:-/tmp}/nirux-wallpapers.XXXXXX") || return 0
  for wp_rf in $wp_rf_themes; do
    if ! (WP_WORK=$wp_rf_work WP_FORCE=1 wallpaper_download_theme "$wp_rf"); then
      say "The new $wp_rf wallpapers could not be downloaded; the current ones stay. Later: nirux wallpapers download"
    fi
  done
  rm -rf "$wp_rf_work"
  refresh_running_theme
}

wallpaper_asset_meta() {
  printf '%s\n%s\n%s\n' "$WALLPAPER_THEME_ASSETS" "$WALLPAPER_EXTRA_ASSETS" "$WALLPAPER_SIGNATURE_ASSET" |
    awk -v n="$1" '$1 == n {print $2, $3; found=1} END {exit found ? 0 : 1}'
}

wallpaper_destination() {
  printf '%s\n' "$(pictures_directory)/Wallpapers/NIRU"
}

# Display layouts are NIRUWM's `displays.toml` profiles, reached from one place
# so a user does not need to remember which program owns them.
layout() {
  sub=${1:-list}
  [ -x "$BIN/niructl" ] || die 'niructl is missing; run nirux update'
  case "$sub" in
    list)
      "$BIN/niructl" display list || die 'could not read the display profiles'
      ;;
    save)
      [ -n "${2:-}" ] || die 'layout save needs a name, for example: nirux layout save Desk'
      "$BIN/niructl" display save "$2" || die "could not save the layout $2"
      say "Layout $2 saved. Apply it with: nirux layout apply $2"
      ;;
    apply)
      [ -n "${2:-}" ] || die 'layout apply needs a name; see nirux layout list'
      "$BIN/niructl" display apply "$2" || die "could not apply the layout $2"
      ;;
    rotate)
      [ -n "${2:-}" ] && [ -n "${3:-}" ] ||
        die 'layout rotate needs an output and normal|left|right|inverted; niructl monitors lists the outputs'
      "$BIN/niructl" display rotate "$2" "$3" || die "could not turn $2 to $3"
      ;;
    auto)
      "$BIN/niructl" display auto || die 'could not arrange the screens'
      ;;
    *) die 'layout takes list, save NAME, apply NAME, rotate OUTPUT ROTATION or auto' ;;
  esac
}

wallpapers() {
  sub=${1:-status}
  case "$sub" in
    status) wallpapers_status ;;
    download)
      wp_choice=${2:-themes}
      if [ "$wp_choice" = theme ]; then
        [ -n "${3:-}" ] || die 'wallpapers download theme needs a theme name'
        wp_choice=theme:$3
      fi
      case "$wp_choice" in
        themes|signature|extras|all|carl-larsson|satie|erik-satie|theme:*) ;;
        *) die 'wallpapers download takes themes, signature, extras, all, theme NAME, carl-larsson or satie' ;;
      esac
      # Self-contained command: it can run outside install/update, where WORK
      # and OS are never set. A private directory keeps the archives off /tmp
      # and removes them again. OS is needed only to install unzip when missing.
      OS=${OS:-$(distro)}
      wp_work=$(mktemp -d "${TMPDIR:-/tmp}/nirux-wallpapers.XXXXXX") ||
        die 'could not create a temporary directory'
      trap 'rm -rf "$wp_work"' EXIT HUP INT TERM
      WP_WORK=$wp_work wallpapers_download "$wp_choice"
      ;;
    remove) wallpapers_remove ;;
    style) wallpapers_style "${2:-}" ;;
    *) die 'wallpapers takes status, download, style or remove' ;;
  esac
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

# Count the two optional colour-variant packs. Erik Satie's package uses the
# existing `satie` theme slug so the variants sit beside the default theme image.
wallpaper_extra_count() {
  wp_extra_dir=$(wallpaper_destination)
  wp_extra=0
  for wp_pack in carl-larsson satie; do
    for wp_colour in $WALLPAPER_EXTRA_COLOURS; do
      for wp_size in 4k 8k; do
        [ -f "$wp_extra_dir/nirux-wallpaper-$wp_pack-$wp_colour-$wp_size.png" ] &&
          wp_extra=$((wp_extra + 1))
      done
    done
  done
  printf '%s\n' "$wp_extra"
}

wallpapers_status() {
  wp_dir=$(wallpaper_destination)
  wp_have=$(wallpaper_theme_count)
  wp_extra=$(wallpaper_extra_count)
  say "Theme wallpapers: $wp_have of 10 installed in $wp_dir"
  say "Additional colour packs: $wp_extra of 16 installed"
  say "NIRUX Signature: $(wallpaper_signature_count) of 10 installed (nirux wallpapers download signature)"
  if [ "$wp_have" -eq 10 ] && [ "$wp_extra" -eq 16 ]; then
    say 'Every theme and additional wallpaper is installed; nothing to download.'
    return 0
  fi
  say ''
  say 'A theme without its own wallpaper uses its background colour, so the'
  say 'desktop still matches the theme. Optional theme wallpaper archives are'
  say 'downloaded from GitHub release assets and verified by byte count and SHA-256:'
  say ''
  say '    nirux wallpapers download themes'
  say '    nirux wallpapers download nord'
  say ''
  say 'Carl Larsson and Erik Satie colour variants (red, blue, green, noir):'
  say ''
  say '    nirux wallpapers download extras'
  say ''
  say 'Download everything: nirux wallpapers download all'
  say 'The same action is offered in the launcher under Wallpaper.'
}

wallpaper_asset_path() {
  case "$1" in
    */*|'') die "invalid wallpaper asset name: $1" ;;
  esac
  printf '%s\n' "$1"
}

wallpaper_fetch_asset() {
  wp_asset=$(wallpaper_asset_path "$1")
  wp_meta=$(wallpaper_asset_meta "$wp_asset") ||
    die "unknown wallpaper asset: $wp_asset"
  wp_bytes=${wp_meta%% *}
  wp_sha=${wp_meta#* }
  wp_file=${WP_WORK:?no work directory}/$wp_asset
  rm -f "$wp_file"
  wp_base=https://github.com/nirucon/nirux-wallpapers/releases/download/$(wallpaper_asset_release "$wp_asset")
  case "$wp_asset" in
    nirux-wallpaper-signature.tar.xz)
      wp_base=https://github.com/nirucon/nirux-wallpapers/releases/download/$WALLPAPER_SIGNATURE_RELEASE ;;
  esac
  fetch "$wp_base/$wp_asset" "$wp_file" ||
    die "could not download $wp_asset; check the network connection"
  wp_actual_bytes=$(wc -c < "$wp_file" | tr -d ' ')
  [ "$wp_actual_bytes" = "$wp_bytes" ] ||
    die "the $wp_asset download was incomplete ($wp_actual_bytes of $wp_bytes bytes); run the command again"
  [ "$(sha256sum "$wp_file" | cut -d ' ' -f1)" = "$wp_sha" ] ||
    die "$wp_asset did not match its checksum; nothing was installed"
  printf '%s\n' "$wp_file"
}

wallpaper_extract_asset() {
  wp_asset=$1
  wp_tar=$2
  wp_stage=${WP_WORK:?no work directory}/${wp_asset%.tar.xz}-stage
  rm -rf "$wp_stage"
  mkdir -p "$wp_stage" || die 'could not create the wallpaper staging directory'
  tar -xJf "$wp_tar" -C "$wp_stage" ||
    die "could not extract $wp_asset"
  printf '%s\n' "$wp_stage"
}

# Install the PNGs from one verified archive. Existing user-modified files are
# never adopted; only NIRUX-owned bytes are updated. Unrelated manifest entries
# are retained.
wallpaper_install_stage() {
  wp_stage=$1
  wp_manifest=$(wallpaper_manifest)
  mkdir -p "${wp_manifest%/*}" || die 'could not create the NIRUX state directory'
  wp_next=${WP_WORK:?no work directory}/wallpapers-manifest.next
  if [ -f "$wp_manifest" ]; then
    cp -p "$wp_manifest" "$wp_next"
  else
    : > "$wp_next"
  fi
  wp_installed=0
  for wp_src in "$wp_stage"/nirux-wallpaper-*.png; do
    [ -f "$wp_src" ] || continue
    wp_name=${wp_src##*/}
    awk -v n="$wp_name" '$2 != n' "$wp_next" > "$wp_next.tmp" ||
      die 'could not update the wallpaper manifest'
    mv -f "$wp_next.tmp" "$wp_next"
    wp_target=$(wallpaper_destination)/$wp_name
    mkdir -p "$(dirname "$wp_target")" || die "could not create $(dirname "$wp_target")"
    if [ -f "$wp_target" ]; then
      wp_old=$(awk -v n="$wp_name" '$2 == n {print $1; exit}' "$wp_manifest" 2>/dev/null)
      wp_cur=$(sha256sum "$wp_target" | cut -d ' ' -f1)
      if [ -z "$wp_old" ] || [ "$wp_cur" != "$wp_old" ]; then
        say "Keeping your own $wp_target"
        [ -z "$wp_old" ] || printf '%s  %s\n' "$wp_old" "$wp_name" >> "$wp_next"
        continue
      fi
    fi
    install -m 644 "$wp_src" "$wp_target" || die "could not install $wp_target"
    printf '%s  %s\n' "$(sha256sum "$wp_target" | cut -d ' ' -f1)" "$wp_name" >> "$wp_next"
    wp_installed=$((wp_installed + 1))
  done
  chmod 644 "$wp_next" 2>/dev/null || :
  mv -f "$wp_next" "$wp_manifest" || die 'could not record the installed wallpapers'
  WP_INSTALLED_COUNT=$wp_installed
}

wallpaper_theme_installed() {
  wp_theme_dir=$(wallpaper_destination)
  [ -f "$wp_theme_dir/nirux-wallpaper-$1-4k.png" ] &&
    [ -f "$wp_theme_dir/nirux-wallpaper-$1-8k.png" ]
}

wallpaper_download_theme() {
  wp_theme=$1
  case " $WALLPAPER_OPTIONAL_THEMES " in
    *" $wp_theme "*) ;;
    *) die "unknown optional theme wallpaper: $wp_theme" ;;
  esac
  if [ "${WP_FORCE:-0}" != 1 ] && wallpaper_theme_installed "$wp_theme" && ! wallpaper_theme_outdated "$wp_theme"; then
    say "$wp_theme wallpapers are already installed."
    return 0
  fi
  wp_asset=nirux-wallpaper-$wp_theme.tar.xz
  say "Downloading $wp_theme 4k/8k wallpapers from GitHub..."
  wp_tar=$(wallpaper_fetch_asset "$wp_asset")
  wp_stage=$(wallpaper_extract_asset "$wp_asset" "$wp_tar")
  for wp_size in 4k 8k; do
    wp_image=$wp_stage/nirux-wallpaper-$wp_theme-$wp_size.png
    [ -f "$wp_image" ] && [ ! -L "$wp_image" ] && is_png "$wp_image" ||
      die "the $wp_theme wallpaper archive is incomplete or invalid; nothing installed"
  done
  say 'Download verified.'
  wallpaper_install_stage "$wp_stage"
  rm -rf "$wp_stage" "$wp_tar"
  say "Installed $WP_INSTALLED_COUNT $wp_theme wallpaper file(s)."
}

wallpapers_download_themes() {
  wp_missing=0
  for wp_theme in $WALLPAPER_OPTIONAL_THEMES; do
    if ! wallpaper_theme_installed "$wp_theme" || wallpaper_theme_outdated "$wp_theme"; then
      wp_missing=1
      wallpaper_download_theme "$wp_theme" || return 1
    fi
  done
  if [ "$wp_missing" -eq 0 ]; then
    say 'All nine optional theme wallpapers are already installed.'
  fi
  refresh_running_theme
}

wallpaper_pack_installed() {
  wp_pack=$1
  wp_dir=$(wallpaper_destination)
  for wp_colour in $WALLPAPER_EXTRA_COLOURS; do
    for wp_size in 4k 8k; do
      [ -f "$wp_dir/nirux-wallpaper-$wp_pack-$wp_colour-$wp_size.png" ] || return 1
    done
  done
  return 0
}

# Verify and install one optional colour pack.
wallpapers_download_pack() {
  wp_pack=$1
  case "$wp_pack" in
    carl-larsson) wp_label='Carl Larsson' ;;
    satie) wp_label='Erik Satie' ;;
    *) die "unknown wallpaper pack: $wp_pack" ;;
  esac
  if wallpaper_pack_installed "$wp_pack"; then
    say "$wp_label additional wallpapers are already installed."
    return 0
  fi
  wp_asset=nirux-wallpaper-$wp_pack-extras.tar.xz
  say "Downloading $wp_label colour wallpapers from GitHub..."
  wp_tar=$(wallpaper_fetch_asset "$wp_asset")
  wp_stage=$(wallpaper_extract_asset "$wp_asset" "$wp_tar")
  for wp_colour in $WALLPAPER_EXTRA_COLOURS; do
    for wp_size in 4k 8k; do
      wp_image=$wp_stage/nirux-wallpaper-$wp_pack-$wp_colour-$wp_size.png
      [ -f "$wp_image" ] && [ ! -L "$wp_image" ] && is_png "$wp_image" ||
        die "the $wp_label wallpaper pack is incomplete or invalid; nothing installed"
    done
  done
  say 'Download verified.'
  wallpaper_install_stage "$wp_stage"
  rm -rf "$wp_stage" "$wp_tar"
  say "Installed $WP_INSTALLED_COUNT $wp_label wallpaper file(s)."
}

wallpapers_download() {
  wallpapers_lock
  wp_choice=${1:-themes}
  case "$wp_choice" in
    themes) wallpapers_download_themes && wallpapers_download_signature ;;
    signature) wallpapers_download_signature ;;
    extras)
      wallpapers_download_pack carl-larsson
      wallpapers_download_pack satie
      ;;
    all)
      wallpapers_download_themes
      wallpapers_download_signature
      wallpapers_download_pack carl-larsson
      wallpapers_download_pack satie
      ;;
    carl-larsson) wallpapers_download_pack carl-larsson ;;
    satie|erik-satie) wallpapers_download_pack satie ;;
    theme:*) wallpaper_download_theme "${wp_choice#theme:}" ;;
    *) die 'wallpapers download takes themes, signature, extras, all, theme NAME, carl-larsson or satie' ;;
  esac
}

wallpaper_signature_count() {
  wp_sig_dir=$(wallpaper_destination)
  wp_sig=0
  for wp_theme in $WALLPAPER_THEMES; do
    [ -f "$wp_sig_dir/nirux-wallpaper-signature-$wp_theme-4k.png" ] && wp_sig=$((wp_sig + 1))
  done
  printf '%s\n' "$wp_sig"
}

# NIRUX Signature: ten 4K pictures, one per built-in theme.
wallpapers_download_signature() {
  if [ "$(wallpaper_signature_count)" -ge 10 ]; then
    say 'NIRUX Signature wallpapers are already installed.'
    return 0
  fi
  wp_asset=nirux-wallpaper-signature.tar.xz
  say 'Downloading the NIRUX Signature wallpapers from GitHub...'
  wp_tar=$(wallpaper_fetch_asset "$wp_asset")
  wp_stage=$(wallpaper_extract_asset "$wp_asset" "$wp_tar")
  for wp_theme in $WALLPAPER_THEMES; do
    wp_image=$wp_stage/nirux-wallpaper-signature-$wp_theme-4k.png
    [ -f "$wp_image" ] && [ ! -L "$wp_image" ] && is_png "$wp_image" ||
      die 'the NIRUX Signature archive is incomplete or invalid; nothing installed'
  done
  say 'Download verified.'
  wallpaper_install_stage "$wp_stage"
  rm -rf "$wp_stage" "$wp_tar"
  say "Installed $WP_INSTALLED_COUNT NIRUX Signature wallpaper file(s)."
}

# `nirux wallpapers style art|signature|toggle`: which picture a theme shows.
# Choosing Signature downloads the pack first when it is missing.
wallpapers_style() {
  wp_style=${1:-}
  case "$wp_style" in
    art|signature|toggle) ;;
    '') "$BIN/niructl" wallpaper status 2>/dev/null | sed -n 's/^theme_style=/Theme pictures: /p'; return 0 ;;
    *) die 'wallpapers style takes art, signature or toggle' ;;
  esac
  [ -x "$BIN/niructl" ] || die 'niructl is missing; run nirux update'
  if [ "$wp_style" = toggle ]; then
    case "$("$BIN/niructl" wallpaper status 2>/dev/null | sed -n 's/^theme_style=//p')" in
      signature) wp_style=art ;;
      *) wp_style=signature ;;
    esac
  fi
  if [ "$wp_style" = signature ] && [ "$(wallpaper_signature_count)" -lt 10 ]; then
    OS=${OS:-$(distro)}
    wp_work=$(mktemp -d "${TMPDIR:-/tmp}/nirux-wallpapers.XXXXXX") ||
      die 'could not create a temporary directory'
    WP_WORK=$wp_work wallpapers_download_signature || { rm -rf "$wp_work"; return 1; }
    rm -rf "$wp_work"
  fi
  "$BIN/niructl" wallpaper style "$wp_style" >/dev/null ||
    die 'could not change the wallpaper style (is NIRUWM 0.24.1 or newer installed?)'
  say "Theme pictures: $wp_style"
}

wallpapers_remove() {
  wallpapers_lock
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


