# Screenshots and recording

NIRUSHOT takes screenshots, lets you annotate them, picks colours from the screen and copies text from it (OCR). NIRUCLIP records the screen, a region or the camera, with microphone and desktop audio. This chapter covers the keys, the review window, the colour picker, OCR and recording.

## Take a screenshot

| Keys | Captures |
|---|---|
| `Print` | A region you drag out |
| `Super+Print` | The whole screen (all monitors) |
| `Super+Shift+Print` | The active window |

The capture is copied to the clipboard at once, then the review window opens. Even if you cancel the review, the original stays pasteable and no file is written.

From a terminal:

```sh
nirushot --region                          # select a region (the default)
nirushot --window                          # the active window
nirushot --full                            # all monitors
nirushot --region --delay 3                # wait three seconds first
nirushot --full --copy                     # clipboard only, no review
nirushot --region --save ~/Pictures/shot.png
nirushot --full --save shot.png --review   # save to that path from the review
nirushot --no-notify                       # no notification after saving
```

Without `--copy` or `--save` the capture opens in review. `--save PATH` writes that file, `--copy` skips review, `--review` opens review anyway.

The region selector draws a thick amber border. `Escape` in the selector cancels without a capture.

## Review and annotate

The review window is a centred floating window on the monitor that holds the capture. It takes the keyboard focus but grabs nothing, so the screen lock can always take over; the review stays open underneath with your edits.

| Keys | Action |
|---|---|
| `c`, then drag | Crop |
| `r`, then drag | Rectangle |
| `a`, then drag | Arrow |
| `m`, then drag | Opaque black mask |
| `h`, then drag | Highlight (everything outside is dimmed to 50 %) |
| `t`, then click | One line of text; `Enter` places it, `Escape` cancels |
| `1` to `6` or the swatches | Colour: theme focus colour, red, yellow, green, white, black |
| `w` or the picker | Thin, medium or thick stroke (S/M/L text size with the text tool) |
| `v` | View/pan mode: drag the image |
| Middle-drag, or hold `Space` and drag | Pan with any tool |
| Mouse wheel, `+`, `=`, `-` | Zoom |
| `0` or `f` | Fit |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` or `Ctrl+Y` | Redo |
| `Delete` | Remove the last annotation (undoable) |
| `s`, `Ctrl+S` or `Enter` | Save and copy |
| `y` or `Ctrl+C` | Copy without saving |
| `o` | Copy the text in the image as shown (OCR); the review stays open |
| `u` | Share with NIRUSHARE (devices, or Discord webhooks after a preview) |
| `Escape` | Discard (first cancels a drag in progress) |

Saved screenshots go to `~/Pictures/Screenshot-YYYY-MM-DD_HH-MM-SS.png`; an existing name gets `-2`, `-3` and so on. Saving or copying an edited image replaces the clipboard with the edited version. After saving, a notification offers Open, Copy and Show in folder (when `notify-send` supports actions).

Editing is non-destructive: every crop, mark and text is an operation over the untouched capture, with up to 100 undo steps. The mask is always opaque black, never a blur, because a blur can leak what is underneath.

## Pick a colour from the screen

Press `Super+Ctrl+C` (or run `nirushot pick`). The screen freezes, and a loupe next to the pointer shows the 11x11 pixels around it magnified ten times, with a crosshair and the value.

| Keys | Action |
|---|---|
| Mouse | Move the crosshair |
| Arrow keys | Move one pixel |
| `Shift`+arrow keys | Move ten pixels |
| `Tab` / `Shift+Tab` | Format: `#rrggbb`, `rgb(r, g, b)`, `hsl(h, s%, l%)` |
| Left click, `Enter` or `Space` | Pick |
| `Escape` or right click | Cancel |

The value is printed, copied and shown in a notification. The last ten colours are kept in `~/.local/state/nirushot/colors.json`; see them with `nirulauncher --colors` (`Enter` copies the hex value).

```sh
nirushot pick --format hsl     # start in hsl() instead of #rrggbb
nirushot pick --no-copy --no-notify --no-history
```

The picker gives up after 60 seconds without input, never opens over a lock, and exits 0 after a pick, 1 when cancelled, 2 on an error.

## Copy text from the screen (OCR)

Press `Super+Ctrl+O` (or run `nirushot ocr`). The screen freezes; drag over the text. `tesseract` reads it in Swedish and English, and the text is copied. The notification shows the first line and the character count, with **Copy again** and **Undo** (puts back what the clipboard held before) where the notification daemon supports actions. `Escape` or a right click cancels.

In the review window, `o` does the same for the image as you edited it (after crops and masks).

```sh
nirushot ocr --check                    # tesseract version, installed and missing languages
nirushot ocr --languages swe+eng --psm 6
nirushot ocr --geometry 800x200+100+100 # a fixed region, for scripts
nirushot ocr --image page.png           # read a file, no screen
```

NIRUX 0.12.245 installs tesseract with Swedish and English data on Debian, Arch and Void. Nothing leaves the machine: the region is written to a private temporary directory and removed right after.

Optional settings in `~/.config/nirushot/config.toml`:

```toml
[ocr]
languages = "swe+eng"   # tesseract codes joined with +
psm = 3                 # page segmentation; 6 suits one block, 7 one line
keep_newlines = true    # false joins everything into one line
```

| Key | Default | Meaning |
|---|---|---|
| `languages` | `"swe+eng"` | OCR languages |
| `psm` | `3` | tesseract page segmentation mode, 0 to 13 |
| `keep_newlines` | `true` | Keep line breaks in the copied text |

If OCR misreads small or styled text, select tighter or try `psm = 6` or `psm = 7`. Without the `swe` data, å, ä and ö come out wrong; `nirushot ocr --check` tells you.

The capture sound is switched with `nirux sounds toggle screenshot` (see [10-sound-notifications-studio.md](10-sound-notifications-studio.md)).

## Record the screen

NIRUCLIP is alpha: recording, pause/resume and recovery work, but `--window` records a fixed rectangle and camera/audio results depend a lot on the hardware.

NIRUWM has no default recording key. Start a recording from:

- the capture view: `nirulauncher --clip` (also a middle click on the bar's `recording` module);
- a terminal, with `niruclip`.

The capture view offers Full screen, Region, Webcam only, the four camera corners, your saved profiles, Stop, Check camera, Camera preview, MP4/GIF export, Share and Recover. Its recordings start with a 3-second countdown.

While recording, the bar's `recording` module shows `● rec MM:SS` (`○ paused MM:SS` while paused). Right-click it to stop and save.

```sh
niruclip --full --audio mic               # full screen and microphone
niruclip --region --audio both            # drag a region; microphone and desktop audio
niruclip --full --webcam corner --corner bottom-right --webcam-size large
niruclip --webcam-only --audio mic        # camera only
niruclip --profile screen-camera
niruclip --pause
niruclip --resume
niruclip --stop
niruclip --status                         # add --json for scripts
```

`--full` records the primary RandR output (`--screen OUTPUT` picks another). Recordings go to `~/Videos/NIRUCLIP-YYYY-MM-DD_HH-MM-SS.mkv` (or `--output PATH`, or the `NIRUCLIP_OUTPUT` directory). Existing files are never overwritten.

To get a key, add a binding to `~/.config/niruwm/config.toml`, for example:

```toml
[[keys]]
keys = "super+alt+r"
action = "shell niruclip --stop"
description = "Stop and save the NIRUCLIP recording"
```

Check that the key is free first with `Super+F1` and `Ctrl+R`.

## Recording options

| Option | Values |
|---|---|
| Mode | `--full` (default), `--region`, `--window`, `--webcam-only` |
| `--audio` | `none`, `mic` (default), `desktop`, `both` |
| `--mic` | A source name, part of its description, or `default` |
| `--webcam` | `off`, `corner`, `only` |
| `--corner` | `top-left`, `top-right`, `bottom-left`, `bottom-right` |
| `--webcam-size` | `small`, `medium` (default), `large`: 20, 26 or 34 % of the video height |
| `--camera` | A device, or `auto` (first camera, infrared sensors skipped) |
| `--camera-shape` | `rounded` (default), `circle`, `rect` |
| `--camera-border` | `theme` (default), `none`, or `RRGGBB` |
| `--mirror`, `--no-mirror` | Mirror the camera (default: not mirrored, so text reads correctly) |
| `--preset` | `share` (default, up to 1080p), `small` (up to 720p), `quality`; never upscales |
| `--encoder` | `auto` (default: VAAPI when a probe succeeds), `software`, `vaapi` |
| `--countdown` | `0` to `10` seconds (default 3) |
| `--output PATH` | A file or directory |
| `--screen OUTPUT` | A connected RandR output |
| `--profile NAME` | A saved or built-in profile |
| `--no-notify` | No desktop notifications (also `NIRUCLIP_NOTIFY=0`) |

`--audio both` mixes microphone and desktop audio at full level with a peak limiter that only acts when the sum would clip.

## Choose the microphone

*(NIRUCLIP 0.6.0)*

```sh
niruclip --list-mics                       # input sources; * marks the system default
niruclip --list-mics --json
niruclip --full --audio mic --mic webcam   # this recording only
niruclip --full --audio both --mic UMC1820
```

`--mic` takes an exact source name, or a case-insensitive part of the description (`webcam`, `UMC1820`), or `default`. It applies to `--audio mic` and the microphone half of `--audio both`; the system default is never changed. The order of precedence is `--mic`, then the profile's `mic`, then the top-level `mic` in the config, then the system default.

If the chosen microphone is not there, NIRUCLIP records from the system default and says so in a notification during the countdown; it never refuses to record because of the microphone. `--status` shows which microphone was used.

## Use the camera

```sh
niruclip --check-camera                       # is the picture usable?
niruclip --preview --camera-shape circle --mirror   # live preview of the overlay; q closes
```

The countdown and the running recording check the camera. They detect a privacy image (for example a crossed-out camera), a frozen picture, a camera that sends no frames, or one another program uses, and report it in a notification, in `--status`, in the bar (`· cam off`, `· cam !`) and in the launcher.

**Camera recovery.** If the camera is unplugged or stops sending frames:

- a screen recording continues without the camera at once and takes it back if it returns within 10 seconds;
- a camera-only recording waits up to 10 seconds, then saves what was recorded.

A camera that shows its firmware placeholder is closed and reopened in another mode (twice by default) before NIRUCLIP warns. The result is always one playable file; each switch shows as a short jump.

If the picture is a crossed-out camera or black, that is the camera's own privacy image: press the camera key (often `F10` on HP laptops), open the shutter or check the BIOS setting, then run `niruclip --check-camera`. "Camera is in use by ..." means a browser or video call holds it.

Recovery settings, at the top of `~/.config/niruclip/config.toml`:

| Key | Default | Meaning |
|---|---|---|
| `camera_reconnect_seconds` | `10` | Wait this long for a lost camera; `0` turns recovery off |
| `camera_stall_seconds` | `2` | No new frame for this long counts as lost (0.5 to 30) |
| `camera_reopen_attempts` | `2` | Reopens on a placeholder or frozen picture; `0` only warns |
| `camera_reopen_autosuspend` | `true` | Keep USB autosuspend off while reopening, when allowed without root |

## Profiles

Built-in profiles:

| Profile | Captures |
|---|---|
| `screen-mic` | Full screen and microphone |
| `screen-camera` | Full screen with camera overlay and microphone |
| `camera-mic` | Camera only with microphone |
| `screen-desktop` | Full screen with desktop audio |

Save the current options as a profile, list them, and use one:

```sh
niruclip --full --audio desktop --save-profile demo
niruclip --list-profiles
niruclip --profile demo
```

Profiles live in `~/.config/niruclip/config.toml`. Options on the command line override the profile.

```toml
schema = 1
default_profile = "screen-mic"   # used when no --profile is given
encoder = "auto"
mic = "default"

[profiles.demo]
description = "Custom capture profile"
mode = "full"                    # full, region, window, webcam-only
audio = "desktop"                # none, mic, desktop, both
mic = "UMC1820"                  # optional
webcam = "off"                   # off, corner, only
corner = "bottom-right"
webcam_size = "medium"
preset = "share"
countdown = 3
camera_shape = "circle"
camera_mirror = false
camera_border = "theme"

[profiles.screen-camera]         # same name as a built-in: changes only these keys
mic = "webcam"
```

`camera`, `camera_shape`, `camera_mirror` and `camera_border` can also be set at the top level as defaults for every recording. A `/dev/v4l/by-path/` device path keeps pointing at the same USB port.

## Export and share

```sh
niruclip --export mp4                 # MP4 next to the last recording, lossless and instant
niruclip --export mp4 --from 3 --to 9 # trimmed (re-encoded for an exact cut)
niruclip --export gif --from 3 --to 9 # 12 fps, up to 720 px wide, at most 30 s by default
niruclip --export mp4 --input ~/Videos/NIRUCLIP-2026-11-09_10-00-00.mkv
niruclip --share                      # export MP4 and open NIRU Share with it
```

The MKV itself is never changed.

## Recover an interrupted recording

Recordings are written as `.part.mkv` and renamed only when they contain a usable video. If a recording ends unexpectedly (crash, killed encoder, power loss):

```sh
niruclip --status
niruclip --recover
```

`--recover` validates and restores the partial file, joins the segments of a paused recording, and after a power loss remuxes the file losslessly. The bar's `recording` module offers recovery on a right click, and the capture view has **Recover interrupted recording**.

NIRUCLIP warns below 2 GB free space and stops cleanly (or does not start) below 500 MB. It never deletes a recording.

## Files

| Path | Purpose |
|---|---|
| `~/Pictures/Screenshot-*.png` | Saved screenshots |
| `~/.config/nirushot/config.toml` | Optional `[ocr]` settings |
| `~/.local/state/nirushot/colors.json` | The last ten picked colours |
| `~/Videos/NIRUCLIP-*.mkv` | Recordings (`*.part.mkv` while recording), exports next to them |
| `~/.config/niruclip/config.toml` | Profiles, default profile, encoder, microphone, camera recovery |
| `~/.local/state/niruclip/session.json` | Recording state, read by the bar and the launcher |

## See also

- [05-launcher.md](05-launcher.md)
- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [15-key-bindings.md](15-key-bindings.md)
- [16-commands.md](16-commands.md)
