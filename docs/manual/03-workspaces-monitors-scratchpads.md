# Workspaces, monitors and scratchpads

This chapter covers the ten workspaces each screen has, moving windows between workspaces and screens, per-workspace layouts, and the scratchpads: the default one and the nine numbered slots.

## Workspaces in short

- Every connected screen has its own ten workspaces. Plug a screen in or out and NIRUWM follows.
- The workspace keys act on the focused screen. The focused screen is the one with the focused window, or the one the mouse pointer is on.
- A workspace keeps its own layout, master ratio and master count (see [02-windows-and-layouts.md](02-windows-and-layouts.md)).
- NIRUBAR shows the workspaces of its screen. A workspace with a window that asked for attention is drawn in the theme's attention colour.
- A window belongs to one workspace at a time. To see a window on every workspace of its screen, make it sticky with `Super+Alt+S`.

## Switch workspaces

| Keys | Action |
|---|---|
| `Super+1` to `Super+9` | Go to workspace 1 to 9 |
| `Super+0` | Go to workspace 10 |
| `Super+Tab` | Next workspace |
| `Super+Shift+Tab` | Previous workspace |
| `Super+Ctrl+1` to `Super+Ctrl+9`, `Super+Ctrl+0` | Also go to workspace 1 to 10 (see the note below) |

The cheat sheet calls `Super+Ctrl+N` "Show workspace N too (toggle)", but in NIRUWM 0.22.1 it simply goes to workspace N, like `Super+N`. Workspaces are not combined.

On Swedish, German and similar layouts `/` is `Shift+7`, so `Super+/` cannot be pressed apart from the workspace 7 key: `Super+7` stays workspace 7, and the cheat sheet is on `Super+F1`.

From a terminal or a script (N is 1 to 10):

```sh
niructl tag 3          # go to workspace 3 on the focused screen
niructl status         # the running window manager and the current workspace
```

## Move windows between workspaces

| Keys | Action |
|---|---|
| `Super+Shift+1` to `Super+Shift+9` | Move the window to workspace 1 to 9 |
| `Super+Shift+0` | Move the window to workspace 10 |
| `Super+Ctrl+Shift+1` to `Super+Ctrl+Shift+9`, `Super+Ctrl+Shift+0` | Move the window to workspace 1 to 10 and go there with it |

```sh
niructl movetotag 5    # move the focused window to workspace 5
```

`Super+Shift+N` sends the window away and you stay where you are; `Super+Ctrl+Shift+N` takes you along. The cheat sheet describes `Super+Ctrl+Shift+N` as "Put the window on workspace N too (toggle)", but a window is only ever on one workspace. Moving a scratchpad to a workspace makes it a normal window there.

## Give workspaces their own layout

Change a workspace's layout with its key (`Super+T`, `Super+M`, `Super+Ctrl+S` and so on, see [02-windows-and-layouts.md](02-windows-and-layouts.md)). The choice is written to `[monitors] layouts` in `~/.config/niruwm/config.toml` at once, and the workspace starts with it at the next login.

To decide in advance, set the list yourself, in workspace order:

```toml
[monitors]
workspaces = 10
layouts = ["tile", "monocle", "centered", "tile"]
```

The layout names are `tile`, `left`, `monocle`, `centered`, `centeredfloat`, `fibonacci`, `floating` and `scroll`. The list may be shorter than the number of workspaces; the rest are tiled. With an empty list (the default) every workspace starts tiled.

```sh
niructl layout show    # the stored lists, common and per screen
niructl layout save    # write what every workspace uses now
```

## Use more than one screen

| Keys | Action |
|---|---|
| `Super+,` / `Super+Alt+,` | Focus the previous screen |
| `Super+Alt+.` | Focus the next screen |
| `Super+Shift+,` | Move the window to the previous screen |
| `Super+Shift+.` | Move the window to the next screen |

With two screens `Super+,` reaches the other one either way, because the step wraps around. Moving the mouse pointer across the edge of a screen also focuses that screen. A window moved to another screen lands on the workspace that screen is showing, and the focus goes with it. You can also hold `Super` and drag a window across (see [02-windows-and-layouts.md](02-windows-and-layouts.md#use-the-mouse)).

`Super+.` is not a screen key: it opens the emoji picker. For `[[keys]]` the actions are `focusmon -1`, `focusmon 1`, `tagmon -1` and `tagmon 1`.

```sh
niructl monitors       # connected screens with their RandR names
```

A new window opens on the screen under the mouse pointer.

### When a screen goes away and comes back

When a screen is unplugged, its windows wait on the same workspace number of a remaining screen. When it comes back on the same connector in the same session, it shows the workspace it showed before, each workspace keeps its layout and ratios, and its windows return to it unless you moved them meanwhile. A screen that returns on another connector starts fresh. If a window ends up outside every screen, `niructl windows rescue` brings it back.

### Settings for one screen

`[[monitors.profiles]]` overrides one screen, named by its RandR output name (`niructl monitors` or `xrandr --listmonitors`):

```toml
[[monitors.profiles]]
name = "HDMI-1"
workspaces = ["web", "code", "chat"]   # labels this screen shows instead of 1..10
primary = true                         # focused at login
layouts = ["tile", "centered"]         # wins over [monitors] layouts here
```

| Key | Default | Meaning |
|---|---|---|
| `[monitors] workspaces` | `10` | Workspaces per screen without a profile |
| `[monitors] layouts` | `[]` | Starting layout per workspace |
| `[monitors] master_ratios`, `nmasters` | `[]` | Written by NIRUWM after `Super+H/L` and `Super+I/D` |
| `[[monitors.profiles]] name` | | RandR output name |
| `[[monitors.profiles]] workspaces` | | Workspace labels for this screen |
| `[[monitors.profiles]] primary` | | Gets the focus at login, and new windows when the pointer is outside every screen |
| `[[monitors.profiles]] layouts` | `[]` | This screen's starting layouts |

The labels in the bar for every screen are set in `[bar] tags`; see [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md). Where screens are placed is a display profile, not a workspace setting: see [09-displays.md](09-displays.md).

## Scratchpads

A scratchpad is a floating window you show and hide with one key, above whatever workspace you are on. There is one default scratchpad and nine numbered slots.

| Keys | Action |
|---|---|
| `Super+Shift+S` | Show or hide the default scratchpad |
| `Super+Alt+1` to `Super+Alt+9` | Show or hide scratchpad 1 to 9 |
| `Super+Alt+Shift+1` to `Super+Alt+Shift+9` | Send the focused window to scratchpad 1 to 9, or take it back |
| `Super+Shift+Space` | On a scratchpad: make it a normal tiled window again |

How they behave:

- **One at a time.** Showing a scratchpad hides the one that was shown. The key of the shown one hides it, and the focus goes back to the window you were using.
- **Not part of any workspace.** Showing or hiding one never moves or resizes other windows. A hidden one is left out of tiling, focus cycling, window lists, workspace cells and the saved session.
- **It follows you.** A shown scratchpad stays on top when you switch workspace, and moves along when you change screen with `Super+,`, `Super+Alt+.` or a workspace key there. Moving the mouse alone does not drag it along.
- **It stays until you hide it.** Moving the mouse onto another window gives that window the keyboard focus, but the scratchpad stays visible on top.
- **Its dialogs belong to it.** An Open or Save dialog from the scratchpad's program stays above it, is hidden and shown with it and follows it to another workspace or screen.
- **Closing frees the slot.** The next press starts the slot's command again, if it has one. An empty slot without a command shows a short hint.

### The default scratchpad

`Super+Shift+S` starts the command the first time and then shows and hides its window. The window is recognised by its window class, so the command must set one (`--class`, `-class`, `--name` or `--app-id`, depending on the program).

```toml
[scratchpad]
command = ["kitty", "--class", "scratchpad"]
width = 0.6               # share of the screen, 0.1 to 0.95
height = 0.6
hide_on_focus_loss = false
```

| Key | Default | Meaning |
|---|---|---|
| `command` | `["kitty", "--class", "scratchpad"]` | Program for the default scratchpad, an argument list |
| `width` | `0.6` | Width as a share of the screen, 0.1 to 0.95 |
| `height` | `0.6` | Height as a share of the screen, 0.1 to 0.95 |
| `hide_on_focus_loss` | `false` | `true` hides the scratchpad as soon as another window gets the focus |

### Numbered slots

Slots need no settings: any window can be sent to any slot with `Super+Alt+Shift+N`. If slot N already holds a window, that window comes back to the current workspace as a normal window (the two swap places). Pressing `Super+Alt+Shift+N` on the window that is in slot N, `Super+Shift+Space`, or `Super+Shift+1` to `Super+Shift+0` makes it a normal window again.

To give a slot a program that starts the first time you press `Super+Alt+N`, or its own size, add a `[[scratchpad.slot]]`:

```toml
[[scratchpad.slot]]       # Super+Alt+1
number = 1
command = ["kitty", "--class", "scratch-btop", "-e", "btop"]
width = 0.8
height = 0.8

[[scratchpad.slot]]       # Super+Alt+2: a calculator
number = 2
command = ["kitty", "--class", "scratch-calc", "-e", "python3", "-q"]
width = 0.4
height = 0.5
```

| Key | Default | Meaning |
|---|---|---|
| `number` | | The slot, 1 to 9 (the digit in `Super+Alt+N`) |
| `command` | `[]` | Program to start on first use; empty means the slot only holds windows you send to it |
| `width`, `height` | `[scratchpad]` values | Size as a share of the screen |

Each command needs its own class, because that is how the slot recognises its window. A second window of the same class is an ordinary window. Some extras use a slot by themselves; for example NIRUDICTATE's agent mode keeps opencode in slot 9 (see [12-extras.md](12-extras.md)).

### Scratchpads from the terminal

```sh
niructl scratchpad              # show or hide the default scratchpad
niructl scratchpad 2 toggle     # slot 2: toggle, show or hide
niructl scratchpad 2 show
niructl scratchpad default hide # 0 or "default" names the default one
niructl scratchpad send 3       # send the focused window to slot 3
niructl scratchpad send 3 --window 0x1a00007   # send one named window
niructl scratchpad unscratch    # make the focused scratchpad a normal window
niructl scratchpad list         # every slot: key, state, window
niructl scratchpad list --json
```

NIRUBAR's `scratchpad` module lists the scratchpads and shows or hides one with a click.

## See also

- [02-windows-and-layouts.md](02-windows-and-layouts.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [09-displays.md](09-displays.md)
- [14-configuration-reference.md](14-configuration-reference.md)
- [15-key-bindings.md](15-key-bindings.md)
- [16-commands.md](16-commands.md)
