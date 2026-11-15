icons_policy_path() { say "$STATE/icons-policy"; }
icons_policy_read() {
  icons_persisted=$(awk '$1 == "icons" && ($2 == "papirus" || $2 == "none") {print $2; exit}'     "$(icons_policy_path)" 2>/dev/null) || :
}
icons_policy_write() {
  mkdir -p "$STATE" || die 'could not create icon policy directory'
  printf '# NIRUX owner: %s\nicons %s\n' "$PREFIX" "$1" > "$STATE/icons-policy.new" ||
    die 'could not record the icon policy'
  mv -f "$STATE/icons-policy.new" "$STATE/icons-policy" ||
    die 'could not activate the icon policy'
}
icons_packages_for() {
  case "$1" in
    arch) say "papirus-icon-theme gtk-update-icon-cache gsettings-desktop-schemas" ;;
    debian) say "papirus-icon-theme gtk-update-icon-cache gsettings-desktop-schemas" ;;
    void) say "papirus-icon-theme gtk-update-icon-cache gsettings-desktop-schemas" ;;
  esac
}
set_icon_ini() {
  icon_file=$1
  icon_dir=${icon_file%/*}
  mkdir -p "$icon_dir" || return 1
  if [ -f "$icon_file" ]; then
    icon_tmp=$(mktemp "$icon_file.XXXXXX") || return 1
    awk '$0 !~ /^[[:space:]]*gtk-icon-theme-name[[:space:]]*=/ {print}' "$icon_file" > "$icon_tmp" || {
      rm -f "$icon_tmp"; return 1;
    }
    mv -f "$icon_tmp" "$icon_file" || return 1
  fi
  printf 'gtk-icon-theme-name=Papirus-Dark\n' >> "$icon_file"
}
icons_apply() {
  [ "${ICONS_EFFECTIVE:-none}" = papirus ] || return 0
  icons_source=$ROOT/usr/share/icons/Papirus-Dark
  if [ ! -d "$icons_source" ]; then
    if [ "${packages:-1}" = 0 ]; then
      say 'Papirus-Dark is not installed; skipping the optional icon theme (--no-packages).'
      return 0
    fi
    icons_packages=$(icons_packages_for "$OS")
    # The package is installed only for this explicit choice; it is deliberately
    # not in the base package list because the theme is large.
    install_packages "$icons_packages" || die 'could not install Papirus icon packages'
  fi
  [ -d "$icons_source" ] || die 'Papirus-Dark is missing after package installation'
  icons_dest=$HOME/.local/share/icons/Papirus-Dark
  icons_base_source=$ROOT/usr/share/icons/Papirus
  icons_base_dest=$HOME/.local/share/icons/Papirus
  if [ ! -d "$icons_dest" ]; then
    mkdir -p "$HOME/.local/share/icons" || die 'could not create the local icon directory'
    cp -a "$icons_source" "$icons_dest" || die 'could not copy Papirus-Dark locally'
  fi
  if [ -d "$icons_base_source" ] && [ ! -d "$icons_base_dest" ]; then
    mkdir -p "$HOME/.local/share/icons" || die 'could not create the local icon directory'
    cp -a "$icons_base_source" "$icons_base_dest" || die 'could not copy Papirus locally'
  fi
  # The full Papirus folder switcher is not packaged consistently across all
  # three distros. Re-point the ordinary folder symbol to the shipped grey
  # variant in both local themes; this is the part PCManFM uses for folders.
  for icons_theme in "$icons_dest" "$icons_base_dest"; do
    [ -d "$icons_theme" ] || continue
    for icons_folder in "$icons_theme"/*/places/folder.svg; do
      [ -f "${icons_folder%/*}/folder-grey.svg" ] || continue
      ln -sfn folder-grey.svg "$icons_folder" || :
    done
  done
  set_icon_ini "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" || :
  set_icon_ini "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini" || :
  if [ -f "$HOME/.gtkrc-2.0" ]; then
    gtk2_tmp=$(mktemp "$HOME/.gtkrc-2.0.XXXXXX") || :
    if [ -n "${gtk2_tmp:-}" ]; then
      awk '$0 !~ /^[[:space:]]*gtk-icon-theme-name[[:space:]]*=/ {print}' "$HOME/.gtkrc-2.0" > "$gtk2_tmp" &&
        mv -f "$gtk2_tmp" "$HOME/.gtkrc-2.0" || rm -f "$gtk2_tmp"
    fi
  fi
  printf 'gtk-icon-theme-name="Papirus-Dark"\n' >> "$HOME/.gtkrc-2.0"
  if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Dark'" >/dev/null 2>&1 || :
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" >/dev/null 2>&1 || :
  fi
  command -v gsettings >/dev/null 2>&1 && {
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' >/dev/null 2>&1 || :
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || :
  }
  command -v gtk-update-icon-cache >/dev/null 2>&1 && {
    gtk-update-icon-cache -f -t "$icons_dest" >/dev/null 2>&1 || :
    [ -d "$icons_base_dest" ] && gtk-update-icon-cache -f -t "$icons_base_dest" >/dev/null 2>&1 || :
  }
  icons_policy_write papirus
}
icons_choose() {
  operation=$1
  icons_persisted=
  icons_policy_read
  icons_persisted=$icons_persisted
  if [ "$ICONS_EXPLICIT" = 1 ] && [ "$ICONS_CHOICE" != keep ]; then
    ICONS_EFFECTIVE=$ICONS_CHOICE
  elif [ "$operation" = update ] || [ "$ICONS_CHOICE" = keep ]; then
    ICONS_EFFECTIVE=${icons_persisted:-none}
  elif [ -t 0 ]; then
    say 'Install Papirus-Dark icons with grey folders for this user?'
    say 'This is an optional ~112-190 MB download and a local copy under ~/.local/share/icons.'
    printf 'Install Papirus-Dark [y/N]: '
    IFS= read -r icons_answer || icons_answer=no
    case "$icons_answer" in [yY]*) ICONS_EFFECTIVE=papirus ;; *) ICONS_EFFECTIVE=none ;; esac
  else
    ICONS_EFFECTIVE=none
  fi
  case "$ICONS_EFFECTIVE" in papirus|none) ;; *) die 'icons must be papirus or none' ;; esac
  if [ "$ICONS_EXPLICIT" = 1 ] || [ "$operation" = install ]; then
    icons_policy_write "$ICONS_EFFECTIVE"
  fi
}

# Ask once whether to fetch the optional theme wallpaper set.
#
# Only the default theme's wallpaper ships with a release; the other nine are a
# optional set is a GitHub release so the core NIRUX release stays small. The
# question is asked at install only, remembered in a policy file, and defaults
# to no so an unattended install never pulls hundreds of megabytes.
#
# The same set is offered once more when an update finds the other nine themes
# without their wallpapers, so an earlier "no" can still be answered with a
# terminal. `nirux wallpapers download` always stays available.
# The answer lives in $STATE/wallpaper-bundle-policy; see
# wallpaper_bundle_decision below.
wallpapers_policy_read() {
  wp_policy_file=$STATE/wallpaper-bundle-policy
  wp_persisted=$(awk '$1 == "wallpapers" && ($2 == "all" || $2 == "default") {print $2; exit}' \
    "$wp_policy_file" 2>/dev/null) || :
}
# The running installer decides whether to fetch the set. The question belongs
# to the terminal that started the install: the staged target runs with stdin
# closed, so it never sees one, and its answer file is carried over instead.
wallpaper_bundle_decision() {
  # The decision is returned in wp_decision, never on stdout: the caller uses
  # this function interactively, and a command substitution would capture the
  # prompt and leave a blind read waiting for input.
  wp_decision=
  case "${WALLPAPER_CHOICE:-${NIRUX_WALLPAPERS:-}}" in
    all) wp_decision=all; return 0 ;;
    none|default) wp_decision=default; return 0 ;;
  esac
  wallpapers_policy_read
  case "$operation" in
    install)
      # A fresh noninteractive install still gets the full nine-theme set.
      # The owner explicitly wants every installed machine to have all theme
      # wallpapers; an explicit `default` policy or --wallpapers default is
      # the way to opt out.
      if [ -z "$wp_persisted" ] && [ ! -t 0 ]; then
        wp_decision=all
        return 0
      fi
      ;;
    update)
      # Only when the ten themes are known to be incomplete, so a machine that
      # already has the set never asks again.
      [ "$(wallpaper_theme_count)" -lt 10 ] || return 0
      if [ "$wp_persisted" = all ] && [ -f "${WORK}/download/nirux/nirux-wallpapers.tar.xz" ]; then
        wp_decision=all
        return 0
      fi
      ;;
    *) return 0 ;;
  esac
  [ -t 0 ] || return 0
  if [ "$wp_persisted" = all ]; then
    # Asked for once and never delivered, for example because the download
    # failed. Fetch it again when the release ships the files.
    [ -f "${WORK}/download/nirux/nirux-wallpapers.tar.xz" ] && wp_decision=all
    return 0
  fi
  say ''
  say 'NIRUX ships ten themes, and changing theme is the main way to change the look.'
  say 'With every wallpaper installed, a theme change brings its wallpaper, bar palette,'
  say 'terminal colours and login screen together. Without them the nine non-default'
  say 'themes use their own background colour, which works but looks plain.'
  say ''
  say 'The optional set is downloaded from GitHub release assets in nirucon/nirux-wallpapers.'
  say 'An update never fetches it again, and you can add it later from the launcher'
  say 'or with: nirux wallpapers download [themes|theme NAME]'
  say ''
  printf 'Download the nine optional theme wallpapers now? [Y/n]: '
  IFS= read -r wp_answer || wp_answer=yes
  # The recommended answer is yes, so an empty line accepts the set. Only an
  # explicit no declines; an unattended install still defaults to the small
  # release because it never reaches this prompt.
  case "$wp_answer" in
    [nN]*) wp_decision=default ;;
    *) wp_decision=all ;;
  esac
}
wallpapers_policy_write() {
  [ -n "${wp_policy_file:-}" ] || wp_policy_file=$STATE/wallpaper-bundle-policy
  printf '# NIRUX owner: %s\nwallpapers %s\n' "$PREFIX" "$wp_persisted" > "$wp_policy_file" ||
    die 'could not record the wallpaper policy'
}
# Direct (non-staged) installs used to call a helper that no longer existed.
# Keep the decision and the persisted policy in one place for both paths.
select_wallpaper_bundle() {
  [ -n "${wallpaper_decision:-}" ] || return 0
  wp_persisted=$wallpaper_decision
  wallpapers_policy_write
}
