# NIRUX

Install, update and remove the NIRU desktop suite on Void Linux, Arch Linux and
Debian.

**A personal hobby project.** I build this for my own machines. It is public so
others can read it and try it, but there is no support promise. Early software,
used at your own risk.

## The suite

| Program | What it does |
| --- | --- |
| [niruwm](https://github.com/nirucon/niruwm) | tiling window manager and session |
| [nirubar](https://github.com/nirucon/nirubar) | status bar with modules |
| [niruscreensaver](https://github.com/nirucon/niruscreensaver) | idle screen |
| [nirulock](https://github.com/nirucon/nirulock) | lock screen |

Each installs and runs on its own. NIRUX just does all four at once, with the
programs they use.

## Install

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

That installs the packages listed below with sudo, downloads the released
binaries into `~/.local/bin`, adds the session to the display manager and
installs the PAM service for the lock screen, and copies `nirux` itself to
`~/.local/bin` so `nirux update` works from anywhere. Log out and choose
**NIRUWM**.

| Command | What it does |
| --- | --- |
| `./nirux install` | everything, including packages |
| `./nirux install --minimal` | binaries and session only, no packages |
| `./nirux update` | install the newest release of everything |
| `./nirux status` | what is installed, what is missing, and whether NIRUPI is present |
| `./nirux doctor` | every program's own checks: libraries, keyboard, lock screen, settings |
| `./nirux uninstall` | remove the programs, keep your settings |
| `./nirux uninstall --purge` | remove the programs and your settings |

## Packages

`./nirux install` installs these, because a default key binding or the session
uses each one:

| Purpose | Void | Arch | Debian |
| --- | --- | --- | --- |
| Terminal | `kitty` | `kitty` | `kitty` |
| Launcher | `rofi` | `rofi` | `rofi` |
| Font | `dejavu-fonts-ttf` | `ttf-dejavu` | `fonts-dejavu-core` |
| Notifications | `dunst` | `dunst` | `dunst` |
| Compositor | `picom` | `picom` | `picom` |
| Wallpaper | `feh` | `feh` | `feh` |
| Screenshot | `maim` | `maim` | `maim` |
| Idle timing | `xidlehook` | `xidlehook` | `xidlehook` |
| Keyboard layout | `setxkbmap`, `xkeyboard-config` | `xorg-setxkbmap`, `xkeyboard-config` | `x11-xkb-utils`, `xkb-data` |
| Media and playback | `playerctl` | `playerctl` | `playerctl` |

The binaries are static where possible, so no Rust is needed. Nirulock links
the system libpam, which is present on every system that can log in.

### Other distributions

The binary releases are built for x86_64 Linux with glibc and run on most
distributions. Install the packages above with your own package manager, then:

```sh
./nirux install --no-packages
```

Fedora names them `kitty rofi dejavu-sans-mono-fonts dunst picom feh maim
xidlehook xkeyboard-config`. On openSUSE use `zypper install kitty rofi
dejavu-fonts dunst picom feh maim xidlehook xkeyboard-config`.

On these systems `./nirux doctor` still works; the doctor only reads.

## Settings

`~/.config/niruwm/config.toml` is shared by the window manager and the bar;
`~/.config/niruui/` holds the screensaver and lock settings. Both are documented
inline. After editing, run `niructl reload` or press Super+R.

## Example configs

The first time a program runs without a settings file it uses documented
built-in defaults. Two files are worth starting from, because they list every
option:

- `~/.config/niruwm/config.toml`: the window manager, the bar, the key
  bindings and the idle ladder. The full list ships as `config.example.toml`
  in the [niruwm](https://github.com/nirucon/niruwm) repository; `niruwm
  --dump-config > ~/.config/niruwm/config.toml` writes it out.
- `~/.config/niruui/screensaver.toml`: when the screen sleeps, locks and turns
  off. One file decides the whole ladder for the window manager, the idle
  timer, the screensaver and the lock screen.

`nirux doctor` reports which files exist and which values are in use.

## Uninstall

`./nirux uninstall` removes the binaries, the session entry and the PAM service.
Your settings stay until you add `--purge`.

## NIRUPI

[NIRUPI](https://github.com/nirucon/nirupi) is a separate desktop by the same
author. NIRUX never installs it and never changes it. If it is present, `nirux
status` says so and `nirux install` mentions that both sessions are now in the
display manager. On a machine without it nothing changes.

## License

MIT. Copyright 2026 Nicklas Rudolfsson.
