# Changelog

Earlier releases are described in their release notes and commit messages.

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
