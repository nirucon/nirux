extras_table() {
  cat <<'EOF'
nirunote nirunote 0.7.1 a27ba8db13915143f42f3141933a8596d96b0f02ce906fedde9b81f42870039a
nirupres nirupres 2.4.0 ead8a48ec4d34b7f77d585ddb5ec98c9c6f9a8aa7ec273de8529dbee09e008a3
nplay nplay 1.8.2 5bd6dc17095648017ccf5922e342574ed596cc845ada78adbc5d5ff312d433d8
niruamp niruamp 0.5.2 d6623c81a23959eb3eb350e34f7203651b84a818a9896296d217ceaae55b65fe
niruflow niruflow 0.6.1 8c5611a3d719fb0ec6f0dc8f296ffde1b22e5d4aa9e6f600b5d5c76e8934a26e
nirusec nirusec 0.2.0 f3f7b85a1e0e3e91880721c060d24c50eadf843c602624eb8345bf8f3c5ae6d2
nirugame nirugame 0.1.4 96288834f2ca08c08b062f6f28142c079ee6c9c9198b9cdf085143deac719e54
niruremote niruremote 0.2.0 64571f661be436c1fb69b72439f7af69802d87c83ac1652c49b84f0cfd80f784
nirudictate nirudictate 0.3.0 49d4fa1987ca392e4763f8a1c16551b573c018e9d6a1cda7029c3bdeebeb77b2
EOF
}
# Extras that left the suite. Each is removed once with the uninstaller of
# its last pinned source: NIRUORG was replaced by NIRUFM (0.12.317).
extras_retired_table() {
  say 'niruorg niruorg 0.6.1 d012b5802fdf1253bb887c50395a2d611cd4958c43cad57650a0752bdefd1138'
}
extras_retire() {
  extras_retired_table | while read -r name repo version expected; do
    installed=$(extras_installed_version "$name" 2>/dev/null || :)
    if [ -z "$installed" ]; then
      extras_unselect "$name" >/dev/null 2>&1 || :
      continue
    fi
    say "$name left the suite (NIRUFM replaces it); removing it with its $version uninstaller."
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/nirux-extra.XXXXXX") || continue
    archive=$tmp/$repo.tar.gz
    if ! fetch "https://github.com/nirucon/$repo/archive/refs/tags/v$version.tar.gz" "$archive" ||
       [ "$(sha256sum "$archive" | awk '{print $1}')" != "$expected" ] ||
       ! tar -xzf "$archive" -C "$tmp"; then
      rm -rf "$tmp"; say "could not fetch the $name uninstaller; it stays installed"; continue
    fi
    src=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    extras_sudo_shim "$tmp"
    if [ -f "$src/uninstall.sh" ] && ( cd "$src" && extras_consent && PATH="$EXTRAS_SHIM_PATH$HOME/.local/bin:$PATH" bash ./uninstall.sh ); then
      extras_unselect "$name" >/dev/null 2>&1 || :
      say "Removed $name."
    else
      say "the $name uninstaller failed; it stays installed"
    fi
    rm -rf "$tmp"
  done
}
extras_row() {
  extras_table | awk -v n="$1" '$1 == n {print; found=1} END {exit found ? 0 : 1}'
}
extras_selected() {
  [ -f "$EXTRAS_SELECTED" ] && awk -v n="$1" '$1 == n {found=1} END {exit found ? 0 : 1}' "$EXTRAS_SELECTED"
}
extras_select() {
  name=$1
  extras_row "$name" >/dev/null || die "unknown extra: $name"
  mkdir -p "$STATE"
  touch "$EXTRAS_SELECTED"
  grep -qxF "$name" "$EXTRAS_SELECTED" 2>/dev/null || printf '%s\n' "$name" >> "$EXTRAS_SELECTED"
  LC_ALL=C sort -u "$EXTRAS_SELECTED" -o "$EXTRAS_SELECTED" 2>/dev/null || :
}
extras_unselect() {
  [ -f "$EXTRAS_SELECTED" ] || return 0
  awk -v n="$1" '$1 != n' "$EXTRAS_SELECTED" > "$EXTRAS_SELECTED.tmp.$$" &&
    mv -f "$EXTRAS_SELECTED.tmp.$$" "$EXTRAS_SELECTED" || {
      rm -f "$EXTRAS_SELECTED.tmp.$$"; die 'could not update extras selection'
    }
}
extras_installed_version() {
  name=$1
  bin=
  if [ -x "$HOME/.local/bin/$name" ]; then bin=$HOME/.local/bin/$name
  elif command -v "$name" >/dev/null 2>&1; then bin=$(command -v "$name")
  fi
  [ -n "$bin" ] || return 1
  "$bin" --version 2>/dev/null | awk 'NF {v=$NF} END {print v}'
}
extras_list() {
  printf '%-12s %-9s %-12s %s\n' NAME PINNED INSTALLED SELECTED
  extras_table | while read -r name _repo version _sha; do
    installed=$(extras_installed_version "$name" 2>/dev/null || :)
    selected=no
    extras_selected "$name" && selected=yes
    printf '%-12s %-9s %-12s %s\n' "$name" "$version" "${installed:--}" "$selected"
  done
}
# A vendor installer calls plain `sudo`. Without a terminal (a deployment
# script, a graphical update) that sudo cannot ask, so when NIRUX already holds
# the password it hands the installer a private `sudo` that answers through
# askpass from the secret file. The password never reaches argv or the
# environment; the shim lives in the extra's 0700 work directory and is removed
# with it. With no held password nothing changes and sudo asks as usual.
EXTRAS_SHIM_PATH=
extras_sudo_shim() {
  EXTRAS_SHIM_PATH=
  [ "$(id -u)" != 0 ] || return 0
  real_sudo=$(command -v sudo 2>/dev/null) || return 0
  # No `sudo -n` shortcut: a timestamp NIRUX created can be keyed to its own
  # process and still refuse the installer's sudo.
  if [ -z "${SUDO_SECRET:-}" ] && ! sudo_secret_file; then
    # No terminal and no password: every sudo the vendor installer runs fails
    # with "a terminal is required", and pam_faillock counts each of them.
    # Three extras in a row locked the account for ten minutes, the lock
    # screen included (seen on Arch). Answer such a sudo here instead, unless
    # sudo works without a password for this user.
    [ -t 0 ] && return 0
    mkdir -p "$1/.sudo" && chmod 700 "$1/.sudo" || return 0
    {
      printf '#!/bin/sh\n'
      printf '"%s" -n "$@" 2>/dev/null && exit 0\n' "$real_sudo"
      printf 'echo "nirux: this extra needs sudo, and there is no terminal to ask for the password." >&2\n'
      printf 'echo "nirux: run nirux extras install in a terminal." >&2\n'
      printf 'exit 1\n'
    } > "$1/.sudo/sudo" || return 0
    chmod 700 "$1/.sudo/sudo" || return 0
    EXTRAS_SHIM_PATH="$1/.sudo:"
    return 0
  fi
  if [ -z "${SUDO_SECRET_FILE:-}" ] || [ ! -f "$SUDO_SECRET_FILE" ]; then
    sudo_secret_keep "$SUDO_SECRET" >/dev/null 2>&1 || return 0
  fi
  mkdir -p "$1/.sudo" && chmod 700 "$1/.sudo" || return 0
  printf '#!/bin/sh\ncat "%s"\n' "$SUDO_SECRET_FILE" > "$1/.sudo/askpass" || return 0
  cat > "$1/.sudo/sudo" <<EOF || return 0
#!/bin/sh
for a in "\$@"; do
  case \$a in -S|--stdin|-A|--askpass) exec "$real_sudo" "\$@" ;; -*) ;; *) break ;; esac
done
SUDO_ASKPASS="$1/.sudo/askpass" exec "$real_sudo" -A "\$@"
EOF
  chmod 700 "$1/.sudo/sudo" "$1/.sudo/askpass" || return 0
  EXTRAS_SHIM_PATH="$1/.sudo:"
}
# Download the pinned source of an extra and verify it against the pin. Sets
# repo, version, tmp (the work directory to remove) and src (the unpacked tree).
extras_fetch() {
  row=$(extras_row "$1") || die "unknown extra: $1"
  repo=$(printf '%s\n' "$row" | awk '{print $2}')
  version=$(printf '%s\n' "$row" | awk '{print $3}')
  expected=$(printf '%s\n' "$row" | awk '{print $4}')
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/nirux-extra.XXXXXX") || die 'could not create extras work directory'
  archive=$tmp/$repo.tar.gz
  url="https://github.com/nirucon/$repo/archive/refs/tags/v$version.tar.gz"
  say "Downloading $repo $version ..."
  if ! fetch "$url" "$archive"; then rm -rf "$tmp"; die "could not download $repo $version"; fi
  actual=$(sha256sum "$archive" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then rm -rf "$tmp"; die "checksum mismatch for $repo $version; nothing changed"; fi
  if ! tar -xzf "$archive" -C "$tmp"; then rm -rf "$tmp"; die "could not unpack $repo $version"; fi
  src=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  [ -n "$src" ] || { rm -rf "$tmp"; die "$repo $version is empty"; }
}
# Asking for an extra is the consent to install its packages. With a terminal
# the vendor installer still asks as usual; without one (a deployment, a
# graphical update) it cannot ask, so it is told that the answer is yes.
extras_consent() {
  if [ -t 0 ]; then unset NIRUX_ASSUME_YES; else NIRUX_ASSUME_YES=1; export NIRUX_ASSUME_YES; fi
}
# Remove an extra with its own uninstaller from the pinned source, then forget
# the selection. `--purge` is passed on; an uninstaller without purge support
# keeps its data, as its README describes.
extras_uninstall() {
  purge=
  names=
  for argument in "$@"; do
    case "$argument" in
      --purge) purge=--purge ;;
      -*) die "unknown option: $argument" ;;
      *) names="$names $argument" ;;
    esac
  done
  [ -n "$names" ] || die 'usage: nirux extras uninstall NAME... [--purge]'
  for name in $names; do
    extras_row "$name" >/dev/null || die "unknown extra: $name"
    extras_fetch "$name"
    [ -f "$src/uninstall.sh" ] || { rm -rf "$tmp"; die "$repo $version has no uninstaller; see its README"; }
    say "Removing $name with its $version uninstaller${purge:+ (purge)}."
    extras_sudo_shim "$tmp"
    # shellcheck disable=SC2086 # purge is empty or one fixed word
    if ! ( cd "$src" && extras_consent && PATH="$EXTRAS_SHIM_PATH$HOME/.local/bin:$PATH" bash ./uninstall.sh $purge ); then
      rm -rf "$tmp"; die "$name uninstaller failed"
    fi
    rm -rf "$tmp"
    extras_unselect "$name"
    say "Removed $name; it is no longer selected for updates."
  done
}
extras_install_one() {
  name=$1
  extras_row "$name" >/dev/null || die "unknown extra: $name"
  # NIRUAMP is a graphical frontend, not a player. Keep the music pair coherent
  # by installing/updating NPLAY first when NIRUAMP is requested.
  # POSIX sh has no local variables: the recursive call below overwrites every
  # variable of this function, so nothing may be read before it and used after.
  if [ "$name" = niruamp ]; then
    nplay_pin=$(extras_row nplay | awk '{print $3}')
    nplay_now=$(extras_installed_version nplay 2>/dev/null || :)
    if [ "$nplay_now" != "$nplay_pin" ]; then
      extras_install_one nplay || die 'NIRUAMP requires NPLAY; NPLAY installation failed'
    fi
    name=niruamp
  fi
  extras_fetch "$name"
  [ -f "$src/install.sh" ] || { rm -rf "$tmp"; die "$repo $version has no installer"; }
  say "Installing $repo $version (the vendor installer may ask for confirmation)."
  extras_sudo_shim "$tmp"
  if ! ( cd "$src" && extras_consent && PATH="$EXTRAS_SHIM_PATH$HOME/.local/bin:$PATH" bash ./install.sh ); then rm -rf "$tmp"; die "$repo installer failed; existing data was not intentionally removed"; fi
  installed=$(extras_installed_version "$name" 2>/dev/null || :)
  if [ -z "$installed" ]; then rm -rf "$tmp"; die "$repo installed without a working $name command"; fi
  rm -rf "$tmp"
  extras_select "$name"
  say "Installed $name $installed"
}
extras_install() {
  if [ "$#" -eq 0 ]; then
    # shellcheck disable=SC2046
    set -- $(awk '{print $1}' "$EXTRAS_SELECTED" 2>/dev/null || :)
  fi
  [ "$#" -gt 0 ] || die 'select an extra first, or name one: nirux extras install niruflow'
  for name in "$@"; do extras_install_one "$name"; done
}
extras_update() {
  extras_retire
  [ -f "$EXTRAS_SELECTED" ] || die 'no extras selected'
  # Vendor installers may write their config and keys.d entries, so a round
  # that installs anything starts with a snapshot.
  extras_pending=
  while read -r name; do
    row=$(extras_row "$name" 2>/dev/null) || continue
    pinned=$(printf '%s\n' "$row" | awk '{print $3}')
    [ "$(extras_installed_version "$name" 2>/dev/null || :)" = "$pinned" ] || extras_pending="$extras_pending $name $pinned"
  done < "$EXTRAS_SELECTED"
  [ -z "$extras_pending" ] || snapshot_guard extras '' '' "extras update:$extras_pending"
  while read -r name; do
    [ -n "$name" ] || continue
    row=$(extras_row "$name") || continue
    pinned=$(printf '%s\n' "$row" | awk '{print $3}')
    installed=$(extras_installed_version "$name" 2>/dev/null || :)
    if [ "$installed" = "$pinned" ]; then say "$name $installed is current"; else extras_install_one "$name"; fi
  done < "$EXTRAS_SELECTED"
}
extras_command() {
  action=${1:-list}
  case "$action" in
    list|status) extras_list ;;
    select)
      [ "$#" = 2 ] || die 'usage: nirux extras select NAME'
      extras_select "$2"; say "selected $2" ;;
    unselect)
      [ "$#" = 2 ] || die 'usage: nirux extras unselect NAME'
      extras_unselect "$2"; say "unselected $2" ;;
    install) shift; extras_install "$@" ;;
    update) shift; extras_update ;;
    uninstall|remove) shift; extras_uninstall "$@" ;;
    *) die 'usage: nirux extras [list|status|select NAME|unselect NAME|install [NAME...]|uninstall NAME... [--purge]|update]' ;;
  esac
}

