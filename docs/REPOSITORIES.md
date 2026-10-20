# NIRU repository inventory — 2026-10-20

All URLs are under `https://github.com/nirucon/`. Baseline revisions are the
checked-out GitHub main heads before this review's uncommitted edits.
No AGENTS.md was found in these checkouts.

## Desktop core

| Repository | Revision | Review / verification |
|---|---|---|
| nirux | `375feb4` | Installer, config migration, manifest, CI, docs; offline integration on three OS environments |
| niruwm | `bdcd34b` | Binding defaults/canonical config/installer review; all binary unit suites, fmt/clippy |
| nirubar | `648619f` | Config, visibility and clock/render path; binary unit suite, fmt/clippy |
| nirulock | `e99a002` | Standalone installer/PAM assets/ownership; binary unit suites and installer regressions |
| niruscreensaver | `37cefb5` | Standalone installer/version/ownership; binary unit suite and installer regressions |
| nirulauncher | `ad9068f` | README/source layout and existing contract; binary unit suite only |
| nirunotify | `cc72b38` | README/source layout and existing contract; binary unit suite only |

This is targeted core review, not line-by-line proof of the entire suite. Retain
the earlier runtime/protocol audit and finish the acceptance queue in ROADMAP.

## Optional applications and adapters

These received an initial README/install-surface review, **not exhaustive code
audits or three-distro runtime certification**. Follow portability tasks P01–P06
in [ROADMAP](../ROADMAP.md).

| Repository | Revision | Integration decision / follow-up |
|---|---|---|
| niruflow | `8ebe053` | Optional maintenance app; README claims 0.1 alpha while latest commit says 0.4.1; reconcile actual package metadata first |
| nirulize | `58d6f16` | Optional terminal visualizer; remove private-machine path/Omarchy-only install example; verify Void capture packages |
| nirunote | `c90421e` | Optional Qt editor; installer handles pacman/APT, lacks Void dependency installation |
| niruorg | `e465781` | Optional Qt organizer; installer handles pacman/APT, lacks Void dependency installation; remote/FUSE tests separately |
| nirupres | `2d07cf4` | Optional Qt presenter; validate venv/wheel and Multimedia/WebEngine availability on all three OSes |
| nirupresence | `02add5b` | Optional network companion; check plain NIRUWM session startup on Void without NIRUPI hook edits |
| nirupresence-qsp | `120ef01` | Optional Omarchy/QuickShell adapter; not a NIRUX dependency |
| niru-omasverigesradio | `a71dcb5` | Optional Omarchy/QuickShell radio; reuse nplay/MPRIS if adding native integration |
| nplay | `abaf0e4` | Optional independent player; already documents three distros; check MPRIS/bus integration |
| nplay-themepack | `1da2e4a` | Optional declarative themes; validate with its manage.py; preserve edits |
| nplay-themepackniru | `8f0dfcc` | Optional declarative themes; palette export only after appearance contract |
| niru-cmus | `80f1848` | Optional terminal themes; preserve existing files; no core package dependency |
| nirureaper-noir | `15b25c4` | Optional REAPER theme generator; no core REAPER dependency |

`nirupi` is explicitly excluded by the owner. `nas` and `craftapps` are account
repositories outside the NIRU desktop scope; no changes or review claims here.
