
# ── nirux backup and nirux migrate (docs: manual chapter 11) ────────────────
# A backup is one file per run: the home directory as tar, compressed with
# zstd and encrypted with age to a public key, written to a folder that
# Nextcloud carries off the machine. Only the newest copies are kept per
# computer. A computer takes part only when its own backup.toml says
# enabled = true. Computers need only the public key to write a backup; the
# secret key, protected by a passphrase, lies in the Vault folder and is needed
# only to restore or to move to a new computer.
BACKUP_CONFIG=$NIRUX_CONFIG/backup.toml
BACKUP_LAST=${XDG_STATE_HOME:-$HOME/.local/state}/nirux/backup-last
# Paths in backup.toml may start with ~/ (the home directory).
# shellcheck disable=SC2088
BACKUP_DEFAULT_DEST='~/Nextcloud/Backup/nirux'
# shellcheck disable=SC2088
BACKUP_DEFAULT_KEY='~/Nextcloud/Vault/nirux-backup-key.age'
# Left out by default (paths relative to $HOME). The copy holds what makes the
# computer yours: settings, keys, notes and your own files. Browsers and chat
# apps keep their own sync or need a new login; games, music, films, downloads,
# Docker, ISO images, caches, programs and mail kept on a server can be fetched
# again. Directories with a CACHEDIR.TAG (Rust target/ and
# others) are left out too, and so is every Nextcloud folder.
BACKUP_EXCLUDES='.cache .local/share/Trash .local/share/nirux/generations .local/share/nirux/browsers
.local/share/nirux/opencode .local/share/nirux/localsend .local/share/Steam .steam
.local/share/umu .local/share/niruwebapp .local/share/niruflow/versions .local/share/flatpak
.local/share/containers .var .config/net.imput.helium .config/chromium .config/google-chrome
.config/BraveSoftware .mozilla .config/discord .config/Signal .rustup .cargo/registry .cargo/git
.npm .local/share/pnpm Games ISO snap Music Videos Movies Downloads Docker
.local/share/docker .local/share/lutris .local/share/bottles .local/share/heroic .wine'
# Never copied to a new computer: files that describe this machine's hardware
# or NIRUX installation rather than you.
MIGRATE_SKIP='.config/niruwm/displays.toml .config/nirux/backup.toml .local/state/wireplumber
.config/pulse .local/state/nirux .config/nirux/helium-flags .config/monitors.xml'

backup_usage() {
  say 'Usage: nirux backup [status]       this computer: on or off, last and next copy'
  say '       nirux backup setup          create or connect the key, then switch this computer on'
  say '       nirux backup now            make a copy now'
  say '       nirux backup run --auto     the nightly run: a copy only when one is due'
  say '       nirux backup list [HOST]    copies of every computer, or of HOST'
  say '       nirux backup restore [HOST|FILE] [--to DIR]   unpack a copy into DIR'
  say '       nirux backup off            this computer takes no more copies'
  say '       nirux migrate from HOST [--dry-run|--yes]   bring HOST'"'"'s settings, keys and files here'
  say "Settings: $BACKUP_CONFIG (enabled, every, keep, destination, key, exclude, include)."
}
backup_path() {
  # shellcheck disable=SC2088
  case "$1" in
    "~") say "$HOME" ;;
    "~/"*) say "$HOME/${1#??}" ;;
    *) say "$1" ;;
  esac
}
backup_value() {
  bv=$(toml_value "$BACKUP_CONFIG" backup "$1")
  if [ -n "$bv" ]; then say "$bv"; else say "$2"; fi
}
backup_enabled() { [ "$(backup_value enabled false)" = true ]; }
backup_dest() { backup_path "$(backup_value destination "$BACKUP_DEFAULT_DEST")"; }
backup_key() { backup_path "$(backup_value key "$BACKUP_DEFAULT_KEY")"; }
backup_host() { say "${NIRUX_BACKUP_HOST:-$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || say unknown)}"; }
backup_keep() {
  bk=$(backup_value keep 2)
  case "$bk" in ''|*[!0-9]*|0) say 2 ;; *) say "$bk" ;; esac
}
backup_every_seconds() {
  case "$(backup_value every weekly)" in daily) say 86400 ;; *) say 604800 ;; esac
}
backup_human() {
  awk -v b="${1:-0}" 'BEGIN { split("B KB MB GB TB", u); i = 1; while (b >= 1024 && i < 5) { b /= 1024; i++ }
    printf (i == 1 ? "%d %s\n" : "%.1f %s\n"), b, u[i] }'
}
backup_last_field() { awk -v k="$1" -F= '$1 == k { print substr($0, length(k) + 2) }' "$BACKUP_LAST" 2>/dev/null | tail -n 1; }
backup_copies() { # DIR: the copies in DIR, oldest first
  for bc_f in "$1"/*.tar.zst.age; do
    [ -f "$bc_f" ] && say "${bc_f##*/}"
  done | grep -E '^[A-Za-z0-9._-]+-[0-9]{8}-[0-9]{4,6}\.tar\.zst\.age$' | sort || :
}

backup_write_config() { # ENABLED RECIPIENT: keeps the other keys of an existing file
  mkdir -p "$NIRUX_CONFIG"
  if [ ! -f "$BACKUP_CONFIG" ]; then
    {
      say '# NIRUX backup (nirux backup --help, manual chapter 11).'
      say '# This computer takes part only when enabled = true.'
      say '[backup]'
      say 'enabled = false'
      say '# daily or weekly; the copy is made by the nightly run while you are away.'
      say 'every = "weekly"'
      say '# Copies kept for this computer; older ones are deleted.'
      say 'keep = 2'
      say "destination = \"$BACKUP_DEFAULT_DEST\""
      say "key = \"$BACKUP_DEFAULT_KEY\""
      say 'recipient = ""'
      say '# Files larger than this are left out.'
      say 'max_file_mb = 1024'
      say '# More paths to leave out, and paths to keep that the defaults leave out'
      say '# (relative to your home), for example exclude = [ "Pictures/raw" ] and'
      say '# include = [ "Games/Saves" ].'
      say 'exclude = [ ]'
      say 'include = [ ]'
    } > "$BACKUP_CONFIG"
  fi
  awk -v en="$1" -v rc="$2" '
    /^[[:space:]]*\[/ { sec = $0; gsub(/[][[:space:]]/, "", sec) }
    sec == "backup" && /^[[:space:]]*enabled[[:space:]]*=/ { print "enabled = " en; next }
    sec == "backup" && /^[[:space:]]*recipient[[:space:]]*=/ && rc != "" { print "recipient = \"" rc "\""; next }
    { print }' "$BACKUP_CONFIG" > "$BACKUP_CONFIG.$$" && mv -f "$BACKUP_CONFIG.$$" "$BACKUP_CONFIG"
}

backup_tools() { # make sure age and zstd exist (interactive: may use sudo)
  bt_missing=
  command -v age >/dev/null 2>&1 || bt_missing=age
  command -v zstd >/dev/null 2>&1 || bt_missing="$bt_missing zstd"
  bt_missing=${bt_missing# }
  [ -n "$bt_missing" ] || return 0
  [ "${1:-}" = install ] || { say "nirux backup: missing $bt_missing (run nirux backup setup)" >&2; return 1; }
  OS=${OS:-$(distro)}
  say "Installing $bt_missing ..."
  ( SUDO_SECRET_BORROWED=1; install_packages "$bt_missing" ) || die "could not install $bt_missing"
}

backup_setup() {
  [ -t 0 ] || die 'nirux backup setup asks questions: run it in a terminal'
  backup_tools install
  bs_key=$(backup_key) bs_pub="$(backup_key).pub"
  if [ -f "$bs_key" ] && [ -f "$bs_pub" ]; then
    bs_rcpt=$(grep -m 1 '^age1' "$bs_pub" || :)
    [ -n "$bs_rcpt" ] || die "no public key in $bs_pub"
    say "Using the backup key in $bs_key."
  elif [ -f "$bs_key" ]; then
    die "$bs_key exists but $bs_pub is missing; run nirux backup setup on a computer that has both"
  else
    [ -d "$(dirname "$bs_key")" ] || die "$(dirname "$bs_key") does not exist (is Nextcloud set up here?)"
    say 'Creating the backup key. It is protected by a passphrase that you choose now.'
    say 'Keep the passphrase safe: without it no copy can be restored.'
    # The secret key exists only in memory and, encrypted, in the key file.
    bs_secret=$(age-keygen 2>/dev/null) || die 'age-keygen failed'
    bs_rcpt=$(printf '%s\n' "$bs_secret" | age-keygen -y) || die 'could not read the new key'
    if ! printf '%s\n' "$bs_secret" | age -p -o "$bs_key.$$"; then
      bs_secret=; rm -f "$bs_key.$$"; die 'the key was not saved'
    fi
    bs_secret=
    chmod 600 "$bs_key.$$" && mv -f "$bs_key.$$" "$bs_key"
    say "$bs_rcpt" > "$bs_pub"
    say "Saved $bs_key (secret, passphrase-protected) and $bs_pub (public)."
  fi
  backup_write_config true "$bs_rcpt"
  say "This computer ($(backup_host)) now takes part: a copy $(backup_value every weekly) to $(backup_dest)/$(backup_host)."
  if nirux_confirm 'Make the first copy now? [y/N] '; then backup_now; fi
}

# Paths relative to the home, one per line, as tar member names (./path).
backup_rel_paths() { sed "s:^$HOME/*::; s:/*$::; s:^/*::" | grep -v '^$' | sed 's:^:./:' || :; }

# Paths in include are kept although a default or exclude leaves them out. An
# excluded folder that holds one is replaced by its other entries, level by
# level, so include = [ "Games/Saves" ] keeps the saves and none of the games.
backup_keep_includes() { # LIST
  toml_list "$BACKUP_CONFIG" backup include | backup_rel_paths > "$WORK/backup-include"
  while IFS= read -r ki; do
    while ke=$(awk -v p="$ki" '$0 == p || index(p, $0 "/") == 1 { print; exit }' "$1") && [ -n "$ke" ]; do
      awk -v e="$ke" '$0 != e' "$1" > "$1.new"
      if [ "$ke" != "$ki" ] && [ -d "$HOME/${ke#./}" ] && [ ! -L "$HOME/${ke#./}" ]; then
        kn=${ki#"$ke"/}; kn=${kn%%/*}
        for kc in "$HOME/${ke#./}"/* "$HOME/${ke#./}"/.[!.]* "$HOME/${ke#./}"/..?*; do
          [ -e "$kc" ] || [ -L "$kc" ] || continue
          [ "${kc##*/}" = "$kn" ] || say "$ke/${kc##*/}"
        done >> "$1.new"
      fi
      mv "$1.new" "$1"
    done
  done < "$WORK/backup-include"
}

# What tar leaves out: one member name per line (./path), matched exactly.
backup_exclude_list() { # OUT
  bl_max=$(backup_value max_file_mb 1024)
  case "$bl_max" in ''|*[!0-9]*) bl_max=1024 ;; esac
  {
    for bl_p in $BACKUP_EXCLUDES; do say "$bl_p"; done
    toml_list "$BACKUP_CONFIG" backup exclude
    # Every Nextcloud folder (already off the machine) and the destination.
    sed -n 's/^[0-9]*\\Folders\\[0-9]*\\localPath=//p' "${XDG_CONFIG_HOME:-$HOME/.config}/Nextcloud/nextcloud.cfg" 2>/dev/null || :
    say "$(backup_dest)"
    say Nextcloud
    # Thunderbird's copy of IMAP mail: the server keeps it. Local folders stay.
    for bl_p in "$HOME"/.thunderbird/*/ImapMail; do [ ! -d "$bl_p" ] || say "$bl_p"; done
  } | backup_rel_paths | sort -u > "$1"
  backup_keep_includes "$1"
  # Files larger than the limit, found outside the excluded paths.
  set -- "$1"
  bl_first=1
  while IFS= read -r bl_p; do
    if [ "$bl_first" = 1 ]; then set -- "$@" -path "$HOME/${bl_p#./}"; bl_first=0
    else set -- "$@" -o -path "$HOME/${bl_p#./}"; fi
  done < "$1"
  bl_out=$1; shift
  find "$HOME" -xdev \( "$@" \) -prune -o -type f -size +"${bl_max}"M -print 2>/dev/null |
    sed "s:^$HOME/:./:" > "$WORK/backup-too-large" || :
  cat "$WORK/backup-too-large" >> "$bl_out"
}

backup_now() {
  backup_enabled || die "this computer is not part of the backup: run nirux backup setup (or set enabled = true in $BACKUP_CONFIG)"
  backup_tools || return 1
  bn_rcpt=$(backup_value recipient '')
  case "$bn_rcpt" in age1*) ;; *) die "no recipient key in $BACKUP_CONFIG: run nirux backup setup" ;; esac
  bn_host=$(backup_host)
  bn_dir=$(backup_dest)/$bn_host
  [ -d "$(backup_dest)" ] || mkdir -p "$(backup_dest)" 2>/dev/null || die "cannot create $(backup_dest)"
  mkdir -p "$bn_dir" || die "cannot create $bn_dir"
  bn_lock=${XDG_RUNTIME_DIR:-/tmp}/nirux-backup.lock.$(id -u)
  mkdir "$bn_lock" 2>/dev/null || die 'a backup is already running'
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/nirux-backup.XXXXXX") || { rmdir "$bn_lock"; die 'no temporary directory'; }
  # shellcheck disable=SC2064
  trap "rm -rf '$WORK'; rmdir '$bn_lock' 2>/dev/null" EXIT HUP INT TERM
  backup_exclude_list "$WORK/exclude"
  bn_large=$(wc -l < "$WORK/backup-too-large" | tr -d ' ')
  bn_free=$(df -Pk "$bn_dir" | awk 'NR == 2 { print $4 }')
  [ "${bn_free:-0}" -gt 1048576 ] || die "less than 1 GB free in $bn_dir"
  bn_name=$bn_host-$(date +%Y%m%d-%H%M%S).tar.zst.age
  # Written as .part (Nextcloud does not upload those), then renamed in one step.
  bn_part=$bn_dir/$bn_name.part
  say "Backing up $HOME to $bn_dir ..."
  bn_nice=''
  command -v nice >/dev/null 2>&1 && bn_nice='nice -n 19'
  command -v ionice >/dev/null 2>&1 && bn_nice="$bn_nice ionice -c 3"
  bn_start=$(date +%s)
  # tar walks the home directory itself; unreadable files and files that
  # change while it reads are reported, not fatal. Its exit code is kept,
  # because only the last command of a pipeline sets the pipeline's.
  # shellcheck disable=SC2086
  { $bn_nice tar -C "$HOME" --one-file-system --exclude-caches-all --anchored --no-wildcards \
      --exclude-from="$WORK/exclude" --ignore-failed-read --totals -v --index-file="$WORK/index" \
      --warning=no-file-changed --warning=no-file-removed --warning=no-file-ignored \
      -cf - . 2>"$WORK/tar.err"; echo "$?" > "$WORK/tar.rc"; } |
    $bn_nice zstd -q -T2 -6 | age -r "$bn_rcpt" > "$bn_part"
  bn_rc=$?
  bn_tar=$(cat "$WORK/tar.rc" 2>/dev/null || say 9)
  if [ "$bn_rc" = 0 ] && [ "$bn_tar" -le 1 ] && [ -s "$bn_part" ]; then
    chmod 600 "$bn_part"; mv -f "$bn_part" "$bn_dir/$bn_name"
  else
    rm -f "$bn_part"
    mkdir -p "$(dirname "$BACKUP_LAST")"
    { say "time=$(date +%s)"; say 'result=failed'; say "error=$(grep -v '^Total bytes' "$WORK/tar.err" | head -n 1)"; } > "$BACKUP_LAST.tmp" && mv -f "$BACKUP_LAST.tmp" "$BACKUP_LAST"
    die "the backup failed (tar $bn_tar, pipe $bn_rc): $(grep -v '^Total bytes' "$WORK/tar.err" | head -n 3)"
  fi
  bn_count=$(grep -vc '/$' "$WORK/index" || :)
  bn_bytes=$(sed -n 's/^Total bytes written: \([0-9]*\).*/\1/p' "$WORK/tar.err" | tail -n 1)
  bn_unread=$(grep -c 'Cannot open\|Cannot read\|Cannot stat' "$WORK/tar.err" || :)
  bn_size=$(stat -c %s "$bn_dir/$bn_name")
  bn_keep=$(backup_keep)
  backup_copies "$bn_dir" | head -n "-$bn_keep" | while IFS= read -r bn_old; do
    rm -f "$bn_dir/$bn_old" && say "Removed the older copy $bn_old"
  done
  mkdir -p "$(dirname "$BACKUP_LAST")"
  { say "time=$(date +%s)"; say 'result=ok'; say "file=$bn_name"; say "size=$bn_size"; say "files=$bn_count"
    say "too_large=$bn_large"; say "seconds=$(( $(date +%s) - bn_start ))"; say "unreadable=$bn_unread"; say "bytes=${bn_bytes:-0}"; } > "$BACKUP_LAST.tmp" && mv -f "$BACKUP_LAST.tmp" "$BACKUP_LAST"
  say "Done: $bn_name, $(backup_human "$bn_size") from $(backup_human "${bn_bytes:-0}") in $bn_count files, $(( $(date +%s) - bn_start )) s."
  [ "$bn_large" = 0 ] || say "Left out $bn_large files larger than $(backup_value max_file_mb 1024) MB (max_file_mb)."
  [ "$bn_unread" = 0 ] || say "Could not read $bn_unread files (owned by another user)."
  rm -rf "$WORK"; rmdir "$bn_lock" 2>/dev/null; trap - EXIT HUP INT TERM
}

backup_due() {
  backup_enabled || return 1
  bd_last=$(backup_last_field time); bd_res=$(backup_last_field result)
  [ "$bd_res" = ok ] || bd_last=0
  [ $(( $(date +%s) - ${bd_last:-0} )) -ge $(( $(backup_every_seconds) - 7200 )) ]
}

backup_status() {
  if backup_enabled; then say "backup: on for $(backup_host), $(backup_value every weekly), keeping $(backup_keep)"
  else say "backup: off for $(backup_host) (nirux backup setup switches it on)"; fi
  say "destination: $(backup_dest)/$(backup_host)"
  bs_t=$(backup_last_field time)
  if [ -n "$bs_t" ]; then
    bs_days=$(( ($(date +%s) - bs_t) / 86400 ))
    if [ "$(backup_last_field result)" = ok ]; then
      say "last copy: $(backup_last_field file), $(backup_human "$(backup_last_field size)"), $bs_days days ago"
    else
      say "last run FAILED $bs_days days ago: $(backup_last_field error)"
    fi
  else
    say 'last copy: none yet'
  fi
  backup_copies "$(backup_dest)/$(backup_host)" | sed 's/^/  /'
  if backup_enabled && [ -n "$bs_t" ] && [ $(( $(date +%s) - bs_t )) -gt $(( 2 * $(backup_every_seconds) + 86400 )) ]; then
    say 'warning: the last good copy is old; the nightly run needs the computer on and locked at night, or run nirux backup now'
    return 1
  fi
}

backup_list() {
  bl_dest=$(backup_dest)
  [ -d "$bl_dest" ] || die "no backup folder at $bl_dest"
  for bl_h in "$bl_dest"/*/; do
    bl_h=${bl_h%/}; bl_n=${bl_h##*/}
    [ -z "${1:-}" ] || [ "$1" = "$bl_n" ] || continue
    backup_copies "$bl_h" | while IFS= read -r bl_f; do
      say "$bl_n  $bl_f  $(backup_human "$(stat -c %s "$bl_h/$bl_f")")"
    done
  done
}

# backup_open SOURCE DIR: decrypt and unpack the newest copy of host SOURCE
# (or the file SOURCE) into DIR. Asks for the key's passphrase.
backup_open() {
  backup_tools || return 1
  case "$1" in
    */*|*.age) bo_file=$1 ;;
    *) bo_file=$(backup_dest)/$1/$(backup_copies "$(backup_dest)/$1" | tail -n 1)
       [ -f "$bo_file" ] || die "no copy of $1 in $(backup_dest)/$1" ;;
  esac
  [ -f "$bo_file" ] || die "no such copy: $bo_file"
  bo_key=$(backup_key)
  [ -f "$bo_key" ] || die "the backup key is missing: $bo_key (is Nextcloud's Vault folder synced here?)"
  mkdir -p "$2" && chmod 700 "$2"
  say "Unpacking $(basename "$bo_file") into $2 (age asks for the key's passphrase) ..."
  age -d -i "$bo_key" "$bo_file" | zstd -dq | tar -xf - -C "$2" || die 'could not unpack the copy (wrong passphrase?)'
}

backup_restore() {
  br_src='' br_to=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --to) [ "$#" -ge 2 ] || die 'missing --to DIR'; br_to=$2; shift ;;
      -*) die "unknown restore option: $1" ;;
      *) br_src=$1 ;;
    esac
    shift
  done
  [ -n "$br_src" ] || br_src=$(backup_host)
  [ -n "$br_to" ] || br_to=$HOME/nirux-restore-$(basename "$br_src" .tar.zst.age)-$(date +%Y%m%d-%H%M)
  [ ! -e "$br_to" ] || [ -z "$(ls -A "$br_to" 2>/dev/null)" ] || die "$br_to is not empty"
  backup_open "$br_src" "$br_to"
  say "Restored into $br_to. Nothing in your home was changed; copy back what you need."
}

backup_command() {
  case "${1:-status}" in
    status) backup_status ;;
    setup|on) backup_setup ;;
    now) backup_now ;;
    run) [ "${2:-}" = --auto ] || die 'usage: nirux backup run --auto'
         if backup_due; then backup_now; else :; fi ;;
    list) backup_list "${2:-}" ;;
    restore) shift; backup_restore "$@" ;;
    off) backup_write_config false ''; say "Backup is off for $(backup_host); the copies already made are kept." ;;
    --help|-h|help) backup_usage ;;
    *) backup_usage >&2; exit 2 ;;
  esac
}

# nirux migrate from HOST: a new computer takes HOST's settings, keys and files
# from HOST's newest backup copy. Hardware-specific files are left out, every
# file it replaces is kept first, and NIRUX takes a snapshot before.
migrate_command() {
  [ "${1:-}" = from ] && [ -n "${2:-}" ] || die 'usage: nirux migrate from HOST [--dry-run|--yes]'
  mg_host=$2 mg_dry=0 mg_yes=0
  case "${3:-}" in --dry-run) mg_dry=1 ;; --yes) mg_yes=1 ;; '') ;; *) die "unknown migrate option: $3" ;; esac
  [ "$mg_host" != "$(backup_host)" ] || die "this computer is $mg_host; name the old computer"
  mg_stage=${XDG_CACHE_HOME:-$HOME/.cache}/nirux-migrate-$mg_host
  rm -rf "$mg_stage"
  # shellcheck disable=SC2064
  trap "rm -rf '$mg_stage'" EXIT HUP INT TERM
  backup_open "$mg_host" "$mg_stage"
  for mg_p in $MIGRATE_SKIP; do rm -rf "${mg_stage:?}/$mg_p"; done
  mg_list=$mg_stage.list
  ( cd "$mg_stage" && find . \( -type f -o -type l \) | sed 's:^\./::' ) > "$mg_list"
  mg_total=$(wc -l < "$mg_list" | tr -d ' ')
  mg_replace=$mg_stage.replace
  : > "$mg_replace"
  while IFS= read -r mg_f; do
    [ -e "$HOME/$mg_f" ] || [ -L "$HOME/$mg_f" ] || continue
    cmp -s "$HOME/$mg_f" "$mg_stage/$mg_f" || say "$mg_f" >> "$mg_replace"
  done < "$mg_list"
  mg_n=$(wc -l < "$mg_replace" | tr -d ' ')
  say "From $mg_host: $mg_total files; $mg_n would replace a different file here."
  say "Left out (this computer's own): $(echo $MIGRATE_SKIP | tr ' ' ',')"
  if [ "$mg_dry" = 1 ]; then sed 's/^/  replaces /' "$mg_replace" | head -n 30; rm -f "$mg_list" "$mg_replace"; return 0; fi
  if [ "$mg_yes" = 0 ]; then
    [ -t 0 ] || die 'nirux migrate asks before it copies: run it in a terminal, or add --yes'
    nirux_confirm "Copy them into $HOME now? [y/N] " || { rm -f "$mg_list" "$mg_replace"; say 'Nothing changed.'; return 0; }
  fi
  snapshot_create migrate '' '' "before migrate from $mg_host" '' >/dev/null 2>&1 || :
  mg_keep=${XDG_STATE_HOME:-$HOME/.local/state}/nirux/migrate-$(date +%Y%m%d-%H%M%S)
  if [ "$mg_n" -gt 0 ]; then
    mkdir -p "$mg_keep" && chmod 700 "$mg_keep"
    ( cd "$HOME" && tar --verbatim-files-from -cf - -T "$mg_replace" ) | tar -xf - -C "$mg_keep"
    say "Kept the $mg_n replaced files in $mg_keep"
  fi
  ( cd "$mg_stage" && tar --verbatim-files-from -cf - -T "$mg_list" ) | ( cd "$HOME" && tar -xpf - ) || die 'copying failed; your replaced files are in '"$mg_keep"
  rm -f "$mg_list" "$mg_replace"
  say "Copied $mg_total files from $mg_host."
  if [ -s "$EXTRAS_SELECTED" ]; then
    say "Extras chosen on $mg_host: $(tr '\n' ' ' < "$EXTRAS_SELECTED")"
    if [ "$mg_yes" = 0 ] && nirux_confirm 'Install them here now? [y/N] '; then extras_command install || :
    else say 'Install them with: nirux extras install'; fi
  fi
  say 'Still to do by hand:'
  say '  - log out and in once, so the session reads the new settings;'
  say "  - if your login password differs from $mg_host's, the keyring asks for the old one once;"
  say '    change it to the new one in Passwords and Keys (the seahorse package);'
  say '  - sign in to Nextcloud, and link Signal from your phone; Teams and the browser need a new login;'
  say '  - nirux backup setup, if this computer should take part in the backup.'
}
