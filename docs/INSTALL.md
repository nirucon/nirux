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
other runtime tools. Super+P opens the native NIRU launcher. Rofi is not
installed by default; an explicit custom launcher command can still use it if
the user installs it. Use `--no-packages` only when those dependencies are
already installed; `--minimal` is an alias for the same behaviour, not a partial
suite.

```sh
./nirux install --browser helium
./nirux install --browser none
./nirux install --display-manager startx
./nirux install --display-manager sddm
./nirux install --display-manager lightdm
```

An existing display manager is preserved. If none exists, the interactive
default is startx; SDDM and LightDM can be selected explicitly. NIRUX-owned
greeters use the Niru Noir palette and the Rooted in Less wallpaper. An existing
`~/.xinitrc` is preserved.

When LightDM or SDDM is explicitly selected during installation, NIRUWM is the
first-login default on Debian, Arch and Void. LightDM uses a managed seat
default and GTK greeter default; SDDM is seeded only if it has no remembered
session. Existing remembered sessions are preserved. Keeping an existing
display manager or running an update does not reset its session selection.
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

## Desktop integration

NIRUX installs Noto Color Emoji, the four NIRU theme wallpaper sets and three extra wallpapers in
`~/Pictures/Wallpapers/NIRU`. Existing files are kept; edited wallpapers are
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
niructl audio outputs
niructl audio sources
niructl audio mute
niructl audio mic-status
niructl audio mic-mute on|off|toggle
niructl audio mic-level up|down|set N
```

The optional `microphone` bar module shows mute and input gain. Unmuted is not
reported as actively recording. Controls are also available through
`nirulauncher --microphone` and Super+Shift+P. WirePlumber and `wpctl` are
installed by NIRUX.

### Bluetooth

BlueZ is installed and the distribution Bluetooth service is enabled. Add
`"bluetooth"` to the bar modules to show adapter and connected-device state.

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

### Display profiles

Display profiles use `xrandr` and `~/.config/niruwm/displays.toml`.
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

A normal uninstall removes NIRUX-owned links, managed browser files, generated
session files and owned system integration, and restores backed-up system files.
Browser profiles and wallpaper pictures are kept.

`--purge` additionally removes unmodified NIRUX wallpapers and these documented
suite-owned configuration directories:

- `~/.config/niruwm`, `~/.config/niruui`
- `~/.config/nirubar`, `~/.config/nirulauncher`, `~/.config/nirunotify`
- `~/.local/state/niruwm`, `~/.local/state/nirulock`,
  `~/.local/state/niruscreensaver`
- `~/.cache/nirubar`

XDG paths are respected. OS packages, the chosen display manager, NIRUPI and
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
