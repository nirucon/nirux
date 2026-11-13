# Extras

Extras are optional NIRU applications with their own repositories and release cadence. This chapter explains how to install, update and remove them with `nirux extras`, then gives a short practical tour of each one, and ends with the small core tools NIRUWEBAPP, NIRUFETCH and NIRUSHARE.

## How extras work

A normal `nirux install` or `nirux update` never installs an extra. You ask for each one by name. Every NIRUX release pins one version of each extra, together with the SHA-256 of its source archive.

| Extra | Pinned | What it is | Status |
|---|---|---|---|
| [niruorg](#niruorg-file-manager) | 0.6.1 | Two-pane file manager for local folders, servers and cloud remotes | beta |
| [nirunote](#nirunote-markdown-editor) | 0.7.1 | Minimal Markdown editor and viewer | beta |
| [nirupres](#nirupres-presentations) | 2.3.0 | Presentation studio | beta |
| [nplay](#nplay-terminal-music-player) | 1.8.2 | Terminal music, radio and podcast player; also fully standalone | beta |
| [niruamp](#niruamp-graphical-frontend-for-nplay) | 0.5.2 | Winamp-inspired graphical frontend for NPLAY (requires NPLAY) | alpha |
| [niruflow](#niruflow-maintenance-and-cleanup) | 0.6.1 | Local maintenance and automation | alpha |
| [nirusec](#nirusec-firewall-and-security-overview) | 0.2.0 | Firewall, ports, updates, firmware and security overview | alpha |
| [nirugame](#nirugame-game-launcher) | 0.1.4 | Steam, RetroArch and native games, with optional SID music | alpha |
| [niruremote](#niruremote-remote-desktop) | 0.2.0 | Graphical remote desktop over Tailscale and SSH | alpha |
| [nirudictate](#nirudictate-local-dictation) | 0.3.0 | Local speech-to-text dictation, voice commands, and voice messages to opencode | alpha |

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

`update` only touches selected extras whose installed version differs from the pin, and takes a NIRUX snapshot first when anything will be installed. `uninstall` (also spelled `remove`) runs the extra's own `uninstall.sh` from the same pinned source and unselects it. Every extra keeps your data on a normal uninstall; `--purge` is passed to the uninstallers that support it (NPLAY, NIRUAMP, NIRUPRES, NIRUFLOW, NIRUREMOTE, NIRUDICTATE). Uninstall extras before `nirux uninstall`, which removes the `nirux` command itself.

The bar's update module tracks the core NIRUX release only, not each extra. After `nirux update`, run `nirux extras update` to follow the new pins.

### Consent and sudo

Extra installers may install runtime packages and ask for `sudo`; read their output.

- **In a terminal** the installer asks before installing packages, as usual.
- **Without a terminal** (a deployment script, a graphical update) nobody can answer, so NIRUX sets `NIRUX_ASSUME_YES=1`: asking NIRUX for the extra is the consent.
- **Without a terminal and without a password held by NIRUX**, an extra that needs `sudo` fails at once with "this extra needs sudo, and there is no terminal to ask for the password". It does not try, because each failed sudo counts toward `pam_faillock`, and three failures lock the account (screen lock included) for ten minutes. Run `nirux extras install NAME` in a terminal instead.

NIRUX never deletes an extra's user data when you unselect it. The full description is in [docs/EXTRAS.md](https://github.com/nirucon/nirux/blob/main/docs/EXTRAS.md).

## NIRUORG: file manager

Keyboard-friendly two-pane file manager with tabs, a command palette and safe copy and move between local folders, Nextcloud, SSH/SFTP (through SSHFS), FTP/FTPS and rclone remotes. Copies go to a partial file first, and a move deletes the source only after the destination is complete. Python and PySide6 (Qt 6). Status: beta.

```sh
nirux extras install niruorg
niruorg                 # or niruorg PATH, or NIRUORG in the launcher (Super+P)
niruorg --self-test
```

| Keys | Action |
|---|---|
| `Ctrl+T` / `Ctrl+W` | New tab / close tab |
| `Ctrl+Shift+T` | Reopen closed tab |
| `Ctrl+K` | Command palette |
| `Ctrl+L` | Type a location |
| `Ctrl+F` / `/` | Find files and content / filter the current folder |
| `F3` / `Space` | Quick Look / Inspector |
| `Ctrl+Shift+Right` | Send the selection to the other pane |
| `Ctrl+Shift+M` | Compare panes |
| `Ctrl+D` | Work Basket (collect files from several places) |
| `Ctrl+Alt+T` | Terminal in the current folder |
| `Ctrl+H` | Hidden files |
| `Ctrl+Z` | Undo the last transfer |

Drag files between panes to copy; use **Move** from Actions to move. All settings are in the app (**Settings**). The theme follows NIRUX live by default.

- Preferences: `~/.config/NIRU/NIRUORG.conf`
- Servers: `~/.config/niruorg/servers.json` (or `~/Nextcloud/Backup/niruorg/servers.json` when that folder exists)
- Logs: `~/.local/state/niruorg/launcher.log`

`Super+Shift+F` still opens the default file manager (pcmanfm), not NIRUORG. Full documentation: [github.com/nirucon/niruorg](https://github.com/nirucon/niruorg).

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

A keyboard-oriented presentation studio: 25 slide layouts, 17 slide themes, speaker notes, a presenter window and an audience window on the screen you choose, PDF and image-based PPTX export, and Talk mode, which records the talk with NIRUCLIP and writes a chapter per slide. Every deck is one `.nirupres` file with its images inside. Status: beta.

```sh
nirux extras install nirupres
nirupres                                  # the editor
nirupres --present deck.nirupres          # present from the start
nirupres --talk deck.nirupres screen-mic  # present and record (screen-mic, screen-camera, camera-mic)
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
| `S` / `Z` | Spotlight / zoom |
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
- The presenter view shows the current and next slide, a large timer with
  pace, the clock, `x / y` and the speaker notes (at least a third of the
  height; `A−`/`A+` sizes are remembered).

Text in a layout shrinks until it fits and is never drawn outside its box;
when it still does not fit it ends with "…", and lists say "+N more". Deck
health marks such slides with an orange **FIT** badge. New layouts: CODE,
IMAGE + CAPTION and THREE COLUMN (columns separated by `|||`); TABLE wraps its
cells.

There is no config file to edit; choices are stored as small JSON files in `~/.local/share/nirupres/`. Talk recordings go to `~/Videos/` (`NIRUPRES_TALK_DIR` changes that). Talk mode needs NIRUCLIP, which is alpha. Full documentation: [github.com/nirucon/nirupres](https://github.com/nirucon/nirupres).

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

The theme follows NIRUX live; **Settings → Theme → NIRUAMP Classic** is the standalone look. There is no equalizer. Preferences are in `~/.config/niruamp/`, window state in `~/.local/state/niruamp/`. Full documentation: [github.com/nirucon/niruamp](https://github.com/nirucon/niruamp).

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

A retro-themed launcher for games you already have: Steam games, RetroArch playlists and native games with a `Categories=Game` desktop entry. It downloads and bundles nothing. Status: alpha.

```sh
nirux extras install nirugame
nirugame                         # or nirugame --open steam|retroarch|native|music
nirugame --list
nirugame --setup-plan all        # print a package plan for Steam and RetroArch; installs nothing
nirugame --music-status
```

In the window, use the tabs to narrow the list, type to search, then `Up` / `Down` and `Enter` to launch.

**SID music:** put your own `.sid`, `.psid` or `.rsid` files in `~/.local/share/nirugame/music/` and pick a track (or **Off**) in the Music tab. Playback needs `sidplayfp` from your distribution. The chosen track is stored in `~/.config/nirugame/config.toml`.

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

## Other suite tools

These are core components, installed and updated by `nirux install` and `nirux update`, but small enough to describe here.

### NIRUWEBAPP: web apps in their own windows

Runs a website as an app in its own window, using your installed Helium, Chromium, Chrome or Brave in app mode. Each web app gets a desktop entry (so it shows up in the launcher) and, by default, its own isolated browser profile. Status: alpha.

```sh
niruwebapp create "YouTube Music" https://music.youtube.com
niruwebapp create https://teams.cloud.microsoft/ --shared-profile   # named Teams
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
