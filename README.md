# NIRUX

Install and maintain the NIRU X11 desktop on **Void Linux glibc, Arch Linux and
Debian**, independently of NIRUPI. Current release binaries target x86_64/glibc.
Personal software for the author's machines, public for others to try.

Includes [niruwm](https://github.com/nirucon/niruwm),
[nirubar](https://github.com/nirucon/nirubar),
[niruscreensaver](https://github.com/nirucon/niruscreensaver),
[nirulock](https://github.com/nirucon/nirulock) and
[nirulauncher](https://github.com/nirucon/nirulauncher) and
[nirunotify](https://github.com/nirucon/nirunotify), with Xorg, fonts and session
dependencies on a clean installation. Niru Noir is the default theme. Laptop backlight keys and Super+N night light work on supported hardware.

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

The 0.10.10 checkpoint ships and merges a canonical niruwm/nirubar config, uses a music-note icon and leaves a gap below the bar for notifications. It adds ISO week numbers and Left/Right month navigation to the bar calendar. It makes the verified native notifier the default provider when installed, with Dunst as fallback. It adds clickable notification actions and ActionInvoked to nirunotify. It installs PipeWire UCM profiles and RTKit so audio is usable from the first session, and doctor reports a missing default sink. It installs the remaining vanilla-desktop dependencies (PipeWire ALSA, slop, pcmanfm and Debian Font Awesome icons) and removes the dead Flameshot default. It adds monitor selection and configurable critical timeout/DND policy to the native nirunotify service. It adds the native nirunotify service (D-Bus, DND, bounded history, lock privacy and coalesced hardware OSD) while keeping Dunst as the default provider. It adds an opt-in Open-Meteo weather module in nirubar with background refresh, an atomic cache, offline/stale states and a distinct configured `0,0` location. It adds native `nirulauncher` for Super+P (apps) and Super+Shift+P (apps plus actions), with lock, screensaver, reload, DND, idle, brightness, night light, suspend, themes, workspaces and confirmed power actions. It adds lock-before-suspend through a logind/elogind sleep delay inhibitor. It adds explicit idle inhibition through `niructl idle` and `Super+Shift+C`. It makes `niructl suspend` wait for NIRULOCK's explicit readiness marker before suspending, so a locker that cannot confirm readiness is refused. It makes the screensaver and lock screen follow the suite theme's content colours while keeping an opaque black background. It installs only missing runtime packages instead of upgrading the whole system during an update. It adds native `niructl` desktop actions for lock, screensaver, logout, suspend, reboot, shutdown and provider-aware DND, plus `Super+Shift+D` for DND. It lets updates provision the downloaded release's runtime package list and expands doctor checks for configured programs, providers, real bar ownership, selected-prefix paths and the bar cache on purge. It makes NIRUPI helper shortcuts an explicit `nirupi_compat` profile, so a standalone install has suite-native defaults. It restores sessions by matching mapped windows to saved launch records, including floating state and focus, and follows the 0.7.3 observable `niructl reload`/`theme` acknowledgement. It includes complete layout selection and laptop brightness/night-light controls and global per-monitor workspaces, identity-based hotplug, bounded probes and filesystem/lock corrections, consistent key overrides,
helper reaping, full-monitor fullscreen and popup/reload pixmap cleanup.
Nirunotify is the default notification provider when installed; Dunst remains
available as the automatic fallback and can be selected explicitly with
`NOTIFICATION_PROVIDER=auto|native|dunst|external`.

[Installation details](docs/INSTALL.md) · [Roadmap and handoff](ROADMAP.md) ·
[Code audit](AUDIT.md) · [Measurements](MEASUREMENTS.md)

MIT. Copyright 2026 Nicklas Rudolfsson.
