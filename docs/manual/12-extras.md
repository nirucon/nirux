# Extras

Extras are optional NIRU applications with their own repositories and release cadence. This chapter explains how to install, update and remove them with `nirux extras`, then gives a short practical tour of each one, and ends with the small core tools NIRUWEBAPP, NIRUFETCH and NIRUSHARE.

## How extras work

All extras are native programs drawn directly on X11, like the core suite: NIRUNOTE, NIRUPRES and NIRUFLOW are no longer Python and Qt, NPLAY is no longer Python, and NIRUAMP, NIRUSEC, NIRUGAME and NIRUDICTATE no longer use a GPU toolkit. They open in a few hundredths of a second and use about 8 to 20 MB. Updating an extra from an older version replaces the old install and keeps your files and settings.

A normal `nirux install` or `nirux update` never installs an extra. You ask for each one by name. Every NIRUX release pins one version of each extra, together with the SHA-256 of its source archive.

| Extra | Pinned | What it is | Status |
|---|---|---|---|
| [nirunote](#nirunote-markdown-editor) | 1.0.0 | Minimal Markdown editor and viewer | beta |
| [nirupres](#nirupres-presentations) | 3.1.0 | Presentation studio | beta |
| [nplay](#nplay-terminal-music-player) | 2.0.2 | Terminal music, radio and podcast player; also fully standalone | beta |
| [niruamp](#niruamp-graphical-frontend-for-nplay) | 0.7.1 | Graphical frontend for NPLAY with three retro skins (Classic, Phosphor, Hi-Fi Deck) and a levelled spectrum (requires NPLAY) | alpha |
| [niruflow](#niruflow-maintenance-and-cleanup) | 1.0.0 | Local maintenance and automation | alpha |
| [nirusec](#nirusec-firewall-and-security-overview) | 0.3.2 | Firewall, ports, updates, firmware and security overview | alpha |
| [nirugame](#nirugame-game-launcher) | 0.3.0 | Steam games, ROMs from your folders and RetroArch, and native games, with box art and optional SID music | alpha |
| [niruremote](#niruremote-remote-desktop) | 0.2.0 | Graphical remote desktop over Tailscale and SSH | alpha |
| [nirudictate](#nirudictate-local-dictation) | 0.4.0 | Local speech-to-text dictation, voice commands, and voice messages to opencode | alpha |
| [docker-stacks](#docker-stacks-docker-in-the-terminal) | 1.0.1 | Docker Compose stacks, containers, images, volumes and networks in the terminal | beta |
| [niruprodrive](#niruprodrive-proton-drive-backup-and-sharing) | 0.1.6 | Proton Drive backups per computer, sending, fetching and links, with a tray cloud | alpha |
| [nirutoday](#nirutoday-today-at-a-glance) | 0.1.1 | Today at a glance in a teletext look: SMHI weather, Sveriges Radio news, VMA, electricity price, name day and calendar | alpha |
| [nirusid](#nirusid-sid-music-player) | 0.1.1 | SID music player with HVSC lengths and STIL, raster bars and a chip view; the default player for .sid files | alpha |
| [nirusys](#nirusys-system-monitor) | 0.1.0 | Retro system monitor: CPU, memory, disks, network, GPU, sensors, battery, processes and system panels with phosphor graphs, 24-hour history and alerts; full window, desktop widget or mini strip | alpha |
| [nirusettings](#nirusettings-settings) | 0.2.1 | The NIRUX settings in one retro window: theme, window manager, bar, lock screen, screensaver, sounds, key bindings, extras and updates, checked before they are written | alpha |
| [nirux-thegame](#nirux-the-game) | 0.2.0 | NIRUX, the game: an original C64-style shooter in eight sectors with SID-style music, three play modes, gamepad support and crisp scaling on any screen | alpha |

### Install, update and remove

```sh
nirux extras list                      # NAME, PINNED, INSTALLED, SELECTED
nirux extras status                    # the same table
nirux extras install niruflow          # install one (or several: install nplay niruamp)
nirux extras install                   # install every selected extra
nirux extras update                    # bring selected extras to the pinned versions
nirux extras select niruflow           # remember a choice without installing
nirux extras unselect niruflow         # stop updating it; nothing is removed
nirux extras uninstall niruflow        # the extra's own uninstaller; keeps its data
nirux extras uninstall niruflow --purge
```

What happens on `install`:

1. NIRUX downloads the pinned source tag from GitHub and checks its SHA-256 before unpacking. A mismatch stops with "nothing changed".
2. It runs that project's own `install.sh`.
3. It checks that the command works (`NAME --version`) and marks the extra as selected in `~/.local/share/nirux/extras-selected`.

`update` only touches selected extras whose installed version differs from the pin, and takes a NIRUX snapshot first when anything will be installed. `uninstall` (also spelled `remove`) runs the extra's own `uninstall.sh` from the same pinned source and unselects it. Every extra keeps your data on a normal uninstall; `--purge` is passed to the uninstallers that support it (NPLAY, NIRUAMP, NIRUPRES, NIRUFLOW, NIRUREMOTE, NIRUDICTATE, docker-stacks, niruprodrive, NIRUTODAY). Uninstall extras before `nirux uninstall`, which removes the `nirux` command itself.

The bar's update module tracks the core NIRUX release only, not each extra. After `nirux update`, run `nirux extras update` to follow the new pins.

### Consent and sudo

Extra installers may install runtime packages and ask for `sudo`; read their output.

- **In a terminal** the installer asks before installing packages, as usual.
- **Without a terminal** (a deployment script, a graphical update) nobody can answer, so NIRUX sets `NIRUX_ASSUME_YES=1`: asking NIRUX for the extra is the consent.
- **Without a terminal and without a password held by NIRUX**, an extra that needs `sudo` fails at once with "this extra needs sudo, and there is no terminal to ask for the password". It does not try, because each failed sudo counts toward `pam_faillock`, and three failures lock the account (screen lock included) for ten minutes. Run `nirux extras install NAME` in a terminal instead.

NIRUX never deletes an extra's user data when you unselect it. The full description is in [docs/EXTRAS.md](https://github.com/nirucon/nirux/blob/main/docs/EXTRAS.md).

## NIRUORG left the suite

NIRUORG was replaced by NIRUFM, the file manager that ships with NIRUX
(`Super+Shift+F`, see [Getting started](01-getting-started.md#files-and-folders)).
`nirux extras update`, which the nightly update runs, removes an installed
NIRUORG with its own uninstaller. Its settings in `~/.config/NIRU` and
`~/.config/niruorg` are left in place.

## NIRUNOTE: Markdown editor

A small, quiet editor and viewer for plain Markdown files with a styled preview, find and replace, an outline, crash recovery and optional Hunspell spell checking (the installer fetches a Swedish dictionary). No accounts, no cloud. Status: beta.

The preview renders CommonMark and GitHub Markdown: nested lists and quotes, task lists, aligned tables, strikethrough, footnotes, reference links, bare URLs, GitHub alerts (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) and fenced code highlighted in the theme colours (skipped above 300k characters). Long lines and wide tables wrap. Local images are scaled to the page; remote images load in the background while visible (turn them off with **Remote images in Preview** in Preferences). Raw HTML is not run: a small formatting subset such as `kbd`, `sub`, `sup` and `mark` is kept. Relative Markdown links open in the same window, `#anchor` links scroll, and `Alt+Left` goes back. The manual (`nirux manual`) opens in NIRUNOTE as a read-only viewer at the chosen heading.

```sh
nirux extras install nirunote
nirunote                 # reopen the last document (if enabled in Preferences)
nirunote notes.md
nirunote --new
nirunote --focus         # start in focus mode
nirunote --scratchpad    # a separate scratch note
nirunote README.md --read-only           # viewer: no editing, saving or recovery data
nirunote notes.md --heading "Next steps" # open at a heading (title, part of it, or #slug)
nirunote notes.md --preview              # start in Preview
```

| Keys | Action |
|---|---|
| `Ctrl+N` / `Ctrl+O` / `Ctrl+P` | New / open / Quick Open |
| `Ctrl+S` / `Ctrl+Shift+S` | Save / Save As |
| `Ctrl+Shift+E` | Toggle Edit and Preview |
| `Ctrl+F` / `Ctrl+H` | Find (in the Preview when it is shown) / replace |
| `F3` / `Shift+F3` | Find next / previous (`Esc` closes the find bar) |
| `Alt+Left` | Back, after following a link in the Preview |
| `Ctrl++` / `Ctrl+-` / `Ctrl+0`, `Ctrl`+wheel | Zoom in / out / reset |
| `Ctrl+B` / `Ctrl+I` / `Ctrl+K` | Bold / italic / link |
| `Ctrl+Shift+X` | Toggle a checkbox |
| `Ctrl+G` / `Ctrl+Shift+O` | Go to heading / outline (also in the Preview) |
| `Ctrl+Shift+P` | Command palette |
| `F11` | Focus mode |
| `Ctrl+Shift+F` | Toggle floating window |

Settings are in **View** and **View → Preferences…**; the default save folder is `~/Documents`.

- Preferences: `~/.config/NIRU/NIRUNOTE.conf`
- Scratch note and recovery: `~/.local/state/nirunote/`

Full documentation: [github.com/nirucon/nirunote](https://github.com/nirucon/nirunote).

## NIRUPRES: presentations

A keyboard-oriented presentation studio: 25 slide layouts, 17 slide themes, speaker notes, a presenter window and an audience window on the screen you choose, PDF and image-based PPTX export, and Talk mode, which records the slides, your voice and a small camera picture with NIRUCLIP and writes a chapter per slide. Every deck is one `.nirupres` file with its images inside. Status: beta.

```sh
nirux extras install nirupres
nirupres                                  # the editor
nirupres --present deck.nirupres          # present from the start
nirupres --talk deck.nirupres             # present and record (slides-camera, slides, camera or auto)
nirupres --export-pdf deck.nirupres out.pdf
nirupres --check-config
```

| Keys | Action |
|---|---|
| `Ctrl+Enter` | Add a slide |
| `Ctrl+D` | Duplicate the slide |
| `Alt+Up` / `Alt+Down` | Move the slide |
| `Ctrl+K` | Command palette |
| `Ctrl+Shift+E` | Export to PDF |
| `F5` / `Shift+F5` | Present from the current slide / from the start |
| `Right`, `Space` / `Left` | Next / previous slide while presenting |
| `B` / `W` | Black / white screen |
| `S` / `F` / `Z` | Spotlight / focus reveal / zoom; `[` `]` size them. Aim with the mouse over CURRENT in the presenter view (a click pins) |
| `C` / `P` | Curtain / pause |
| `Esc` | End the presentation |
| `Ctrl+-` / `Ctrl++` | Smaller / larger speaker notes in the presenter view |

### Presenting in Teams, Meet or Zoom

Share the **window**, never the entire screen. In the browser's share dialog
choose the **Window** tab and the window named `AUDIENCE · share this ·
NIRUPRES`. The presenter view is called `PRIVATE presenter · do not share` and
has a red "PRIVATE · NOT FOR SHARING" bar, also in the dialog's thumbnail.

- **One screen (laptop):** F5 asks for *Laptop presenter* (the presenter view
  fills the screen and the 16:9 audience window waits behind it, still shared
  live) or *Slides only*. "Remember my choice" keeps the answer.
- **Docked:** the audience window goes full screen on the other screen and the
  presenter view stays on yours.
- **Share check:** before an online presentation NIRUPRES says which window to
  pick and flashes a green "SHARED WINDOW · AUDIENCE" frame on it for 5 s.
  The timer starts when you press Start.
- **Switch workspaces freely.** NIRUWM keeps the audience window live for the
  share while you look at other workspaces (`_NIRUWM_KEEP_MAPPED`); nothing
  from them reaches the audience. Come back to NIRUPRES to change slides; the
  presenter view has the keyboard at once.
- **Presenting mode:** NIRUPRES runs `niructl present on`, which turns on Do
  Not Disturb and hides the private bar modules (`[bar] presenting_hide`);
  both come back when the presentation ends, also if NIRUPRES crashes.
- **Fades:** the show fades in from black when it starts (online: after
  *Start presenting*) and out to black at the end; `Esc` again closes at once.
  Next on the last slide fades to black; Next or `Esc` ends, Previous goes
  back. CURRENT in the presenter view shows the fades, transitions and the
  spotlight exactly as the audience sees them.
- The presenter view shows the current and next slide, a large timer with
  pace, the clock, `x / y` and the speaker notes (at least a third of the
  height; `A−`/`A+` sizes are remembered).

### Talk mode: record a talk

*(NIRUPRES 3.1, NIRUCLIP 0.14)* **TALK** in the toolbar (or `Ctrl+K`, *Talk · record a talk…*) asks what to record and then presents from the first slide while NIRUCLIP records:

- **Slides + microphone + small camera** (the default when a camera is connected): the camera sits in the bottom-right corner, 16 % of the picture height, rounded with a thin accent border, so it stays clear of the slide content.
- **Slides + microphone.**
- **Camera + microphone (no slides).**
- **Include the sound of videos in the slides** also records the computer's sound (all of it; Do Not Disturb is on while you present).

Only the slides are recorded, never the presenter view with your notes, timer and next slide. NIRUCLIP records the audience window by its window id, not the screen. On one screen your presenter view fills the screen and the slides go to an off-screen recording stage of 1080 lines in the deck's aspect, so the video is a clean 1080p whatever the laptop's resolution; with two screens the projector window is recorded. The presenter view shows a red **● REC** badge with the recording time (amber **NOT RECORDING** with the reason if it stops) and your live camera picture in CURRENT, where and as large as it is in the video. The presenter clock starts with the recording.

**■ END AND SAVE TALK** or `Esc` ends the talk. The recording is `~/Videos/NIRUPRES-DECK-TIMESTAMP.mkv`, with a chapter per slide change (from 0:00) in `.chapters.json` and `.srt` beside it. Talk mode needs NIRUCLIP 0.14 or newer and refuses to record with an older one instead of recording the screen. From a terminal: `nirupres --talk deck.nirupres [slides-camera|slides|camera|auto] [--video-sound]` (the old names `screen-camera`, `screen-mic` and `camera-mic` still work).

Text in a layout shrinks until it fits and is never drawn outside its box;
when it still does not fit it ends with "…", and lists say "+N more". Deck
health marks such slides with an orange **FIT** badge. New layouts: CODE,
IMAGE + CAPTION and THREE COLUMN (columns separated by `|||`); TABLE wraps its
cells.

There is no config file to edit; choices are stored as small JSON files in `~/.local/share/nirupres/`. Talk recordings go to `~/Videos/` (`NIRUPRES_TALK_DIR` changes that). Talk mode needs NIRUCLIP, which is alpha. Video slides play through mpv (web videos through yt-dlp); without mpv the poster frame is shown. Full documentation: [github.com/nirucon/nirupres](https://github.com/nirucon/nirupres).

## NPLAY: terminal music player

A keyboard-first terminal player built around mpv: your local library, Navidrome/Subsonic, Spotify (Premium, optional), YouTube audio and Sveriges Radio, with a queue, playlists, a CAVA visualizer, MPRIS media keys and local listening statistics. It is completely standalone: it needs no NIRUX, no X11 and runs over SSH. Status: beta.

```sh
nirux extras install nplay
nplay                    # start the player in a terminal
nplay "search terms"     # start and search
nplay --doctor           # check dependencies, configuration and privacy
nplay --scan             # rescan the local library
```

| Keys | Action |
|---|---|
| `b` / `/` / `Ctrl+P` | Browse / search / Universal Quick Find |
| `Ctrl+N` | Now Playing |
| `Space` | Pause or resume |
| `n` / `p` | Next / previous track |
| `+` / `-` / `m` | Volume up / down / mute |
| `a` | Add to the queue |
| `s` / `x` | Cycle shuffle / repeat |
| `t` | Theme chooser |
| `?` | Help for the current view |
| `Q` | Quit |

The media keys (`XF86AudioPlay`, `XF86AudioNext`, ...) control NPLAY through MPRIS.

- Settings: `~/.config/nplay/config.ini` (music folders in `music_dirs`, default `~/Music`); most can be changed live under **Browse → Settings**
- Credentials: `~/.config/nplay/secrets.ini` (0600)
- Library, playlists, statistics: `~/.local/share/nplay/`

Full documentation, all keys and the configuration reference: [github.com/nirucon/nplay](https://github.com/nirucon/nplay).

## NIRUAMP: graphical frontend for NPLAY

A compact, Winamp-inspired window with an LED clock, a spectrum display, a playlist and a fullscreen visual mode. It is not a second player: NPLAY does the playback, and NIRUAMP talks to its local control service. `nirux extras install niruamp` installs or updates the pinned NPLAY first. Status: alpha.

```sh
nirux extras install niruamp
niruamp                  # or NIRUAMP in the launcher
```

NIRUAMP connects to a running `nplay --serve`, or starts one itself. A second launch brings the existing window forward.

| Keys | Action |
|---|---|
| `Space` | Play or pause |
| `N` / `P` | Next / previous |
| `S` | Stop |
| `Left` / `Right` | Seek 5 s (`Shift`: 30 s) |
| `+` / `-` / `M` | Volume / mute |
| `/` or `Ctrl+F` | Search |
| `1` to `5` | Playlist, queue, browse, settings, about |
| `W` / `T` | Windowshade / always on top |
| `F11` | Fullscreen visual mode (`Esc` leaves it) |
| `K` | Next skin |
| `V` | Spectrum on or off |

The theme follows NIRUX live; **Settings → Theme → NIRUAMP Classic** is the standalone look. There is no equalizer.

**Skins.** NIRUAMP has three skins, all taking their colours from your NIRUX theme (the accent lights the LEDs, lamps and highlights, the foreground colours the text):

- **Classic**: the hardware panel with an LED clock, a spectrum with peak caps, and shuffle and repeat lamps.
- **Phosphor**: a green CRT operator console with scanlines, a glowing seven-segment clock and a monospaced readout. A colourful theme accent tints the phosphor; a grey accent leaves it green.
- **Hi-Fi Deck**: a brushed-metal cassette deck. The cassette label shows the track, the reels follow the position, the display shows the time and a 16-band analyser, and two VU meters show the low and high halves of the spectrum.

`K`, the skin button in the deck or **Settings → Appearance → Skin** switches; the choice is saved as `skin` (`classic`, `phosphor` or `hifi`) in `~/.config/niruamp/config.toml`.

**Welcome sound.** A short welcome sound plays the first time NIRUAMP starts after you log in, at 35 % by default; later starts in the same login are silent. **Settings → Appearance → Welcome sound** sets Off, 20, 35, 50, 75 or 100 %, and **TRY** plays it. The keys are `startup_sound` and `startup_sound_volume`.

**Visualiser.** The spectrum comes from CAVA through NPLAY. NIRUAMP shows it on a decibel scale around a level that adapts slowly to the music, so quiet and loud recordings both fill the display without sticking at the top; bars fall back smoothly and leave small peak caps. **Settings → Visualization** sets the frame rate (30, 20 or 15 fps) and whether the spectrum pauses while the window is hidden. Nothing is drawn while paused, silent or hidden. Preferences are in `~/.config/niruamp/`, window state in `~/.local/state/niruamp/`. Full documentation: [github.com/nirucon/niruamp](https://github.com/nirucon/niruamp).

## NIRUFLOW: maintenance and cleanup

A local maintenance cockpit: cleanup rules for old downloads and screenshots, large, duplicate and forgotten files, project artifacts and Docker leftovers. Scans are read-only, removals need confirmation, and cleanup moves files to a quarantine you can restore from. Synced folders (Nextcloud and similar) are protected. Status: alpha.

```sh
nirux extras install niruflow
niruflow                         # the window
niruflow rules                   # configured rules
niruflow scan RULE               # dry run: what a rule would move
niruflow run RULE --apply        # quarantine the candidates (rule must be enabled)
niruflow history
niruflow restore ID              # restore a quarantined item
niruflow large-files
niruflow forgotten --months 12
niruflow docker-cleanup-preview
niruflow doctor
```

The command line prints JSON, so it pipes into `jq`. Rules are disabled by default; enable them in the window. An optional hourly systemd user timer (`bash ./install-scheduler.sh` from a checkout of the repository) runs rules marked automatic; on Void, schedule `niruflow run-enabled` yourself.

- Configuration: `~/.config/niruflow/config.json`
- History and quarantine: `~/.local/state/niruflow/` (quarantine kept 30 days by default)

Full documentation: [github.com/nirucon/niruflow](https://github.com/nirucon/niruflow).

## NIRUSEC: firewall and security overview

A desktop tool for the parts of a machine that are easy to forget: the UFW firewall in plain language, listening services, blocked traffic, package updates, CPU microcode, firmware and running Docker containers. It is a working core, not a security audit. Status: alpha.

```sh
nirux extras install nirusec
nirusec                         # the window
nirusec --open firewall         # overview, firewall, ports, logs, updates, firmware, docker
nirusec --status                # the last check, from the shared cache
nirusec --profile-rules soft    # the exact UFW rules of a profile
```

- **Keys:** `Ctrl+1` to `Ctrl+7` switch views, `Tab` moves between controls, `F5` checks again.
- **Profiles:** Soft (home and office), Medium (public Wi-Fi), Hard (Tailscale only), Gaming and Off. **Preview** shows the exact UFW commands and warns when a change would cut the SSH session you are using.
- **Safe undo:** any change that could cut access is tried for 120 seconds. Press **Keep**, or the previous settings return by themselves, even if NIRUSEC crashes or you log out.
- **Passwords:** the window runs as you; changes go through a small PolicyKit helper and ask for the administrator password every time.
- **Bar:** a shield icon in NIRUBAR shows the state.

Installing NIRUSEC installs UFW but does not enable it, and never flashes firmware. Docker's published ports bypass UFW.

If you lock yourself out, from the local console:

```sh
sudo /usr/local/libexec/nirusec-helper safe-mode
sudo /usr/local/libexec/nirusec-helper restore-ufw
```

State is in `/var/lib/nirusec`, firewall backups in `/var/backups/nirusec`, local exceptions in `/etc/nirusec/local-exceptions.toml`. Uninstalling keeps firewall rules, preferences, cache and backups. Full documentation: [github.com/nirucon/nirusec](https://github.com/nirucon/nirusec).

## NIRUGAME: game launcher

A retro launcher for games you already have: Steam games, your ROMs and RetroArch playlists, and native games with a `Categories=Game` desktop entry. It never installs, downloads or bundles games, ROMs, cores or music. Status: alpha.

```sh
nirux extras install nirugame
nirugame                         # or nirugame --open steam|retroarch|native|favourites|recent|music|SYSTEM
nirugame --list                  # --list --rescan ignores the cache
nirugame --cores                 # which core or emulator each system uses
nirugame --setup-plan all        # print a package plan for Steam and RetroArch; installs nothing
nirugame --music-status
```

It finds ROMs in `~/Games/roms`, `~/Games/ROMs`, `~/ROMs`, `~/roms`, system folders in `~/Games` such as `PS1`, RetroArch's file browser folder, the folders of your playlists and `[roms] dirs` in `~/.config/nirugame/config.toml`. The system comes from the extension or the folder name (a `.zip` in `snes/` is a SNES game), and each game starts with an installed libretro core (`retroarch -L CORE ROM`, or the Flatpak). Choose a core per system under `[cores]` (`snes = "snes9x"`) or a stand-alone emulator under `[emulators]` (`c64 = "x64sc"`; `Shift+Enter` then uses RetroArch). A game without a core is greyed out with the core to install. The list is kept in `~/.cache/nirugame/roms.json`, so the window opens with the library at once; `F5` scans again.

The window has tabs for All, Favourites, Recent, Steam, RetroArch, Native, each system (with its count) and Music, RetroArch box art where you have it and a details pane. Arrows move, `Enter` launches, `/` searches, `Tab` switches tabs, `F` marks a favourite, `G` switches between list and grid, `Esc` closes.

**SID music:** put your own `.sid` files in `~/.local/share/nirugame/music/` and pick a track (or **Off**) in the Music tab; it plays in the background with `sidplayfp`. `N` or **Open in NIRUSID** hands the track to [NIRUSID](#nirusid-sid-music-player), the full SID player.

Full documentation: [github.com/nirucon/nirugame](https://github.com/nirucon/nirugame).

## NIRUREMOTE: remote desktop

Lists the machines in your Tailscale tailnet, says whether remote desktop is really ready on each, and opens a graphical session. A Linux/X11 host is reached with x11vnc running inside the SSH connection itself, so no port is opened anywhere. Windows hosts open over RDP and macOS hosts over VNC when those are enabled on the target. Status: alpha.

```sh
nirux extras install niruremote
niruremote setup --run           # install x11vnc and a VNC viewer (asks for sudo)
niruremote probe                 # on the host: X11 session and x11vnc ready?
niruremote peers --refresh       # on the client: tailnet machines and their state
niruremote connect desktop       # open a session
niruremote connect desktop --print   # show the plan, start nothing
niruremote disable               # on the host: end every remote session
niruremote doctor
```

Before the first connection, set up SSH key login from the client to each Linux host, and check that `ssh HOST niruremote probe --json` works without a prompt. Use the Tailscale name that `niruremote peers` shows.

The session ends when you close the viewer, press `Ctrl+C` or lose the network. The host gets a notification when a session starts and ends. A locked screen stays locked: the viewer sees NIRULOCK. There is no audio, file transfer or monitor picker; use NIRUSHARE for text and images. Wayland hosts are not supported. The peer cache is `~/.cache/niruremote/peers.json`.

Full documentation, including Windows and macOS targets: [github.com/nirucon/niruremote](https://github.com/nirucon/niruremote).

## NIRUDICTATE: local dictation

Speech to text on this computer: press a shortcut, speak, and the text appears in the window you type in. Swedish by default (KB-Whisper), English one click away, transcribed locally by whisper.cpp. Nothing leaves the computer except the one-time model download. Status: alpha.

```sh
nirux extras install nirudictate
nirudictate settings             # the control panel (also NIRUDICTATE in the launcher)
```

The installer starts the background service in your session, and the NIRUX session starts it at every login. On first run, open the panel, download the recommended model (KB-Whisper Small is about 260 MB) and press **Test microphone**.

| Keys | Action |
|---|---|
| `Ctrl+Alt+Space` | Dictate: tap to start (stops after 2 s of silence, or tap again), or hold while speaking and release |
| `Shift+Alt+Space` | Agent mode: the same, but the text goes to opencode |
| `Shift+Alt+Space` twice quickly | Agent mode, new conversation |
| `Enter` / `Esc` | In the agent confirmation box: send now / cancel (it sends by itself after 2 s) |
| `Super+Alt+9` | Show or hide the opencode window (scratchpad 9) |
| `Super+Alt+Space` | Voice command: the same trigger, and what you say controls NIRUX (see below) |

NIRUDICTATE listens for its shortcuts itself; they are not NIRUWM bindings, but they appear in the cheat sheet (`Super+/`; on Swedish and similar layouts `/` is `Shift+7`). The bar's `dictation` module shows a red dot while recording (`● AI` in agent mode).

```sh
nirudictate toggle               # start or stop a dictation
nirudictate cancel               # stop and discard
nirudictate language toggle      # sv or en
nirudictate models recommend
nirudictate agent new            # the next agent message starts a new conversation
nirudictate doctor               # shortcut, audio, models and display
```

### Voice commands: Super+Alt+Space

Say what you want, in Swedish or English, and NIRUX does it: "öppna terminalen",
"open the browser", "gå till arbetsyta tre", "lås skärmen". The overlay shows **CMD**
while it listens and then what runs ("Öppnar terminal" / "Opening terminal"). What you say
is matched against a fixed list, locally and without AI; it never runs an arbitrary shell
command. When it is not sure, it runs nothing and says "Förstod inte: …".

| Say (sv / en) | It does |
|---|---|
| öppna terminalen / open terminal | NIRUWM's terminal (your `terminal` setting) |
| öppna webbläsaren / open the browser | NIRUWM's browser (your `browser` setting) |
| öppna Spotify, starta Thunderbird / open Signal | the app that name clearly matches; otherwise the launcher with the name typed |
| gå till arbetsyta tre / go to workspace three | workspace 1 to 10; also "nästa/föregående arbetsyta", "next/previous workspace" |
| flytta fönstret till arbetsyta fyra / move the window to workspace four | moves the focused window |
| helskärm, flytande fönster, byt till monokel / fullscreen, float, switch to monocle | window and layout |
| översikt / overview; fönsterhopp / window jump; sök / search | `Super+E`, `Ctrl+Alt+W`, the launcher's search |
| lås skärmen / lock the screen | locks |
| höj volymen, volym 50 procent, ljud av / louder, volume 50 percent, mute | sound; "stäng av mikrofonen" / "mute the microphone" too |
| ljusare, mörkare / brighter, dimmer | brightness |
| spela, pausa, nästa låt / play, pause, next song | media players |
| ta en skärmbild, skärmbild av ett område / take a screenshot | NIRUSHOT |
| nattljus av, slå på stör ej / night light off, turn on do not disturb | night light and Do Not Disturb |
| anteckning köp mjölk, kom ihåg att … / note buy milk | adds the text to the quick-note inbox |
| sök efter väder i Stockholm / search for … | web search |
| stäng fönstret, viloläge, starta om datorn, stäng av datorn, logga ut / close the window, suspend, restart, shut down, log out | asks first: `Enter` runs, `Esc` cancels |

`nirudictate command list` prints every phrase it knows; `nirudictate command --dry-run "öppna terminalen"`
shows what a phrase would do without doing it. Settings are in `[command]` in
`~/.config/nirudictate/config.toml`: `enabled`, `key`, `confirm_dangerous`, `language`
(`both` by default: the dictation language listens first, and if nothing matches, the
other language's model tries, when installed) and `app_names` (installed app names help
recognition). A command takes about 3 s on a fast desktop with the Small model, longer
when the second language has to try. It needs NIRUWM 0.26 and NIRULAUNCHER 0.14 or later.

**Agent mode** needs [opencode](https://opencode.ai), which NIRUX does not install; without it the agent shortcut is simply not taken. The speech is still transcribed locally, but the text you confirm goes to the AI provider opencode uses. Keep scratchpad slot 9 free for the opencode window. opencode asks before it edits files or runs commands, as usual.

- Settings: `~/.config/nirudictate/config.toml` (shortcut, mode, language, output, vocabulary, `[agent]`, `[command]`); `nirudictate reload` after editing
- Models: `~/.local/share/nirudictate/models/`
- History: `~/.local/state/nirudictate/history.jsonl` (0600; turn it off in the panel)
- Sounds: the `dictation` category of `nirux sounds` (see [10-sound-notifications-studio.md](10-sound-notifications-studio.md#event-sounds))

Full documentation: [github.com/nirucon/nirudictate](https://github.com/nirucon/nirudictate).

## docker-stacks: Docker in the terminal

A fast terminal view of everything Docker runs: Compose stacks (wherever
their files are, running, stopped or taken down), containers, images,
volumes, networks and disk use, with live CPU and memory from Docker's own
events and stats. It works the same at the desk and over SSH on a server,
and wears the desktop's NIRU theme or a retro one (`t`). Status: beta.

```sh
nirux extras install docker-stacks
docker-stacks                    # the view; ? lists every key
docker-stacks list               # stacks, state and links
docker-stacks update NAME        # pull and up, in this terminal
```

On a stack: `u` up, `d` down, `s` stop, `r` restart, `U` update, `l` logs,
`e` a shell in a service, `o` open its link (Traefik, Caddy and published
ports; over SSH it is copied to the terminal's clipboard), `E` edit the
compose file, `B` dump its PostgreSQL or MySQL, and `x` uninstall, with a
choice to dump the databases first, delete volumes and images and move the
folder to `.trash`. Anything that deletes data asks first, and deleting
volumes wants the name typed. Stacks are also read from `~/Docker` (the
`roots` setting in `~/.config/docker-stacks/config.toml`). It needs Docker
with Compose v2 and membership of the `docker` group.

Full documentation: [github.com/nirucon/docker-stacks](https://github.com/nirucon/docker-stacks).

## niruprodrive: Proton Drive backup and sharing

A backup of the folders you choose on each computer to Proton Drive, files
sent, fetched and shared, a pixel cloud in the bar and a small window in the
NIRU theme. It is a third-party application, not made or supported by
Proton: it works through Proton's own Proton Drive CLI, which the installer
fetches from proton.me (pinned to a tested version and checked with the
SHA-512 Proton publishes). Status: alpha.

```sh
nirux extras install niruprodrive    # only on the computers that should have it
niruprodrive                         # the window: Drive, Transfers, Backup
niruprodrive upload FILE...          # to My files/NIRUX/Uploads
niruprodrive link FILE [DAYS]        # a public link on the clipboard
niruprodrive backup                  # back up now
```

- **Sign in** once per computer: Enter in the window opens Proton's sign-in
  page in the browser, with two-factor if you use it. niruprodrive never sees
  the password; the session is kept in the keyring (or `pass`, with
  `credentials = "pass"`).
- **Backup, per computer.** On the Backup tab each computer chooses its own
  folders (drop them from NIRUFM or press `A`), the schedule (`S`: hourly,
  daily or manual) and whether to back up on battery (`O`). They go to
  `My files/NIRUX/<computer>/`. Only changes are sent. Nothing is ever
  removed in the Drive: a deleted file stays there and a changed file keeps
  its old revisions. Names such as `node_modules`, `target`, `.cache` and
  `*.iso` are left out (`E` opens the settings,
  `~/.config/niruprodrive/config.toml`).
- **Drive tab:** browse My files, `D` downloads to `~/Downloads`, `C` copies
  a public link, `Shift+C` one that ends after 7 days, `X` removes a link,
  and files dropped on the window are sent to the folder shown. To restore a
  backup, open This computer and download.
- **The bar:** the cloud shows a tick when all is sent, an arrow while
  sending, bars when paused, `!` after a failure, and a dash when signed out or
  before any folder is chosen. Click for the window, right-click for back up now, pause and quit.
- **It stays up.** The service runs under a small supervisor that starts it
  again if it is killed or crashes; Quit and a logout end it. What stopped it,
  and which process sent the signal, is written to
  `~/.local/state/niruprodrive/service.log`.

niruprodrive can only list, upload, download, make folders and add or remove
links: there is no command in it that trashes, deletes, moves or replaces
anything in the Drive.

Full documentation: [github.com/nirucon/niruprodrive](https://github.com/nirucon/niruprodrive).

## NIRUTODAY: today at a glance

One page with the day, in a retro teletext look that follows the NIRU theme:
the weather from SMHI, news from Sveriges Radio, VMA and warnings, the
electricity price, the name day and your calendar. Three columns on a wide
screen, two on a laptop, one in a narrow window or a scratchpad. Status: alpha.

```sh
nirux extras install nirutoday
nirutoday                  # the page (also NIRUTODAY in the launcher)
nirutoday --print          # today as text, for a terminal
```

- **101 Weather:** now, the next hours and the week from SMHI, with "feels
  like", wind and rain.
- **102 News:** Sveriges Radio articles, P4 Väst and Ekot by default; news
  naming a nearby place (Ljungskile, Uddevalla and around by default) is
  marked and comes first. `Tab` switches between all, local and one program,
  `Enter` opens a story. `L` (or **LIVE**) plays P4 Väst live, or Ekot's
  newest broadcast, in NIRUAMP, which is started if it is not running.
- **103 Alerts:** VMA for the county as a red banner, SMHI warnings and
  Krisinformation.se. A new VMA or an orange or red warning also comes as a
  notice, once, while NIRUTODAY runs (also hidden in a scratchpad).
- **104 Electricity:** the spot price per hour for the elområde, the price
  now and the cheapest three hours; `T` shows tomorrow after about 13:00.
- **105 Today:** name day, flag day and holiday, sunrise and sunset, and
  today's events from the calendars NIRUBAR reads.
- **106 Traffic** is off until you add a free Trafikverket key.

Dates and times are written the Swedish way (tisdag 24 november, v. 48,
24-hour clock). Settings: `~/.config/nirutoday/config.toml`, written with
the defaults at the first start: the place, county, nearby places, the news
programs and channels, the elområde, calendar, notices, and `[traffic]`
(`enabled`, `key`, `radius_km`; keep the file private with `chmod 600` when
it holds the key). Cache: `~/.cache/nirutoday/` (private; the page opens with
the last data and works offline).

Full documentation: [github.com/nirucon/nirutoday](https://github.com/nirucon/nirutoday).

## NIRUSID: SID music player

A player for Commodore 64 SID music with the libsidplayfp engine. It plays PSID and RSID tunes, takes song lengths and comments from the High Voltage SID Collection (HVSC), and shows what the SID chip does while it plays: raster bars, and per voice the note, waveform, pulse width, ADSR, gate and filter routing with an oscilloscope, plus a piano roll. It follows the theme live, can use a C64 pixel font or the C64's own colours, and also plays the NIRUX music. Status: alpha.

```sh
nirux extras install nirusid   # builds it on this computer (installs libsidplayfp's development files and cargo if missing)
nirusid                        # open the window
nirusid tune.sid               # play a file; a second call hands it to the open window
nirusid --info tune.sid        # header, HVSC length and STIL as text
```

Put your SID files, or the whole HVSC, in `~/Music/SID` (or choose another folder with `F2`). The first scan runs in the background; later starts show the library at once. The installer makes NIRUSID the player for `.sid` files once and remembers what opened them before; `nirux extras uninstall nirusid` gives them back. On Void, whose libsidplayfp has no reSIDfp, it uses the lighter SIDLite emulation; `nirusid --version` shows which.

- **Play:** `Space` plays or pauses, `v` stops, `Enter` plays the selected tune. `n` and `p` go to the next and previous tune, `]` and `[` to the next and previous subtune, and `Left`/`Right` seek. Tunes move on at their HVSC length, or after 3 minutes when it is unknown.
- **Find:** `/` searches every title, author, year and path; `Tab` switches between Library, Search, Playlist, Favourites, History, NIRUX music and your saved playlists; `o` sorts.
- **The chip:** `1` to `9` mute single voices, `0` turns them all on, `m` switches the chip model (6581/8580) and `t` the clock (PAL/NTSC).
- **Keep:** `a` adds to the playlist, `f` marks a favourite, `Ctrl+S` saves the playlist under a name. `e` exports the subtune to WAV and `E` to FLAC (with `flac` or `ffmpeg`), in `~/Music/NIRUSID`.
- `?` shows every key. NIRUBAR's media module and the media keys control NIRUSID through MPRIS.

Settings are in `~/.config/nirusid/config.toml`; playlists, favourites and history are in `~/.local/share/nirusid`.

Full documentation: [github.com/nirucon/nirusid](https://github.com/nirucon/nirusid).

## NIRUSYS: System monitor

NIRUSYS is a retro, console-style system monitor in the NIRUX theme colours, made to stay on screen all day: one thread wakes once a second, reads a few kept-open files from /proc and /sys, redraws only what changed and draws nothing while hidden. Status: alpha.

    nirux extras install nirusys   # builds it on this computer (installs cargo and gcc if missing)
    nirusys                        # the full window
    nirusys --widget               # a column on the desktop, below other windows, on every workspace
    nirusys --mini                 # one strip: host, CPU, memory, network, temperature
    nirusys --text                 # one sample as text, with every install-date witness

The header shows the host, distribution, kernel, NIRUX version, window manager, uptime, load, the clock with the ISO week, and the day the system was installed with its age (hover it for the source: the root file system's birth time, the Debian installer log, the first pacman.log line or the oldest xbps package, whichever is earliest).

- **Panels:** CPU (per core, frequency, governor, temperature), memory (swap, zram, pressure), disks (usage, read and write, temperature, SMART or the weekly checkup), network (Wi-Fi, Tailscale and your computers), GPU (Intel, AMD, NVIDIA), sensors, battery, top processes, and system (pending updates from NIRUBAR, failed services, the last NIRUX update).
- **Graphs:** phosphor traces with a scale and peak marker; `h` shows the last 24 hours, kept in `~/.local/state/nirusys`.
- **Alerts:** a notification when a file system reaches 95 % or the CPU 95 °C; more thresholds in the configuration.
- `1` … `9` collapse panels, `?` shows every key, hover shows exact values.
- NIRUBAR's pulse module (**System monitor…**) and the SYSTEM card in NIRUPANEL open NIRUSYS when it is installed.

Settings are in `~/.config/nirusys/config.toml` (which panels, in which order, the widget corner, alerts).

Full documentation: [github.com/nirucon/nirusys](https://github.com/nirucon/nirusys).

## NIRUSETTINGS: settings

The settings of the NIRUX desktop in one keyboard-driven window, in the theme colours: Appearance (theme, fonts, wallpaper, colour overrides), Window manager (gaps, borders, layouts, scratchpad, picture in picture, programs, night light), Bar (modules and their order, edge, height, transparency, clock), Lock screen (layout, pause music), Screensaver (the idle and lock timers, scenes), Sound (event sounds), plus Key bindings, Extras and Updates. Status: alpha.

    nirux extras install nirusettings
    nirusettings            # or: nirusettings bar | lock | keys | extras | updates

Arrows move, Left/Right or +/- change a value, Space toggles, Return edits, `r` resets, `u` undoes, `/` searches everything. A `*` marks a value that differs from the default; FILE or DEFAULT says where it comes from. Each value is checked like the program itself checks it (and by `niruwm --check-config` and `nirubar --check-config`) before only that line of the file changes; comments stay, and the old file is kept once per session as `FILE.bak`. NIRUWM and NIRUBAR apply it at once with `niructl reload`; the lock screen and screensaver use it the next time they start, and the window says so. `nirusettings --set bar.position bottom` does the same from a terminal. Its settings are described by schema files (`~/.local/share/nirusettings/schema/`), so new settings need no new program. Version 0.2.0 has 273 settings and 4 lists, including every lock screen layout (`attract`, `satie`, `bbs` and `hacker` too) and the `c64` and `c64-sid` screensaver scenes; a choice newer than the installed program is refused.

- **Scratchpads 1 to 9** (Window manager, Scratchpads): each slot shows its keys (Super+Alt+N shows or hides it, Super+Alt+Shift+N sends a window there) and its program. `Return` edits a slot, `p` picks a program from the installed ones (with a filter), `Delete` clears it. The window class NIRUWM needs is filled in, and marked "guessed" when it is a guess (check it with `xprop WM_CLASS`).
- **Programs at login** (autostart) with their workspace, and **Window rules** (class, workspace counted from 1, floating, centred, on every workspace, opacity; the first match wins). `Shift+Up`/`Shift+Down` reorder.
- **Key bindings are editable:** `Return` changes one (type the keys or press them), `a` adds, `Delete` removes (a built-in one is released), `r` puts NIRUWM's own back. It asks before taking a key that is in use and marks with `!` two bindings that are the same key on your keyboard layout.
- **Screensaver preview:** `p` on a scene (also in the picker and the shuffle list) shows it with `niruscreensaver --preview`.
- **Bar:** Weather, Timer, Calendar and Panel timeouts from NIRUBAR's own `~/.config/nirubar/config.toml`.
- In lists and forms: `Return` opens, `a` adds, `Delete` removes, `Ctrl+S` saves, `Esc` cancels, `?` shows the keys. From a terminal: `nirusettings --add niruwm:scratchpad.slot number=9 "command=sh -c 'exec nirusys' --class nirusys"`, `--remove ID WHICH`, and `--get`, `--set`, `--reset` and `--list` for `niruwm:scratchpad.slot`, `niruwm:autostart.apps`, `niruwm:rules` and `niruwm:keys`.

Full documentation: [github.com/nirucon/nirusettings](https://github.com/nirucon/nirusettings).

## NIRUX: the game

NIRUX is an original shooter in the Commodore 64 style: a 320x200 picture in the 16 C64 colours with raster bars, parallax and explosions, and 14 original songs from its own three-voice SID-style synthesiser. The campaign has eight sectors in three kinds of play, about 30 to 60 minutes to beat: side-scrolling space (The Outer Rim, The Shipyards, The Gauntlet), isometric flight where up and down change your altitude (Glass Dunes, Ice Pylons) and on foot with eight-way fire and grenades (Iron Jungle, Burning City). Sector 8, The NIRUX Core, goes through all three before the final boss, and an ending with credits follows. Every sector has a mid-boss and a boss. Status: alpha.

    nirux extras install nirux-thegame   # builds it on this computer (installs cargo if missing)
    nirux-thegame                        # fullscreen; --windowed, --level N, --demo

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | arrows or WASD | left stick or D-pad |
| Fire (hold for auto fire) | Space, Ctrl or Z | A / cross (or right trigger) |
| Special: smart bomb, altitude or grenade | X or Shift | B / circle (or left trigger) |
| Pause | Esc or P | Start |
| Back | Esc | Select |
| Fullscreen, mute | F11, M | |

The **Controls** entry in the title and pause menus shows the same table and the name of a connected pad. On foot, holding fire keeps your aim so you can strafe.

- **Gamepads:** PS3, PS4 and PS5, Xbox, 8BitDo and ordinary USB pads work through the kernel's input devices, and a pad can be plugged in at any time. The menus work with the pad too. If a pad is found but cannot be read, the Controls screen says so.
- **Any screen:** the picture is scaled by the largest whole number that fits, so pixels stay sharp on a laptop, a widescreen or a HiDPI screen, and the area around it is the C64 border in each sector's colour. The CRT scanlines can be switched off in Options. It uses about a tenth of one core, less in quiet scenes.
- **A level now and then:** progress is saved after each sector, and Level select starts any sector you have reached. Easy, Normal and Hard, and a high score table.
- Settings are in `~/.config/nirux-thegame/config.toml`, progress and scores in `~/.local/share/nirux-thegame/save.toml`.

Full documentation: [github.com/nirucon/nirux-thegame](https://github.com/nirucon/nirux-thegame).

## Other suite tools

These are core components, installed and updated by `nirux install` and `nirux update`, but small enough to describe here.

### NIRUWEBAPP: web apps in their own windows

Runs a website as an app in its own window, using your installed Helium, Chromium, Chrome or Brave in app mode. Each web app gets a desktop entry (so it shows up in the launcher) and, by default, its own isolated browser profile. Status: alpha.

The quickest start is the built-in catalogue: well-known web apps in sets, with checked addresses and the profile that signs in best. `nirux install` offers it (chapter 1), and you can add more at any time:

```sh
nirux webapps                       # the catalogue; * marks what you have
nirux webapps add work ai           # sets and single apps in any mix
nirux webapps add svt-play gmail
nirux webapps add nextcloud --url cloud.example.com
nirux webapps check                 # do the addresses of your web apps still work?
```

`nirux webapps` runs `niruwebapp catalog` and `niruwebapp add`, which you can also use directly. A service you already have (a Gemini you made yourself, say) is recognised and not added twice, and existing web apps are never changed.

| Set | Web apps | Signs in with |
|---|---|---|
| `work` | Teams, Outlook, Outlook Calendar, Copilot (Microsoft 365), Loop, Planner, OneDrive | your normal browser profile (Microsoft 365 sign-in) |
| `ai` | Claude, ChatGPT, Grok; Gemini, Gemini Notebook | their own profiles; the Google group |
| `google` | Gmail, Google Calendar, Google Drive | the Google group |
| `proton` | Proton Mail, Calendar, Drive and Pass | the Proton group |
| `media` | YouTube, YouTube Music; SVT Play | the Google group; its own |
| `other` | Spotify, Discord, GitHub, Excalidraw | their own profiles |
| `nextcloud` | Your own Nextcloud (asks for the address) | its own profile |

**Profile groups.** The apps of a group share one browser profile of their own: sign in to Google once and Gmail, Calendar, Drive, Gemini and YouTube all know you, while your normal browsing stays apart. Make your own group with `--profile-group NAME` on `create` or `edit`. Removing a web app keeps the group profile while other web apps use it.

**Addresses that move.** Services change addresses (NotebookLM became Gemini Notebook at `notebook.google.com`, Outlook moved to `outlook.cloud.microsoft`). Every `nirux update` runs `niruwebapp refresh`, which moves a web app still on a known former address to the current one. The weekly checkup (chapter 11) also tries each of your web apps and warns about one that no longer answers or now leads elsewhere; `nirux webapps check` does the same at once.

Your own web apps:

```sh
niruwebapp create "YouTube Music" https://music.youtube.com
niruwebapp create https://teams.cloud.microsoft/ --shared-profile   # named Teams
niruwebapp create "Google Keep" https://keep.google.com --profile-group google
niruwebapp list
niruwebapp launch "YouTube Music"
niruwebapp edit youtube-music --fetch-icon
niruwebapp remove youtube-music --delete-profile --yes
niruwebapp doctor
```

Use `--shared-profile` when sign-in should follow your normal browser (Microsoft 365, for example); cookies are then shared with ordinary browsing. Launching a web app that is already open brings its window forward; `--new-window` opens another. `remove` keeps the profile unless you pass `--delete-profile`. Profiles are in `~/.local/share/niruwebapp/profiles/`. More: [github.com/nirucon/niruwebapp](https://github.com/nirucon/niruwebapp).

### NIRUFETCH: system summary

A fast system summary for the terminal in the NIRUX style, in the colours of the current theme. It reads local files only. Status: beta.

Beside the summary sits a small mark of your distribution (Debian, Arch, Void, Ubuntu, Fedora, or Tux for others) in the theme's colours, and below it a strip of the terminal's colours. The mark is left out when the window is narrower than about 63 columns. `Host` shows the machine model.

```sh
nirufetch
nirufetch --compact     # small terminals
nirufetch --full        # GPU, displays, battery, packages, init, selected extras
nirufetch --json        # everything, for scripts and bug reports
nirufetch --plain       # no colour (NO_COLOR is honoured too)
nirufetch --no-logo     # without the mark
```

Settings live in `~/.config/nirufetch/config.toml` (all optional):

```toml
logo = "distro"          # "distro", "nirux" (the NIRUX rune) or "off"
logo_colors = "theme"    # "theme" or "distro" (the distribution's own colours)
palette = true           # the colour strip
fields = ["os", "host", "kernel", "cpu", "memory", "theme"]   # rows and order
```

`fields` accepts `os host nirux kernel uptime init shell wm terminal cpu gpu memory swap disk display battery packages locale load extras theme`; without it the default set is shown, and `--full` always shows everything. Display names in `--full` match xrandr (`DisplayPort-4`, `eDP`).

More: [github.com/nirucon/nirufetch](https://github.com/nirucon/nirufetch).

### NIRUSHARE: share with your own devices

Sends clipboard text, screenshots and images between your own trusted NIRUX devices over Tailscale, or posts them to Discord channels through webhooks you set up yourself. The NIRUX session starts its service (`nirushare serve`). NIRUSHARE is alpha: test it before you rely on it.

Pairing is explicit: being in the same tailnet is not enough.

```sh
nirushare token                          # on device A: show a one-time token
nirushare trust device-a TOKEN           # on device B: trust A
nirushare send --clipboard --to device-a
nirushare send --file picture.png --all  # every trusted device
nirushare devices
nirushare status                         # trusted devices, queue, recent transfers
nirushare inbox
nirushare copy ID
```

Offline devices get the item when they return (retried for up to 7 days). Received images go to `~/Downloads/nirushare/` (your XDG Downloads folder); text goes to the inbox. In the launcher, open the **Share** view (`nirulauncher --share`); in the NIRUSHOT review, press `u` to share a screenshot.

**Discord:** nothing is set up by default. Add named webhooks to `~/.config/nirushare/webhooks.toml` (keep it 0600; anyone with a webhook URL can post to that channel):

```toml
[webhook.friends]
url = "https://discord.com/api/webhooks/<id>/<token>"
```

```sh
nirushare discord list                   # names only, never URLs
nirushare discord check
nirushare send --to discord:friends      # the clipboard: preview, then "Send? [y/N]"
nirushare send --to discord:friends shot.png
nirushare discord undo ID                # delete it again within 5 minutes
```

Nothing is posted without a preview that names the target, and the "Sent to Discord" notification has an **Undo** action for 5 minutes. More: [github.com/nirucon/nirushare](https://github.com/nirucon/nirushare).

## See also

- [01-getting-started.md](01-getting-started.md)
- [07-screenshots-and-recording.md](07-screenshots-and-recording.md)
- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [11-updates.md](11-updates.md)
- [16-commands.md](16-commands.md)
