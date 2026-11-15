owned() {
  grep -qxF "# NIRUX owner: $PREFIX" "$1" 2>/dev/null ||
    grep -q '^# NIRULOGIN owner:' "$1" 2>/dev/null ||
    grep -qxF "// NIRUX owner: $PREFIX" "$1" 2>/dev/null ||
    grep -qxF "/* NIRUX owner: $PREFIX */" "$1" 2>/dev/null
}
# A binary file cannot carry a comment: the header bytes would corrupt it and
# a PNG decoder would reject the icon. Ownership for such files is recorded in
# a sidecar beside the installed file instead, named by its SHA-256. A replaced
# file no longer matches and is therefore not removed.
owned_binary() {
  [ -f "$1" ] || return 1
  [ -f "$own_record" ] || return 1
  current=$(sha256sum "$1" | cut -d ' ' -f1)
  # The record is written by root; with a strict umask (077) it is not
  # readable by the user, so read it the same way it was written.
  grep -qxF "$current" "$own_record" 2>/dev/null || as_root grep -qxF "$current" "$own_record"
}
write_binary() {
  target=$1; source=$2
  own_record=$ROOT$(dirname "$target").nirux-owned/$(basename "$target").sha256
  if [ -f "$target" ]; then
    installed_sum=$(sha256sum "$target" | cut -d ' ' -f1)
    source_sum=$(sha256sum "$source" | cut -d ' ' -f1)
    [ "$installed_sum" != "$source_sum" ] || return 0
    # An unmodified NIRUX icon is replaced; anything else is preserved as a
    # backup first, exactly as write_system does for text files.
    if ! owned_binary "$target"; then
      [ -f "$target.nirux-backup" ] || as_root cp -p "$target" "$target.nirux-backup"
    fi
  fi
  as_root install -d -m 755 "$(dirname "$target")"
  as_root install -m 644 "$source" "$target"
  as_root install -d -m 755 "$(dirname "$own_record")"
  sha256sum "$source" | cut -d ' ' -f1 > "$WORK/own-record"
  as_root install -m 644 "$WORK/own-record" "$own_record"
}
remove_binary() {
  target=$1
  own_record=$ROOT$(dirname "$target").nirux-owned/$(basename "$target").sha256
  if [ -f "$target" ] && owned_binary "$target"; then
    if [ -f "$target.nirux-backup" ]; then as_root mv -f "$target.nirux-backup" "$target"
    else as_root rm -f "$target"
    fi
  fi
  if [ -f "$own_record" ]; then
    as_root rm -f "$own_record"
    as_root rmdir "$(dirname "$own_record")" 2>/dev/null || :
  fi
}
legacy_owned() {
  case "$1" in
    */xsessions/niruwm.desktop)
      grep -qxF "Exec=$BIN/niruwm-session" "$1" ||
        grep -qxF "Exec=\"$BIN/niruwm-session\"" "$1" ;;
    */pam.d/nirulock) grep -q '^# Installed by nirux\.' "$1" 2>/dev/null ;;
    *) return 1 ;;
  esac
}
# Are two files identical? `cmp` is not installed by default on every
# distribution NIRUX supports (Arch's coreutils leaves it out), so the check
# falls back to comparing the bytes with the shell tools that are always there.
same_file() {
  if command -v cmp >/dev/null 2>&1; then
    cmp -s "$1" "$2"
  else
    [ "$(sha256sum "$1" | cut -d ' ' -f1)" = "$(sha256sum "$2" | cut -d ' ' -f1)" ]
  fi
}
write_system() {
  target=$1; source=$2
  if [ -f "$target" ]; then
    # Some managed files, notably sudoers rules, are unreadable to the user.
    # Compare through the same privilege boundary used to install them.
    installed_sum=$(as_root sha256sum "$target" 2>/dev/null | cut -d ' ' -f1)
    source_sum=$(sha256sum "$source" | cut -d ' ' -f1)
    [ "$installed_sum" != "$source_sum" ] || return 0
  fi
  if [ -f "$target" ] && ! owned "$target" && ! legacy_owned "$target" &&
     ! as_root grep -qxF "# NIRUX owner: $PREFIX" "$target" 2>/dev/null; then
    if grep -q '^# NIRUX owner:' "$target" 2>/dev/null; then die "$target belongs to another NIRUX installation"; fi
    [ -f "$target.nirux-backup" ] || as_root cp -p "$target" "$target.nirux-backup"
  fi
  as_root install -d -m 755 "$(dirname "$target")"
  as_root install -m 644 "$source" "$target"
}
prepare_pam() {
  pam_source=$WORK/generation/pam
  for include in $(awk '$2 == "include" || $2 == "substack" {print $3}' "$pam_source"); do
    [ -f "$ROOT/etc/pam.d/$include" ] || die "PAM include $include is missing; install the distribution PAM packages"
  done
  { say "# NIRUX owner: $PREFIX"; cat "$pam_source"; } > "$WORK/pam"
  write_system "$ROOT/etc/pam.d/nirulock" "$WORK/pam"
}
