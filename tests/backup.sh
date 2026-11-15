#!/bin/sh
# NIRUX 0.12.280-0.12.283: nirux backup and nirux migrate. A computer takes part only
# when backup.toml says so; a copy is one encrypted, compressed file; the
# newest copies are kept; what is left out stays out; restore never touches the
# home directory; migrate leaves this computer's own files alone and keeps
# every file it replaces.
# Offline: needs age and zstd; nothing outside a temporary HOME is touched.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
for tool in age age-keygen zstd tar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP backup: $tool is missing"; exit 0; }
done
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
N="$SOURCE/nirux"
use_home() { # HOME of a computer named $1
  export HOME="$TEST/$1" NIRUX_BACKUP_HOST="$1"
  export XDG_CONFIG_HOME="$HOME/.config" XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
  export XDG_RUNTIME_DIR="$TEST/run-$1" NIRUX_PREFIX="$HOME/.local"
  mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
}
DEST=$TEST/cloud/Backup/nirux KEY=$TEST/cloud/Vault/key
mkdir -p "$DEST" "$TEST/cloud/Vault"
age-keygen -o "$KEY" 2>/dev/null
RCPT=$(age-keygen -y "$KEY")

use_home old
# 1. Off until the computer's own file says otherwise.
if out=$(sh "$N" backup now 2>&1); then fail "a copy was made without opting in: $out"; fi
printf '%s\n' "$out" | grep -q 'not part of the backup' || fail "unclear refusal: $out"
sh "$N" backup run --auto || fail 'the nightly run fails on a computer that is off'
[ -z "$(ls -A "$DEST")" ] || fail 'the nightly run made a copy on a computer that is off'
echo 'OK   a computer takes part only after it opts in'

# 2. Contents: kept and left out.
mkdir -p "$HOME/.config/nirux" "$HOME/.config/niruwm" "$HOME/Documents" "$HOME/.ssh" "$HOME/.cache/x" \
  "$HOME/Games/g" "$HOME/Git/p/target" "$HOME/Nextcloud/n" "$HOME/.config/net.imput.helium/Default" \
  "$HOME/.local/share/nirux/generations/a" "$HOME/.local/share/keyrings" "$HOME/Videos" "$HOME/Pictures/raw"
echo note > "$HOME/Documents/note.txt"
echo 'id key' > "$HOME/.ssh/id_ed25519"; chmod 600 "$HOME/.ssh/id_ed25519"
echo keyring > "$HOME/.local/share/keyrings/login.keyring"
echo cache > "$HOME/.cache/x/c"; echo game > "$HOME/Games/g/save"
echo 'Signature: 8a477f597d28d172789f06886806bc55' > "$HOME/Git/p/target/CACHEDIR.TAG"; echo obj > "$HOME/Git/p/target/o"
echo src > "$HOME/Git/p/main.rs"; echo cloud > "$HOME/Nextcloud/n/f"; echo web > "$HOME/.config/net.imput.helium/Default/h"
echo gen > "$HOME/.local/share/nirux/generations/a/bin"; printf 'niruamp\n' > "$HOME/.local/share/nirux/extras-selected"
echo 'monitors here' > "$HOME/.config/niruwm/displays.toml"; echo 'theme = "noir"' > "$HOME/.config/niruwm/theme-preferences.toml"
echo video > "$HOME/Videos/clip"; echo raw > "$HOME/Pictures/raw/r"
mkdir -p "$HOME/Games/Saves/w3" "$HOME/Music" "$HOME/Docker/img" "$HOME/Downloads" "$HOME/.thunderbird/p/ImapMail/srv"
echo save > "$HOME/Games/Saves/w3/slot1"; echo rom > "$HOME/Games/.rom"; echo song > "$HOME/Music/song"
echo layer > "$HOME/Docker/img/l"; echo dl > "$HOME/Downloads/f"; echo prefs > "$HOME/.thunderbird/p/prefs.js"
echo mail > "$HOME/.thunderbird/p/ImapMail/srv/INBOX"
head -c 1100000 /dev/zero > "$HOME/Documents/large.bin"
cat > "$HOME/.config/nirux/backup.toml" <<EOF
[backup]
enabled = true
every = "weekly"
keep = 2
what = "home"
destination = "$DEST"
key = "$KEY"
recipient = "$RCPT"
max_file_mb = 1
exclude = [ "Pictures/raw" ]
include = [ "Games/Saves" ]
EOF
out=$(sh "$N" backup now 2>&1) || fail "backup failed: $out"
printf '%s\n' "$out" | grep -q '^Done: old-' || fail "no done line: $out"
printf '%s\n' "$out" | grep -q 'Left out 1 files larger than 1 MB' || fail "the large file is not reported: $out"
copies=$(ls "$DEST/old")
[ "$(printf '%s\n' "$copies" | grep -c '\.tar\.zst\.age$')" = 1 ] || fail "expected one copy: $copies"
copy=$DEST/old/$copies
[ "$(stat -c %a "$copy")" = 600 ] || fail 'the copy is readable by others'
head -c 21 "$copy" | grep -q 'age-encryption.org' || fail 'the copy is not an age file'
age -d -i "$KEY" "$copy" | zstd -dq | tar -tf - > "$TEST/members"
for keep in ./Documents/note.txt ./.ssh/id_ed25519 ./.local/share/keyrings/login.keyring ./Git/p/main.rs \
  ./.local/share/nirux/extras-selected ./.config/niruwm/displays.toml ./Games/Saves/w3/slot1 ./.thunderbird/p/prefs.js; do
  grep -qx "$keep" "$TEST/members" || fail "missing from the copy: $keep"
done
for out_ in ./.cache/x/c ./Games/g/save ./Git/p/target/o ./Nextcloud/n/f ./.config/net.imput.helium/Default/h \
  ./.local/share/nirux/generations/a/bin ./Videos/clip ./Pictures/raw/r ./Documents/large.bin ./Games/.rom ./Music/song \
  ./Docker/img/l ./Downloads/f ./.thunderbird/p/ImapMail/srv/INBOX; do
  grep -qx "$out_" "$TEST/members" && fail "in the copy but should be left out: $out_"
done
echo 'OK   one encrypted copy; settings, keys, files and included saves kept; caches, games, music, Docker, IMAP mail, browsers, Nextcloud and large files left out'

# 3. Not due again right away; three copies leave the newest two.
sh "$N" backup run --auto >/dev/null || fail 'the nightly run failed'
[ "$(ls "$DEST/old" | wc -l)" = 1 ] || fail 'a copy was made although none was due'
sleep 1; sh "$N" backup now >/dev/null; sleep 1; sh "$N" backup now >/dev/null
left=$(ls "$DEST/old")
[ "$(printf '%s\n' "$left" | wc -l)" = 2 ] || fail "keep = 2 left: $left"
printf '%s\n' "$left" | grep -qx "$copies" && fail 'the oldest copy was kept'
for part in "$DEST"/old/*.part; do [ ! -e "$part" ] || fail 'a partial file was left behind'; done
sh "$N" backup status | grep -q '^backup: on for old' || fail 'status does not say on'
echo 'OK   the nightly run waits until a copy is due; only the newest two are kept'

# 4. Restore unpacks into a new directory and leaves the home alone.
echo changed > "$HOME/Documents/note.txt"
sh "$N" backup restore old --to "$TEST/restored" >/dev/null 2>&1 || fail 'restore failed'
[ "$(cat "$TEST/restored/Documents/note.txt")" = note ] || fail 'restored file has the wrong content'
[ "$(cat "$HOME/Documents/note.txt")" = changed ] || fail 'restore changed the home directory'
echo 'OK   restore unpacks into its own directory'

# 4b. The default copy holds settings, keys and mail settings, not data.
sed -i '/^what = /d' "$HOME/.config/nirux/backup.toml"
mkdir -p "$HOME/.config/emu.bak-20261103/cores"; echo core > "$HOME/.config/emu.bak-20261103/cores/c"
echo old > "$HOME/.config/niruwm/config.toml.bak"; echo old > "$HOME/.config/niruwm/theme-preferences.toml.bak-20261101"
echo old > "$HOME/.config/picom.conf~"; echo log > "$HOME/.config/LOG.old"
echo 'alias ll="ls -l"' > "$HOME/.bashrc"; mkdir -p "$HOME/.local/bin"; echo '#!/bin/sh' > "$HOME/.local/bin/mine"
sh "$N" backup status | grep -q 'settings$' || fail 'status does not name the default'
out=$(sh "$N" backup now 2>&1) || fail "settings backup failed: $out"
newest=$(ls "$DEST/old" | tail -n 1)
age -d -i "$KEY" "$DEST/old/$newest" | zstd -dq | tar -tf - > "$TEST/members"
for keep in ./.config/niruwm/theme-preferences.toml ./.ssh/id_ed25519 ./.local/share/keyrings/login.keyring \
  ./.local/share/nirux/extras-selected ./.thunderbird/p/prefs.js ./.bashrc ./.local/bin/mine ./Games/Saves/w3/slot1; do
  grep -qx "$keep" "$TEST/members" || fail "missing from the settings copy: $keep"
done
for out_ in ./Documents/note.txt ./Git/p/main.rs ./Pictures/raw/r ./Music/song ./.thunderbird/p/ImapMail/srv/INBOX \
  ./.config/net.imput.helium/Default/h ./.local/share/nirux/generations/a/bin ./Games/.rom \
  ./.config/emu.bak-20261103/cores/c ./.config/niruwm/config.toml.bak ./.config/picom.conf~ ./.config/LOG.old \
  ./.config/niruwm/theme-preferences.toml.bak-20261101; do
  grep -qx "$out_" "$TEST/members" && fail "in the settings copy but should be left out: $out_"
done
echo 'OK   the default copy holds settings, keys, NIRUX and mail settings and the include list, no data or backup files'

# 5. Migrate to a new computer.
use_home new
mkdir -p "$HOME/.config/niruwm" "$HOME/Documents" "$HOME/.config/nirux"
echo 'new monitors' > "$HOME/.config/niruwm/displays.toml"
echo 'theme = "light"' > "$HOME/.config/niruwm/theme-preferences.toml"
printf '[backup]\nenabled = false\ndestination = "%s"\nkey = "%s"\n' "$DEST" "$KEY" > "$HOME/.config/nirux/backup.toml"
if sh "$N" migrate from old >/dev/null 2>&1 < /dev/null; then fail 'migrate copied without a question or --yes'; fi
sh "$N" migrate from old --dry-run > "$TEST/dry" 2>&1 || fail "dry run failed: $(cat "$TEST/dry")"
grep -q 'replaces .config/niruwm/theme-preferences.toml' "$TEST/dry" || fail "dry run does not show the replaced file: $(cat "$TEST/dry")"
[ "$(cat "$HOME/.config/niruwm/theme-preferences.toml")" = 'theme = "light"' ] || fail 'the dry run changed a file'
sh "$N" migrate from old --yes > "$TEST/mig" 2>&1 || fail "migrate failed: $(cat "$TEST/mig")"
[ "$(cat "$HOME/.config/niruwm/theme-preferences.toml")" = 'theme = "noir"' ] || fail 'settings were not brought over'
[ "$(cat "$HOME/.ssh/id_ed25519")" = 'id key' ] || fail 'keys were not brought over'
[ "$(stat -c %a "$HOME/.ssh/id_ed25519")" = 600 ] || fail 'the key lost its permissions'
[ "$(cat "$HOME/.config/niruwm/displays.toml")" = 'new monitors' ] || fail "this computer's display settings were replaced"
grep -q 'enabled = false' "$HOME/.config/nirux/backup.toml" || fail "this computer's backup choice was replaced"
kept=$(find "$HOME/.local/state/nirux" -path '*migrate-*/.config/niruwm/theme-preferences.toml' | head -n 1)
[ -n "$kept" ] && [ "$(cat "$kept")" = 'theme = "light"' ] || fail 'the replaced file was not kept'
[ ! -e "$HOME/.cache/nirux-migrate-old" ] || fail 'the unpacked copy was left in the cache'
grep -q 'nirux extras install' "$TEST/mig" || fail 'the extras of the old computer are not mentioned'
echo 'OK   migrate brings settings and keys, keeps this computer'"'"'s own files and every replaced file'

# 6. Off again.
use_home old
sh "$N" backup off >/dev/null
grep -q '^enabled = false' "$HOME/.config/nirux/backup.toml" || fail 'off did not switch it off'
grep -q "^recipient = \"$RCPT\"" "$HOME/.config/nirux/backup.toml" || fail 'off lost the key'
echo 'OK   off keeps the key and the copies'
echo 'PASS backup'
