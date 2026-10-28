# NIRUX

**A minimal, native X11 desktop by Nicklas Rudolfsson.**

NIRUX brings together a tiling window manager, per-monitor status bar, keyboard-first
launcher, notifications, locking, screenshots and graphical theme, wallpaper and
display settings. The components share appearance and configuration conventions.
It is an early-beta desktop intended for everyday use and continued refinement.

NIRU Actions adds one catalogue for maintenance, diagnostics, display recovery,
work contexts and optional OpenCode assistance. Deterministic actions work without
an account, network request or model.

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

- **NIRUWM:** eight layouts, per-monitor workspaces, floating windows, scratchpad,
  keybindings, session state and display profiles. **Scroll** keeps one window
  per column and shows one or two adjacent columns, sliding horizontally with
  focus; `Super+Ctrl+S` selects it and `Super+Ctrl+Shift+S` toggles columns.
- **NIRUBAR:** workspaces, wired/Wi-Fi state, audio, microphone, brightness, media, battery,
  calendar and optional providers, with direct routes to settings. It supports
  XEmbed and D-Bus StatusNotifierItem trays on the primary monitor, including
  real icons and clickable application menus. A session watcher recovers windows
  after dock, lid and output changes and re-applies the saved startup profile
  when the connected-output set changes.
- **NIRU Launcher:** applications, windows, web search, actions and NIRUX Settings.
  **Super+A** opens the focused NIRU Actions view; the same entries appear in
  **Super+Shift+P**. It includes storage review, off-screen window recovery, NIRUX
  installed/running status, focus and presentation contexts, recent tasks and an
  optional OpenCode terminal handoff. Deterministic phrases such as "lock",
  "lås", "focus mode", "stör ej" and "höj volymen" resolve to the same commands;
  **Ctrl+S** saves the selected application or command as a reusable action.
  Wi-Fi discovery, SSID filtering and profile operations use the existing
  network manager. See the [backend compatibility notes](docs/WIFI.md) and
  [NIRU Actions](docs/ACTIONS.md).
- **Theme Selector, Wallpaper and Display:** native graphical settings; browsing
  previews does not automatically apply a change. Theme Selector and Wallpaper
  open floating on the active monitor.
- **Notifications, lock, idle, screenshots and recording:** integrated lightweight
  tools, with shared colours/fonts and normal system authentication. NIRUCLIP
  records the screen, a region or camera with optional overlay, microphone and
  desktop audio; the launcher exposes built-in or saved profiles.
- **Files and removable media:** udisks2/GVFS backends for USB, MTP, SMB and
  phones, plus archive tools. Papirus-Dark with grey folders is an optional
  per-user install (`--icons papirus`) because of its size.
- **Input and display scale:** keyboard layout/repeat, pointer speed, natural
  scrolling and touchpad tap controls. The system X11 layout is inherited unless
  you explicitly choose another one. The bar and launcher read `Xft.dpi` and
  scale through `NIRU_UI_SCALE` (bounded 0.75–2.5) while still fitting an
  800x600 screen. See [input settings](docs/INPUT.md).
- **NIRU Display 0.2:** stable screen numbers, EDID identity, full frames, frozen
  drag, snapping, zoom/pan, mirror grouping and safe preview transactions.
- **NIRUBAR:** includes an optional `tasks` module for running/waiting NIRU jobs and
  an XEmbed + SNI tray; it does not require a desktop daemon.

Start with **Super+P** for applications, **Super+A** for NIRU Actions and
**Super+Shift+P** for applications, windows, actions and settings. Use the
launcher's keybinding view for the active shortcuts, including overrides.

## Update and activation

```sh
~/.local/bin/nirux update
~/.local/bin/nirux status
```

Updates keep a previous generation for rollback. Settings and custom content are
preserved according to installer ownership rules. Follow the activation message:
**log out and back in when WM/session programs change**. Restarting a bar alone
does not activate a new running window manager. `nirux status` reports when the
installed and running bar/WM generations differ. The installer never updates the
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

## Important installed software

NIRUX provisions the X11 runtime, keyboard/mouse input, PipeWire audio (including the NIRU Sound panel via `nirulauncher --sound`), NetworkManager
or the existing Wi-Fi stack, fonts (DejaVu, Liberation, Noto Sans/Serif and Color
Emoji), kitty, fish, pcmanfm, picom, dunst, screenshot and notification tools. Helium, LocalSend and OpenCode are optional managed choices;
an existing installation of any of them is left untouched. OpenCode is not required
for NIRU Actions; its integration opens a terminal handoff and asks before changes.

## Documentation and components

- [Installation, session choices and troubleshooting](docs/INSTALL.md)
- [NIRU Actions, tasks and optional OpenCode](docs/ACTIONS.md)
- [Input settings](docs/INPUT.md)
- [Wi-Fi backends and limitations](docs/WIFI.md)
- [Theme and additional wallpaper packs](docs/WALLPAPERS.md)
- [Shared configuration example](config.example.toml) and
  [appearance overrides](appearance.example.toml)
- [Pinned component versions](manifest)

Every component below is installed from the pinned manifest:

| Repository | Purpose |
|---|---|
| [nirux](https://github.com/nirucon/nirux) | Installer, update/rollback, suite pins and session integration |
| [niruwm](https://github.com/nirucon/niruwm) | Window manager, workspaces, `niructl`, `niruidle` and session |
| [nirubar](https://github.com/nirucon/nirubar) | Per-monitor bar, panels, tray and tasks |
| [nirulauncher](https://github.com/nirucon/nirulauncher) | Applications, windows, search, settings and NIRU Actions |
| [nirudisplay](https://github.com/nirucon/nirudisplay) | Monitor layout, modes, rotation and profiles |
| [niruwallpaper](https://github.com/nirucon/niruwallpaper) | Wallpaper selection, scale, rotation and output |
| [niruthemeselector](https://github.com/nirucon/niruthemeselector) | Theme browsing and application |
| [nirunotify](https://github.com/nirucon/nirunotify) | Notification service and hardware OSD |
| [nirulock](https://github.com/nirucon/nirulock) | PAM lock screen |
| [niruscreensaver](https://github.com/nirucon/niruscreensaver) | Idle screen |
| [nirushot](https://github.com/nirucon/nirushot) | Screenshot capture, review and annotation |
| [niruclip](https://github.com/nirucon/niruclip) | Screen, region and camera recording with profiles and recovery |
| [niruwebapp](https://github.com/nirucon/niruwebapp) | Small isolated web-app windows |
| [nirufetch](https://github.com/nirucon/nirufetch) | NIRU-styled system summary |

NIRUX is provided without warranty. See [LICENSE](LICENSE).
