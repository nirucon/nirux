# NIRU desktop roadmap

Personal X11 desktop for the author's own machines; others are welcome to try it.
This is the authoritative implementation and handoff document. Component READMEs
link here instead of duplicating the plan. Checked items require verification,
not just source changes. Do not release placeholder binaries.

## Agreed direction

- Small independent native Rust/X11 programs, consistent NIRU styling, no large
  desktop framework. Settings belong in XDG-respecting TOML files.
- `nirulauncher`: separate repository; Super+P opens applications, Super+Shift+P
  opens applications plus desktop actions. Center on the active monitor, clamp
  to its usable area. Keyboard-first; configurable dimensions, fonts, colours,
  matching, terminal and actions. Never execute desktop-file Exec through a shell.
- `nirunotify`: separate repository; native replacement for Dunst implementing
  org.freedesktop.Notifications. Only one service owns the bus name. Do not
  disable Dunst until the replacement passes its protocol and session tests.
- Weather: Open-Meteo, configurable Ljungskile default, Celsius/metric, background
  refresh approximately every 30 minutes. Cached/stale/offline states are explicit.
- Visible bar modules have useful information panels. Reading information must
  not silently change volume or playback. Keep actions explicit and configurable.

## Rules for any implementing agent

1. Read this document, repository instructions, status and current code first.
   Preserve local user changes. Treat findings below as a starting point, not a
   substitute for checking the current revision.
2. Implement a small task and its acceptance checks before starting another.
   No fabricated performance numbers or claims of physical hardware testing.
3. Keep normal rendering free of networking, package checks and blocking probes.
   Bound worker counts, subprocess durations, queues, caches and untrusted input.
4. Never add automatic unauthenticated lock dismissal, password/keycode logging,
   or a timeout wrapper which kills a working locker. X11 cannot defend against
   a hostile client or an administrator killing the locker; do not claim otherwise.
5. Configuration additions shared by WM and bar require agreement tests in both
   repositories. New programs use their own config file; avoid schema coupling.
6. Before release: fmt, clippy, unit/integration checks appropriate to the change;
   exercise Arch, Debian and Void glibc. Keep x86_64/glibc limits explicit.
7. Push reviewed commits, publish immutable version tags and checksummed assets,
   then update nirux's pinned manifest only after every referenced asset exists.
8. Before a context/session limit: stop starting features, finish a safe tested
   checkpoint, publish only completed work, and update the handoff below. Never
   force a live desktop logout merely to activate an upgrade.

## M0 — audit and measurement

- [x] Read current WM, bar, screensaver, locker and nirux integration.
- [x] Identify the first confirmed failures (see findings below).
- [x] Record reproducible before/after measurements in MEASUREMENTS.md.

Confirmed at audit start:

| ID | Repository / location | Finding | Priority |
|---|---|---|---|
| L1 | nirulock `main.rs::run` | Default 5-minute setting is multiplied by 10 seconds: lock disappears after about 50 seconds without authentication; environment override can dismiss sooner. | P0 |
| L2 | nirulock `handle_key` / `trace` | Raw keycode and modifier logs can disclose password input. | P0 |
| L3 | nirulock `grab_input`, `submit` | Grab replies are ignored; wrong-password flow releases/reacquires the keyboard. Needs continuous verified grabs and an input-isolation test. | P0 |
| L4 | nirulock `pam.rs` | Shared password is assigned before the authentication mutex, allowing concurrent attempts to interfere. | P1 |
| L5 | nirulock `Surface::new` / `Lock::new` | Password surface becomes visible before the keyboard grab is verified; failed startup looks like a ready lock. | P0 |
| W1 | niruwm `niruidle.rs` | Child handles are dropped, external kill/timeout helpers used, and fallback blank sentinel can reach kill(0). Locker activity resets a boolean without tracking the actual child. | P0 |
| B1 | nirubar `run`, `frame_key`, `av` | Unconditional 100ms timer plus animation loop repeatedly probes external tools; redraw-key comparison excludes playback progress. | P1 |
| B2 | nirubar `module.rs` | Volume/media clicks perform actions before opening information; external probes can block the UI. | P1 |
| S1 | niruscreensaver `draw` | Reopens fonts and reruns font discovery on every draw; one-second wakeups despite minute-only clock. | P1 |
| X1 | saver/locker `Surface` | Root geometry and combined-screen centering require RandR resize/hotplug and per-monitor tests. | P1 |

Measurement method: isolated Xvfb, fixed geometry/font/config; record program and
tool versions, elapsed time, RSS, thread count, CPU ticks and probe counts. Compare
the same workload before/after. Include idle, media scrolling, popup open and lock
failure. Initial objectives: bar external media/volume probes <=1 sample/second
each; no unconditional animation timer; screensaver fonts loaded once/run;
no child zombies after repeated idle cycles. Set further numerical budgets only
after measurements. CPU results in containers are not physical-laptop guarantees.

## M1 — correctness and idle efficiency (first implementation checkpoint)

Dependencies: M0 findings. Repositories: all four components, then nirux.

- [x] L1/L2: no timer/environment bypass; retain old timeout config as deprecated,
      ignored compatibility input. Remove keycode logging. Explain migration.
- [x] L3/L4/L5: verify input grabs before showing the password surface, retain them on refused authentication, serialize
      password lifetime. Test wrong password, Escape, correct password and input
      isolation. Only authenticated success exits normally.
- [x] W1: owned Child handles, reap saver and locker, never timeout a locker,
      explicit blanking state (never pid 0), bounded retry after failed startup.
- [x] B1: remove always-running timer/X connection; separate probe cadence from
      animation cadence; include progress changes in invalidation.
- [x] S1: persistent renderers and host cache; deadline-driven visible updates.
- [ ] Regression tests, measured comparison, component releases, pinned nirux
      release. Do not force the user's running WM to restart.

Acceptance: a short legacy timeout and NIRULOCK_SAFE_SECONDS cannot unlock;
password traces contain no input; idle child lifecycle tests pass; scrolling
does not multiply probes; progress-only changes repaint; minute-boundary and
input-dismissal tests pass. Existing config remains readable.

## M2 — nirulauncher 0.1 and WM integration

Dependencies: M1. New repo: `nirucon/nirulauncher`.

- [ ] Document independent config and command interfaces; native window with
      proper WM_CLASS, focus, singleton behaviour, Escape and outside dismissal.
- [ ] Resolve active monitor from NIRUWM/EWMH + pointer/RandR fallback; center
      within work area; test negative coordinates, small screens and two monitors.
- [ ] Parse XDG application directories and precedence, Hidden/NoDisplay,
      OnlyShowIn/NotShowIn, TryExec, Terminal, quoted Exec and supported field
      codes. Reject malformed commands; use argv-based spawning, not shell.
- [ ] Search, arrows, Enter, scrolling, accessible contrast and readable empty
      states. Index once on open; no daemon/poll loop while closed.
- [ ] Action mode: lock, screensaver, reload, workspace navigation and theme
      selection. Logout/reboot/shutdown require explicit confirmation; arbitrary
      user actions are argv arrays in config.
- [ ] Add configurable WM defaults for Super+P / Super+Shift+P, retaining a useful
      fallback when launcher is unavailable. Preserve user key overrides.
- [ ] Test actual key presses, monitor placement, desktop-entry execution and
      cleanup. Publish native binary + SHA256SUMS, then extend nirux's manifest,
      stage/verify/status/doctor/rollback/uninstall and offline fixtures together.

## M3 — bar information and cached weather

Dependencies: M1 background-probe infrastructure; coordinate schema with WM.

- [ ] Move all slow probes to bounded workers; cap command time/output, preserve
      cached state on failures, never spawn unbounded threads or children.
- [ ] Audit every module click: clock/calendar, network, battery, volume, media,
      updates, pulse, uptime, sun, weather. Left click = information by default;
      configurable secondary actions. Hidden modules cannot steal hitboxes.
- [ ] Weather config in bar's own independent TOML (avoid shared-parser drift):
      location name/lat/lon, units, refresh/backoff, request deadline and cache age.
- [ ] Open-Meteo background client: TLS verification, bounded JSON/body/cache,
      atomic writes, no API key. Details include apparent temperature, rain,
      wind, forecast and last successful update. Failed requests never block X.
- [ ] Test with recorded fixtures, offline startup, corrupt cache, stale state,
      provider errors and cancellation; ordinary CI must not depend on live weather.
- [ ] Multi-monitor workspace occupancy/selection audit: current bar assumes nine
      global workspaces; verify actual WM per-monitor contracts before changing it.

## M4 — native nirunotify

Dependencies: M1; optionally reuse proven launcher drawing primitives without
introducing an unstable shared crate. New repo: `nirucon/nirunotify`.

- [ ] Implement standard bus ownership, GetCapabilities, GetServerInformation,
      Notify, CloseNotification, NotificationClosed and ActionInvoked.
- [ ] Handle replacement IDs, expire_timeout (-1/0/positive), urgency, app names,
      actions and hints. Do not advertise unsupported features. Cap strings,
      images, queued notifications and resident history; treat markup as data.
- [ ] Native styled windows on configurable active/primary/named monitor; stack
      within work area, explicit actions, DND, urgency policy and history command.
- [ ] Wait on D-Bus/X/deadlines rather than poll; no periodic work when empty.
- [ ] Session integration selects exactly one provider. Preserve Dunst fallback
      and do not replace a bus owner unexpectedly. Suppress notification content
      while locked; ensure all overlay windows stay below the locker.
- [ ] Protocol tests on a private D-Bus; Xvfb geometry/expiry/action/replacement
      tests; high-volume memory and queue tests; real notify-send integration.
- [ ] Publish binary/assets; update all nirux paths and tests as in M2. Add a
      session notification_provider setting with a backwards-compatible default.

## M5 — monitor/input resilience and refinements

- [ ] RandR hotplug/resize coverage, window and pixmap resizing, active-monitor
      clock placement and screen coverage in saver/locker. Never uncover root
      during a failed resize. Mixed DPI and non-Latin input need explicit tests.
- [ ] Audit lock map/stack loops for self-triggered ConfigureNotify storms.
- [ ] Suspend/resume: lock before sleep, clear stale input on resume, coordinate
      logind/elogind inhibitors without adding duplicate idle supervisors.
- [ ] Shared theme agreement tests and optional per-program overrides; strict,
      bounded config validation. Avoid duplicated TOML parser drift.
- [ ] Investigate event-driven MPRIS/PipeWire updates before further polling work.

## Optional ideas (not release commitments)

- Launcher context rows: current track, pending updates and workspace targets,
  sourced from cached local state rather than fresh blocking probes.
- A compact "desktop health" panel showing missing tools, last weather refresh
  and notification DND; export existing diagnostics rather than build a daemon.
- Screensaver quiet mode: minute clock on active monitor, dim secondary monitors,
  optional low-frequency position shift for burn-in avoidance.
- Notification history that is memory-only by default; optional bounded disk
  persistence with private permissions and explicit retention settings.

## Handoff / checkpoint

M1 implementation is complete; final suite release/CI validation is the last
unchecked gate above. Component checkpoints: niruwm 0.16.4 (`ea266f3`), nirubar
0.16.5 (`db42bf6`), niruscreensaver 0.8.0 (`d932519`), nirulock 0.16.5 (`dbaf437`).
The intermediate nirulock 0.16.4 was superseded after a new failing regression
demonstrated that its prompt could appear before input was acquired.

Local checks passed: fmt/clippy/unit tests for all four; real X tests for bar
singleton/progress-only redraw and lock timeout/input isolation/startup refusal;
non-root correct/wrong-password/Escape checks; actual WM shortcut isolation during
lock and restoration after authentication. Resource measurements are in
MEASUREMENTS.md. Physical GPU, hotplug and suspend/resume remain M5 work.

Repositories created: nirulauncher `6ce48e0`, nirunotify `441a91a`, each containing
README, MIT license and DESIGN.md. These are design checkpoints, NOT executable
releases. Nirux documents their status and deliberately does not download them.

Next implementation: M2 in nirulauncher. Start with Cargo/config validation and a
fixture-tested XDG desktop-entry index/Exec argv parser; then implement the native
centered window and its input/monitor tests. Release menu grabs before executing
a lock action. Do not start notification/weather implementation in the same
checkpoint. Wire launcher into WM/nirux only once its actual binary, CLI and tests
exist. Bounded asynchronous bar probes and click semantics remain M3, not M1.
