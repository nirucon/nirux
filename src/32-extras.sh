extras_table() {
  cat <<'EOF'
nirunote nirunote 1.0.0 b76c2c10a60ec1a5b9563372f356b3203d9ca04aa90c81b6a92d95466b51b988
nirupres nirupres 3.1.0 52e1b4518b1898d441008f6fed340bc2a9f098de13e8b13df947021f53248808
nplay nplay 2.0.2 f22caba40677ef239f59062fdff6878421ccf3256f7f283f27ec24a533ab5177
niruamp niruamp 0.7.1 09435eb6cefc58633e5930dcca5de3f612db96415feb2ebc34fc65b441587d1a
niruflow niruflow 1.0.0 288ea78a0b4b6945624d1529c5581b74d13be9269057698e7fa4d5832496746c
nirusec nirusec 0.3.2 0d941c0bff02c6677b359ea31a7b54c62b5a93bde9c0e377001e314a48e40c5e
nirugame nirugame 0.3.0 0f671d1272a3c1e5b8c8d935f015009f95145cfba44d32da28c72db7899e1356
niruremote niruremote 0.2.0 64571f661be436c1fb69b72439f7af69802d87c83ac1652c49b84f0cfd80f784
nirudictate nirudictate 0.4.0 759cd574286b97291ac7f35cc923a1596deac0de3f92c9515e408fb8c46e7b21
docker-stacks docker-stacks 1.0.1 e6abbfe0edb1c9424e52e691d54ca9bf409fbdc6845706e83a8ccd95456a87e6
niruprodrive niruprodrive 0.1.6 b541754b2355e3c693a6d243a0b16d68e1d0e97185ae67ad5211a33301d44594
nirutoday nirutoday 0.1.1 04e795ef4e4098fd7f6eb6fe6fa3c723cd2f928449c5c6880fd504369989560f
nirusid nirusid 0.1.1 437b1b257dcfcdfe2ea64ffd96c8cca8b17d340114ef9ee19a0845139b92b940
nirusys nirusys 0.1.0 9566178199d5b839e6126d7ddfa371f88bcdd950f3019fdc19cf3f62ca53af78
nirusettings nirusettings 0.2.1 36d7d44adb88abc43e3e626437355b809f320f4c84d8e49b7e872eb04dfbac1d
nirux-thegame nirux-thegame 0.1.1 2f9737653d1cb2db06e3d9044c177eb041fa13dd77e0c587e6ece94e9a277d81
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
  # The first non-empty line names the version ("NIRUSID 0.1.1"); later
  # lines may describe libraries ("libsidplayfp 2.12.0 with reSIDfp"). The
  # whole output is read so the program never sees a closed pipe.
  "$bin" --version 2>/dev/null | awk 'NF && v == "" {v=$NF} END {print v}'
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

