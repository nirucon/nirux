# Command reference

The two command-line tools of the desktop: `nirux` installs and maintains NIRUX,
`niructl` controls the running session. Every program also answers `--help` or
`--version`.

## nirux

`nirux --help` prints the usage of the installed release. Run `nirux` as your
normal user, never in a root shell; it asks for sudo itself when it needs it.

### Install and update

| Command | What it does |
|---|---|
| `nirux install [OPTIONS]` | Install NIRUX: packages, the program generation, session, login and integration |
| `nirux update [OPTIONS]` | Update to the newest release, or to `--release VERSION` |
| `nirux update-shutdown [--yes] [--dry-run] [--no-power]` | Update the distribution, NIRUX and the selected extras, then power off |
| `nirux update-reboot [--yes] [--dry-run] [--no-power]` | The same, then restart |
| `nirux rollback` | Switch back to the previous program generation |
| `nirux gc [--keep N] [--dry-run]` | Remove old program generations (also done after every update) |
| `nirux snapshot [--note TEXT]` | Save a snapshot of your configuration |
| `nirux snapshot list` | List the snapshots |
| `nirux restore [ID\|latest] [--dry-run]` | Restore a configuration snapshot, after a preview and a y/N question |
| `nirux checkup [--dry-run]` | Run the weekly checkup now (or show what it would do) |
| `nirux checkup last\|status\|enable\|disable` | The latest report, the schedule, or turn it on or off |
| `nirux checkup discord set\|test` | Set the Discord webhook for the checkup report, or test it |
| `nirux fleet [status [--json]]` | Status of your other NIRUX machines |
| `nirux fleet update HOST...\|--all\|--behind` | Update other machines over SSH, one at a time |
| `nirux fleet setup [HOST...]` | Let this machine log in to the others with an SSH key |
| `nirux sync status [HOST...] [--files]` | What differs between this machine and the others |
| `nirux sync push HOST...\|--all [ITEM...]` | Copy settings from this machine (`--yes`, `--dry-run`) |
| `nirux sync pull HOST [ITEM...]` | Copy settings from another machine to this one |
| `nirux sync items` | The items `sync` knows, with their paths |
| `nirux uninstall [--purge]` | Remove NIRUX; `--purge` also removes its configuration and state |

Options of `install` and `update`:

| Option | Meaning |
|---|---|
| `--minimal`, `--no-packages` | Binaries and integration only; the OS packages must already exist |
| `--display-manager auto\|startx\|nirulogin\|sddm\|lightdm` | Login method (install only; an update keeps the current one) |
| `--browser helium\|none\|keep` | The managed Helium browser, a persistent opt-out, or the current policy |
| `--browser-addon bonjourr\|none\|keep` | The optional Bonjourr start page (update) |
| `--wallpapers all\|default` | All ten theme wallpapers, or only the default one |
| `--localsend yes\|no`, `--opencode yes\|no` | Optional apps; without a flag an install asks and an update keeps the choice |
| `--icons none\|papirus` (update also `keep`) | Papirus-Dark icons with grey folders |
| `--release VERSION` | Install or update to that release instead of the newest |

### Desktop pieces

| Command | What it does |
|---|---|
| `nirux status` | Programs, session file, PAM, polkit rule, browser, generation and manual |
| `nirux doctor` | `status`, plus tools, audio, capture, the configuration checks and, in a session, the live WM, bar and services |
| `nirux manual [TOPIC]` | Open this manual, see [Reading this manual](#reading-this-manual) |
| `nirux extras [list\|status]` | Pinned, installed and selected extras |
| `nirux extras install [NAME...]` | Download the pinned extra, verify it and run its installer |
| `nirux extras update` | Update the selected extras to their pins |
| `nirux extras select NAME`, `unselect NAME` | Remember an extra for updates, or forget it |
| `nirux extras uninstall NAME... [--purge]` | Run the extra's own uninstaller; `--purge` also removes its data |
| `nirux sounds [status [--json]]` | Event sounds: on or off, per category and event |
| `nirux sounds list` | Every event and its category |
| `nirux sounds on`, `off` | All event sounds on or off |
| `nirux sounds toggle EVENT\|CATEGORY` | One event or category on or off |
| `nirux sounds test EVENT [--app NAME] [--level N]` | Play an event, even when it is off |
| `nirux sounds play EVENT [--app NAME] [--level N]` | Play an event as the desktop would (respects the off switches, a muted output and the cooldown) |
| `nirux sounds app APP [SOUND\|PATH\|default\|off\|remove]` | The notification sound of one application |
| `nirux wallpapers [status]` | Which optional wallpapers are installed |
| `nirux wallpapers download [themes\|extras\|all\|theme NAME]` | Download optional wallpapers |
| `nirux wallpapers remove` | Remove the downloaded optional wallpapers |
| `nirux login-wallpaper list\|set FILE\|reset\|sync` | The wallpaper of the login screen |
| `nirux layout list\|save NAME\|apply NAME` | Display profiles (the same as `niructl display list\|save\|apply`) |
| `nirux layout rotate OUTPUT normal\|left\|right\|inverted\|auto` | Turn one screen |
| `nirux reset-config` | Replace `~/.config/niruwm/config.toml` with the current example (backup and snapshot first) |
| `nirux repair-session` | Rewrite the session files |
| `nirux repair-wallpaper` | Repair the wallpaper setup |
| `nirux browser-addon bonjourr\|none\|status` | The optional browser start page |
| `nirux remove helium\|localsend\|opencode` | Remove an optional app that NIRUX installed |
| `nirux --version`, `nirux --help` | The installed release, the usage text |

### Reading this manual

```sh
nirux manual                 # the table of contents
nirux manual 06              # a chapter by number
nirux manual lock            # ... or by name
nirux manual scratchpads     # a heading
nirux manual "studio mode"   # a heading with several words
nirux manual studioläge      # a few Swedish words work too
nirux manual 05-launcher#niru-actions   # CHAPTER#ANCHOR, as in the links
nirux manual --list          # the chapters
nirux manual --path          # the directory of the installed manual
nirux manual --where lås     # FILE:LINE a topic opens, and its heading
```

A topic is matched in this order: a Swedish or English alias, a chapter number or
file name, an exact heading, a chapter title, then any heading that contains the
words. With no match, `nirux manual` lists the chapters and exits with an error.

The manual opens in NIRUNOTE when it is installed (`Ctrl+G` there goes to a
heading; `nirux manual` prints the heading it found), otherwise with `xdg-open`,
otherwise in `less` at the heading. Without a display or a terminal it prints the
file path. The installed files are read-only.

The manual is part of each release and installed in the program generation, at
`~/.local/share/nirux/current/manual`, so it always describes the installed
programs, also offline, and a rollback brings back the matching manual. The same
text is on GitHub under
[docs/manual](https://github.com/nirucon/nirux/tree/main/docs/manual).

## niructl

`niructl` talks to the running NIRUWM over X11, so most commands need a NIRUWM
session (`DISPLAY` set). `niructl keys` and `niructl` without arguments also work
outside one. The commands the key bindings run are the same ones, so anything a key
does can be scripted.

Common examples:

```sh
niructl reload                 # reread config.toml, appearance and the theme
niructl theme niru-noir        # change the theme
niructl layout scroll          # change the layout of this workspace
niructl scratchpad 3 toggle    # show or hide scratchpad 3
niructl display list           # display profiles
niructl audio sources          # microphones
niructl lock --manual          # lock as Super+Escape does
niructl keys --markdown        # the keys in effect, as Markdown
```

### All niructl commands

<!-- generated: niructl (tools/manual-gen.sh; do not edit by hand) -->

Every form `niructl` accepts, from its usage text (NIRUWM 0.24.1). Run `niructl`
without arguments to print it.

- `niructl status`
- `niructl tag N`
- `niructl movetotag N`
- `niructl theme NAME`
- `niructl themes`
- `niructl theme-catalog`
- `niructl theme-import`
- `niructl theme-remove`
- `niructl theme-hide`
- `niructl theme-show`
- `niructl keys`
- `niructl monitors`
- `niructl reload`
- `niructl restart-bar`
- `niructl restart-wm [--check]`
- `niructl bar top|bottom|hide|show|toggle|cycle|status`
- `niructl quit`
- `niructl save`
- `niructl save-session`
- `niructl layout NAME|columns 1|2|toggle`
- `niructl layouts`
- `niructl clear-session`
- `niructl brightness up|down|set N|status`
- `niructl nightlight on|off|toggle|status|temperature K|apply|watch`
- `niructl compositor on|off|toggle|status`
- `niructl timing show|set KEY MINUTES`
- `niructl wallpaper list|status|apply [--json]|set PATH|mode VALUE|rotation MINUTES|scale VALUE|follow-theme on|off|style art|signature|toggle`
- `niructl wallpaper output list|set NAME KEY VALUE|reset NAME`
- `niructl autostart`
- `niructl recipe list|run NAME`
- `niructl mode focus|presentation|stop|status [MINUTES]`
- `niructl display list [--json]|save NAME|save-json NAME|preview NAME [SECONDS]|preview-json [SECONDS]|apply NAME|keep|revert|status [--json]|delete NAME|rename OLD NEW|startup show|set NAME|off|apply|rotate OUTPUT normal|left|right|inverted|auto|automatic on|off|status [--json]|run|doctor [--json]|watch [--once] [--quiet]`
- `niructl action list [--json]|save NAME -- CMD [ARG...]|run NAME|delete NAME|rename OLD NEW|pin NAME|unpin NAME`
- `niructl layout show|save`
- `niructl scratchpad [N] [toggle|show|hide]|send N|unscratch|list [--json]`
- `niructl urgent [list|--json|focus]`
- `niructl swallow on|off|toggle|status`
- `niructl studio on|off|toggle|status`
- `niructl powerprofile status|list|set NAME|next`
- `niructl lock [--manual|--silent|--reason NAME]`
- `niructl screensaver`
- `niructl logout`
- `niructl suspend`
- `niructl reboot`
- `niructl shutdown`
- `niructl update-shutdown`
- `niructl update-reboot`
- `niructl dnd on|off|toggle|status`
- `niructl audio status [--json]|outputs|sources [--json]|output ID|next|source ID|next|input ID|next|mute|mic-status [--json]|mic-mute [on|off|toggle]|mic-level up|down|set N|mic-test [SECONDS] [--json] [--keep]|volume up|down`
- `niructl bluetooth status|list|power on|off|toggle|connect MAC|disconnect MAC`
- `niructl explain [--launcher]`
- `niructl idle on|off|toggle|status [MINUTES]`
- `niructl storage review [--json]|clean cache --yes`
- `niructl agent [--dry-run] TASK`
- `niructl task list [--json]|clear`
- `niructl windows rescue [--dry-run]`
- `niructl input status [--json]|apply|set-keyboard LAYOUT [VARIANT]|set-repeat DELAY RATE|set-pointer natural|tap on|off|toggle natural|tap|set-speed VALUE|cycle-speed|reset`

<!-- end generated: niructl -->

## Other programs

| Program | Most useful commands |
|---|---|
| `niruwm` | `--check-config`, `--version` |
| `nirubar` | `--check-config`, `--version` |
| `nirulauncher` | `--apps`, `--actions`, `--help` for every view; see [The launcher](05-launcher.md) |
| `nirunotify` | `--check-config`; see [Sound, notifications and studio mode](10-sound-notifications-studio.md) |
| `nirulock`, `niruscreensaver` | `--config`; see [Lock screen and screensaver](06-lock-and-screensaver.md) |
| `nirushot`, `niruclip` | See [Screenshots and recording](07-screenshots-and-recording.md) |
| `nirudisplay`, `niruwallpaper`, `niruthemeselector` | Graphical; see [Displays](09-displays.md) and [Themes and wallpapers](08-themes-and-wallpapers.md) |

## See also

- [Key bindings](15-key-bindings.md)
- [Configuration reference](14-configuration-reference.md)
- [Keeping NIRUX up to date](11-updates.md)
