# Displays

This chapter covers arranging screens with NIRU Display and `niructl display`: resolution, refresh rate, position, rotation and primary screen, saved profiles, the profile at login, automatic switching on hotplug and lid, and the doctor. It ends with brightness and night light.

## How it fits together

- `niructl display` owns the screen arrangement. **NIRU Display** (`nirudisplay`) is the graphical editor, and NIRU Launcher lists the same profiles under **Displays**. All of them use the same commands, so they never disagree.
- A **profile** is a saved arrangement: every lit screen with its mode, refresh rate, position, rotation and which one is primary. Profiles are in `~/.config/niruwm/displays.toml`.
- Profiles follow their screens by identity (make, model and serial from the EDID), not by connector name.
- The screen arrangement is separate from window layouts and workspaces (see [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md)).

Everything here is X11/RandR. Not offered: custom modelines, fractional per-screen scaling, ICC calibration, DDC/CI, HDR, VRR and rotation from a tilt sensor.

## Arrange screens with NIRU Display

Open **Displays** in NIRU Launcher, or run `nirudisplay`. You edit a draft; nothing changes on the screens until you press **Preview**.

1. Drag the screens into place. Edges snap, and the exact position is shown next to the screen.
2. Select a screen and set its resolution, refresh rate and rotation, enable or disable it, or make it primary. **Single**, **Extend** and **Mirror** arrange all screens at once.
3. Press **Preview**. The new layout is applied with a 15-second countdown. Press **Keep** to confirm it; **Revert**, or doing nothing, restores the previous layout.
4. Press `Ctrl+S` (**Save as...**) to save the arrangement as a profile.

Every screen has a **stable number**, shown in the canvas, the screen list and **Identify** (`I`), which shows each screen's number, connector and model on the screen itself for four seconds. Identical monitors are told apart by connector and a serial suffix. The primary screen has a `P` badge, disabled outputs have a dashed frame, and overlapping or invalid layouts are drawn in the warning colour and block Preview until fixed.

| Keys | Action |
|---|---|
| `Tab` | Move the focus between controls |
| Arrows | Move the selected screen 1 px (when no property control is focused) |
| `Shift`+arrows | Move the selected screen 10 px |
| `Space` / `Enter` | Press the focused control |
| `Enter` on mode, rate or rotation | Open its list (arrows move, `Enter` chooses, `Esc` closes) |
| Left / Right on mode, rate or rotation | Step through the values |
| `I` | Identify the screens |
| `R` | Reload the real state (the draft stays one `Ctrl+Z` away) |
| `Ctrl+Z` | Undo a draft change |
| `Ctrl+S` | Save as... |
| `0` | Fit the canvas |
| `F1` | Help |
| `Esc` / `Q` | Close |
| `Enter` / `Esc` during a preview | Keep / revert it |

With the mouse: the wheel over the canvas zooms, the middle button pans, a click on a profile loads it and a double-click loads and previews it.

The countdown runs in a separate `niructl` process, so a crash of the window never leaves a risky layout in place. Closing the window during a preview asks whether to keep or revert; it never reverts silently.

The profile list shows a summary per profile ("3 screens, eDP + 2x 2560x1440"), a **current** badge on the profile that matches the screens now, **at login** on the startup profile, **auto** on the profile the automatic switching applied and **manual** on one kept out of it. Profiles that need a screen that is not connected are dimmed and say what they need.

```sh
nirudisplay status       # connected screens and saved profiles
nirudisplay list         # saved profiles
```

NIRU Display 0.4.0 needs `niructl` from NIRUWM 0.17 or newer for automatic switching.

## Manage profiles from the terminal

```sh
niructl monitors                       # connected screens and their RandR names
niructl display save Desk              # save the layout as it is now
niructl display list                   # saved profiles
niructl display list --json
niructl display preview Desk           # try it for 15 s, then it reverts
niructl display preview Desk 30        # ... or for 30 s
niructl display keep TOKEN             # keep the preview (the token is printed)
niructl display revert TOKEN           # revert it now
niructl display status                 # is a preview running, and how long is left
niructl display apply Desk             # switch at once, no countdown
niructl display rename Desk Office
niructl display delete Office
niructl display auto                   # all screens side by side, preferred modes, upright
```

`preview` prints a line `preview-token: TOKEN`; `keep` and `revert` need that token, so a stale command can never confirm a newer preview. If `apply` fails, the previous layout is put back. `display auto` is a good starting point to save a profile from. `save-json` and `preview-json` read a profile as JSON on standard input; NIRU Display uses them.

`nirux layout` is a short form of the same commands:

```sh
nirux layout list
nirux layout save Desk
nirux layout apply Desk
nirux layout rotate HDMI-1 left
nirux layout auto
```

## Rotate a screen

To turn one screen without making a profile (a monitor mounted upside down or standing on its side):

```sh
niructl display rotate HDMI-1 left     # normal, left, right or inverted
```

Save a profile afterwards to keep it. In NIRU Display, use the rotation button of the selected screen.

## Choose a profile for login

A startup profile is applied once by `niruwm-session` at login, before the window manager reads the screens. It is off by default.

```sh
niructl display startup show
niructl display startup set Desk
niructl display startup off
niructl display startup apply          # what the session runs at login
```

In NIRU Display this is **Use at login**. If a screen of the profile is missing, the session logs why and keeps the connected screens usable. Renaming or deleting the startup profile in NIRU Display updates the reference.

## Switch automatically on hotplug and lid

Automatic switching is off by default. When it is on, the session applies the right layout whenever screens are plugged in or out, or the laptop lid closes or opens.

```sh
niructl display automatic on           # also acts on the screens connected now
niructl display automatic off
niructl display automatic status
niructl display automatic status --json
niructl display automatic run          # decide again now, as a hotplug would
```

In NIRU Display the switch is **Automatic** in the profile header. The layout is chosen in this order:

1. **A profile that fits exactly**: every screen it names is connected and no other one. At login the startup profile wins if it fits; after that, the profile last used with these screens; then a profile matched by identity beats one matched only by connector. If several still tie, nothing is guessed: a notification asks you to pick one, and your pick is remembered.
2. **The last layout these screens had**, whether it was a profile or arranged by hand.
3. **Extend**: the current layout with each new screen placed to the right. A screen seen before gets its remembered mode, rate and rotation; a new one its preferred mode, upright. NIRU Display then offers *Automatic layout, save as profile?*.

Every automatic change shows a short notification. Nothing is changed while a preview is pending. A profile you apply by hand stays until the next hotplug or lid change.

### The lid

Closing the lid while another screen is connected turns the built-in panel off; opening it brings the panel back through the same choice, so a *Desk* profile with the panel on returns. The session is never left dark: if the last external screen goes away with the lid closed, the panel is turned back on. Whether the laptop suspends is still decided by logind (by default it stays awake when docked and suspends otherwise).

### When a screen refuses its mode

After every automatic change the screens are read back and compared. If a screen refuses its saved mode or rate, the layout is relaxed: first the driver chooses the rate, then the screen's preferred mode is used. The full saved settings are tried again after 10 s, 20 s, 40 s and so on, up to every 5 minutes. The saved profile is never changed.

### Profiles in more detail

- **Identity.** Saving records each screen's make, product code, model and serial. If `DP-1` and `DP-2` swap, or a monitor moves to another dock port, it keeps its settings. Identical monitors without distinct serials, and screens without an EDID, are matched by connector.
- **Older profiles** saved before NIRUWM 0.17 match by connector. Save them again (`niructl display save NAME`, or **Save as...** under the same name) to add identities; name, place in the list and **Use at login** are kept.
- **Screens left off.** Connected screens a profile does not light are saved as deliberately off, so a *Docked* profile saved with the laptop panel off still fits, and turns the panel off, when the lid is open.
- **Manual only.** `auto = false` keeps a profile out of automatic switching; it can still be applied by hand.

The file format, for writing a profile by hand:

```toml
# ~/.config/niruwm/displays.toml
# automatic = true             # niructl display automatic on|off
# startup_profile = "Desk"     # niructl display startup set NAME

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
rate = 59.95                   # optional; without it xrandr chooses
position = "1920x0"
rotation = "normal"
primary = false
[profile.outputs.identity]
manufacturer = "DEL"
product_code = 41234
model = "DELL U2723QE"
serial = "ABC1234"

[[profile]]
name = "Presentation"
auto = false                   # never chosen automatically
[[profile.outputs]]
name = "HDMI-1"
mode = "preferred"
position = "0x0"
rotation = "normal"
primary = true
```

A profile leaves a screen off on purpose with `[[profile.off]]` and `name = "eDP-1"`. The full example is [displays.example.toml](https://github.com/nirucon/nirux/blob/main/displays.example.toml), and the matching rules are in NIRUWM's [display-profiles.md](https://github.com/nirucon/niruwm/blob/main/docs/display-profiles.md).

## The display watcher

`niruwm-session` starts `niructl display watch`, which waits for RandR and kernel events (and reads the lid while it can matter) instead of polling. It does the automatic switching when that is on; otherwise, when the screens change, it applies the startup profile if that fits, or else moves windows that ended up off-screen back to a connected display. You rarely run it yourself:

```sh
niructl display watch --once           # print each output as enabled or disabled, then exit
niructl display watch --quiet          # run without printing; only one watcher runs per display
```

## Ask the doctor

When a profile does not apply as you expect:

```sh
niructl display doctor
niructl display doctor --json
niructl display status --json          # the same information for NIRU Display
```

The doctor shows whether automatic switching is on and the lid state, every connected screen with its identity, which profile is current, and for each profile whether it fits now and why not (for example `needs HP E27q G5 (serial ...2MRJ)`, `also connected: HDMI-1`, or the built-in screen while the lid is closed). It also reports profiles without identities, screens that cannot be told apart, a startup profile that is missing or does not fit, leftover "ghost" desktop areas, and the last automatic action and any pending retry.

If windows are stranded outside every screen, run `niructl windows rescue` (see [02-windows-and-layouts.md](02-windows-and-layouts.md#rescue-lost-windows)).

## Files

| Path | Purpose |
|---|---|
| `~/.config/niruwm/displays.toml` | Profiles, `automatic`, `startup_profile` |
| `~/.local/state/niruwm/display-memory.toml` | Last layout per set of screens, last mode per screen |
| `~/.local/state/niruwm/display-auto.toml` | Last automatic action, pending retry |
| `~/.local/state/niruwm/display-preview.toml` | A pending preview |

The state files only hold memory and can be deleted at any time.

## Brightness

| Keys | Action |
|---|---|
| `XF86MonBrightnessUp` | Screen brightness up (5 %) |
| `XF86MonBrightnessDown` | Screen brightness down (5 %) |

```sh
niructl brightness status        # current level in percent
niructl brightness up
niructl brightness down
niructl brightness set 40        # 0 to 100
```

Brightness uses `brightnessctl`.

```toml
[brightness]
device = ""      # empty: brightnessctl's default device
step = 5         # percent per up/down
```

## Night light

By default the night light follows the sun: warm, reddish light (2700 K) from sunset to sunrise at the location in `[nightlight]`. Without a location it uses Stockholm's. `Super+N` switches it by hand, and that choice holds until the next sunset or sunrise; then the schedule takes over again. `mode = "manual"` turns the schedule off.

| Keys | Action |
|---|---|
| `Super+N` | Night light on or off (until the next sunset or sunrise) |

```sh
niructl nightlight status
niructl nightlight on
niructl nightlight off
niructl nightlight toggle
niructl nightlight temperature 3000    # 1000 to 10000 K, now
niructl nightlight apply               # apply what the schedule wants now
niructl nightlight watch               # follow the schedule (fixed or solar mode)
```

Night light uses `gammastep` and needs a location: `[nightlight] latitude` and `longitude`, or the top-level `weather_latitude` and `weather_longitude`.

```toml
[nightlight]
latitude = 59.33
longitude = 18.07
temperature = 2700       # Kelvin at night, and for "on"
mode = "solar"           # solar (default), fixed or manual
on = "20:00"             # fixed mode: switch on
off = "07:00"            # fixed mode: switch off
day_temperature = 6500   # solar mode: daytime Kelvin
```

| Mode | Behaviour |
|---|---|
| `solar` | gammastep follows sunrise and sunset at your location (default) |
| `fixed` | On and off at the `on` and `off` times every day |
| `manual` | Only `Super+N` and `niructl nightlight on/off` |

NIRUX 0.12.264 moved existing installations that still had the old defaults (`manual`, 3400 K) to the schedule once. Set `mode = "manual"` to go back; that is not changed again.

## See also

- [02-windows-and-layouts.md](02-windows-and-layouts.md)
- [03-workspaces-monitors-scratchpads.md](03-workspaces-monitors-scratchpads.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [05-launcher.md](05-launcher.md)
- [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)
- [14-configuration-reference.md](14-configuration-reference.md)
- [16-commands.md](16-commands.md)
