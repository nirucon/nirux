# NIRUX - A minimal X11 desktop by Nicklas Rudolfsson

**Beta.** A small, keyboard-first X11 desktop for **Arch Linux, Debian and
Void Linux (glibc, x86_64)**.

NIRUX is built in the spirit of [suckless dwm](https://dwm.suckless.org/), which
the author ran for many years before writing this
suite. That inheritance is deliberate and visible: one flat text file for the
whole configuration, a tiling window manager with tags instead of virtual
desktops, keybindings as the primary interface, and no desktop-environment
stack. The difference is scope. NIRUX adds what a modern machine needs to be
usable every day (audio, network, notifications, a lock screen, screenshots,
themes) while keeping the surface small enough to read in one sitting.

The suite is crafted in Rust; the installer is a compact POSIX shell program.
The result is fast, quiet and intentionally minimal: no desktop-environment
stack and no unnecessary background services.

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
- **Standard folders:** locale-aware XDG Documents, Downloads, Music, Pictures and Videos.
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
- **Appearance:** Niru Noir, Nord, Satie, Carl Larsson, Forest Vigil, Blood of
  Urdr, Root and Stone, Blue Horizon, The Norns and Winter Nights themes,
  shared semantic colours, configurable fonts, emoji,
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
kitty/fish integration and terminal colours. User configuration is not
overwritten.

### Wallpapers

Only the default theme's wallpaper ships with a release, in 4K and 8K. The
other nine themes are an optional set of about 311 MB served from the project's
own Nextcloud, so a routine release stays small and an update does not download
wallpapers a machine already has:

```sh
nirux wallpapers status     # how many of the ten themes have an image
nirux wallpapers download   # install all ten (checksum verified)
nirux wallpapers remove     # delete the downloaded set, keep the default
```

The same action is in the launcher under **Wallpaper**. NIRUX asks once during
installation whether to fetch the set and remembers the answer; the default is
no. The archive is verified against a SHA-256 pinned in this repository, staged
in a temporary directory, and moved into place only when complete, so an
interrupted download cannot leave a half-written set.

A theme without its image paints its own background colour, taken from the
theme file, so the desktop still matches the theme instead of showing the
previous theme's picture. `remove` never deletes a file you modified.

Use `./nirux install --no-packages` only when all runtime dependencies already
exist.

## Maintain

```sh
nirux update
nirux remove helium|localsend|opencode
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
