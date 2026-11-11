# Themes and wallpapers

This chapter covers the NIRU themes, theme packs, NIRU Theme Selector, the `niructl theme` commands, `appearance.toml`, the terminal colours, and wallpapers: NIRU Wallpaper, `niructl wallpaper`, the optional wallpaper downloads and the login screen picture.

## How themes work

One theme is active at a time, and it is followed everywhere: NIRUWM's borders, NIRUBAR, NIRU Launcher, NIRUNOTIFY, NIRULOCK, NIRUSCREENSAVER, NIRUSHOT, the toolkit apps that choose *Follow NIRUX*, the kitty and fish colours and, unless you chose your own picture, the wallpaper and the login screen.

- The active theme is the `theme` key at the top of `~/.config/niruwm/config.toml`.
- Built-in themes are compiled into NIRUWM, so they always work.
- User themes, from a theme pack or imported by you, are files in `~/.config/niruwm/themes/NAME.toml`. A user file with the same name as a built-in theme replaces that theme.

## The built-in themes

| Theme id | Name |
|---|---|
| `niru-noir` | Niru Noir (the default) |
| `niru-nord` | Niru Nord |
| `niru-satie` | Niru Satie |
| `niru-carl-larsson` | Niru Carl Larsson |
| `niru-forest-vigil` | Niru Forest Vigil |
| `niru-blood-of-urdr` | Niru Blood of Urdr |
| `niru-root-and-stone` | Niru Root and Stone |
| `niru-blue-horizon` | Niru Blue Horizon |
| `niru-the-norns` | Niru The Norns |
| `niru-winter-nights` | Niru Winter Nights |

NIRUX ships the Noir wallpaper. The other nine themes' wallpapers are an optional download (see [Download the optional wallpapers](#download-the-optional-wallpapers)); without it a theme paints its background colour instead.

## Change the theme

With the mouse: open **NIRU Theme Selector** from NIRU Launcher (`Super+P`, or the unified launcher `Super+Shift+P`), or run `niruthemeselector`.

From a terminal:

```sh
niructl themes                 # every theme: id, name, origin; * marks the active one
niructl theme niru-nord        # switch theme
```

`niructl themes` also says when a theme is hidden, has no wallpaper installed, or is invalid (with the reason). A theme change reaches the running bar, launcher and other components without a reload, and runs the terminal hook (see [Terminal colours](#terminal-colours)).

`niructl theme NAME` also repairs a `config.toml` that lacks sections: missing sections are restored from the example, the previous file is kept as `config.toml.bak`, and a file that is not valid TOML is refused instead of overwritten. This part works without a running session, for example over ssh.

## NIRU Theme Selector

NIRU Theme Selector shows every theme as a small desktop preview with its wallpaper, bar, window frame and palette. Choosing a card only changes the preview; **Apply** switches the theme through `niructl`. For 15 seconds after an apply, **Undo** puts the previous theme back. NIRU Theme Selector is beta.

| Keys | Action |
|---|---|
| Typing | Filter the grid by name or id |
| `Esc` | Clear the filter; with no filter, close the window |
| `Tab` / `Shift+Tab` | Move between cards, actions and filter chips |
| Arrows, `PageUp` / `PageDown`, `Home` / `End` | Choose a theme (only the preview changes) |
| `Enter` or double-click | Apply the selected theme |
| `Space` | Press the focused control |
| `Ctrl+Z` | Undo the last apply (within 15 s) |
| `Alt+A` / `Alt+I` / `Alt+H` / `Alt+D` | Apply / import / hide or show / remove |
| `Alt+V` | Show the hidden themes |
| `Alt+R` | Reload the list |
| `Alt+S` | Theme pictures: Art or NIRUX Signature (also the label in the key row) |
| `Ctrl+Q` / `Alt+Q` | Close |
| `F1` | Help |

The filter chips are **All**, **Built-in**, **User** and **Hidden**. In the import form, `Ctrl+V` pastes, `Ctrl+B` opens **Browse...** (starting in `~/Downloads`), `Ctrl+R` toggles replacing a user theme with the same id, and `Enter` imports.

```sh
niruthemeselector status       # active theme and catalogue
niruthemeselector list         # available themes
```

## Install a theme pack

Theme packs are separate repositories named `nirux-theme-*`, for example the Carl Larsson and Erik Satie colour variants, Evert Taube, Piaf Noir and the two Hackerman themes. The list is in the [NIRUX README](https://github.com/nirucon/nirux#readme).

1. Clone the pack and run its installer:

   ```sh
   git clone https://github.com/nirucon/nirux-theme-evert-taube
   cd nirux-theme-evert-taube
   ./install.sh
   ```

2. Select it in NIRU Theme Selector (it is listed under **User**), or with `niructl theme ID`; `niructl themes` shows the id.

## Import, remove, hide and show themes

```sh
niructl theme-import ~/mytheme.toml                       # id from the file name
niructl theme-import ~/mytheme.toml --id my-theme --wallpaper ~/wall.png
niructl theme-import ~/mytheme.toml --id my-theme --replace
niructl theme-remove my-theme      # user themes only
niructl theme-hide niru-satie      # hide a built-in theme from the lists
niructl theme-show niru-satie
niructl theme-catalog              # every theme as JSON (for scripts and GUIs)
```

- The id may use letters, digits, `-` and `_`. It cannot be a built-in id unless you replace an existing user override.
- `--wallpaper` takes a PNG only. It is copied to the theme wallpaper folder as `nirux-wallpaper-ID-4k.png` (a leading `niru-` is dropped from the id).
- Built-in themes cannot be removed, only hidden. The active theme cannot be removed or hidden until you apply another one.
- The hidden list is kept in `~/.config/niruwm/theme-preferences.toml`.
- Imported theme files are data and are never executed.

### The theme file format

```toml
# ~/.config/niruwm/themes/my-theme.toml
name = "My Theme"
background = "2e3440"
foreground = "eceff4"
muted = "9aa5b1"
border = "3b4252"
focus = "88c0d0"
# urgent = "ebcb8b"   # optional: the attention colour for urgent windows
```

Colours are six hex digits without `#`. Every key except `urgent` is required. A theme without `urgent` gets the attention colour from `appearance.toml`, or one derived from its background.

## Fine-tune with appearance.toml

`~/.config/niruwm/appearance.toml` is an optional file of semantic values that every component reads: colour overrides, font, spacing, focus width and reduced motion. Start from [appearance.example.toml](https://github.com/nirucon/nirux/blob/main/appearance.example.toml).

```toml
schema = 1

# [colors]            # uncomment a key to override it in every component
# accent = "5a5a60"

[font]
size = 15.0
# path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

[spacing]
gap = 8
padding = 12
margin = 16
bar_height = 28

[focus]
width = 2             # window border and focus ring, in pixels

[motion]
reduced = false       # true stops scrolling titles and other movement
```

- The `[colors]` keys are `background`, `surface`, `foreground`, `muted`, `border`, `focus`, `accent`, `selected`, `success`, `warning`, `error` and `disabled`.
- Colour overrides apply to the built-in themes. A user theme file takes precedence over them.
- For NIRUWM, `gap`, `border_width` (from `[focus] width`), `bar_height`, `font_size` and `font_path` in `config.toml` win; the appearance values are used only when `config.toml` does not set them.
- An unreadable file or an unsupported `schema` is ignored, so a bad edit never breaks a working theme.

Every key with its default is in [14-configuration-reference.md](14-configuration-reference.md).

## Terminal colours

NIRUX colours kitty and fish from the active theme. On every theme change, at login and after an install or update, `nirux-theme-hook` (in `~/.local/bin`) writes:

| File | Used by |
|---|---|
| `~/.config/nirux/theme/kitty.conf` | Included by NIRUX's kitty configuration; open kitty windows reload it at once |
| `~/.config/nirux/theme/fish.fish` | Read by NIRUX's fish setup; open shells pick it up at the next prompt |

Both files are generated: do not edit them. Noir, Nord, Satie and Carl Larsson have their own terminal palettes. Other themes get a dark or light base palette (chosen from how bright the background is) with the theme's own background, foreground, muted, border and focus colours. The same hook also updates the login screen picture, unless you chose one (see [The login screen picture](#the-login-screen-picture)).

## Wallpapers

NIRUWM sets and rotates the wallpaper; NIRU Wallpaper and `niructl wallpaper` are the controls. All settings live in `[wallpaper]` in `~/.config/niruwm/config.toml`, and they are written for you by these tools.

You have three choices:

- **Follow the theme** (the default): the active theme's own picture, so a theme change also changes the wallpaper.
- **Another theme picture**: keep the theme but show a different picture from the installed set, for example a Carl Larsson colour variant.
- **Your own picture** from `~/Pictures/Wallpapers` (or the folder in `[wallpaper] dir`).

By default every screen shows the same picture, scaled for its own size. A screen can have its own picture.

### Art or Signature

A theme's picture comes in two styles:

- **Art** (the default): each theme's own artwork, from Carl Larsson to Forest Vigil.
- **Signature**: the same photograph for every theme, the NIRUX Noir picture (photo by Nicklas Rudolfsson, 2025) toned in that theme's own colours. The whole suite then looks like one family, and a theme change still changes the colours of the picture.

Switch with `Alt+S` in NIRU Theme Selector, `S` (or the **Theme picture** button) in NIRU Wallpaper, or from a terminal:

```sh
nirux wallpapers style signature   # downloads the Signature pack (about 47 MiB) the first time
nirux wallpapers style art
nirux wallpapers style toggle
niructl wallpaper style toggle     # the same switch, once the pack is installed
```

The choice is `theme_style` in `[wallpaper]`. A theme without a Signature picture (your own themes) keeps its artwork. The login screen follows the same style.

### NIRU Wallpaper

Open **Wallpaper** in NIRU Launcher, or run `niruwallpaper`. It shows previews of the theme pictures (under **Official themes**) and your own (under **My wallpapers**), a map of the screens when you have more than one, the scale preview and the rotation interval. Choose, then **Apply**. NIRU Wallpaper is beta.

| Keys | Action |
|---|---|
| `Tab` / `Shift+Tab` | Move between controls |
| Arrows | Choose a picture in the grid |
| `PageUp` / `PageDown`, `Home` / `End` | Move a page, or to the first or last picture |
| `Space` | Choose the picture, or press the focused control |
| `Enter` | Apply, or press the focused control |
| `Ctrl+D` | Discard the staged change |
| `A` | Back to the picture grid |
| `S` | Theme pictures: Art or NIRUX Signature (also the **Theme picture** button) |
| `F1` | Help |
| `Esc` or `q` | Close |

**Add pictures...** under **My wallpapers** lists the PNG, JPEG, WebP and BMP files in your Pictures and Downloads folders and copies the ones you mark into the wallpaper folder. Originals are never moved.

```sh
niruwallpaper status       # the settings and what each screen shows
niruwallpaper list         # available wallpapers
niruwallpaper set PATH     # apply one picture to every screen
```

### Wallpapers from the terminal

```sh
niructl wallpaper status                 # theme, picture, and why it is what it is
niructl wallpaper list
niructl wallpaper set ~/Pictures/Wallpapers/fjord.jpg   # your own picture, kept across theme changes
niructl wallpaper follow-theme on        # back to the theme's picture
niructl wallpaper follow-theme off
niructl wallpaper mode random            # random, fixed or single
niructl wallpaper rotation 30            # minutes between changes; 0 turns rotation off
niructl wallpaper scale fit              # fill, fit, stretch or center
niructl wallpaper style toggle           # Art or Signature theme pictures
niructl wallpaper apply                  # set the wallpaper again now
```

`wallpaper set` switches to `mode = "single"`, which keeps that picture across theme changes. `follow-theme on` turns following back on and changes `single` to `fixed`; the file stays in the config, so `wallpaper mode single` returns to it.

### One screen, its own picture

```sh
niructl wallpaper output list                   # screens with source, mode and scale
niructl wallpaper output set DP-1 image PATH    # this screen's own picture
niructl wallpaper output set DP-1 scale fit
niructl wallpaper output set DP-1 mode theme    # this screen follows the theme
niructl wallpaper output set DP-1 inherit       # back to the common settings
niructl wallpaper output reset DP-1             # remove the screen's entry
```

Screens are named by their RandR output name (`eDP-1`, `HDMI-1`), so a cable moved to another port is a different screen. An unplugged screen keeps its entry and gets its picture back when it returns to the same port.

### The [wallpaper] settings

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | NIRUWM owns the background; `false` when another program sets it |
| `dir` | `"~/Pictures/Wallpapers"` | Folder for your own pictures (jpg, jpeg, png, webp, bmp) |
| `mode` | `"random"` | `random`: a new picture each rotation; `fixed`: one picture kept; `single`: always `file` |
| `file` | `""` | The picture for `single` |
| `rotation_minutes` | `10` | Minutes between changes; `0` turns rotation off |
| `scale` | `"fill"` | `fill` (crop), `fit` (letterbox), `stretch` or `center` |
| `files` | `[]` | Rotate through these files instead of the whole folder |
| `shuffle_on_start` | `true` | A fresh picture at login, even in `fixed` mode |
| `follow_theme` | `true` | Use the theme's picture; a `single` file is never overridden |
| `theme_dir` | `"~/Pictures/Wallpapers/NIRU"` | Where the theme pictures are |
| `theme_style` | `"art"` | `art`: each theme's artwork; `signature`: the NIRUX Signature photo in the theme's colours |

While `follow_theme` is on and the mode is not `single`, a screen without its own picture shows the theme's picture. To rotate through your own pictures, turn follow-theme off and use `random` mode.

## Download the optional wallpapers

```sh
nirux wallpapers status              # how many theme and extra pictures are installed
nirux wallpapers download themes     # the nine optional theme wallpapers (4K and 8K) and Signature
nirux wallpapers download theme nord # one theme only
nirux wallpapers download signature  # NIRUX Signature, ten themes, 4K (about 47 MiB)
nirux wallpapers download extras     # Carl Larsson and Erik Satie colour variants
nirux wallpapers download carl-larsson
nirux wallpapers download satie
nirux wallpapers download all
nirux wallpapers remove              # remove them again (Noir and your own files stay)
```

The theme set is about 284 MiB and the two extra packs about 254 MiB together. Downloads are verified against pinned sizes and SHA-256 checksums, and pictures already installed are reused. Run from a session, the active theme's picture is refreshed when the download finishes; no logout is needed. The pictures go to `Wallpapers/NIRU` in your XDG Pictures folder. Opening NIRU Wallpaper never downloads anything.

## The login screen picture

The login screen follows the theme: the theme hook copies the theme's picture to the NIRUX SDDM or LightDM greeter on every theme change. To choose a picture yourself:

```sh
nirux login-wallpaper list           # PNG pictures in Wallpapers/NIRU; * marks your choice
nirux login-wallpaper set nirux-wallpaper-nord-4k.png   # a name there, or a path
nirux login-wallpaper reset          # back to following the theme
nirux login-wallpaper sync           # copy the theme's picture now
```

The picture must be a PNG, and it appears at the next start of the login screen. A picture chosen with `set` is never replaced by a theme change until you `reset`. `nirux login-wallpaper` works with the NIRUX SDDM and LightDM greeters; NIRU Login takes its colours and picture from `/etc/nirulogin/theme.toml`, which NIRUX writes from the active theme during `nirux update`.

## Troubleshooting

- **The wallpaper no longer follows the theme.** Run `niructl wallpaper status`, which says why, then `niructl wallpaper follow-theme on`.
- **A theme shows only a colour.** Its picture is not installed: `nirux wallpapers download theme NAME`.
- **NIRU Wallpaper says NIRUWM does not own the wallpaper.** `[wallpaper] enabled = false` in `config.toml`; set it to `true` and press `Super+R`.
- **The wallpaper folders are wrong** (for example after renaming your Pictures folder): `nirux repair-wallpaper` rewrites `dir` and `theme_dir` and keeps a backup of `config.toml`.
- **Rotation does nothing.** A `single` picture keeps one image, and a screen that follows the theme shows the theme's picture.

## See also

- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [06-lock-and-screensaver.md](06-lock-and-screensaver.md)
- [09-displays.md](09-displays.md)
- [14-configuration-reference.md](14-configuration-reference.md)
- [16-commands.md](16-commands.md)
