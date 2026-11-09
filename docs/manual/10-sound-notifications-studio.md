# Sound, notifications and studio mode

This chapter covers volume, outputs and the microphone, media keys, the NIRUX event sounds, notifications and Do Not Disturb (NIRUNOTIFY), and the session modes that keep the screen awake or silence the desktop: keep awake, focus and presentation mode, and studio mode for recording. Bluetooth and power profiles are at the end.

## Change the volume

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up 5 % (also unmutes), stops at 100 % |
| `XF86AudioLowerVolume` | Volume down 5 % |
| `XF86AudioMute` | Mute or unmute the output |
| `XF86AudioPlay` / `XF86AudioPause` | Play or pause (`playerctl play-pause`) |
| `XF86AudioNext` / `XF86AudioPrev` | Next / previous track (`playerctl`) |

The volume keys use `wpctl` on the default sink (with an `amixer` fallback), show the level in the NIRUNOTIFY OSD and play a short tick whose pitch follows the new level. At 0 % or 100 % a duller bump tells you the key cannot go further. The play keys need `playerctl` and a player that speaks MPRIS.

From a terminal or a script:

```sh
niructl audio volume up      # +5 % on the default output
niructl audio volume down    # -5 %
niructl audio mute           # toggle mute on the default output
```

In the bar, scroll on the `volume` module to change the level, right-click to mute, and middle-click to mute the microphone. See [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md).

## Choose the output and the input

`niructl audio` talks to WirePlumber (`wpctl`). Devices are selected by their numeric ID, not by name, because two identical devices can be connected at the same time.

```sh
niructl audio status           # outputs, inputs and the microphone reading
niructl audio status --json
niructl audio outputs          # list outputs; * marks the default
niructl audio outputs --json
niructl audio sources          # list inputs; * marks the default
niructl audio sources --json
niructl audio output 52        # make output 52 the default
niructl audio output next      # cycle to the next output
niructl audio source 61        # make input 61 the default
niructl audio source next      # cycle to the next input
```

`niructl audio input ID|next` is the same as `source`.

To pick a device from a list instead, open the launcher's sound view with `nirulauncher --sound` (outputs, inputs, active streams and event sounds) or `nirulauncher --microphone`. See [05-launcher.md](05-launcher.md).

## Use the microphone

```sh
niructl audio mic-status            # mute state and gain of the default input
niructl audio mic-status --json
niructl audio mic-mute              # toggle (the default)
niructl audio mic-mute on           # mute
niructl audio mic-mute off          # unmute
niructl audio mic-level up          # +5 % input gain
niructl audio mic-level down        # -5 %
niructl audio mic-level set 70      # 0 to 100
```

Changing the gain never unmutes a muted microphone, and the gain is capped at 100 %.

To check that the microphone works and is not clipping, record a short test:

```sh
niructl audio mic-test              # 5 seconds
niructl audio mic-test 10           # 1 to 15 seconds
niructl audio mic-test --json
niructl audio mic-test 5 --keep     # keep the WAV file and print its path (with --json)
```

The test records through `pw-record` (or `arecord` when PipeWire is missing) and prints the peak and RMS level in dBFS, whether it clipped, and a verdict. The recording is deleted afterwards unless you pass `--keep`.

The bar's `microphone` module shows the input state: right-click mutes, scroll changes the gain, middle-click opens the source selector.

## Event sounds

NIRUX plays short, soft sounds for the session, notifications, the keys you press, the charger and battery, devices that come and go, and NIRUDICTATE dictation. They are quiet, start at once and never pause, duck or reroute other audio.

| Category | Events | On by default |
|---|---|---|
| `system` | `startup`, `update`, `shutdown`, `auth-fail` (wrong password in NIRULOCK), `lock`, `unlock` | all except `lock` and `unlock` |
| `notifications` | `notification` (or the app's own sound) | yes |
| `feedback` | `volume-up`, `volume-down`, `volume-limit`, `mute`, `unmute`, `brightness-up`, `brightness-down`, `screenshot` | all except the brightness ticks |
| `power` | `power-plug`, `power-unplug`, `battery-low`, `battery-critical`, `battery-full` | all except `battery-full` |
| `devices` | `device-connect`, `device-disconnect` (USB, sound cards, monitors, optionally Bluetooth) | yes |
| `dictation` | `dictation-start`, `dictation-stop`, `dictation-done`, `dictation-error` | all except `dictation-done` |

Manage them with `nirux sounds`:

```sh
nirux sounds status                 # categories, events and app sounds
nirux sounds status --json          # what the launcher reads
nirux sounds list                   # every event, whether it plays, and its file
nirux sounds on                     # all sounds on
nirux sounds off                    # all sounds off
nirux sounds toggle power           # one category
nirux sounds toggle battery-full    # one event
nirux sounds test device-connect    # play it now, even if it is switched off
nirux sounds play volume-up --level 70
```

`test` ignores rate limits and the event's own switch; mute and `nirux sounds off` still apply. The launcher's sound view (`nirulauncher --sound`) has the same switches and a Test entry for each event, and runs `nirux sounds` for you.

To use your own sound for an event, put an Ogg file at `~/.config/nirux/sounds/EVENT.ogg`, for example `~/.config/nirux/sounds/startup.ogg`. A replaced `volume-up` or `volume-down` plays the same file at every level.

Startup and shutdown sounds are part of the session and take effect at the next login.

### Per-app notification sounds

By default Thunderbird mail plays `mail` and Signal messages play `chat`; every other app plays the normal notification sound.

```sh
nirux sounds app signal                 # show the current choice
nirux sounds app signal chat            # a sound name: chat.ogg
nirux sounds app discord ~/Music/ping.ogg
nirux sounds app teams off              # notification shown, no sound
nirux sounds app teams default          # the normal notification sound
nirux sounds app signal remove          # forget the entry
nirux sounds test notification --app Signal
```

The app name is the one the notification is sent with, as listed by `nirunotify --history`; case does not matter. A sound name plays `NAME.ogg` from `~/.config/nirux/sounds/` first, then from the NIRUX sounds. A missing file falls back to the notification sound.

### sounds.toml

The settings live in `~/.config/nirux/sounds.toml` (a new file looks like `sounds.example.toml` in the NIRUX repository). An event plays only when `[sounds] enabled`, its category's `enabled` and its own key are all `true`. NIRUNOTIFY rereads the file when it changes.

```toml
[sounds]
enabled = true
volume = 35                     # every category, unless the category sets its own
notification_cooldown_ms = 2500
notification_exclude_apps = ["nplay", "spotify"]   # notifications shown, no sound
respect_mute = true             # nothing plays while the default output is muted

[sounds.feedback]
brightness-up = false           # one event off
rate_limit_ms = 80              # a held key plays at most one tick per 80 ms

[sounds.power]
battery_low_percent = 20
battery_critical_percent = 5
battery_full_percent = 100      # or your charge limit, for example 80

[sounds.devices]
bluetooth = false               # Bluetooth links (off by default)
debounce_ms = 1500              # a dock is one sound
```

Good to know:

- Do Not Disturb silences notification sounds and nothing else: keys, charger, battery, devices and the lock screen still sound.
- A wired headphone jack is not a kernel device event, so plugging headphones into the jack is silent.
- `NIRUNOTIFY_DEBUG_SOUNDS=1 nirunotify` explains every sound decision on stderr, and `nirunotify --check-config` shows what the charger, battery and monitor watcher reads.

The full reference, including how the sounds are generated, is [docs/SOUNDS.md](https://github.com/nirucon/nirux/blob/main/docs/SOUNDS.md).

## Notifications

NIRUNOTIFY is the notification service. It shows themed popups in the top-right corner of the screen under the pointer, never takes keyboard focus, and keeps a history in memory (the last 100). Popups are suppressed while the screen is locked. Any program can send one with `notify-send`.

- Click a popup to run its default action, or to close it when it has none.
- The bar's `notifications` module shows the history count; click it for recent notifications.

```sh
notify-send "Hello" "Body"
nirunotify --history          # recent notifications
nirunotify --count            # how many are visible
nirunotify --dismiss ID       # close one popup
nirunotify --clear            # clear the history
nirunotify --check-config
```

### Do Not Disturb

| Keys | Action |
|---|---|
| `Super+Shift+D` | Do Not Disturb on or off |

```sh
niructl dnd toggle
niructl dnd on
niructl dnd off
niructl dnd status
```

`niructl dnd` uses NIRUNOTIFY (`nirunotify --dnd on|off|toggle|status`) and falls back to Dunst when NIRUNOTIFY is not running. While DND is on, popups and notification sounds stop; critical notifications get through only if `critical_ignore_dnd = true`. The bar's `dnd` module (a bell) toggles DND on left click.

### Configure notifications

`~/.config/nirunotify/config.toml`. Colours follow the NIRUWM theme, and font and spacing come from `~/.config/niruwm/appearance.toml` unless set here.

| Key | Default | Meaning |
|---|---|---|
| `width` | `360` | Width of each popup, in pixels |
| `margin` | `12` | Gap from the screen edge and between popups |
| `max_visible` | `5` | Popups on screen; older ones stay in the history |
| `default_timeout_ms` | `6000` | Timeout when the sender does not choose one |
| `max_timeout_ms` | `60000` | Upper bound for any timeout, including "never expire" |
| `critical_timeout_ms` | `30000` | Timeout for critical notifications |
| `critical_ignore_dnd` | `false` | Let critical notifications through Do Not Disturb |
| `monitor` | `""` | Empty: the screen under the pointer; `"primary"`; or an output name |
| `font_path` | unset | A font file, for example DejaVu Sans Mono |
| `font_size` | `14.0` | Text size |
| `position` | `"top-right"` | `top-right`, `top-left`, `bottom-right` or `bottom-left` |

## Keep the screen awake

| Keys | Action |
|---|---|
| `Super+Shift+C` | Keep the screen awake on or off |

```sh
niructl idle on            # until you turn it off
niructl idle on 90         # for 90 minutes (1 to 1440)
niructl idle off
niructl idle toggle
niructl idle status
```

While it is on, the screen saver, the idle lock and display-off wait. The state is the file `~/.local/state/niruui/inhibit`.

## Focus and presentation mode

A work mode turns on Do Not Disturb and keep-awake for a while, and puts both back when it ends.

```sh
niructl mode focus             # 25 minutes
niructl mode focus 50          # 1 to 480 minutes
niructl mode presentation      # 60 minutes
niructl mode presentation 90
niructl mode status            # the mode and minutes left
niructl mode stop
```

The two modes do the same thing and differ only in their default length. When the time is up you get a notification. Only what the mode itself changed is undone: if DND or keep-awake was already on, it stays on. The bar's `mode` module shows the active mode and the minutes left. In the launcher, type `focus mode`, `presentation mode` or `stop context`.

## Studio mode

Studio mode is one switch for recording sessions with a DAW. While it is on:

- the screen saver, idle lock and display-off wait;
- Do Not Disturb is on (no popups, no notification sounds);
- the compositor (picom) of this display is stopped;
- the power profile is set to `performance`.

```sh
niructl studio on
niructl studio off
niructl studio toggle
niructl studio status           # what studio mode changed, and any notes
niructl studio toggle --quiet   # print only the first line ("studio on")
```

Turning it off puts back exactly what it changed, in reverse order, and leaves alone anything you changed in the meantime: if DND was already on, or you picked another power profile while recording, that stays. The mode belongs to the running X session (it is stored on the root window, not in a file), so it never outlives a logout; the session turns it off on logout.

There is no default key. Use the launcher (type `studio mode`, `daw mode` or `recording mode`; Swedish `studioläge`), the Quick Settings row **Studio mode**, or bind the `studio_toggle` action in `~/.config/niruwm/config.toml` (see [02-windows-and-layouts.md](02-windows-and-layouts.md)). The bar's `mode` module shows *studio* while it is on.

Configure it in the `[studio]` table of `~/.config/niruwm/config.toml`. Every key is optional:

```toml
[studio]
idle = true                    # pause screen saver, lock and display-off
dnd = true                     # Do Not Disturb
compositor = true              # stop picom while on, start it again after
power_profile = "performance"  # "" or "keep" leaves the profile alone
auto_enable = false            # turn on when a DAW window appears
daw_classes = ["REAPER"]       # what counts as a DAW window (WM_CLASS, any case)
```

With `auto_enable = true`, studio mode turns on when a window whose class is in `daw_classes` appears (this is `niructl studio on --auto`) and turns off when the last one closes. If you turned it on by hand, closing the DAW leaves it on.

Studio mode needs NIRUWM 0.20 or newer in the running session; after an update, log out and in once. The power profile step needs power-profiles-daemon; without it, `status` notes that the profile was skipped.

## Bluetooth audio

Pair a device once with your usual tool (for example `bluetoothctl`), then connect it from NIRUX:

```sh
niructl bluetooth status            # adapter, power and paired devices
niructl bluetooth list              # MAC, name, connected, battery
niructl bluetooth power toggle      # or on / off
niructl bluetooth connect AA:BB:CC:DD:EE:FF
niructl bluetooth disconnect AA:BB:CC:DD:EE:FF
```

`connect` only accepts a paired device. A connected headset appears as an output; switch to it with `niructl audio output next` or the launcher's sound view. `nirulauncher --bluetooth` lists the devices with actions, and the bar's `bluetooth` module shows the state (right-click toggles power).

## Power profiles

With power-profiles-daemon installed:

```sh
niructl powerprofile status         # provider, active profile, available profiles
niructl powerprofile list
niructl powerprofile set balanced
niructl powerprofile next           # cycle
```

The bar's `powerprofile` module shows the active profile; right-click selects the next one.

## See also

- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [05-launcher.md](05-launcher.md)
- [06-lock-and-screensaver.md](06-lock-and-screensaver.md)
- [12-extras.md](12-extras.md)
- [14-configuration-reference.md](14-configuration-reference.md)
- [16-commands.md](16-commands.md)
