# NIRUX

Install, update and remove the NIRU X11 desktop on **Arch Linux, Debian and
Void Linux (glibc, x86_64)**.

NIRUX provides the complete suite, its X11 session, themes, wallpapers,
terminal integration and the OS packages the components need. Niru Noir is the
default theme; Nord, Satie and Carl Larsson are also included.

## Suite

| Component | Role |
|---|---|
| [NIRUX](https://github.com/nirucon/nirux) | Installer, update, rollback, dependencies and system integration |
| [NIRUWM](https://github.com/nirucon/niruwm) | Window manager, session, `niructl` and `niruidle` |
| [NIRUBAR](https://github.com/nirucon/nirubar) | Per-monitor status bar and panels |
| [NIRUSCREENSAVER](https://github.com/nirucon/niruscreensaver) | Unlocked idle screen |
| [NIRULOCK](https://github.com/nirucon/nirulock) | PAM-based lock screen |
| [NIRULAUNCHER](https://github.com/nirucon/nirulauncher) | Keyboard-first application and action launcher |
| [NIRUNOTIFY](https://github.com/nirucon/nirunotify) | Native notifications and hardware OSD |
| [NIRUSHOT](https://github.com/nirucon/nirushot) | Screenshot capture, review, crop and annotation |

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

The installer provisions OS packages and the complete NIRU session. An existing
display manager is preserved; otherwise choose startx (default), SDDM or
LightDM. A fresh install offers the managed Helium browser and installs the
theme wallpapers, kitty/fish integration and terminal colours. User
configuration and NIRUPI are not overwritten.

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

Releases are checksummed and pinned. Updates switch program generations
atomically and keep the previous generation for rollback. Log out and in after
updates that change the session, window manager or idle daemon.

Default prefix: `~/.local`. Shared configuration:
`~/.config/niruwm/config.toml`. XDG paths are respected.

## Documentation

- [Installation and maintenance](docs/INSTALL.md)
- [Visual language](docs/STYLE.md)
- [Example configuration](config.example.toml)

MIT. Copyright 2026 Nicklas Rudolfsson.
