#!/bin/sh
# nirux snapshot / restore: what a snapshot holds and leaves out, the snapshot
# before an update (taken by the running installer or by the target), a failing
# snapshot that warns or (strict) stops, keep = N rotation, restore with
# --dry-run, the confirmation and the safety snapshot, and extras updates.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'chmod -R u+w "$TEST" 2>/dev/null; rm -rf "$TEST"' EXIT HUP INT TERM
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
export HOME="$TEST/home"
unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_DATA_HOME NIRUX_PREFIX NIRUX_SNAPSHOT_STRICT
mkdir -p "$HOME"
nirux() { sh "$SOURCE/nirux" "$@"; }
SNAPS=$HOME/.local/state/nirux/snapshots
C=$HOME/.config

# A configured desktop, with things a snapshot must leave out.
mkdir -p "$C/niruwm/themes" "$C/niru/quotes" "$C/niruui" "$C/nirux" "$C/nirushare" "$C/kitty" "$C/fish" \
  "$C/unrelated" "$HOME/.local/share/niru/keys.d" "$HOME/.local/state/nirulauncher" "$HOME/Music/SID" "$C/nirudictate"
printf 'theme = "nord"\n\n[monitors]\nworkspaces = 10\n' > "$C/niruwm/config.toml"
printf 'schema = 1\n' > "$C/niruwm/appearance.toml"
printf 'name = "Mine"\n' > "$C/niruwm/themes/mine.toml"
printf 'Cattle die.\n' > "$C/niru/quotes.txt"
printf 'Kinsmen die.\n' > "$C/niru/quotes/extra.txt"
printf 'layout = "cava"\n' > "$C/niruui/lock.toml"
printf '[sounds]\nenabled = true\n' > "$C/nirux/sounds.toml"
printf 'backend = "xrender";\n' > "$C/picom.conf"
printf 'shell fish\n' > "$C/kitty/kitty.conf"
printf 'set -g x 1\n' > "$C/fish/config.fish"
printf 'model = "sv"\n' > "$C/nirudictate/config.toml"
printf '[[keys]]\nkeys = "super+d"\n' > "$HOME/.local/share/niru/keys.d/nirudictate.toml"
printf 'firefox.desktop\n' > "$HOME/.local/state/nirulauncher/favorites.tsv"
printf 'firefox.desktop\t9\n' > "$HOME/.local/state/nirulauncher/usage.tsv"
printf '{"token": "abcdefghijklmnop"}\n' > "$C/nirushare/config.json"
printf 'api_key = "sk-abcdefghijklmnop"\n' > "$C/niruwm/weather.toml"
printf 'x\n' > "$C/nirux/github-token"
printf 'not ours\n' > "$C/unrelated/file"
printf 'SID\n' > "$HOME/Music/SID/1-Commando.sid"
snap_names() { for f in "$SNAPS"/*; do [ ! -e "$f" ] || printf '%s\n' "${f##*/}"; done; }
members() { tar -tzf "$1" | sed -n 's|^home/||p' | grep -v '/$' | LC_ALL=C sort; }

# --- manual snapshot -----------------------------------------------------------
nirux snapshot --note 'first try' > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'manual snapshot failed'; }
ID1=$(sed -n 's/^Snapshot: //p' "$TEST/out")
case "$ID1" in [0-9]*-manual) ;; *) fail "manual snapshot id: $ID1" ;; esac
[ -f "$SNAPS/$ID1.tar.gz" ] && [ -f "$SNAPS/$ID1.manifest" ] || fail 'snapshot files missing'
[ "$(stat -c %a "$SNAPS")" = 700 ] && [ "$(stat -c %a "$SNAPS/$ID1.tar.gz")" = 600 ] || fail 'snapshots must be private'
members "$SNAPS/$ID1.tar.gz" > "$TEST/members"
for f in .config/niruwm/config.toml .config/niruwm/appearance.toml .config/niruwm/themes/mine.toml \
  .config/niru/quotes.txt .config/niru/quotes/extra.txt .config/niruui/lock.toml .config/nirux/sounds.toml \
  .config/picom.conf .config/kitty/kitty.conf .config/fish/config.fish .config/nirudictate/config.toml \
  .local/share/niru/keys.d/nirudictate.toml .local/state/nirulauncher/favorites.tsv; do
  grep -qxF "$f" "$TEST/members" || fail "snapshot lacks $f"
done
for f in .config/nirushare/config.json .config/niruwm/weather.toml .config/nirux/github-token \
  .config/unrelated/file Music/SID/1-Commando.sid .local/state/nirulauncher/usage.tsv; do
  ! grep -qxF "$f" "$TEST/members" || fail "snapshot must not hold $f"
done
grep -q 'not included (secret): .config/niruwm/weather.toml' "$TEST/out" &&
  grep -q 'not included (secret): .config/nirux/github-token' "$TEST/out" &&
  grep -q 'not included (holds an upload token): .*nirushare' "$TEST/out" || { cat "$TEST/out"; fail 'exclusions not reported'; }
tar -xzOf "$SNAPS/$ID1.tar.gz" MANIFEST > "$TEST/manifest"
head -n 1 "$TEST/manifest" | grep -qx 'nirux-snapshot 1' && grep -qx 'note first try' "$TEST/manifest" &&
  grep -qx 'files 13' "$TEST/manifest" && grep -q '^bytes [0-9][0-9]*$' "$TEST/manifest" &&
  grep -q "^f	snapshot	[0-9a-f]\{64\}	13	.config/niru/quotes/extra.txt$" "$TEST/manifest" &&
  grep -q '^archive_bytes [0-9]' "$SNAPS/$ID1.manifest" || fail 'manifest content'
nirux snapshot list > "$TEST/out"
grep -q "^$ID1 .* 13 .*first try$" "$TEST/out" || { cat "$TEST/out"; fail 'snapshot list'; }
nirux snapshot --bogus > /dev/null 2>&1 && fail 'unknown snapshot option accepted'
nirux snapshot --help | grep -q 'nirux restore \[ID|latest\] \[--dry-run\]' || fail 'snapshot help'
nirux --help | grep -q 'nirux snapshot' || fail 'usage lists snapshot'

# --include-from adds files outside the usual set (sync uses it for music).
printf 'Music/SID/1-Commando.sid\n' > "$TEST/include"
nirux snapshot --include-from "$TEST/include" > "$TEST/out" 2>&1 || fail 'include snapshot failed'
ID2=$(sed -n 's/^Snapshot: //p' "$TEST/out")
members "$SNAPS/$ID2.tar.gz" | grep -qxF Music/SID/1-Commando.sid || fail '--include-from ignored'
printf '../etc/passwd\n' > "$TEST/include"
nirux snapshot --include-from "$TEST/include" > /dev/null 2>&1 && fail 'a path outside the home was accepted'

# --- restore -------------------------------------------------------------------
printf 'Cattle die, and kinsmen.\n' > "$C/niru/quotes.txt"
rm "$C/niruwm/themes/mine.toml"
printf 'name = "Newer"\n' > "$C/niruwm/themes/newer.toml"
cp -R "$C" "$TEST/before-restore"
nirux restore "$ID1" --dry-run > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'dry run failed'; }
grep -q 'restore   .config/niru/quotes.txt (+1 -1 lines)' "$TEST/out" &&
  grep -q 'recreate  .config/niruwm/themes/mine.toml (missing now)' "$TEST/out" &&
  grep -q 'keep      .config/niruwm/themes/newer.toml (newer than the snapshot; kept)' "$TEST/out" &&
  grep -q '^2 to restore, 11 unchanged, 1 newer files kept.$' "$TEST/out" &&
  grep -q 'Dry run: nothing was changed.' "$TEST/out" || { cat "$TEST/out"; fail 'dry run report'; }
diff -r "$C" "$TEST/before-restore" > /dev/null || fail 'dry run changed files'
[ "$(ls "$SNAPS"/*.tar.gz | wc -l)" = 2 ] || fail 'dry run took a snapshot'
printf 'n\n' | nirux restore "$ID1" > "$TEST/out" 2>&1 && fail 'declined restore must fail'
grep -q 'Cancelled; nothing was changed.' "$TEST/out" || fail 'cancel message'
diff -r "$C" "$TEST/before-restore" > /dev/null || fail 'declined restore changed files'
nirux restore "$ID1" < /dev/null > /dev/null 2>&1 && fail 'restore without an answer must not proceed'
printf 'y\n' | nirux restore "$ID1" > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'restore failed'; }
[ "$(cat "$C/niru/quotes.txt")" = 'Cattle die.' ] && [ -f "$C/niruwm/themes/mine.toml" ] || fail 'files not restored'
[ -f "$C/niruwm/themes/newer.toml" ] || fail 'restore removed a newer file'
SAFE=$(sed -n 's/.*Snapshot: //p' "$TEST/out")
case "$SAFE" in *-before-restore) ;; *) fail "safety snapshot id: $SAFE" ;; esac
[ "$(tar -xzOf "$SNAPS/$SAFE.tar.gz" home/.config/niru/quotes.txt)" = 'Cattle die, and kinsmen.' ] || fail 'safety snapshot does not hold the state before'
grep -q "note before restoring $ID1" "$SNAPS/$SAFE.manifest" || fail 'safety snapshot note'
grep -q 'niructl reload' "$TEST/out" && grep -q 'next lock or screensaver' "$TEST/out" || fail 'reload advice'
nirux restore latest --dry-run > "$TEST/out" 2>&1
grep -q "^Snapshot $SAFE$" "$TEST/out" || fail 'latest is the safety snapshot'
nirux restore "$ID1" --yes > "$TEST/out" 2>&1
grep -q 'already matches' "$TEST/out" || fail 'restore of the current state should do nothing'
nirux restore nosuch > /dev/null 2>&1 && fail 'unknown snapshot accepted'
nirux restore '../x' > /dev/null 2>&1 && fail 'invalid snapshot id accepted'
nirux restore manual --dry-run > /dev/null 2>&1 && fail 'an ambiguous id must be refused'

# --- keep = 3 ------------------------------------------------------------------
for n in 1 2 3 4; do nirux snapshot --note "round $n" > /dev/null 2>&1; done
[ "$(ls "$SNAPS"/*.tar.gz | wc -l)" = 3 ] && [ "$(ls "$SNAPS"/*.manifest | wc -l)" = 3 ] || fail 'default keep is 3'
nirux snapshot list > "$TEST/out"
[ "$(grep -c 'round [234]$' "$TEST/out")" = 3 ] || { cat "$TEST/out"; fail 'rotation must keep the newest'; }
printf '[snapshots]\nkeep = 2 # two\n' > "$C/nirux/snapshots.toml"
nirux snapshot > "$TEST/out" 2>&1
[ "$(ls "$SNAPS"/*.tar.gz | wc -l)" = 2 ] && grep -q 'keeping 2' "$TEST/out" || fail '[snapshots] keep'
printf '[snapshots]\nkeep = 0\n' > "$C/nirux/snapshots.toml"
nirux snapshot > /dev/null 2>&1
[ "$(ls "$SNAPS"/*.tar.gz | wc -l)" = 3 ] || fail 'an invalid keep falls back to 3'
rm -f "$C/nirux/snapshots.toml"

# --- before an update ------------------------------------------------------------
# The running installer: everything up to the hand-over to the target is
# stubbed; the fake target records whether it was told the snapshot is taken.
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nVERSION=0.12.243\n' > "$HOME/.local/bin/nirux"
cat > "$TEST/update.sh" <<'UPDATE'
NIRUX_LIBRARY=1
. "$SOURCE/nirux"
distro() { say debian; }
platform() { :; }
choose_browser() { BROWSER_EFFECTIVE=keep; }
browser_addon_choose() { :; }
choose_optional_apps() { :; }
icons_choose() { :; }
wallpaper_bundle_decision() { wp_decision=; }
stage_release() {
  RELEASE=0.13.0 APPLY_PROTOCOL=2 NIRUX_STAGE_COMPONENTS=0
  mkdir -p "$WORK/download/nirux"
  printf '#!/bin/sh\necho "target snapshot=${NIRUX_APPLY_SNAPSHOT:-}" >> "%s"\n' "$TEST/target.log" > "$WORK/download/nirux/nirux"
}
install_or_update update --no-packages
UPDATE
export SOURCE TEST
rm -f "$SNAPS"/*
sh "$TEST/update.sh" > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'update failed'; }
snap_names | grep -q '^[0-9]\{8\}-[0-9]\{6\}-0\.12\.243-to-0\.13\.0\.tar\.gz$' || { ls "$SNAPS"; fail 'update snapshot name'; }
grep -qx 'target snapshot=taken' "$TEST/target.log" || fail 'the target was not told about the snapshot'
grep -q 'Saving a snapshot of your NIRUX configuration' "$TEST/out" || fail 'update snapshot message'
# A failing snapshot warns and the update goes on ...
rm -rf "$SNAPS"; printf 'not a directory\n' > "$SNAPS"; : > "$TEST/target.log"
sh "$TEST/update.sh" > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'a failed snapshot blocked the update'; }
grep -q 'warning: no configuration snapshot was taken; continuing' "$TEST/out" && grep -q 'strict = true' "$TEST/out" || { cat "$TEST/out"; fail 'snapshot warning'; }
[ -s "$TEST/target.log" ] || fail 'update did not continue'
# ... unless snapshots are strict.
printf '[snapshots]\nstrict = true\n' > "$C/nirux/snapshots.toml"; : > "$TEST/target.log"
sh "$TEST/update.sh" > "$TEST/out" 2>&1 && fail 'strict snapshots must stop the update'
grep -q 'snapshot failed and snapshots are strict' "$TEST/out" && [ ! -s "$TEST/target.log" ] || fail 'strict stop'
rm -f "$C/nirux/snapshots.toml"
NIRUX_SNAPSHOT_STRICT=1 sh "$TEST/update.sh" > /dev/null 2>&1 && fail 'NIRUX_SNAPSHOT_STRICT=1 must stop the update'
rm -f "$SNAPS"
# The target installer takes the snapshot when the running one did not.
cat > "$TEST/apply.sh" <<'APPLY'
NIRUX_LIBRARY=1
. "$SOURCE/nirux"
operation=update RELEASE=0.13.0
apply_snapshot
APPLY
NIRUX_APPLY_SNAPSHOT=taken sh "$TEST/apply.sh" > /dev/null 2>&1
[ ! -d "$SNAPS" ] || [ -z "$(ls "$SNAPS")" ] || fail 'the target took a second snapshot'
sh "$TEST/apply.sh" > /dev/null 2>&1
snap_names | grep -q -- '-0\.12\.243-to-0\.13\.0\.tar\.gz$' || fail 'the target did not take the snapshot'

# --- extras update and reset-config ----------------------------------------------
cat > "$TEST/extras.sh" <<'EXTRAS'
NIRUX_LIBRARY=1
. "$SOURCE/nirux"
mkdir -p "$STATE"; printf 'nirudictate\n' > "$EXTRAS_SELECTED"
extras_installed_version() { cat "$TEST/dictate-version"; }
extras_install_one() { echo "installed $1" >> "$TEST/extras.log"; }
extras_update
EXTRAS
rm -rf "$SNAPS"
extras_pin=$(sh -c 'NIRUX_LIBRARY=1; . "$1"; extras_row nirudictate' sh "$SOURCE/nirux" | awk '{print $3}')
printf '%s\n' "$extras_pin" > "$TEST/dictate-version"
sh "$TEST/extras.sh" > "$TEST/out" 2>&1
[ ! -d "$SNAPS" ] || fail 'a current extras round must not take a snapshot'
printf '0.0.1\n' > "$TEST/dictate-version"
sh "$TEST/extras.sh" > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'extras update failed'; }
snap_names | grep -q -- '-extras\.tar\.gz$' && grep -q "note extras update: nirudictate $extras_pin" "$SNAPS"/*-extras.manifest || fail 'extras snapshot'
mkdir -p "$HOME/.local/share/nirux"; printf 'theme = "noir"\n' > "$HOME/.local/share/nirux/config.example.toml"
nirux reset-config > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'reset-config failed'; }
snap_names | grep -q -- '-reset-config\.tar\.gz$' || fail 'reset-config snapshot'

# --- rollback points to restore ----------------------------------------------------
S=$HOME/.local/share/nirux
mkdir -p "$S/generations/a/bin" "$S/generations/b/bin"
touch "$S/generations/a/bin/niruwm" "$S/generations/b/bin/niruwm"; chmod +x "$S/generations/a/bin/niruwm"
ln -s "$S/generations/b" "$S/current"; ln -s "$S/generations/a" "$S/previous"
nirux rollback > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail 'rollback failed'; }
grep -q 'nirux snapshot list and nirux restore' "$TEST/out" || fail 'rollback must mention restore'
echo 'snapshot: OK'
