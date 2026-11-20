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

# EVENT|TEXT|AFTER. AFTER is "tone" for a voice followed by the event's NIRUX
# tone (sounds/EVENT.ogg): shutdown says "Goodbye" and then plays its tune.
# Events without a voice here keep their tone.
VOICES='battery-low|Battery low|
battery-critical|Power critical|
reminder|Reminder|
meet-ready|All systems ready|
auth-fail|Access denied|
shutdown|Goodbye|tone'

tones=$(dirname "$0")/../sounds
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
printf '%s\n' "$VOICES" | while IFS='|' read -r name text after; do
  # The voice of mail.ogg: American English, low pitch, slow, at about the
  # loudness of mail.ogg, with leading and trailing silence trimmed.
  espeak-ng -v en-us -p 20 -s 130 "$text" --stdout > "$tmp/raw.wav"
  trim='silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-22:TP=-4:LRA=7,areverse,silenceremove=start_periods=1:start_threshold=-50dB,afade=t=in:d=0.02,areverse'
  if [ "$after" = tone ]; then
    # The voice, a short breath, then the tone, at the tone's format.
    ffmpeg -nostdin -loglevel error -y -i "$tmp/raw.wav" -i "$tones/$name.ogg" -filter_complex \
      "[0:a]$trim,aresample=48000,aformat=channel_layouts=stereo,apad=pad_dur=0.12[v];[1:a]aresample=48000,aformat=channel_layouts=stereo[t];[v][t]concat=n=2:v=0:a=1[out]" \
      -map '[out]' -c:a libvorbis -q:a 4 -map_metadata -1 -fflags +bitexact "$out/$name.ogg"
  else
    ffmpeg -nostdin -loglevel error -y -i "$tmp/raw.wav" -af "$trim" \
      -ac 1 -ar 22050 -c:a libvorbis -q:a 3 -map_metadata -1 -fflags +bitexact "$out/$name.ogg"
  fi
  echo "voice: $name.ogg ($text${after:+, then the tone})"
done
