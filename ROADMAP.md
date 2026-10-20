# NIRU desktop — implementation roadmap

Updated **2026-10-20**. Audience: human maintainers, OpenCode and DeepSeek.
This file is the authoritative **current plan**. The
[previous roadmap](docs/history/ROADMAP-2026-10-19.md) preserves release history.
[Current review](docs/REVIEW-2026-10-20.md) records evidence and limits.
[Next-session prompt](docs/NEXT-SESSION.md) is the copy-ready continuation brief.

## 1. Product contract

- A small, coherent, keyboard-first X11 desktop on vanilla **Void glibc, Debian
  and Arch Linux**. Current release target: **x86_64/glibc**.
- Core: niruwm/session/niructl/niruidle, nirubar, niruscreensaver, nirulock,
  nirulauncher, nirunotify. NIRUX owns provisioning and release integration.
- Normal-user installation; sudo only for distribution packages/system files.
  Preserve existing user values and unrelated system integration.
- NIRUPI is outside this work. Do not install, update, clean or modify it.
- English UI/docs, ISO dates, 24-hour time, Monday-first calendar, ISO weeks.
- Niru Noir by default; Nord, Satie, Carl Larsson and custom themes supported.
- No new mandatory daemon, GUI framework, network service or repository for
  capabilities existing components can provide. Optional apps stay optional.
- Every new mandatory dependency has a verified mapping on **all three** distros.

## 2. Actual checkpoint

Published NIRUX **0.10.19** pins:

| Component | Version | Responsibility |
|---|---|---|
| niruwm | 0.16.21 | WM, session, niructl, niruidle |
| nirubar | 0.18.7 | Per-output bars, panels, tray |
| niruscreensaver | 0.8.1 | Unlocked idle surface |
| nirulock | 0.16.8 | PAM lock and explicit readiness |
| nirulauncher | 0.1.1 | Applications and desktop actions |
| nirunotify | 0.3.2 | Notifications, actions, DND, bounded history/OSD |

Launcher, notifier, weather, native desktop actions, manual brightness/night
light and sleep delay inhibition **already exist**. Native notifications are the
`auto` preference; Dunst is fallback. Do not rebuild these as new projects.

The 2026-10-20 corrections are **published** in NIRUX 0.10.15, niruwm 0.16.20,
nirubar 0.18.7 and updated installer/docs on the component main branches. NIRUX
**0.10.16** added the I06 configuration migration; **0.10.17** added the I07
target-installer staging handoff; **0.10.18** completed owned purge coverage and
made missing configured programs fail `doctor`; **0.10.19** pins niruwm 0.16.21
with the I09 standalone-installer metadata fix. All are installed on the owner's
machines, and each update exercised the installed parent/update path. Publication
is not physical acceptance: complete H01–H03 before treating the release as
fully verified.

## 3. Status vocabulary and execution rules

Use `TODO`, `IN_PROGRESS`, `LOCAL_VERIFIED`, `RELEASED`, `BLOCKED`.
`LOCAL_VERIFIED` never means published, installed, physically tested or complete.
Start one task ID; finish its acceptance before another feature checkpoint.

For each task, record: ID, repositories/paths, baseline revision, reproduction,
implementation, test command/result, distro/environment, remaining limits,
release/pin status and next task. Keep passwords/tokens out of every record.
Run `git status` first and preserve work from earlier maintainers.
Commit/push/tag/release only when explicitly requested by the user.

## 4. Ordered implementation queue

### M0 — make the current installation truthful

| ID / status | Repositories and exact work | Acceptance |
|---|---|---|
| I01 / RELEASED | `nirux/nirux`: missing-only Arch installs use `pacman -S`, never `-Sy`. | Mock command regression on all three OS shells; expired mirror package errors retain the current generation. |
| I02 / RELEASED | `nirux/nirux`: scope config keys to their TOML tables, handle indented/commented headers, preserve mode and user values. | Migration fixture: colliding keys, monitor profiles, 0600 mode, second-run idempotence. Full TOML edge cases remain I06. |
| I03 / RELEASED | Canonical examples in nirux/niruwm/nirubar: remove dead NIRUPI/Flameshot overrides; create Pictures before screenshots; update opt-in. | Both real component validators accept the canonical file; fresh standalone shortcuts call installed tools. Physical shortcut check remains H01. |
| I04 / RELEASED | Locker/saver installers: current default versions, reject NIRUX binary links, hash-check removals; locker removes only recorded PAM files and downloads release-pinned PAM. | Offline ownership/removal regressions on Void/Arch/Debian. Real standalone prebuilt install + PAM matrix remains H02. |
| I05 / RELEASED | `nirubar/src/config.rs,module.rs`: reject bad strftime formats before rendering; disabled battery/network/clock have no module/hitbox. | Rust regressions and fmt/clippy. WM/bar validator parity remains U01. |
| I06 / RELEASED | `nirux/nirux`: define supported migration syntax; test quoted keys, multiline strings/arrays, duplicate tables and interrupted writes. Stop rather than damage unsupported input; use a validated staged candidate before activation. | Original file and active generation survive every rejection; candidate parses in both components. No mandatory Python/TOML runtime just for migration. |
| I07 / RELEASED | `nirux/nirux`: forward staging to the verified target installer through a versioned internal handoff so new components install on the **first** update. Provision new shared-library dependencies before running staged components. | Old-installer → synthetic new-component and missing-library fixtures; corrupt assets or provisioning failure retain the old generation. |
| I08 / RELEASED | `nirux/nirux`: finish owned purge coverage for nirubar config, nirulauncher, nirunotify and saver state; make missing configured programs actionable in doctor. | Normal uninstall keeps config; documented purge covers only owned suite data. Missing configured browser is visible and fails the relevant diagnostic. |
| I11 / RELEASED | `nirux/nirux`: remove an accidental `cmp` dependency from owned-file comparison; use the existing SHA-256 checks. `nirulock/install.sh` does the same for PAM. | Arch base container runs the full integration without diffutils; suite/PAM files with equal content stay untouched. |
| I09 / RELEASED | `niruwm/install.sh`: selected old-release bar version comes from that release's metadata, not checkout `nirubar-version`; align standalone version/ownership checks. | Test old and current releases from a newer checkout; no generation contents overwritten. |

**Next implementation task: H03.** I06 is released in NIRUX 0.10.16, I07 in
0.10.17, I08 in 0.10.18 and I09 in niruwm 0.16.21/NIRUX 0.10.19. M0 and H02 are
complete. H02 was verified with the released nirulock 0.16.8 and
niruscreensaver 0.8.1 assets: source and prebuilt installers, pinned PAM,
modified-file preservation, corrupt/missing assets and non-root wrong/correct
PAM checks on Arch, Debian and Void. No test wrote production
`/etc/pam.d`. H03 is next; its lid/suspend, docking and physical output checks
need the owner's machines available.

### M1 — release acceptance on vanilla installations

| ID / status | Work | Acceptance |
|---|---|---|
| H01 / TODO | Fresh OS + empty normal-user home on Void/Arch/Debian; startx, then existing/selected display-manager paths. | Real release install → status/doctor → login → terminal/launcher/browser configuration, screenshots, icons, audio, lock/unlock → update → rollback → uninstall. Record OS release, manifest and exact results. |
| H02 / RELEASED | Standalone saver/locker prebuilt and source installers, pinned PAM, modified-file preservation and failed-install boundaries. | All three distro mappings plus non-root wrong/correct-password PAM checks. No test writes to production `/etc/pam.d`. |
| H03 / IN_PROGRESS | Physical Void + ThinkPad: lid close, suspend/resume, external output attach/remove, lock during topology changes, native notification privacy. | Never suspend before ready lock; no uncovered pixels; workspace/output identities survive; notifier cleans up on logout. Record physical separately from Xvfb. |
| H04 / RELEASED | Compile/publish changed components, verify assets/checksums, then update NIRUX pins and run full distro CI. Components and NIRUX 0.10.15 published 2026-10-20; finish asset/CI verification and one install/update check. | One install/update reaches the intended complete generation. Immutable tags/assets; never relabel published releases. |

Available hosts: `niru@void` and `niru@thinkpad`. Existing installs are **not clean
OS evidence**. Debian currently has container evidence, no physical host supplied.
Never force an active desktop to log out for acceptance testing.

H03 partial verification (2026-10-20):

- **Void, real X session:** lock covered the full 1920x1080 root; RTC-assisted
  suspend/resume kept Xorg and the lock alive with `_NIRU_LOCK_READY` and full
  coverage after resume. A locked mode change to 1600x900 resized the lock and
  restored cleanly, then returned to 1920x1080. The running session was still
  niruwm 0.16.19, so the monitor metadata during a mode change must be rechecked
  after logout/login on the installed 0.16.21.
- **ThinkPad, current 0.16.21 on isolated Xvfb:** lock covered the full
  1280x800 root. Native `nirunotify` kept a notification out of the lock (history
  only). Root resize to 800x600 resized the lock and restored. An unlocked
  session suspended via RTC/systemctl became locked before sleep and was still
  ready with full coverage after resume. Logout killed the notifier, WM and bar.
- **Remaining physical steps:** lid close/open and external output attach/remove.
  These need the owner at the machines; they are not claimed as verified.

### M2 — reliable and useful controls

| ID | Repositories / implementation boundary | Done when |
|---|---|---|
| U01 | WM/bar config validation contract; invalid values, hidden modules, unavailable/stale vs zero data; bound/coalesce WM hardware helpers. | Shared valid/invalid fixtures behave consistently; key storms cannot create unlimited children or freeze X. |
| U02 | Nirubar responsive layout with priorities and an overflow panel; retain stable workspace cells. | 800px, 1366px, 1920px and two-output tests; hidden summaries remain accessible, hitboxes match visible geometry. |
| U03 | Nirubar explicit media buttons/player selection and audio output/mic controls; deliberate click/scroll mappings. | Reading a panel never changes playback/mute; disabled actions explain missing providers; helpers remain bounded. |
| U04 | Nirubar honest network state and aggregate battery details. | Distinguish link/IP/connectivity; no mandatory NetworkManager. Multi-battery fixtures; absent estimates stay unavailable. |
| U05 | Launcher grouped actions, window switching, local recency/favourites and proper text input; lock layout/Caps indication and compose/AltGr review. | XDG desktop precedence and argv parsing preserved; Swedish/US/AltGr tests; no shell interpolation of desktop Exec. |
| U06 | Saver checked input grabs and output/resize coverage; retire duplicated rendering only where proven useful. | Failed grabs cannot claim success; root resize/hotplug and documented mouse dismissal covered. Retain all locker regressions. |

### M3 — coherent appearance and laptop behaviour

| ID | Work | Acceptance |
|---|---|---|
| A01 | Small versioned XDG appearance contract: semantic colours, font, spacing, focus, reduced motion. Existing user theme files take precedence. | Four built-in themes + custom fixture across WM/bar/launcher/notifier/lock/saver; invalid reload keeps the working state. Lock remains opaque black. |
| A02 | Night-light fixed/solar schedules and resume/hotplug reapply; brightness device/step selection. | Offline manual mode preserved; no GeoClue requirement; one provider owner; physical permissions diagnosed. |
| A03 | Optional weather/sun compact cell and daylight/precipitation timeline using existing cache. | Offline/stale/polar/explicit-0,0 fixtures; no extra polling daemon; no synchronous HTTP in the UI loop. |
| A04 | Optional notification images/hints after bounded decoding and protocol tests. | Advertise only implemented capabilities; image/queue/memory limits; lock privacy and action signals remain correct. |

## 5. Small innovations after the gates above

1. **Explain this state** (first): launcher actions open existing diagnostics for
   missing brightness, stale weather, notification ownership and active inhibitors.
   Reuse collected state; add no service.
2. **Focus session**: timed DND + keep-awake, one visible remaining-time indicator;
   restore previous state only if the user has not changed it meanwhile. Lock and
   manual suspend remain independent.
3. **Desktop lens**: contextual palette queries (`battery`, `display`, `weather`,
   `workspace`) expose cached facts and relevant existing actions.
4. **Docking profiles**: connector-identity preferences for output layout/bar density;
   explicit preview and timed revert, after H03 passes.

Each starts as one optional action/panel in an existing component, with a measured
idle CPU/RSS/process baseline and a regression for its actual failure modes.

## 6. Related repositories and portability backlog

See [repository inventory](docs/REPOSITORIES.md) for reviewed revisions and scope.
These are independent optional apps, not default core dependencies.

- **P01:** nirunote/niruorg: add verified Void Python/PySide6 package mappings,
  X11/offscreen startup and upgrade/removal tests. Do not copy Arch names blindly.
- **P02:** nirupres/niruflow: verify Python/Qt dependencies and clean installs on all
  three systems; document wheel/system-package limits. Correct stale niruflow README.
- **P03:** nirulize/nplay: verify PipeWire monitor/MPRIS/session-bus integration on
  all three distros; replace machine-specific nirulize install instructions.
- **P04:** nirupresence: opt-in NIRUWM startup contract without editing NIRUPI; one
  daemon, same graphical D-Bus, clean logout. No remote service/account requirement
  for the desktop itself.
- **P05:** QuickShell plugins remain optional Omarchy adapters. Do not install
  QuickShell in NIRUX to gain radio/presence; reuse nplay/MPRIS/native panels.
- **P06:** cmus/NPLAY/REAPER themes: validate declarative files and preserve modified
  files. Optional semantic palette export after A01; never force app settings.

## 7. Verification and handoff template

```text
Task ID/status:
Repositories + starting revisions:
Files changed / behaviour:
Reproduction before fix:
Commands run + results:
Distro + environment (mock / container / Xvfb / physical):
Published versions + NIRUX pins (or UNPUBLISHED):
Known limits / next task:
```

Core checks: `sh tests/integration.sh` in nirux; `sh tests/installer.sh` in
locker/saver; Rust `cargo fmt --check`, appropriate `cargo clippy --locked ... --
-D warnings` and `cargo test --locked --bins`. Use component X11/D-Bus suites for
changed runtime protocols and the NIRUX real-release smoke suite for release pins.
Clean package installation and physical login/PAM/sleep are separate evidence.

README policy: purpose, three-distro support/actual limits, install, essential
commands, config path, links. Keep release chronology in history/changelogs.
Delete obsolete generated artifacts only after tracing ownership; preserve
regressions, user themes/settings and useful history.
