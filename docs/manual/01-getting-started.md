# Getting started

What NIRUX is, how to install it, and the handful of keys you need on the first day.

## What NIRUX is

NIRUX is a keyboard-first X11 desktop for Debian, Arch and Void Linux (x86_64,
glibc): the tiling window manager NIRUWM, the bar NIRUBAR, NIRU Launcher,
notifications, lock screen, screensaver, screenshots, screen recording, themes,
wallpaper and display tools, installed and updated together by the `nirux` command
as one verified set. Optional apps, the *extras*, are installed separately.

NIRUX is beta and is made by one person for his own machines. Read
[Status and how it is made](README.md#status-and-how-it-is-made) before you rely on it.

## Install

As your normal user, not in a root shell:

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

The installer asks for sudo, installs the runtime packages, downloads the release,
checks every file against its SHA-256 sum and installs under `~/.local`. A fresh
install asks about the Helium browser, LocalSend, OpenCode, Tailscale and Papirus
icons, and uses **NIRU Login** as the login screen unless you already have a
display manager:

```sh
./nirux install --display-manager auto|startx|nirulogin|sddm|lightdm
```

The runtime packages include **gnome-keyring**, a small store for saved logins.
The login screen unlocks it with your password, so apps such as the Nextcloud
client keep their logins across reboots. It needs a few megabytes of memory and
no processor time while idle. Change your password with `passwd` in your own
session and the keyring's password follows it.

**Tailscale** (default yes) joins the computer to your private network, so
`nirux fleet`, nirushare and SSH reach it from your other machines. The
installer installs and starts it and shows a link: open it on any device to add
the computer. `Ctrl+C` skips the link; run `sudo tailscale up` later.
`--tailscale no` leaves it out, and an existing Tailscale is never removed.

**Web apps** open sites such as Teams, Gmail or Claude in their own windows,
with their own icons in the launcher (NIRUWEBAPP, chapter 12). The installer
lists the sets and asks which ones you want (default `ai media`), then asks
for your Nextcloud address (empty skips it):

| Set | Web apps |
|---|---|
| `work` | Microsoft 365: Teams, Outlook, Outlook Calendar, Copilot, Loop, Planner, OneDrive |
| `ai` | Claude, ChatGPT, Gemini, Grok, Gemini Notebook |
| `google` | Gmail, Google Calendar, Google Drive |
| `proton` | Proton Mail, Calendar, Drive and Pass |
| `media` | YouTube, YouTube Music, SVT Play |
| `other` | Spotify, Discord, GitHub, Excalidraw |

`--webapps work,ai` (or `all`, or `none`) and `--nextcloud ADDRESS` answer
without asking; a noninteractive install adds none. Both also work with
`nirux update`, and `nirux webapps add` adds more later.

On a laptop with a touchpad, tapping works from the start, also on the login
screen: one finger clicks, two fingers right-click, three fingers middle-click,
tap and drag moves things, and two fingers scroll. Turn tapping off with
`niructl input set-pointer tap off`.

From a text console without a display manager, start the session with
`startx "$HOME/.local/bin/niruwm-session"`.

The commands are in `~/.local/bin`. Until you have logged in to NIRUWM once, that
directory may not be on your `PATH` (Arch and Void do not add it), so use
`~/.local/bin/nirux` in the terminal you installed from.

## First login

1. Log out, or reboot into NIRU Login. NIRU Login always starts NIRUWM; with SDDM or
   LightDM, choose the **NIRUWM** session.
2. You get an empty desktop with the bar at the top. Press `Super+Enter` for a
   terminal (kitty with fish).
3. Press `Super+F1` for the cheat sheet of every key binding.
4. Run `nirux doctor` once. It checks the programs, the session, PAM, audio, capture
   and the configuration, and inside the session also the window manager and bar.

`Super` is the Windows key.

## The essentials

| Keys | Action |
|---|---|
| `Super+Enter` | Terminal |
| `Super+P` | Applications |
| `Super+Shift+P` | Applications, windows, actions and settings in one view |
| `Super+A` | NIRU Actions: settings, maintenance and diagnostics by name |
| `Super+F1` | Cheat sheet of all keys (`Super+/` where `/` is its own key) |
| `Super+Shift+F1` | This manual: search chapters and headings |
| `Super+Q` | Close the focused window |
| `Super+1` to `Super+9`, `Super+0` | Go to workspace 1 to 10 |
| `Super+Shift+1` to `Super+Shift+9` | Move the window to a workspace |
| `Super+J` / `Super+K` | Focus the next / previous window |
| `Super+T` / `Super+M` / `Super+F` | Tile / monocle / floating layout |
| `Super+Shift+Space` | Float the window, or tile it again |
| `Super+Shift+S` | Show or hide the scratchpad terminal |
| `Super+V` | Clipboard history |
| `Super+S` | Web search |
| `Super+.` | Emoji and symbols |
| `Print` | Screenshot of a region |
| `Super+Escape` | Lock the screen |
| `Super+Shift+R` | Reload the configuration |
| `Super+Ctrl+Shift+Q` | Log out |

The complete list is in [Key bindings](15-key-bindings.md).

## The cheat sheet

`Super+F1` opens every key binding in effect, grouped and searchable, including your
own overrides and keys that programs such as NIRUDICTATE register.

| Keys | In the cheat sheet |
|---|---|
| Type | Search by words or by key name |
| `Enter` | Run the selected binding |
| `Ctrl+R` | Press a key to see what it does |
| `Esc` | Close |

Clashes between bindings are flagged. On Swedish and similar layouts `/` is
`Shift+7`, so `Super+/` does not reach the cheat sheet there: use `Super+F1`.

## Do things by name

Most settings have no key of their own. Open NIRU Actions (`Super+A`) and type what
you want: *wifi*, *bluetooth*, *displays*, *theme*, *sound*, *lock*, *focus mode*,
*volume up*. Phrases resolve to native actions on the machine, with no account,
model or network request. See [The launcher](05-launcher.md).

The bar's Quick Settings button opens volume, microphone, Wi-Fi, Bluetooth,
displays, power profile, themes, Do Not Disturb, keep-awake, night light and lock in
one view. See [The bar and Quick Settings](04-bar-and-quick-settings.md).

## Files and folders

`Super+Shift+F` opens **NIRUFM**, the file manager of NIRUX. It starts in a few
hundredths of a second, uses about 15 MB of memory and follows the theme. Press
`F1` in it for every key.

- **Views:** icons, thumbnails, compact and a detailed list (`Ctrl+1` to `Ctrl+4`
  or the buttons at the top right). Each folder remembers its view; a folder of
  photos opens as thumbnails. `Ctrl+wheel` zooms.
- **Files:** `Ctrl+C`, `Ctrl+X`, `Ctrl+V`, `Delete` (to the trash), `Ctrl+Z`
  (undo), `F2` (rename), drag and drop to folders, tabs and other programs.
  Nothing is ever overwritten: a name that exists gets " (2)".
- **Look:** `Space` previews a picture, PDF or text; `Enter` on a photo (or
  `Ctrl+G`) opens the gallery with a film strip, slideshow and full screen.
- **Find:** `Ctrl+F` searches the folder and everything below it.
- **Work:** tabs (`Ctrl+T`), two panes (`F3`), properties (`Alt+Enter`),
  pack and unpack archives from the right-click menu, a terminal here (`F4`).
- **Drives and servers:** USB sticks appear under DEVICES; click to mount,
  ⏏ to eject. `Ctrl+K` connects to `sftp://`, `ftp://`, `smb://` or `davs://`
  servers; SSH hosts from `~/.ssh/config` complete with `Tab`.
- **Nextcloud:** in a synced folder the right-click menu copies the public or
  internal link and opens sharing, and badges show what is synced.

Folders that other programs open ("show in folder") open in NIRUFM too.

## The terminal: NIRUTERM and NIRUPROMPT

`Super+Enter` opens **NIRUTERM**, the NIRUX terminal, and `Super+Shift+Enter`
opens kitty. NIRUTERM opens in about 40 ms, uses 12 to 25 MB, follows the
theme live and shows pictures with `niruterm icat FILE` (or `icat FILE`).
Ctrl+Shift+C and Ctrl+Shift+V copy and paste, Ctrl+Shift+N opens a window in
the same folder, Ctrl+click opens a link. To swap them back, set
`terminal = ["kitty"]` and `terminal_alt = ["niruterm"]` under Programs in
`~/.config/niruwm/config.toml`.

**NIRUPROMPT** draws the fish prompt and works in bash too:

```sh
niruprompt styles                 # preview: nirux, runes, ascii, powerline, minimal, c64
niruprompt style runes            # choose one
niruprompt alias add gs git status   # an alias for bash and fish
niruprompt install bash           # the prompt, aliases and a large shared history in bash
```

## Read this manual

```sh
nirux manual             # the table of contents (or Super+Shift+F1)
nirux manual lock        # a chapter
nirux manual scratchpads # a heading
nirux manual --list      # all chapters
```

It opens in NIRUNOTE when that is installed, else in your default viewer, else in
`less`. The manual installed with each release matches the installed programs and
works offline. From the launcher: NIRU Actions, type *manual*. See
[Command reference](16-commands.md#reading-this-manual).

## Where things are

| Path | What |
|---|---|
| `~/.config/niruwm/config.toml` | Window manager, bar, keys, idle, wallpaper |
| `~/.config/niruwm/appearance.toml` | Fonts, colours, spacing (optional) |
| `~/.config/niruui/lock.toml`, `screensaver.toml` | Lock screen and screensaver |
| `~/.config/nirux/` | Sounds, fleet, sync and snapshot settings |
| `~/.local/share/nirux/current` | The active program generation |
| `~/.local/state/niruwm/session.log` | Session and window manager log |

All files and keys are in [Configuration reference](14-configuration-reference.md).

## See also

- [Windows and layouts](02-windows-and-layouts.md)
- [The launcher](05-launcher.md)
- [Keeping NIRUX up to date](11-updates.md)
- [Troubleshooting](13-troubleshooting.md)
