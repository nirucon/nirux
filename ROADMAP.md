# NIRU desktop — current roadmap and restart handoff

Priority order updated **2026-10-21**. Published baseline: **NIRUX 0.10.64**.

## Start here — the active work queue

**N1–N4 are done. N5 is in progress.**
This is the owner's next feature queue. N1–N4 are implemented; N5's capture and
review surface are released, with notification actions and physical multi-output
verification still open.
Reuse existing components for N1–N4. Display profiles stay built
into NIRUX; a larger display repository is deferred. N5 plans a separate,
on-demand `nirushot` tool.

| Order / ID | Status | Deliverable |
|---|---|---|
| 1 / N1 | DONE in 0.10.57 | Microphone state, mute, input selection and level |
| 2 / N2 | DONE in 0.10.58 | Bluetooth state and controls for paired devices |
| 3 / N3 | DONE in 0.10.59 | Built-in display profiles with preview and automatic revert |
| 4 / N4 | DONE in 0.10.62 | Capability-aware power-profile selection |
| 5 / N5 | IN PROGRESS — capture and review surface released; notification actions/physical verification pending | nirushot: capture, copy/save and small annotation workflow |

### N1 — Microphone module

- **First step:** inspect the existing `niructl audio sources` and mic-mute
  controls. Extend that path instead of adding a second audio implementation.
- Add an optional NIRUBAR `microphone` module showing muted, unmuted, no input
  or provider unavailable. Show the selected input and level in its panel.
- Provide explicit mute, input selection and level controls using the same
  CLI as the launcher. Reading a panel must never toggle mute.
- Keep the bar compact with a documented visibility setting. Recording-use
  indication is optional and only shown when confirmed by PipeWire; unmuted
  must never be labelled as actively recording.
- **Done when:** changing the default input or mute externally updates the
  module; controls and CLI agree; missing provider/device is explained; theme
  colours, keyboard access and large-font layout work.
- **Main repositories:** nirubar, niruwm/niructl, nirulauncher, nirux.

### N2 — Bluetooth module

- **First step:** inspect BlueZ adapter/device properties and the dependency
  and service mappings on Arch, Debian and Void.
- Add an optional NIRUBAR `bluetooth` module: unavailable, blocked/off, on,
  connected. Hide by default when no adapter exists.
- Panel: paired devices, connection state and battery percentage only when
  the device reports it. Provide power on/off and connect/disconnect actions
  for paired devices through one shared CLI path.
- Use BlueZ signals or bounded cached queries. Pairing can open an existing
  manager/agent on demand; include its dependencies when offered.
- **Done when:** external state changes, missing BlueZ/adapter, rfkill,
  connection failure and unknown battery are handled honestly. Opening the
  panel performs no connection or pairing action. No new resident NIRU daemon.
- **Main repositories:** nirubar, niruwm/niructl, nirulauncher, nirux.

### N3 — Display profiles, built in

- **First step:** inspect current RandR/hotplug handling and define a small
  profile format for outputs, modes, positions, rotation and primary output.
- Implement list/save/preview/keep/revert in niructl, applied through the WM's
  existing output handling. Add launcher selection and access from the bar's
  display panel. Ship opt-in examples: Laptop, Desk and Presentation.
- Preserve a known-good layout before preview. Require an explicit Keep;
  automatically revert after a short countdown if it is not confirmed.
- Validate connected output identities and supported modes before applying.
  Unplugging a display or a failed apply must leave a usable internal/remaining
  display and reachable windows. Hotplug may suggest a profile; first version
  does not silently apply one.
- **Done when:** valid profiles apply, invalid/unavailable profiles explain
  why, timeout and cancellation restore the layout, and WM/bar/workspaces and
  night light recover after output changes.
- **Main repositories:** niruwm/niructl, nirubar, nirulauncher, nirux.
  **No nirudisplay repository in this queue.**

### N4 — Power-profile module

- **First step:** detect available provider capabilities on all three distros;
  define one CLI adapter for status/list/set and provider errors.
- Add an optional NIRUBAR `powerprofile` module and launcher actions for
  Power saver, Balanced and Performance, exposing only profiles the provider
  actually supports. Show AC/battery context and reported restrictions.
- Use an existing provider such as power-profiles-daemon or a compatible
  alternative. Do not run competing policy services or write guessed CPU/sysfs
  settings when no provider exists. NIRUX provisions the selected provider and
  service when the feature is enabled.
- **Done when:** profile changes are confirmed, external changes update the
  UI, unsupported/denied/held profiles are explained, and no-provider machines
  keep a clean bar. No automatic battery-based switching in the first version.
- **Main repositories:** nirubar, niruwm/niructl, nirulauncher, nirux.

### N5 — nirushot

- **First step:** inspect existing maim/slop/clipboard shortcuts and define the
  CLI, capture backend and minimal native review UI before creating the repo.
  The contract is now recorded in [NIRUSHOT.md](docs/NIRUSHOT.md).
- **First delivery:** region, selected window and full-screen capture; save to
  a chosen file or copy the image; delayed capture; Escape/cancel; notification
  actions for Open, Copy and Show in folder. Keep the existing screenshot
  shortcut as fallback until the released tool is integrated.
- **Second delivery, same point:** an on-demand review surface with crop,
  simple rectangle/arrow annotation and opaque masking. Save an edited copy
  without silently overwriting the original. Use NIRU theme/type/spacing.
- Reuse working X11 capture and clipboard tools where suitable. No upload,
  screen recorder, mandatory clipboard manager or background screenshot service.
- **Done when:** capture/cancel/save/copy and notification actions work across
  multi-output geometry, saved files have the expected content, editing/masking
  produces the exported result, and failure leaves no grabs or stray helpers.
  Then publish checksummed assets and integrate manifest, dependencies,
  shortcuts, diagnostics, rollback and owned uninstall in NIRUX.
- **Main repositories:** new nirushot (created during N5), nirux, niruwm,
  nirulauncher, nirunotify.

### Working rule for N1–N5

Finish one point before starting the next. Each point needs implementation,
configuration/example, concise docs, appropriate automated checks and a recorded
result. Release and deploy verified runtime changes to ThinkPad and Void,
preserving the separate NIRUPI setup. Keep owner-present hardware checks on an
explicit deferred list when the owner is unavailable; do not mark them passed.
Update the current ID, status and next concrete step in this file and the
next-session prompt together.

## Previous queue — P1–P6 and deferred acceptance

P1–P6 are recorded as implemented, with verification limits below. P2 remains
partial. The owner's deferred hardware/test work is retained and does not
replace the new N1–N5 feature order.

| Order / ID | Status | Deliverable |
|---|---|---|
| 1 / P1 | DONE in 0.10.46 | Reliable notification stacking and one working native DND path |
| 2 / P2 | PARTIAL — owner-present tests open | Real power, login, suspend/resume and display acceptance |
| 3 / P3 | IMPLEMENTED — owner deferred greeter/lock pixel and hotplug tests | Consistent typography, spacing, scaling and controls across the suite |
| 4 / P4 | IMPLEMENTED — owner deferred edge-case tests | Reliable workspace autostart for slow applications |
| 5 / P5 | IMPLEMENTED — verification deferred | “Why is this unavailable?” diagnostics in the launcher |
| 6 / P6 | IMPLEMENTED — verification deferred | Work modes and reusable workspace recipes |

### P1 — Notifications and DND

- **First step:** reproduce a notification falling below a terminal, and trace
  `niructl dnd` with NIRUNOTIFY as the active provider. It currently uses
  `dunstctl` even though the native notifier has its own DND interface.
- Fix stacking above ordinary windows without taking focus; define behaviour
  for fullscreen and retain lock-screen privacy.
- Route launcher, keyboard and bar DND controls to the active provider. Keep
  Dunst fallback and show the same state everywhere.
- Include closely related popup polish: font-aware wrapping/height, theme
  accents, readable secondary text, dismissal and bounded repeated messages.
- **Done when:** real X11/D-Bus tests cover a terminal raised after a popup,
  fullscreen, lock/unlock, native/Dunst DND and expiry. The reported hidden
  notification is reproduced and fixed.
- **Main repositories:** nirunotify, niruwm/niructl, nirubar, nirulauncher.

### P2 — Real desktop acceptance

- **First step:** turn the remaining H01 gaps into a recorded test matrix.
- Verify launcher power commands, local Polkit authorisation, SDDM and LightDM
  login, startx, lock/unlock, physical audio, suspend/resume and external screens.
- Complete fresh Void acceptance and retain the Debian/Arch VM evidence.
  Fold relevant session cleanup, night-light reapply and resource checks into
  these runs; fix failures in this point rather than opening a parallel queue.
- **Done when:** each path has its environment and actual result recorded.
  Isolated tests cover command/permission failures; physical checks cover the
  hardware paths. Unavailable hardware is explicitly blocked, never marked
  passed based on a running process or green release workflow.
- **Main repositories:** nirux, niruwm, nirulock, niruscreensaver; other
  components only where a reproduced failure requires them.

### P3 — One visual language

- **First step:** define a small shared scale for typography, spacing, focus
  and semantic colours, then compare the existing components against it.
  The scale is now recorded in [STYLE.md](docs/STYLE.md).
- Apply it to launcher, bar panels, notifications and greeters. Preserve theme
  identity, custom overrides and an opaque lock background.
- Make large fonts, small screens and mixed-width outputs work with measured
  text, bounded geometry, correct hitboxes and accessible overflow.
- Group small control improvements here: audio output/mic selection and mute,
  clear display/battery/network states, and a configurable welcome notification
  (always, first login/after update, off). Reuse existing providers.
- **Done when:** all four themes and a custom theme have rendered-value and
  layout checks at small/laptop/desktop sizes. Invalid reload keeps the last
  working appearance, and controls report unavailable providers honestly.
- **Main repositories:** nirubar, nirulauncher, nirunotify, niruwm, nirux.

### P4 — Reliable workspace autostart

- **First step:** reproduce a slow application mapping its window after the
  autostart sequence has moved to the next workspace.
- Replace timing-only placement with bounded launch/window matching, with
  optional class/instance rules where needed. Handle single-instance apps.
- Detect user workspace changes reliably; do not steal their workspace back.
  Define saved-session precedence and prevent duplicate launches.
- **Done when:** slow, missing, single-instance and multiple-window apps are
  tested; windows reach the intended workspace without focus theft or an
  unbounded wait. Existing simple argv configuration stays supported.
- **Main repositories:** niruwm/niructl, nirux config and integration tests.

### P5 — Explain this state

- **First step:** expose structured, read-only results from existing
  `nirux doctor`/`niructl` checks for display in the launcher.
- Explain unavailable brightness, audio, browser, weather, notifications and
  sleep inhibitors. Show installed versus running versions and when a new
  session is required.
- Offer explicit relevant actions next to a short explanation. Opening a
  diagnostic must not change settings, request privilege or block on HTTP.
- **Done when:** injected missing-provider, permission and stale-state cases
  show a useful cause and next step; CLI and launcher agree. No new daemon.
- **Main repositories:** nirux, niruwm/niructl, nirulauncher, nirubar.

### P6 — Work modes and workspace recipes

- **First step:** define one small opt-in configuration and ownership model,
  reusing the reliable launch placement from P4 and diagnostics from P5.
- Add Focus and Presentation modes: timed DND/keep-awake, a visible countdown
  and an explicit stop action. Restore only values the mode still owns.
- Add launcher-invoked workspace recipes for app groups, target workspaces
  and layouts, such as Development or Music. Do not duplicate session restore.
- **Done when:** timeout, cancellation, manual overrides, repeated invocation
  and logout cleanup are tested. Recipes reuse P4 rather than another launch
  engine; no extra resident service or mandatory application is introduced.
- **Main repositories:** niructl, niruwm, nirulauncher, nirubar.

### Earlier queue acceptance rules

Take one point at a time: reproduce → implement → verify → document → release
and deploy when applicable. Record remaining limits and the next concrete
step. P2 remains open for the deferred owner-present work. These earlier
acceptance requirements still apply to changes touching those paths; the
active feature order is N1–N5 at the top of this file.

- **Start here after restarting OpenCode:** [NEXT-SESSION.md](docs/NEXT-SESSION.md)
- **Evidence and open defects:** [restart review](docs/REVIEW-2026-10-20-RESTART.md)
- **Repositories:** [inventory](docs/REPOSITORIES.md)
- **Previous work:** [delivery history through 0.10.30](docs/history/ROADMAP-0.10.30.md)
- **Current checkpoint evidence:** [0.10.64 nirushot review surface](docs/history/CHECKPOINT-0.10.64.md)
- **S04 runtime audit:** [package and normal-user results](docs/history/AUDIT-S04-0.10.35.md)
- **R01 performance baseline:** [idle and startup measurements](docs/history/AUDIT-R01-BASELINE.md)
- **H01 partial fresh-VM evidence:** [Debian/Arch VMs and gaps](docs/history/AUDIT-H01-PARTIAL.md)

## 1. Product contract

A small, coherent, keyboard-first X11 desktop on vanilla **Void glibc, Debian
and Arch Linux**, currently **x86_64/glibc**. Niru Noir by default; Nord, Satie,
Carl Larsson and custom themes. English UI/docs, ISO dates, 24-hour clock,
Monday-first calendar and ISO weeks.

NIRUX must provision everything needed for the suite on a clean supported OS:
X11/startx, session bus, fonts/cursors, terminal, audio, hardware helpers,
screenshots, launcher, notifications and PAM lock integration. Preserve an
existing display manager; offer startx by default when none exists, with SDDM
or LightDM optional. **Helium must be an explicit installer option**, with its
dependencies managed by NIRUX. Preserve existing browser/user configuration.

No NIRUPI dependency or modifications. No new mandatory daemon, framework,
account or repository when an existing component can provide the feature.
Networking, Git/bootstrap download tools, sudo access and OS/hardware-specific
drivers/firmware must be documented separately from suite provisioning.

## 2. Published baseline — availability is not acceptance

| Repository | Pinned release | Responsibility |
|---|---|---|
| nirux | 0.10.64 | Packages, generations, target-owned apply, managed Helium, wallpapers, kitty/fish |
| niruwm | 0.16.59 | WM, session, niructl, niruidle, theme wallpapers, terminal hook |
| nirubar | 0.18.26 | Per-output bar, tray, panels, weather |
| niruscreensaver | 0.8.3 | Unlocked idle surface |
| nirulock | 0.16.10 | PAM lock, input grabs and readiness |
| nirulauncher | 0.2.11 | Apps, actions, windows, local recency/favourites |
| nirunotify | 0.3.7 | Native notifications, actions, DND, history/OSD |
| nirushot | 0.2.0 | Capture and native review/crop/annotation helper |

All listed releases/assets were found on GitHub. Previous sessions reported
installation of 0.10.30 on `niru@void` and `niru@thinkpad` (Arch). Those hosts
now run NIRUX 0.10.46 / NIRUWM 0.16.43 / NIRUNOTIFY 0.3.7; the 0.10.46 deployment
check is recorded in the N5 checkpoint.

**S01, S02 and S03 are implemented; 0.10.33 added theme wallpapers.**
[Run 39420180581](https://github.com/nirucon/nirux/actions/runs/39420180581)
passes Arch, Debian Bookworm and Void glibc, including real pinned releases,
doctor, config contract, startx and a normal-user Helium launch with the
Chromium sandbox enabled. The original failure
([run 39406911647](https://github.com/nirucon/nirux/actions/runs/39406911647))
stopped at `doctor` because the canonical `brave` browser was not installed;
config-contract and startx were never reached in that run.

Helium is pinned to upstream 0.19.4.1 with a recorded SHA-256. The canonical
browser is now `helium`, a fresh install selects it by default, and
`--browser none` is a persistent opt-out. Containers are supporting evidence,
not a fresh physical OS certification; H01 remains open; S04, S03 and W01/W02 are delivered.

The earlier I06–I09, U01–U06 and A01–A03 work is **shipped**, with useful
regressions. It is not blanket proof that every original acceptance criterion
passed. The follow-ups below supersede historical claims of full completion.

## 3. Previous delivery and hardware evidence — reference only

The table below preserves previous delivery evidence. Start new work from the
N1–N5 queue above, not from the order of these historical rows.

| ID / status | Exact next work | Acceptance |
|---|---|---|
| S01 / DONE | Reproduced the 0.10.30 failure: all three distros stopped at doctor with `missing configured brave`; config-contract/startx were not reached. Fixed by the S02 browser policy. Evidence: CI run 39420180581. | New full CI run passes Arch, Debian Bookworm and Void glibc; complete logs retained. |
| S02 / DONE | Managed Helium 0.19.4.1 with recorded SHA-256, runtime dependencies, owned desktop entry, persistent `--browser helium|none|keep` policy, actionable status/doctor and owned removal. Evidence: run 39420180581 and [checkpoint](docs/history/CHECKPOINT-0.10.32.md). | Helium selected: empty-home browser install launches as a normal user with sandbox enabled. Opt-out survives updates. Corrupt download, update, rollback and owned uninstall covered by regressions. No `--no-sandbox` path. |
| W07 / DONE (owner request) | Fix shutdown in Super+Shift+P and make local power actions work without sudo; add themed SDDM/LightDM greeters with the Rooted in Less wallpaper and a session welcome. | `loginctl`/`systemctl` use the real `poweroff` verb; a NIRUX polkit rule allows local active wheel/sudo users to power off, reboot and suspend while remote sessions still authenticate normally. SDDM and LightDM GTK get NIRU Noir themes and the Rooted in Less background; every NIRU session shows a themed welcome notification, including startx with a custom xinitrc. Evidence: 0.10.44/0.10.45 checkpoint. |
| W06 / DONE (owner request) | Make native notification popups and OSD follow the active NIRUWM theme, including live changes. | Palette comes from the current theme and shared appearance; `niructl theme`/`niructl reload` restyles existing popups without restarting the notifier; custom themes get a derived surface colour; urgency strips use the theme accent, muted and error colours. Evidence: 0.10.42/0.10.43 checkpoint. |
| W05 / DONE (owner request) | Add dwm-style Super+mouse move/resize and workspace-ordered autostart from the shared config. | All four resize corners, floating/tiling toggle, ordered workspace launch, settle, safe return to workspace 1, no duplicate with restore/NIRUPI, clear English config documentation. Evidence: 0.10.41 checkpoint. |
| W04 / DONE (owner request) | Add wallpaper choices and settings to the unified launcher, including the three extra NIRUX wallpapers. | Super+Shift+P lists theme and extra wallpapers; selecting one applies it with `mode=single`; mode, rotation, scale and follow-theme are visible and cyclable. Evidence: 0.10.41 checkpoint. |
| W03 / DONE (owner request) | Fix bar theme identity and make Reboot/Shutdown work from the launcher. | Appearance example no longer overrides built-in themes; old Noir-only file is migrated without touching custom colours. Polkit agent is provisioned/started and failed power actions are visible. Evidence: 0.10.41 checkpoint. |
| W02 / DONE (owner request) | Install a NIRU kitty/fish setup with a fast fish prompt, history, autosuggestions, completions and theme-following terminal colours. | Kitty always uses fish; existing configs are updated with one reversible managed block; theme changes update kitty/fish through a small NIRUWM hook; all built-in palettes meet the contrast test. Evidence: 0.10.41 checkpoint. |
| W01 / DONE (owner request) | Install the four theme wallpaper sets into `~/Pictures/Wallpapers/NIRU`; add `follow_theme`/`theme_dir`; make a theme change apply its default wallpaper without breaking custom files, rotation or `mode = "single"`. | New and existing installs receive the assets; modified user files are preserved; theme change replaces the root wallpaper only when enabled/following; owned purge removes only unmodified assets. Evidence: 0.10.33 checkpoint. |
| S03 / DONE | Target-owned apply protocol 2. The target runs browser install, config migration, wallpapers, PAM/system integration, startx/DM setup, activation and the restart message. `_handoff-version` stays 1 for old callers; `_apply-version` advertises 2. Evidence: [checkpoint](docs/history/CHECKPOINT-0.10.34.md). | One update to synthetic 99.4.0 links a new component, adds a new config key and installs a new wallpaper asset. An injected 99.4.1 failure restores the exact config and leaves the generation unchanged. |
| S04 / DONE | Rechecked the complete vanilla package/runtime matrix on Arch, Debian Bookworm and Void glibc. Release install as a normal user, status/doctor, startx, WM/bar, theme wallpaper, maim screenshot, font/cursor fallback, audio process start and Helium were exercised. Evidence: [S04 audit](docs/history/AUDIT-S04-0.10.35.md). | No manual suite package fixes; package versions and normal-user runtime recorded. Physical audio, PAM unlock and lock/suspend remain H01. |
| H01 / PARTIAL — now part of P2 | Debian and Arch passed on fresh LXD VMs: empty-home 0.10.35 install, status/doctor, startx/WM/bar, wallpaper theme change, maim screenshot, Helium sandbox, PAM auth, update, rollback and purge. Evidence: [H01 partial audit](docs/history/AUDIT-H01-PARTIAL.md). Remaining: fresh Void VM/physical clean OS, physical audio, lock/unlock and suspend/output. | Debian/Arch VM acceptance done. H01 completes only when Void and physical hardware paths are recorded. Containers/Xvfb remain supporting evidence. |

**The active queue is N1–N5 at the top of this file.** H01 is included in P2;
optional notification images and repositories outside N5 remain later work.

### Three-distro acceptance sheet

| Path | Arch | Debian | Void glibc |
|---|---|---|---|
| Package provisioning | Passed in 39420180581 | Passed in 39420180581 | Passed in 39420180581 |
| Mock install/update/rollback | Passed in 39420180581 | Passed in 39420180581 | Passed in 39420180581 |
| Full real-release/startx CI | **Passed** | **Passed** | **Passed** |
| One-update target apply | **Passed in synthetic regression** | **Passed in synthetic regression** | **Passed in synthetic regression** |
| S04 normal-user runtime | **Passed in container** | **Passed in container** | **Passed in container** |
| Managed Helium option + normal-user sandbox | **Passed in container** | **Passed in container** | **Passed in container** |
| Fresh normal-user OS desktop acceptance | **VM passed**; physical audio/lock open | **VM passed**; physical open | **Open** (fresh VM/physical clean OS needed) |
| Physical sleep/output checks | Owner previously confirmed | No physical host supplied | Owner previously confirmed |

## 4. Correctness and integration follow-ups

These are detailed requirements, not a second priority list. Apply C01/C06 in
P3, C02/C07 and hardware/resource verification in P2, notification lifecycle in
P1, and relevant input/provider checks wherever P1–P6 touch them. Unrelated
remaining C03–C05 work stays in the backlog after P6. Legacy priority labels do
not override the active N1–N5 queue.

| ID / priority | Repositories and work | Done when |
|---|---|---|
| C01 / P1 | Appearance: common validation, theme precedence, neutral defaults, explicit per-component overrides, font/spacing/focus/reduced-motion semantics. The shipped Noir-only example was fixed in 0.10.41; remaining work is live last-good state and rendered-value assertions. | Four themes and custom theme retain their identity; actual rendered colours/geometry and black lock opacity are asserted. Live invalid reload preserves the previous applied state. Checks must assert values, not just six exit codes. |
| C02 / P1 | Night light: manual/off/status must not need coordinates; fixed scheduling must work offline without a location. Reapply unchanged Kelvin after resume/RandR. One watcher per X session with manual override ownership and bounded helper timeouts. | No-coordinate manual/off/fixed tests; two invocations cannot compete; resume/output changes trigger an actual gamma call even when the saved temperature is unchanged. Include polar/0,0/timezone and permission evidence. |
| C03 / P1 | Launcher/lock keyboard input: real Swedish/US/AltGr/Caps mapping, MappingNotify, Unicode and compose review. Favourites/groups/window-focus semantics and local-state writes. | Real X key sequences produce intended search/password characters. Dead-key/IME limitations remain explicit until implemented. Preserve desktop-file precedence, Hidden masks and argv-only Exec launch. |
| C04 / P1 | Battery/network honesty: complete-pack rate accounting, coherent units, Full vs Not charging, IPv6 reject/default route filtering, selected-interface/address association. | Mixed energy/charge and partial-rate fixtures cannot produce a false estimate; no IP/default route is never described as proven Internet connectivity. No mandatory NetworkManager or online ping service. |
| C05 / P1 | Weather: missing probability/temperature stays unavailable; timezone-aware forecast indexing, explicit wind units, current-day/polar daylight, age-based stale label. | Unknown is not 0%; stale-day sunrise is not today's event; forecast location time is handled correctly. No synchronous HTTP, no second fetch daemon. |
| C06 / P2 | Responsive bar and controls: sparse indices, large fonts/titles/tray, small widths, input buttons, overflow access and configuration. Output selection and genuine panel controls still need a design beyond mouse shortcuts. | 800/1366/1920 and mixed-width outputs have pixel/hitbox/popup tests. Reading is side-effect free. Provider absence is visible; helper processes and their descendants have deadlines and bounded concurrency. |
| C07 / P1 | Suite lifecycle/ownership: precise logout cleanup, live reload, stale singleton/lock state, unmanaged-file protection, failed activation and rollback of added/removed components. | Isolated X11/D-Bus tests and failure injection retain user data and leave no competing notifier, idle ladder, night-light watcher or leaked grabs/processes. No testing in production PAM. |
| R01 / BASELINE — owner request | Performance and resource budget: idle CPU/PSS/process counts per component, login/startx latency, bar redraw and helper lifetimes, no unnecessary resident browser/notification processes. Baseline: [R01 audit](docs/history/AUDIT-R01-BASELINE.md). | Baseline and explicit budgets recorded on all three distros. Remaining: physical H01 repeat, automated regression and stale-session-bus cleanup (C07). Optimize measured hot paths only. |
| A04 / TODO — later | Optional bounded notification images/hints in nirunotify. | Cap dimensions/decoded bytes/queue/history; advertise only implemented capabilities. Retain D-Bus actions, lock privacy, DND and cleanup regressions. |

H02 installer/PAM and H03 sleep/output checks have previous automated and
owner-confirmed evidence. Keep those regressions; rerun affected paths after
runtime changes. Existing hosts are never clean-OS proof and active sessions
must not be forcibly logged out for testing.

## 5. Later ideas — after the active queue

Explain this state is now P5; Focus/Presentation modes and workspace recipes
are P6. The remaining ideas below are not prerequisites for starting N1–N5:

1. **Desktop lens** — local queries for `window`, `workspace`, `audio`, `battery`,
   `display`, `weather`; show cached facts with explicit existing actions.
2. **Advanced docking automation** — beyond N3's built-in manual display
   profiles: workspace affinity, bar density and optional automatic matching.
   Reuse N3 preview/revert and hardware evidence before expanding it.
3. **First-login self-check** — on-demand completion screen in the launcher:
   audio/browser/font/backlight shortcuts and why something is unavailable.
   No resident onboarding process and no telemetry.
4. **Appearance export** — optional palette export to already-owned nplay/cmus/
   terminal themes, with preview and modified-file preservation after C01.

Every feature is opt-in where appropriate and records idle CPU/RSS/process count,
helper/network activity, a failure regression and all three distro mappings.

## 6. Related repositories and the no-bloat boundary

There is **no demonstrated need for another mandatory core repository**.
Use nirulauncher/niructl/nirubar before introducing another control-centre app.
Use nplay/MPRIS for media/radio rather than requiring QuickShell. See the
[repository inventory](docs/REPOSITORIES.md) for optional applications and limits.

| Queue | Optional work | Gate |
|---|---|---|
| P01 | nirunote/niruorg | Void Python/PySide6 mappings, clean install/startup/upgrade/removal on all three systems. |
| P02 | nirupres/niruflow | Qt/multimedia/WebEngine/venv packaging evidence; reconcile actual versions and READMEs. |
| P03 | nplay/nirulize | MPRIS/PipeWire monitor capture and session-bus integration; no machine-specific paths. |
| P04 | nirupresence | Explicit opt-in session lifetime, one instance, clean logout, no NIRUPI edits. |
| P05 | QuickShell radio/presence adapters | Optional external-desktop adapters only; never default core dependencies. |
| P06 | nplay/cmus/REAPER themes | Declarative validation, preserve edits, optional appearance export after C01. |
| P07 | DAW and REAPER compatibility | Test REAPER on all three distros with ALSA and PipeWire JACK, correct window classes/floating rules for plugin/dialog windows, realtime permissions and documented plugin limitations. Optional app only; no mandatory DAW package or Wine/yabridge layer. |

**Repository scope:** N3 display profiles remain in niructl/WM/bar/launcher.
The larger `nirudisplay` repository idea is deferred. N5 plans `nirushot` as an
independent, on-demand capture/review tool; it has not been created by this
roadmap update.

## 7. Working/release rules and restart

- Read the [restart prompt](docs/NEXT-SESSION.md) and review before changing code.
- Inspect `git status`, fetch, compare local/main and preserve unfamiliar work.
- Prefer persistent clones under `~/.cache/niru-work/`; `/tmp/opencode` was cleared
  during previous work. GitHub main and the published manifest are authoritative.
- The owner requests commit/push/publication after each **verified completed**
  checkpoint and installation on Void/Arch when there is a deployable change.
  Documentation-only updates are pushed; they do not need artificial binary tags.
- Immutable releases: never move an existing published tag or replace its assets.
  A release workflow passing is not equivalent to the full distro CI passing.
- Keep concise READMEs, current task IDs, commands/evidence and remaining limits.
  Archive useful history instead of deleting it. Never store credentials.
- Tests: `sh tests/integration.sh`, `shellcheck -S warning nirux tests/*.sh`,
  relevant Rust fmt/clippy/tests and real X11/D-Bus regressions. Run the actual
  released-asset smoke and full distro CI before claiming install acceptance.
- Deployment: inspect versions/config/status/doctor before and after; preserve
  configuration and rollback. Ask for SSH/sudo credentials if needed.

Restart shorthand:

> Read https://raw.githubusercontent.com/nirucon/nirux/main/docs/NEXT-SESSION.md
> and continue with its first task. Follow the linked current roadmap and review.
