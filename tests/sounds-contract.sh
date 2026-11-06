#!/bin/sh
# Event and per-app notification sounds. No audio device, X server or network.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

HOME=$TEST/home
XDG_CONFIG_HOME=$HOME/.config
NIRUX_PREFIX=$TEST/prefix
export HOME XDG_CONFIG_HOME NIRUX_PREFIX
unset NIRUX_SOUNDS NIRUX_SUDO_PASSWORD NIRUX_SUDO_SECRET_FILE 2>/dev/null || :
SOUNDS=$NIRUX_PREFIX/share/nirux/sounds
CONFIG=$XDG_CONFIG_HOME/nirux/sounds.toml
LOG=$TEST/played
mkdir -p "$HOME" "$SOUNDS" "$TEST/bin"
for name in startup notification update shutdown mail chat auth-fail lock unlock \
  volume-up volume-down volume-limit mute unmute brightness-up brightness-down screenshot \
  power-plug power-unplug battery-low battery-critical battery-full device-connect device-disconnect; do
  printf 'OggS %s\n' "$name" > "$SOUNDS/$name.ogg"
done
mkdir -p "$SOUNDS/levels"
for level in 000 010 020 030 040 050 060 070 080 090 100; do
  printf 'OggS up %s\n' "$level" > "$SOUNDS/levels/volume-up-$level.ogg"
  printf 'OggS down %s\n' "$level" > "$SOUNDS/levels/volume-down-$level.ogg"
done

# A fake player records the file it was asked to play; a fake wpctl reports an
# unmuted sink so the host's real mute state cannot change the result.
cat > "$TEST/bin/pw-play" <<'EOF'
#!/bin/sh
for arg do last=$arg; done
printf '%s\n' "$last" >> "$PLAYED_LOG"
EOF
cat > "$TEST/bin/wpctl" <<'EOF'
#!/bin/sh
printf 'Volume: 0.50\n'
EOF
chmod +x "$TEST/bin/pw-play" "$TEST/bin/wpctl"
PATH=$TEST/bin:$PATH
PLAYED_LOG=$LOG
export PATH PLAYED_LOG

nirux() { sh "$SOURCE/nirux" "$@"; }

# The player runs in the background; wait briefly for its line.
played() {
  i=0
  while [ "$i" -lt 40 ]; do
    [ -s "$LOG" ] && break
    i=$((i + 1)); sleep 0.05
  done
  sleep 0.05
  result=$(tail -n 1 "$LOG" 2>/dev/null || :)
  : > "$LOG"
  printf '%s' "$result"
}
expect() {
  label=$1 want=$2
  got=$(played)
  [ "$got" = "$want" ] || fail "$label: expected '${want:-silence}', got '${got:-silence}'"
}
nothing() {
  sleep 0.3
  [ ! -s "$LOG" ] || fail "$1: expected silence, played $(cat "$LOG")"
}
reset_cooldowns() { rm -f "$SOUNDS"/.notification-stamp*; }

# A new configuration has the per-app defaults.
nirux sounds status > "$TEST/status"
grep -q '^\[sounds\.apps\]' "$CONFIG" || fail 'new config has no [sounds.apps]'
grep -q '^thunderbird = "mail"' "$CONFIG" || fail 'new config has no Thunderbird mapping'
grep -q '^signal = "chat"' "$CONFIG" || fail 'new config has no Signal mapping'
grep -q 'signal = chat' "$TEST/status" || fail 'status does not list app sounds'

# App names are matched case-insensitively, as nirunotify sends them.
nirux sounds play notification --app Thunderbird; expect thunderbird "$SOUNDS/mail.ogg"
nirux sounds play notification --app Signal; expect 'signal right after mail' "$SOUNDS/chat.ogg"
nirux sounds play notification --app kitty; expect 'unmapped app' "$SOUNDS/notification.ogg"
nirux sounds play notification; nothing 'same sound within cooldown'
rm -f "$SOUNDS/.notification-stamp"
nirux sounds play notification; expect 'no app' "$SOUNDS/notification.ogg"

# Each sound has its own rate limit.
nirux sounds play notification --app Thunderbird; nothing 'mail within cooldown'
nirux sounds test notification --app Thunderbird; expect 'test ignores cooldown' "$SOUNDS/mail.ogg"
reset_cooldowns

# Excluded apps stay silent; disabled notification sounds stay silent.
nirux sounds play notification --app NPLAY; nothing 'excluded app'
nirux sounds toggle notification > /dev/null
nirux sounds play notification --app Signal; nothing 'notification sounds off'
nirux sounds toggle notification > /dev/null
reset_cooldowns

# A missing app sound falls back to the notification sound.
rm -f "$SOUNDS/chat.ogg"
nirux sounds play notification --app Signal; expect 'missing chat.ogg' "$SOUNDS/notification.ogg"
printf 'OggS chat\n' > "$SOUNDS/chat.ogg"
reset_cooldowns

# A user sound with the same name wins over the NIRUX sound.
mkdir -p "$XDG_CONFIG_HOME/nirux/sounds"
printf 'OggS mine\n' > "$XDG_CONFIG_HOME/nirux/sounds/mail.ogg"
nirux sounds play notification --app thunderbird; expect 'user mail.ogg' "$XDG_CONFIG_HOME/nirux/sounds/mail.ogg"
rm -f "$XDG_CONFIG_HOME/nirux/sounds/mail.ogg"
reset_cooldowns

# The app command: path, off, default and remove, without disturbing [sounds].
printf 'OggS path\n' > "$HOME/ping.ogg"
# The tilde is literal on purpose: NIRUX expands it, not the shell.
# shellcheck disable=SC2088
nirux sounds app signal '~/ping.ogg' > /dev/null
nirux sounds play notification --app Signal; expect 'path value' "$HOME/ping.ogg"
reset_cooldowns
nirux sounds app signal off > /dev/null
nirux sounds play notification --app Signal; nothing 'app off'
nirux sounds app discord chat > /dev/null
nirux sounds play notification --app discord; expect 'added app' "$SOUNDS/chat.ogg"
reset_cooldowns
nirux sounds app signal remove > /dev/null
grep -q '^signal' "$CONFIG" && fail 'remove left the Signal entry'
nirux sounds play notification --app Signal; expect 'removed app' "$SOUNDS/notification.ogg"
reset_cooldowns
if nirux sounds app 'bad name!' chat > /dev/null 2>&1; then fail 'invalid app name accepted'; fi
if nirux sounds app signal 'bad"value' > /dev/null 2>&1; then fail 'invalid sound accepted'; fi

# Changing a [sounds] key keeps it in [sounds], not in [sounds.apps].
nirux sounds off > /dev/null
nirux sounds on > /dev/null
awk '/^\[sounds\.apps\]/{apps=1} apps && /^enabled/{bad=1} END{exit bad}' "$CONFIG" ||
  fail 'a [sounds] key was written into [sounds.apps]'
[ "$(awk '/^\[/{exit} /^enabled/{n++} END{print n+0}' "$CONFIG")" = 1 ] || fail 'enabled key duplicated in [sounds]'

# A configuration from before per-app sounds gets the table once.
cat > "$CONFIG" <<'EOF'
[sounds]
enabled = true
volume = 35
notification = true
notification_cooldown_ms = 2500
respect_mute = true
EOF
nirux sounds status > /dev/null
nirux sounds status > /dev/null
[ "$(grep -c '^\[sounds\.apps\]' "$CONFIG")" = 1 ] || fail 'migration did not add exactly one [sounds.apps]'
grep -q '^volume = 35' "$CONFIG" || fail 'migration changed existing keys'
reset_cooldowns
nirux sounds play notification --app Thunderbird; expect 'migrated config' "$SOUNDS/mail.ogg"

# An existing, deliberately empty table is never refilled.
cat > "$CONFIG" <<'EOF'
[sounds]
enabled = true

[sounds.apps]
EOF
nirux sounds status > /dev/null
grep -q '^thunderbird' "$CONFIG" && fail 'an empty user table was refilled'
reset_cooldowns
nirux sounds play notification --app Thunderbird; expect 'empty table' "$SOUNDS/notification.ogg"

# Machine-readable status for the launcher.
cat > "$CONFIG" <<'EOF'
[sounds]
enabled = true
volume = 40
notification_exclude_apps = ["nplay"]

[sounds.apps]
thunderbird = "mail"
signal = "off"
discord = "nosuchsound"
EOF
nirux sounds status --json > "$TEST/status.json"
python3 - "$TEST/status.json" "$SOUNDS" <<'PY' || fail 'status --json is wrong'
import json, sys
data = json.load(open(sys.argv[1]))
sounds = sys.argv[2]
assert data["schema"] == 1 and data["enabled"] is True and data["volume"] == 40, data
assert data["events"]["notification"] is True, data
assert data["exclude"] == ["nplay"], data
apps = {a["app"]: a for a in data["apps"]}
assert apps["thunderbird"]["state"] == "ok" and apps["thunderbird"]["file"] == sounds + "/mail.ogg", apps
assert apps["signal"]["state"] == "silent", apps
assert apps["discord"]["state"] == "missing", apps
PY

# --- System, feedback, power and device sounds -----------------------------
rm -f "$CONFIG" "$CONFIG.bak"
nirux sounds status > "$TEST/status"
for table in system notifications feedback power devices apps; do
  [ "$(grep -c "^\[sounds\.$table\]" "$CONFIG")" = 1 ] || fail "new config lacks exactly one [sounds.$table]"
done
grep -q '^feedback: on' "$TEST/status" || fail 'status does not show categories'
cmp -s "$CONFIG" "$SOURCE/sounds.example.toml" || fail 'a new sounds.toml differs from sounds.example.toml'
grep -q '^  volume-up: on' "$TEST/status" || fail 'status does not show feedback events'
grep -q '^  brightness-up: off' "$TEST/status" || fail 'brightness is not off by default'
grep -q '^  battery-full: off' "$TEST/status" || fail 'battery-full is not off by default'
grep -q '^  lock: off' "$TEST/status" || fail 'lock is not off by default'

nirux sounds list > "$TEST/list"
for event in startup update shutdown auth-fail lock unlock notification volume-up volume-down \
  volume-limit mute unmute brightness-up brightness-down screenshot power-plug power-unplug \
  battery-low battery-critical battery-full device-connect device-disconnect; do
  grep -q " $event " "$TEST/list" || fail "list lacks $event"
  nirux sounds test "$event" > /dev/null
  expect "test $event" "$SOUNDS/$event.ogg"
done
if nirux sounds test nosuch > /dev/null 2>&1; then fail 'unknown event accepted'; fi

# Defaults: off events stay silent when played, on events play.
nirux sounds play brightness-up; nothing 'brightness off by default'
nirux sounds play battery-full; nothing 'battery-full off by default'
nirux sounds play power-plug; expect 'power-plug' "$SOUNDS/power-plug.ogg"
nirux sounds play auth-fail; expect 'auth-fail' "$SOUNDS/auth-fail.ogg"

# The volume tick follows the level, rounded to the nearest 10 % step.
nirux sounds play volume-up --level 47; expect 'tick at 47 %' "$SOUNDS/levels/volume-up-050.ogg"
sleep 0.1
nirux sounds play volume-down --level 08; expect 'tick at 08 %' "$SOUNDS/levels/volume-down-010.ogg"
sleep 0.1
nirux sounds play volume-up --level 100; expect 'tick at 100 %' "$SOUNDS/levels/volume-up-100.ogg"
sleep 0.1
nirux sounds play volume-up --level 9999; expect 'tick above 100 %' "$SOUNDS/levels/volume-up-100.ogg"
sleep 0.1
nirux sounds play volume-up; expect 'tick without level' "$SOUNDS/volume-up.ogg"

# Held keys: one tick per rate_limit_ms per event.
sleep 0.1
nirux sounds play volume-down; nirux sounds play volume-down
sleep 0.3
[ "$(wc -l < "$LOG")" = 1 ] || fail 'rate limit let a second tick through'
: > "$LOG"
nirux sounds toggle feedback > /dev/null
grep -q '^enabled = false' "$CONFIG" || fail 'category toggle did not write enabled = false'
sleep 0.1
nirux sounds play volume-up; nothing 'feedback category off'
nirux sounds play power-plug; expect 'other categories unaffected' "$SOUNDS/power-plug.ogg"
nirux sounds toggle feedback > /dev/null

# Toggling an event writes it in its category table; legacy keys stay in [sounds].
nirux sounds toggle device-connect > /dev/null
awk '/^\[sounds\.devices\]/{d=1;next} /^\[/{d=0} d && /^device-connect = false/{ok=1} END{exit !ok}' "$CONFIG" ||
  fail 'event toggle did not land in [sounds.devices]'
nirux sounds play device-connect; nothing 'device-connect toggled off'
nirux sounds toggle device-connect > /dev/null
nirux sounds toggle startup > /dev/null
awk '/^\[/{exit} /^startup = false/{ok=1} END{exit !ok}' "$CONFIG" || fail 'startup toggle left [sounds]'
nirux sounds play startup; nothing 'startup toggled off'
nirux sounds toggle startup > /dev/null

# Every event, the old ones included, can be replaced by the user's file.
for event in startup notification update shutdown volume-up screenshot; do
  printf 'OggS mine\n' > "$XDG_CONFIG_HOME/nirux/sounds/$event.ogg"
done
reset_cooldowns
nirux sounds play startup; expect 'user startup.ogg' "$XDG_CONFIG_HOME/nirux/sounds/startup.ogg"
nirux sounds play notification --app kitty; expect 'user notification.ogg' "$XDG_CONFIG_HOME/nirux/sounds/notification.ogg"
nirux sounds play update; expect 'user update.ogg' "$XDG_CONFIG_HOME/nirux/sounds/update.ogg"
nirux sounds play shutdown; expect 'user shutdown.ogg' "$XDG_CONFIG_HOME/nirux/sounds/shutdown.ogg"
sleep 0.1
nirux sounds play volume-up --level 30; expect 'user tick beats the levels' "$XDG_CONFIG_HOME/nirux/sounds/volume-up.ogg"
nirux sounds play screenshot; expect 'user screenshot.ogg' "$XDG_CONFIG_HOME/nirux/sounds/screenshot.ogg"
nirux sounds list | grep -q 'screenshot .*(yours)' || fail 'list does not mark the user file'
rm -f "$XDG_CONFIG_HOME/nirux/sounds/"*.ogg
reset_cooldowns

# A muted sink silences everything when respect_mute is on.
printf '#!/bin/sh\nprintf "Volume: 0.50 [MUTED]\\n"\n' > "$TEST/bin/wpctl"
nirux sounds play power-unplug; nothing 'muted sink'
sed 's/^respect_mute = true/respect_mute = false/' "$CONFIG" > "$TEST/c" && cat "$TEST/c" > "$CONFIG"
nirux sounds play power-unplug; expect 'respect_mute off' "$SOUNDS/power-unplug.ogg"
sed 's/^respect_mute = false/respect_mute = true/' "$CONFIG" > "$TEST/c" && cat "$TEST/c" > "$CONFIG"
printf '#!/bin/sh\nprintf "Volume: 0.50\\n"\n' > "$TEST/bin/wpctl"

# A category may set its own volume.
awk '{print} /^\[sounds\.power\]$/{print "volume = 70"}' "$CONFIG" > "$TEST/c" && cat "$TEST/c" > "$CONFIG"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$PLAYED_LOG"\n' > "$TEST/bin/pw-play"
nirux sounds play power-plug; expect 'power volume' "--volume=0.70 $SOUNDS/power-plug.ogg"
nirux sounds play auth-fail; expect 'global volume' "--volume=0.35 $SOUNDS/auth-fail.ogg"
printf '#!/bin/sh\nfor arg do last=$arg; done\nprintf "%%s\\n" "$last" >> "$PLAYED_LOG"\n' > "$TEST/bin/pw-play"

# Migration: a 0.12.218 configuration keeps every choice, gains the category
# tables once, and keeps a backup.
cat > "$CONFIG" <<'EOF'
[sounds]
enabled = true
volume = 20
startup = false
notification = true
update = true
shutdown = true
notification_cooldown_ms = 2500
respect_mute = true

[sounds.apps]
thunderbird = "mail"
signal = "off"
EOF
cp "$CONFIG" "$TEST/before.toml"
nirux sounds status > /dev/null
nirux sounds list > /dev/null
cmp -s "$CONFIG.bak" "$TEST/before.toml" || fail 'migration kept no backup of the old file'
head -n "$(wc -l < "$TEST/before.toml")" "$CONFIG" | cmp -s - "$TEST/before.toml" || fail 'migration changed existing lines'
for table in system notifications feedback power devices apps; do
  [ "$(grep -c "^\[sounds\.$table\]" "$CONFIG")" = 1 ] || fail "migration did not add exactly one [sounds.$table]"
done
[ "$(grep -c '^signal' "$CONFIG")" = 1 ] || fail 'migration touched [sounds.apps]'
nirux sounds play startup; nothing 'migrated startup = false kept'
nirux sounds play volume-up; expect 'migrated config gets feedback' "$SOUNDS/volume-up.ogg"
nirux sounds play notification --app Signal; nothing 'migrated app choice kept'

# A user's own category table is never refilled or overridden.
cat > "$CONFIG" <<'EOF'
[sounds]
enabled = true

[sounds.feedback]
volume-up = false

[sounds.power]
EOF
nirux sounds status > /dev/null
[ "$(grep -c '^\[sounds\.feedback\]' "$CONFIG")" = 1 ] || fail 'user feedback table duplicated'
[ "$(grep -c '^\[sounds\.power\]' "$CONFIG")" = 1 ] || fail 'user power table duplicated'
nirux sounds play volume-up; nothing 'user volume-up = false'
sleep 0.1
nirux sounds play volume-down; expect 'unset key uses the default' "$SOUNDS/volume-down.ogg"
nirux sounds play battery-low; expect 'empty power table uses defaults' "$SOUNDS/battery-low.ogg"

nirux sounds status --json > "$TEST/status.json"
python3 - "$TEST/status.json" <<'PY' || fail 'status --json categories are wrong'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == 1, data
assert set(data["categories"]) == {"system", "notifications", "feedback", "power", "devices"}, data
assert "volume-up" in data["categories"]["feedback"]["events"], data
assert data["events"]["volume-up"] is False and data["events"]["volume-down"] is True, data
assert data["events"]["brightness-up"] is False and data["events"]["startup"] is True, data
PY

printf 'PASS: event, feedback, power, device and per-app sounds\n'
