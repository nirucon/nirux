# The NIRUX manual

How to use and maintain the NIRUX desktop: the window manager, bar, launcher, lock
screen, capture tools, themes, displays, sound, updates and extras, with the exact
keys, commands and settings.

This manual ships with every NIRUX release and is installed with the programs, so it
describes the version you have and works offline. Open it with `nirux manual`, a
chapter or heading with `nirux manual TOPIC` (for example `nirux manual lock`), or
from the launcher's Manual view. In NIRUNOTE, `Ctrl+G` goes to a heading.

## Chapters

| | Chapter | What it covers |
|---|---|---|
| 1 | [Getting started](01-getting-started.md) | Install, first login, the essential keys, the cheat sheet |
| 2 | [Windows and layouts](02-windows-and-layouts.md) | Tiling, the eight layouts, floating, fullscreen, swallowing, urgency |
| 3 | [Workspaces, monitors and scratchpads](03-workspaces-monitors-scratchpads.md) | Workspaces per monitor, moving windows, the scratchpads |
| 4 | [The bar and Quick Settings](04-bar-and-quick-settings.md) | Bar modules, Quick Settings, calendar, tray |
| 5 | [The launcher](05-launcher.md) | Apps, NIRU Actions, files, emoji, calculator, web search, clipboard, settings views |
| 6 | [Lock screen and screensaver](06-lock-and-screensaver.md) | Lock, idle timers, CAVA, quotes, SID pause music |
| 7 | [Screenshots and recording](07-screenshots-and-recording.md) | NIRUSHOT, OCR, the color picker, NIRUCLIP recording |
| 8 | [Themes and wallpapers](08-themes-and-wallpapers.md) | Themes, theme packs, appearance, wallpapers, login wallpaper |
| 9 | [Displays and profiles](09-displays.md) | NIRU Display, profiles, automatic switching, rotation, night light |
| 10 | [Sound, notifications and studio mode](10-sound-notifications-studio.md) | Volume, microphone, event sounds, notifications, DND, studio mode |
| 11 | [Keeping NIRUX up to date](11-updates.md) | Update, rollback, snapshots, fleet, sync, the GitLab mirror |
| 12 | [Extras](12-extras.md) | NIRUNOTE, NIRUORG, NIRUPRES, NPLAY, NIRUAMP, NIRUFLOW, NIRUSEC, NIRUGAME, NIRUREMOTE, NIRUDICTATE |
| 13 | [Troubleshooting](13-troubleshooting.md) | Status, doctor, logs, common problems |
| 14 | [Configuration reference](14-configuration-reference.md) | Every configuration file and key (generated) |
| 15 | [Key bindings](15-key-bindings.md) | Every default key binding (generated) |
| 16 | [Command reference](16-commands.md) | `nirux` and `niructl` commands |

## Conventions

- `Super` is the Windows key. `Super+Shift+S` means hold Super and Shift, press S.
- On Swedish and similar keyboard layouts `/` is `Shift+7`, so bindings with `/` are
  written with their alternative (`Super+F1` for the cheat sheet).
- `~/.config` stands for `$XDG_CONFIG_HOME`, `~/.local/state` for `$XDG_STATE_HOME`.
- Commands run as your normal user in a terminal (`Super+Enter`). `niructl` needs a
  running NIRUWM session.
- Chapters 14 to 16 are partly generated from the programs and their example files
  by `tools/manual-gen.sh`, so they match the release.

## Status and how it is made

NIRUX is **beta**: it is the daily desktop of its author on several Debian, Arch and
Void machines, and mostly complete for that use. Some components are **alpha** (for
example NIRUCLIP, NIRU Login, NIRUWEBAPP, NIRUSHARE and several extras); the manual
says so where it matters. Expect rough edges, read what you install and keep backups
of anything important before you change a working desktop.

NIRUX is made by Nicklas Rudolfsson ([@nirucon](https://github.com/nirucon)) for his
own needs. It is free and open source under the MIT License, with no warranty of any
kind. In recent releases Claude, Anthropic's AI, has done much of the heavy lifting
under his direction; he decides what is built and tests it on his own machines. The
same applies to this manual: it is written from the code and documentation of each
release, and where something was unclear it says less rather than guess. Corrections
are welcome as issues in [nirucon/nirux](https://github.com/nirucon/nirux/issues).

See also the project [README](https://github.com/nirucon/nirux#status-disclaimer-and-how-its-made).
