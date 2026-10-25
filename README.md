# NIRUX - A minimal X11 desktop by Nicklas Rudolfsson

**Early beta.** A small, keyboard-first X11 desktop for **Arch Linux, Debian and
Void Linux (glibc, x86_64)**.

NIRUX started with a simple idea: to build the desktop I actually want to use.

For many years, my Linux desktop was based on
[dwm](https://dwm.suckless.org/). Over time I built my own configuration around
it, using a carefully selected set of patches and adapting the environment
closely to the way I work. That experience has had a strong influence on NIRUX
and is still very much part of its DNA.

The influence of dwm and the suckless philosophy is intentional. NIRUX favors
a keyboard-first workflow, tags rather than conventional virtual desktops,
simple configuration, minimal interfaces and components that remain
understandable. Some of its behavior and ideas are also inspired by dwm patches
that became important parts of my daily workflow over the years.

NIRUX is not dwm, however, nor is it intended to be a rewrite of it. The suite,
including **NIRUWM**, **NIRUBAR** and the surrounding components, is built in
**Rust** and developed as its own integrated X11 desktop. It shares some of the
suckless ideas that I have always appreciated, while expanding the scope to
include the things I want from a modern machine used every day: audio,
networking, notifications, locking, idle handling, screenshots, themes,
wallpapers and other desktop integration.

Most importantly, NIRUX is built for me and my own workflow.

It reflects how I want my desktop to behave, how I use the keyboard, how I
organize windows and workspaces, and how I want the different parts of my Linux
environment to work together. It is deliberately opinionated and is not an
attempt to design a desktop that suits everyone.

That said, NIRUX is **open source**. If the same ideas appeal to you, you are
very welcome to try it, use it, modify it and adapt it to your own workflow.

The suite is crafted in Rust, while the installer is a compact POSIX shell
program. The goal is a fast, quiet and intentionally minimal desktop without a
traditional desktop-environment stack or unnecessary background services.

NIRUX installs, updates and removes the complete NIRUX desktop, including the
window manager, bar, launcher, notifications, lock screen, idle screen,
screenshots, themes, wallpapers, terminal integration and the OS packages the
components need.

## Project status

At the time of writing, I consider NIRUX to be in **early beta**.

There is already quite a lot of functionality despite its intentionally simple
design, and I currently run NIRUX myself on two of my daily-driver machines.
That does not mean everything is finished or that everything will work
perfectly on every system.

I fully expect to find bugs, rough edges and things that can be improved as I
continue using it. I will fix issues as I encounter them, and more functionality
may find its way into the suite over time when it makes sense. At the same time,
I want to preserve the simplicity and focused nature of the project rather than
adding features simply for the sake of having more features.

There is no fixed roadmap or promise about what NIRUX will eventually become.
It is first and foremost a personal project that I build because I enjoy
developing it and because I want to use it myself. Time will tell where the
project goes from here.

NIRUX is provided **without warranty or guarantees of any kind**. Installation,
updates and use are entirely at your own risk. If you decide to try it,
especially on an existing system, make sure you understand what the installer
does and have backups of anything you care about.

## What it can do

- **Window management:** tiling with seven layouts, per-monitor workspaces,
  scratchpad, floating windows, fullscreen, gap control and session restore.
- **Bar:** ten per-monitor workspaces with occupancy markers, clock/calendar,
  network, battery, audio, microphone, brightness, media, weather, updates,
  CPU/memory, uptime, power profile, Bluetooth and a system tray.
- **Standard folders:** locale-aware XDG Documents, Downloads, Music, Pictures
  and Videos.
- **Keyboard-first desktop:** application search, open-window switching,
  grouped actions, workspace recipes and focus/presentation modes.
- **Notifications:** native notification service and hardware OSD, DND,
  history, actions and live theme changes.
- **Session:** startx, SDDM or LightDM, PAM lock, idle screen, Polkit power
  actions and a managed session bus. On a fresh SDDM, NIRUWM is the first
  session in the list; an existing SDDM keeps its configuration, and a
  remembered session from another desktop is cleared on install, so the login
  screen offers every installed session with NIRUWM first. Autologin is never
  changed.
- **Hardware controls:** PipeWire/WirePlumber audio and microphone, BlueZ
  Bluetooth, RandR display profiles, power-profiles-daemon, backlight and
  night light.
- **LocalSend:** verified official Linux tarball, floating centered window,
  no Flatpak.
- **OpenCode:** managed V2 native CLI, installed without npm, services or
  agent startup.
- **Webapps:** `niruwebapp` creates browser-backed desktop apps with dedicated
  profiles and optional local icons.
- **Screenshots:** region, window or full-screen capture with a floating review
  dialog, crop, rectangle, arrow, mask, zoom and pan.
- **Appearance:** Niru Noir, Nord, Satie, Carl Larsson, Forest Vigil, Blood of
  Urdr, Root and Stone, Blue Horizon, The Norns and Winter Nights themes,
  shared semantic colours, configurable fonts, emoji, theme-matched login
  wallpaper, optional extra wallpapers and optional picom transparency.
- **Safe maintenance:** checksummed releases, pinned components, atomic
  generations, rollback, configuration migration, diagnostics and owned
  uninstall.

## Suite

| Component | Role |
|---|---|
| [NIRUX](https://github.com/nirucon/nirux) | Installer, updates, dependencies and system integration |
| [NIRUWM](https://github.com/nirucon/niruwm) | Window manager, session, `niructl` and `niruidle` |
| [NIRUBAR](https://github.com/nirucon/nirubar) | Per-monitor status bar and panels |
| [NIRUSCREENSAVER](https://github.com/nirucon/niruscreensaver) | Unlocked idle screen |
| [NIRULOCK](https://github.com/nirucon/nirulock) | PAM-based lock screen |
| [NIRULAUNCHER](https://github.com/nirucon/nirulauncher) | Keyboard-first application and action launcher |
| [NIRUNOTIFY](https://github.com/nirucon/nirunotify) | Native notifications and hardware OSD |
| [NIRUSHOT](https://github.com/nirucon/nirushot) | Screenshot capture, review and annotation |
| [NIRUWALLPAPER](https://github.com/nirucon/niruwallpaper) | Wallpaper settings with previews and a per-screen choice, opened from the launcher |
| [NIRUFETCH](https://github.com/nirucon/nirufetch) | NIRU-themed terminal system fetch |
| [NIRUWEBAPP](https://github.com/nirucon/niruwebapp) | Browser-backed webapp manager |

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

An existing display manager is preserved; otherwise choose startx (default),
SDDM or LightDM. A fresh install offers the managed Helium browser and installs
kitty/fish integration and terminal colours. User configuration is not
overwritten.

Use `./nirux install --no-packages` only when all runtime dependencies already
exist.

### Wallpapers

Only the default theme's wallpaper ships with a release, in 4K and 8K. The
other nine themes are an optional set of about 326 MB served from the project's
own Nextcloud, so a routine release stays small and an update does not download
wallpapers a machine already has.

**The default theme's wallpaper comes from the release, not the download.** It
is installed before any optional set and is never taken from the Nextcloud
archive, so the optional archive carries only the other nine themes. This means
a new noir image reaches every machine through `nirux update`; nothing has to be
re-downloaded.

```sh
nirux wallpapers status     # how many of the ten themes have an image
nirux wallpapers download   # install all ten (checksum verified)
nirux wallpapers remove     # delete the downloaded set, keep the default
```

The same action is in the launcher under **Wallpaper**. To pick a wallpaper with
preview thumbnails, open **NIRU Wallpaper** from the launcher (search for
`wallpaper`, `background` or `appearance`) or run `niruwallpaper`. It is a front
end for `niructl wallpaper`, so it changes nothing NIRUWM does not already
control, and choosing an image there does not change the desktop theme.

NIRUX asks once during
installation whether to fetch the set and remembers the answer. The archive is
verified against a SHA-256 pinned in this repository, staged in a temporary
directory, and moved into place only when complete, so an interrupted download
cannot leave a half-written set.

**Recommended: say yes at install time.** NIRUX ships ten themes, and switching
theme is the main way to change the look of the desktop. With the full set
installed, every one of them arrives complete: wallpaper, bar palette, terminal
colours and login screen all change together. Without it, the nine themes that
are not the default fall back to their own background colour, which is tidy but
plain, and the theme looks half finished until you download the images later.
The set is a one-time download of about 326 MB; an update never fetches it
again. If you decline now, `nirux wallpapers download` adds it at any time
without reinstalling anything.

A theme without its image paints its own background colour, taken from the
theme file, so the desktop still matches the theme instead of showing the
previous theme's picture. `remove` never deletes a file you modified.

### More than one screen

NIRUWM sets every screen separately. By default all screens show the same
picture, scaled and cropped for each screen's own size and position; one
picture is not stretched across the desktop. In **NIRU Wallpaper**, the header
lists *All screens* and each connected screen, so one screen can keep its own
picture while the others follow the shared settings and the theme.

A screen's own picture survives theme changes, reloads, rotation and a
reconnect. A new screen inherits the shared settings. Screens are identified by
their RandR output name, so a cable moved to another port starts from the shared
settings; the saved entry stays for the original port. Settings are stored as
`[[wallpaper.outputs]]` entries in `~/.config/niruwm/config.toml`:

```toml
[[wallpaper.outputs]]
output = "DP-1"
mode = "single"          # this screen shows file; "theme" follows the theme
file = "~/Pictures/Wallpapers/mine/tower.png"
scale = "fill"           # empty inherits the common scale
```

The same from the command line:

```sh
niructl wallpaper output list                    # screens and their settings
niructl wallpaper output set DP-1 image FILE
niructl wallpaper output set DP-1 scale fit
niructl wallpaper output set DP-1 mode theme
niructl wallpaper output reset DP-1              # inherit the shared settings
```

## Maintain

```sh
nirux update
nirux remove helium|localsend|opencode
nirux status
nirux doctor
nirux rollback
nirux uninstall
nirux uninstall --purge
```

Updates verify checksums and component versions, install missing runtime
packages, then switch one program generation atomically. The previous
generation remains available for rollback. Log out and in after updates that
change the session, window manager or idle daemon.

Default prefix: `~/.local`.

Shared configuration:

```text
~/.config/niruwm/config.toml
```

XDG paths are respected.

## Documentation

- docs/INSTALL.md
- docs/STYLE.md
- [Example configuration](config.example.toml)

## License

MIT. Copyright 2026 Nicklas Rudolfsson.
