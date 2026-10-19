# NIRUX

Install and maintain the NIRU X11 desktop on **Void Linux glibc, Arch Linux and
Debian**, independently of NIRUPI. Current release binaries target x86_64/glibc.
Personal software for the author's machines, public for others to try.

Includes [niruwm](https://github.com/nirucon/niruwm),
[nirubar](https://github.com/nirucon/nirubar),
[niruscreensaver](https://github.com/nirucon/niruscreensaver) and
[nirulock](https://github.com/nirucon/nirulock), with Xorg, fonts and session
dependencies on a clean installation. Niru Noir is the default theme.

## Install

Run as your normal login user with sudo available:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

An existing display manager is preserved. Otherwise choose startx (default), SDDM
or LightDM. Existing configuration and NIRUPI are preserved. For an existing
desktop with dependencies installed: `./nirux install --no-packages`.

## Maintain

```sh
nirux update
nirux status
nirux doctor
nirux rollback
nirux uninstall             # add --purge to remove NIRU settings/state
```

Releases pin checksummed component assets and activate one program generation
atomically. Log out/in to activate updated WM/session/idle binaries; bar restart
is handled through the running WM. Default prefix: `~/.local`; XDG paths respected.

The 0.6.6 checkpoint includes filesystem/lock corrections, consistent key overrides,
helper reaping, full-monitor fullscreen and popup/reload pixmap cleanup.
[nirulauncher](https://github.com/nirucon/nirulauncher) and
[nirunotify](https://github.com/nirucon/nirunotify) remain design-stage components.

[Installation details](docs/INSTALL.md) · [Roadmap and handoff](ROADMAP.md) ·
[Code audit](AUDIT.md) · [Measurements](MEASUREMENTS.md)

MIT. Copyright 2026 Nicklas Rudolfsson.
