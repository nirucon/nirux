# Changelog

Earlier releases are described in their release notes and commit messages.

## 0.12.271 (unreleased)

- **Video on the graphics card in Helium.** Videos in the managed Helium are
  decoded by the GPU instead of the CPU (measured: 1080p H264, VP9 and AV1 from
  about 95 % of a core to about 32 %); web calls such as Teams use the same
  decoder. NIRUX finds the
  card that drives the display, installs its VA-API and Vulkan drivers, checks
  them with `vainfo` and `vulkaninfo`, and only then starts Helium with the
  Vulkan video path. AMD and Intel are on by default, NVIDIA is opt-in;
  `[browser] hardware_video = "auto"|"on"|"off"` in the new NIRUX-only
  `~/.config/nirux/browser.toml`. `nirux doctor` shows the card, the formats it
  decodes and the flags; `nirux doctor --fix` installs what is missing.
- **A Helium launcher.** `~/.local/bin/helium` is now a small NIRUX launcher
  that adds these flags (your own flags still win), not a link; it is
  rewritten on every install and update.
- The nightly update may now install Void packages whose names start with a
  capital letter (`Vulkan-Tools`).

## 0.12.270 (2026-11-13)

- **Presenting you can see.** NIRUPRES 2.4.0: the fade in and out now show in
  the presenter view too (in laptop mode they only happened behind it), aim
  Spotlight, Focus and Zoom by pointing at the current slide in the presenter
  view, and Next on the last slide fades to black. Fixes: notes size at start,
  keys with Ctrl/Shift, zoom near the edge, see-through windows under picom.

## 0.12.269 (2026-11-13)

- **Safe presenting in Teams.** NIRUPRES 2.3.0 names its windows so the share
  dialog cannot mix them up (`AUDIENCE · share this · NIRUPRES` and a red
  `PRIVATE presenter · do not share`), checks the share before you start, and
  gives a laptop presenter view with notes, next slide and timer on one screen.
- **Switch workspaces while you present.** NIRUWM keeps the shared audience
  window live while you look elsewhere (`_NIRUWM_KEEP_MAPPED`); before, the
  audience saw a frozen slide.
- **Presenting mode.** `niructl present on|off|status` turns on Do Not Disturb
  and hides private bar modules (`[bar] presenting_hide`); NIRUPRES uses it and
  it ends by itself if NIRUPRES stops.
- **Slides that fit.** Text shrinks to fit its box and never spills over;
  deck health marks slides that do not fit. New layouts: CODE, IMAGE +
  CAPTION, THREE COLUMN; tables wrap.
- NIRUWM 0.28.0, NIRUBAR 0.27.0, NIRUPRES 2.3.0 (extra).

## 0.12.268 (2026-11-13)

- **Nightly updates.** Between 03:00 and 05:00, when nobody is logged in, the
  computer updates its system packages, NIRUX, the extras and the apps by
  itself. `nirux doctor` runs before and after; if something got worse, the
  previous NIRUX and settings come back and a warning is posted. On battery it
  waits for the charger or 50 %. `nirux autoupdate status|last|disable` (on by
  default; Debian, Arch and Void).
- **Apps follow upstream.** Helium, LocalSend and OpenCode update to their
  newest stable release at every `nirux update`, verified against the
  publisher's checksum; the version NIRUX names is the lowest it installs
  (Helium 0.21.2.1, OpenCode 2.2.7). `--apps pinned` keeps the pins.
- **Disk warning in the bar.** A red disk icon left of the gear appears when
  the disk is 90 % full (`[bar] disk_warn`); a click runs `nirux clean`, which
  shows what it would remove and asks first.
- **Fixes after sleep.** After a wake-up NIRUX checks Wi-Fi, sound, screens
  and Tailscale and repairs the common failures; a notice only when it fixed
  something or could not (`nirux resume-check`).
- **Battery health.** The battery panel shows the health in percent of the
  design capacity, the charge cycles and a graph of the last 24 hours.
- **What's new after an update.** The first login on a new version shows its
  highlights once, with a button to the manual (`nirux whats-new`).
- **The bar follows the NIRUX defaults.** Every `nirux update` keeps
  `[bar] modules` on the default list and order, which now includes `updates`
  (system package count) and `disk`; the previous list stays in the settings
  history (`niructl config undo`). `follow_default_modules = false` keeps your
  own list.
- NIRUWM 0.27.1, NIRUBAR 0.26.1.

## 0.12.267 (2026-11-12)

- `nirux extras update` installs NIRUDICTATE 0.3.0 (voice commands); 0.12.266
  had the wrong checksum for it and kept 0.2.1.

## 0.12.266 (2026-11-12)

- **Voice commands: `Super+Alt+Space`** (NIRUDICTATE 0.3.0, an extra). Say
  "öppna terminalen", "open the browser", "gå till arbetsyta tre", "lås
  skärmen", "höj volymen", "anteckning köp mjölk" and more, in Swedish or
  English. A fixed, local list, no AI and never an arbitrary command; closing
  a window and the power commands ask first. `nirudictate command list` shows
  every phrase.
- **Workspace overview: `Super+E`.** Every workspace on every screen as a
  small picture with its window titles; a digit, the arrows or a click go
  there. Pictures stay in memory, only for you, and are deleted when the
  screen locks (NIRUWM 0.26.0, NIRULAUNCHER 0.14.0).
- **`niructl do ACTION`** runs any key binding's action by name from a script
  (`niructl do terminal`, `niructl do tag 3`); it never starts arbitrary
  programs.
- **Privacy dot in the bar.** A red dot while an app uses the microphone, a
  camera or NIRUCLIP screen recording; click it to see which (NIRUBAR
  0.25.0). Added to existing bars once.
- **The power profile follows the charger:** `power-saver` on battery,
  `balanced` on the charger, on laptops. `[battery] auto_profile`,
  `profile_on_battery`, `profile_on_ac`; a profile you pick yourself holds
  until the next plug or unplug, and studio mode still wins.
- **Typewriter clicks in the lock screen** while you type the password
  (`lock-typing`, on by default; `nirux sounds toggle lock-typing` turns it
  off). NIRULOCK 0.26.0, NIRUNOTIFY 0.6.0, which can also pick between
  `EVENT-2.ogg`, `EVENT-3.ogg` variants of any sound.
- **`nirux doctor --fix`** repairs what doctor finds and can safely fix:
  missing packages, the backlight and battery udev rules, a missing bar,
  notification daemon, idle daemon or night-light schedule, and PipeWire
  user services. It asks once (`--yes` for scripts).
- Fixed: after the 0.12.264 update the night light schedule did not start
  until the next login; restarting NIRUWM in place now starts a missing
  night-light or power-profile watcher.

## 0.12.265 (2026-11-12)

- The window jump (`Ctrl+Alt+W`) shows the letters on its labels; in
  0.12.264 they were plain boxes (NIRULAUNCHER 0.13.1).

## 0.12.264 (2026-11-12)

- **Jump to a window: `Ctrl+Alt+W`.** Every visible window on every screen
  gets a short label; type it and that window has the focus. Letters by
  default (home row first), or numbers with `[hints] style = "numbers"` in
  `~/.config/nirulauncher/config.toml` (NIRULAUNCHER 0.13.0).
- **Quick note: `Super+Shift+N`.** One line, added to `~/Notes/inbox.md`
  (`[note] file`) with the time, for NIRUNOTE or any editor. Before `Enter`,
  `↑`/`↓` choose whether it also goes to a Discord webhook or a trusted
  device through NIRUSHARE.
- **The night light follows the sun by default:** warm, reddish 2700 K from
  sunset to sunrise. `Super+N` switches it by hand until the next sunset or
  sunrise; `mode = "manual"` turns the schedule off. Without a location it
  uses Stockholm's. `nirux update` moves a file that still has the old
  defaults (manual, 3400 K) to the schedule once. The schedule changes the
  temperature without notifications.
- **Battery charge limit, 80 % by default** (`[battery] charge_limit`, 100
  for no limit). It is set at every login by `niructl battery`; *Charge to
  100 % once* in Quick Settings (or `niructl battery full`) lasts until the
  next login. It needs firmware support, which `niructl battery status` and
  `nirux doctor` report; many HP models lack it. NIRUX installs a udev rule
  so the limit can be set without root; log in again after the first
  installation. `nirux update` adds the `[battery]` section to the file.

## 0.12.263 (2026-11-12)

- **Settings history and undo.** NIRUWM 0.25.1 keeps every version of
  `config.toml` that loads (the last 30, in
  `~/.local/state/niruwm/config-history/`). `niructl config history` lists
  them with the sections each one changed, `niructl config undo` goes back
  one version (again for one more), `niructl config restore N` picks one and
  `niructl config diff N` shows what changed since. Each command prints the
  change and asks first; `--yes` applies at once. The file being replaced is
  kept first, so every step can be undone, and the session reloads.
- **What you have changed.** `niructl config diff` lists only the values
  that differ from the defaults (changed, added, removed); `--all` also names
  the default keys your file does not have.
- **Reset one part.** `niructl config reset bar` (any section, a key such as
  `bar.modules`, or `all`) takes that part from the NIRUX example, comments
  included, and leaves the rest of the file alone. The picture folders NIRUX
  chose for this machine are kept. `reset all` also works when the file no
  longer parses.
- **The bar reset no longer loses the previous backup.** `nirubar
  --reset-config` (NIRUBAR 0.24.0) runs the reset above, keeps the old file
  in the history instead of overwriting one backup file, and reloads the bars
  itself.
- **`Super+A`, Appearance:** *Undo the last settings change*, *Settings
  history* and *Settings that differ from the defaults* (NIRULAUNCHER 0.12.1).
- **New default bar modules** for new installations and resets: workspaces,
  dictation, recording, scratchpad, layout, media, volume, microphone,
  brightness, display, tailscale, network, wifi, mode, battery, niruxupdate,
  agent, nirusec, dnd, quicksettings, share and clock. Modules for something
  that is not installed (NIRUDICTATE, NIRUSEC, Tailscale, a battery) show
  nothing. An existing `modules` list is not changed.

## 0.12.262 (2026-11-11)

- **An update no longer removes the NIRUX Signature pictures.** The update
  that installs the release's own Noir picture removed other NIRUX pictures
  it did not recognise, and the Signature set (0.12.258) was missing from the
  list it keeps. Run `nirux wallpapers download signature` once if your
  Signature pictures are gone.

## 0.12.261 (2026-11-11)

- **The bar keeps your settings with the Signature wallpaper style (NIRUBAR
  0.23.2, NIRUWM 0.24.4).** NIRUBAR did not know `[wallpaper] theme_style`,
  which `nirux wallpapers style signature` writes. It refused every reload,
  and from 0.12.260 a restarted bar fell back to the default modules. It now
  accepts the key, and when the bar itself has to fall back it says so in a
  notification. `tests/config-contract.sh` checks every key NIRUWM writes
  against NIRUBAR.
- **New wallpapers for seven themes, same colours, new style:** Nord, Forest
  Vigil, Blood of Urðr, Root and Stone, Blue Horizon, The Norns and Winter
  Nights (4K and 8K, nirux-wallpapers v1.2.0). `nirux update` replaces the
  old pictures of the themes you have; a picture you changed yourself stays.
  Satie, Carl Larsson, the extras and Signature are unchanged.

## 0.12.260 (2026-11-11)

(0.12.259 did not publish: NIRUWM had to bundle the new NIRUBAR.)
Nothing to fiddle with after an install:

- **A typing error in the settings no longer logs you out (NIRUWM 0.24.3,
  NIRUBAR 0.23.1).** A stray character in `config.toml` used to stop the bar
  and, at the next login, end the session straight back at the login screen.
  Now both start with the last settings that worked (or the defaults), and a
  notification says where the error is, such as `config.toml line 213`. Fix
  it and reload with `Super+Shift+R`.
- **Tailscale at install.** `nirux install` asks (default yes), installs and
  starts Tailscale on Void, Arch and Debian and shows the link that adds the
  computer to your network. `--tailscale yes|no` chooses it without asking;
  an update changes nothing unless the flag is given.
- **Touchpads tap from the start.** On machines with a touchpad: one finger
  clicks, two right-click, three middle-click, tap and drag, two-finger
  scrolling, and no taps while typing, also on the login screen.
- **Void: sound on every start.** A sound card whose firmware loads late
  (Intel SOF laptops) appeared while runit handed udevd over and stayed
  root-only, so PipeWire offered only "Dummy Output". The new runit service
  `nirux-udev-replay` replays those device events once at start.
- Manual chapters 1 and 13.

## 0.12.258 (2026-11-11)

- **A new default wallpaper.** The Noir picture is now a misty Swedish lake
  (photo by Nicklas Rudolfsson, 2025), 4K and 8K. It replaces the old one on
  update unless you changed the file yourself.
- **NIRUX Signature (NIRUWM 0.24.1).** Every built-in theme can show the same
  photograph toned in its own colours instead of its own artwork:
  `nirux wallpapers style signature` (downloads the 47 MiB pack the first
  time), `Alt+S` in NIRU Theme Selector 0.3.0 or `S` in NIRU Wallpaper 0.3.0.
  Art stays the default; the login screen follows the chosen style.
- Manual chapter 8 and docs/WALLPAPERS.md: Art or Signature.

## 0.12.257 (2026-11-11)

- **Void: elogind no longer restarts every second.** At boot the login
  screen asked for logind before runit had started elogind, D-Bus started a
  copy of its own, and the runit service failed in a loop for as long as the
  machine ran. NIRUX now installs a D-Bus activation file that asks runit to
  start its supervised elogind instead. It takes effect at the next start.

## 0.12.256 (2026-11-11)

- **`nirux checkup` and the Wi-Fi helper no longer ask for a password on
  Void.** sudo uses the last matching rule, and Void's wheel rule sorted
  after the NIRUX rules. The rules are now `zz-nirux-checkup` and
  `zz-nirux-wifi` in `/etc/sudoers.d`, which sort last (sudo and sudo-rs).

## 0.12.255 (2026-11-11)

- **A weekly checkup on every computer (`nirux checkup`).** Monday 07:00,
  or at start when it was missed: disks and the EFI partition, SMART and
  NVMe health, failed services, reboot needed, waiting and security updates,
  NIRUX behind, snapshot age, OOM kills, time sync, Tailscale, firewall and
  battery health. It also cleans the package cache, unused packages and old
  kernels, the journal, coredumps, old temporary files and thumbnails. The
  last three reports are kept, and with a webhook each computer posts its
  report to Discord. Root-owned helper, systemd timer or runit service.
- `smartmontools` (and `pacman-contrib` on Arch) are now installed with NIRUX.
- Manual chapter 11: Weekly checkup.

## 0.12.254 (2026-11-10)

- **NIRUFETCH 0.3.0: a distribution mark in the theme's colours.** A small
  Debian, Arch, Void, Ubuntu or Fedora mark (Tux for others) beside the
  summary, a strip of the terminal colours, and the machine model (`Host`).
  `--full` adds the init system and names displays as xrandr does.
  `~/.config/nirufetch/config.toml` turns the mark off, picks the NIRUX rune
  or the distribution's colours, hides the strip, and chooses the rows.
- Manual chapter 12 and the configuration reference cover the new settings.

## 0.12.253 (2026-11-10)

- **A new volume and brightness OSD (NIRUNOTIFY 0.5.0).** An icon, the name,
  the value in large type and a level bar in the theme accent that glides to
  the new level. A held key keeps the same box, `Muted` shows the last level
  greyed out, and pressing against 0 % or 100 % lights the bar briefly.
- **Notifications and the OSD appear on the focused screen.** Before, the
  screen was chosen once when the session started, so with several screens
  they could land on the wrong screen or across two. They now follow the
  NIRUWM focused screen, keep clear of that screen's bar only, and move at
  once on hotplug or docking. `monitor = "pointer"`, `"primary"` or an output
  name in `nirunotify/config.toml` choose differently.
- Manual chapter 10: the OSD and screen choice.

## 0.12.252 (2026-11-10)

- **Closing the lid while docked locks (NIRUWM 0.23.3).** With external
  screens the laptop stays awake as before, but the screen now locks.
  `[idle] lock_on_lid_close = false` turns it off. Undocked, the lid locks and
  suspends as before.

## 0.12.251 (2026-11-10)

- **An update waiting for the unlock is not lost (NIRUWM 0.23.2).** When the
  screen was locked again within seconds of an unlock, the in-place restart
  gave up until the next login; it now waits for the next unlock.
- The sound rate limit no longer depends on a printf in a command
  substitution (a held volume key could tick twice).

## 0.12.250 (2026-11-10)

- **Locking works while the screensaver is up (NIRUWM 0.23.1).** A manual
  lock, `Super+Shift+Escape` or the lock before a lid-close suspend failed
  while NIRUSCREENSAVER held the pointer; the screensaver is now closed first.
- **The display no longer goes dark before the lock.** The X server's own
  10-minute blank and DPMS timers are kept at zero, so the idle ladder
  (screensaver, lock, display off) runs as configured.
- Manual chapter 6: these fixes, lid behaviour when docked, and how to make
  the idle lock come sooner.

## 0.12.249 (2026-11-10)

- **Updates without logging out (NIRUWM 0.23.0).** `nirux update` inside a
  session now runs `niructl restart-wm`: the window manager, bars and changed
  helpers restart in place with every window, workspace, layout and scratchpad
  kept. A locked screen stays locked; the restart waits for the unlock. A
  session on NIRUWM older than 0.23.0 needs one last login.
- **`lock_after_screensaver = 0` locks.** It locks at `screensaver_timeout`
  instead of only showing the screensaver.
- **Calendar reminders (NIRUBAR 0.23.0).** A notification before timed events,
  10 minutes by default; `remind_minutes` in `calendars.toml` (0 = off).
- **NIRUNOTE 0.7.1.** Full CommonMark and GitHub Markdown in the preview
  (tables, footnotes, alerts, highlighted code), `--read-only`, `--heading`,
  find in the preview, back after links, faster on big files. `nirux manual`
  opens read-only at the chosen heading.
- **Fleet health.** `nirux fleet` has a HEALTH column: disk, failed units,
  stale sessions and lock readiness (also in `--json`).
- **Multichannel inputs (NIRUCLIP 0.7.0, NIRULAUNCHER 0.11.0).** Record one
  input or a pair of an interface such as the UMC1820 with `--mic-channels`;
  the launcher's Capture view shows a Mic inputs row only when such an
  interface is present.

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
