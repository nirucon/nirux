# Installation and maintenance

NIRUX installs and maintains the NIRU X11 desktop on **Arch Linux, Debian and
Void Linux (glibc, x86_64)**. It provisions the suite, the X11 session, themes,
wallpapers, terminal integration and the OS packages the components need.

Distribution graphics drivers and firmware remain the responsibility of the OS
installation. Void musl and non-x86_64 systems are not supported by the released
binaries.

## Install

Run as your normal login user with `sudo` available:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

A normal install provisions Xorg/startx, D-Bus, PAM, Polkit, fonts, kitty, fish,
pcmanfm, audio, notifications, screenshots, Bluetooth, power profiles and the
other runtime tools. Super+P opens the native NIRU launcher. Use
`--no-packages` only when those dependencies are already installed; `--minimal`
is an alias for the same behaviour, not a partial suite.

```sh
./nirux install --browser helium
./nirux install --browser none
./nirux install --display-manager startx
./nirux install --display-manager sddm
./nirux install --display-manager lightdm
./nirux install --browser none --localsend no --opencode no
```

Helium, LocalSend and OpenCode are optional. A fresh interactive install asks
about each; noninteractive installs default to enabled. Use `--browser`,
`--localsend yes|no` and `--opencode yes|no` to decide explicitly. The choice is
persisted and respected by `nirux update`.

Remove one managed app without removing the desktop:

```sh
nirux remove helium
nirux remove localsend
nirux remove opencode
```

External installations and user files are never removed.

An existing display manager is preserved. If none exists, the interactive
default is startx; SDDM and LightDM can be selected explicitly. NIRUX-owned
greeters use the selected theme palette and its matching wallpaper, with the
login panel centred in the lower part of the screen. An existing
`~/.xinitrc` is preserved.

When LightDM or SDDM is explicitly selected during installation, NIRUWM is the
first-login default on Debian, Arch and Void. LightDM uses a managed seat
default and GTK greeter default; SDDM is seeded only if it has no remembered
session. Existing remembered sessions are preserved. Keeping an existing
display manager or running an update does not reset its session selection.
The LightDM GTK greeter's top panel cannot centre a clock reliably between the
host and session groups, so NIRUX leaves the clock out rather than showing an
off-centre time. Use the NIRUX SDDM greeter when a clock is required.
The SDDM theme selects the installed Qt5/Qt6 greeter and resolves its images
from the theme directory rather than the shared SDDM component directory.
Display managers selected by NIRUX start only after the program generation is
active, including Void's immediately-starting runit service links.

Package installation refreshes a running system D-Bus configuration and input
device rules before the first desktop starts. This lets newly created service
accounts (such as `polkitd`) use their bus policies, and lets the greeter use
the system's configured X11 keyboard layout without requiring a reboot. No
Swedish layout is forced on the greeter: Debian's `/etc/default/keyboard` and
the equivalent distribution configuration remain authoritative. On Arch and
Void, a console-only keymap is not a substitute for configuring the X11 layout.
The system bus is reloaded,
never restarted; on Void a bus that is not yet running reads fresh policies
when its service starts. Debian's temporary package policy defers only LightDM
and SDDM, while delegating other services to any existing administrator policy.

If an earlier LightDM installation opens only a terminal, choose **NIRUWM** in
the greeter's session menu before logging in. Debian's **Default Xsession** is
not NIRUWM; the greeter remembers the corrected choice. The suite is installed
as release programs under `~/.local/bin` and `~/.local/share/nirux`, not as
component source repositories under `~/Git`.

Power actions use the shared systemd-logind/elogind login1 D-Bus API with
normal Polkit authorisation and inhibitor checks. Systemd's `loginctl` is a
session-control tool, not a shutdown/reboot command; elogind's extra power
verbs must not be assumed on Debian or Arch. NIRUWM 0.16.60 corrects that
backend choice. NIRULAUNCHER 0.2.12 also waits for the WM to map its window
before grabbing input/focus, avoiding startup `SetInputFocus`/`BadMatch` errors.

From a local TTY:

```sh
startx "$HOME/.local/bin/niruwm-session"
```

Do not run startx over SSH.

## Browser

Helium is the managed browser option. NIRUX downloads the pinned official
archive, verifies its checksum and version, and installs an owned desktop entry.
The browser profile is never rewritten.

```sh
./nirux install --browser helium
./nirux install --browser none
./nirux update --browser helium
./nirux update --browser none
```

An update keeps the recorded policy when no browser flag is given. An existing
browser outside NIRUX is left untouched.

## Standard folders

A normal install includes `xdg-user-dirs`. On a fresh home it creates the
locale-appropriate Documents, Downloads, Music, Pictures and Videos folders.
Desktop, Templates and PublicShare are disabled by default; if they are still
the empty XDG defaults they are removed. Existing custom paths, localized
names, symlinks and non-empty directories are preserved. NIRUX does not add
English aliases or move files. Missing configured folders are created, while a
conflicting regular file is reported and left untouched.

## Desktop integration

NIRUX installs Noto Color Emoji, Liberation (metric-compatible Arial/Times/
Courier substitutes), Noto Sans/Serif core fonts and, when selected, the ten NIRU
theme wallpaper sets in `~/Pictures/Wallpapers/NIRU`. A fresh install fetches the
selected set before starting the first session; a download started from an
already running session refreshes that session's theme when it completes. This
gives clean installs a useful web-font fallback instead of relying entirely on DejaVu/Nimbus. The CJK/Indic/Arabic Noto
extras are deliberately not installed by default because of their size. Existing files are kept; edited wallpapers are
never overwritten. The directory can be changed with `XDG_PICTURES_DIR` or
`[wallpaper] theme_dir`.

```toml
[wallpaper]
enabled = true
mode = "random"
rotation_minutes = 10
follow_theme = true
theme_dir = "~/Pictures/Wallpapers/NIRU"
```

Kitty uses fish inside the terminal without changing the login shell. Existing
kitty/fish configuration is preserved through managed blocks with backups.
NIRUX adds fish completions, a two-line prompt, `nirux-update` and theme colours
under `~/.config/nirux/theme/`.

Mouse controls: **Super+left-drag** moves a window, **Super+right-drag** resizes
from the nearest corner, and **Super+Shift+Space** toggles floating.

**Super+S** opens the dedicated web search: every engine is listed before you
type, an alias such as `gh niruwm` searches one engine, and a typed `https://`
address is offered as **Open address**. **Super+Shift+P** finds NIRUX Settings,
which also lists the effective keybindings and the idle/lock timers.
**Super+Escape** locks the screen. **Super+Shift+Escape** locks, keeps the lock
screen visible for three seconds and then suspends; unlocking during that delay
cancels the suspend.

## Configuration

Shared window manager and bar settings live in
`~/.config/niruwm/config.toml`. Start from [config.example.toml](../config.example.toml).
The optional `~/.config/niruwm/appearance.toml` carries semantic colours, font,
spacing, focus width and reduced motion for the suite. A theme file in
`~/.config/niruwm/themes/NAME.toml` takes precedence. See
[STYLE.md](STYLE.md).

Updates add new defaults to an existing configuration without rewriting user
values. Invalid files are rejected before the active configuration or program
generation changes. `niruwm --check-config` and `nirubar --check-config` validate
without applying.

## Suite features

### Notifications

The provider defaults to native NIRUNOTIFY when installed, with Dunst as the
fallback. Colours follow the active NIRUWM theme and update with
`niructl theme` or `niructl reload`.

```sh
niructl dnd on|off|toggle|status
nirunotify --history
nirunotify --osd volume 45
```

### Audio and microphone

```sh
niructl audio status --json
niructl audio outputs --json
niructl audio sources --json
niructl audio mute
niructl audio mic-status --json
niructl audio mic-mute on|off|toggle
niructl audio mic-level up|down|set N
niructl audio mic-test 5 --json
nirulauncher --sound
```
The Sound panel shows output volume/mute, input gain/mute, active streams and a
local five-second microphone test with peak/RMS/clipping feedback. `Test
microphone` is never automatic; temporary recordings are removed when the panel
closes. The same controls are available from Super+Shift+P and Super+A.

The optional `microphone` bar module shows mute and input gain. Unmuted is not
reported as actively recording. Controls are also available through
`nirulauncher --microphone` and Super+Shift+P. WirePlumber and `wpctl` are
installed by NIRUX.

### Capture and NIRUCLIP

NIRUX installs `ffmpeg`, `slop`, `maim`, `v4l-utils`, `xclip` and X11 tools.
NIRUCLIP 0.2 is a static native recorder that owns its process and a versioned
state file; NIRUSHOT remains the one-shot screenshot tool.

```sh
niruclip --full --audio mic
niruclip --region --webcam corner --webcam-size medium
niruclip --webcam-only --audio mic
niruclip --profile screen-camera
niruclip --stop
niruclip --status --json
niruclip --recover
```

The launcher exposes **Capture** actions through `nirulauncher --clip`, including
the built-in profiles `screen-mic`, `screen-camera`, `camera-mic` and
`screen-desktop`. `niruclip --list-profiles` lists saved profiles;
`--save-profile NAME` stores the current choices under
`$XDG_CONFIG_HOME/niruclip/config.toml`. A valid interrupted partial is offered
as `recover`; a failed startup is shown as `failed`, not as false recovery.
Add `"recording"` to the NIRUBAR modules for the active timer, stop and recovery
indicator. `--no-packages` never installs the optional Papirus icon theme.

### Bluetooth

NIRUX installs BlueZ and the PipeWire BlueZ SPA package
(`libspa-0.2-bluetooth` on Debian; the native PipeWire package on Arch and `libspa-bluetooth` on Void).
The distribution Bluetooth service must remain enabled. Add `"bluetooth"` to the
bar modules to show adapter and connected-device state.

```sh
niructl bluetooth status
niructl bluetooth list
niructl bluetooth power on|off|toggle
niructl bluetooth connect MAC
niructl bluetooth disconnect MAC
nirulauncher --bluetooth
```

Pairing and discovery remain explicit actions through the distribution
Bluetooth manager or `bluetoothctl`.

### Power profiles

`power-profiles-daemon` is installed and enabled. Add `"powerprofile"` to the
bar modules to show the active profile.

```sh
niructl powerprofile status
niructl powerprofile list
niructl powerprofile set balanced
niructl powerprofile next
nirulauncher --power
```

Only profiles reported by the provider are offered. NIRUX does not switch
profiles automatically based on battery state.

### Themes

`niructl theme NAME` remains the fast textual theme switch. Run
`niruthemeselector` for the graphical browser, or open **Appearance and themes**
in NIRUX Settings. User themes live in `~/.config/niruwm/themes/`; bundled
themes can be hidden, and imported themes can be removed without deleting
external wallpaper files.

### Display profiles

Display profiles use `xrandr` and `~/.config/niruwm/displays.toml`. Run
`nirudisplay` for the graphical editor, or use the launcher's Displays view.
`niructl display startup set NAME` opts into applying a profile once at login;
`niructl display startup off` disables it.
[displays.example.toml](../displays.example.toml) contains Laptop, Desk and
Presentation templates.

```sh
niructl display save Laptop
niructl display list
niructl display preview Desk 15
niructl display keep
niructl display revert
niructl display status
```

Preview restores the previous layout after the deadline or on failure. Only
connected outputs and supported modes are accepted.

### Night light and brightness

`[nightlight] mode` accepts `manual`, `fixed` or `solar`. Fixed uses local
`on`/`off` times; solar computes sunrise and sunset from the configured
coordinates. Manual keeps the Super+N toggle.

```sh
niructl nightlight apply|watch|status
niructl brightness up|down
```

`[brightness] device` selects the brightnessctl device and `step` sets the
increment. NIRUX adds the installing account to the `video` group when it
exists, because brightnessctl's udev rule grants that group access to the
backlight. Log out and in after the first install before using the brightness
keys. `nirux doctor` reports a backlight that brightnessctl cannot read.

### nirufetch

`nirufetch` prints a local NIRU-styled system summary: OS, kernel, uptime,
shell, WM, terminal, CPU, memory, disk and active theme. It reads local files
only and has no network or daemon.

```sh
nirufetch
nirufetch --plain
```

### Webapps

`niruwebapp` creates normal desktop applications backed by an already installed
Helium/Chromium browser. Each app gets an owned desktop entry, a stable ID and a
dedicated profile by default. No Electron, WebView runtime or browser is
installed.

```sh
niruwebapp create "YouTube Music" https://music.youtube.com
niruwebapp list
niruwebapp launch "YouTube Music"
niruwebapp icon youtube-music ~/Pictures/yt.png
niruwebapp edit youtube-music --shared-profile
niruwebapp edit youtube-music --isolated-profile
niruwebapp remove youtube-music --delete-profile
```

`--shared-profile` uses the browser's ordinary session; `--isolated-profile`
returns to a dedicated profile. Switching keeps the old profile on disk, so it
is non-destructive. `--icon` and `icon` accept PNG, SVG, XPM or JPEG; owned
icons are removed with the launcher. Removing a launcher keeps its profile
unless `--delete-profile` is explicit.

### OpenCode

A normal install downloads the pinned official OpenCode V2 native CLI and
installs `opencode` under the NIRUX prefix. It does not install npm, start a
service, create a session, authenticate or modify existing OpenCode config.
An existing unmanaged `opencode` command is left untouched.

```sh
opencode --version
```

The binary is an external managed app, like LocalSend, so `nirux rollback`
does not roll it back. Updates replace it only when the NIRUX release pins a new
version. Use `--no-packages` does not skip this download; it is controlled by
the OpenCode pin in the release.

### LocalSend

A normal install downloads the official LocalSend Linux tarball, verifies its
SHA-256, and installs it under the NIRUX prefix with a desktop entry. Flatpak is
not used. The default NIRUWM rule opens the main window floating and centered;
child dialogs remain separate. LocalSend uses the local network directly and
does not require a NIRUX-managed service or a firewall change. Discovery and
transfers remain LocalSend's responsibility.

### Login wallpaper

The NIRUX login screen uses the same wallpaper set as the desktop. Choose any
installed NIRUX wallpaper:

```sh
nirux login-wallpaper list
nirux login-wallpaper set nirux-wallpaper-nord-8k.png
nirux login-wallpaper reset
```

The choice applies to the installed SDDM and/or LightDM greeter, survives
updates, and is stored under `~/.config/nirux/`. By default the login screen
uses the wallpaper of the currently selected NIRUX theme (Noir, Nord, Satie,
Carl Larsson, Forest Vigil, Blood of Urdr, Root and Stone, Blue Horizon,
The Norns or Winter Nights).
`reset` returns to that theme wallpaper.

NIRUX installs the default theme's wallpaper and offers the other nine with
`nirux wallpapers download`; see [Wallpapers](../README.md#wallpapers). Any
other PNG in `~/Pictures/Wallpapers/NIRU` appears in both
`nirux login-wallpaper list` and `niructl wallpaper list` without changing
NIRUX.

### File manager, removable media and archives

A normal install provisions `udisks2`, GVFS and the GVFS backends for MTP,
SMB/CIFS, Apple devices and FUSE mounts, plus `xarchiver`, 7-Zip, ZIP and RAR
support and `exfatprogs`. PCManFM can therefore show removable media, phones and
network shares through the normal GVFS/udisks2 path. Arch enables `udisks2` and
Void creates the runit service link; Debian uses D-Bus activation.

### Optional Papirus icons

Papirus is intentionally opt-in because the theme is about 112–190 MB per
distribution and is copied into the user's `~/.local/share/icons/Papirus-Dark`.
Select `--icons papirus` (or answer yes during an interactive install) to install
Papirus-Dark with grey folders. The GTK3, GTK4 and GTK2 icon settings and the
GSettings icon theme are updated for the installing user, and the local icon
cache is refreshed. Choose `--icons none` to opt out; an existing local Papirus
installation is left untouched. `papirus-folders` is not required.

### Fonts

The suite default font is configured in `~/.config/niruwm/appearance.toml`:

```toml
[font]
size = 15.0
path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
```

NIRUBAR and NIRULAUNCHER use this as their fallback when their own config does
not set `font_size`/`font_path`. Per-component overrides remain in
`~/.config/niruwm/config.toml` and `~/.config/nirulauncher/config.toml`.

### Compositor and transparency

The session starts picom when installed. `niructl compositor status|on|off|toggle`
controls it and Super+Shift+P exposes the same toggle under Appearance. Inactive
window transparency and shadows live in `~/.config/picom.conf`; NIRUX does not
rewrite an existing file. A conservative starting point is:

```ini
inactive-opacity = 0.94;
active-opacity = 1.0;
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.35;
```

### Screenshots

Super+Print captures the full screen, Print selects a region and
Super+Shift+Print captures the active window. NIRUSHOT opens a floating review
dialog with crop, rectangle, arrow, mask, zoom and pan.

```sh
nirushot --region
nirushot --full
nirushot --window
nirushot --region --delay 3
nirushot --region --save ~/Pictures/shot.png
nirushot --full --copy
```

`--save` writes the chosen file; `--copy` skips review and copies directly.
Cancel leaves no file. Notifications use the active NIRUNOTIFY/Dunst provider.

### Power actions

NIRUX installs a Polkit agent and a narrow rule that lets the installing NIRUX
account, plus local active users in `wheel` or `sudo`, power off, reboot or
suspend without a password. Remote sessions and other identities still
authenticate normally.

## Reset configuration

To restore the complete shared NIRUWM/NIRUBAR configuration to the current
NIRUX example, including the numbered/icon/text workspace presets:

```sh
nirux reset-config
```

A `.nirux-backup` copy is kept next to the file. The standalone equivalent is:

```sh
niruwm --reset-config
```

This intentionally discards local overrides such as theme, browser, key
bindings and bar layout. NIRUBAR's narrower `--reset-config` only resets the
`[bar]` table.

## Upgrading from NIRUPI/dwm

Old installs may keep a `~/.xinitrc` or SDDM session selection that points to
a NIRUPI/dwm session this suite no longer provides. NIRUX backs up and repairs
only those known legacy choices; a custom session file is left untouched.
`nirux update` does this automatically. To run the repair explicitly:

```sh
nirux repair-session
```

The backup is `~/.xinitrc.nirux-backup` or
`/var/lib/sddm/state.conf.nirux-backup`. If the session still fails, inspect
`~/.local/state/niruwm/session.log` and `~/.xsession-errors`.

## Update and rollback

```sh
nirux update
nirux rollback
```

Releases contain the installer, a version manifest and `SHA256SUMS`. The manifest
pins every component. Updates verify downloads, check required shared libraries
and versions, install missing runtime packages, then switch generations
atomically. A failed checksum, package step or version check keeps the previous
generation.

Generations live in `~/.local/share/nirux/generations`; `~/.local/bin` points
through one `current` link. Rollback restores program files, not OS packages or
PAM configuration. Settings are not overwritten on update.

Use `nirux update --no-packages` to skip package provisioning. The window
manager, idle daemon and session changes take effect after a new login;
`niructl reload` reloads configuration and `niructl restart-bar` restarts the bar.

## Diagnostics

```sh
nirux status
nirux doctor
```

`status` checks installed programs, system integration, PAM files and
permissions. `doctor` also checks launch tools, configured commands, component
settings and the live control channel when `DISPLAY` is set. From SSH or a TTY
the live-session check is reported as skipped.

## Uninstall

```sh
nirux uninstall
nirux uninstall --purge
```

A normal uninstall removes NIRUX-owned links, managed Helium, LocalSend and
OpenCode files, generated session files and owned system integration, and
restores backed-up system files. Browser profiles, app settings and wallpaper
pictures are kept.

`--purge` additionally removes unmodified NIRUX wallpapers and these documented
suite-owned configuration directories:

- `~/.config/niruwm`, `~/.config/niruui`
- `~/.config/nirubar`, `~/.config/nirulauncher`, `~/.config/nirunotify`
- `~/.local/state/niruwm`, `~/.local/state/nirulock`,
  `~/.local/state/niruscreensaver`
- `~/.cache/nirubar`

Normal uninstall keeps user themes in `~/.config/niruwm/themes/`. An explicit
`--purge` removes suite configuration directories, including user theme files;
back them up first.

XDG paths are respected. OS packages, the chosen display manager and
unrelated files are retained.

`NIRUX_PREFIX` changes the install prefix (default `$HOME/.local`). Use the same
prefix for later commands.

## Tests

```sh
sh tests/integration.sh
sh tests/release-smoke.sh
```

`integration.sh` runs isolated install, update, rollback and uninstall checks
against all three distribution mappings. `release-smoke.sh` tests the real pinned
releases through startx in an isolated home and requires Xvfb and the runtime
dependencies. CI additionally installs the vanilla package lists on Arch, Debian
and Void, runs a normal-user Helium sandbox and exercises the generated session.

MIT. Copyright 2026 Nicklas Rudolfsson.
