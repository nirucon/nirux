# Sounds

NIRUX plays short, soft sounds for the session, notifications, the keys you
press, the charger and battery, and devices that come and go. They are one
family: the same voice (a soft attack, a near-sine bar with a quieter fourth
partial that dies away quickly) and the same key as the startup and
notification sounds (G major: the notification is a G4 + D5 fifth).

## Events

| Category | Event | Default | Sound |
|---|---|---|---|
| system | `startup`, `update`, `shutdown` | on | the session sounds |
| system | `auth-fail` | on | low soft thud (G3, 150 ms), wrong password in NIRULOCK |
| system | `lock`, `unlock` | off | near-silent chime (D6 + G6 / G5 → D6) |
| notifications | `notification` | on | G4 + D5, or the app's sound from `[sounds.apps]` |
| feedback | `volume-up`, `volume-down` | on | 40 ms tock; its pitch follows the new level (D5 at 0 %, G5 at 100 %) |
| feedback | `volume-limit` | on | duller 60 ms bump when the key cannot go further (0 % or 100 %) |
| feedback | `mute`, `unmute` | on | two notes, B4 → G4 / G4 → B4, 150 ms |
| feedback | `brightness-up`, `brightness-down` | off | quiet airy 30 ms tick |
| feedback | `screenshot` | on | soft, muted 110 ms shutter |
| power | `power-plug`, `power-unplug` | on | two notes, G4 → D5 / D5 → G4 |
| power | `battery-low` | on | D5 → B4 → G4, once per discharge at `battery_low_percent` |
| power | `battery-critical` | on | B4 → E4 twice, once per discharge at `battery_critical_percent` |
| power | `battery-full` | off | G4 → B4 → D5 → G5 when a seen charge finishes |
| devices | `device-connect`, `device-disconnect` | on | a double click, up / down |

Every sound starts at once (no leading silence) and is quieter than a
notification; the feedback ticks are the quietest.

## Commands

```sh
nirux sounds status              # categories, events and app sounds
nirux sounds list                # every event, whether it plays, and its file
nirux sounds on | off            # everything
nirux sounds toggle power        # a category
nirux sounds toggle battery-full # one event
nirux sounds test device-connect # play one now, even if it is off
nirux sounds play volume-up --level 70
```

`test` ignores rate limits and the event's own switch; mute and `nirux sounds
off` still apply. `nirux sounds status --json` is the machine-readable form
used by NIRULAUNCHER.

## Configuration

`~/.config/nirux/sounds.toml`. A new file looks like
[sounds.example.toml](../sounds.example.toml). An event plays when
`[sounds] enabled`, its category's `enabled` and its own key are all `true`.
The event key is read from its category table first, then from `[sounds]`
(where `startup`, `update`, `shutdown` and `notification` have always been),
then from the default above.

```toml
[sounds]
enabled = true
volume = 35          # every category, unless the category sets its own
respect_mute = true  # nothing plays while the default sink is muted

[sounds.feedback]
enabled = true
volume-up = true
brightness-up = false
rate_limit_ms = 80   # a held key plays at most one tick per 80 ms
# volume = 50        # optional: this category's own volume

[sounds.power]
battery_low_percent = 20
battery_critical_percent = 5
battery_full_percent = 100   # or your charge limit, for example 80

[sounds.devices]
usb = true
audio = true         # sound cards (USB headsets, docks)
displays = true      # monitor hotplug
bluetooth = false    # Bluetooth links; mice and keyboards reconnect often
debounce_ms = 1500   # a dock is one sound
```

**Do Not Disturb** (`nirunotify --dnd on`) silences notification sounds and
nothing else: the keys, the charger, the battery, devices and the lock screen
still sound.

**Mute**: with `respect_mute = true` nothing plays while the default sink is
muted. The mute sound plays just before the sink is muted and the unmute sound
right after it is unmuted, so both are heard.

**Your own sounds**: `~/.config/nirux/sounds/EVENT.ogg` replaces the NIRUX
sound for EVENT, for every event including `startup` and `notification`. A
replaced `volume-up`/`volume-down` plays the same file at every level.

**Upgrades**: a `sounds.toml` from an older NIRUX gains each missing category
table once, with the defaults. Existing keys and tables are never changed,
including a table you emptied on purpose, and the previous file is kept as
`sounds.toml.bak`.

## How it plays

- **NIRUNOTIFY** plays the feedback, power, device and lock-screen sounds. It
  reads `sounds.toml` with the same rules as `nirux` and rereads it when it
  changes, starts `pw-play` (or `paplay`, `ffplay`) on the file directly, with
  no shell, and reaps it. On othala this adds about 15 ms to the player's own
  start; a volume key is decided in under a millisecond.
- **Volume and brightness keys** (NIRUWM, `niructl brightness`) already call
  `nirunotify --osd`; the same call carries the sound and the new level.
- **NIRUSHOT** and **NIRULOCK** send one line on NIRUNOTIFY's control socket
  (`sound screenshot`, `sound auth-fail`); nothing is started.
- **Charger, battery and devices** come from kernel uevents
  (`NETLINK_KOBJECT_UEVENT`). The watcher sleeps until the kernel reports
  something; there is no timer and no polling. A burst (a dock: hub, devices,
  audio card, monitor, charger) is gathered for a quarter of a second and is
  one sound; the charger wins. More devices in the same direction stay quiet
  for `debounce_ms`. Device sounds pause for five seconds after a resume.
- **Startup, update, shutdown and notifications** play through `nirux sounds
  play`, as before.

Sounds are ordinary short playback streams on the default sink. Nothing
changes volumes, routing, or other streams, so music is never paused or ducked
and CAVA visualizers are not affected.

`nirunotify --check-config` shows what the watcher reads (charger, battery,
monitors) and whether kernel events are available.
`NIRUNOTIFY_DEBUG_SOUNDS=1 nirunotify` explains every decision on stderr.

## Limitations

- A wired headphone jack is not a kernel device event, so plugging headphones
  into the jack is silent; USB and Bluetooth (when enabled) headsets sound.
- Battery levels are read on the kernel's battery events. Laptops report
  those on every percent or status change; firmware that reports less often
  sounds `battery-low` at its next report.
- The volume keys stop at 100 %. A wpctl too old for `-l` raises without a
  limit, and the limit bump then never plays.

## Making the sounds

The sounds are generated, not recorded:

```sh
python3 tools/gen-sounds.py --report
```

The script uses the Python standard library to synthesise every sound and
ffmpeg (libvorbis) to encode them as mono 44.1 kHz Ogg Vorbis into `sounds/`
and `sounds/levels/` (the volume tick for each 10 % step). The output is
deterministic, and loudness is normalised to a per-sound target (maximum
momentary loudness, EBU R128). The sounds are original work under this
repository's MIT license.
