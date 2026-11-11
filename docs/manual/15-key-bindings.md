# Key bindings

Every key binding of a fresh NIRUX installation, grouped as in the cheat sheet.
The cheat sheet itself (`Super+F1`, or `Super+/` where `/` is its own key) always
shows the keys in effect on your machine, including your own `[[keys]]` and the keys
that extras such as NIRUDICTATE register.

On Swedish and similar layouts `/` is `Shift+7`, so `Super+/` is not reachable as
one chord: use `Super+F1`.

## Change a key binding

Add a `[[keys]]` entry to `~/.config/niruwm/config.toml`, then reload with
`Super+Shift+R` or `niructl reload`:

```toml
[[keys]]
keys = "super+shift+n"
action = "spawn kitty -e nplay"
```

The actions a binding can use are listed in the comment above the `[[keys]]`
entries in `config.example.toml`; see
[Configuration reference](14-configuration-reference.md). In the cheat sheet,
`Ctrl+R` tells you what a pressed key does, and clashes are flagged.

## All key bindings

<!-- generated: keys (tools/manual-gen.sh; do not edit by hand) -->

The key bindings of a fresh NIRUX installation: NIRUWM 0.24.4 defaults with
the `[[keys]]` of the NIRUX `config.example.toml`. Your own `[[keys]]` and the keys
that extras register are added on top; `Super+F1` shows the keys in effect.

### Apps and launchers

| Keys | Action |
|---|---|
| `Super+A` | NIRU Actions: maintenance, diagnostics, contexts and OpenCode |
| `Super+S` | Web search: type a phrase, Enter opens it |
| `Super+V` | Clipboard history |
| `Super+Shift+F1` | The NIRUX manual (search and read) |
| `Super+O` | Find files in the home folder |
| `Super+Shift+B` / `Super+Shift+M` / `Super+Shift+P` / `Super+Shift+Q` / `Super+Ctrl+T` | Unified launcher: apps, windows, actions and settings |
| `Alt+Tab` / `` Super+` `` / `Super+W` | Window switcher |
| `Super+Enter` | Open a terminal |
| `Super+Shift+Enter` | Open the alternative terminal |
| `Super+B` | Open the web browser |
| `Super+P` | Application launcher |
| `Super+/` / `Super+F1` | Keybinding cheat sheet (this list) |
| `Super+.` | Emoji and symbol picker |
| `Super+Shift+F` | Open the file manager (pcmanfm) |

### Session

| Keys | Action |
|---|---|
| `Super+Shift+Escape` | Lock, then suspend the computer |
| `Super+Shift+R` / `Super+Ctrl+Shift+R` / `Super+R` | Reload the configuration |
| `Super+N` | Night light on or off |
| `Super+Shift+D` | Do Not Disturb on or off |
| `Super+Shift+C` | Keep the screen awake on or off |
| `Super+Shift+W` | Save the open windows as the session |
| `Super+Escape` | Lock the screen |
| `Super+Ctrl+Shift+Q` | Log out (end the session) |

### Layouts

| Keys | Action |
|---|---|
| `Super+Alt+B` | Bar: top, bottom, hidden |
| `Super+T` | Layout: Tile |
| `Super+Y` | Layout: Left stack |
| `Super+M` | Layout: Monocle (one window at a time) |
| `Super+C` | Layout: Centered master |
| `Super+U` | Layout: Centered floating master |
| `Super+F` | Layout: Floating |
| `Super+Ctrl+E` | Layout: Fibonacci spiral |
| `Super+Ctrl+S` | Layout: Scroll |
| `Super+Ctrl+Shift+S` | Scroll layout: one or two visible columns |
| `Super+Ctrl+,` | Previous layout |
| `Super+Ctrl+.` | Next layout |
| `Super+H` | Narrower master area |
| `Super+L` | Wider master area |
| `Super+I` | One more window in the master area |
| `Super+D` | One window fewer in the master area |
| `Super+G` | Gaps between windows on or off |

### Scratchpads

| Keys | Action |
|---|---|
| `Super+Shift+S` | Show or hide the default scratchpad |
| `Super+Alt+1…9` | Show or hide scratchpad 1…9 |
| `Super+Alt+Shift+1…9` | Send the window to scratchpad 1…9, or take it back |

### Focus and windows

| Keys | Action |
|---|---|
| `Super+Alt+S` | Sticky (on every workspace) on or off |
| `Super+Shift+J` / `Super+Shift+Down` / `Super+Shift+Right` | Move the window down the stack |
| `Super+Shift+K` / `Super+Shift+Up` / `Super+Shift+Left` | Move the window up the stack |
| `Super+Shift+U` | Go to the window that asked for attention (urgent) |
| `Super+Alt+.` | Focus the next screen |
| `Super+Alt+,` / `Super+,` | Focus the previous screen |
| `Super+Shift+.` | Move the window to the next screen |
| `Super+Shift+,` | Move the window to the previous screen |
| `Super+Q` | Close the window |
| `Super+J` / `Super+Right` / `Super+Down` | Focus the next window |
| `Super+K` / `Super+Left` / `Super+Up` | Focus the previous window |
| `Super+Shift+Space` | Floating on or off |
| `Super+Shift+E` | Fullscreen on or off |

### Workspaces

| Keys | Action |
|---|---|
| `Super+Ctrl+1…9` / `Super+Ctrl+0` | Go to workspace 1…9 / 10 |
| `Super+Ctrl+Shift+1…9` / `Super+Ctrl+Shift+0` | Move the window to workspace 1…9 / 10 and follow it |
| `Super+Shift+1…9` / `Super+Shift+0` | Move the window to workspace 1…9 / 10 |
| `Super+1…9` / `Super+0` | Go to workspace 1…9 / 10 |
| `Super+Tab` | Next workspace |
| `Super+Shift+Tab` | Previous workspace |

### Floating windows

| Keys | Action |
|---|---|
| `Super+Ctrl+Shift+Left` | Shrink a floating window horizontally |
| `Super+Ctrl+Shift+Right` | Grow a floating window horizontally |
| `Super+Ctrl+Shift+Up` | Shrink a floating window vertically |
| `Super+Ctrl+Shift+Down` | Grow a floating window vertically |
| `Super+Ctrl+Left` | Move a floating window left |
| `Super+Ctrl+Right` | Move a floating window right |
| `Super+Ctrl+Up` | Move a floating window up |
| `Super+Ctrl+Down` | Move a floating window down |

### Screenshots and color

| Keys | Action |
|---|---|
| `Super+Ctrl+O` | Copy the text in a screen region (OCR) |
| `Super+Ctrl+C` | Pick a color from the screen and copy it |
| `Super+Print` | Screenshot of the whole screen, then review |
| `Print` | Screenshot of a region, then review |
| `Super+Shift+Print` | Screenshot of the active window, then review |

### Hardware keys

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute or unmute |
| `XF86AudioPlay` | Play or pause |
| `XF86AudioPause` | Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86MonBrightnessUp` | Screen brightness up (5 %) |
| `XF86MonBrightnessDown` | Screen brightness down (5 %) |


<!-- end generated: keys -->

## See also

- [Getting started](01-getting-started.md)
- [Windows and layouts](02-windows-and-layouts.md)
- [Command reference](16-commands.md)
