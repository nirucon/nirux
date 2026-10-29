# NIRUX

**A minimal, native X11 desktop built by me, for me.**

NIRUX is my personal desktop suite: a tiling window manager, keyboard-first
launcher, status bar, notifications, lock screen, screenshots, recording,
themes, wallpaper and display tools. It is heavily inspired by **dwm**, which I
used for many years, but it is not a dwm fork, a dwm configuration or a copy of
dwm. The layouts, session layer, bar, launcher and tools are their own code and
their own design.

I consider NIRUX an **early beta**. It is made for my own machines and my own
workflow. Others are welcome to test it at their own risk. I give no guarantees
of stability, data safety, compatibility or fitness for any purpose. Read the
installer and back up anything important before changing a working desktop.

## Supported systems

- **Arch Linux, Debian and Void Linux glibc**, x86_64.
- A normal user with `sudo`, network access and `git`.
- X11 with working graphics, drivers and firmware.
- Released binaries do not support Wayland, Void musl or other architectures.

NIRUX installs desktop runtime dependencies, not an operating system or GPU
drivers. It preserves existing user settings where possible.

## Install

Run as your normal desktop user, **not in a root shell**:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

The installer downloads versioned release assets and verifies their checksums.
The default prefix is `~/.local`. It preserves an existing display manager and
supports **startx, SDDM and LightDM**; choose NIRUWM when logging in. See
[installation](docs/INSTALL.md) for explicit session and package choices.

Use `--no-packages` only when the required runtime packages already exist.
Driver and firmware problems belong to the distribution, not to NIRUX.

## What is in the box

### Window management and session

- **NIRUWM:** eight layouts: tile, left, monocle, centered, centered-floating,
  fibonacci, floating and Scroll.
- Per-monitor workspaces and per-workspace layouts.
- Floating windows, fullscreen, scratchpad, gaps, master count and master ratio.
- **Sticky windows:** `Super+Alt+S` keeps the focused window visible on every
  workspace of its monitor. The same key turns sticky off again.
- Window rules for floating, centered, workspace, sticky and compositor opacity.
- Session state, saved window placement, display profiles and safe recovery.
- **Scroll layout:** one window per column, one or two adjacent columns visible;
  `Super+Ctrl+S` selects Scroll and `Super+Ctrl+Shift+S` toggles columns.

### Bar and panels

- **NIRUBAR:** per-monitor workspace cells, title, media, volume, microphone,
  brightness, network, Wi-Fi, battery, mode, tasks, updates and calendar.
- Optional **Tailscale** peers module, placed before network and visible only
  when Tailscale is installed.
- **Quick Settings:** opens from the gear icon and brings volume, microphone,
  Wi-Fi, Bluetooth, displays, power profile, themes, DND, idle inhibition,
  night light and lock into one launcher view.
- XEmbed and D-Bus StatusNotifierItem trays with real icons and menus.
- Clickable panels and a narrow-width overflow menu.

### Launcher, keyboard and clipboard

- **NIRU Launcher:** applications, windows, NIRU Actions, web search, Wi-Fi,
  Bluetooth, displays, power, themes, sound, timing, input, screenshots and
  recording.
- **Alt+Tab / Super+grave:** window switcher and workspace-grouped overview.
- **Super+V:** local clipboard history. Entries are stored under
  `~/.local/state/niru/clipboard.json`, capped at 200 entries, filtered for
  obvious secrets and never uploaded.
- **Super+P:** applications. **Super+A:** NIRU Actions. **Super+Shift+P:**
  applications, windows, actions and settings in one view.
- Deterministic English phrases such as “lock”, “focus mode”, “do not disturb”
  and “volume up” resolve to the same native actions. Additional language
  aliases are documented in [NIRU Actions](docs/ACTIONS.md). No account, model
  or network request is required.

### Themes, wallpaper and display

- **NIRU Theme Selector** and **NIRU Wallpaper** with graphical previews.
- Ten built-in NIRUX themes and custom user themes.
- Wallpaper scale, rotation, output selection and follow-theme behaviour.
- **NIRU Display:** stable screen numbers, EDID identity, frozen drag, snapping,
  zoom/pan, mirror grouping and safe preview transactions.

### Notifications, lock and media

- **NIRUNOTIFY:** native notifications, DND, history, clipboard-safe OSDs and
  optional event sounds.
- **NIRULOCK:** PAM-backed lock screen with minimal, terminal, runic and corner
  layouts.
- **NIRUSCREENSAVER:** idle screen with configurable inactivity and lock timing.
- **NIRUSHOT:** full-screen, region and window capture with review/annotation;
  the original capture is always copied to the clipboard.
- **NIRUCLIP:** screen, region or camera recording with microphone, desktop
  audio, overlays and profiles.

### Event sounds

NIRUX has four short audio cues: startup, notification, NIRUX update and
shutdown. They are enabled by default at 35% volume and are easy to change:

```sh
nirux sounds status
nirux sounds off
nirux sounds on
nirux sounds toggle notification
nirux sounds test startup
```

Configuration lives in `~/.config/nirux/sounds.toml`. Sounds respect system mute;
notification sounds are rate-limited. Apps in `notification_exclude_apps` still
show their text notifications and history but do not play the notification cue.
Startup/shutdown sounds are part of the session and need a new login after an
update.

### Optional suite extras

These are suite-adjacent applications, but they are **not** part of the core
manifest and are never installed by a normal `nirux update`:

```sh
nirux extras list
nirux extras select niruflow
nirux extras install niruflow
nirux extras update
```

Available extras:

- **NIRUORG** — file and folder management.
- **NIRUNOTE** — minimal Markdown editor.
- **NIRUPRES** — presentation studio.
- **NPLAY** — terminal music, radio and podcast player.
- **NIRUFLOW** — local maintenance and automation.

## Key bindings at a glance

| Binding | Action |
|---|---|
| `Super+P` | Applications |
| `Super+A` | NIRU Actions |
| `Super+Shift+P` | Applications, windows, actions and settings |
| `Alt+Tab` | Window switcher |
| `Super+grave` | Workspace overview |
| `Super+V` | Clipboard history |
| `Super+Alt+S` | Toggle sticky for the focused window |
| `Super+Ctrl+S` | Scroll layout |
| `Super+Ctrl+Shift+S` | Toggle Scroll columns |
| `Super+Shift+Space` | Toggle floating |
| `Super+Shift+E` | Toggle fullscreen |
| `Super+Shift+S` | Scratchpad |
| `Super+Shift+R` | Reload configuration |

The launcher’s keybinding view always shows the effective shortcuts, including
local overrides.

## Update, rollback and activation

```sh
~/.local/bin/nirux update
~/.local/bin/nirux status
```

Updates keep a previous program generation for rollback. Settings and custom
content are preserved according to installer ownership rules. Follow the
activation message: **log out and back in when WM/session programs change.**
Restarting a bar alone does not activate a new running window manager, although
the bar can normally be restarted with `niructl restart-bar`.

```sh
~/.local/bin/nirux rollback
```

Rollback restores the previous program generation; it is not a backup of
personal files or operating-system packages.

## Removal

```sh
~/.local/bin/nirux uninstall
```

Use `nirux --help` and [installation/removal details](docs/INSTALL.md) before
using `--purge`. Purge removes additional managed configuration/state and is not
a lossless undo of every change.

## Documentation and components

- [Installation, session choices and troubleshooting](docs/INSTALL.md)
- [NIRU Actions, tasks and optional OpenCode](docs/ACTIONS.md)
- [Input settings](docs/INPUT.md)
- [Wi-Fi backends and limitations](docs/WIFI.md)
- [Theme and additional wallpaper packs](docs/WALLPAPERS.md)
- [Browser addons](docs/BROWSER-ADDONS.md)
- [Optional extras](docs/EXTRAS.md)
- [Shared configuration example](config.example.toml) and
  [appearance overrides](appearance.example.toml)
- [Pinned component versions](manifest)

Core components come from the pinned manifest:

| Repository | Purpose |
|---|---|
| [nirux](https://github.com/nirucon/nirux) | Installer, update/rollback, suite pins and session integration |
| [niruwm](https://github.com/nirucon/niruwm) | Window manager, workspaces, `niructl`, `niruidle`, clipboard and gesture helpers |
| [nirubar](https://github.com/nirucon/nirubar) | Per-monitor bar, panels, Quick Settings, tray, Tailscale and tasks |
| [nirulauncher](https://github.com/nirucon/nirulauncher) | Applications, windows, overview, clipboard, settings and NIRU Actions |
| [nirudisplay](https://github.com/nirucon/nirudisplay) | Monitor layout, modes, rotation and profiles |
| [niruwallpaper](https://github.com/nirucon/niruwallpaper) | Wallpaper selection, scale, rotation and output |
| [niruthemeselector](https://github.com/nirucon/niruthemeselector) | Theme browsing and application |
| [nirunotify](https://github.com/nirucon/nirunotify) | Notification service, DND and hardware OSD |
| [nirulock](https://github.com/nirucon/nirulock) | PAM lock screen |
| [niruscreensaver](https://github.com/nirucon/niruscreensaver) | Idle screen |
| [nirushot](https://github.com/nirucon/nirushot) | Screenshot capture, review and annotation |
| [niruclip](https://github.com/nirucon/niruclip) | Screen, region and camera recording with profiles and recovery |
| [niruwebapp](https://github.com/nirucon/niruwebapp) | Small isolated web-app windows |
| [nirufetch](https://github.com/nirucon/nirufetch) | NIRU-styled system summary |

## Release policy

The current release and the previous two functional releases are the supported
window. Older releases are historical and may contain bugs fixed in later
versions. Git tags and commits remain as release evidence; old GitHub Releases
and assets may be removed during cleanup. A version with a known broken asset is
not kept merely because its number is recent.

NIRUX is provided without warranty. See [LICENSE](LICENSE).
