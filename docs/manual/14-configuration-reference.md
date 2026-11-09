# Configuration reference

Where NIRUX keeps its settings, how to apply a change, and every key of the example
configuration files.

## Apply a change

| File | Apply with |
|---|---|
| `~/.config/niruwm/config.toml`, `appearance.toml`, `themes/` | `Super+Shift+R` or `niructl reload` (WM, bar and theme) |
| `~/.config/niruwm/displays.toml` | `niructl display apply NAME`, or automatically on hotplug |
| `~/.config/niruui/lock.toml`, `screensaver.toml` | The next lock or screensaver start |
| `~/.config/nirulauncher/config.toml` | The next time the launcher opens |
| `~/.config/nirunotify/config.toml` | `niructl reload` |
| `~/.config/nirux/sounds.toml` | Immediately (`nirux sounds status` shows the result) |

An invalid `config.toml` is rejected and the previous settings stay in effect.
Check a file without applying it:

```sh
niruwm --check-config
nirubar --check-config
nirulauncher --check-config
nirunotify --check-config
```

`nirux update` adds new keys with their defaults to an existing configuration and
never rewrites your values. `nirux reset-config` replaces `config.toml` with the
current example (it keeps a `.nirux-backup` copy and takes a snapshot first).

## Other configuration files

These are not generated from an example file. The chapters describe them.

| File | Chapter |
|---|---|
| `~/.config/nirux/fleet.toml`, `snapshots.toml`, `sync.toml` | [Keeping NIRUX up to date](11-updates.md) |
| `~/.config/nirux/sounds/EVENT.ogg` | [Sound, notifications and studio mode](10-sound-notifications-studio.md) |
| `~/.config/niru/quotes.txt`, `~/.config/niru/quotes/` | [Lock screen and screensaver](06-lock-and-screensaver.md) |
| `~/.config/niruwm/themes/NAME.toml` | [Themes and wallpapers](08-themes-and-wallpapers.md) |
| NIRUSHOT and NIRUCLIP settings | [Screenshots and recording](07-screenshots-and-recording.md) |
| `~/.local/share/niru/keys.d/` | [Key bindings](15-key-bindings.md) |

## Example files

<!-- generated: config (tools/manual-gen.sh; do not edit by hand) -->

The example configuration files of NIRUX 0.12.246 and its components, with every
key they set or show. A value marked *commented example* is off by default:
remove the `#` to use it. The full annotated file follows each table.

| File | Read by | Example from |
|---|---|---|
| [`~/.config/niruwm/config.toml`](#configniruwmconfigtoml) | niruwm, nirubar, niruidle, niructl | nirux 0.12.246 `config.example.toml` |
| [`~/.config/niruwm/appearance.toml`](#configniruwmappearancetoml) | the whole suite | nirux 0.12.246 `appearance.example.toml` |
| [`~/.config/nirux/sounds.toml`](#configniruxsoundstoml) | nirux, nirunotify | nirux 0.12.246 `sounds.example.toml` |
| [`~/.config/niruwm/displays.toml`](#configniruwmdisplaystoml) | niruwm, niructl, nirudisplay | nirux 0.12.246 `displays.example.toml` |
| [`~/.config/nirubar/config.toml`](#confignirubarconfigtoml) | nirubar | nirubar 0.21.0 `weather.example.toml` |
| [`~/.config/nirulauncher/config.toml`](#confignirulauncherconfigtoml) | nirulauncher | nirulauncher 0.10.0 `config.example.toml` |
| [`~/.config/nirunotify/config.toml`](#confignirunotifyconfigtoml) | nirunotify | nirunotify 0.4.2 `config.example.toml` |
| [`~/.config/niruui/lock.toml`](#configniruuilocktoml) | nirulock | nirulock 0.25.0 `config.example.toml` |
| [`~/.config/niruui/screensaver.toml`](#configniruuiscreensavertoml) | niruscreensaver | niruscreensaver 0.14.1 `config.example.toml` |
| [`~/.config/nirushare/webhooks.toml`](#confignirusharewebhookstoml) | nirushare | nirushare 0.4.0 `webhooks.example.toml` |

### ~/.config/niruwm/config.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `theme` | `"niru-noir"` | List them with: niructl themes |
| `(top level)` | `gap` | `8` | Space between windows, in pixels. |
| `(top level)` | `border_width` | `2` | Border around each window, in pixels. |
| `(top level)` | `bar_height` | `28` | Height of the bar, in pixels. |
| `(top level)` | `master_ratio` | `0.55` | Each workspace keeps its own ratio after Super+H/L; this is only the default. |
| `(top level)` | `terminal` | `["kitty"]` | Commands are argument lists, never passed through a shell. |
| `(top level)` | `terminal_alt` | `[]` | Bound to Super+Shift+Enter. |
| `(top level)` | `browser` | `["helium"]` | Super+B starts this. |
| `(top level)` | `launcher` | `["nirulauncher", "--apps"]` | Super+P and the native action launcher. |
| `(top level)` | `font_size` | `15.0` |  |
| `(top level)` | `font_path` | `"/path/to/your/monospace.ttf"` (commented example) |  |
| `(top level)` | `weather_latitude` | `59.33` | At the top level, not under [bar]: NIRUWM reads this file too and refuses fields it does not know, so a setting only the bar uses still h... |
| `(top level)` | `weather_longitude` | `18.07` |  |
| `[wallpaper]` | `enabled` | `true` |  |
| `[wallpaper]` | `dir` | `"~/Pictures/Wallpapers"` | Directory to draw from. |
| `[wallpaper]` | `mode` | `"random"` | random = a new picture each rotation fixed  = one picture, chosen once and kept single = always file |
| `[wallpaper]` | `file` | `""` |  |
| `[wallpaper]` | `rotation_minutes` | `10` | Minutes between changes. |
| `[wallpaper]` | `scale` | `"fill"` | How a picture fills the screen: fill (crop), fit (letterbox), stretch, center. |
| `[wallpaper]` | `files` | `[]` | Rotate through these files instead of the whole directory. |
| `[wallpaper]` | `shuffle_on_start` | `true` | Pick a fresh picture at login, even in fixed mode. |
| `[wallpaper]` | `follow_theme` | `true` | When the theme changes, apply that theme's wallpaper from theme_dir. |
| `[wallpaper]` | `theme_dir` | `"~/Pictures/Wallpapers/NIRU"` | NIRUX installs nirux-wallpaper-<theme>-4k.png and -8k.png here. |
| `[autostart]` | `enabled` | `false` |  |
| `[autostart]` | `settle_seconds` | `2` | Seconds to wait after each workspace group before moving to the next one. |
| `[autostart]` | `window_timeout_ms` | `5000` | How long to wait for a matched window before moving on. |
| `[autostart]` | `return_workspace` | `1` | Return here when the sequence finishes. |
| `[autostart.apps]` | `workspace` | `1` (commented example) |  |
| `[autostart.apps]` | `class` | `"nirushare"` (commented example) |  |
| `[autostart.apps]` | `command` | `["nirushare", "serve"]` (commented example) |  |
| `[autostart.apps]` | `workspace` | `1` (commented example) |  |
| `[autostart.apps]` | `class` | `"kitty"` (commented example) |  |
| `[autostart.apps]` | `command` | `["kitty"]` (commented example) |  |
| `[autostart.apps]` | `workspace` | `3` (commented example) |  |
| `[autostart.apps]` | `class` | `"helium"` (commented example) |  |
| `[autostart.apps]` | `command` | `["helium"]` (commented example) |  |
| `[recipes]` | `name` | `"Development"` (commented example) |  |
| `[recipes.apps]` | `workspace` | `1` (commented example) |  |
| `[recipes.apps]` | `class` | `"kitty"` (commented example) |  |
| `[recipes.apps]` | `command` | `["kitty"]` (commented example) |  |
| `[recipes.apps]` | `workspace` | `2` (commented example) |  |
| `[recipes.apps]` | `class` | `"helium"` (commented example) |  |
| `[recipes.apps]` | `command` | `["helium"]` (commented example) |  |
| `[nightlight]` | `latitude` | `59.33` | Manual night light, applied by niructl nightlight on / Super+N. |
| `[nightlight]` | `longitude` | `18.07` |  |
| `[nightlight]` | `temperature` | `3400` |  |
| `[nightlight]` | `mode` | `"manual"` | manual: Super+N / niructl nightlight on\|off fixed:  on/off local times every day solar:  gammastep computes sunrise/sunset from the coord... |
| `[nightlight]` | `on` | `"20:00"` |  |
| `[nightlight]` | `off` | `"07:00"` |  |
| `[nightlight]` | `day_temperature` | `6500` |  |
| `[brightness]` | `device` | `""` | Empty uses brightnessctl's default device; step is the up/down percentage. |
| `[brightness]` | `step` | `5` |  |
| `[monitors]` | `workspaces` | `10` |  |
| `[monitors]` | `master_ratios` | `[0.55, 0.65, 0.45]` (commented example) | Per-workspace tiling state written by NIRUWM after Super+H/L or Super+I/D: |
| `[monitors]` | `nmasters` | `[1, 2, 1]` (commented example) |  |
| `[monitors.profiles]` | `name` | `"HDMI-1"` (commented example) |  |
| `[monitors.profiles]` | `workspaces` | `["web", "code", "chat"]` (commented example) |  |
| `[monitors.profiles]` | `primary` | `true` (commented example) |  |
| `[idle]` | `screensaver_timeout` | `5` (commented example) |  |
| `[idle]` | `lock_after_screensaver` | `2` (commented example) |  |
| `[idle]` | `screensaver_timeout` | `15` |  |
| `[idle]` | `lock_after_screensaver` | `15` |  |
| `[idle]` | `dpms_off_after_lock` | `15` |  |
| `[bar]` | `enabled` | `true` | The bar is a separate process; NIRUWM starts it from PATH. |
| `[bar]` | `position` | `"top"` | Screen edge: "top" (default) or "bottom". |
| `[bar]` | `modules` | `["workspaces", "layout", "media", "volume", "brightness",...` | Weather settings live in ~/.config/nirubar/config.toml; see weather.example.toml. |
| `[bar]` | `microphone_visibility` | `"always"` | Missing input/provider stays visible even with "muted" visibility. |
| `[bar]` | `tags` | `["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]` | Numbered (default): |
| `[bar]` | `tags` | `["\uf015", "\uf121", "\uf086", "\uf0c0", "\uf001", "\uf03...` (commented example) | Icon labels: comment out the numbered line and uncomment this one. |
| `[bar]` | `tags` | `["web", "code", "chat", "term", "media", "", "", "", "", ""]` (commented example) | Text labels: comment out the numbered line and uncomment this one. |
| `[bar]` | `cell_width` | `30` | Width of one workspace cell, in pixels. |
| `[bar]` | `workspace_layout` | `1` (commented example) | Workspace label preset. |
| `[bar]` | `transparent` | `true` (commented example) | Bar transparency. |
| `[bar]` | `opacity` | `94` (commented example) |  |
| `[bar]` | `title` | `false` | Show the focused window title between the workspaces and the status. |
| `[bar]` | `title_max` | `20` |  |
| `[bar]` | `title_delay_seconds` | `0` | Seconds before the title appears. |
| `[bar]` | `show_date` | `true` | Date and time. |
| `[bar]` | `show_time` | `true` |  |
| `[bar]` | `date_format` | `"%Y-%m-%d"` |  |
| `[bar]` | `time_format` | `"%H:%M"` |  |
| `[bar]` | `separator` | `"\|"` | Separator between status modules. |
| `[bar]` | `icons` | `true` | Use Nerd Font glyphs for battery and network. |
| `[bar]` | `popups` | `true` | Clicking a module opens a small panel with more detail. |
| `[bar]` | `popup_timeout_seconds` | `4` | Seconds before an open panel closes itself. |
| `[bar]` | `media_width` | `32` | Characters kept from the media title before an ellipsis. |
| `[bar]` | `graph_width` | `24` | Width of the graph in the pulse panel, in characters. |
| `[bar]` | `update_check_minutes` | `30` | Minutes between package update checks. |
| `[bar]` | `tray` | `true` | Let the bar own a system tray. |
| `[scratchpad]` | `command` | `["kitty", "--class", "scratchpad"]` |  |
| `[scratchpad]` | `width` | `0.6` |  |
| `[scratchpad]` | `height` | `0.6` |  |
| `[scratchpad]` | `hide_on_focus_loss` | `false` | A shown scratchpad stays on top until you hide it with its key, even when the mouse moves onto another window (that window gets the keybo... |
| `[scratchpad]` | `number` | `1` (commented example) | Numbered scratchpads need no settings: any window can be sent to any slot with Super+Alt+Shift+N. |
| `[scratchpad]` | `command` | `["kitty", "--class", "scratch-btop", "-e", "btop"]` (commented example) |  |
| `[scratchpad]` | `width` | `0.8` (commented example) |  |
| `[scratchpad]` | `height` | `0.8` (commented example) |  |
| `[rules]` | `class` | `"localsend"` (commented example) |  |
| `[rules]` | `floating` | `true` (commented example) |  |
| `[rules]` | `center` | `true` (commented example) |  |
| `[rules]` | `description` | `"..." is what the cheat sheet (Super+/) shows for the key.` (commented example) | An entry with the same keys replaces the default; a new keys entry adds a binding. |

<details><summary>The annotated example file (config.example.toml)</summary>

```toml
# NIRUWM + NIRUBAR shared configuration.
#
# Location: ~/.config/niruwm/config.toml (or $XDG_CONFIG_HOME/niruwm/).
# Both programs read this file and ignore nothing: a key this file does not
# describe is rejected, so a typo is visible instead of silent.
#
# ── Reloading ───────────────────────────────────────────────────────────────
# After editing, press Super+R, or run:
#
#     niructl reload
#
# That reloads the window manager, the bar and the theme. If the file is
# invalid the previous settings stay in effect and niruwm prints the error to
# the session log. Check a file without applying it with:
#
#     niruwm --check-config
#     nirubar --check-config
#
# Restart the session only for session.conf changes.

# Sections:
#   Appearance and layout
#   Programs and font
#   Weather location
#   Wallpaper
#   Autostart
#   Night light and brightness
#   Monitors
#   Screensaver and lock      [idle]    read by niruidle
#   Bar                       [bar]     read by nirubar
#   Key bindings              [[keys]]  read by niruwm
#
# ── Who reads what ──────────────────────────────────────────────────────────
# One file, several programs. Each key below names its owner:
#
#   niruwm    the window manager: layout, keys, wallpaper, rules
#   nirubar   the bar: [bar] labels, modules, transparency
#   niruidle  the screensaver/lock timers: [idle]
#   niructl   the control command; reads the same file
#
# A program accepts sections it does not own, so one bad section cannot stop
# the session from starting. Values are validated by the program that uses
# them; anything out of range falls back to the documented default here rather
# than failing the file.
#
# ── Reading this file ───────────────────────────────────────────────────────
# Every setting below states:
#
#   What it changes, valid values, default, and what it relates to.
#
# Commented-out examples (`# key = value`) show optional settings. A line that
# is not commented is in effect.
#
# ── Settings added in 0.11.0 ────────────────────────────────────────────────
#
#   [bar] workspace_layout    1 numbers, 2 icons, 3 text    default 1
#   [bar] transparent         true/false                   default true
#   [bar] opacity             1-100 percent                default 94
#   [idle] screensaver_timeout    minutes idle -> screensaver   default 15
#   [idle] lock_after_screensaver minutes screensaver -> lock   default 15
#   [idle] dpms_off_after_lock    minutes lock -> display off   default 15
#
# They are documented in full in their own sections further down.

# ── Appearance ──────────────────────────────────────────────────────────────
# Theme name. Built in: niru-noir, niru-nord, niru-satie, niru-carl-larsson,
# niru-forest-vigil, niru-blood-of-urdr, niru-root-and-stone, niru-blue-horizon,
# niru-the-norns, niru-winter-nights.
# List them with: niructl themes
theme = "niru-noir"
# ── Layouts ─────────────────────────────────────────────────────────────────
# One of: tile, left, monocle, centered, centeredfloat, fibonacci, floating, scroll.
# Change at runtime with Super+T/Y/M/C/U/F, cycle with Super+Ctrl+period.
# List them all with: niructl layouts
# Space between windows, in pixels.
gap = 8
# Border around each window, in pixels. 0 draws no borders.
border_width = 2
# Height of the bar, in pixels. The bar reserves exactly this much.
bar_height = 28
# Default share of the screen width given to the master column (0.1 to 0.9).
# Each workspace keeps its own ratio after Super+H/L; this is only the default.
master_ratio = 0.55

# ── Programs ────────────────────────────────────────────────────────────────
# Commands are argument lists, never passed through a shell.
terminal = ["kitty"]
# Bound to Super+Shift+Enter. Empty means the terminal above.
terminal_alt = []
# Super+B starts this. Install/select a browser.
browser = ["helium"]
# Super+P and the native action launcher.
launcher = ["nirulauncher", "--apps"]

# ── Font ────────────────────────────────────────────────────────────────────
font_size = 15.0
# font_path = "/path/to/your/monospace.ttf"

# ── Weather location ───────────────────────────────────────────────────────
# The `sun` module shows sunrise and sunset for this place, in degrees; north
# and east are positive. Zero coordinates identify the equator/prime meridian.
# At the top level, not under [bar]: NIRUWM reads this file too and refuses
# fields it does not know, so a setting only the bar uses still has to be
# somewhere both accept.
weather_latitude = 59.33
weather_longitude = 18.07

# ── Wallpaper ───────────────────────────────────────────────────────────────
# NIRUWM sets and rotates the wallpaper only when enabled = true. NIRUX
# installs the four theme wallpaper sets under ~/Pictures/Wallpapers/NIRU.
# Set this false when another program owns the background.
[wallpaper]
enabled = true
# Directory to draw from. Images: jpg, jpeg, png, webp, bmp.
dir = "~/Pictures/Wallpapers"
# random = a new picture each rotation
# fixed  = one picture, chosen once and kept
# single = always `file`
mode = "random"
file = ""
# Minutes between changes. 0 disables rotation.
rotation_minutes = 10
# How a picture fills the screen: fill (crop), fit (letterbox), stretch, center.
scale = "fill"
# Rotate through these files instead of the whole directory. Empty = the
# directory, for example:
#   files = ["~/Pictures/one.jpg", "~/Pictures/two.png"]
files = []
# Pick a fresh picture at login, even in `fixed` mode.
shuffle_on_start = true
# When the theme changes, apply that theme's wallpaper from theme_dir. Your
# own `mode = "single"` file is never overridden.
follow_theme = true
# NIRUX installs nirux-wallpaper-<theme>-4k.png and -8k.png here. A custom
# theme `foo` can provide nirux-wallpaper-foo-4k.png.
theme_dir = "~/Pictures/Wallpapers/NIRU"

# ── Autostart ──────────────────────────────────────────────────────────────
# Optional programs opened once at login. They are grouped by workspace and
# started in workspace order, so a terminal, browser and editor do not all open
# in one heap. Multiple entries on the same workspace run in the order written.
# `command` is an argument list, never a shell string. Empty `apps` means
# nothing starts. A saved-session restore suppresses this sequence so the same
# programs are not opened twice.
[autostart]

enabled = false
# Seconds to wait after each workspace group before moving to the next one.
settle_seconds = 2
# How long to wait for a matched window before moving on. Only used when an
# app has a `class`; entries without one keep the legacy fixed spacing.
window_timeout_ms = 5000
# Return here when the sequence finishes. 0 leaves the last workspace active.
return_workspace = 1
# `class` is an optional case-insensitive substring of WM_CLASS. With it,
# autostart waits for that app's window (even a slow starter) and moves it to
# this workspace. Without it, the app opens normally after a short delay.
# [[autostart.apps]]
# workspace = 1
# class = "nirushare"
# command = ["nirushare", "serve"]
#
# [[autostart.apps]]
# workspace = 1
# class = "kitty"
# command = ["kitty"]
#
# [[autostart.apps]]
# workspace = 3
# class = "helium"
# command = ["helium"]

# Launcher-invoked workspace recipes. They reuse the same class/window
# matching as autostart and return to the workspace you started from.
# [[recipes]]
# name = "Development"
# [[recipes.apps]]
# workspace = 1
# class = "kitty"
# command = ["kitty"]
# [[recipes.apps]]
# workspace = 2
# class = "helium"
# command = ["helium"]



# ── Night light and brightness ─────────────────────────────────────────────
[nightlight]
# Manual night light, applied by `niructl nightlight on` / Super+N.
# 0,0 means no location; manual temperature still works.
latitude = 59.33
longitude = 18.07
temperature = 3400
# manual: Super+N / niructl nightlight on|off
# fixed:  on/off local times every day
# solar:  gammastep computes sunrise/sunset from the coordinates
mode = "manual"
on = "20:00"
off = "07:00"
day_temperature = 6500

[brightness]
# Empty uses brightnessctl's default device; step is the up/down percentage.
device = ""
step = 5

# ── Monitors ────────────────────────────────────────────────────────────────
# Automatic by default: every connected screen gets its own ten workspaces,
# like dwm. Plug a screen in or out and NIRUWM follows.
#
# `profiles` overrides one screen by its RandR name (see `xrandr --listmonitors`
# or `niructl monitors`). Use it when a screen should have named workspaces, a
# different count, or be the one that holds focus at login.

[monitors]
workspaces = 10
# Per-workspace tiling state written by NIRUWM after Super+H/L or Super+I/D:
# master_ratios = [0.55, 0.65, 0.45]
# nmasters = [1, 2, 1]

# [[monitors.profiles]]
# name = "HDMI-1"
# workspaces = ["web", "code", "chat"]
# primary = true

# ── Screensaver and lock ────────────────────────────────────────────────────
# The idle ladder is one sequence:
#
#   active  --screensaver_timeout-->  screensaver  --lock_after_screensaver-->  locked
#
# NIRUIDLE owns both timers in one process, so there is a single timer on each
# step and none can be started twice. User activity before the screensaver
# resets the first timer; activity on the screensaver resets both and returns
# to `active`.
#
# Values are whole minutes.
#
#   screensaver_timeout     minutes of inactivity before the screensaver.
#                           Must be at least 1. 0 is rejected, because it
#                           would mean "never" and leave the screen unlocked.
#   lock_after_screensaver  minutes the screensaver stays up before locking.
#                           0 locks at the same time as the screensaver.
#   dpms_off_after_lock     minutes after locking before the display is
#                           switched off. 0 keeps the display on.
#
# Defaults: 15, 15, 15.
# A value above 1440 (one day) is rejected. At runtime, an out-of-range
# screensaver_timeout falls back to 15 so the screen is never left unlocked.
#
# Example: screensaver after 5 minutes, lock 2 minutes later.
#
# [idle]
# screensaver_timeout = 5
# lock_after_screensaver = 2

[idle]
screensaver_timeout = 15
lock_after_screensaver = 15
dpms_off_after_lock = 15

# ── Bar ─────────────────────────────────────────────────────────────────────
[bar]
# The bar is a separate process; NIRUWM starts it from PATH.
enabled = true
# Screen edge: "top" (default) or "bottom". Runtime hide/show is available
# with `niructl bar hide|show|toggle` and Super+Alt+B cycles top, bottom, hidden.
position = "top"
# Modules to show, in order. Remove one to hide it. A font without the glyphs
# falls back to plain text.
#
#   workspaces  one cell per workspace
#   media       the playing track, scrolling when it is long
#   volume      speaker and percentage; click opens information
#   network     wired link (and Wi-Fi when wifi = false)
#   wifi        Wi-Fi radio and connection; opens the Wi-Fi selector
#   updates     packages that can be upgraded
#   pulse       cpu and memory, with a graph in the panel
#   uptime      how long the machine has been on
#   sun         sunrise and sunset, from top-level coordinates above
#   battery     laptops only; other machines show nothing
#   clock       date and time
#
# `volume` and `media` need wpctl (or amixer) and playerctl; `updates` needs
# the package manager it finds. Each says what is missing when clicked.
# Add "weather" (and optionally "sun") to enable the information panels.
# Add "notifications" for an unread indicator backed by nirunotify.
# Add "dnd" for a bell that shows and toggles Do Not Disturb.
# Add "microphone" for input gain/mute; this does not monitor recording activity.
# Add "bluetooth" for adapter/device status; hidden when no adapter exists.
# Add "powerprofile" for Power saver/Balanced/Performance when PPD is available.
# "wifi" is added automatically after "network" when an adapter exists; set
# `wifi = false` to hide it.
# "niruxupdate" shows a newer NIRUX release than the installed one. It asks
# GitHub once a day, keeps the answer in ~/.cache/nirubar, and is silent when
# there is nothing newer. It never installs anything: click it for the command,
# which you run when you can log out afterwards.
# "scratchpad" shows NIRUWM scratchpads (Super+Shift+S, Super+Alt+1-9): a
# terminal mark while any exist; click it to list, show and hide them. It draws
# nothing while there is no scratchpad.
# "dictation" shows NIRUDICTATE (an extra): a red dot while it records, an
# accent mark while it transcribes; nothing otherwise or when not installed.
# Weather settings live in ~/.config/nirubar/config.toml; see weather.example.toml.
modules = ["workspaces", "layout", "media", "volume", "brightness", "display", "tailscale", "network", "wifi", "mode", "battery", "agent", "dnd", "scratchpad", "dictation", "quicksettings", "updates", "clock"]
# Missing input/provider stays visible even with "muted" visibility.
microphone_visibility = "always" # "always" or "muted"
# Left: information. Right: mute. Scroll: gain (never unmutes).
# Middle: input selector (nirulauncher --microphone).
# Workspace labels. Numbered labels are the default.
#
# Numbered (default):
tags = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
#
# Icon labels: comment out the numbered line and uncomment this one. Use a
# Nerd Font; the bar falls back to text per glyph. Super+1…0 still selects
# workspace 1…10.
# tags = ["\uf015", "\uf121", "\uf086", "\uf0c0", "\uf001", "\uf03d", "\uf0f3", "\uf0ac", "\uf013", "\uf02d"]
#
# Text labels: comment out the numbered line and uncomment this one. Empty
# entries keep the numeric label for that workspace.
# tags = ["web", "code", "chat", "term", "media", "", "", "", "", ""]
# Width of one workspace cell, in pixels.
cell_width = 30
# Workspace label preset. Only the labels change; the workspace count and the
# Super+1..0 shortcuts are identical in every preset.
#
#   1  numbers   1 2 3 4 5 6 7 8 9 10          (default)
#   2  icons     web code chat terminal mail folder ...   (needs a Nerd Font)
#   3  text      web ai ai ai term chat mail folder pchat term
#
# Default: 1. Unset or an unknown number keeps `tags` below, which is the
# same as preset 1 unless you set tags yourself.
# workspace_layout = 1
#
# Bar transparency. The bar paints opaque pixels; when this is true it also
# publishes _NET_WM_WINDOW_OPACITY, and the compositor (picom in NIRUX)
# blends it with the wallpaper. Without a compositor the bar stays opaque.
#
#   true   see-through bar in the current NIRUX look      (default)
#   false  fully opaque bar
#
# `opacity` is the percentage used when transparent is true. Values outside
# 1-100 fall back to the default instead of making the bar disappear.
# transparent = true
# opacity = 94
# Show the focused window title between the workspaces and the status.
title = false
title_max = 20
# Seconds before the title appears. With 2, switching through windows shows no
# titles at all and the one you settle on appears. 0 shows it at once. Only
# useful with `title = true`.
title_delay_seconds = 0
# Date and time.
show_date = true
show_time = true
date_format = "%Y-%m-%d"
time_format = "%H:%M"
# Separator between status modules.
separator = "|"
# Use Nerd Font glyphs for battery and network. Falls back per glyph.
icons = true
# Clicking a module opens a small panel with more detail.
popups = true
# Seconds before an open panel closes itself. 0 waits for a click or Escape.
popup_timeout_seconds = 4
# Characters kept from the media title before an ellipsis.
media_width = 32
# Width of the graph in the pulse panel, in characters.
graph_width = 24
# Minutes between package update checks. The result is cached in
# ~/.cache/nirubar/updates so the bar never runs a package query per redraw.
update_check_minutes = 30
# Let the bar own a system tray. Applications that show a tray icon appear in
# the bar without any other program. Set false if another tray is running.
tray = true

# ── Scratchpads ─────────────────────────────────────────────────────────────
# A scratchpad is a floating window you show and hide with one key, above
# whatever workspace you are on. Showing one hides the one that was shown; the
# key of the shown one hides it again. It is never part of a workspace, so it
# never moves or resizes your other windows.
#
#   Super+Shift+S            the default scratchpad below
#   Super+Alt+1 ... 9        scratchpad 1 ... 9 (NIRUDICTATE's agent mode keeps
#                            its opencode window in 9)
#   Super+Alt+Shift+1 ... 9  send the focused window to scratchpad 1 ... 9
#                            (on the window already there: take it back out)
#   Super+Shift+Space        on a scratchpad: make it a normal window again
#
# The default scratchpad (Super+Shift+S). `command` is started the first time
# and must give its window a class (--class, -class, --name or --app-id), which
# is how the window is recognised. width/height: share of the screen,
# 0.1 to 0.95, default 0.6.
[scratchpad]
command = ["kitty", "--class", "scratchpad"]
width = 0.6
height = 0.6
# A shown scratchpad stays on top until you hide it with its key, even when
# the mouse moves onto another window (that window gets the keyboard focus,
# the scratchpad stays visible above it). Set this to true to hide the
# scratchpad instead as soon as another window gets the focus.
hide_on_focus_loss = false

# Numbered scratchpads need no settings: any window can be sent to any slot
# with Super+Alt+Shift+N. Add a [[scratchpad.slot]] to give a slot a program
# that starts the first time you press Super+Alt+N, or its own size. Each
# command needs its own class. Unset width/height use the values above.
#
# [[scratchpad.slot]]     # Super+Alt+1
# number = 1
# command = ["kitty", "--class", "scratch-btop", "-e", "btop"]
# width = 0.8
# height = 0.8

# ── Window rules ────────────────────────────────────────────────────────────
# [[rules]]
# class = "localsend"
# floating = true
# center = true

# ── Key bindings ────────────────────────────────────────────────────────────
# Mouse: hold Super and drag with button 1 to move a window (a tiled window
# becomes floating), or button 3 to resize it from the nearest corner.
# Super+Shift+Space toggles floating and tiling again.
#
# Every default binding is listed below, so changing one is a single edit.
# An entry with the same keys replaces the default; a new keys entry adds a
# binding. Use action = "unbind" to disable a default binding. An optional
# description = "..." is what the cheat sheet (Super+/) shows for the key.
#
# Modifiers: super, shift, ctrl, alt.
# Keys: Return, space, Tab, Escape, Left/Right/Up/Down, Print, comma, period,
#       slash, minus, equal, backtick, F1..F35, or a single character.
#
# Actions:
#   terminal, terminal_alt, browser, launcher, launcher_unified,
#   launcher_keys (cheat sheet), launcher_emoji (emoji and symbols),
#   window_switcher, lock, start CMD, shell CMD,
#   focus_next, focus_prev, move_next, move_prev,
#   tag N, movetotag N, toggletag N, togglemovetotag N, tag_next, tag_prev,
#   layout tile|left|monocle|centered|centeredfloat|floating|fibonacci|scroll,
#   scroll_columns 1|2|toggle,
#   layout_next, layout_prev,
#   inc_master, dec_master, inc_master_ratio, dec_master_ratio,
#   toggle_float, toggle_fullscreen, swap_next, swap_prev,
#   move_float left|right|up|down, resize_float dx dy,
#   media_key NAME, brightness_step N, nightlight_toggle, dnd_toggle, idle_toggle,
#   close, quit, reload, toggle_gaps, theme NAME,
#   focusmon N, tagmon N   (relative monitor step: -1 or 1)

[[keys]]
keys = "super+Return"
action = "terminal"

[[keys]]
keys = "super+shift+Return"
action = "terminal_alt"

[[keys]]
keys = "super+b"
action = "browser"

[[keys]]
keys = "super+p"
action = "launcher"

[[keys]]
keys = "super+shift+p"
action = "launcher_unified"

# The keybinding cheat sheet: every key in effect (programs such as
# NIRUDICTATE register theirs in ~/.local/share/niru/keys.d), searchable by
# words or by key. Enter runs one; Ctrl+R tells what a pressed key does.
[[keys]]
keys = "super+slash"
action = "launcher_keys"

# The same sheet on a key every layout has. Where "/" is Shift+7 (Swedish,
# German, …) Super+/ is the workspace 7 key and stays workspace 7, so use
# Super+F1 there.
[[keys]]
keys = "super+F1"
action = "launcher_keys"

# Emoji and symbols (©, →, °, €, typographic quotes). Enter pastes into the
# window you were using and restores the clipboard; Shift+Enter only copies;
# Tab changes the skin tone. `:name` in the launcher finds them too.
[[keys]]
keys = "super+period"
action = "launcher_emoji"

# Pick a color from the screen (arrows move 1 px, Shift 10 px; Tab switches
# hex/rgb/hsl; Esc cancels). The color is copied; the last 10 are in the
# launcher's Colors view.
[[keys]]
keys = "super+ctrl+c"
action = "shell nirushot pick"

# Screens. "Focus the next screen" moved from Super+period (now the emoji
# picker) to Super+Alt+period in NIRUWM 0.18, with Super+Alt+comma as its
# pair. Super+comma still focuses the previous screen; with two screens
# either key reaches the other one.
[[keys]]
keys = "super+alt+period"
action = "focusmon 1"

[[keys]]
keys = "super+alt+comma"
action = "focusmon -1"

[[keys]]
keys = "super+comma"
action = "focusmon -1"

[[keys]]
keys = "super+shift+period"
action = "tagmon 1"

[[keys]]
keys = "super+shift+comma"
action = "tagmon -1"

# Remember every open window (workspace, screen, floating) so the next login
# can start them again. Logging out saves too. Needs `restore_session = true`
# at the top of the file to bring them back.
[[keys]]
keys = "super+shift+w"
action = "save_session"

[[keys]]
keys = "super+w"
action = "window_switcher"

[[keys]]
keys = "super+Escape"
action = "lock"

[[keys]]
keys = "super+shift+q"
action = "launcher_unified"

[[keys]]
keys = "super+q"
action = "close"

[[keys]]
keys = "super+ctrl+shift+q"
action = "quit"

[[keys]]
keys = "super+r"
action = "reload"

# Workspaces: show, move, toggle.
[[keys]]
keys = "super+1"
action = "tag 1"

[[keys]]
keys = "super+2"
action = "tag 2"

[[keys]]
keys = "super+3"
action = "tag 3"

[[keys]]
keys = "super+4"
action = "tag 4"

[[keys]]
keys = "super+5"
action = "tag 5"

[[keys]]
keys = "super+6"
action = "tag 6"

[[keys]]
keys = "super+7"
action = "tag 7"

[[keys]]
keys = "super+8"
action = "tag 8"

[[keys]]
keys = "super+9"
action = "tag 9"

[[keys]]
keys = "super+0"
action = "tag 10"

[[keys]]
keys = "super+shift+1"
action = "movetotag 1"

[[keys]]
keys = "super+shift+2"
action = "movetotag 2"

[[keys]]
keys = "super+shift+3"
action = "movetotag 3"

[[keys]]
keys = "super+shift+4"
action = "movetotag 4"

[[keys]]
keys = "super+shift+5"
action = "movetotag 5"

[[keys]]
keys = "super+shift+6"
action = "movetotag 6"

[[keys]]
keys = "super+shift+7"
action = "movetotag 7"

[[keys]]
keys = "super+shift+8"
action = "movetotag 8"

[[keys]]
keys = "super+shift+9"
action = "movetotag 9"

[[keys]]
keys = "super+Tab"
action = "tag_next"

[[keys]]
keys = "super+shift+Tab"
action = "tag_prev"

# Focus and stacking.
[[keys]]
keys = "super+j"
action = "focus_next"

[[keys]]
keys = "super+k"
action = "focus_prev"

[[keys]]
keys = "super+Right"
action = "focus_next"

[[keys]]
keys = "super+Down"
action = "focus_next"

[[keys]]
keys = "super+Left"
action = "focus_prev"

[[keys]]
keys = "super+Up"
action = "focus_prev"

[[keys]]
keys = "super+shift+Right"
action = "move_next"

[[keys]]
keys = "super+shift+Left"
action = "move_prev"

# Layouts.
#   tile          master left, stack right
#   left          master right, stack left
#   monocle       one window fills the screen, others behind it
#   centered      master in the middle, stack either side
#   centeredfloat master centred at 70% height, others floating
#   fibonacci     spiral split
#   scroll        one/two columns, sliding horizontally
#   floating      nothing tiled, windows keep their own size
[[keys]]
keys = "super+t"
action = "layout tile"

[[keys]]
keys = "super+y"
action = "layout left"

[[keys]]
keys = "super+m"
action = "layout monocle"

[[keys]]
keys = "super+c"
action = "layout centered"

[[keys]]
keys = "super+u"
action = "layout centeredfloat"

[[keys]]
keys = "super+f"
action = "layout floating"

[[keys]]
keys = "super+ctrl+e"
action = "layout fibonacci"

# Scroll: one window per column, one or two adjacent columns visible.
[[keys]]
keys = "super+ctrl+s"
action = "layout scroll"

[[keys]]
keys = "super+ctrl+shift+s"
action = "scroll_columns toggle"

[[keys]]
keys = "super+ctrl+comma"
action = "layout_prev"

[[keys]]
keys = "super+ctrl+period"
action = "layout_next"

[[keys]]
keys = "super+h"
action = "dec_master_ratio"

[[keys]]
keys = "super+l"
action = "inc_master_ratio"

[[keys]]
keys = "super+i"
action = "inc_master"

[[keys]]
keys = "super+d"
action = "dec_master"

# Windows.
[[keys]]
keys = "super+shift+space"
action = "toggle_float"

[[keys]]
keys = "super+shift+e"
action = "toggle_fullscreen"

[[keys]]
keys = "super+g"
action = "toggle_gaps"

[[keys]]
keys = "super+ctrl+Left"
action = "move_float left"

[[keys]]
keys = "super+ctrl+Right"
action = "move_float right"

[[keys]]
keys = "super+ctrl+Up"
action = "move_float up"

[[keys]]
keys = "super+ctrl+Down"
action = "move_float down"

# Standalone desktop actions.
[[keys]]
keys = "super+shift+f"
action = "start pcmanfm"

[[keys]]
keys = "super+ctrl+t"
action = "launcher_unified"

[[keys]]
keys = "super+Print"
action = "shell nirushot --full"

[[keys]]
keys = "Print"
action = "shell nirushot --region"

[[keys]]
keys = "super+shift+Print"
action = "shell nirushot --window"
```

</details>

### ~/.config/niruwm/appearance.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `schema` | `1` | Components apply these semantic values, then a user theme file at ~/.config/niruwm/themes/NAME.toml takes precedence. |
| `[colors]` | `background` | `"0f0f10"` (commented example) |  |
| `[colors]` | `surface` | `"161618"` (commented example) |  |
| `[colors]` | `foreground` | `"e5e5e5"` (commented example) |  |
| `[colors]` | `muted` | `"a8a8a8"` (commented example) |  |
| `[colors]` | `border` | `"2a2a2d"` (commented example) |  |
| `[colors]` | `focus` | `"5a5a60"` (commented example) |  |
| `[colors]` | `accent` | `"5a5a60"` (commented example) |  |
| `[colors]` | `selected` | `"26262a"` (commented example) |  |
| `[colors]` | `success` | `"8fbf7f"` (commented example) |  |
| `[colors]` | `warning` | `"d7b36a"` (commented example) |  |
| `[colors]` | `error` | `"d77a7a"` (commented example) |  |
| `[colors]` | `disabled` | `"5a5a5e"` (commented example) |  |
| `[font]` | `size` | `15.0` |  |
| `[font]` | `path` | `"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"` (commented example) |  |
| `[spacing]` | `gap` | `8` |  |
| `[spacing]` | `padding` | `12` |  |
| `[spacing]` | `margin` | `16` |  |
| `[spacing]` | `bar_height` | `28` |  |
| `[focus]` | `width` | `2` | Window border and focus ring width in pixels. |
| `[motion]` | `reduced` | `false` | Stop scrolling titles and other non-essential movement. |

<details><summary>The annotated example file (appearance.example.toml)</summary>

```toml
# NIRU appearance contract, schema 1.
# Location: ~/.config/niruwm/appearance.toml (XDG respected).
#
# Components apply these semantic values, then a user theme file at
# ~/.config/niruwm/themes/NAME.toml takes precedence. An unreadable or
# unsupported file is ignored, so a bad edit never replaces a working theme.
schema = 1

# Colour overrides are optional. Leave [colors] commented out so the selected
# NIRU theme (Noir, Nord, Satie or Carl Larsson) owns the palette. Uncomment a
# key to override that semantic colour in every component.
# [colors]
# background = "0f0f10"
# surface = "161618"
# foreground = "e5e5e5"
# muted = "a8a8a8"
# border = "2a2a2d"
# focus = "5a5a60"
# accent = "5a5a60"
# selected = "26262a"
# success = "8fbf7f"
# warning = "d7b36a"
# error = "d77a7a"
# disabled = "5a5a5e"

[font]
size = 15.0
# path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

[spacing]
gap = 8
padding = 12
margin = 16
bar_height = 28

[focus]
# Window border and focus ring width in pixels.
width = 2

[motion]
# Stop scrolling titles and other non-essential movement.
reduced = false
```

</details>

### ~/.config/nirux/sounds.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `[sounds]` | `enabled` | `true` |  |
| `[sounds]` | `volume` | `35` |  |
| `[sounds]` | `startup` | `true` |  |
| `[sounds]` | `notification` | `true` |  |
| `[sounds]` | `update` | `true` |  |
| `[sounds]` | `shutdown` | `true` |  |
| `[sounds]` | `notification_cooldown_ms` | `2500` |  |
| `[sounds]` | `notification_exclude_apps` | `["nplay", "spotify"]` |  |
| `[sounds]` | `respect_mute` | `true` |  |
| `[sounds.system]` | `enabled` | `true` |  |
| `[sounds.system]` | `auth-fail` | `true` |  |
| `[sounds.system]` | `lock` | `false` |  |
| `[sounds.system]` | `unlock` | `false` |  |
| `[sounds.notifications]` | `enabled` | `true` |  |
| `[sounds.feedback]` | `enabled` | `true` |  |
| `[sounds.feedback]` | `volume-up` | `true` |  |
| `[sounds.feedback]` | `volume-down` | `true` |  |
| `[sounds.feedback]` | `volume-limit` | `true` |  |
| `[sounds.feedback]` | `mute` | `true` |  |
| `[sounds.feedback]` | `unmute` | `true` |  |
| `[sounds.feedback]` | `brightness-up` | `false` |  |
| `[sounds.feedback]` | `brightness-down` | `false` |  |
| `[sounds.feedback]` | `screenshot` | `true` |  |
| `[sounds.feedback]` | `rate_limit_ms` | `80` |  |
| `[sounds.power]` | `enabled` | `true` |  |
| `[sounds.power]` | `power-plug` | `true` |  |
| `[sounds.power]` | `power-unplug` | `true` |  |
| `[sounds.power]` | `battery-low` | `true` |  |
| `[sounds.power]` | `battery-critical` | `true` |  |
| `[sounds.power]` | `battery-full` | `false` |  |
| `[sounds.power]` | `battery_low_percent` | `20` |  |
| `[sounds.power]` | `battery_critical_percent` | `5` |  |
| `[sounds.power]` | `battery_full_percent` | `100` |  |
| `[sounds.devices]` | `enabled` | `true` |  |
| `[sounds.devices]` | `device-connect` | `true` |  |
| `[sounds.devices]` | `device-disconnect` | `true` |  |
| `[sounds.devices]` | `usb` | `true` |  |
| `[sounds.devices]` | `audio` | `true` |  |
| `[sounds.devices]` | `displays` | `true` |  |
| `[sounds.devices]` | `bluetooth` | `false` |  |
| `[sounds.devices]` | `debounce_ms` | `1500` |  |
| `[sounds.dictation]` | `enabled` | `true` |  |
| `[sounds.dictation]` | `dictation-start` | `true` |  |
| `[sounds.dictation]` | `dictation-stop` | `true` |  |
| `[sounds.dictation]` | `dictation-done` | `false` |  |
| `[sounds.dictation]` | `dictation-error` | `true` |  |
| `[sounds.apps]` | `thunderbird` | `"mail"` |  |
| `[sounds.apps]` | `signal` | `"chat"` |  |

<details><summary>The annotated example file (sounds.example.toml)</summary>

```toml
[sounds]
enabled = true
volume = 35
startup = true
notification = true
update = true
shutdown = true
notification_cooldown_ms = 2500
notification_exclude_apps = ["nplay", "spotify"]
respect_mute = true

# System sounds. startup, update and shutdown are switched in [sounds] above.
[sounds.system]
enabled = true
auth-fail = true
lock = false
unlock = false

# Notification sounds (the notification key in [sounds] above and the app
# sounds in [sounds.apps]). Do Not Disturb silences these and nothing else.
[sounds.notifications]
enabled = true

# Feedback for keys you press. Volume ticks play on the new level, so you
# hear how loud it is; holding a key plays at most one tick per rate_limit_ms.
[sounds.feedback]
enabled = true
volume-up = true
volume-down = true
volume-limit = true
mute = true
unmute = true
brightness-up = false
brightness-down = false
screenshot = true
rate_limit_ms = 80

# Charger and battery. battery-low and battery-critical sound once per
# discharge when the battery falls to the given percentage.
[sounds.power]
enabled = true
power-plug = true
power-unplug = true
battery-low = true
battery-critical = true
battery-full = false
battery_low_percent = 20
battery_critical_percent = 5
battery_full_percent = 100

# Devices that come and go: USB, audio devices, monitors and, if you want,
# Bluetooth links. A burst (a dock) is one sound per debounce_ms.
[sounds.devices]
enabled = true
device-connect = true
device-disconnect = true
usb = true
audio = true
displays = true
bluetooth = false
debounce_ms = 1500

# NIRUDICTATE (an extra): start and stop of a dictation, the text being
# inserted, and a dictation that failed. Silent without NIRUDICTATE.
[sounds.dictation]
enabled = true
dictation-start = true
dictation-stop = true
dictation-done = false
dictation-error = true

# Per-app notification sounds. The key is the app name a notification is sent
# with (see `nirunotify --history`), compared case-insensitively. The value is
# a sound name, which plays NAME.ogg from ~/.config/nirux/sounds or the NIRUX
# sounds; a file path (absolute or ~/...); "default" for the normal
# notification sound; or "off" to keep the notification silent.
[sounds.apps]
thunderbird = "mail"
signal = "chat"
```

</details>

### ~/.config/niruwm/displays.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `automatic` | `true` (commented example) | Switch profiles automatically when screens are plugged in or out or the laptop lid closes. |
| `(top level)` | `startup_profile` | `"Desk"` (commented example) | Applied once at login (niructl display startup set NAME). |
| `[profile]` | `name` | `"Laptop"` |  |
| `[profile.outputs]` | `name` | `"eDP-1"` |  |
| `[profile.outputs]` | `mode` | `"preferred"` |  |
| `[profile.outputs]` | `position` | `"0x0"` |  |
| `[profile.outputs]` | `rotation` | `"normal"` |  |
| `[profile.outputs]` | `primary` | `true` |  |
| `[profile]` | `name` | `"Desk"` |  |
| `[profile.outputs]` | `name` | `"eDP-1"` |  |
| `[profile.outputs]` | `mode` | `"preferred"` |  |
| `[profile.outputs]` | `position` | `"0x0"` |  |
| `[profile.outputs]` | `rotation` | `"normal"` |  |
| `[profile.outputs]` | `primary` | `true` |  |
| `[profile.outputs]` | `name` | `"HDMI-1"` |  |
| `[profile.outputs]` | `mode` | `"2560x1440"` |  |
| `[profile.outputs]` | `rate` | `59.95` |  |
| `[profile.outputs]` | `position` | `"1920x0"` |  |
| `[profile.outputs]` | `rotation` | `"normal"` |  |
| `[profile.outputs]` | `primary` | `false` |  |
| `[profile.outputs.identity]` | `manufacturer` | `"DEL"` |  |
| `[profile.outputs.identity]` | `product_code` | `41234` |  |
| `[profile.outputs.identity]` | `model` | `"DELL U2723QE"` |  |
| `[profile.outputs.identity]` | `serial` | `"ABC1234"` |  |
| `[profile]` | `name` | `"Docked"` |  |
| `[profile.outputs]` | `name` | `"DP-2"` |  |
| `[profile.outputs]` | `mode` | `"preferred"` |  |
| `[profile.outputs]` | `position` | `"0x0"` |  |
| `[profile.outputs]` | `rotation` | `"normal"` |  |
| `[profile.outputs]` | `primary` | `true` |  |
| `[profile.outputs.identity]` | `manufacturer` | `"DEL"` |  |
| `[profile.outputs.identity]` | `product_code` | `41234` |  |
| `[profile.outputs.identity]` | `model` | `"DELL U2723QE"` |  |
| `[profile.outputs.identity]` | `serial` | `"ABC1234"` |  |
| `[profile.off]` | `name` | `"eDP-1"` |  |
| `[profile]` | `name` | `"Presentation"` |  |
| `[profile]` | `auto` | `false` |  |
| `[profile.outputs]` | `name` | `"HDMI-1"` |  |
| `[profile.outputs]` | `mode` | `"preferred"` |  |
| `[profile.outputs]` | `position` | `"0x0"` |  |
| `[profile.outputs]` | `rotation` | `"normal"` |  |
| `[profile.outputs]` | `primary` | `true` |  |

<details><summary>The annotated example file (displays.example.toml)</summary>

```toml
# NIRUX display profiles: ~/.config/niruwm/displays.toml.
#
# The easiest way to make one is to arrange the screens (NIRU Display, or
# xrandr) and save the result: `niructl display save NAME`, or Save as… in
# NIRU Display. Saving records each screen's identity (make, model and serial
# from its EDID), so the profile follows its screens even when connector names
# change. This file shows the format for writing or editing one by hand.
#
# Try a profile:   niructl display preview NAME [SECONDS]
# Keep it:         niructl display keep TOKEN   (the token is printed)
# Undo it:         niructl display revert TOKEN
# What fits now:   niructl display doctor
# Full reference:  https://github.com/nirucon/niruwm/blob/main/docs/display-profiles.md

# Switch profiles automatically when screens are plugged in or out or the
# laptop lid closes. Off unless set (niructl display automatic on|off).
# automatic = true

# Applied once at login (niructl display startup set NAME).
# startup_profile = "Desk"

[[profile]]
name = "Laptop"
[[profile.outputs]]
name = "eDP-1"
mode = "preferred"
position = "0x0"
rotation = "normal"
primary = true

# Laptop open next to one external screen. With an identity the entry follows
# that monitor to whatever connector it is on; without one it matches the
# connector name, exactly as profiles from before NIRUWM 0.17 do.
[[profile]]
name = "Desk"
[[profile.outputs]]
name = "eDP-1"
mode = "preferred"
position = "0x0"
rotation = "normal"
primary = true
[[profile.outputs]]
name = "HDMI-1"
mode = "2560x1440"
rate = 59.95
position = "1920x0"
rotation = "normal"
primary = false
[profile.outputs.identity]
manufacturer = "DEL"
product_code = 41234
model = "DELL U2723QE"
serial = "ABC1234"

# Lid closed on a dock: only the external screen. `off` names the screens the
# profile leaves off on purpose, so it also fits with the lid open.
[[profile]]
name = "Docked"
[[profile.outputs]]
name = "DP-2"
mode = "preferred"
position = "0x0"
rotation = "normal"
primary = true
[profile.outputs.identity]
manufacturer = "DEL"
product_code = 41234
model = "DELL U2723QE"
serial = "ABC1234"
[[profile.off]]
name = "eDP-1"

# A profile only for applying by hand: never chosen automatically.
[[profile]]
name = "Presentation"
auto = false
[[profile.outputs]]
name = "HDMI-1"
mode = "preferred"
position = "0x0"
rotation = "normal"
primary = true
```

</details>

### ~/.config/nirubar/config.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `[weather]` | `location` | `"Stockholm"` |  |
| `[weather]` | `latitude` | `59.33` |  |
| `[weather]` | `longitude` | `18.07` |  |
| `[weather]` | `refresh_minutes` | `30` | Refresh interval in minutes. |
| `[calendar]` | `refresh_minutes` | `15` (commented example) |  |
| `[calendar]` | `days_ahead` | `7` (commented example) |  |
| `[calendar]` | `show_in_bar` | `false` (commented example) |  |

<details><summary>The annotated example file (weather.example.toml)</summary>

```toml
# NIRUBAR weather settings.
# Location: ~/.config/nirubar/config.toml (or $XDG_CONFIG_HOME/nirubar/).
# Add "weather" to [bar] modules in the shared niruwm config to show it.

[weather]
location = "Stockholm"
latitude = 59.33
longitude = 18.07
# Refresh interval in minutes. 30 is the default; stale data stays visible.
refresh_minutes = 30

# Calendar events in the clock popup. The feeds and their secret URLs live in
# ~/.config/nirubar/calendars.toml (see calendars.example.toml); these are
# the non-secret options, shown with their defaults.
# [calendar]
# refresh_minutes = 15   # 5 to 1440
# days_ahead = 7         # agenda: today and the next N days (0 to 31)
# show_in_bar = false    # next event within 12 h before the clock
```

</details>

### ~/.config/nirulauncher/config.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `width` | `640` | Window width in pixels. |
| `(top level)` | `max_rows` | `12` | Maximum visible result rows. |
| `(top level)` | `row_height` | `26` | One result row, in pixels. |
| `(top level)` | `padding` | `12` | Inner padding, in pixels. |
| `(top level)` | `font_size` | `15.0` | Font size. |
| `(top level)` | `font_path` | `"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"` (commented example) |  |
| `(top level)` | `terminal` | `["kitty"]` | Applications with Terminal=true are started through this argv array. |
| `(top level)` | `browser` | `["brave"]` (commented example) | Leave empty to use NIRUWM's browser from ~/.config/niruwm/config.toml, then $BROWSER, then xdg-open (the desktop's default browser). |
| `[search.sources]` | `id` | `"searx"` (commented example) |  |
| `[search.sources]` | `label` | `"SearXNG (home)"` (commented example) |  |
| `[search.sources]` | `url` | `"https://searx.example/search?q={query}"` (commented example) |  |
| `[search.sources]` | `alias` | `"sx"` (commented example) |  |
| `[search.sources]` | `id` | `"google"` (commented example) |  |
| `[search.sources]` | `label` | `"Google (no tracking)"` (commented example) |  |
| `[search.sources]` | `url` | `"https://www.google.com/search?q={query}&pws=0"` (commented example) |  |
| `[search.sources]` | `id` | `"grok"` (commented example) |  |
| `[search.sources]` | `enabled` | `false` (commented example) |  |
| `[search]` | `default` | `"duckduckgo"` (commented example) |  |
| `[search]` | `order` | `["duckduckgo", "github", "archwiki", "wikipedia"]` (commented example) |  |
| `[search]` | `aliases` | `{ gh = "github", aw = "archwiki", yt = "youtube" }` (commented example) |  |
| `[search]` | `favorites` | `["firefox.desktop", "Lock screen"]` (commented example) | Desktop-file IDs or action names pinned above search rank. |
| `[search]` | `rank_by_usage` | `true` (commented example) | Order equal search matches by how often and how recently they were launched (local history in ~/.local/state/nirulauncher/usage.tsv), and... |
| `[files]` | `enabled` | `true` (commented example) |  |
| `[files]` | `roots` | `["~"]` (commented example) |  |
| `[files]` | `backend` | `"auto"` (commented example) |  |
| `[files]` | `max_results` | `50` (commented example) |  |
| `[files]` | `show_hidden` | `false` (commented example) |  |
| `[files]` | `locate_db` | `"~/.cache/files.db"` (commented example) | A plocate/locate database to search instead of the system one (-d), e.g. |
| `[files]` | `exclude` | `[".cache", ".local/share/Trash", ".git", "node_modules", ...` (commented example) | exclude replaces this built-in list: names anywhere, or paths below a root when they contain a slash; * and ? match like a shell glob. |

<details><summary>The annotated example file (config.example.toml)</summary>

```toml
# NIRULAUNCHER settings.
# Location: ~/.config/nirulauncher/config.toml (or $XDG_CONFIG_HOME/nirulauncher/)
#
# Colours come from the suite theme selected in ~/.config/niruwm/config.toml.
# A user theme file in ~/.config/niruwm/themes/NAME.toml takes precedence.

# Window width in pixels. Clamped to the selected monitor.
width = 640
# Maximum visible result rows. The window grows with fewer results.
max_rows = 12
# One result row, in pixels.
row_height = 26
# Inner padding, in pixels.
padding = 12
# Font size. Use font_path for a specific font file.
font_size = 15.0
# font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

# Applications with Terminal=true are started through this argv array.
terminal = ["kitty"]

# How a web search opens: the program, then the address.
# Leave empty to use NIRUWM's `browser` from ~/.config/niruwm/config.toml,
# then $BROWSER, then xdg-open (the desktop's default browser).
# browser = ["brave"]

# Web search engines, shown by Super+S. Every enabled engine is listed before
# anything is typed, and the first character already searches. Seventeen are
# built in and need no configuration:
# duckduckgo, brave, google, wikipedia, wikipedia-sv, youtube, github,
# archwiki, crates, docsrs, chatgpt, gemini, grok, copilot, discogs,
# musicbrainz, metal-archives. `nirulauncher --list-search` prints their ids,
# labels, templates and hosts.
#
# Add or override an engine with a `[[search.sources]]` entry. An id that
# matches a built-in replaces it in place; a new id is appended. `{query}` is
# replaced by the percent-encoded text (`{}` works too; a template with
# neither gets `?q=` appended). Only http(s) addresses are opened, so a typo
# cannot start a local program. `alias` selects the engine with
# "alias phrase" in the search field.
#
# [[search.sources]]
# id = "searx"
# label = "SearXNG (home)"
# url = "https://searx.example/search?q={query}"
# alias = "sx"
#
# [[search.sources]]
# id = "google"
# label = "Google (no tracking)"
# url = "https://www.google.com/search?q={query}&pws=0"
#
# To leave an engine out, turn it off by id:
#
# [[search.sources]]
# id = "grok"
# enabled = false

# Search preferences. `order` lists the ids shown first; the rest keep their
# built-in order. `default` is selected when the field is empty. `aliases`
# overrides a built-in alias without redefining the engine.
#
# [search]
# default = "duckduckgo"
# order = ["duckduckgo", "github", "archwiki", "wikipedia"]
# aliases = { gh = "github", aw = "archwiki", yt = "youtube" }

# A typed http:// or https:// address is offered as "Open address" above the
# engine rows. Enter on an empty field keeps the launcher open.

# Desktop-file IDs or action names pinned above search rank.
# favorites = ["firefox.desktop", "Lock screen"]

# Order equal search matches by how often and how recently they were launched
# (local history in ~/.local/state/nirulauncher/usage.tsv), and show up to five
# recent rows after the favourites when the field is empty. A better text
# match always wins over frequent use.
# rank_by_usage = true

# File search: `--files`, "Find files" in NIRU Actions, or `/ name` in the
# unified view. Every key is optional. Results come from plocate/locate when
# its database covers the roots, else fd/fdfind, else a bounded built-in walk
# (backend = "auto"); "plocate", "locate", "fd" and "builtin" choose one.
# Recently used files (~/.local/share/recently-used.xbel) come first.
#
# [files]
# enabled = true
# roots = ["~"]
# backend = "auto"
# max_results = 50
# show_hidden = false
# A plocate/locate database to search instead of the system one (-d), e.g.
# one built without root: updatedb.plocate -o ~/.cache/files.db -U ~ -l no
# locate_db = "~/.cache/files.db"
# `exclude` replaces this built-in list: names anywhere, or paths below a
# root when they contain a slash; `*` and `?` match like a shell glob.
# exclude = [".cache", ".local/share/Trash", ".git", "node_modules", "target",
#            "__pycache__", ".venv", ".mypy_cache", ".pytest_cache", ".tox",
#            ".gradle", ".npm", ".cargo", ".rustup"]
```

</details>

### ~/.config/nirunotify/config.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `width` | `360` | Width of each notification surface, in pixels. |
| `(top level)` | `margin` | `12` | Gap from the screen edge and between stacked notifications. |
| `(top level)` | `max_visible` | `5` | Maximum visible notifications. |
| `(top level)` | `default_timeout_ms` | `6000` | Server-side default when a client sends -1. |
| `(top level)` | `max_timeout_ms` | `60000` | Upper bound for any timeout, including a client's persistent 0. |
| `(top level)` | `critical_timeout_ms` | `30000` | Urgent notifications use this timeout; they may also bypass DND if enabled. |
| `(top level)` | `critical_ignore_dnd` | `false` |  |
| `(top level)` | `monitor` | `""` | Empty = monitor under the pointer; "primary" = RandR primary; or an output name. |
| `(top level)` | `font_path` | `"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"` (commented example) |  |
| `(top level)` | `font_size` | `14.0` |  |
| `(top level)` | `position` | `"top-right"` | top-right, top-left, bottom-right or bottom-left. |

<details><summary>The annotated example file (config.example.toml)</summary>

```toml
# NIRUNOTIFY settings.
# Location: ~/.config/nirunotify/config.toml (or $XDG_CONFIG_HOME/nirunotify/)
#
# Colours follow the active NIRUWM theme (`theme` in niruwm/config.toml) and
# update live after `niructl theme` or `niructl reload`. Font, margin and
# spacing come from niruwm/appearance.toml unless set explicitly below.

# Width of each notification surface, in pixels.
width = 360
# Gap from the screen edge and between stacked notifications.
margin = 12
# Maximum visible notifications. Older ones stay in memory history.
max_visible = 5
# Server-side default when a client sends -1.
default_timeout_ms = 6000
# Upper bound for any timeout, including a client's persistent 0.
max_timeout_ms = 60000
# Urgent notifications use this timeout; they may also bypass DND if enabled.
critical_timeout_ms = 30000
critical_ignore_dnd = false
# Empty = monitor under the pointer; "primary" = RandR primary; or an output name.
monitor = ""
# font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
font_size = 14.0
# top-right, top-left, bottom-right or bottom-left.
position = "top-right"
```

</details>

### ~/.config/niruui/lock.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `font_path` | `"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"` (commented example) | ~/.config/niruui/lock.toml; every setting is optional. |
| `(top level)` | `font_size` | `22.0` |  |
| `(top level)` | `layout` | `"cava"` | minimal \| terminal \| runic \| corner \| cava cava uses the active NIRUX theme and visualises system audio through CAVA. |
| `(top level)` | `visualizer` | `true` |  |
| `(top level)` | `visual` | `"auto"` | What the cava layout shows where the spectrum is drawn: "auto"   the CAVA spectrum only while music or radio plays, otherwise a quote fro... |
| `(top level)` | `quotes` | `["*"]` | Built-in: havamal-en, havamal-sv, stoic-en, stoic-sv. |
| `(top level)` | `prompt_echo` | `"count"` | How the prompt echoes the password: "count" shows one * per character (the default); "pulse" shows a fixed row of eight cells with one li... |
| `(top level)` | `show_hostname` | `false` | Show the machine's hostname under the clock. |
| `(top level)` | `rune_font_path` | `"/usr/share/fonts/truetype/noto/NotoSansRunic-Regular.ttf"` (commented example) | Optional: use a specific runic font. |
| `[pause_music]` | `enabled` | `false` |  |
| `[pause_music]` | `folder` | `"~/Music/SID"` | .sid files, searched recursively and played in natural order (1-, 2-, 10-). |
| `[pause_music]` | `track_seconds` | `180` | DOCUMENTS directory) knows the length. |
| `[pause_music]` | `stop_on_display_off` | `true` |  |
| `[pause_music]` | `on` | `["manual"]` | Lock reasons that may play: manual (a key, the launcher, niructl lock in a terminal), idle (NIRUIDLE), suspend (lock before suspend), s... |
| `[palette]` | `background` | `"000000"` |  |
| `[palette]` | `foreground` | `"e5e5e5"` |  |
| `[palette]` | `muted` | `"a8a8a8"` |  |
| `[palette]` | `border` | `"2a2a2d"` |  |
| `[palette]` | `focus` | `"5a5a60"` |  |
| `[palette]` | `warning` | `"d7b36a"` (commented example) | Failure feedback; defaults to the appearance contract's warning colour. |

<details><summary>The annotated example file (config.example.toml)</summary>

```toml
# ~/.config/niruui/lock.toml; every setting is optional.
# font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
font_size = 22.0

# minimal | terminal | runic | corner | cava
# cava uses the active NIRUX theme and visualises system audio through CAVA.
layout = "cava"
visualizer = true
# What the cava layout shows where the spectrum is drawn:
#   "auto"   the CAVA spectrum only while music or radio plays, otherwise a
#            quote from ~/.config/niru/quotes/ (the default)
#   "cava"   the spectrum alone, as before 0.19 (CAVA runs whenever the display is on)
#   "quotes" quotes alone; CAVA never starts
#   "none"   neither (visualizer = false also means this)
visual = "auto"
# Which quote collections (~/.config/niru/quotes/NAME.txt) to show, by name;
# "*" matches anything, "?" one character. One pattern or an array:
#   quotes = ["*"]                       every collection (the default)
#   quotes = "havamal-sv"                one collection
#   quotes = ["havamal-*", "stoic-en"]   several
# Built-in: havamal-en, havamal-sv, stoic-en, stoic-sv. See the README.
quotes = ["*"]

# How the prompt echoes the password: "count" shows one * per character (the
# default); "pulse" shows a fixed row of eight cells with one lit * that moves
# to a random cell on every key, so the length is never shown.
prompt_echo = "count"

# Show the machine's hostname under the clock. Off by default, so a locked
# screen in a shared place does not name the machine.
show_hostname = false

# Optional: use a specific runic font. The runic layout omits its ornament if
# no rune font is available; it never draws missing-glyph boxes.
# rune_font_path = "/usr/share/fonts/truetype/noto/NotoSansRunic-Regular.ttf"

# Pause music: Commodore 64 SID tunes while the screen is locked. Off by
# default. Needs sidplayfp. Starts only when no other audio plays in the first
# seconds after locking; Esc, unlock, suspend and (by default) the display
# going off stop it for the rest of the lock. Only plays for the lock reasons
# in `on` (see `nirulock --help`): by default only when you lock by hand.
[pause_music]
enabled = false
# .sid files, searched recursively and played in natural order (1-, 2-, 10-).
folder = "~/Music/SID"
# Seconds per tune, unless the HVSC Songlengths.md5 in the folder (or its
# DOCUMENTS directory) knows the length.
track_seconds = 180
stop_on_display_off = true
# Lock reasons that may play: manual (a key, the launcher, `niructl lock` in a
# terminal), idle (NIRUIDLE), suspend (lock before suspend), script
# (`niructl lock --silent`, SSH), session, and unspecified (an older caller
# that gives no reason). Leave it out for the default, ["manual"].
on = ["manual"]

[palette]
background = "000000"
foreground = "e5e5e5"
muted = "a8a8a8"
border = "2a2a2d"
focus = "5a5a60"
# Failure feedback; defaults to the appearance contract's warning colour.
# warning = "d7b36a"
```

</details>

### ~/.config/niruui/screensaver.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `(top level)` | `font_path` | `"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"` (commented example) | ~/.config/niruui/screensaver.toml; every setting is optional. |
| `(top level)` | `font_size` | `22.0` |  |
| `(top level)` | `clock_size` | `88.0` |  |
| `(top level)` | `layout` | `"cava"` | minimal \| terminal \| runic \| corner \| cava cava uses the active NIRUX theme and visualises system audio through CAVA. |
| `(top level)` | `visualizer` | `true` |  |
| `(top level)` | `visual` | `"auto"` | What the cava layout shows where the spectrum is drawn: "auto"   the CAVA spectrum only while music or radio plays, otherwise a quote fro... |
| `(top level)` | `quotes` | `["*"]` | Built-in: havamal-en, havamal-sv, stoic-en, stoic-sv. |
| `(top level)` | `show_media` | `true` | Show "Artist – Title" of the playing MPRIS player under the spectrum (needs playerctl; followed only while the spectrum is live). |
| `(top level)` | `rune_font_path` | `"/usr/share/fonts/truetype/noto/NotoSansRunic-Regular.ttf"` (commented example) | Optional: use a specific runic font. |
| `(top level)` | `idle_minutes` | `10` |  |
| `(top level)` | `lock_after_minutes` | `5` |  |
| `(top level)` | `dpms_off_minutes` | `0` |  |
| `(top level)` | `show_away_after_seconds` | `60` |  |
| `(top level)` | `dismiss_on_motion` | `false` | A key or click always dismisses the screen. |
| `(top level)` | `reduced_motion` | `false` | The screen fades in from black over 300 ms; true shows it at once. |
| `(top level)` | `show_hostname` | `false` | Show the machine's hostname under the clock. |
| `[palette]` | `background` | `"000000"` |  |
| `[palette]` | `foreground` | `"e5e5e5"` |  |
| `[palette]` | `muted` | `"a8a8a8"` |  |
| `[palette]` | `border` | `"2a2a2d"` |  |
| `[palette]` | `focus` | `"5a5a60"` |  |

<details><summary>The annotated example file (config.example.toml)</summary>

```toml
# ~/.config/niruui/screensaver.toml; every setting is optional.
# font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
font_size = 22.0
clock_size = 88.0

# minimal | terminal | runic | corner | cava
# cava uses the active NIRUX theme and visualises system audio through CAVA.
layout = "cava"
visualizer = true
# What the cava layout shows where the spectrum is drawn:
#   "auto"   the CAVA spectrum only while music or radio plays, otherwise a
#            quote from ~/.config/niru/quotes/ (the default)
#   "cava"   the spectrum alone, as before 0.19 (CAVA runs whenever the display is on)
#   "quotes" quotes alone; CAVA never starts
#   "none"   neither (visualizer = false also means this)
visual = "auto"
# Which quote collections (~/.config/niru/quotes/NAME.txt) to show, by name;
# "*" matches anything, "?" one character. One pattern or an array:
#   quotes = ["*"]                       every collection (the default)
#   quotes = "havamal-sv"                one collection
#   quotes = ["havamal-*", "stoic-en"]   several
# Built-in: havamal-en, havamal-sv, stoic-en, stoic-sv. See the README.
quotes = ["*"]
# Show "Artist – Title" of the playing MPRIS player under the spectrum
# (needs playerctl; followed only while the spectrum is live).
show_media = true

# Optional: use a specific runic font. Missing rune fonts simply omit the
# ornament; the saver never draws missing-glyph boxes.
# rune_font_path = "/usr/share/fonts/truetype/noto/NotoSansRunic-Regular.ttf"

idle_minutes = 10
lock_after_minutes = 5
dpms_off_minutes = 0
show_away_after_seconds = 60

# A key or click always dismisses the screen. Pointer motion does not, so a
# bumped desk does not wake it; set this to dismiss after the pointer has
# moved more than 24 px since the screen appeared.
dismiss_on_motion = false

# The screen fades in from black over 300 ms; true shows it at once.
reduced_motion = false

# Show the machine's hostname under the clock. Off by default, so a screen in
# a shared place does not name the machine.
show_hostname = false

[palette]
background = "000000"
foreground = "e5e5e5"
muted = "a8a8a8"
border = "2a2a2d"
focus = "5a5a60"
```

</details>

### ~/.config/nirushare/webhooks.toml

| Section | Key | Example value | Meaning |
|---|---|---|---|
| `[webhook.friends]` | `url` | `"https://discord.com/api/webhooks/000000000000000000/repl...` |  |
| `[webhook.work-log]` | `url` | `"https://discord.com/api/webhooks/000000000000000000/repl...` |  |
| `[webhook.work-log]` | `username` | `"Niru"` |  |
| `[webhook.work-log]` | `avatar_url` | `"https://example.com/avatar.png"` |  |
| `[webhook.work-log]` | `embeds` | `false` |  |
| `[webhook.work-log]` | `max_file_mb` | `10` |  |

<details><summary>The annotated example file (webhooks.example.toml)</summary>

```toml
# NIRUSHARE Discord webhooks: ~/.config/nirushare/webhooks.toml
#
# There are no webhooks until you add them here. Keep this file private:
#     chmod 600 ~/.config/nirushare/webhooks.toml
# A webhook URL works like a password: anyone who has it can post to the
# channel. NIRUSHARE never prints, logs or queues the URL; everything else
# refers to a webhook by its name (send --to discord:NAME).
#
# Create a webhook in Discord: Server Settings -> Integrations -> Webhooks ->
# New Webhook -> Copy Webhook URL.
#
# The URLs below are placeholders and do not work.

[webhook.friends]
url = "https://discord.com/api/webhooks/000000000000000000/replace-with-the-token-from-discord"

[webhook.work-log]
url = "https://discord.com/api/webhooks/000000000000000000/replace-with-the-token-from-discord"
username = "Niru"                            # optional: the name shown on the message
avatar_url = "https://example.com/avatar.png"  # optional: the picture shown on the message
embeds = false                               # optional: no link previews (default true)
max_file_mb = 10                             # optional: the server's upload limit (default 10)

# A forum or thread: add ?thread_id=<id> to the URL.
```

</details>

<!-- end generated: config -->

## See also

- [Key bindings](15-key-bindings.md)
- [Command reference](16-commands.md)
- [Troubleshooting](13-troubleshooting.md)
