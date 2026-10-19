# NIRU desktop roadmap

Updated **2026-10-19**. Status: **implementation approved and in progress**.
R0 component corrections are published; NIRUX 0.6.1 integration is being verified.
This plan supersedes the previous M2-first handoff. Detailed evidence,
source locations and verification limits are in [AUDIT.md](AUDIT.md).

## Product direction

- Small, independent Rust/X11 components with a coherent desktop experience.
- Standalone installation on **Void Linux glibc, Arch Linux and Debian**; NIRUPI
  integration is optional and explicit. Current release assets target x86_64.
- English UI, diagnostics, comments and documentation. Dates `YYYY-MM-DD`,
  24-hour time, Monday-first calendars with `Mon Tue Wed Thu Fri Sat Sun` labels.
- **Niru Noir** by default; also support the existing **Niru Nord**, **Niru Satie**
  and **Niru Carl Larsson** themes throughout the suite, plus custom themes.
- Short READMEs: purpose, supported systems, install, essential commands,
  configuration location and links. Detailed reference and testing belong in docs.
- Every visible bar module opens useful information. Actions are deliberate;
  reading volume or media details must not silently mute or pause playback.
- Ship verified increments directly to `main`; component releases precede a
  checksummed, pinned NIRUX release. Existing published versions remain immutable.

## Current checkpoint

The **0.6.1** source manifest pins niruwm **0.16.4**, nirubar **0.16.6**,
niruscreensaver **0.8.0** and nirulock **0.16.6**. The earlier M1 fixes removed
unauthenticated lock timers and raw keycode logging, improved idle child ownership,
and reduced bar/screensaver work. Historical measurements: [MEASUREMENTS.md](MEASUREMENTS.md).

The public repositories **nirulauncher** and **nirunotify** already contain design
contracts. Neither has a working binary/release and neither belongs in the pinned
installer yet. No additional repository is currently necessary for brightness,
night light or themes: put these capabilities behind existing NIRU interfaces.

## Priority order

| Phase | Deliverable | Depends on |
|---|---|---|
| R0 | Memory safety and reliable lock coverage | Approval |
| R1 | WM/bar integration, child lifecycle, truthful installation | R0 |
| R2 | Suite theme and control contracts; standalone desktop actions | R1 |
| R3 | Laptop brightness and night light | R2 |
| R4 | Native launcher and unified command palette | R1, R2 |
| R5 | Responsive bar, weather and information panels | R1, R2 |
| R6 | Native notification service and hardware OSD | R0, R2; reuse proven R4 rendering where useful |
| R7 | Polish, clean documentation and release acceptance | Each completed increment |

R0 is the first implementation checkpoint. Finish and verify a small checkpoint
before starting another. R3 and R4 have no product dependency on each other;
brightness need not wait for an entire notification daemon or weather module.

## R0 — memory safety and lock correctness

- [x] **B01:** replace the undersized handwritten `statvfs` ABI with maintained,
  target-correct bindings. Audit the other handwritten ABI declarations too.
- [x] **L01:** close the lock stacking gap for newly mapped/raised windows;
  coordinate session overlays and test real WM + compositor + notifications.
- [x] **L02:** resize opaque coverage and backing resources on root/RandR changes;
  handle newly connected displays and selected-monitor prompt placement.
- [x] Keep the verified input grabs and authentication-only successful exit from
  M1. Configuration/theme/rendering failures must not dismiss an established lock.
- [ ] Add regressions for the actual failing paths, then publish a correction
  release and update NIRUX pins only after assets and checksums are available.

Acceptance: the filesystem call cannot overwrite adjacent storage; later windows
do not reveal content above the lock in the supported session; expanding or
rearranging the display leaves no uncovered region. Wrong password and Escape
retain input isolation; correct password restores the WM shortcuts.

## R1 — fix the existing desktop before extending it

### niruwm

- [ ] **W01:** one effective binding table for runtime, validation and config dump;
  individual overrides retain unrelated defaults. Add an explicit unbind mechanism.
- [ ] **W02:** reap every application/helper child without one waiting thread per
  long-lived application. Bound repeated hardware-key and helper invocations.
- [ ] **W03:** define a coherent monitor/workspace protocol with nirubar. Use stable
  output identity, correct EWMH global desktop offsets and monitor-targeted commands.
  Honour configured workspace counts/labels, including more than nine.
- [ ] **W04:** reconcile monitor identities during hotplug; refresh monitor config,
  wallpaper state, borders and bars on reload. Poll timeouts must also rotate wallpaper.
- [ ] **W05:** fullscreen uses the complete monitor rectangle, not the bar-reduced
  tiling area; other monitors keep their own bar and usable geometry.
- [ ] **W06:** restore sessions by matching mapped windows to pending launch records,
  not by changing the active workspace before spawning asynchronous applications.
  Restore floating state, deduplicate shared process commands, preserve focus and
  exclude the scratchpad. Use argv for failure notifications.
- [ ] **W07:** complete `niructl` layout coverage and acknowledgements; do not report
  successful reload solely after a fixed sleep. Status must identify the real WM.

### nirubar

- [ ] **B02/B03:** permit exactly one bar per monitor, but one tray per X screen;
  publish/read monitor-specific workspaces rather than nine global cells.
- [ ] **B04:** place popups in root coordinates within their monitor work area;
  map before focus, restore prior focus, repaint Expose, close cleanly on reload.
  Dismissal hit surfaces must not obscure the desktop or block the bar itself.
- [ ] **B05:** complete XEmbed container mapping/layout and correct `_XEMBED` messages;
  selection loss for a tray must not terminate an otherwise healthy bar.
- [ ] **B06:** free X pixmaps on popup close and renderer replacement; keep resource
  ownership explicit and avoid allocating a pixmap for direct window rendering.
- [ ] **B07/B08:** move subprocesses and filesystem capacity checks off rendering;
  clocked samples and graph history must be independent of animation/event rate.
- [ ] **B09:** make left-click informational, with configurable middle/right/scroll
  actions and explicit buttons in interactive panels. Hide hitboxes with modules.
- [ ] **B10/B11:** unify validation expectations, reject invalid time formats safely,
  honour visibility settings, distinguish unavailable/stale data from zero values,
  and repair package-count/error/locale handling and the ALSA parser.

### Installation and standalone operation

- [ ] **X01:** repair component installers: versions, independent component builds,
  pinned session assets, canonical config paths and ownership of installed links.
  An individual installer must not overwrite files inside a NIRUX generation.
- [ ] **X02:** replace dead NIRUPI-only default shortcuts with suite-native actions;
  offer NIRUPI helpers as an explicit compatibility profile.
- [ ] **X03:** make updates install/check newly introduced runtime dependencies;
  diagnose active services/providers, real bar ownership and selected-prefix tools.
- [ ] Test clean installs and upgrades from current versions on all three systems,
  with an empty home and separately with NIRUPI already installed.

Acceptance: actual key presses retain defaults after one override; repeated helper
launches leave no zombies; two displays retain two stable bars and independent
workspaces; repeated popup/reload cycles do not grow X-server pixmap usage;
fullscreen covers its monitor; a compiler-free documented install is truly so.

## R2 — shared appearance and desktop action contracts

- [ ] Specify a small versioned suite appearance document, discoverable through XDG.
  Preserve existing `niruwm/themes` customizations through an explicit compatibility
  precedence; each component remains independently runnable.
- [ ] Use semantic tokens: background, surface, foreground, muted, border, accent,
  success, warning, error, selected and disabled. Define typography, spacing,
  borders, focus indication and reduced-motion behaviour with each theme.
- [ ] Treat colours as colours: never select contrast using numeric RGB `max`.
  Keep an optional opaque black saver/lock background with theme-coloured content.
- [ ] `niructl theme NAME` applies to WM, bar, open palette, notifier and the next
  saver/lock. Define reload notifications and observable success/failure.
  A theme reload never weakens an established lock.
- [ ] Fix root background selection and separate optional GTK/Qt integration from
  native suite theming; application settings remain opt-in exports.
- [ ] Introduce argv-based desktop actions for lock, screensaver, logout, suspend,
  reboot, shutdown, theme selection, DND, idle inhibition and configuration reload.
  `niructl` is the common user-facing interface; a small companion binary within
  an existing repo is acceptable if implementation requires it.
- [ ] Define lock readiness, unlock, idle and notification privacy state with
  explicit ownership and acknowledgement. Do not infer readiness from a child PID.
- [ ] Implement lock-before-suspend with logind/elogind delay-inhibitor integration;
  cover lid close, manual suspend, resume, docking and provider failure.

Acceptance: all four existing themes work across native components; one command
changes the suite consistently; an invalid theme preserves the working state;
standalone actions work with NIRUPI absent. ISO dates and English Monday-first
calendar labels hold even in a Swedish system locale.

## R3 — laptop brightness and night light

### Brightness

- [ ] Bind `XF86MonBrightnessUp` / `XF86MonBrightnessDown` by default. Their keysyms
  already exist; the missing parts are actions and default bindings.
- [ ] Add `niructl brightness up|down|set|status` (proposed CLI), configurable step,
  device and minimum usable level. Coalesce repeat input and show the actual result.
- [ ] Use `brightnessctl` for internal backlights, with correct device selection,
  non-root udev/seat permissions and useful failure messages. Do not use gamma
  dimming as a substitute for hardware brightness.
- [ ] Add a bar `brightness` module: level and an interactive panel with fine steps.
  Hide automatically when no supported device exists; explain unavailable devices
  in the unified desktop menu/diagnostics.
- [ ] Later optional extension: keyboard backlight keys and DDC/CI external monitors,
  isolated behind capability checks; no mandatory DDC polling or access on desktops.

### Night light

- [ ] Add `niructl nightlight on|off|toggle|status|temperature` (proposed CLI),
  a standalone Super+N action and controls in the bar/unified palette.
- [ ] Manage **one** gamma provider, preferring Gammastep on X11. Respect an explicitly
  configured external Redshift/Gammastep owner; never run competing providers.
- [ ] Support manual temperature, fixed schedule and sunrise/sunset schedule,
  configurable transition and day/night Kelvin values. Use explicit coordinates
  for automatic solar timing; manual mode must work offline without GeoClue.
- [ ] Show effective mode/temperature and a temporary override until the next
  schedule boundary. Reapply after resume, hotplug and provider restart.
- [ ] Install `brightnessctl` and the selected night-light backend on Void/Arch/Debian;
  update dependency checks, session cleanup, upgrade and uninstall together.

Hardware checkpoint: Void's Intel backlight accepted **100% → 95% → 100%** without
sudo. Its real RandR display accepted **4500 K** and a reset when explicit location
was supplied. This proves backend feasibility, not completed NIRU keybindings/UI.

## R4 — nirulauncher: two modes, one consistent interface

Use the existing [design contract](https://github.com/nirucon/nirulauncher/blob/main/DESIGN.md),
extended by the appearance and desktop-action contracts above.

- [ ] **Super+P:** `nirulauncher --apps`, focused application search and launch.
  Clean list, keyboard navigation, readable app descriptions, optional favourites
  and recency stored locally. No network requests or persistent indexing daemon.
- [ ] **Super+Shift+P:** `nirulauncher --actions`, applications plus desktop actions,
  grouped/searchable without making normal app search a power menu.
- [ ] Default action groups: **Applications**, **Windows & Workspaces**,
  **Display & Appearance**, **Notifications & Focus**, **Session & Power**.
- [ ] Include window/workspace switching, themes, brightness, night light, notification
  history/DND, timed keep-awake, reload, screensaver, lock, suspend, logout, reboot
  and shutdown as their supporting components become available.
- [ ] Show unavailable actions with an explanation where useful; do not expose
  entries backed only by nonexistent scripts. Custom actions are argv arrays.
- [ ] Confirm logout/reboot/shutdown inside the palette, with Cancel selected first;
  return the exact requested action to the shared desktop-action backend.
- [ ] Honour XDG desktop-file precedence, visibility, TryExec, Terminal, Path and Exec
  quoting/field codes. Never pass desktop-file Exec through a shell.
- [ ] Center/clamp to the active monitor's usable area; single instance, robust
  focus/dismissal, UTF-8 search, scrolling and reasonable contrast on every theme.
- [ ] Release menu input ownership before starting a locker. Test actual Super
  shortcuts, malformed desktop files, duplicate activation and small/two monitors.
- [ ] Publish real binary/checksum assets, then add the component to every NIRUX
  install/update/status/doctor/rollback/uninstall path and fixture.

## R5 — nirubar weather and useful panels

- [ ] Ship a `weather` module alongside optional `sun`, with an optional combined
  compact display; share location/time calculations, not duplicate requests.
- [ ] Use Open-Meteo with metric/Celsius defaults, configurable named location and
  coordinates; retain the previously agreed Ljungskile default in the example.
  A missing location is distinct from the valid coordinates `0,0`.
- [ ] Bar summary: condition, temperature, optional precipitation hint. Panel:
  apparent temperature, wind/gusts, precipitation probability/amount, short hourly
  forecast, sunrise/sunset/day length, last refresh and offline/stale state.
- [ ] Refresh approximately every 30 minutes through bounded background work;
  verified TLS, request/body limits, backoff and a versioned atomic cache.
  Solar data remains usable offline, including polar day/night and DST boundaries.
- [ ] Put new weather settings in nirubar's own namespaced configuration; migrate
  legacy top-level coordinates explicitly instead of expanding shared-parser drift.
- [ ] Make network panels honest about link, address and connectivity; provide
  optional network-management actions without assuming NetworkManager is installed.
- [ ] Improve battery aggregation, charging/remaining-time/health detail where the
  kernel exposes it; do not fabricate missing estimates.
- [ ] Add explicit media controls and player selection; audio output/mic selection
  and mute are deliberate controls. Prefer MPRIS/event subscriptions when practical.
- [ ] Responsive layout: stable workspace region, configurable module priorities,
  overflow panel on narrow screens, monitor-aware popups and optional secondary-bar
  compact mode. Information remains accessible when its summary is hidden.
- [ ] Calendar: `Mon`–`Sun`, Monday first, today indication, month navigation and
  optional ISO week numbers. Match text and cell widths after changing labels.

Acceptance: frozen/hung helpers and weather failures do not stop clicks/redraw;
sample/history intervals remain correct while media scrolls; recorded weather
fixtures cover success, invalid response, offline, stale cache and retry. Normal CI
does not depend on a live provider.

## R6 — nirunotify: notifications and quiet hardware feedback

Use the existing [design contract](https://github.com/nirucon/nirunotify/blob/main/DESIGN.md).

- [ ] Implement the actual `org.freedesktop.Notifications` methods/signals, replacement
  IDs, close reasons, urgency, expiry, actions and supported hints; advertise only
  implemented capabilities. Test interoperability with `notify-send` and real apps.
- [ ] Native themed surfaces with readable app/title/body hierarchy, wrapping,
  restrained urgency accents, actions, configurable monitor/position/width and
  bounded stack/history. Ordinary notifications must not steal keyboard focus.
- [ ] Hardware OSD for volume, brightness and night light: replace/coalesce updates
  using one semantic channel per control, rather than one notification per key.
  Keep a working `notify-send`/Dunst path while the native daemon is developed.
- [ ] DND, history, dismiss and pause through a documented control interface;
  optional bar unread indicator. Critical-notification policy is configurable.
- [ ] Session provider selection: native, Dunst or external; exactly one bus owner,
  tracked child, clear startup failures and no automatic eviction of another daemon.
- [ ] Hide private content while locked and apply an explicit unlock replay policy;
  coordinate with R0/R2 instead of relying solely on stacking.
- [ ] Bound notification text/images, queued messages, history and work per event.
  Memory-only history by default; optional persistence has explicit retention.
- [ ] Publish verified binaries before changing NIRUX defaults or removing Dunst.

## R7 — cleanup and release acceptance

- [ ] Move detailed setup/control/config/testing reference out of long READMEs;
  retain useful configuration examples and link one authoritative roadmap/audit.
- [ ] Remove obsolete alpha/version text, stale helper references, duplicated
  comments and inaccurate claims after the corresponding behaviour is repaired.
- [ ] Keep compatibility readers only with documented precedence/migration tests;
  do not delete user settings, wallpapers, NIRUPI or unrelated installed files.
- [ ] Reconcile saver/locker rendering differences. Extract a small shared crate
  only if repeated proven primitives justify it; pin its version and preserve
  standalone builds. A shared theme contract is required; a framework is not.
- [ ] Include newly released programs in manifest/staging/checksums/version checks,
  diagnostics, session startup/cleanup, offline fixtures, generation adoption,
  rollback and uninstall. Purge/cache ownership must cover every installed component.
- [ ] Run fmt/clippy and meaningful regressions per changed component; clean
  install/update/rollback/uninstall on Void, Arch and Debian. Run GUI protocol
  tests with isolated X/D-Bus and real release assets.
- [ ] On physical Void: laptop keys, backlight, night-light transitions, audio,
  themes, notification privacy, lock/PAM, lid/suspend/resume and external-monitor
  hotplug. Record which tests are physical and which use Xvfb.
- [ ] Review status/diff/history; commit intended files directly on `main`, let CI
  pass, publish versioned component assets and SHA256SUMS, then release NIRUX with
  the completed pins. Record versions, acceptance results and the next handoff.

## Innovative refinements after the foundation

1. **Desktop lens:** the unified palette answers contextual queries such as
   `display`, `night`, `battery`, `weather` and `workspace` with cached local
   information and relevant actions, not just executable names.
2. **One-shot focus sessions:** a timed keep-awake/DND state with a visible remaining
   duration and automatic restoration. Keep manual lock and suspend policy explicit.
3. **Daylight strip:** a restrained weather-panel timeline connecting sunrise,
   sunset, night-light transitions and upcoming rain. Works in all four themes.
4. **Docking profiles:** remember preferred monitor arrangement, bar density and
   output devices by connector identity; preview changes and provide a revert timer.
5. **Quiet saver:** low-frequency position changes for burn-in avoidance, content
   on the active monitor and dim/blank secondary monitors, with explicit policy.
6. **Explain this state:** consistent details for stale weather, unavailable
   brightness, DND, idle inhibition, notification ownership and failed actions;
   expose diagnostics already collected rather than adding a polling daemon.

## Implementation handoff — 2026-10-19

- Published nirubar **0.16.6** (`80e5d8b`): maintained libc bindings, an adjacent-storage
  regression that failed on the old declaration, glibc/musl checks and nonblocking
  close-on-exec signal pipes. Unit, X11, resource and three-distribution CI passed.
- Published nirulock **0.16.6** (`177dd9c`): root/RandR coverage, output-local prompt,
  overlay repairs, bounded event batches and one wakeup-driven PAM worker. Regressions
  failed on old overlay/resize behaviour and pass now, including restack-storm and
  authentication-time overlay checks. Non-root wrong password/Escape/correct password
  passed; PAM distro CI passed on Void/Arch/Debian. Physical hotplug remains untested.
- NIRUX **0.6.1** source pins these two published corrections; integration/release
  verification is the next gate before declaring the suite checkpoint complete.
- R1 source work is committed in niruwm **0.16.5** (`06a3b64`), awaiting CI/release:
  partial bindings and real unbinding, child reaping without per-app threads,
  full-monitor fullscreen, idle wallpaper ticks, bar-independent borders, argv
  notifications, independently versioned installer assets and standalone source
  builds. Actual X11 and isolated source/prebuilt installer tests passed locally.
- After those releases are verified, continue R1 with monitor/workspace agreement,
  popup/tray/pixmap lifecycle and nonblocking bar probes. Do not jump to launcher
  or weather while these integration paths remain broken.

Keep each next checkpoint small and publish only verified assets. Preserve the
existing lock regressions; never add password-derived logging or timed dismissal.
