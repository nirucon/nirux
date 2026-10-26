# NIRUX

**A minimal, native X11 desktop by Nicklas Rudolfsson.**

NIRUX brings together a tiling window manager, per-monitor status bar, keyboard-first
launcher, notifications, locking, screenshots and graphical theme, wallpaper and
display settings. The components share appearance and configuration conventions.
It is an early-beta desktop intended for everyday use and continued refinement.

## Supported systems

- **Arch Linux, Debian and Void Linux glibc**, x86_64.
- An existing Linux installation with working graphics, drivers and firmware.
- A normal user with `sudo`, Internet access and `git` for the installation below.
- X11; released binaries do not support Wayland, Void musl or other architectures.

NIRUX installs desktop runtime dependencies, not an operating system or GPU
drivers. It preserves existing user settings where possible. Back up important
configuration before changing an existing desktop.

## Install

Run as your normal desktop user, **not in a root shell**:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

The installer downloads versioned release assets and verifies their checksums.
The default prefix is `~/.local`. It preserves an existing display manager and
supports **startx, SDDM and LightDM**; select NIRUWM when logging in. For explicit
session selection and installation options, see [installation](docs/INSTALL.md).

Use `--no-packages` only when the required runtime packages already exist. Driver
and firmware problems must be resolved through the distribution. Optional managed
applications and image downloads are described in the installation guide.

## The desktop at a glance

- **NIRUWM:** seven layouts, per-monitor workspaces, floating windows, scratchpad,
  keybindings, session state and display profiles.
- **NIRUBAR:** workspaces, wired/Wi-Fi state, audio, brightness, media, battery,
  calendar and optional providers, with direct routes to settings.
- **NIRU Launcher:** applications, windows, web search, actions and NIRUX Settings.
  Wi-Fi discovery, SSID filtering and profile operations use the existing network
  manager. See the [backend compatibility notes](docs/WIFI.md).
- **Theme Selector, Wallpaper and Display:** native graphical settings; browsing
  previews does not automatically apply a change. Theme Selector and Wallpaper
  open floating on the active monitor.
- **Notifications, lock, idle and screenshots:** integrated lightweight tools,
  with shared colours/fonts and normal system authentication.

Start with **Super+P** for applications and **Super+Shift+P** for actions/settings.
Use the launcher's keybinding view for the active shortcuts, including overrides.

## Update and activation

```sh
~/.local/bin/nirux update
~/.local/bin/nirux status
```

Updates keep a previous generation for rollback. Settings and custom content are
preserved according to installer ownership rules. Follow the activation message:
**log out and back in when WM/session programs change**. Restarting a bar alone
does not activate a new running window manager. The installer never updates the
whole base operating system on your behalf.

```sh
~/.local/bin/nirux rollback
```

Rollback restores the previous program generation; it is not a backup of all
personal files or operating-system packages. Activate the restored session normally.

## Removal

```sh
~/.local/bin/nirux uninstall
```

Use `nirux --help` and [installation/removal details](docs/INSTALL.md) before using
`--purge`. Purge removes additional managed configuration/state; it is not a
lossless undo of every change. Personal or modified files must be preserved, and
distribution runtime packages may remain installed.

## Documentation and components

- [Installation, session choices and troubleshooting](docs/INSTALL.md)
- [Wi-Fi backends and limitations](docs/WIFI.md)
- [Theme and additional wallpaper packs](docs/WALLPAPERS.md)
- [Shared configuration example](config.example.toml) and
  [appearance overrides](appearance.example.toml)
- [Pinned component versions](manifest)

[NIRUWM](https://github.com/nirucon/niruwm) ·
[NIRUBAR](https://github.com/nirucon/nirubar) ·
[Launcher](https://github.com/nirucon/nirulauncher) ·
[Theme Selector](https://github.com/nirucon/niruthemeselector) ·
[Wallpaper](https://github.com/nirucon/niruwallpaper) ·
[Display](https://github.com/nirucon/nirudisplay) ·
[Lock](https://github.com/nirucon/nirulock) ·
[Notifications](https://github.com/nirucon/nirunotify) ·
[Screenshots](https://github.com/nirucon/nirushot)

NIRUX is provided without warranty. See [LICENSE](LICENSE).
