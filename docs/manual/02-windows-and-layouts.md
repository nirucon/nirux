# Windows and layouts

This chapter covers how NIRUWM places windows: the eight layouts, the master area, gaps, focus and stacking, floating, fullscreen and sticky windows, window rules, swallowing, urgency, the mouse and saving a session. NIRUWM is beta: the core is in daily use, while newer pieces such as the Scroll layout still get regular fixes.

## How tiling works

NIRUWM is a dwm-style tiling window manager. Every workspace has one layout, and the layout decides where each tiled window goes. You never drag windows into place: you open them and the layout arranges them.

- Most layouts have a **master area** (normally one large window) and a **stack** (the rest).
- The order of windows matters: the first window in the order is the master, the rest follow in the stack.
- A new window joins the end of the order, so the master stays where it is. In the Scroll layout a new window opens in the column right after the focused one.
- A single tiled window fills the work area without gaps or a border. Monocle, and Scroll with one column, also draw no border.
- Moving the mouse onto a window gives it the keyboard focus.

The settings for all of this live in `~/.config/niruwm/config.toml`. After an edit, press `Super+R` or run `niructl reload`. See [14-configuration-reference.md](14-configuration-reference.md) for every key.

## Choose a layout

Each key sets the layout of the focused workspace only. Every other workspace, on every screen, keeps its own layout.

| Keys | Layout | What it does |
|---|---|---|
| `Super+T` | `tile` | Master left, stack right (the default) |
| `Super+Y` | `left` | Master right, stack left |
| `Super+M` | `monocle` | One window fills the screen, the rest behind it |
| `Super+C` | `centered` | Master in the middle, stack on either side |
| `Super+U` | `centeredfloat` | Master centred at 70% height, the rest floating |
| `Super+Ctrl+E` | `fibonacci` | Spiral split, each window half of the rest |
| `Super+F` | `floating` | Nothing is tiled, windows keep their own size |
| `Super+Ctrl+S` | `scroll` | One window per column, one or two columns visible |
| `Super+Ctrl+.` | | Next layout |
| `Super+Ctrl+,` | | Previous layout |

`Super+Ctrl+.` and `Super+Ctrl+,` cycle in the order of the table. The same from a terminal:

```sh
niructl layouts              # every layout with its key, in cycling order
niructl layout monocle       # set the focused workspace's layout
niructl layout show          # the layouts stored in config.toml
niructl layout save          # write the current layouts to config.toml now
```

The layout name on the command line is the one in the second column (`centeredfloat`, not "centered floating").

A layout choice is written to `[monitors] layouts` at once, so it survives a crash and a logout. To choose starting layouts in advance, see [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md#give-workspaces-their-own-layout).

### The Scroll layout

Scroll keeps one window per column on a horizontal strip and shows one or two adjacent columns. Focus slides the view only as far as needed: with columns A B C D and two visible, moving focus right goes `A B`, then `B C`, then `C D`. A single window fills the work area.

| Keys | Action |
|---|---|
| `Super+Ctrl+S` | Switch the workspace to Scroll |
| `Super+Ctrl+Shift+S` | One or two visible columns (toggle) |
| `Super+J` / `Super+K` | Focus the next or previous column (the view follows) |
| `Super+Shift+J` / `Super+Shift+K` | Move the window one column right or left |

```sh
niructl layout columns 1       # one column
niructl layout columns 2       # two columns (the default)
niructl layout columns toggle
```

`layout columns` works only while Scroll is active. The layout name is saved; the column mode is not, and returns to two columns after a restart. When the work area is narrower than 480 px, two-column mode falls back to one column. Columns outside the view stay managed: they are listed in the window switcher (`Super+W`, `Alt+Tab`), and activating one there brings its column into view.

## Resize the master area

| Keys | Action |
|---|---|
| `Super+H` | Narrower master area |
| `Super+L` | Wider master area |
| `Super+I` | One more window in the master area |
| `Super+D` | One window fewer in the master area |

The ratio changes in steps of 0.05. Ratio and count belong to the focused workspace only and are saved beside its layout as `master_ratios` and `nmasters` in `[monitors]`. The top-level `master_ratio` (default `0.55`, range 0.1 to 0.9) is only the starting value for workspaces that have none.

## Gaps and borders

| Key | Default | Meaning |
|---|---|---|
| `gap` | `8` | Space between windows, in pixels |
| `border_width` | `2` | Border around each window, in pixels; `0` draws none |
| `master_ratio` | `0.55` | Default master share for new workspaces |

`Super+G` turns gaps off. Pressing it again sets them to 8 px. The change lasts until the next reload, which brings back the `gap` from the file.

The focused window's border uses the theme's focus colour. `gap`, `border_width` and `bar_height` can also come from `appearance.toml` when `config.toml` does not set them (see [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)).

## Focus, move and close windows

| Keys | Action |
|---|---|
| `Super+J` / `Super+Right` / `Super+Down` | Focus the next window |
| `Super+K` / `Super+Left` / `Super+Up` | Focus the previous window |
| `Super+Shift+J` / `Super+Shift+Right` / `Super+Shift+Down` | Move the window down the stack |
| `Super+Shift+K` / `Super+Shift+Left` / `Super+Shift+Up` | Move the window up the stack |
| `Super+W` / `Alt+Tab` / `` Super+` `` | Window switcher |
| `Super+Q` | Close the window |

Moving a window swaps it with its neighbour in the order, so you can bring a stack window into the master position with a few presses of `Super+Shift+K`. Floating windows are not part of the order and are not moved.

In `[[keys]]` the actions are `focus_next`, `focus_prev`, `move_next` and `move_prev` (`swap_next` and `swap_prev` are the same actions under other names).

## Floating windows

A floating window keeps its own size and position above the tiled ones. Dialogs float by themselves, and so do the NIRU settings windows (NIRU Theme Selector, NIRU Wallpaper).

| Keys | Action |
|---|---|
| `Super+Shift+Space` | Floating on or off for the focused window |
| `Super+Ctrl+Left` / `Right` / `Up` / `Down` | Move the window 20 px (a tiled window becomes floating) |
| `Super+Ctrl+Shift+Left` / `Right` | Shrink or grow it horizontally by 20 px |
| `Super+Ctrl+Shift+Up` / `Down` | Shrink or grow it vertically by 20 px |
| `Super+F` | Floating layout: nothing on this workspace is tiled |

For other steps, bind `move_float DX DY` or `resize_float DX DY` yourself, for example `action = "resize_float 50 0"`.

## Fullscreen

`Super+Shift+E` turns fullscreen on or off for the focused window. A fullscreen window covers the whole screen, including the bar, and has no border. Programs that ask for fullscreen themselves (a video player, a browser's F11) get the same treatment, also when they ask before their window first appears.

## Sticky windows

`Super+Alt+S` makes the focused window sticky: it stays visible on every workspace of its screen. A sticky window always floats, so it is useful for a small video, a clock or a chat window. Press `Super+Alt+S` again to make it normal. Scratchpads cannot be made sticky; they follow you anyway (see [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md)).

## Window rules

A rule sets how a window starts, matched by its window class. Add one `[[rules]]` table per rule in `~/.config/niruwm/config.toml`:

```toml
[[rules]]
class = "localsend"
floating = true
center = true

[[rules]]
class = "Signal"
workspace = 8        # counts from 0: 8 is workspace 9

[[rules]]
class = "kitty"
opacity = 92         # percent, needs the compositor
```

| Key | Default | Meaning |
|---|---|---|
| `class` | (required) | Text that must appear in the window's `WM_CLASS` (instance or class name). Case-sensitive |
| `workspace` | current | Workspace to open on, counted from 0 (`0` is workspace 1) |
| `floating` | `false` | Open floating instead of tiled |
| `center` | `false` | Centre a floating window on its screen when it first appears |
| `sticky` | `false` | Open sticky (and floating) |
| `opacity` | none | Compositor opacity, 1 to 100 percent |

The first rule whose `class` matches wins, and rules apply only when a window first appears. To find a class, run `xprop WM_CLASS` and click the window. Opacity needs picom running (`niructl compositor status`).

## Window swallowing

A program started from a terminal (`mpv`, `zathura`, `feh` and so on) takes the terminal's place: same workspace, same position in the order, the terminal's size if the terminal floated. The terminal is hidden until the program's window closes, then it comes back in place with the focus. Swallowing is on by default.

```sh
niructl swallow status
niructl swallow off          # this session only
niructl swallow on
niructl swallow toggle
```

`niructl swallow` lasts until the next login. To change it for every login, set `[swallow]`:

```toml
[swallow]
enabled = true                       # default
# terminals = ["kitty", "XTerm"]     # replaces the built-in list
# exclude = ["firefox", "mpv"]       # replaces the built-in list
```

Terminal and exclude classes match either part of `WM_CLASS`, in any case. The built-in terminals are kitty, Alacritty, st, XTerm, UXTerm, foot, wezterm, URxvt, ghostty, konsole, gnome-terminal and xfce4-terminal. The built-in exclude list covers xev, the common browsers (firefox, chromium, brave-browser, helium) and the NIRU tools (nirulauncher, nirunotify, nirulock, nirushot, niruclip). Dialogs, scratchpads, other terminals and windows that a rule sends to a workspace never swallow. For `[[keys]]`, the action is `swallow_toggle`.

## Urgent windows

A window that asks for attention (a terminal bell, a chat message) is marked unless it already has the focus: its border and its workspace cell in NIRUBAR take the theme's attention colour.

| Keys | Action |
|---|---|
| `Super+Shift+U` | Go to the window that asked for attention most recently |

```sh
niructl urgent               # windows that asked for attention, newest last
niructl urgent --json
niructl urgent focus         # the same as Super+Shift+U
```

Going to the window switches screen and workspace, or shows its scratchpad, and clears the mark. A window inside a scratchpad is listed as `scratchpad`.

## Use the mouse

| Input | Action |
|---|---|
| Move the pointer onto a window | Focus it |
| `Super` + left-drag | Move the window; a tiled window becomes floating |
| `Super` + right-drag | Resize the window from the nearest corner |
| Click inside a window or the bar | Normal interaction, no `Super` needed |

A dragged window can cross to another screen. It lands on the screen it overlaps most. If it was tiled and that screen's workspace uses a tiling layout, it is tiled there again; otherwise it stays floating where you dropped it. `Super+Shift+Space` tiles a floating window again.

## Save and restore the session

NIRUWM can remember which programs were open, on which screen and workspace, and whether they floated, and start them again at the next login. The programs' own state (browser tabs, an editor's files) is up to the programs.

1. Turn restoring on at the top of `~/.config/niruwm/config.toml`:

   ```toml
   restore_session = true    # default: false
   ```

2. Press `Super+Shift+W` to save the open windows now. Logging out saves too.

```sh
niructl save-session         # save now (without a running WM: list what is saved)
niructl save                 # the same as Super+Shift+W
niructl clear-session        # forget the saved session
```

The saved session is `~/.local/state/niruwm/session.tsv`. When a session is restored, `[autostart]` does not run, so programs are not opened twice. If the window manager crashes, `niruwm-session` starts it again and every open window keeps its workspace and scratchpad; this is separate from saving.

## Rescue lost windows

After a screen is unplugged or a display layout changes, a floating window can end up outside every connected screen.

```sh
niructl windows rescue --dry-run   # list the windows that are off-screen
niructl windows rescue             # move them back
```

Rescued windows go to the screen under the mouse pointer, near its top-left corner. Windows in hidden Scroll columns are not lost and are left alone.

## Change or add a binding

Every key above can be replaced or removed with `[[keys]]` in `config.toml`:

```toml
[[keys]]
keys = "super+shift+f"
action = "start thunar"
description = "Open Thunar"   # shown in the cheat sheet

[[keys]]
keys = "super+g"
action = "unbind"
```

An entry with the same keys replaces the default, and `action = "unbind"` removes it. Modifiers are `super`, `shift`, `ctrl` and `alt`. Every action is listed in the comments of [config.example.toml](https://github.com/nirucon/niruwm/blob/main/config.example.toml), and every default key in [15-key-bindings.md](15-key-bindings.md). Press `Super+/` or `Super+F1` for the cheat sheet of every key in effect. On Swedish, German and similar layouts `/` is `Shift+7`, so `Super+/` is the workspace 7 key there: use `Super+F1`.

## See also

- [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [09-displays.md](09-displays.md)
- [14-configuration-reference.md](14-configuration-reference.md)
- [15-key-bindings.md](15-key-bindings.md)
- [16-commands.md](16-commands.md)
