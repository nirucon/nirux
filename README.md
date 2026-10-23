# NIRUX - A minimal X11 desktop by Nicklas Rudolfsson

**Early beta.** A small, keyboard-first X11 desktop for **Arch Linux, Debian and
Void Linux (glibc, x86_64)**. The suite is crafted in Rust; the installer is a
compact POSIX shell program. The result is fast, quiet and intentionally
minimal: no desktop-environment stack and no unnecessary background services.

NIRUX installs, updates and removes the complete NIRU desktop, including the
window manager, bar, launcher, notifications, lock screen, idle screen,
screenshots, themes, wallpapers, terminal integration and the OS packages the
components need.

## What it can do

- **Window management:** tiling with seven layouts, per-monitor workspaces,
  scratchpad, floating windows, fullscreen, gap control and session restore.
- **Bar:** ten per-monitor workspaces with occupancy markers, clock/calendar, network, battery, audio,
  microphone, brightness, media, weather, updates, CPU/memory, uptime, power
  profile, Bluetooth and a system tray.
- **Standard folders:** locale-aware XDG Desktop, Documents, Downloads, Music, Pictures and Videos.
- **Keyboard-first desktop:** application search, open-window switching,
  grouped actions, workspace recipes and focus/presentation modes.
- **Notifications:** native notification service and hardware OSD, DND,
  history, actions and live theme changes.
- **Session:** startx, SDDM or LightDM, PAM lock, idle screen, Polkit power
  actions and a managed session bus.
- **Hardware controls:** PipeWire/WirePlumber audio and microphone, BlueZ
  Bluetooth, RandR display profiles, power-profiles-daemon, backlight and
  night light.
- **LocalSend:** verified official Linux tarball, floating centered window, no Flatpak.
- **OpenCode:** managed V2 native CLI, installed without npm, services or agent startup.
- **Webapps:** `niruwebapp` creates browser-backed desktop apps with dedicated profiles and optional local icons.
- **Screenshots:** region, window or full-screen capture with a floating review
  dialog, crop, rectangle, arrow, mask, zoom and pan.
- **Appearance:** Niru Noir, Nord, Satie, Carl Larsson, Forest Vigil and Blood
  of Urdr themes, shared semantic colours, configurable fonts, emoji,
  theme-matched login wallpaper, optional extra wallpapers and optional picom
  transparency.
- **Safe maintenance:** checksummed releases, pinned components, atomic
  generations, rollback, configuration migration, diagnostics and owned
  uninstall.

## Suite

| Component | Role |
|---|---|
| [NIRUX](https://github.com/nirucon/nirux) | Installer, updates, dependencies and system integration |
| [NIRUWM](https://github.com/nirucon/niruwm) | Window manager, session, `niructl` and `niruidle` |
| [NIRUBAR](https://github.com/nirucon/nirubar) | Per-monitor status bar and panels |
| [NIRUSCREENSAVER](https://github.com/nirucon/niruscreensaver) | Unlocked idle screen |
| [NIRULOCK](https://github.com/nirucon/nirulock) | PAM-based lock screen |
| [NIRULAUNCHER](https://github.com/nirucon/nirulauncher) | Keyboard-first application and action launcher |
| [NIRUNOTIFY](https://github.com/nirucon/nirunotify) | Native notifications and hardware OSD |
| [NIRUSHOT](https://github.com/nirucon/nirushot) | Screenshot capture, review and annotation |
| [NIRUFETCH](https://github.com/nirucon/nirufetch) | NIRU-themed terminal system fetch |
| [NIRUWEBAPP](https://github.com/nirucon/niruwebapp) | Browser-backed webapp manager |

## Requirements

- Arch Linux, Debian or Void Linux glibc on x86_64.
- A normal user with `sudo` configured.
- Network access, and `git` if you clone the repository.
- Working graphics and hardware drivers/firmware from the OS installation.

NIRUX does not install proprietary GPU drivers or missing firmware. Void musl
and non-x86_64 systems are not supported by the released binaries.

## Install

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

An existing display manager is preserved; otherwise choose startx (default),
SDDM or LightDM. A fresh install offers the managed Helium browser and installs
the theme wallpapers, kitty/fish integration and terminal colours. User
configuration is not overwritten.

Use `./nirux install --no-packages` only when all runtime dependencies already
exist.

## Maintain

```sh
nirux update
nirux status
nirux doctor
nirux rollback
nirux uninstall
nirux uninstall --purge
```

Updates verify checksums and component versions, install missing runtime
packages, then switch one program generation atomically. The previous generation
remains available for rollback. Log out and in after updates that change the
session, window manager or idle daemon.

Default prefix: `~/.local`. Shared configuration:
`~/.config/niruwm/config.toml`. XDG paths are respected.

## Documentation

- [Installation and maintenance](docs/INSTALL.md)
- [Visual language](docs/STYLE.md)
- [Example configuration](config.example.toml)

MIT. Copyright 2026 Nicklas Rudolfsson.
