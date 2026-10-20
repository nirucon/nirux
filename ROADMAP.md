# NIRU desktop — current roadmap and restart handoff

Updated **2026-10-20**, checked against **NIRUX 0.10.43**.

- **Start here after restarting OpenCode:** [NEXT-SESSION.md](docs/NEXT-SESSION.md)
- **Evidence and open defects:** [restart review](docs/REVIEW-2026-10-20-RESTART.md)
- **Repositories:** [inventory](docs/REPOSITORIES.md)
- **Previous work:** [delivery history through 0.10.30](docs/history/ROADMAP-0.10.30.md)
- **Current checkpoint evidence:** [0.10.43 live notification theme](docs/history/CHECKPOINT-0.10.42.md)
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
| nirux | 0.10.43 | Packages, generations, target-owned apply, managed Helium, wallpapers, kitty/fish |
| niruwm | 0.16.40 | WM, session, niructl, niruidle, theme wallpapers, terminal hook |
| nirubar | 0.18.18 | Per-output bar, tray, panels, weather |
| niruscreensaver | 0.8.3 | Unlocked idle surface |
| nirulock | 0.16.10 | PAM lock, input grabs and readiness |
| nirulauncher | 0.2.3 | Apps, actions, windows, local recency/favourites |
| nirunotify | 0.3.5 | Native notifications, actions, DND, history/OSD |

All listed releases/assets were found on GitHub. Previous sessions reported
installation of 0.10.30 on `niru@void` and `niru@thinkpad` (Arch); those hosts
still need the 0.10.43 deployment check.

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

## 3. Immediate queue — installation before new features

Work one ID at a time; record reproduction, paths, revisions, commands/results,
environment, release/deployment status, remaining limits and next task.

| ID / status | Exact next work | Acceptance |
|---|---|---|
| S01 / DONE | Reproduced the 0.10.30 failure: all three distros stopped at doctor with `missing configured brave`; config-contract/startx were not reached. Fixed by the S02 browser policy. Evidence: CI run 39420180581. | New full CI run passes Arch, Debian Bookworm and Void glibc; complete logs retained. |
| S02 / DONE | Managed Helium 0.19.4.1 with recorded SHA-256, runtime dependencies, owned desktop entry, persistent `--browser helium|none|keep` policy, actionable status/doctor and owned removal. Evidence: run 39420180581 and [checkpoint](docs/history/CHECKPOINT-0.10.32.md). | Helium selected: empty-home browser install launches as a normal user with sandbox enabled. Opt-out survives updates. Corrupt download, update, rollback and owned uninstall covered by regressions. No `--no-sandbox` path. |
| W06 / DONE (owner request) | Make native notification popups and OSD follow the active NIRUWM theme, including live changes. | Palette comes from the current theme and shared appearance; `niructl theme`/`niructl reload` restyles existing popups without restarting the notifier; custom themes get a derived surface colour. Evidence: 0.10.43 checkpoint. |
| W05 / DONE (owner request) | Add dwm-style Super+mouse move/resize and workspace-ordered autostart from the shared config. | All four resize corners, floating/tiling toggle, ordered workspace launch, settle, safe return to workspace 1, no duplicate with restore/NIRUPI, clear English config documentation. Evidence: 0.10.41 checkpoint. |
| W04 / DONE (owner request) | Add wallpaper choices and settings to the unified launcher, including the three extra NIRUX wallpapers. | Super+Shift+P lists theme and extra wallpapers; selecting one applies it with `mode=single`; mode, rotation, scale and follow-theme are visible and cyclable. Evidence: 0.10.41 checkpoint. |
| W03 / DONE (owner request) | Fix bar theme identity and make Reboot/Shutdown work from the launcher. | Appearance example no longer overrides built-in themes; old Noir-only file is migrated without touching custom colours. Polkit agent is provisioned/started and failed power actions are visible. Evidence: 0.10.41 checkpoint. |
| W02 / DONE (owner request) | Install a NIRU kitty/fish setup with a fast fish prompt, history, autosuggestions, completions and theme-following terminal colours. | Kitty always uses fish; existing configs are updated with one reversible managed block; theme changes update kitty/fish through a small NIRUWM hook; all built-in palettes meet the contrast test. Evidence: 0.10.41 checkpoint. |
| W01 / DONE (owner request) | Install the four theme wallpaper sets into `~/Pictures/Wallpapers/NIRU`; add `follow_theme`/`theme_dir`; make a theme change apply its default wallpaper without breaking custom files, rotation or `mode = "single"`. | New and existing installs receive the assets; modified user files are preserved; theme change replaces the root wallpaper only when enabled/following; owned purge removes only unmodified assets. Evidence: 0.10.33 checkpoint. |
| S03 / DONE | Target-owned apply protocol 2. The target runs browser install, config migration, wallpapers, PAM/system integration, startx/DM setup, activation and the restart message. `_handoff-version` stays 1 for old callers; `_apply-version` advertises 2. Evidence: [checkpoint](docs/history/CHECKPOINT-0.10.34.md). | One update to synthetic 99.4.0 links a new component, adds a new config key and installs a new wallpaper asset. An injected 99.4.1 failure restores the exact config and leaves the generation unchanged. |
| S04 / DONE | Rechecked the complete vanilla package/runtime matrix on Arch, Debian Bookworm and Void glibc. Release install as a normal user, status/doctor, startx, WM/bar, theme wallpaper, maim screenshot, font/cursor fallback, audio process start and Helium were exercised. Evidence: [S04 audit](docs/history/AUDIT-S04-0.10.35.md). | No manual suite package fixes; package versions and normal-user runtime recorded. Physical audio, PAM unlock and lock/suspend remain H01. |
| H01 / PARTIAL — **START HERE** | Debian and Arch passed on fresh LXD VMs: empty-home 0.10.35 install, status/doctor, startx/WM/bar, wallpaper theme change, maim screenshot, Helium sandbox, PAM auth, update, rollback and purge. Evidence: [H01 partial audit](docs/history/AUDIT-H01-PARTIAL.md). Remaining: fresh Void VM/physical clean OS, physical audio, lock/unlock and suspend/output. | Debian/Arch VM acceptance done. H01 completes only when Void and physical hardware paths are recorded. Containers/Xvfb remain supporting evidence. |

**Next session starts with H01, not A04.** Finish the one-update and vanilla
acceptance path before optional notification images or new repositories.

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

## 5. Useful innovations, implemented in existing components first

Order these after S01–S04 and the relevant correctness gate:

1. **Explain this state** — launcher actions for missing backlight permissions,
   audio sink/mic, browser, stale weather, notification ownership and inhibitors.
   Reuse `nirux doctor`/`niructl`; one coherent diagnostic, no service.
2. **Desktop lens** — local queries for `window`, `workspace`, `audio`, `battery`,
   `display`, `weather`; show cached facts with explicit existing actions.
3. **Focus session** — bounded timed DND + keep-awake, one visible countdown,
   restore only settings the user has not changed. Manual lock/suspend independent.
4. **Docking profiles** — output identity, workspace affinity, bar density and
   night-light reapply, with preview and timed revert. Hardware acceptance first.
5. **First-login self-check** — on-demand completion screen in the launcher:
   audio/browser/font/backlight shortcuts and why something is unavailable.
   No resident onboarding process and no telemetry.
6. **Appearance export** — optional palette export to already-owned nplay/cmus/
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

**Conditional new repo idea: `nirudisplay`**, an optional native display-profile
editor, only if docking-profile work proves independently reusable. Start with
niructl/WM RandR support and preview/revert; no daemon, mandatory compositor,
network service or replacement session manager. It is a proposal, not an
approved dependency or a repository that already exists.

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
