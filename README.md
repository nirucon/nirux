# NIRUX

Install and maintain the NIRU X11 desktop on **Void Linux glibc, Arch Linux and
Debian**, independently of NIRUPI. Current release binaries target x86_64/glibc.
Personal software for the author's machines, public for others to try.

Includes [niruwm](https://github.com/nirucon/niruwm),
[nirubar](https://github.com/nirucon/nirubar),
[niruscreensaver](https://github.com/nirucon/niruscreensaver),
[nirulock](https://github.com/nirucon/nirulock) and
[nirulauncher](https://github.com/nirucon/nirulauncher), with Xorg, fonts and
session dependencies on a clean installation. Niru Noir is the default theme. Laptop backlight keys and Super+N night light work on supported hardware.

## Install

Run as your normal login user with sudo available:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

An existing display manager is preserved. Otherwise choose startx (default), SDDM
or LightDM. Existing configuration and NIRUPI are preserved. For an existing
desktop with dependencies installed: `./nirux install --no-packages`.

## Maintain

```sh
nirux update               # also checks/install missing runtime packages
nirux update --no-packages
nirux status
nirux doctor
nirux rollback
nirux uninstall             # add --purge to remove NIRU settings/state
```

Releases pin checksummed component assets and activate one program generation
atomically. Log out/in to activate updated WM/session/idle binaries; bar restart
is handled through the running WM. Default prefix: `~/.local`; XDG paths respected.

The 0.9.2 checkpoint adds an opt-in Open-Meteo weather module in nirubar with background refresh, an atomic cache, offline/stale states and a distinct configured `0,0` location. It adds native `nirulauncher` for Super+P (apps) and Super+Shift+P (apps plus actions), with lock, screensaver, reload, DND, idle, brightness, night light, suspend, themes, workspaces and confirmed power actions. It adds lock-before-suspend through a logind/elogind sleep delay inhibitor. It adds explicit idle inhibition through `niructl idle` and `Super+Shift+C`. It makes `niructl suspend` wait for NIRULOCK's explicit readiness marker before suspending, so a locker that cannot confirm readiness is refused. It makes the screensaver and lock screen follow the suite theme's content colours while keeping an opaque black background. It installs only missing runtime packages instead of upgrading the whole system during an update. It adds native `niructl` desktop actions for lock, screensaver, logout, suspend, reboot, shutdown and provider-aware DND, plus `Super+Shift+D` for DND. It lets updates provision the downloaded release's runtime package list and expands doctor checks for configured programs, providers, real bar ownership, selected-prefix paths and the bar cache on purge. It makes NIRUPI helper shortcuts an explicit `nirupi_compat` profile, so a standalone install has suite-native defaults. It restores sessions by matching mapped windows to saved launch records, including floating state and focus, and follows the 0.7.3 observable `niructl reload`/`theme` acknowledgement. It includes complete layout selection and laptop brightness/night-light controls and global per-monitor workspaces, identity-based hotplug, bounded probes and filesystem/lock corrections, consistent key overrides,
helper reaping, full-monitor fullscreen and popup/reload pixmap cleanup.
[nirunotify](https://github.com/nirucon/nirunotify) remains a design-stage component.

[Installation details](docs/INSTALL.md) · [Roadmap and handoff](ROADMAP.md) ·
[Code audit](AUDIT.md) · [Measurements](MEASUREMENTS.md)

MIT. Copyright 2026 Nicklas Rudolfsson.
