# NIRUX

Install and maintain the small NIRU X11 desktop on **Void Linux glibc, Debian
and Arch Linux**. Release binaries target **x86_64/glibc**.

Includes niruwm, niructl, niruidle, nirubar, niruscreensaver, nirulock,
nirulauncher and nirunotify, plus Xorg and runtime dependencies. Niru Noir is the
default theme; Nord, Satie and Carl Larsson are also available.

**0.10.33 status:** managed Helium, theme wallpapers and theme-follow settings
are implemented. Fresh installs get the four NIRU theme wallpaper sets under
`~/Pictures/Wallpapers/NIRU`; changing the theme can switch to that theme's
wallpaper while custom files, rotation and `mode = "single"` remain preserved.
See the [current roadmap](ROADMAP.md) for remaining S03/S04/H01 acceptance work
and exact verification limits.

## Install

Run as your normal login user with sudo available:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

An existing display manager is preserved. Otherwise choose startx (default), SDDM
or LightDM. A fresh install offers the managed Helium browser (default installed)
and remembers the choice. It also installs the four theme wallpaper sets under
`~/Pictures/Wallpapers/NIRU`. Existing settings, wallpapers and browsers are
preserved; NIRUPI is a separate installation. Use `--no-packages` only when
runtime dependencies are already installed.

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
