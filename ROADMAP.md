# NIRU desktop roadmap

Updated **2026-10-19**. Status: **implementation approved and in progress**.
R0 is published and physically verified on Void; the first R1 corrections are
verified and pinned for NIRUX 0.6.2. R1 as a whole remains in progress.
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

The **0.10.12** manifest pins niruwm **0.16.19**, nirubar **0.18.6**,
niruscreensaver **0.8.1**, nirulock **0.16.8**, nirulauncher **0.1.1** and
nirunotify **0.3.2**. NIRULAUNCHER provides native Super+P apps and
Super+Shift+P apps/actions; NIRUNOTIFY is an installed native notification
provider (Dunst remains the default); NIRUBAR has an opt-in Open-Meteo weather
module with background refresh and a versioned cache.
NIRULOCK publishes explicit lock readiness; `niructl suspend` waits for it,
idle inhibition is explicit, and the session holds a sleep delay inhibitor and
locks before releasing it. Updates provision the
downloaded release's runtime package list without a full system upgrade, and
doctor reports selected programs, providers, real bar ownership and prefix
tools. Native `niructl` desktop actions cover lock, screensaver, logout,
suspend, reboot, shutdown, DND, theme and reload; the saver and lock screen
follow the suite theme for content colours. Default shortcuts are
suite-native; NIRUPI's helper shortcuts and session helpers are an explicit
`nirupi_compat` profile. Session restore matches mapped windows to their saved
launch records, including floating state and focus. Reload and theme commands
wait for the window manager's observable result instead of a fixed sleep, and a
rejected configuration keeps the previous working state. Historical
measurements: [MEASUREMENTS.md](MEASUREMENTS.md).

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
- [x] Add regressions for the actual failing paths, then publish a correction
  release and update NIRUX pins only after assets and checksums are available.

Acceptance: the filesystem call cannot overwrite adjacent storage; later windows
do not reveal content above the lock in the supported session; expanding or
rearranging the display leaves no uncovered region. Wrong password and Escape
retain input isolation; correct password restores the WM shortcuts.

## R1 — fix the existing desktop before extending it

### niruwm

- [x] **W01:** one effective binding table for runtime, validation and config dump;
  individual overrides retain unrelated defaults. Add an explicit unbind mechanism.
- [x] **W02:** reap every application/helper child without one waiting thread per
  long-lived application.
- [ ] Bound/coalesce repeated hardware-key and helper invocations; child reaping
  alone does not impose an execution/time/output budget.
- [x] **W03:** global EWMH desktop numbers and `_NIRUWM_MONITORS` give each output a
  stable offset/count/active range; clients publish global desktops and `niructl`
  addresses them. Released in niruwm 0.16.6.
- [x] **W04:** clients re-home by RandR output name, master counts survive reorder,
  and reload rebuilds monitor config, wallpaper, borders and bars. Idle wallpaper
  ticks were fixed earlier. Released in niruwm 0.16.6.
- [x] **W05:** fullscreen uses the complete monitor rectangle, not the bar-reduced
  tiling area; other monitors keep their own bar and usable geometry.
- [x] **W06:** restore sessions by matching mapped windows to pending launch records,
  not by changing the active workspace before spawning asynchronous applications.
  Restore floating state, deduplicate shared process commands, preserve focus and
  exclude the scratchpad. Use argv for failure notifications. Released in niruwm
  0.16.10.
- [x] **W07, first step:** `niructl layout centeredfloat` works (control value 6) and
  `niructl status` reports the real `_NET_WM_NAME`. Released in niruwm 0.16.8.
- [x] **W07, acknowledgement:** reload and theme publish `_NIRUWM_CONFIG_ACK` with
  the requesting serial and the applied theme; rejection uses the high bit and keeps
  the working state. Released in niruwm 0.16.9.

### nirubar

- [x] **B02/B03:** one bar per monitor on a shared X screen, one tray per screen,
  monitor-local cells read from `_NIRUWM_MONITORS`, global desktop occupancy and
  monitor-targeted workspace commands. Released in nirubar 0.17.0.
- [x] **B04:** place popups in root coordinates within their monitor work area;
  map before focus, restore prior focus, repaint Expose, close cleanly on reload.
  The click catcher is input-only and no longer obscures the desktop or blocks the bar.
  Released in nirubar 0.16.8 with a two-coordinate/focus/restore X11 regression.
- [x] **B05:** mapped XEmbed manager container and sent the real `_XEMBED`
  embedded-notify message; tray handover no longer terminates the bar. Released in
  nirubar 0.16.11 with an isolated embedding/selection-loss regression.
- [x] **B06:** free X pixmaps on popup close and renderer replacement; keep resource
  ownership explicit and avoid allocating a pixmap for direct window rendering.
- [x] **B07:** `wpctl`/`playerctl`/`ip`/`iw`/package queries use a bounded runner
  (deadline, process-group kill, capped output); load/memory/statvfs sampling runs
  on one background worker instead of rendering. Released in nirubar 0.17.0.
- [x] **B08:** load/graph samples use a one-second cadence independent of repaint and
  scrolling; a regression calls render fifty times and observes one sample.
  Released in nirubar 0.16.10.
- [x] **B09, first step:** volume/media information clicks do not mute or toggle
  playback. A GUI regression checks helper action logs.
- [ ] Finish B09 with configurable middle/right/scroll actions and explicit buttons
  in interactive panels. Hide hitboxes with modules.
- [x] **B10, calendar step:** Monday-first English `Mon Tue Wed Thu Fri Sat Sun`
  labels with matching three-character day cells.
- [x] **B11, probe step:** real `amixer "[NN%] [on]"` output parses correctly;
  update queries force the C locale and do not report failed diagnostics as zero.
- [ ] Finish B10/B11: unify validation expectations, reject invalid time formats safely,
  honour visibility settings and distinguish unavailable/stale data from zero values.

### Installation and standalone operation

- [ ] **X01:** repair component installers: versions, independent component builds,
  pinned session assets, canonical config paths and ownership of installed links.
  An individual installer must not overwrite files inside a NIRUX generation.
- [x] **X02:** replace dead NIRUPI-only default shortcuts with suite-native actions;
  offer NIRUPI helpers as an explicit compatibility profile. Released in niruwm
  0.16.11 and nirubar 0.17.2 (the bar accepts the shared setting).
- [x] **X03:** make updates install/check newly introduced runtime dependencies;
  diagnose active services/providers, real bar ownership and selected-prefix tools.
  Released in NIRUX 0.7.6.
- [x] **X03, vanilla completeness:** every fresh install provides the native
  experience without manual suite dependencies: X input drivers, DejaVu plus an
  icon font (JetBrains Nerd Font on Arch, Symbols Nerd Font on Void, Font Awesome
  fallback on Debian), PipeWire ALSA, screenshot selection (maim/slop), pcmanfm,
  network tools (iproute2/iw) and xdg-utils. Audio includes PipeWire,
  WirePlumber, the Pulse/ALSA bridges, ALSA UCM profiles and RTKit; doctor checks
  for a default sink. Dead Flameshot default removed. Released in NIRUX 0.10.5/0.10.6.
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
- [x] `niructl theme NAME` applies to WM and bar, reports observable
  success/failure, and the next saver/lock uses the selected theme's content
  colours with an opaque black background. A theme reload does not dismiss a lock.
- [ ] Extend theme propagation to the open palette and native notifier once those
  components exist; define their reload notifications.
- [ ] Fix root background selection and separate optional GTK/Qt integration from
  native suite theming; application settings remain opt-in exports.
- [x] Introduce argv-based desktop actions for lock, screensaver, logout, suspend,
  reboot, shutdown, theme selection, DND and configuration reload. `niructl` is
  the common user-facing interface.
- [x] Add idle inhibition (`niructl idle on|off|toggle|status [MINUTES]`,
  `Super+Shift+C`) with an explicit expiring state file; NIRUIDLE resets the idle
  clock and suppresses saver/lock/DPMS while it is active. Released in niruwm
  0.16.14.
- [ ] Keep confirmation in the launcher for logout/reboot/shutdown.
- [x] Define lock readiness with explicit ownership and acknowledgement. NIRULOCK
  publishes `_NIRU_LOCK_READY` naming its mapped lock window and clears it on
  unlock; no child PID is treated as proof. Released in nirulock 0.16.8.
- [ ] Extend the state contract to idle and notification privacy, and define the
  authenticated unlock replay policy.
- [x] Manual `niructl suspend` locks first and refuses to suspend without verified
  readiness. Released in niruwm 0.16.13.
- [x] Hold a logind/elogind sleep delay inhibitor in the session, lock on
  PrepareForSleep(true), and release only after verified readiness; a failed lock
  keeps the inhibitor held. Released in niruwm 0.16.15.
- [ ] Physically verify lid close, resume, docking and inhibitor-provider failure;
  the delay-inhibitor backend and manual lock path are tested on Void.

Acceptance: all four existing themes work across native components; one command
changes the suite consistently; an invalid theme preserves the working state;
standalone actions work with NIRUPI absent. ISO dates and English Monday-first
calendar labels hold even in a Swedish system locale.

## R3 — laptop brightness and night light

### Brightness

- [x] Bind `XF86MonBrightnessUp` / `XF86MonBrightnessDown` by default.
- [x] `niructl brightness up|down|set N|status` uses brightnessctl and notifies the
  actual level. Fixed five-percent steps for now; configurable device/step remains.
- [x] Internal backlights use `brightnessctl` and report missing tools/devices.
  Vendor device selection and seat-permission diagnostics remain follow-up work.
- [x] Bar `brightness` module hides without a device and explains controls in its
  panel. Fine interactive steps remain part of the unified controls work.
- [ ] Later optional extension: keyboard backlight keys and DDC/CI external monitors,
  isolated behind capability checks; no mandatory DDC polling or access on desktops.

### Night light

- [x] `niructl nightlight on|off|toggle|status|temperature K` and Super+N manage
  one manual Gammastep adjustment with explicit coordinates.
- [x] Manual mode uses one Gammastep one-shot and `-x` reset; external providers are
  respected. Scheduled/daemon ownership remains open.
- [x] Manual Kelvin and explicit coordinates work offline without GeoClue.
- [ ] Add fixed and sunrise/sunset schedules, transitions and resume reapplication.
- [ ] Show schedule state and reapply after resume/hotplug/provider restart.
- [x] Install `brightnessctl` and `gammastep` on Void, Arch and Debian; doctor checks
  them. `nirux update` now provisions this release's package list (X03).

Hardware checkpoint: Void's Intel backlight accepted **100% → 95% → 100%** without
sudo. Its real RandR display accepted **4500 K** and a reset when explicit location
was supplied. This proves backend feasibility, not completed NIRU keybindings/UI.

## R4 — nirulauncher: two modes, one consistent interface

Use the existing [design contract](https://github.com/nirucon/nirulauncher/blob/main/DESIGN.md),
extended by the appearance and desktop-action contracts above.

- [x] **Super+P:** `nirulauncher --apps`, focused application search and launch.
  Clean list, keyboard navigation, readable app descriptions. No network requests
  or persistent indexing daemon. Released in nirulauncher 0.1.1.
- [x] **Super+Shift+P:** `nirulauncher --actions`, applications plus desktop actions,
  searchable without making normal app search a power menu. NIRUWM prefers the
  suite launcher and keeps the configured launcher as fallback.
- [ ] Add visual action groups, favourites and recency stored locally; the current
  0.1 list is flat and searchable.
- [ ] Default action groups: **Applications**, **Windows & Workspaces**,
  **Display & Appearance**, **Notifications & Focus**, **Session & Power**.
- [x] Include workspace switching, themes, brightness, night light, DND, timed
  keep-awake, reload, screensaver, lock, suspend, logout, reboot and shutdown.
- [ ] Add window switching and notification history when their backends expose
  documented lists.
- [ ] Show unavailable actions before activation with an explanation where useful;
  failures are currently shown as an inline error. Custom actions are argv arrays.
- [x] Confirm logout/reboot/shutdown inside the palette; Escape cancels and the
  exact `niructl` action is returned to the shared backend.
- [x] Honour XDG desktop-file precedence, visibility, TryExec, Terminal, Path and
  Exec quoting/common field codes. Desktop Exec is parsed into argv, never a shell.
  English `Name` is preferred; localized names and the full field-code set remain.
- [x] Center/clamp to the pointer monitor, single instance, focus/dismissal,
  UTF-8 display/search, scrolling and suite-theme contrast. Keyboard text input is
  Latin-1; input methods and malformed small/two-monitor matrices remain.
- [x] Release menu input ownership before starting a locker. Super+P and
  Super+Shift+P were exercised on Void in an isolated X session.
- [x] Publish binary/checksum assets and add the component to NIRUX
  install/update/status/doctor/rollback/uninstall and fixtures. Released in
  NIRUX 0.9.0.

## R5 — nirubar weather and useful panels

- [x] Ship a `weather` module alongside optional `sun`; both share the same
  configured coordinates. Released in nirubar 0.18.1.
- [ ] Add an optional combined compact weather/sun cell and share request/derived
  time calculations explicitly rather than only the coordinates.
- [x] Use Open-Meteo with metric/Celsius defaults, a configurable named location
  and coordinates; the example uses Ljungskile. A missing location is distinct
  from a deliberately configured `0,0` (regression in nirubar 0.18.1).
- [x] Bar summary: condition and temperature. Panel: apparent temperature,
  wind/gusts, precipitation, six-hour forecast, sunrise/sunset, last refresh and
  offline/stale state.
- [ ] Add the optional precipitation hint to the summary and day length to the panel.
- [x] Refresh approximately every 30 minutes through bounded background work;
  HTTPS-only curl, request/body limits, failure backoff and a versioned atomic
  cache. A live Open-Meteo request and the cache were verified on Void. Solar data
  remains from the existing offline `sun` module.
- [x] Put weather settings in `~/.config/nirubar/config.toml`; legacy shared
  top-level coordinates remain an explicit fallback.
- [ ] Make network panels honest about link, address and connectivity; provide
  optional network-management actions without assuming NetworkManager is installed.
- [ ] Improve battery aggregation, charging/remaining-time/health detail where the
  kernel exposes it; do not fabricate missing estimates.
- [ ] Add explicit media controls and player selection; audio output/mic selection
  and mute are deliberate controls. Prefer MPRIS/event subscriptions when practical.
- [ ] Responsive layout: stable workspace region, configurable module priorities,
  overflow panel on narrow screens, monitor-aware popups and optional secondary-bar
  compact mode. Information remains accessible when its summary is hidden.
- [x] Calendar: `Mon`–`Sun`, Monday first, today indication, ISO week numbers and
  Left/Right month navigation with fixed cell widths. Released in nirubar 0.18.5.

Acceptance: frozen/hung helpers and weather failures do not stop clicks/redraw;
sample/history intervals remain correct while media scrolls; recorded weather
fixtures cover success, invalid response, offline, stale cache and retry. Normal CI
does not depend on a live provider.

## R6 — nirunotify: notifications and quiet hardware feedback

Use the existing [design contract](https://github.com/nirucon/nirunotify/blob/main/DESIGN.md).

- [x] Implement the core `org.freedesktop.Notifications` methods, replacement IDs,
  close reasons, urgency, expiry, `NotificationClosed`, clickable actions and
  `ActionInvoked`; advertise only `body` and `actions`. `notify-send`, replacement,
  history and a default-action click are covered by the D-Bus/X11 smoke test.
  Released in nirunotify 0.1.2/0.3.0.
- [ ] Add images and richer hints only after each is implemented and advertised.
- [x] Native themed surfaces with app/title/body hierarchy, wrapping, restrained
  urgency accents, configurable position/width, pointer/primary/named monitor
  selection, bounded stack/history and no keyboard focus steal. Monitor selection
  released in nirunotify 0.2.0.
- [x] Action buttons with a default-action body click, plus an optional bar unread
  indicator/history panel. Released in nirunotify 0.3.0 and nirubar 0.18.2.
- [x] Hardware OSD for volume, brightness and night light through
  `nirunotify --osd CHANNEL TEXT`; one surface is replaced per update. NIRUCTL,
  the WM volume keys and night light use it when the daemon is running and fall
  back to `notify-send`/Dunst.
- [x] DND, history, dismiss and clear through a documented Unix-socket CLI.
  History is memory-only and bounded at 100 entries. Critical notifications have
  a configurable timeout and DND-bypass policy (nirunotify 0.2.0).
- [x] Add an optional nirubar `notifications` unread indicator and history panel
  backed by `nirunotify --count/--history`. Released in nirubar 0.18.2.
- [x] Session provider selection (`NOTIFICATION_PROVIDER=auto|native|dunst|external`),
  exactly one bus owner, a tracked child, clear startup failure and no eviction
  of an existing daemon. `auto` now prefers the verified native service when
  installed and keeps Dunst as fallback. Released in niruwm 0.16.19.
- [x] Hide private content while `_NIRU_LOCK_READY` names a live lock window;
  queue up to 100 notifications and replay them after verified unlock.
- [x] Bound text, live/replacement maps, queued commands and history at 100;
  memory-only history, no images accepted, no per-event worker threads.
- [x] Publish verified binaries, integrate install/update/status/doctor/
  rollback/uninstall and make the verified native service the default when
  installed, with Dunst retained as fallback.

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
- NIRUX **0.6.1** is published and installed on the physical Void laptop. Its full
  Arch/Debian/Void CI passed in [39218765783](https://github.com/nirucon/nirux/actions/runs/39218765783).
  On the real Xorg desktop, nirulock 0.16.6 stayed above Dunst notifications,
  rejected wrong password/Escape and accepted the correct password. The updated
  bar was restarted through its WM owner and live diagnostics passed.
- R1 niruwm **0.16.5** (`b02c07f`) is published with successful three-distribution
  session CI [39219010977](https://github.com/nirucon/niruwm/actions/runs/39219010977):
  partial bindings and real unbinding, child reaping without per-app threads,
  full-monitor fullscreen, idle wallpaper ticks, bar-independent borders, argv
  notifications, independently versioned installer assets and standalone source
  builds. Actual X11 and isolated source/prebuilt installer tests passed locally.
  One CI-only fixture issue (isolated HOME hiding rustup settings) was corrected
  before tagging; no failed release/tag was replaced.
- R1 nirubar **0.16.7** (`c28d24a`) has successful three-distribution CI
  [39220093599](https://github.com/nirucon/nirubar/actions/runs/39220093599): no
  disposable popup pixmaps, explicit main-buffer release on reload, information-only
  volume/media clicks, canonical standalone config paths and NIRUX ownership refusal.
  X-Resource regression checks server storage across popup/theme/reload cycles;
  helper action logs remain empty. Details/reference moved out of the short README.
- NIRUX **0.6.2** pins these already-published component assets. Suite acceptance
  passed [CI 39220970675](https://github.com/nirucon/nirux/actions/runs/39220970675)
  and [release 39221324010](https://github.com/nirucon/nirux/actions/runs/39221324010).
  The published generation is installed on Void; the running bar is 0.16.7 and
  live diagnostics/config checks passed. Physical checks additionally verified
  that Super workspace shortcuts are blocked during lock and work after correct
  authentication; the original workspace was restored after testing. A running
  niruwm 0.16.4 session needs a new login to activate installed WM/session 0.16.5;
  replacing files or restarting the bar does not upgrade the running WM.
- Physical test precondition: a direct locker launch while the idle saver already
  owned input refused the pointer grab and displayed no password surface. Waking
  that unlocked saver allowed acceptance to pass. Preserve this refusal behaviour;
  coordinated manual-lock/idle-saver transitions remain part of I01/R2.
- NIRUX **0.6.3** pins nirubar **0.16.8** and passed CI
  [39227218456](https://github.com/nirucon/nirux/actions/runs/39227218456) and
  release [39227581664](https://github.com/nirucon/nirux/actions/runs/39227581664).
  Installed on Void; the restarted live bar reports 0.16.8. Physical lock, PAM,
  notification-coverage and post-unlock shortcut tests passed again. Popups now
  use monitor/root coordinates, focus after mapping, repaint retained content and
  restore prior focus; the click catcher is input-only and the bar stays clickable.
- NIRUX **0.6.5** pins nirubar **0.16.10** after successful CI and release; installed
  on Void with the live bar reporting 0.16.10. The physical lock/PAM/shortcut and
  notification-coverage checks passed again. Load sampling is fixed-cadence, ALSA
  parsing handles real `[NN%] [on]` output, and update queries are locale-stable and
  do not convert failed diagnostics into zero updates. Remaining B07 probes still
  run synchronously; this checkpoint does not claim they are nonblocking.
- NIRUX **0.6.6** pins nirubar **0.16.11** after green CI/release; installed on Void
  with the live bar reporting 0.16.11. XEmbed icons are reparented into a mapped
  manager, receive `_XEMBED_INFO` and the real embedded-notify message; a tray
  selection handover no longer terminates the bar. Physical lock/PAM/shortcut and
  notification-coverage checks passed again. Remaining B07 probes are still
  synchronous.
- NIRUX **0.7.0** pins niruwm **0.16.6** and nirubar **0.17.0** after green CI and
  release. Installed on Void; the live bar reports 0.17.0 and physical lock/PAM/
  notification/shortcut checks passed. The running WM was still 0.16.4 during that
  check, so monitor-offset integration takes effect at the next login. Bar 0.17.0
  falls back to nine global workspaces when `_NIRUWM_MONITORS` is absent.
- Verified regressions: two bars share one X screen, same-monitor duplicates are
  refused, a right-monitor cell click sends global desktop 4, XEmbed icons embed,
  tray handover does not kill the bar, bounded probes time out and cap output, and
  load sampling stays on its worker.
- NIRUX **0.7.1** pins niruwm **0.16.7** and nirubar **0.17.1** after green CI and
  release; installed on Void. Backlight keys and `niructl brightness` changed the
  physical laptop 100%→95%→100%. `niructl nightlight toggle` applied Gammastep in
  the live session and `off` reset it; the test restored the off state.
- NIRUX **0.7.2** pins niruwm **0.16.8** after green CI/release and is installed on
  Void. `niructl layouts` and direct `centeredfloat` selection are complete; status
  reports the real WM name.
- NIRUX **0.7.3** pins niruwm **0.16.9** after green CI
  [39247666501](https://github.com/nirucon/niruwm/actions/runs/39247666501) and
  release. Installed on Void. `niructl reload`/`theme` no longer sleep: they wait
  for `_NIRUWM_CONFIG_ACK`, verify `_NIRUWM_THEME`, and report a rejected
  configuration while the previous state stays active. Rejection now fails with a
  regression that previously would have reported success. On Void, the installed
  release passed an isolated Xvfb acceptance; the live session still runs WM 0.16.8
  until the next login, where the new `niructl` uses the documented compatibility
  pause and warning for the old manager.
- NIRUX **0.7.4** pins niruwm **0.16.10** after green CI
  [39250016754](https://github.com/nirucon/niruwm/actions/runs/39250016754) and
  release. Installed on Void. Restore now waits for mapped windows, applies the
  saved screen/workspace and floating state, starts shared commands once, excludes
  the scratchpad and finally shows the saved focus. The X11 regression covers two
  saved placements and final focus. The installed release passed an isolated Xvfb
  acceptance on Void; the live session still runs the older WM until the next
  login.
- NIRUX **0.7.5** pins niruwm **0.16.11** and nirubar **0.17.2** after green CI
  [39252819310](https://github.com/nirucon/niruwm/actions/runs/39252819310) and
  releases. Installed on Void. Defaults no longer bind NIRUPI-only helpers;
  `nirupi_compat = true` adds the old shortcuts, and the session starts NIRUPI
  battery/autostart/lock helpers only in that profile. The installed binaries
  accept the shared setting in both standalone and compatibility configurations,
  and `niruwm --dump-config` confirms the defaults are suite-native. Live
  session acceptance still needs the next login.
- NIRUX **0.7.6** added update provisioning from the downloaded release's
  package list and expanded doctor checks. Installed on Void. The update from
  0.7.5 still used the old installer's disabled-package path, so the first
  0.7.6 update did not provision; the installed 0.7.6 `_provision` dry run now
  reads the new list. Doctor correctly reports the live WM, one bar for one
  published monitor, the selected prefix, configured programs and missing
  providers on the physical session. Integration covers missing-package
  detection, dry-run provisioning and bar cache purge.
- NIRUX **0.7.7** pins niruwm **0.16.12** with argv-based `niructl` actions for
  lock, screensaver, logout, suspend, reboot, shutdown and provider-aware DND,
  plus `Super+Shift+D`. Unit tests use fake backends and assert the exact argv.
  NIRUX **0.7.8** stops update provisioning from performing a full system
  upgrade: an explicit missing-package list installs only those packages.
- NIRUX **0.7.9** pins niruscreensaver **0.8.1** and nirulock **0.16.7**. Both
  read the theme selected in `~/.config/niruwm/config.toml`, prefer a user theme
  file, and keep an opaque black background. Their tests cover built-in and user
  theme precedence. Installed on Void; both installed binaries accept a Nordic
  suite configuration. Live saver/lock rendering still needs the next lock test.
- NIRUX **0.8.0** pins nirulock **0.16.8** and niruwm **0.16.13**. NIRULOCK
  publishes `_NIRU_LOCK_READY` only after verified grabs and a mapped surface,
  and clears it on accepted unlock. The X11 regression asserts the marker names
  the visible lock window; a killed locker leaves no usable window even if the
  property survives. `niructl suspend` starts or reuses a ready NIRULOCK and
  refuses a locker that cannot confirm readiness. The installed 0.8.0 binary
  passed an isolated Xvfb readiness/stale-window check on Void.
- NIRUX **0.8.1** pins niruwm **0.16.14**. `niructl idle on|off|toggle|status
  [MINUTES]` writes an explicit expiring state file; NIRUIDLE resets the idle
  clock and suppresses saver/lock/DPMS while it is active. The installed binary
  passed a live state-file check on Void (`off → on 1 min → off`).
- NIRUX **0.8.2** pins niruwm **0.16.15**. The session holds a
  logind/elogind delay inhibitor (systemd-inhibit or elogind-inhibit) and listens
  for `PrepareForSleep(true)` with dbus-monitor; it locks via the readiness
  contract before releasing the inhibitor, and holds it if locking fails. On
  Void, `elogind-inhibit` acquisition/listing and `niructl lock` readiness passed.
  A physical lid-close/resume/docking test remains open.
- NIRUX **0.9.0** pins nirulauncher **0.1.1** and niruwm **0.16.16** and installs
  the launcher in every generation. The first update from 0.8.2 used the old
  installer and omitted the new program; the second 0.9.0 update staged it, the
  same one-release transition as the update-provisioning change. On Void, the
  installed launcher opened through real Super+P and Super+Shift+P in an isolated
  X session, and Escape returned focus/closed it. UI smoke also covers search,
  quoted argv, outside-click dismissal and singleton activation on Xvfb.
- NIRUX **0.9.1–0.9.2** pin nirubar **0.18.0–0.18.1**. Weather is opt-in via the
  `weather` module; settings live in `~/.config/nirubar/config.toml`. The live
  request and atomic cache were verified on Void, and a unit regression keeps
  configured `0,0` distinct from an unset location. Background refresh, stale
  state, backoff and the panel are covered by unit tests and the live check.
- NIRUX **0.10.0–0.10.1** install nirunotify **0.1.2** while leaving Dunst as
  the provider default. The first update from 0.9.2 used the old installer and
  omitted the new program; the second 0.10.0 update staged it. On Void, a native
  provider session in an isolated D-Bus/X session delivered `notify-send` into
  history, owned the bus as the only configured provider, cleaned the notifier
  up on logout, and the installed daemon passed DND/history/OSD/lock-privacy
  checks. Notification actions/images, monitor selection and physical provider
  acceptance remain open.
- NIRUX **0.10.2** pins nirunotify **0.2.0**, adding pointer/primary/named
  monitor selection and configurable critical timeout/DND policy. Installed on
  Void; the notifier smoke test still passes. Notification actions/images, bar
  unread and physical provider acceptance remain.
- NIRUX **0.10.3** pins nirubar **0.18.2** and nirunotify **0.2.1**. The optional
  bar unread indicator/history panel was installed and a live count was exercised
  on Void. Installed on Void.
- **Arch ThinkPad clean acceptance:** Tailscale became reachable. The machine had
  an orphaned NIRUX 0.4.1 flat install, no NIRUPI, no config, no session entry and
  no `.xinitrc`. Cloning current main and running `./nirux install
  --display-manager startx` installed 78 Arch packages, adopted the legacy
  generation, activated NIRUX 0.10.3, created `.xinitrc`/session entry and kept
  the legacy generation for rollback. `nirux status` and `doctor` pass; all seven
  components report the pinned versions. An isolated Xvfb session launched through
  `niruwm-session` (the startx path), started the WM and bar, opened nirulauncher
  with a real Super+P, closed it with Escape, and quit without leftover
  WM/bar/Dunst processes. A physical `startx` on the laptop remains for the user
  to confirm; no display manager is enabled.
- NIRUX **0.10.4** fixes the vanilla Arch/Debian/Void experience: Arch gets
  xf86-input-libinput, xwininfo, iw, iproute2, xdg-utils and the JetBrains Mono
  Nerd Font; Debian gets libinput, iw, iproute2 and xdg-utils; Void gets xwininfo,
  iw, iproute2, xdg-utils and the 5 MB Symbols Nerd Font. NIRUBAR 0.18.3 shows
  workspaces, media, volume, brightness, network, battery and clock by default,
  with icon glyphs borrowed from the symbols font when the text font lacks them.
  The update module stays opt-in so its package query cannot delay first paint.
  Installed on the Arch ThinkPad, where the restarted live bar now shows the
  workspace cells, volume, brightness, wifi, battery and clock icons. The Void
  machine was updated too, but no live WM was running at that moment; the new
  bar activates at the next login.
- NIRUX **0.10.4–0.10.5** close the vanilla dependency gap. Arch installs
  xf86-input-libinput, xwininfo, iw, iproute2, xdg-utils, PipeWire ALSA, slop,
  pcmanfm and JetBrains Mono Nerd Font; Debian adds libinput, PipeWire ALSA,
  slop, pcmanfm, network tools and Font Awesome for icon fallback; Void adds
  xwininfo, network tools, xdg-utils, slop, pcmanfm and the 5 MB Symbols Nerd
  Font. NIRUBAR 0.18.3/0.18.4 shows useful default modules and borrows icon
  glyphs from the Nerd/Font Awesome font when the text font lacks them; the
  update probe stays opt-in. NIRUWM 0.16.18 removes the dead Flameshot key.
  Installed on the Arch ThinkPad and restarted the live bar; the workspace,
  volume, brightness, wifi, battery and clock icons are visible. A Debian-family
  Font Awesome fallback screenshot also showed the module icons. Void was
  updated with no live WM running; the new bar activates at next login.
- NIRUX **0.10.6** completes the audio provisioning: PipeWire, WirePlumber,
  `pipewire-pulse`, `pipewire-alsa`, ALSA UCM profiles and RTKit on Arch/Debian;
  Void gets PipeWire, WirePlumber, ALSA UCM and RTKit (Void has no separate
  pipewire-alsa package). Doctor now reports a missing default sink. On the Arch
  ThinkPad, RTKit is active, `pactl` reports PipeWire 1.6.9 with the ALC3232 sink,
  a real `pw-play` stream exited successfully, and doctor reports an audio default
  sink.
- NIRUX **0.10.7** pins nirunotify **0.3.0**, adding bounded action pairs,
  clickable action rows, default-action body clicks and `ActionInvoked`.
  `notify-send --wait -A default=Open` is exercised by the D-Bus/X11 smoke test.
  Installed on Void and the Arch ThinkPad while Dunst remains the default provider.
- **Media keys on the ThinkPad:** the live session was found locked by NIRULOCK,
  which correctly captures the keyboard and releases the WM grabs. In a fresh
  unlocked Xvfb session with the installed 0.16.18 WM, `XF86AudioMute`,
  `XF86AudioRaiseVolume` and `XF86AudioLowerVolume` toggled/changed the real
  PipeWire sink. No media-key regression was found; volume keys intentionally do
  nothing while the lock owns input. Lock-screen media volume remains a possible
  UX refinement, not a broken shortcut.
- NIRUX **0.10.8** pins niruwm **0.16.19**. `NOTIFICATION_PROVIDER` defaults to
  `auto`, which starts nirunotify when installed and falls back to Dunst. An
  isolated Void session with no provider override started nirunotify, owned the
  notification bus, delivered `notify-send` into native history and cleaned the
  daemon up on logout. Void is running 0.10.8; the ThinkPad was unreachable over
  Tailscale at deployment time, so its update and next-login acceptance remain
  pending.
- NIRUX **0.10.8** makes `auto` the notification provider default: native
  nirunotify when installed, Dunst fallback. An isolated Void session verified
  native bus ownership, notify-send history and logout cleanup. Void runs 0.10.8;
  the ThinkPad was offline in Tailscale and remains to be updated.
- NIRUX **0.10.9** pins nirubar **0.18.5** with ISO week numbers and Left/Right
  month navigation in the calendar (unit-tested state transition and fixed row
  width; the panel opens and survives navigation in an isolated bar). Void is
  running 0.10.9; the ThinkPad update remains pending while offline.
- NIRUX **0.10.10–0.10.12** ship a canonical `config.example.toml` as a checksummed
  release asset. Fresh installs receive it; existing configurations are merged
  by appending missing sections and keys without replacing user values. Void's
  older config kept its theme, browser, wallpaper and Stockholm coordinates and
  gained the missing nightlight/bar/wallpaper settings; the ThinkPad received the
  canonical file. Both validate with `niruwm/nirubar --check-config`.
- NIRUBAR **0.18.6** uses a music-note icon for the playing track instead of the
  drawn level bars. NIRUNOTIFY **0.3.2** re-reads the bar strut when a notification
  appears, so notifications keep a margin below a bar that mapped after the
  notifier started. Both were verified with isolated screenshots (note icon and
  a 12 px gap below the bar). Installed on Void and the ThinkPad; the ThinkPad bar
  was reloaded/restarted, while the running WM remains 0.16.17 until logout.
- **Next work:** R5 responsive layout/overflow, network actions, battery/media
  detail and combined weather/sun; R6 images/richer hints and physical
  native-provider acceptance; R2 appearance document/semantic tokens and GTK/Qt
  separation; physical sleep acceptance; R3 schedule/resume/bar controls; R7
  physical startx/rollback acceptance and cleanup. Launcher groups, window
  switching and input-method support remain. Standalone locker/saver
  ownership/PAM assets also remain. Preserve user configuration and NIRUPI.

Keep each next checkpoint small and publish only verified assets. Preserve the
existing lock regressions; never add password-derived logging or timed dismissal.
