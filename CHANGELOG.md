# Changelog

Earlier releases are described in their release notes and commit messages.

## 0.12.248 (2026-11-09)

- **Panels you read stay open (NIRUBAR 0.22.1, NIRUWM 0.22.4).** The calendar,
  weather, tasks, pulse and notifications panels stay until you close them
  (click or Escape); quick-glance panels still close after
  `popup_timeout_seconds`. Per-panel timeouts in `[popup_timeout]` of
  `~/.config/nirubar/config.toml`.
- **Calendar changes apply by themselves.** `calendars.toml` is re-read when
  it changes and on `niructl reload`; new calendars are fetched at once.
- The manual (chapter 4) describes calendar events and panel timeouts.

## 0.12.247 (2026-11-09)

- **NIRUCLIP 0.6.1: the HP laptop camera no longer switches off after a
  second.** NIRUCLIP turned the camera's dynamic exposure framerate off for a
  steady 30 fps; the HP 5MP camera answers that with its privacy image. The
  setting is now opt-in (`camera_steady_framerate = true`).

## 0.12.246 (2026-11-09)

- **The NIRUX manual.** A thorough English manual ships with every release
  and matches the installed version: `nirux manual [TOPIC]`, Super+Shift+F1 or
  the launcher's Manual view (NIRU Launcher 0.10.0, NIRUWM 0.22.3). Key
  bindings, niructl commands and the configuration reference are generated
  and checked before each release.
- **Calendar events in the clock popup (NIRUBAR 0.21.0).** Read-only Google
  Calendar (or any iCal) feeds from `~/.config/nirubar/calendars.toml` (mode
  600): dots on days with events, the next days listed, a click opens the
  calendar on that date. See the manual, chapter 4.
- **NIRUCLIP 0.6.0:** `--mic SOURCE` and `--list-mics` record from a chosen
  microphone without changing the system default; `mic = "..."` per profile.

- **The NIRUX manual.** An English manual in `docs/manual/` (16 chapters:
  getting started, windows and layouts, workspaces and scratchpads, the bar,
  the launcher, lock and screensaver, capture, themes, displays, sound and
  notifications, updates, extras, troubleshooting, and generated configuration,
  key binding and command references). It ships with every release as
  `nirux-manual.tar.xz` and is installed read-only into the program generation
  (`~/.local/share/nirux/current/manual`), so it matches the installed
  programs, works offline and follows a rollback.
- **`nirux manual [TOPIC]`** opens it: the index, or a chapter or heading by
  number, name, heading text, `CHAPTER#ANCHOR` or a Swedish word (`lås`,
  `skärmdump`, `studioläge`). It uses NIRUNOTE when installed, else `xdg-open`,
  else `less` at the heading. `--list` lists the chapters, `--path` prints the
  directory, `--where TOPIC` prints the file and line. `nirux status` names the
  installed manual.
- **Generated sections stay current.** `tools/manual-gen.sh` regenerates the
  key bindings (`niructl keys --markdown` for a fresh NIRUX configuration), the
  niructl command list and the configuration reference from vendored inputs in
  `tools/manual-inputs/`; `--refresh` fetches them for the versions pinned in
  `manifest`. `tests/manual.sh` (CI and the release workflow) fails on a stale
  section or input, a `nirux` command without an entry, a broken link or
  anchor, or a long dash.

## 0.12.245 (2026-11-09)

- **The lock screen plays SID music only when you lock it yourself
  (NIRULOCK 0.25.0, NIRUWM 0.22.1, NIRU Launcher 0.9.0).** Super+Escape, the
  launcher, Quick Settings and `niructl lock` typed in a terminal are manual
  locks; idle locks, suspend, lid and scripts (`niructl lock --silent`) lock
  silently. Esc still returns to the quotes. `[pause_music] on = [...]`
  changes which locks play.
- **Super+Ctrl+O** copies the text in a screen region (`nirushot ocr`).

- **Text from the screen (NIRUSHOT 0.7.0).** `nirushot ocr` reads the text in
  a selected region (Swedish and English) and copies it. tesseract with Swedish
  and English data is now installed with NIRUX on Debian, Arch and Void.

- **GitLab mirror as a fallback source.** When GitHub still fails after its
  retries, a NIRUX release asset (and the latest-release lookup) comes from the
  public backup mirror on GitLab.com (`gitlab.com/rudolfsson/<repo>`, generic
  packages at the same repo/version/file). SHA256SUMS still has to match.
  `NIRUX_MIRROR=none` turns it off.

- **Configuration snapshots: `nirux snapshot` and `nirux restore`.** Every
  `nirux update` first saves the suite configuration to
  `~/.local/state/nirux/snapshots/<time>-<from>-to-<to>.tar.gz` with a
  manifest (file list, sizes, SHA-256). A newer target installer takes it
  when the running installer predates snapshots. `nirux extras update` (when
  it installs something) and `nirux reset-config` take one too. Included: the
  suite's and the extras' config directories, picom/kitty/fish files NIRUX
  writes, registered keys and launcher favourites. Left out: nirushare (upload
  token), token/password-like files (reported), files over 16 MiB, caches,
  state and music. `[snapshots] keep = 3` and `strict = false` in
  `~/.config/nirux/snapshots.toml`; a failed snapshot warns and the update
  goes on unless strict. `nirux snapshot [--note TEXT]`, `nirux snapshot list`,
  `nirux restore [ID|latest] [--dry-run] [--yes]`: a file list with line
  counts, y/N, a safety snapshot first, and what to reload afterwards.
  `nirux rollback` now points to restore for configuration.
- **`nirux sync`: share settings between your NIRUX machines.** Over the
  `nirux fleet` SSH access: `sync status [HOST...]` (same, changed, only here,
  only there and excluded per item, by content hash), `sync push HOST...|--all
  [ITEM...]` and `sync pull HOST [ITEM...]` with a preview, y/N (`--yes`,
  `--dry-run`) and a snapshot on the receiving machine first (a backup tarball
  on an older NIRUX). Items: quotes, keys.d, theme, lock, launcher, sounds and
  sid; `[sync] items`/`exclude` in `~/.config/nirux/sync.toml`. NIRUWM's
  `config.toml` is never copied whole (monitors and displays are per machine);
  only its `theme` key travels. Display profiles, secrets, state and caches
  are never synced, and nothing is deleted on the receiver. rsync when both
  ends have it, else tar over SSH; no new dependencies. From a machine
  without NIRUX, `sync status HOST1 HOST2` compares the hosts with each other.
- New tests `tests/snapshot.sh` and `tests/sync.sh` (fake ssh, remote homes
  as local directories) run in CI and are shellchecked.

## 0.12.244 (2026-11-09)

- **Studio mode (NIRUWM 0.20.0, NIRUBAR 0.20.0, NIRU Launcher 0.8.0).**
  `niructl studio on|off|toggle`, a Quick Settings row, the `studio_toggle`
  action and the phrases "studio mode"/"studioläge": pauses idle locking for
  the session, turns on Do Not Disturb, stops the compositor and sets the
  performance power profile; off restores exactly what it changed. The bar
  shows it. Optional `[studio]` settings, including auto-enable for REAPER
  (off by default).
- **NIRU Launcher 0.8.0:** a window swallowing toggle in Quick Settings and
  NIRU Actions; no "/ for files" hint when file search is off; optional
  `[files] locate_db`, and real plocate verified.
- **NIRUCLIP 0.5.1: the camera recovers.** A camera that is unplugged or
  stalls during a recording is reattached when it returns (the screen keeps
  recording meanwhile); the camera check always runs before a recording, also
  with a short countdown; the HP "camera off" placeholder makes NIRUCLIP reopen
  the camera in another mode.

- **`nirux fleet`: see and update all your NIRUX machines.** `nirux fleet`
  (or `fleet status`, `--json`) lists the Linux Tailscale peers that have
  NIRUX, asked in parallel with a short timeout: online/offline, version,
  behind the latest release, relogin needed (running NIRUWM/NIRUBAR not the
  active generation's binary), locked, distribution, uptime and last update.
  Offline machines seen before are listed with their last version; machines
  without SSH key access show *no access*. `nirux fleet update HOST...|--all|--behind`
  runs `nirux update` (and `nirux extras update` when extras are selected)
  host by host over `ssh -t`, so sudo asks in your terminal, and never logs
  anyone out. `nirux fleet setup` is a one-time, confirmed helper that creates
  an ed25519 key if needed, runs `ssh-copy-id` and verifies key login; it
  changes no Tailscale, sshd or PAM settings. Hosts can be fixed with
  `[fleet] hosts`/`exclude` in `~/.config/nirux/fleet.toml`. Remote commands
  are `sh -s` with the script on standard input, so a fish login shell works.
  New test `tests/fleet.sh`.

## 0.12.243 (2026-11-09)

- **`nirux update` survives GitHub 504s.** GitHub caches a failed response
  per URL, so retrying the same download failed the same way for minutes and
  updates stopped with a 504. Every attempt now asks with its own query (same
  asset, same checksum), up to eight attempts with a short backoff
  (`NIRUX_FETCH_ATTEMPTS` changes the count). A failed download leaves no
  partial file. New test `tests/fetch-retry.sh`.

## 0.12.242 (2026-11-09)

- **NIRUWM 0.19.1: tiles stay below floating windows.** A tiled window that
  took the focus (the pointer crossing into it, a click, a new window) went to
  the very top, so a NIRUSHOT review window or an Open/Save dialog that
  overlapped two tiles ended up half under one of them. A focused tile now
  stays below every floating window; only its own dialogs go on top.
- **Super+O** opens the NIRU Launcher file search.

## 0.12.241 (2026-11-09)

- **NIRUWM 0.19.0: urgent windows and window swallowing.**
  - A window that asks for attention (the urgency hint or
    `_NET_WM_STATE_DEMANDS_ATTENTION`) gets the theme's attention colour on its
    border and its workspace cell in NIRUBAR. `Super+Shift+U` jumps to the most
    recent one, switching screen, workspace or scratchpad as needed;
    `niructl urgent` lists them.
  - A graphical program started from a terminal takes the terminal's place, and
    the terminal comes back when the program closes. On by default for common
    terminals; `[swallow]` in `config.toml` changes it and
    `niructl swallow on|off|toggle` switches it for the session. Existing
    configuration files need no changes.
- **NIRUBAR 0.19.0** paints urgent workspace cells and marks an urgent
  scratchpad. NIRUWM 0.19.0 bundles it.
- **NIRU Launcher 0.6.0: file search.** Type `/` and a query in the launcher,
  or choose *Find files* in NIRU Actions. Searches the home folder (hidden
  folders, caches and build folders skipped) with recent files first; Enter
  opens, Ctrl+Enter opens the folder, Shift+Enter copies the path.

## 0.12.240 (2026-11-08)

- Supersedes 0.12.239, which was tagged but not published: NIRUWM bundles
  NIRUBAR, so the new NIRUBAR needs NIRUWM 0.18.3 (bundles NIRUBAR 0.18.91;
  no window manager changes).
- **NIRUCLIP 0.4.0: the camera works properly.** It used to record whatever
  mode the camera driver last used, YUYV 640x480 on most webcams (camera-only
  clips were 640x480 at about 40 kb/s with many repeated frames). It now asks
  for MJPEG 1280x720 for the overlay and 1920x1080 for camera-only, skips
  infrared and metadata nodes, and keeps camera, screen and microphone on one
  clock, so the overlay face no longer lags the voice by about 0.3 s.
  A camera that shows its privacy image (such as HP's crossed-out camera),
  freezes, stops delivering frames or is in use by another program is
  detected during the countdown and while recording, and reported in a
  notification, `niruclip --status`, NIRUBAR and NIRU Launcher. The overlay
  is sized from the video height with the camera's aspect, rounded (or
  circle/rect) with a thin theme-coloured border, and can be mirrored. New:
  `--check-camera`, `--preview`, `--export mp4|gif` and `--share`.
- **NIRU Launcher 0.5.1:** the capture view (`--clip`) has Check camera,
  Camera preview, Last recording to MP4/GIF and Share last recording, and
  shows a camera problem while recording.
- **NIRUBAR 0.18.91:** the recording timer shows `· cam off` or `· cam !`
  when NIRUCLIP reports a camera problem.

## 0.12.238 (2026-11-08)

- **NIRULOCK 0.23.1 and NIRUSCREENSAVER 0.14.1:** includes everything listed
  for 0.12.237, which was tagged but never published because GitHub's
  release downloads failed (504) during its release check. Also, Esc during
  the pause music now brings the quote back within about a second. Before,
  a flat spectrum stayed for about six seconds while the audio detector's
  silence window ran out. Other music that is really playing keeps the
  spectrum.

## 0.12.237 (2026-11-08)

- **NIRULOCK 0.23.0 and NIRUSCREENSAVER 0.14.0:** a cleaner, properly centred
  lock and idle screen, with the same elements, colours and fonts. Every
  line is centred by its glyph ink; before, the clock sat 5–8 px right of
  centre and "password:" 3 px left. The `cava` layout is one evenly spaced
  column at the optical centre of the prompt output. Rows for a failure or
  PAM message, Caps Lock and the pause-music line are reserved, so the entry
  never moves, and typing no longer slides it. Long PAM messages wrap to two
  lines, the music line is cut to the panel, quotes wrap evenly, and the
  spectrum lines up with its bars. CAVA pacing is unchanged.

## 0.12.236 (2026-11-08)

- **NIRULOCK 0.22.2:** pause music was silent on sessions started from a text
  console (void), although the lock showed the tune: sidplayfp's own
  `/dev/tty` keyboard handling got it stopped by SIGTTOU as a background
  process group. The player now runs in its own session without a terminal.

## 0.12.235 (2026-11-08)

- **NIRULOCK 0.22.1 and NIRUSCREENSAVER 0.13.1:** the CAVA spectrum is smooth
  now, like NIRUAMP's. It was repainted on a 30 fps timer of its own that
  drifted against CAVA's clock, so a frame was shown twice and another skipped
  every second or so (in bursts lasting several seconds) and each frame was up
  to 34 ms late. Each CAVA frame is now painted the moment it arrives: no
  repeated or skipped frames and 0.1 ms from arrival to paint. Silence pause,
  display-off stop and pause music are unchanged.

## 0.12.234 (2026-11-08)

- **NIRUWM 0.18.1:** on Swedish, German and other layouts where `/` is
  Shift+7, the new Super+/ cheat-sheet key took over Super+7, which opened the
  cheat sheet instead of workspace 7. Now the binding for what a key types
  without Shift wins, so Super+7 is workspace 7 again, and **Super+F1** opens
  the cheat sheet on every layout. The dropped key is named in the session
  log.
- `config.example.toml` and the README list Super+F1.

## 0.12.233 (2026-11-08)

New keys, a color picker and pause music on the lock screen.

- **NIRUWM 0.18.0:** `niructl keys --json` is the live source for a
  keybinding cheat sheet; `[[keys]]` takes an optional `description`; programs
  register their own keys in `~/.local/share/niru/keys.d/<app>.toml`.
  New default keys:
  - `Super+/` keybinding cheat sheet;
  - `Super+.` emoji and symbols;
  - `Super+Ctrl+C` color picker.
  - **Moved:** "focus the next screen" is now `Super+Alt+.` (it was `Super+.`),
    with `Super+Alt+,` as its pair. `Super+,` still focuses the previous
    screen. Add one `[[keys]]` entry to get the old key back.
  - Bundles NIRUBAR 0.18.90 (unchanged).
- **NIRULAUNCHER 0.5.0:** the cheat sheet (`--keys`: grouped, search by words
  or key, Enter runs, Ctrl+R tells what a combo does, clashes flagged), the
  emoji and symbol picker (`--emoji`, `:name` in the launcher; recents, skin
  tones, Enter pastes and restores the clipboard, Shift+Enter copies) and a
  Colors view (`--colors`) of the last ten picked colors.
- **NIRUSHOT 0.6.0:** `nirushot pick`, a freeze-frame color picker with a
  loupe; arrows move 1 px (Shift: 10 px), Tab cycles hex/rgb/hsl, Esc cancels.
- **NIRULOCK 0.22.0:** optional `[pause_music]` (off by default): SID tunes
  from `~/Music/SID` through `sidplayfp` while locked and nothing else plays;
  Esc stops it, and it always stops before suspend.
- **NIRUDICTATE 0.2.1** (extra): registers its shortcuts in the cheat sheet.
- **New dependency `sidplayfp`:** Debian and Void install the distribution
  package. On Arch it is AUR only: NIRUX uses paru or yay when installed, or
  builds it with `makepkg` (perl and the autotools included). A failed build
  only warns and is not retried by every update.
- `config.example.toml` lists the new keys and the moved screen keys.
