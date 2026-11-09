#!/bin/sh
# nirux sync against a fake ssh whose hosts are local home directories:
# status per item, push and pull with preview and confirmation, the snapshot on
# the receiving side (and the backup on an older NIRUX), rsync and tar
# transfers, the theme key, exclusions, and hosts without access.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
FAKE=$TEST/fake
mkdir -p "$TEST/bin" "$FAKE/hosts"
export FAKE
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# ssh: HOST is a directory under $FAKE/hosts; "offline" times out, "denied"
# refuses the key. The command runs in that host's HOME and must never carry
# shell syntax: the login shell there is fish.
cat > "$TEST/bin/ssh" <<'SSH'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE/ssh.log"
while [ $# -gt 0 ]; do
  case "$1" in
    -o|-i|-l|-p) shift 2 ;;
    -*) shift ;;
    *) break ;;
  esac
done
host=$1; shift
case "$*" in
  *[\;\|\&\$\<\>\(\)\`\'\"\{\}\~\*]*) printf '%s\n' "$*" >> "$FAKE/violations"; exit 97 ;;
esac
d=$FAKE/hosts/$host
[ -d "$d" ] || { echo "ssh: Could not resolve hostname $host: Name or service not known" >&2; exit 255; }
case "$(cat "$d/mode" 2>/dev/null)" in
  offline) echo "ssh: connect to host $host port 22: Connection timed out" >&2; exit 255 ;;
  denied) echo "$host: Permission denied (publickey,password)." >&2; exit 255 ;;
esac
cd "$d/home" || exit 255
HOME=$d/home exec "$@"
SSH
cat > "$TEST/bin/tailscale" <<'TS'
#!/bin/sh
echo 'failed to connect to local tailscaled' >&2; exit 1
TS
chmod +x "$TEST/bin/"*
export PATH="$TEST/bin:$PATH" HOME="$TEST/home"
unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_DATA_HOME NIRUX_PREFIX NIRUX_SYNC_TRANSFER
mkdir -p "$HOME"
nirux() { sh "$SOURCE/nirux" "$@"; }
HAVE_RSYNC=0; command -v rsync >/dev/null 2>&1 && HAVE_RSYNC=1

# A desktop's settings under home $1.
settings() {
  mkdir -p "$1/.config/niru/quotes" "$1/.config/niruwm/themes" "$1/.config/niruui" "$1/.config/nirux" \
    "$1/.local/share/niru/keys.d" "$1/Music/SID" "$1/.local/state/nirulauncher"
  printf 'Cattle die.\n' > "$1/.config/niru/quotes.txt"
  printf 'theme = "%s"\nfont = 15\n\n[[monitors.profiles]]\nname = "%s-desk"\n' "$2" "$2" > "$1/.config/niruwm/config.toml"
  printf 'output = "%s-HDMI"\n' "$2" > "$1/.config/niruwm/displays.toml"
  printf 'layout = "cava"\n' > "$1/.config/niruui/lock.toml"
  printf '[sounds]\nenabled = true\n' > "$1/.config/nirux/sounds.toml"
  printf 'usage\t3\n' > "$1/.local/state/nirulauncher/usage.tsv"
}
# A remote NIRUX host: "new" runs this checkout, "old" predates snapshots.
make_host() {
  h=$FAKE/hosts/$1/home
  settings "$h" "$1"
  mkdir -p "$h/.local/bin"
  if [ "$2" = new ]; then ln -s "$SOURCE/nirux" "$h/.local/bin/nirux"
  else
    printf '#!/bin/sh\nVERSION=0.12.200\ncase "$1" in --version) echo "NIRUX 0.12.200" ;; *) echo "nirux: unknown command: $1" >&2; exit 1 ;; esac\n' > "$h/.local/bin/nirux"
    chmod +x "$h/.local/bin/nirux"
  fi
}
make_host alpha new
make_host bravo old
make_host carol new; printf 'denied\n' > "$FAKE/hosts/carol/mode"
make_host golf new; printf 'offline\n' > "$FAKE/hosts/golf/mode"
mkdir -p "$FAKE/hosts/foxtrot/home"
A=$FAKE/hosts/alpha/home
B=$FAKE/hosts/bravo/home
# This machine: a different quote, an own theme file, a key registration, a
# lock file with a secret, a SID tune that alpha lacks; alpha has one more.
settings "$HOME" here
printf 'Cattle die, kinsmen die.\n' > "$HOME/.config/niru/quotes.txt"
printf 'name = "Mine"\n' > "$HOME/.config/niruwm/themes/mine.toml"
printf '[[keys]]\nkeys = "super+d"\n' > "$HOME/.local/share/niru/keys.d/nirudictate.toml"
mkdir -p "$HOME/.config/nirulock"; printf 'password = "hunter2hunter2"\n' > "$HOME/.config/nirulock/unlock.toml"
printf 'TUNE1\n' > "$HOME/Music/SID/1-Commando.sid"
printf 'TUNE2\n' > "$A/Music/SID/2-ACE-II.sid"
printf '5a1 = 3:00\n' > "$A/Music/SID/Songlengths.md5"
printf 'Theirs.\n' > "$A/.config/niru/quotes/theirs.txt"
row() { awk -v i="$1" '$1 == i && $2 ~ /^[0-9]+$/ { sub(/^ +/, ""); print }' "$TEST/out"; }

# --- status --------------------------------------------------------------------
nirux sync status alpha > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'status failed'; }
grep -q '^Note: NIRUX is not installed on this machine' "$TEST/out" || fail 'non-NIRUX note'
grep -q '^== alpha (NIRUX 0.12.244, transfer: ' "$TEST/out" || { cat "$TEST/out"; fail 'status header'; }
grep -q '^  ITEM  *SAME  *CHANGED  *ONLY HERE  *ONLY THERE  *EXCLUDED  *HERE  *THERE$' "$TEST/out" || fail 'table header'
row quotes | grep -q '^quotes  *0  *1  *0  *1  *0 ' || { cat "$TEST/out"; fail "quotes row: $(row quotes)"; }
row keys.d | grep -q '^keys.d  *0  *0  *1  *0  *0 ' || fail "keys.d row: $(row keys.d)"
row theme | grep -q '^theme  *0  *1  *1  *0  *0 ' || fail "theme row (key, own theme file): $(row theme)"
row lock | grep -q '^lock  *1  *0  *0  *0  *1 ' || fail "lock row: $(row lock)"
row sounds | grep -q '^sounds  *1  *0  *0  *0  *0 ' || fail "sounds row: $(row sounds)"
row sid | grep -q '^sid  *0  *0  *1  *2  *0  *6 B  *17 B$' || fail "sid row: $(row sid)"
grep -q 'theme: here here, there alpha' "$TEST/out" || fail 'theme difference'
grep -q 'quotes  *changed  *.config/niru/quotes.txt' "$TEST/out" &&
  grep -q 'quotes  *only there .config/niru/quotes/theirs.txt' "$TEST/out" &&
  grep -q 'lock  *excluded  *.config/nirulock/unlock.toml (secret)' "$TEST/out" || { cat "$TEST/out"; fail 'difference list'; }
! grep -q 'displays.toml\|usage.tsv' "$TEST/out" || fail 'display profiles and state must not be compared'
! grep -q 'niruwm/config.toml' "$TEST/out" || fail 'config.toml must not be compared as a file'
nirux sync status bravo carol golf nowhere > "$TEST/out" 2>&1 || fail 'status of problem hosts must not fail'
grep -q '^== bravo (NIRUX 0.12.200' "$TEST/out" && grep -q '^== carol: no SSH key access (run nirux fleet setup carol)' "$TEST/out" &&
  grep -q '^== golf: not reachable' "$TEST/out" && grep -q '^== nowhere: not reachable' "$TEST/out" || { cat "$TEST/out"; fail 'problem hosts'; }
# From a machine without NIRUX, two hosts are compared with each other.
nirux sync status alpha bravo quotes > "$TEST/out" 2>&1 || fail 'two-host status failed'
grep -q 'comparing with alpha instead' "$TEST/out" && grep -q '^== bravo compared with alpha (NIRUX 0.12.200 and 0.12.244)' "$TEST/out" &&
  ! grep -q '^== alpha' "$TEST/out" && row quotes | grep -q '^quotes  *1  *0  *1  *0  *0 ' || { cat "$TEST/out"; fail 'two-host comparison'; }
nirux sync status alpha quotes > "$TEST/out" 2>&1
grep -q '^Items: quotes$' "$TEST/out" && [ -z "$(row sid)" ] || fail 'item selection'
# Every fleet host, from [fleet] hosts (Tailscale is not running here).
mkdir -p "$HOME/.config/nirux"
printf '[fleet]\nhosts = ["alpha", "carol", "golf", "foxtrot"]\n' > "$HOME/.config/nirux/fleet.toml"
nirux sync status > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'fleet-wide status failed'; }
grep -q '^== alpha (NIRUX' "$TEST/out" && grep -q '^== carol: no SSH key access' "$TEST/out" &&
  grep -q '^== golf: offline, skipped' "$TEST/out" && grep -q '^== foxtrot: no NIRUX, skipped' "$TEST/out" || { cat "$TEST/out"; fail 'fleet-wide status'; }
nirux sync items > "$TEST/out"
grep -q '^sid  *~/Music/SID' "$TEST/out" && grep -q 'Never synced: niruwm config.toml as a whole' "$TEST/out" || fail 'sync items'

# --- push ----------------------------------------------------------------------
cp -R "$A" "$TEST/alpha-before"
nirux sync push alpha quotes --dry-run > "$TEST/out" 2>&1 || fail 'push dry run failed'
grep -q '^== push to alpha' "$TEST/out" && grep -q 'quotes: 1 files, 25 B (1 replace a different file, 0 new)' "$TEST/out" &&
  grep -q 'Dry run: nothing was copied.' "$TEST/out" || { cat "$TEST/out"; fail 'push preview'; }
printf 'n\n' | nirux sync push alpha quotes > "$TEST/out" 2>&1 && fail 'declined push must fail'
nirux sync push alpha quotes < /dev/null > "$TEST/out" 2>&1 && fail 'push without an answer must not copy'
diff -r "$A" "$TEST/alpha-before" > /dev/null || fail 'a declined push changed alpha'
printf 'y\n' | nirux sync push alpha quotes theme keys.d lock > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'push failed'; }
[ "$(cat "$A/.config/niru/quotes.txt")" = 'Cattle die, kinsmen die.' ] || fail 'quote not pushed'
[ -f "$A/.config/niru/quotes/theirs.txt" ] || fail 'push deleted a file only alpha had'
[ -f "$A/.local/share/niru/keys.d/nirudictate.toml" ] && [ -f "$A/.config/niruwm/themes/mine.toml" ] || fail 'keys.d/theme files not pushed'
[ ! -e "$A/.config/nirulock/unlock.toml" ] || fail 'a secret was pushed'
grep -qx 'theme = "here"' "$A/.config/niruwm/config.toml" && grep -qx 'name = "alpha-desk"' "$A/.config/niruwm/config.toml" &&
  grep -qx 'font = 15' "$A/.config/niruwm/config.toml" || fail "theme key: $(cat "$A/.config/niruwm/config.toml")"
[ "$(cat "$A/.config/niruwm/displays.toml")" = 'output = "alpha-HDMI"' ] || fail 'display profile touched'
grep -q '^== alpha: snapshot [0-9-]*before-sync' "$TEST/out" && grep -q '^== alpha: theme set to here' "$TEST/out" &&
  grep -q '^== alpha: pushed 3 files' "$TEST/out" && grep -q 'niructl reload' "$TEST/out" || { cat "$TEST/out"; fail 'push report'; }
SNAP=$(ls "$A/.local/state/nirux/snapshots"/*-before-sync.tar.gz)
[ "$(tar -xzOf "$SNAP" home/.config/niru/quotes.txt)" = 'Cattle die.' ] &&
  tar -xzOf "$SNAP" home/.config/niruwm/config.toml | grep -qx 'theme = "alpha"' || fail 'the snapshot on alpha does not hold the state before'
grep -qx 'note sync from [A-Za-z0-9._-]*' "${SNAP%.tar.gz}.manifest" || fail 'remote snapshot note'
nirux sync push alpha quotes keys.d lock --yes > "$TEST/out" 2>&1
grep -q '^== alpha: already in sync' "$TEST/out" && grep -q '^Nothing to push.' "$TEST/out" || { cat "$TEST/out"; fail 'second push'; }
# An older NIRUX: the files to replace are tarred to a backup there first.
NIRUX_SYNC_TRANSFER=tar nirux sync push bravo quotes --yes > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'push to old NIRUX failed'; }
grep -q '^== push to bravo (tar)' "$TEST/out" && grep -q 'older NIRUX without snapshots; backed up' "$TEST/out" || { cat "$TEST/out"; fail 'old-remote report'; }
BK=$(ls "$B/.local/state/nirux/sync-backups"/*-before-sync.tar.gz)
[ "$(tar -xzOf "$BK" .config/niru/quotes.txt)" = 'Cattle die.' ] && [ "$(cat "$B/.config/niru/quotes.txt")" = 'Cattle die, kinsmen die.' ] || fail 'old-remote backup or tar push'
# --all: every online NIRUX host of the fleet.
printf 'Third.\n' > "$HOME/.config/niru/quotes.txt"
printf '[fleet]\nhosts = ["alpha", "bravo", "carol", "golf"]\n' > "$HOME/.config/nirux/fleet.toml"
nirux sync push --all quotes --yes > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'push --all failed'; }
[ "$(cat "$A/.config/niru/quotes.txt")" = Third. ] && [ "$(cat "$B/.config/niru/quotes.txt")" = Third. ] || fail 'push --all'
grep -q 'done: alpha bravo; failed: none' "$TEST/out" || { cat "$TEST/out"; fail 'push --all summary'; }
nirux sync push carol --yes > "$TEST/out" 2>&1
grep -q 'carol: no SSH key access' "$TEST/out" || fail 'push to a host without access'
nirux sync push foxtrot --yes > "$TEST/out" 2>&1
grep -q 'foxtrot: NIRUX is not installed there, skipped' "$TEST/out" || fail 'push to a host without NIRUX'
nirux sync push alpha --all > /dev/null 2>&1 && fail 'hosts and --all together accepted'
nirux sync push '-oProxyCommand=x' > /dev/null 2>&1 && fail 'option-like host accepted'

# --- pull ----------------------------------------------------------------------
for transfer in rsync tar; do
  [ "$transfer" = tar ] || [ "$HAVE_RSYNC" = 1 ] || { echo 'sync: rsync missing, rsync pull not tested'; continue; }
  rm -rf "$HOME/Music/SID"; mkdir -p "$HOME/Music/SID"; printf 'MINE\n' > "$HOME/Music/SID/2-ACE-II.sid"
  rm -rf "$HOME/.local/state/nirux/snapshots"
  NIRUX_SYNC_TRANSFER=$transfer nirux sync pull alpha sid --dry-run > "$TEST/out" 2>&1
  grep -q "^== pull from alpha ($transfer)" "$TEST/out" && grep -q 'sid: 2 files, 17 B (1 replace a different file, 1 new)' "$TEST/out" || { cat "$TEST/out"; fail "pull preview ($transfer)"; }
  [ "$(cat "$HOME/Music/SID/2-ACE-II.sid")" = MINE ] || fail 'pull dry run changed files'
  printf 'y\n' | NIRUX_SYNC_TRANSFER=$transfer nirux sync pull alpha sid theme > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail "pull failed ($transfer)"; }
  [ "$(cat "$HOME/Music/SID/2-ACE-II.sid")" = TUNE2 ] && [ -f "$HOME/Music/SID/Songlengths.md5" ] || fail "sid not pulled ($transfer)"
  LS=$(ls "$HOME/.local/state/nirux/snapshots"/*-before-sync.tar.gz)
  [ "$(tar -xzOf "$LS" home/Music/SID/2-ACE-II.sid)" = MINE ] || fail "local snapshot lacks the replaced tune ($transfer)"
  grep -qx 'theme = "here"' "$HOME/.config/niruwm/config.toml" || fail 'pull changed the theme though alpha has ours now'
done
sed 's/^theme = .*/theme = "nord"/' "$A/.config/niruwm/config.toml" > "$TEST/c" && cat "$TEST/c" > "$A/.config/niruwm/config.toml"
nirux sync pull alpha theme --yes > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'theme pull failed'; }
grep -qx 'theme = "nord"' "$HOME/.config/niruwm/config.toml" && grep -qx 'name = "here-desk"' "$HOME/.config/niruwm/config.toml" || fail 'theme pull'
nirux sync pull alpha bravo > /dev/null 2>&1 && fail 'pull from two hosts accepted'
nirux sync pull carol --yes > "$TEST/out" 2>&1 && fail 'pull from a host without access must fail'

# --- configuration: items and exclude --------------------------------------------
printf 'Fourth.\n' > "$HOME/.config/niru/quotes.txt"
printf 'Fourth theirs.\n' > "$HOME/.config/niru/quotes/theirs.txt"
printf '[sync]\nitems = ["quotes", "sounds", "bogus"]\nexclude = ["sounds", "~/.config/niru/quotes/"]\n' > "$HOME/.config/nirux/sync.toml"
nirux sync push alpha --yes > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'configured push failed'; }
grep -q '^Items: quotes$' "$TEST/out" && grep -q 'ignoring unknown item in .*sync.toml: bogus' "$TEST/out" || { cat "$TEST/out"; fail 'configured items'; }
[ "$(cat "$A/.config/niru/quotes.txt")" = Fourth. ] && [ "$(cat "$A/.config/niru/quotes/theirs.txt")" = Theirs. ] || fail 'path exclude'
[ ! -f "$FAKE/violations" ] || fail "a remote command contained shell syntax: $(cat "$FAKE/violations")"
! grep -v -e '-o BatchMode=yes -o ConnectTimeout=5 ' "$FAKE/ssh.log" || fail 'every sync ssh must use BatchMode'
mkdir -p "$HOME/.local/bin"; ln -s "$SOURCE/nirux" "$HOME/.local/bin/nirux"
nirux sync status alpha bravo > "$TEST/out" 2>&1
! grep -q '^Note:' "$TEST/out" && grep -q '^== alpha (NIRUX' "$TEST/out" && grep -q '^== bravo (NIRUX' "$TEST/out" || { cat "$TEST/out"; fail 'status on a NIRUX machine'; }
nirux sync bogus > /dev/null 2>&1 && fail 'unknown sync command accepted'
nirux sync --help | grep -q 'nirux sync push HOST' || fail 'sync help'
nirux --help | grep -q 'nirux sync' || fail 'usage lists sync'
echo 'sync: OK'
