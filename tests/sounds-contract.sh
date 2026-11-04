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
for name in startup notification update shutdown mail chat; do
  printf 'OggS %s\n' "$name" > "$SOUNDS/$name.ogg"
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
[ "$(grep -c '^enabled' "$CONFIG")" = 1 ] || fail 'enabled key duplicated'

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

printf 'PASS: event and per-app notification sounds\n'
