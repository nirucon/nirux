#!/bin/sh
# Generate the NIRUX voice sounds (sounds/voice/*.ogg): a retro robot voice
# for rare, important events, made with espeak-ng the same way as mail.ogg and
# chat.ogg ("You got mail", "You got chat message"). Every other NIRUX sound
# stays a tone; `nirux sounds voice off` brings the tones back for these too.
#
# usage: tools/gen-voice.sh [OUTDIR]   (needs espeak-ng and ffmpeg)
set -eu
out=${1:-$(dirname "$0")/../sounds/voice}
command -v espeak-ng >/dev/null || { echo 'gen-voice: espeak-ng is missing' >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo 'gen-voice: ffmpeg is missing' >&2; exit 1; }
mkdir -p "$out"

# EVENT|TEXT. teams is not an event: it is the app sound for Microsoft Teams
# notifications, and exists only while the voice sounds are on.
VOICES='battery-low|Battery low
battery-critical|Power critical
network-down|Connection lost
network-up|Back online
reminder|Reminder
timer-done|Time is up
meet-ready|All systems ready
meet-problem|Check your devices
auth-fail|Access denied
update|System updated
startup|System online
shutdown|Goodbye
teams|Teams message'

printf '%s\n' "$VOICES" | while IFS='|' read -r name text; do
  # The voice of mail.ogg: American English, low pitch, slow. Mono 22.05 kHz
  # Vorbis at about the loudness of mail.ogg, with a short fade-out.
  espeak-ng -v en-us -p 20 -s 130 "$text" --stdout |
    ffmpeg -nostdin -loglevel error -y -i - \
      -af 'silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-22:TP=-4:LRA=7,areverse,silenceremove=start_periods=1:start_threshold=-50dB,afade=t=in:d=0.02,areverse' \
      -ac 1 -ar 22050 -c:a libvorbis -q:a 3 -map_metadata -1 -fflags +bitexact "$out/$name.ogg"
  echo "voice: $name.ogg ($text)"
done
