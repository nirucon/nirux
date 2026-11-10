# Lock screen and screensaver

NIRULOCK is the PAM lock screen and NIRUSCREENSAVER is the idle screen that comes before it. This chapter covers locking and unlocking, the idle timers, keeping the screen awake, the five layouts, the CAVA spectrum and quotes, and the optional SID pause music.

## Lock the screen

| Keys / command | Effect |
|---|---|
| `Super+Escape` | Lock now |
| `Super+Shift+Escape` | Lock, then suspend |
| `niructl lock` | Lock (a manual lock when typed in a terminal, a silent script lock otherwise) |
| `niructl lock --manual` | Lock as if by hand |
| `niructl lock --silent` | Lock without pause music (for scripts and rollouts) |
| `niructl lock --reason NAME` | Lock with an explicit reason: `manual`, `idle`, `suspend`, `script` or `session` |
| `niructl suspend` | Lock, then suspend |
| Launcher | `lock` / `lås` in `Super+P`, or **Lock screen** in Quick Settings |

`niructl lock` waits until NIRULOCK reports that it holds the keyboard and pointer. If a NIRULOCK is already shown, it does nothing. An unknown option never stops the lock: niructl warns and locks silently. Without NIRULOCK it falls back to `slock`.

The reason only decides whether pause music may play (see below). Grabs, PAM and unlocking are the same for every reason.

| Lock from | Reason |
|---|---|
| `Super+Escape`, the launcher's lock actions, Quick Settings | `manual` |
| `niructl lock` typed in a terminal, or `--manual` | `manual` |
| `niructl lock` from SSH, cron or a script, or `--silent` | `script` |
| The idle ladder (niruidle) | `idle` |
| Before suspend, lid close, `niructl suspend`, `Super+Shift+Escape` | `suspend` |
| A caller that gives no reason | `unspecified` |

## Unlock

Type your password and press `Enter`.

| Keys | Action |
|---|---|
| `Enter` | Check the password through PAM |
| `Backspace` | Delete a character (first cancels a pending dead key) |
| `Escape` | Clear the entry (and stop the pause music for the rest of this lock) |

- The prompt shows the active keyboard layout (`[SE] password:`) when more than one layout is configured, and a Caps Lock indicator.
- A wrong password is shown for two seconds in the theme's warning colour with the number of failed attempts; the entry stays usable. With NIRUNOTIFY running, a soft `auth-fail` sound plays.
- Messages from PAM modules appear under the prompt, so a `pam_faillock` lockout ("The account is locked due to 3 failed logins") does not look like a wrong password.
- Keys are translated through XKB: dead keys, AltGr, keypad digits and composed letters reach PAM exactly as a terminal would type them. Input methods (IBus, Fcitx) are not used while locked.
- The lock never unlocks by itself.

Only PAM authentication of the process owner unlocks. NIRUX installs the PAM service `/etc/pam.d/nirulock`, which includes your distribution's normal login stack. If it is missing, the lock refuses to start; check with the standalone installer's `./install.sh --check` and read `~/.local/state/nirulock/trace.log`.

`prompt_echo = "count"` (default) shows one `*` per character, at most 32. `prompt_echo = "pulse"` shows a fixed row of eight cells with one lit `*` that jumps on every key, so the length is never shown.

## Lock and suspend

`Super+Shift+Escape` (or `niructl suspend`) starts NIRULOCK, waits for its verified readiness (`_NIRU_LOCK_READY`), keeps the lock visible for three seconds, checks that the same lock window is still there and only then asks logind to suspend. Repeated presses are merged, and unlocking during those three seconds cancels the suspend. If the lock cannot grab the keyboard, the suspend is refused, so the machine never sleeps unlocked.

For other suspends (lid close, a suspend from elsewhere) the session's sleep-lock helper locks first with reason `suspend`. It runs by default; `START_SLEEP_LOCK=0` in `~/.config/niruwm/session.conf` turns it off (restart the session after changing it).

## The idle ladder

`niruidle` (part of NIRUWM) watches X idle time and runs three steps:

1. After `screensaver_timeout` idle minutes: the screensaver (a blank screen when NIRUSCREENSAVER is missing).
2. After `lock_after_screensaver` more minutes: the lock (reason `idle`).
3. After `dpms_off_after_lock` more minutes, only while locked: display off.

Any input before the lock resets the ladder. The timers live in `[idle]` in `~/.config/niruwm/config.toml`:

```toml
[idle]
screensaver_timeout = 15      # idle minutes before the screensaver (at least 1)
lock_after_screensaver = 15   # screensaver minutes before locking
dpms_off_after_lock = 15      # minutes after locking before the display sleeps; 0 keeps it on
```

| Key | Default | Range |
|---|---|---|
| `screensaver_timeout` | `15` | 1 to 1440 |
| `lock_after_screensaver` | `15` | 0 to 1440 |
| `dpms_off_after_lock` | `15` | 0 to 1440 |

With `lock_after_screensaver = 0` the screen locks at `screensaver_timeout`, and the lock screen is shown instead of the screensaver. Without a lock screen installed, the screensaver stays. (NIRUWM before 0.23.0 showed the screensaver and never locked with `0`.)

Change a timer without opening the file (comments and other keys are kept, a backup is written to `config.toml.bak`):

```sh
niructl timing show
niructl timing set screensaver_timeout 10
niructl timing set lock_after_screensaver 5
niructl timing set dpms_off_after_lock 0
```

The running niruidle picks up the change within a few seconds. The launcher has the same values in **Idle and lock timing** (`nirulauncher --timing`).

Older `idle_minutes`, `lock_after_minutes` and `dpms_off_minutes` in `~/.config/niruui/screensaver.toml` are only used when the shared file has no `[idle]` section.

## Keep the screen awake

| Keys / command | Effect |
|---|---|
| `Super+Shift+C` | Keep awake on or off |
| `niructl idle on [MINUTES]` | Keep awake, until turned off or for MINUTES (1 to 1440) |
| `niructl idle off` | Back to the normal ladder |
| `niructl idle toggle [MINUTES]` | Switch |
| `niructl idle status` | `idle on (no expiry)`, `idle on, N min remaining` or `idle off` |
| Launcher | `keep awake` / `håll vaken`, or **Toggle idle inhibition** in Quick Settings |

`niructl idle on` means idle *inhibition* is on: no screensaver, no idle lock, no display off. The state is kept in `~/.local/state/niruui/inhibit`. Studio mode (`niructl studio on`) also inhibits the saver and the idle lock while it is on. Manual locking always works.

## The screensaver

NIRUSCREENSAVER covers every screen with the date, a large clock, how long you have been away and, while music plays, a CAVA spectrum with the playing track. It is **not a lock**: any key or click dismisses it, and that key or click is swallowed so it never reaches the window underneath. Pointer motion does not dismiss it unless `dismiss_on_motion = true` (after 24 px).

```sh
niructl screensaver          # show it now on every monitor
niruscreensaver --preview    # show it on one monitor only, to compare settings
niruscreensaver --config     # print the effective settings
```

## Choose a layout

Set `layout` in `~/.config/niruui/lock.toml` (lock) or `~/.config/niruui/screensaver.toml` (screensaver). Both programs know the same five:

| Layout | Composition |
|---|---|
| `cava` | Default. Large clock above the spectrum or a quote; on the lock, state, away time and prompt below |
| `minimal` | Centred clock (and on the lock: state, away time and prompt) |
| `terminal` | Left-aligned monospace screen with a `~$ lock` / `~$ idle` line |
| `runic` | The minimal composition with a discreet rune row when a runic font is available |
| `corner` | Clock top-left, away time at the bottom (prompt centred on the lock) |

`show_hostname = true` shows the machine name under the clock (`hostname:~$ lock` in `terminal`); it is off by default. Colours always follow the active NIRUX theme on an opaque background; `[palette]` only overrides content colours.

## Music or quotes

`visual` decides what the `cava` layout shows where the spectrum is drawn:

| `visual` | Shows |
|---|---|
| `auto` | Default. The CAVA spectrum only while music or radio plays, otherwise a quote |
| `cava` | The spectrum alone (CAVA runs whenever the display is on) |
| `quotes` | Quotes only; CAVA never starts |
| `none` | Nothing; `visualizer = false` without `visual` also means this |

With `auto`, a small PulseAudio client (PipeWire works through `pipewire-pulse`) watches the playback streams. CAVA starts after about 300 ms of sound above a low threshold, so a silent idle stream never starts it, and stops after 5 s of silence; the quote fades out and the spectrum fades in. With the display off nothing runs at all: no CAVA, no audio monitor, no quote changes. The bars use the theme's focus colour.

CAVA, PipeWire/PulseAudio and `playerctl` (for the screensaver's artist and title line, `show_media = true`) are optional. Without CAVA the screens show quotes or nothing.

## Hávamál and other quotes

A quote changes every minute with a soft fade. The quotes are plain text files in `~/.config/niru/quotes/`, shared by the lock and the screensaver. Each `NAME.txt` is one collection. On first start the directory is created with:

| Collection | Contents |
|---|---|
| `havamal-en` | Hávamál in English (Bellows, 1923) |
| `havamal-sv` | Hávamál in Swedish (Brate, 1913) |
| `stoic-en` | Marcus Aurelius, Epictetus and Seneca in English |
| `stoic-sv` | The same passages in Swedish |

After that the directory is yours and is never written again. To get the built-in collections back, rename or remove the directory; it is recreated at the next start.

The format:

```text
# Lines starting with # are comments.
Quotes are separated by one or more blank lines.
A quote may span several lines.
-- A line starting with "-- " is the attribution
```

- **Add a quote:** write it in a collection with a blank line before and after.
- **Add a collection:** create another `.txt` file, for example `~/.config/niru/quotes/mine.txt`.
- **Choose collections:** set `quotes` in `lock.toml` and `screensaver.toml` (they can differ). `*` matches any text, `?` one character.

```toml
quotes = ["*"]                       # default: every collection
quotes = "havamal-sv"                # one collection
quotes = ["havamal-*", "stoic-en"]   # several
```

All selected quotes go into one shuffled pool: each is shown once before any repeats. If nothing usable is selected, the built-in collections are shown instead. To show no quotes, set `visual = "cava"` or `"none"`.

The old single file `~/.config/niru/quotes.txt` (NIRULOCK 0.19 and NIRUSCREENSAVER 0.11) is ignored if you never edited it; an edited one still counts as the collection `quotes`.

## SID pause music

NIRULOCK can play Commodore 64 SID tunes while the screen is locked. It is off by default and plays only for the lock reasons you allow (by default only a manual lock), so an idle lock, a suspend or a script never starts music.

1. Install `sidplayfp` (Debian and Void: `sidplayfp`; Arch: the AUR package `sidplayfp`). `dbus-monitor` is used to stop the music before suspend.
2. Put `.sid` files in `~/Music/SID` (searched recursively; none are shipped). An HVSC `Songlengths.md5` in the folder (or its `DOCUMENTS` directory) gives each tune its real length.
3. Turn it on in `~/.config/niruui/lock.toml`:

```toml
[pause_music]
enabled = true
folder = "~/Music/SID"
track_seconds = 180          # per tune without Songlengths.md5 (5 to 3600)
stop_on_display_off = true
on = ["manual"]              # reasons that play: manual, idle, suspend, script, session, unspecified
```

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | Master switch |
| `folder` | `"~/Music/SID"` | Where the `.sid` files are |
| `track_seconds` | `180` | Tune length when `Songlengths.md5` does not know it |
| `stop_on_display_off` | `true` | Stop when the display goes off |
| `on` | `["manual"]` | Lock reasons that may play |

Both `enabled = true` and a matching reason in `on` are needed.

How it behaves:

- It waits 2 seconds after locking (up to 5 while a quiet stream exists) and starts only if no other audio played in that time.
- Tunes play in natural order (`1-`, `2-`, `10-`) and loop. A line under the clock names the tune (title, author and year from the SID header) and reminds you that `Esc` stops the music.
- With the spectrum shown, it visualises the tune.
- `Escape`, unlocking, suspend and (by default) the display going off stop it for the rest of that lock. After `Escape` the lock returns to quotes.
- The player is an ordinary `sidplayfp` child with no input: nothing you type reaches it, and it cannot affect authentication.

If it does not start, `~/.local/state/nirulock/trace.log` says why (for example "other audio is playing" or "lock reason idle"). `nirulock --config` prints the effective pause music setting.

## Lock settings

`~/.config/niruui/lock.toml` (every key optional):

| Key | Default | Meaning |
|---|---|---|
| `layout` | `"cava"` | `cava`, `minimal`, `terminal`, `runic`, `corner` |
| `visualizer` | `true` | `false` keeps the layout without the spectrum |
| `visual` | `"auto"` | `auto`, `cava`, `quotes`, `none` |
| `quotes` | `["*"]` | Collections by name or pattern |
| `prompt_echo` | `"count"` | `count` or `pulse` |
| `show_hostname` | `false` | Machine name under the clock |
| `font_size` | `22.0` | Text size (the NIRUX appearance font size when unset) |
| `font_path`, `rune_font_path` | unset | Specific font files |
| `[pause_music]` | off | See above |
| `[palette]` | theme | `background`, `foreground`, `muted`, `border`, `focus`, `warning` |

```sh
nirulock --config     # print the effective settings
nirulock --version
```

## Screensaver settings

`~/.config/niruui/screensaver.toml` (every key optional):

| Key | Default | Meaning |
|---|---|---|
| `layout` | `"cava"` | As for the lock |
| `visualizer`, `visual`, `quotes` | `true`, `"auto"`, `["*"]` | As for the lock |
| `show_media` | `true` | Artist and title of the playing track under the spectrum (needs `playerctl`) |
| `font_size` | `22.0` | Text size |
| `clock_size` | `88.0` | Clock size |
| `show_away_after_seconds` | `60` | When the away time appears |
| `dismiss_on_motion` | `false` | Dismiss after 24 px of pointer motion |
| `reduced_motion` | `false` | No 300 ms fade-in |
| `show_hostname` | `false` | Machine name under the clock |

## Troubleshooting

- **The right password is rejected.** Check the layout shown next to the prompt and the Caps Lock indicator. A PAM lockout message appears under the prompt.
- **The screensaver never appears.** Run `niructl timing show` and `niructl idle status`; keep awake or studio mode stops it.
- **No spectrum.** CAVA is not installed, `visual` is `quotes` or `none`, or (with `auto`) nothing plays loud enough.
- **No pause music.** Check `enabled = true`, the reason in `on`, `sidplayfp` and the `.sid` files, then read `~/.local/state/nirulock/trace.log`.
- **Suspend does not happen after `Super+Shift+Escape`.** The lock could not prove it holds the keyboard, so suspend was refused.
- X11 cannot fully isolate a lock screen from hostile programs on the same display.

## See also

- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [13-troubleshooting.md](13-troubleshooting.md)
- [14-configuration-reference.md](14-configuration-reference.md)
