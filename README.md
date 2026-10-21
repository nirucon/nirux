# NIRUX

Install and maintain the small NIRU X11 desktop on **Void Linux glibc, Debian
and Arch Linux**. Release binaries target **x86_64/glibc**.

Includes niruwm, niructl, niruidle, nirubar, niruscreensaver, nirulock,
nirulauncher and nirunotify, plus Xorg, kitty/fish, theme wallpapers, the NIRU
terminal colours and a graphical Polkit agent for power actions. Niru Noir is the
default theme; Nord, Satie and Carl Larsson are also available.

**0.10.60 status:** adds optional microphone/Bluetooth/power-profile modules plus built-in display
profiles. NIRUX provisions BlueZ and power-profiles-daemon and enables their
services; profile changes validate provider capability before applying.
The suite includes managed Helium, kitty/fish integration, themed panels and
greeters, dwm-style mouse controls, workspace autostart, diagnostics, work modes
and recipes. See [microphone setup](docs/INSTALL.md#microphone-module).
The target installer owns config/integration/activation, so an update
applies new config keys, assets and components in one pass. Fresh installs get
the four NIRU theme wallpaper sets under
`~/Pictures/Wallpapers/NIRU`; changing the theme can switch to that theme's
wallpaper while custom files, rotation and `mode = "single"` remain preserved.
See the [visual language](docs/STYLE.md) and the [current roadmap](ROADMAP.md) for remaining acceptance work
and exact verification limits.

## Prerequisites

- **x86_64 with glibc.** Supported: Arch Linux, Debian and Void glibc. Void musl
  and ARM are not supported by the released binaries.
- **A normal user with sudo already installed and configured.** NIRUX needs it
  for OS packages and system integration; it cannot bootstrap sudo itself.
- **Working network access** (and `git` if you clone the repository). NIRUX
  installs `curl`/CA certificates and downloads checksummed release assets.
- **Working graphics, Wi-Fi and other hardware drivers/firmware.** These remain
  the OS/hardware installation's responsibility; NIRUX does not install
  proprietary NVIDIA drivers or missing firmware.
- **A display path.** An existing display manager is preserved; otherwise the
  install offers startx (default), SDDM or LightDM.

`--no-packages` is only for machines where all runtime dependencies already
exist. Audio/PipeWire, PAM, fonts, cursors, screenshots and the session bus are
provisioned by a normal install. See [installation details](docs/INSTALL.md) for
the exact scope and hardware limits.

## Install

Run as your normal login user with sudo available:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

An existing display manager is preserved. Otherwise choose startx (default), SDDM
or LightDM. Selecting SDDM or LightDM installs a matching NIRU Noir greeter with
the Rooted in Less wallpaper; a NIRU login shows a short themed welcome.
A fresh install offers the managed Helium browser (default installed)
and remembers the choice. It also installs the four theme wallpaper sets plus
three extra NIRUX wallpapers under
`~/Pictures/Wallpapers/NIRU`, kitty with fish, a fast fish prompt/completions,
and terminal colours that follow the active theme. Existing settings,
wallpapers, kitty/fish configs and browsers are preserved; NIRUPI is a separate
installation. Use `--no-packages` only when runtime dependencies are already
installed.

```sh
./nirux install --browser helium
./nirux install --browser none    # persistent opt-out
./nirux update --browser helium   # enable later without editing config
```

## Maintain

```sh
~/.local/bin/nirux update
~/.local/bin/nirux status
~/.local/bin/nirux doctor
~/.local/bin/nirux rollback
~/.local/bin/nirux uninstall   # --purge also removes documented NIRU settings
```

Checksummed releases pin component versions and switch one program generation
atomically. Log out/in after updates to activate the WM, session and idle daemon.
Default prefix: `~/.local`; shared config: `~/.config/niruwm/config.toml`.
XDG paths are respected. The session adds its bin directory to PATH.

[Installation](docs/INSTALL.md) · [Roadmap / AI handoff](ROADMAP.md) ·
[Restart prompt](docs/NEXT-SESSION.md) ·
[Current review](docs/REVIEW-2026-10-20-RESTART.md) · [Baseline audit](AUDIT.md) ·
[Measurements](MEASUREMENTS.md)

MIT. Copyright 2026 Nicklas Rudolfsson.
