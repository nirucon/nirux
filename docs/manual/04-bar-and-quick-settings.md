# The bar and Quick Settings

NIRUBAR is the status bar: one bar per monitor with workspace cells, status modules, click panels, a system tray and an entry to Quick Settings. This chapter covers every module, the mouse conventions, the calendar, weather, transparency and the `niructl bar` commands.

## How the bar works

NIRUWM starts one NIRUBAR per monitor at login. Each bar has its own workspace cells (the ten workspaces of that monitor) and its own clock. The bar reads its settings from the `[bar]` table of the shared file `~/.config/niruwm/config.toml`; colours and font come from the active NIRUX theme.

The mouse works the same way in every module:

| Mouse | Effect |
|---|---|
| Left click | Opens an information panel. It never changes playback, mute or power. |
| Right click | The module's explicit action (play/pause, mute, power, next profile, stop). |
| Scroll | Change a value (volume, microphone gain, previous/next track). |
| Middle click | Opens the keyboard-first control view where one exists. |

Only one panel is open at a time. `Escape`, a click elsewhere or a second click on the same module closes it. Quick-glance panels (volume, microphone, network, battery, Bluetooth, media, power profile, brightness, updates, uptime, display and the rest) also close by themselves after `popup_timeout_seconds` (default 4). Panels you read stay open until you close them: the calendar (clock), weather, tasks, pulse and notifications. See [Panel timeouts](#panel-timeouts). The panel footer says whether it is informational or has controls; press `Enter` or click the footer to open the control view (usually a NIRU Launcher view).

A few modules skip the panel and act on a left click: `wifi`, `agent`, `share`, `nirusec` and `dnd`.

When the bar is too narrow, low-priority modules collapse into a clickable `+N`; click it to see the hidden modules.

## Modules

Choose and order the modules with `[bar] modules`. A module without a provider hides itself (no battery on a desktop, no brightness without a backlight, no Bluetooth without an adapter). An unknown name is reported on stderr and ignored.

| Module | Shows | Left click | Right click / scroll / middle |
|---|---|---|---|
| `workspaces` | Ten cells for this monitor: active, occupied (small accent marker), urgent (attention colour) | Switch to that workspace | |
| `layout` | Current NIRUWM layout; the Scroll layout shows `scroll 1` / `scroll 2` | List of layouts and column controls | |
| `media` | Playing title with a progress hairline; long titles scroll | Track information | Right: play/pause. Scroll up: previous, down: next. Middle: switch to the next player |
| `volume` | Output level or mute | Information | Right: mute. Scroll: volume up/down 5 %. Middle: microphone mute |
| `microphone` | Input mute and gain (not a recording indicator) | Information | Right: mute. Scroll: gain. Middle: input selector (`nirulauncher --microphone`) |
| `brightness` | Backlight percentage; hidden without a readable backlight | Information | |
| `display` | This bar's screen position (`Left`, `Center`, `Right`, `Top`, `Bottom`, diagonals or `Mirror`) | Outputs; footer opens display profiles | Middle: `nirulauncher --displays` |
| `tailscale` | Online Tailscale peers; only when `tailscale` is installed | Peer state; footer opens `nirulauncher --tailscale` | |
| `network` | Wired link; `!` means link up without a default route. Also Wi-Fi when `wifi = false` | Interface, route and address | |
| `wifi` | Wi-Fi radio and connection; `!` means radio off or not connected | Opens the Wi-Fi selector (`nirulauncher --wifi`) | |
| `bluetooth` | Off, on or the connected device | Information; footer opens devices | Right: power on/off. Middle: device selector |
| `powerprofile` | Active power profile (needs `power-profiles-daemon`) | Information | Right: next profile. Middle: `nirulauncher --power` |
| `battery` | Aggregated charge and state; laptops only | Charge, state and remaining time | |
| `mode` | Active work mode (focus/presentation) and minutes left, and *studio* while studio mode is on | Shows `niructl mode stop` or `niructl studio off` | |
| `tasks` | Running or waiting NIRU/OpenCode tasks (`niructl task list`) | Recent states; footer opens NIRU Actions | |
| `agent` | OpenCode entry | Opens a one-line prompt (`nirulauncher --agent`) | |
| `nirusec` | NIRUSEC state mark (an extra) | Opens `nirusec` | |
| `dnd` | Bell or slashed bell | Toggles Do Not Disturb | Right: Quick Settings |
| `notifications` | NIRUNOTIFY history count | Recent notifications | |
| `scratchpad` | A terminal mark while a scratchpad exists, with a count for several; accent while one is shown; `!` when one asks for attention | Panel with one row per scratchpad; click a row to show or hide it | Right: the default scratchpad |
| `dictation` | NIRUDICTATE: red `●` recording, `…` transcribing, `AI` in agent mode; nothing when idle or not installed | | Right: stop and insert. Middle: NIRUDICTATE settings |
| `recording` | NIRUCLIP: `● rec MM:SS`, `○ paused MM:SS`, `· cam off` / `· cam !` on a camera problem | Status; footer opens the capture view | Right: stop and save (or recover an interrupted one). Middle: `nirulauncher --clip` |
| `share` | NIRUSHARE entry | Opens the inbox (`nirulauncher --share`) | |
| `updates` | Available package upgrades (`apt`, `pacman` or `xbps`) | Details and the command to run | |
| `niruxupdate` | A newer NIRUX release, or an installed one that needs a new login; silent otherwise | The command to run (it never installs anything) | |
| `pulse` | CPU and memory | Graph of the last minute | |
| `uptime` | Uptime | Memory use and the fullest file system | |
| `sun` | Sunrise and sunset for the top-level coordinates | Details | |
| `weather` | Cached temperature, condition and rain | Eight-hour timeline | |
| `quicksettings` | A gear | Panel; `Enter` or a click on it opens Quick Settings | |
| `clock` | Date and time | Calendar (see below) | |

The `updates` module runs `xbps-install -un` on Void, `pacman -Qu` on Arch and `apt list --upgradable` on Debian, at most every `update_check_minutes`, and caches the answer in `~/.cache/nirubar/updates`. The `niruxupdate` module follows the core suite only; extras are updated separately.

The `wifi` module is added automatically after `network` when a Wi-Fi adapter exists, even if you leave it out of the list. Set `wifi = false` to keep wireless state inside `network` instead.

### The module list in the NIRUX example config

```toml
[bar]
modules = ["workspaces", "layout", "media", "volume", "brightness", "display", "tailscale", "network", "wifi", "mode", "battery", "agent", "dnd", "scratchpad", "dictation", "quicksettings", "updates", "clock"]
```

To add a module, put its name in the list where you want it. To remove one, delete its name. Then press `Super+R` (or run `niructl reload`).

## Change the workspace labels

Pick a preset with `workspace_layout`, or write your own `tags`. Only the labels change: there are always ten workspaces and `Super+1` to `Super+0` still select them.

| `workspace_layout` | Labels |
|---|---|
| `1` | `1` to `10` (default) |
| `2` | Nerd Font icons (web, code, chat, terminal, mail, folder...) |
| `3` | `web ai ai ai term chat mail folder pchat term` |

A known preset wins over `tags`. Without `workspace_layout` (or with an unknown number) the bar uses `tags`:

```toml
[bar]
tags = ["web", "code", "chat", "term", "media", "", "", "", "", ""]   # empty keeps the number
```

A workspace with a window that asked for attention is filled with the theme's attention colour. A user theme can set `urgent = "rrggbb"`; `[colors] urgent` or `warning` in `~/.config/niruwm/appearance.toml` sets it for the built-in themes.

## Use the calendar

Click the `clock` module. The panel shows a month with Monday first and ISO week numbers.

| Keys | Action |
|---|---|
| `Left` or `PageUp` | Previous month |
| `Right` or `PageDown` | Next month |
| `Escape` | Close |

Set the clock text with `date_format` and `time_format` (strftime, defaults `%Y-%m-%d` and `%H:%M`). `show_date = false` or `show_time = false` shows only one of them.

### Calendar events (Google Calendar and other iCal feeds)

The calendar panel can show events from one or more calendars, read only. Days with events get a dot in each calendar's colour, and the panel lists today and the next days (`days_ahead`, default 7). A click on a day or an event opens the calendar in the browser on that date.

To add a Google calendar:

1. Open calendar.google.com, then the gear, **Settings**.
2. Under **Settings for my calendars**, pick the calendar, then **Integrate calendar**.
3. Copy **Secret address in iCal format**. Anyone with this address can read the calendar, so keep it private.
4. Create the file so only you can read it, and add one block per calendar:

```sh
install -m 600 /dev/null ~/.config/nirubar/calendars.toml
```

```toml
[[calendar]]
name = "Private"
url = "https://calendar.google.com/calendar/ical/.../basic.ics"
color = "#7aa2f7"   # optional
# open = "https://calendar.google.com/calendar/r/day/{yyyy}/{m}/{d}"  # default for Google feeds
```

5. Run `nirubar --check-config`. NIRUBAR refuses the file unless its mode is 600.

After adding, removing or editing a calendar you don't need to do anything else: the bar notices the change within a few seconds and fetches the new calendar at once. `niructl reload` (or `Super+R`) applies it immediately. Logging out is not needed.

Feeds are refreshed every 15 minutes and cached in `~/.cache/nirubar/calendar/` (mode 600), so the events stay visible offline. The address never appears in process lists, logs or error messages, and `nirux sync` and snapshots never copy `calendars.toml`. Other iCal feeds (Nextcloud, iCloud, Outlook) work too; give them an `open` address to make clicks work.

Options go in a `[calendar]` table in `~/.config/nirubar/config.toml`:

| Key | Default | Meaning |
|---|---|---|
| `refresh_minutes` | `15` | How often feeds are fetched (5 to 1440) |
| `days_ahead` | `7` | Days listed below the month (0 to 31) |
| `show_in_bar` | `false` | Show the next event within 12 hours before the clock |

### Panel timeouts

Quick-glance panels close after `popup_timeout_seconds` in `[bar]` of `~/.config/niruwm/config.toml` (default 4; 0 keeps them open). The calendar, weather, tasks, pulse and notifications panels stay open until you close them. To give any panel its own timeout, add a table to NIRUBAR's own file `~/.config/nirubar/config.toml`, not the shared NIRUWM file:

```toml
[popup_timeout]
calendar = 0   # until dismissed
volume = 2     # seconds
```

Use the module names from `[bar] modules`, plus `calendar` for the clock's panel, `tray` for tray menus and `overflow` for the `+N` list. An entry here beats both the reading-panel default and `popup_timeout_seconds`. Run `niructl reload` after editing; `nirubar --check-config` lists the timeouts and any ignored entries.

## Use the system tray

With `tray = true` (default) the bar is the session's system tray, on the primary monitor. It shows both XEmbed and D-Bus StatusNotifierItem icons.

- Left click activates an item.
- Right click opens its menu in a bar panel, where you select an entry. Items without a menu get their secondary action.

Set `tray = false` if another tray program runs.

## Show the weather

Weather is opt-in and comes from Open-Meteo, fetched in the background and cached in `~/.cache/nirubar/weather-v1.json`. The last good result stays visible when a refresh fails.

1. Add `"weather"` to `[bar] modules`.
2. Create `~/.config/nirubar/config.toml`:

```toml
[weather]
location = "Stockholm"
latitude = 59.33
longitude = 18.07
refresh_minutes = 30   # default 30; at most one day
```

3. Press `Super+R`.

The `sun` module does not use this file. It reads the top-level `weather_latitude` and `weather_longitude` in `~/.config/niruwm/config.toml` (north and east are positive). They stay at the top level, not under `[bar]`. Without a `[weather]` table, the weather module also falls back to these coordinates.

## Quick Settings

Quick Settings is one launcher view with the everyday switches. Open it with:

- the `quicksettings` gear in the bar (click it, then `Enter` or click the panel);
- a right click on the `dnd` bell;
- `nirulauncher --quick` from a terminal or a key binding.

It contains, in order:

| Row | Does |
|---|---|
| Volume up / Volume down / Toggle output mute | Output volume |
| Toggle microphone mute | Input mute |
| Wi-Fi and network | Opens the Wi-Fi selector |
| Wired network | Connects or disconnects Ethernet without touching Wi-Fi (shown when an Ethernet interface exists) |
| Bluetooth | Opens Bluetooth devices |
| Displays | Display profiles and rotation |
| Power profile | Power saver, Balanced or Performance |
| Themes | Choose a NIRUX theme |
| Bar: top / Bar: bottom / Bar: hidden / Bar: show | Bar position and visibility |
| Bar: window title | Shows or hides the focused window's title in the bar |
| Audio devices | Choose output and input devices |
| Toggle Do Not Disturb | Suppresses notification popups |
| Toggle night light | Warm display |
| Toggle idle inhibition | Keeps the screen awake |
| Studio mode: on/off, Window swallowing: on/off | NIRUWM session switches |
| Lock screen | Locks now (a manual lock) |
| Update and restart / Update and shut down | Full system, NIRUX and extras update in a terminal, then the power action |

Type to filter the rows, `Enter` runs the selected one, `Escape` closes. The views it opens are described in [05-launcher.md](05-launcher.md).

## Move, hide or restart the bar

| Keys / command | Effect |
|---|---|
| `Super+Alt+B` | Cycle: top, bottom, hidden |
| `niructl bar top` | Bar at the top |
| `niructl bar bottom` | Bar at the bottom (panels then open above it) |
| `niructl bar hide` | Hide the bar |
| `niructl bar show` | Show it again at its configured edge |
| `niructl bar toggle` | Hide or show |
| `niructl bar cycle` | Same as `Super+Alt+B` |
| `niructl bar status` | Prints `top`, `bottom`, `hidden` or `disabled` |
| `niructl restart-bar` | Restart every bar (for example after `nirux update`) |

`top` and `bottom` are written back to `[bar] position` in the config, so they survive a new login. `hide` is for the running session only. `[bar] enabled = false` is the permanent off switch.

`niructl restart-bar` replaces running bars with the installed binary. `niructl restart-wm` replaces the window manager too, with every window kept (see [Updates](11-updates.md)); a running NIRUWM older than 0.23.0 says so instead, and needs one more login.

## Show the window title

Set `title = true` (or `show_title = true`) to show the focused window's title between the workspaces and the status modules, cut to `title_max` characters (default 20). `title_delay_seconds` (default 0) waits that many seconds before the title appears, so flicking through windows shows nothing. You can also toggle it with **Bar: window title** in Quick Settings or:

```sh
nirubar --toggle-title
```

## Make the bar transparent or opaque

The bar paints opaque pixels and asks the compositor (picom in NIRUX) for transparency through `_NET_WM_WINDOW_OPACITY`. Without a compositor it stays opaque.

```toml
[bar]
transparent = true   # default; false gives a fully opaque bar
opacity = 94         # percent, 1-100; out-of-range values fall back to 94
```

## Bar settings

All keys live in `[bar]` in `~/.config/niruwm/config.toml`. The file is strict: a key that NIRUWM or NIRUBAR does not know is rejected, so a typo shows up instead of being ignored.

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Start the bar at all |
| `position` | `"top"` | `"top"` or `"bottom"` |
| `modules` | see above | Modules in order |
| `workspace_layout` | unset | Label preset `1`, `2` or `3` |
| `tags` | `"1"` to `"10"` | Your own workspace labels |
| `cell_width` | `30` | Width of one workspace cell, pixels |
| `title` / `show_title` | `false` | Show the focused window title |
| `title_max` | `20` | Characters kept from the title |
| `title_delay_seconds` | `0` | Delay before the title appears |
| `show_date`, `show_time` | `true` | Parts of the clock |
| `date_format`, `time_format` | `"%Y-%m-%d"`, `"%H:%M"` | Clock format |
| `separator` | `"\|"` | Drawn between status groups |
| `icons` | `true` | Nerd Font glyphs; `false` for plain ASCII labels |
| `popups` | `true` | Left click opens panels |
| `popup_timeout_seconds` | `4` | Quick-glance panels close after this; `0` keeps them until dismissed. Per panel: [Panel timeouts](#panel-timeouts) |
| `media_width` | `32` | Characters of the media title |
| `graph_width` | `24` | Width of the `pulse` graph, characters |
| `update_check_minutes` | `30` | Minutes between package update checks |
| `microphone_visibility` | `"always"` | `"muted"` hides a healthy, unmuted input |
| `battery`, `network`, `wifi` | `true` | Switch those modules off without editing `modules` |
| `tray` | `true` | Own the system tray |
| `transparent` | `true` | See-through through the compositor |
| `opacity` | `94` | Percent used when `transparent` is true |

The bar height is the top-level `bar_height` (default 28). On HiDPI screens the bar reads `Xft.dpi` and scales `font_size`, `bar_height` and `cell_width`; set `NIRU_UI_SCALE` (0.75 to 2.5, `1` disables) to override.

Check and repair:

```sh
nirubar --check-config   # validate the [bar] settings
nirubar --reset-config   # replace only [bar] with the defaults; backup in config.toml.nirubar-backup
```

## Troubleshooting the bar

- **Icons show as boxes.** The font has no Nerd Font glyphs. Install one or set `icons = false`.
- **The bar is not transparent.** picom is not running, or `transparent = false`.
- **A module is missing.** Its provider is absent, or the name is misspelled (see stderr in the session log). Run `nirubar --check-config`.
- **The bar runs an old version after an update.** Run `niructl restart-bar`.

## See also

- [05-launcher.md](05-launcher.md)
- [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md)
- [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)
- [09-displays.md](09-displays.md)
- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [14-configuration-reference.md](14-configuration-reference.md)
