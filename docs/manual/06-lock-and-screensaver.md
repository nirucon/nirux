# Lock screen and screensaver

NIRULOCK is the PAM lock screen and NIRUSCREENSAVER is the idle screen that comes before it. This chapter covers locking and unlocking, the idle timers, keeping the screen awake, the screensaver scenes, the layouts (including the C64 style `demo` lock screen), the CAVA spectrum and quotes, the pause music (the NIRUX music, shuffled, by default), and the NIRUX demo.

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
- While you type the password, each key and Backspace gives a soft typewriter click (the `lock-typing` sound, on by default). Turn it off with `nirux sounds toggle lock-typing`, in the launcher's sound view, or with `lock-typing = false` under `[sounds.system]` in `~/.config/nirux/sounds.toml`.
- Messages from PAM modules appear under the prompt, so a `pam_faillock` lockout ("The account is locked due to 3 failed logins") does not look like a wrong password.
- Keys are translated through XKB: dead keys, AltGr, keypad digits and composed letters reach PAM exactly as a terminal would type them. Input methods (IBus, Fcitx) are not used while locked.
- The lock never unlocks by itself.

Only PAM authentication of the process owner unlocks. NIRUX installs the PAM service `/etc/pam.d/nirulock`, which includes your distribution's normal login stack. If it is missing, the lock refuses to start; check with the standalone installer's `./install.sh --check` and read `~/.local/state/nirulock/trace.log`.

`prompt_echo = "count"` (default) shows one `*` per character, at most 32. `prompt_echo = "pulse"` shows a fixed row of eight cells with one lit `*` that jumps on every key, so the length is never shown.

## Lock and suspend

`Super+Shift+Escape` (or `niructl suspend`) starts NIRULOCK, waits for its verified readiness (`_NIRU_LOCK_READY`), keeps the lock visible for three seconds, checks that the same lock window is still there and only then asks logind to suspend. Repeated presses are merged, and unlocking during those three seconds cancels the suspend. If the lock cannot grab the keyboard, the suspend is refused, so the machine never sleeps unlocked.

For other suspends (lid close, a suspend from elsewhere) the session's sleep-lock helper locks first with reason `suspend`. It runs by default; `START_SLEEP_LOCK=0` in `~/.config/niruwm/session.conf` turns it off (restart the session after changing it).

With several monitors the screensaver draws its clock, panel and away time in the middle of each monitor, and it stays above the bars and every other window (NIRUSCREENSAVER 0.15.0 and later; before that it was centred across all monitors and the bars could show through).

A lock started while the screensaver is up (`niructl lock`, `Super+Shift+Escape`, a lid close) closes the screensaver first. Before NIRUWM 0.23.1 the screensaver kept the pointer, so such a lock failed.

With external monitors connected (docked), logind ignores the lid (`HandleLidSwitchDocked=ignore` in `/etc/systemd/logind.conf`), so the laptop stays awake. Closing the lid then locks the screen without suspending (NIRUWM 0.23.3 and later). Turn that off with `lock_on_lid_close = false` under `[idle]` in `~/.config/niruwm/config.toml`. Undocked, closing the lid locks and suspends as above.

## The idle ladder

`niruidle` (part of NIRUWM) watches how long since the last real input and runs three steps:

1. After `screensaver_timeout` idle minutes: the screensaver (a blank screen when NIRUSCREENSAVER is missing).
2. After `lock_after_screensaver` more minutes: the lock (reason `idle`).
3. After `dpms_off_after_lock` more minutes, only while locked: display off.

Any input before the lock resets the ladder. Only real input counts: keys, buttons, pointer movement and touch, from any device (including `xdotool` and remote desktop input). Since NIRUWM 0.37.16 a program cannot keep the screen unlocked by resetting the X server's idle clock (`XResetScreenSaver`, `xset s reset`), which a browser window opened by a script, such as Playwright's Chromium, can do every few minutes; before that, such a program kept the screensaver and the lock away. A program that should keep the screen on asks for it the documented way (below), and `niructl idle status` shows it. NIRUIDLE keeps the X server's own blank and DPMS timers (`xset q`) at zero, so the display is not turned off before the ladder gets there; before NIRUWM 0.23.1 the server's defaults switched the display off after 10 minutes, which looked like a lock but was not one. The timers live in `[idle]` in `~/.config/niruwm/config.toml`:

```toml
[idle]
screensaver_timeout = 15      # idle minutes before the screensaver (at least 1)
lock_after_screensaver = 15   # screensaver minutes before locking
dpms_off_after_lock = 15      # minutes after locking before the display sleeps; 0 keeps it on
lock_on_lid_close = true      # docked: closing the lid locks (no suspend)
```

| Key | Default | Range |
|---|---|---|
| `screensaver_timeout` | `15` | 1 to 1440 |
| `lock_after_screensaver` | `15` | 0 to 1440 |
| `dpms_off_after_lock` | `15` | 0 to 1440 |
| `lock_on_lid_close` | `true` | `true` or `false`: lock when the lid closes while docked |

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
| `niructl idle status` | `idle on (no expiry)`, `idle on, N min remaining` or `idle off`; then a `session inhibit: HOLDER` line (studio mode) and an `app inhibit: APP (REASON)` line for each program that asks the screen to stay awake |
| Launcher | `keep awake` / `håll vaken`, or **Toggle idle inhibition** in Quick Settings |

`niructl idle on` means idle *inhibition* is on: no screensaver, no idle lock, no display off. The state is kept in `~/.local/state/niruui/inhibit`. Studio mode (`niructl studio on`) also inhibits the saver and the idle lock while it is on. Manual locking always works.

### Programs that keep the screen awake

Programs can ask the screen to stay awake while they need it: Helium while a
video plays or during a call (Teams, Meet), VLC while it plays. NIRUIDLE answers
these requests (the standard `org.freedesktop.ScreenSaver` service on the
session bus, NIRUWM 0.29.0 and later). While a program holds one, there is no
screensaver, no idle lock and no display off; the timers start from zero when
the last request ends. A program that quits or crashes loses its request at
once. `niructl idle status` lists the requests, and the session log has lines
like `niruidle: app inhibit on: helium (Video Wake Lock)`.

Be aware: a video left playing in a browser tab keeps the screen from locking
by itself (GNOME and KDE behave the same). Super+Escape, `niructl lock`,
closing the lid and suspend still lock. Helium only asks for videos with a
sound track. To ignore all such requests:

```toml
[idle]
honor_app_inhibit = false
```

An update that restarts NIRUIDLE drops the requests held so far; programs ask
again when they next start playing.

## Lock when your phone leaves

NIRUIDLE can lock the session when your phone goes out of Bluetooth reach, for
example when you walk away from the desk with it in your pocket (NIRUWM 0.33.0
and later). It is off until you name the phone.

```sh
niructl proximity devices      # paired Bluetooth devices and their addresses
niructl proximity set "Pixel 8"   # by name or by address (AA:BB:CC:DD:EE:FF)
niructl proximity status       # the phone, the delay, and whether it answers now
niructl proximity test         # ask the phone once and say how long it took
niructl proximity off
```

Pair the phone first (Bluetooth in Quick Settings, or `bluetoothctl`). Every
ten seconds NIRUIDLE pages the phone once, the way `l2ping` does but without
root. It does not connect to anything on the phone, and the phone shows no
prompt. When the phone has not answered for `proximity_lock_after` seconds
(and at least twice in a row), the session locks.

```toml
[idle]
proximity_device = "AA:BB:CC:DD:EE:FF"   # "" (the default) turns it off
proximity_lock_after = 30                # seconds out of reach, 10 to 600
```

How it behaves:

- It only locks after the phone has answered at least once since you logged
  in or unlocked. Unlocking with the phone somewhere else does not lock again
  right away; the phone has to come back first.
- It also locks while a video plays, while `niructl idle on` or studio mode
  keeps the screen awake: those are for someone in front of the screen.
- When the phone comes back while the screen is locked, the display turns on
  so the password prompt is ready. It **never unlocks**: you still type your
  password.
- With Bluetooth switched off, or no adapter, it does nothing at all (the
  session log says `cannot check`).
- The session log (`~/.local/state/niruwm/session.log`) has a line each time
  the phone comes or goes: `niruidle: proximity: phone out of reach`.

Bluetooth reaches through walls, often ten metres or more, so it locks when you
have really left, not when you stand up. The ordinary idle ladder still runs
beside it. A phone with Bluetooth switched off, or in flight mode, counts as
gone. Some phones stop answering in deep sleep; if the screen locks while the
phone lies on the desk, raise `proximity_lock_after`.

## The screensaver

NIRUSCREENSAVER covers every screen with one of its scenes: by default the date, a large clock, how long you have been away and, while music plays, a CAVA spectrum with the playing track. It is **not a lock**: any key or click dismisses it, and that key or click is swallowed so it never reaches the window underneath. Pointer motion does not dismiss it unless `dismiss_on_motion = true` (after 24 px).

```sh
niructl screensaver          # show it now on every monitor (also Super+Alt+Z)
niruscreensaver --preview    # show it on one monitor only, to compare settings
niruscreensaver --preview photos   # preview a scene without choosing it
niruscreensaver --config     # print the effective settings
```

## Choose a scene

The launcher's **Screensaver** view (NIRUX Settings, or `nirulauncher --screensaver`) lists the scenes with what each shows, the chosen one first with a **Preview** row that shows it on this monitor. `Enter` on another scene chooses it. The rows below choose which scenes `shuffle` may pick and step through the clock layout, the clock panel, the track line, the seconds per photo and reduced motion. The same from a terminal (NIRUSCREENSAVER 0.16.0 and later):

```sh
niruscreensaver --list                      # the scenes, the chosen one, the shuffle list
niruscreensaver --set scene dark-sid        # choose a scene
niruscreensaver --shuffle toggle photos     # add or remove a scene from shuffle
niruscreensaver --set photos_folder ~/Pictures/Trips
```

Changes are written to `~/.config/niruui/screensaver.toml` with its comments kept, and a value the screensaver would refuse is refused before anything is written. The next time the screensaver appears it reads the file.

| Scene | Shows |
|---|---|
| `clock` | Default. The clock in one of the layouts below, with the spectrum or a quote |
| `photos` | The pictures in `photos_folder` (default `~/Pictures/Wallpapers/NIRU`, the NIRUX wallpapers), each for `photos_seconds`, drifting slowly and crossfading, with a small clock in the corner. Without pictures the clock is shown |
| `dark` | Black, with only the line "NIRUX - A MINIMAL X11 DESKTOP" gliding slowly across each screen |
| `dark-sid` | As `dark`, with the [pause music](#pause-music) (the NIRUX music by default) and the tune's name under the line |
| `ascii` | "NIRUX ascii": black, with a large NIRUX banner in ASCII and "A MINIMAL X11 DESKTOP" under it, centred and sized for each screen. The banner takes the theme's accent colour (the text colour when the accent is too dark to read on black). It is typed out one character at a time behind a block cursor that blinks once a second when the text is done; after a minute it is erased backwards, the screen stays black for a few seconds, and it is typed again, shifted a little from the centre (NIRUSCREENSAVER 0.17.1 and later) |
| `ascii-sid` | As `ascii`, with the pause music like `dark-sid` and the tune under the text |
| `c64` | NIRUX as a Commodore 64 demo, silent: a BASIC boot, then a bouncing NIRUX logo with raster bars and a scroller that shows the time, a dot sphere with bouncing balls under the runes for NIRUX, and Yggdrasil before a plasma, in C64 colours picked by your theme (NIRUSCREENSAVER 0.19.0 and later) |
| `c64-sid` | As `c64`, with the NIRUX music like `dark-sid`, the tune in the top border and the effects pulsing on the beat |
| `demo` | The [NIRUX demo](#the-nirux-demo-and-music) on every screen, silent and in a loop. Without NIRUDEMO, or when it fails to start, that screen shows `dark` (NIRUSCREENSAVER 0.18.0 and later) |
| `shuffle` | One of the scenes in `shuffle` (default `clock`, `photos`, `dark`), a new pick every time |

`dark-sid` and `ascii-sid` use the lock's [pause music](#pause-music) player and folder (`[pause_music] folder` in `lock.toml`, default the NIRUX music in `~/.local/share/nirux/music`). It starts only when nothing else played during the first 2 seconds. Unlike the lock, it also plays when the screensaver starts by itself after the idle timeout, because choosing `dark-sid` or `ascii-sid` is the choice to play. The music stops when the display goes off, when a key or click ends the screensaver, and when the idle lock takes over.

`photos` reads PNG and JPEG files two folder levels deep; when a wallpaper exists as `-4k` and `-8k`, the 4K one is used. With several monitors every scene draws on each one. `reduced_motion = true` stops the photo drift and crossfade and moves the dark line once a minute instead of gliding; `ascii` then shows the whole text at once, with a still cursor, shifted a little every minute.

`c64` turns each screen into a Commodore 64: a 320x200 picture with sharp pixels inside a border that reaches the screen's edges. After a short BASIC boot (`LOAD"NIRUX",8,1` with loading stripes) it loops three parts, the border closing over the screen between them: NIRUX, with raster bars, a bouncing logo and a wavy scroller that greets you with the time; BIFROST, a spinning dot sphere among shaded balls under the runes for NIRUX; and YGGDRASIL, the world tree before a colour plasma. It uses only the sixteen C64 colours, picked from your theme. It costs about 2 % of one core on a 1080p screen, draws nothing while the display is off, and with `reduced_motion = true` shows a still part that changes every minute. `c64-sid` adds the music exactly like `dark-sid`. Try it with `niruscreensaver --preview c64`, choose it with `niruscreensaver --set scene c64`, or add it to the shuffle list with `niruscreensaver --shuffle add c64`.

## Choose a layout

Set `layout` in `~/.config/niruui/lock.toml` (lock) or `~/.config/niruui/screensaver.toml` (screensaver). Both programs know the same five:

| Layout | Composition |
|---|---|
| `cava` | Default. Large clock above the spectrum or a quote; on the lock, state, away time and prompt below |
| `minimal` | Centred clock (and on the lock: state, away time and prompt) |
| `terminal` | Left-aligned monospace screen with a `~$ lock` / `~$ idle` line |
| `runic` | The minimal composition with a discreet rune row when a runic font is available |
| `corner` | Clock top-left, away time at the bottom (prompt centred on the lock) |
| `demo` | Lock only (NIRULOCK 0.30.0 and later): the C64 demo lock screen, see [The demo layout](#the-demo-layout) |
| `attract` | Lock only (NIRULOCK 0.31.0 and later): an arcade cabinet in attract mode, NIRUX RAID plays itself, see [The attract layout](#the-attract-layout) |
| `satie` | Lock only (NIRULOCK 0.32.0 and later): a C64 tape loading screen of Erik Satie with Gymnopédie, see [The satie layout](#the-satie-layout) |
| `bbs` | Lock only (NIRULOCK 0.33.0 and later): NIRUX BBS, a dial-up bulletin board in ANSI art, see [The bbs layout](#the-bbs-layout) |

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

## Pause music

NIRULOCK plays music while the screen is locked. It is on by default (NIRULOCK 0.30.0 and later) but plays only for the lock reasons you allow, by default only a manual lock (Super+Escape, the launcher, Quick Settings or `niructl lock`), so an idle lock, a suspend, the lid or a script never starts music, and a laptop that locks itself during a meeting stays silent.

By default it plays the NIRUX music: eleven original chiptunes in minor keys made for NIRUX by [NIRUDEMO](#the-nirux-demo-and-music) and an arrangement of Erik Satie's Gymnopédie No. 1, installed by NIRUX in `~/.local/share/nirux/music` as `nirux-1-ginnungagap.ogg` to `nirux-12-gymnopedie.ogg` (NIRULOCK 0.29.0 and later; before that the default folder was `~/Music/SID`). They play with `pw-play`, `ffplay` or `mpv`, whichever is installed.

To play your own C64 SID tunes instead, put the `.sid` files in a folder and name it as `folder`, for example `~/Music/SID`. They need `sidplayfp` (Debian and Void: `sidplayfp`; Arch: the AUR package `sidplayfp`). An HVSC `Songlengths.md5` in the folder (or its `DOCUMENTS` directory) gives each tune its real length. A folder may mix `.sid` files with `.ogg`, `.opus`, `.flac` and `.wav` files.

Change it in `~/.config/niruui/lock.toml`:

```toml
[pause_music]
enabled = true               # false turns the music off
shuffle = true               # false plays in natural order (1-, 2-, 10-)
# folder = "~/Music/SID"     # your own tunes instead of the NIRUX music
track_seconds = 180          # per SID tune without Songlengths.md5 (5 to 3600)
stop_on_display_off = true
on = ["manual"]              # reasons that play: manual, idle, suspend, script, session, unspecified
```

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Master switch |
| `shuffle` | `true` | Random order: a random first tune, every tune once per round, never the same twice in a row; SID tunes play their default subtune |
| `folder` | `"~/.local/share/nirux/music"` | Where the tunes are |
| `track_seconds` | `180` | SID tune length when `Songlengths.md5` does not know it; other files play to their end |
| `stop_on_display_off` | `true` | Stop when the display goes off |
| `on` | `["manual"]` | Lock reasons that may play |

Both `enabled = true` and a matching reason in `on` are needed. `dbus-monitor` is used to stop the music before suspend.

How it behaves:

- It waits 2 seconds after locking (up to 5 while a quiet stream exists) and starts only if no other audio played in that time.
- Tunes play shuffled (or in natural order, `1-`, `2-`, `10-`, with `shuffle = false`) and loop. A large collection, even a whole HVSC, never delays the lock: the folder is listed in the background for at most 1.5 seconds. A line under the clock names the tune (for the NIRUX music "♪ Ginnungagap · NIRUX 1"; for SID tunes the title, author and year from the SID header) and reminds you that `Esc` stops the music.
- With the spectrum shown, it visualises the tune.
- `Escape`, unlocking, suspend and (by default) the display going off stop it for the rest of that lock. After `Escape` the lock returns to quotes.
- The player is an ordinary child process with no input: nothing you type reaches it, and it cannot affect authentication.

If it does not start, `~/.local/state/nirulock/trace.log` says why (for example "other audio is playing" or "lock reason idle"). `nirulock --config` prints the effective pause music setting.

## The demo layout

`layout = "demo"` in `lock.toml` turns the lock screen into a small Commodore 64 style demo: a big chunky NIRUX logo, built from NIRUSID's own 8x8 pixel font, wobbles over moving raster bars and a starfield, and a sine scroller along the bottom carries the time, how long the screen has been locked, the tune that plays and a quote (the hostname too with `show_hostname = true`). While music plays the bars and the logo flash on the beat. The colours come from the active NIRUX theme on a black background.

The clock, the password prompt, the keyboard layout, Caps Lock and every failure message stay in the theme font in the calm black middle of the screen; a failed attempt also turns the bars to the warning colour. Every monitor shows the logo and the scroller. It animates at 25 frames a second (fewer on very large screens) and stops drawing when the display is off. The default layout is still `ascii-cava`.

The scroller names the tune by artist and title only (`NOW PLAYING  NIRUX - GIMLE`), as its own segment after the quote, and the quote is in quotation marks with its source.

## The attract layout

`layout = "attract"` makes the lock screen an arcade cabinet nobody is playing. Like a Commodore 64 game left alone it shows its title screen, the high scores and a game that plays itself until GAME OVER, then starts again with a new game. NIRUX RAID is NIRULOCK's own shoot 'em up: a rune craft flown by a small AI over a river through a Norse forest, against wisps, drones, rune towers and longships. The picture is 320x200 pixels in 16 colours from the active theme, scaled up with sharp pixels inside a frame. The clock, password prompt and messages stay on black below it, and a failed attempt turns the frame to the warning colour. Typing never reaches the game. While pause music plays, the tune shows as `NOW PLAYING  ARTIST - TITLE` and explosions flash on the beat. It costs about 1 % of one core and draws nothing with the display off.

## The satie layout

`layout = "satie"` is a C64 game loading from tape, except that the game is Erik Satie. PRESS PLAY ON TAPE, SEARCHING, FOUND ERIK SATIE, and his portrait loads cell by cell while coloured loader stripes flicker in the border, until READY. It loads again every five minutes. The portrait is Henri Manuel's public domain photograph from about 1920, coloured from the active theme (the `niru-satie` theme gives it sepia). When NIRUX's Gymnopédie (`nirux-12-gymnopedie.ogg`) is installed it is this layout's pause music, played again and again, under the usual pause music rules. The prompt and messages stay on black below the picture.

## The bbs layout

`layout = "bbs"` makes the lock screen a bulletin board from the dial-up modem days. The terminal resets the modem, dials (`ATDT`), and after RINGING and CONNECT 14400/ARQ/V42BIS the board streams in at 14400 bps: an ANSI Yggdrasil under the moon, the NIRUX logo over BULLETIN BOARD, a SYSTEM box (node, connection, date, time, time online, status), the MESSAGE OF THE DAY from the quotes, the playing tune as `NOW PLAYING  ARTIST - TITLE`, and a `LOGIN: SYSOP` / `PASSWORD:` prompt that follows `prompt_echo`. A status bar at the bottom has modem lights that blink as you type. A wrong password shows ACCESS DENIED. Any key skips the call. Every five minutes the line drops (NO CARRIER) and it calls again with a new message, unless you are typing or a login failed. When pause music plays (by default only for a manual lock), a quiet SID style modem handshake plays first, then the music. The 16 ANSI colours come from the active theme, nothing private is shown (the login is always SYSOP), and with reduced motion on (`[motion] reduced` in the NIRUX appearance) the board shows at once without blinking or redialling. It costs well under 1 % of one core.

## The NIRUX demo and music

NIRUDEMO is the NIRUX easter egg: a demoscene demo in the spirit of the home computer and console intros of the 1980s and 1990s, drawn at 320 by 180 pixels and scaled up with sharp pixels, in the colours of the active theme, with its own music.

| Keys / command | Effect |
|---|---|
| `Super+Alt+D` | Play the demo on every screen. Any key or click ends it |
| `demo` in the launcher (`Super+P`) | The same |
| `demos` in the launcher, or `nirulauncher --demos` | The Demos view: every demo with its length; `Enter` plays one |
| `nirux demo [N]` | Play demo N (default the first) |
| `nirux demo list` / `nirux demo songs` | The demos, and the NIRUX music |
| `scene = "demo"` in `screensaver.toml` | The demo as the screensaver, silent and in a loop |

Demo 1 is **Ginnungagap**: stars out of the void, the title, raster bars, a low-poly N turning over a grid in fog, plasma with a sine scroller, a tunnel and greetings from the machine it runs on. Every demo is named after its song. The music stays off while Do Not Disturb is on, and the demo ends at once if the screen locks.

The NIRUX music (the default pause music above) is twelve pieces. Eleven are originals of about two minutes each: Ginnungagap, Yggdrasil, Hel, Fimbulvetr, Mimir, Surtr, Norns, Nidhogg, Vanaheim, Ragnarok and Gimle, in minor keys, between dark ambient, the C64 sound (fast arpeggios, pulse bass, vibrato and echo) and calm pieces in the spirit of Erik Satie. The twelfth is Gymnopédie: Erik Satie's Gymnopédie No. 1 (1888, public domain) arranged for NIRUX in the SID sound as a seamless loop of about three and a half minutes (`nirux-12-gymnopedie.ogg`, NIRUDEMO 0.2.0 and later). Any music player plays the files in `~/.local/share/nirux/music`.

## Lock settings

`~/.config/niruui/lock.toml` (every key optional):

| Key | Default | Meaning |
|---|---|---|
| `layout` | `"ascii-cava"` | `ascii-cava`, `ascii`, `cava`, `minimal`, `terminal`, `runic`, `corner`, `demo`, `attract`, `satie`, `bbs` |
| `visualizer` | `true` | `false` keeps the layout without the spectrum |
| `visual` | `"auto"` | `auto`, `music`, `cava`, `quotes`, `none` (`auto` in `ascii-cava`: the spectrum while music plays, otherwise nothing) |
| `quotes` | `["*"]` | Collections by name or pattern |
| `prompt_echo` | `"count"` | `count` or `pulse` |
| `show_hostname` | `false` | Machine name under the clock |
| `font_size` | `22.0` | Text size (the NIRUX appearance font size when unset) |
| `font_path`, `rune_font_path` | unset | Specific font files |
| `[pause_music]` | on for manual locks | See above |
| `[palette]` | theme | `background`, `foreground`, `muted`, `border`, `focus`, `warning` |

```sh
nirulock --config     # print the effective settings
nirulock --version
```

### NIRUX ascii on the lock screen

The lock screen looks like an old terminal by default (`ascii-cava`,
NIRULOCK 0.28.0 and later). When the screen locks, the NIRUX banner is typed
out slowly on every monitor, one `#` at a time, with "A MINIMAL X11 DESKTOP"
under it and a block cursor that blinks after the line when the text is done.
The character just typed glows white and settles into the theme's accent
colour (the text colour when the accent is too dim on black); a large banner
has a dark scanline through every third pixel row. On the monitor with the
prompt, the CAVA spectrum, as wide as the banner, shows under the text while
music plays; then the clock, the password entry and the away time. You can
type your password at once: the typing never holds the prompt up.

| `layout` | Looks like |
|---|---|
| `ascii-cava` | The banner, the spectrum while music plays, the prompt (default) |
| `ascii` | The banner and the prompt, no spectrum |
| `cava` | The large clock above the spectrum or a quote (the default before 0.12.299) |

Switch in `~/.config/niruui/lock.toml`, or on every machine at once:

```sh
nirux fleet set lock.layout cava         # back to the spectrum and quotes
nirux fleet set lock.layout ascii-cava   # NIRUX ascii again
```

```toml
layout = "cava"
```

The next lock uses the new layout; nothing needs a restart.

## Screensaver settings

`~/.config/niruui/screensaver.toml` (every key optional):

| Key | Default | Meaning |
|---|---|---|
| `scene` | `"clock"` | `clock`, `photos`, `dark`, `dark-sid`, `ascii`, `ascii-sid`, `demo` or `shuffle`; see [Choose a scene](#choose-a-scene) |
| `shuffle` | `["clock", "photos", "dark"]` | The scenes `shuffle` picks from |
| `photos_folder` | `"~/Pictures/Wallpapers/NIRU"` | Pictures for `photos` |
| `photos_seconds` | `20` | Seconds per photo, 5 to 3600 |
| `layout` | `"cava"` | The clock scene's layout, as for the lock |
| `visualizer`, `visual`, `quotes` | `true`, `"auto"`, `["*"]` | As for the lock |
| `show_media` | `true` | Artist and title of the playing track under the spectrum (needs `playerctl`) |
| `font_size` | `22.0` | Text size |
| `clock_size` | `88.0` | Clock size |
| `show_away_after_seconds` | `60` | When the away time appears |
| `dismiss_on_motion` | `false` | Dismiss after 24 px of pointer motion |
| `reduced_motion` | `false` | No 300 ms fade-in, no photo drift or crossfade, the dark line moves once a minute |
| `show_hostname` | `false` | Machine name under the clock |

## Troubleshooting

- **The right password is rejected.** Check the layout shown next to the prompt and the Caps Lock indicator. A PAM lockout message appears under the prompt.
- **The screensaver never appears.** Run `niructl timing show` and `niructl idle status`; keep awake, studio mode or a program's request (an `app inhibit:` line, for example a playing video) stops it. The session log `~/.local/state/niruwm/session.log` has the `niruidle:` lines.
- **No spectrum.** CAVA is not installed, `visual` is `quotes` or `none`, or (with `auto`) nothing plays loud enough.
- **No pause music.** Check `enabled = true`, the reason in `on`, `sidplayfp` and the `.sid` files, then read `~/.local/state/nirulock/trace.log`.
- **The screen does not lock by itself.** The lock comes `screensaver_timeout` + `lock_after_screensaver` minutes after the last input (30 with the defaults). Shorten it with `niructl timing set lock_after_screensaver 5`, or lock as the screensaver starts with `0`. Video players and calls can keep the session awake.
- **Suspend does not happen after `Super+Shift+Escape`.** The lock could not prove it holds the keyboard, so suspend was refused.
- X11 cannot fully isolate a lock screen from hostile programs on the same display.

## See also

- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [13-troubleshooting.md](13-troubleshooting.md)
- [14-configuration-reference.md](14-configuration-reference.md)
