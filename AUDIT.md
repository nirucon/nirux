# NIRU desktop audit — 2026-10-19

## Summary

The suite has a useful native X11 foundation and recent, valuable correctness
fixes. The next work should start with **nirubar memory safety and nirulock display
coverage**, then repair WM/bar integration before adding new desktop components.

This is an analysis checkpoint. Product code and release pins were not changed.
The implementation sequence and feature designs are in [ROADMAP.md](ROADMAP.md).

### Reviewed revisions

| Repository | Revision | Current checkpoint |
|---|---|---|
| nirux | `0223689` | Suite 0.6.0 |
| niruwm | `ea266f3` | 0.16.4 |
| nirubar | `db42bf6` | 0.16.5 |
| niruscreensaver | `d932519` | 0.8.0 |
| nirulock | `dbaf437` | 0.16.5 |
| nirulauncher | `6ce48e0` | Design only |
| nirunotify | `441a91a` | Design only |

Local branches were clean and fetched against GitHub before review. No repository
AGENTS.md instructions were present. Existing roadmap/history and code were read;
old fixed defects are not presented below as new unfixed discoveries.

### Evidence levels and priority

- **Reproduced:** exercised the failing runtime path in an isolated environment.
- **Source-confirmed:** the conflicting/missing implementation is directly visible;
  the full scenario still needs a regression or physical acceptance test.
- **P0:** memory safety or lock coverage; first correction checkpoint.
- **P1:** broken supported workflow, resource lifecycle or standalone installation.
- **P2:** consistency, diagnostics and usability improvements.

## P0 findings

### B01 — undersized filesystem ABI can overwrite stack storage

**Reproduced ABI mismatch.** `nirubar/src/pulse.rs:142–181` declares `StatVfs` as
eleven `u64` fields: **88 bytes**. On the audited x86_64 glibc system the real
`struct statvfs` is **112 bytes**, including trailing reserved storage. The libc
call writes beyond the Rust allocation. This path is used by the pulse sampler
and the uptime information popup.

A C probe allocated the full real structure, initialized it to `0xa5`, called
`statvfs("/", ...)` and counted changes past the Rust structure's 88-byte boundary:

```text
statvfs rc=0; nirubar allocation=88; libc sizeof=112;
changed bytes beyond nirubar allocation=24
```

Use maintained platform-correct bindings, not extra guessed padding. Add an ABI
regression and review the remaining unsafe FFI. The fact that published builds
or current unit tests appear to run does not make the undersized call valid.

### L01 — later windows can appear above the established lock

**Reproduced in Xvfb.** `nirulock/src/main.rs:139–147,532–580` selects stacking
events, but the event handler raises on `CirculateNotify` and lock-window
`ConfigureNotify`, not a newly mapped ordinary overlay. After starting the locker,
mapping a 320×100 notification-like window left this root stack, top first:

```text
AUDIT_NOTIFICATION  320x100+10+10
NIRULOCK           1600x900+0+0
```

The keyboard remained owned by the locker; the defect is visible content above
it. Fix normal session overlay coordination, map/raise handling and notifier
privacy. Verify with the actual WM/compositor as well as isolated X. This test
does not claim that an X11 locker can isolate a hostile same-server client.

### L02 — lock coverage does not follow display geometry changes

**Source-confirmed.** `nirulock/src/core.rs:247–279` stores startup root geometry
and allocates one pixmap/window at that size. `keep_on_top` reuses those values;
the main event loop has no root/RandR resize handling. A larger display layout
therefore has no coverage-resize path. Clock and prompt are also centered on the
combined root rather than a selected physical monitor.

Implement an opaque resize/hotplug transition with resource replacement and
per-monitor positioning. Actual GPU hotplug and resume remain physical test work.

## niruwm findings

| ID | Priority / evidence | Finding and source |
|---|---|---|
| W01 | P1, reproduced | `wm/keys.rs:29–33` uses only `cfg.keys` whenever nonempty. The tested/dumped `Config::effective_keys()` merge is not used by runtime. With one custom workspace binding, Super+3 stopped working while the custom binding worked. Adding laptop keys to an existing full table also needs migration. |
| W02 | P1, reproduced | `wm/mod.rs:513–518` drops Child handles in `spawn_detached`. Three `shell true` key activations left three `Z sh` children under the WM. `spawn_owned` instead creates one waiting thread per app; use a single coherent reaping model. |
| W03 | P1, source-confirmed | `clients.rs:547–594` publishes the sum of per-monitor desktops and flattened names, but current desktop/client tags remain monitor-local. `events.rs` and `niructl` still restrict commands to nine. The bar also assumes nine global cells. Define global EWMH offsets and a separate monitor-local contract. |
| W04 | P1, source-confirmed | `wm/mod.rs:331–359` reassigns clients by numeric monitor index, so output sorting/removal can move clients to the wrong surviving output. `randr::refresh` preserves active workspace but resets nmaster. Reload replaces cfg but does not rebuild monitor_cfg/monitors or wallpaper state. `events.rs:49–50` calls wallpaper.tick only when poll reports readable input, so idle timeouts alone do not rotate it. |
| W05 | P1, source-confirmed | `clients.rs:421,444–450` gives fullscreen windows the already bar-reduced monitor area. Fullscreen should use full output geometry. `monitor_area` also reserves a bar only for monitors at y=0 although one is started for every monitor. |
| W06 | P1, source-confirmed | `keys.rs:357–388` changes active tags and spawns all restored apps asynchronously without pending placement matching; `manage` later uses current state/pointer. Saved floating is never applied. Multiple windows can save duplicate commands, and a visible scratchpad is saved. Missing-program names are interpolated into a shell command at lines 396–402. |
| W07 | P2, source-confirmed | `niructl` lists centeredfloat but its layout command cannot select it. Most commands have no real acknowledgement; a fixed 30ms sleep is treated as completion. `status` identifies any `_NET_SUPPORTING_WM_CHECK` owner as niruwm, and documented offline session operations still connect to X first. |
| W08 | P2, source-confirmed | `clients.rs:256–259` skips border updates when the bar is disabled. Direct `Action::Theme` only updates WM state/borders, unlike `niructl theme`, so the theme action has inconsistent suite effects. Binding parsing accepts Mod3, but runtime's modifier mask omits it. |

Runtime binding reproduction used an empty temporary XDG home, disabled bar and
custom Super+X → tag 2 / Super+Z → shell true bindings:

```text
Super+3: _NET_CURRENT_DESKTOP = 0
Super+X: _NET_CURRENT_DESKTOP = 1
WM children after three Super+Z activations: Z sh, Z sh, Z sh
```

## nirubar findings

| ID | Priority / evidence | Finding and source |
|---|---|---|
| B02 | P1, reproduced | `main.rs:268,276–279` uses one `_NIRUBAR_SELECTION` for the entire X screen, while niruwm starts a child for every monitor. A second `--monitor` instance exits as already running. Simultaneous startup can also race selection ownership. WM crash recovery then restarts all bars periodically when one child exits. |
| B03 | P1, source-confirmed | `snapshot`, `compose`, `click` and Workspaces hardcode nine cells and global current desktop/client properties; there is no monitor identity in the workspace commands. The getter also truncates `_NET_CLIENT_LIST` to 64 entries. Configured per-output names/counts cannot be represented correctly. |
| B04 | P1, reproduced geometry/focus; source-confirmed lifecycle | `popup.rs:62–66` ignores bar_x/bar_y. A bar at `800,100,800` opened a panel at `654,28`, outside its physical monitor. Focus remained PointerRoot: focus is requested before the window is mapped. Expose does not repaint retained content, previous focus is not restored, and the fullscreen InputOutput catch window can obscure/intercept the bar. Popup expiry is checked only when the X queue is empty. |
| B05 | P1, source-confirmed | `tray.rs:53–75,139–192` creates a 1×1 unmapped tray parent at -1,-1; layout moves only its children. `_XEMBED_INFO` is used as the embedding message type instead of `_XEMBED`, with the wrong embedder data. Also `main.rs:1000` exits the whole bar on any selection loss, including the tray selection. |
| B06 | P1, source-confirmed | `render.rs:77–80` allocates a pixmap then overwrites its ID with a popup window ID. No renderer cleanup releases that abandoned pixmap, nor the old main renderer on reload. One 340×244 popup buffer is roughly 324 KiB of pixel storage before server overhead. Repeated popups/reloads can grow X-server resources despite stable process RSS. |
| B07 | P1, source-confirmed | `av::run`, updates queries, network detail and filesystem capacity checks execute synchronously without output/time limits. A hung helper or remote filesystem can freeze the bar. One-second AV caching from M1 reduces frequency but does not make those calls nonblocking. |
| B08 | P1, source-confirmed | `module.rs::Pulse::render` samples every render, including media animation and property bursts, and calls filesystem sampling each time. The claimed one-second graph interval is false. With 33ms scroll redraws, a 240-sample history can cover only about eight seconds. Separate sample clocks from painting. |
| B09 | P2, source-confirmed | `Volume::popup` toggles mute and `Media::popup` toggles playback before showing information. Main click dispatch ignores button identity, so middle/right/scroll events can take the same action. Panels need explicit controls and configurable click/scroll mappings. |
| B10 | P1/P2, source-confirmed | Config validators diverge; invalid strftime strings are not validated before formatting. WM accepts future bar keys while the bar rejects them. The README puts weather coordinates under `[bar]`, but both schemas define them at the document root. `battery`/`network` booleans are ignored by module construction, both clock flags false still shows time, and calendar labels are `mo tu ...`, not the requested `Mon Tue ...`. |
| B11 | P1/P2, source-confirmed | Update queries ignore exit failures and parse Debian's English phrase without fixing the command locale; errors can become zero updates. Failed refreshes are not backed off. `update_check_minutes=0` means query on every render. ALSA parsing splits at `[` then expects segments to end at `%]`, which fails on normal `[45%] [on]` output. |
| B12 | P2, source-confirmed | Sun at `0,0` is computed despite documentation calling that location unset. Polar day/night and missing location share an inadequate message; location range is not validated. Time is rounded after modulo, permitting `24:00`. Add deterministic date/zone inputs instead of season-dependent tests. |

The current unit test explicitly checks that a second bar is refused. The test
passes while the two-monitor product contract fails: acceptance must cover the
session that actually launches multiple monitor bars, not just singleton code.

## niruscreensaver and nirulock follow-up

| ID | Priority / evidence | Finding and next work |
|---|---|---|
| S01 | P1, source-confirmed | Saver also fixes coverage/centering to startup root geometry. Its keyboard/pointer Grab cookies are not replied to or checked (`core.rs:317–333`), so it can present itself while input belongs elsewhere. Mouse motion is selected but not handled as dismissal; define and test that policy. |
| T01 | P1, source-confirmed | Both programs use an independent hardcoded Noir palette plus optional numeric palette overrides; neither reads the selected niruwm theme. Root background and GTK session defaults are also fixed to dark/Noir. No suite-wide theme-change contract exists. |
| L03 | P1, source-confirmed | PAM is synchronous in the UI thread (`submit`), including failure delays; during authentication the lock cannot service resize/overlay events. Password Strings are cleared/dropped without explicit zeroization, and conversation error paths can leak prior strdup responses. Use a bounded authentication worker, structured cleanup and deliberate credential lifetime. |
| L04 | P1, source-confirmed | User identity trusts `$USER`, then an external command, finally root. PAM invokes authenticate only, while comments claim broader account policy. Resolve identity from real UID and define/test the intended authentication/account semantics. Do not claim generic fingerprint/multifactor support from the present password-only conversation. |
| L05 | P1, source-confirmed | Key translation handles basic levels/Latin-1, not full XKB state, compose/dead keys, Unicode or input methods; Caps logic covers ASCII only. Show active layout/Caps state and test Swedish/US/AltGr/dead-key cases. The loop also waits on the fd before draining all already-buffered events, unlike the corrected saver loop. |
| I01 | P1, source-confirmed | `niruidle` owns its own lock child but does not share lock state/readiness with a manually launched locker. Suspend/lid paths have no native logind/elogind readiness/inhibitor protocol. Competing starts, failed acquisition, resume and restored idle state require one coherent lifecycle. |

The earlier timeout bypass and raw-keycode leaks were fixed in the reviewed
release. Retain their regressions; do not reintroduce timeout-based lock dismissal.
Saver and locker rendering copies have already diverged despite comments claiming
they are identical and checked by a script that is not present in these trees.

## nirux, installers and portability

### X01 — component installation paths contradict current architecture

**P1, source-confirmed.**

- niruwm `install.sh` defaults to **0.16.2** while Cargo/session are **0.16.4**.
  It still downloads/builds nirubar from the WM release/build output and requires
  equal WM/bar versions, despite the independent bar repo and current **0.16.5**.
  `--build` cannot produce the required bar from the current Cargo manifest.
- Its session script comes from the checkout, rather than the selected release's
  checksummed session asset.
- nirubar `install.sh` always invokes Cargo, contradicting its README's prebuilt
  install claim, writes legacy `~/.config/niru`, and announces **0.1.0-alpha.1**.
- Individual installers use different prefix variables and do not reconcile
  ownership with NIRUX's current-generation symlinks. Audit this before combining
  individual-component installs and suite generations.

NIRUX itself has the stronger model: staged verified assets, generation activation,
rollback and owned system integration. Align individual installs with it while
preserving independent usage.

### X02 — standalone installation exists, standalone shortcuts are incomplete

**P1, source-confirmed.** NIRUX installs Xorg, session tools, audio, fonts and
fallback launcher/notifier for Void/Arch/Debian. It does not require NIRUPI.
However `bindings.rs:189–208` still points night light, suspend, power menu,
theme menu, focus/inhibition and other shortcuts at NIRUPI-only scripts.
Super+Shift+P falls back to the same app launcher as Super+P when NIRUPI is absent.

The session also automatically starts/reuses NIRUPI helpers when present,
including autostart/battery helpers; the delayed autostart process is not tracked
by cleanup. Make compatibility/provider selection explicit and test isolation.

### X03 — new dependencies and accurate diagnostics need lifecycle support

**P1/P2, source-confirmed.** Package lists contain neither brightnessctl nor a
night-light provider. `nirux update` forces package installation off, so adding a
new binary/backend later will not provision it for existing installations.
`doctor` checks fixed kitty/rofi names rather than selected providers and does not
verify notifier bus ownership, gamma ownership, idle inhibition or lock readiness.
Status process matching is per-user, not display/monitor. Purge currently omits
the bar cache and needs expansion when components are added.

The current package mappings and release-smoke workflows already cover the three
requested distributions. Keep x86_64/glibc limits explicit; adding Void musl or
other architectures is separate build/authentication work, not an existing promise.

## Verification performed for this audit

### Current source tests

In the Rust Bookworm container, `cargo test --locked --bins` (bar/saver selected
their main binary) passed for the reviewed sources:

| Binary | Test executions passed |
|---|---:|
| niruwm | 57 |
| niructl | 41 |
| niruidle | 2 |
| nirubar | 63 |
| niruscreensaver | 9 |
| nirulock | 12 |
| pamcheck | 4 |

Some binaries compile the same shared-module tests; these are not all unique
regressions. Ignored GUI tests and full cross-distribution package installs were
not rerun as part of these unit commands. `sh tests/integration.sh` in nirux
passed its offline Arch/Debian/Void mappings, generations, rollback, checksums,
PAM includes, uninstall and purge fixtures. Latest pre-audit NIRUX CI was green
([39167656963](https://github.com/nirucon/nirux/actions/runs/39167656963)).

### Targeted runtime checks

- Full-size C buffer probe proved the 24-byte libc write beyond the Rust ABI size.
- Isolated Xvfb reproduced second-monitor bar refusal, incorrect popup origin,
  failed popup focus, dropped default bindings, shell-child zombies and later
  content above the lock. These checks used current locally built binaries.
- Physical Void laptop: current suite versions matched the pins; a real NIRUWM
  X11 session was running on **eDP-1, 1920×1080**, alongside an installed NIRUPI.
- `nirux doctor` passed with the running session's actual DISPLAY/XAUTHORITY.
  The initial DISPLAY-only SSH attempt lacked X authorization; it was corrected,
  not treated as a desktop failure.
- Intel `brightnessctl` worked as the normal user: **100% → 95% → 100%**, restoring
  the initial raw value **19200**.
- Gammastep and Redshift were installed; neither was running in the process check.
  Bare Gammastep attempted missing GeoClue. With explicit location, a one-shot
  RandR **4500 K** adjustment and reset succeeded. Manual NIRU controls must not
  require working GeoClue or a live network connection.

The laptop's configuration and installed suite were retained. Hardware shortcut
integration, multi-monitor physical hotplug, lid/suspend/resume, new notification
protocols and fresh physical Arch/Debian installations remain release acceptance
work. No unimplemented launcher/notifier/weather functionality is described as
already tested or released.
