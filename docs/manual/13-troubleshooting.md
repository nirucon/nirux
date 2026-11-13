# Troubleshooting

Where to look first, the logs, and fixes for common problems.

## Start here

```sh
nirux status        # programs, session file, PAM, polkit, generation, manual
nirux doctor        # status, plus tools, audio, capture, config checks and the live session
nirux doctor --fix  # the same, then repairs what it safely can, after asking
niructl explain     # what is going on with this session
```

`nirux doctor` ends with a list of the problems it can repair itself.
`nirux doctor --fix` shows that list, asks once, and then repairs them; `--yes`
skips the question (for scripts). What it repairs:

| Problem | Repair |
|---|---|
| NIRUX packages missing | installs them with the distribution's package manager (sudo) |
| Backlight present but not readable | installs the NIRUX backlight rule and adds you to the `video` group (sudo; log in again for the group) |
| Battery charge limit supported but not writable | installs the NIRUX battery rule (sudo) |
| NIRUBAR not running, or not on every monitor | restarts the bar |
| No notification daemon | starts NIRUNOTIFY for this session |
| `niruidle` not running | starts it for this session (screen saver, idle lock) |
| Night light schedule set but not running | starts the schedule's watcher for this session |
| No default audio sink, with PipeWire as systemd user services | restarts PipeWire and WirePlumber |

Session repairs are offered only inside a running NIRUWM session. Anything else
`doctor` reports, such as an invalid configuration, is left to you:
`niructl config undo` takes back the last configuration change.

`nirux doctor` checks the live window manager, bar, notification daemon, night
light and idle daemon only inside a session; over SSH or from a text console it says
the live check was skipped. In the launcher, the **Health** view
(`nirulauncher --health`) shows installed and running
programs, session, audio, network, display and capture status, with a link from each
row to its settings view or diagnostic command.

## Logs

| Log | What is in it |
|---|---|
| `~/.local/state/niruwm/session.log` | Session and window manager, capped at 8 MB, older lines in `session.log.1` to `.3` |
| `~/.xsession-errors` | What a display manager session wrote before NIRUWM's own log |
| `~/.local/state/nirux/update-power.log` | Phases of `nirux update-reboot` and `update-shutdown` |

```sh
tail -f ~/.local/state/niruwm/session.log
```

## Check a configuration file

```sh
niruwm --check-config
nirubar --check-config
nirulauncher --check-config
nirunotify --check-config
niruidle --config
nirulock --config
niruscreensaver --config
```

A typing error in `config.toml` never ends the session or hides the bar. At login
NIRUWM and NIRUBAR start with the last settings that worked (kept in
`~/.local/state/niruwm/config.last-good.toml`), or the defaults when there are
none, and a notification says where the error is, for example
`config.toml line 213: expected '.', '='`. A reload with an error keeps the
current settings and shows the same notification. Fix the line, then
`Super+Shift+R` or `niructl reload`. The error is also in the session log.

## Common problems

| Problem | What to do |
|---|---|
| A new release is installed but nothing changed | Log out and back in. A running window manager is never replaced by an update. `nirux status` says when the running WM is from an old generation. |
| Something broke after an update | `nirux rollback`, then log in again. Configuration: `nirux restore latest --dry-run`, then `nirux restore latest`. See [Keeping NIRUX up to date](11-updates.md). |
| A configuration change did nothing | `niruwm --check-config`, then `niructl reload` (or `Super+Shift+R`). |
| The bar is missing or wrong | `niructl restart-bar`. `niructl bar show` if it was hidden with `Super+Alt+B`. |
| The screen went back to the login screen | Read the session log. A deliberate quit is logged as `quit requested ...`, a crash as `niruwm stopped with status N ... starting it again`. After a crash NIRUWM restarts with the open windows; only four crashes within a minute end the session. |
| The session does not start, or a display manager opens only a terminal | `nirux repair-session`, then choose the **NIRUWM** session in the greeter (Debian's *Default Xsession* is not NIRUWM). |
| A setting change made things worse | `niructl config undo` goes back one working version (again for one more); `niructl config history` lists them. |
| The wallpaper is wrong or missing | `niructl wallpaper status` says why. `niructl wallpaper follow-theme on` returns to theme wallpapers; `nirux repair-wallpaper` repairs the setup. |
| Windows are on a screen that is gone | `niructl windows rescue` (try `--dry-run` first) moves them to a connected screen. |
| A display profile does not apply | `niructl display doctor` shows what matches and what is missing. See [Displays and profiles](09-displays.md). |
| A key does nothing | `Super+F1`, then `Ctrl+R` and press the key: the cheat sheet tells what it is bound to and flags clashes. On Swedish layouts use `Super+F1` instead of `Super+/`. |
| No sound, or videos play silently | `niruio doctor` (or `Super+Shift+A`, Doctor tab) follows the sound from the program to the device and offers a fix; `niruio doctor --fix` applies them. A whole kind of program that stays silent (every video in mpv, every game) is usually a role WirePlumber remembers as muted: `niruio saved`, then `niruio reset --silencing`. `niructl audio status`, `niructl audio outputs`; `nirux doctor` checks for a default PipeWire sink. Only "Dummy Output" on Void: the sound card appeared while udev was starting; NIRUX's `nirux-udev-replay` service fixes it at the next start (`sudo sv status nirux-udev-replay`). See [Sound, notifications and studio mode](10-sound-notifications-studio.md). |
| Bluetooth audio does not work | `nirux doctor` reports a missing BlueZ SPA plugin: install your distribution's PipeWire BlueZ package. A headset that sounds like a telephone is in headset mode: NIRUIO's Cards tab switches it to hi-fi playback. |
| A microphone records nothing, or the camera is missing | `niruio doctor` checks the input (muted, turned down, ALSA capture switch, unplugged port) and the cameras (present, `video` group, held by another program). |
| Brightness keys do nothing | `nirux doctor` says whether `brightnessctl` can read the backlight; it needs udev or group permissions. |
| Video in Helium or Teams uses the processor | `nirux doctor` shows the graphics card and whether hardware video is on, and why not; `nirux doctor --fix` installs missing packages. Restart Helium after it is turned on. See [Hardware video in Helium](11-updates.md#hardware-video-in-helium). |
| Screenshots or recording fail | `nirux doctor` checks `ffmpeg` with `x11grab`, `slop`, `maim` and the camera device. |
| The disk is filling up | `nirux clean` shows what can be freed (package cache, the journal above 200 MB, thumbnails, old NIRUX generations and snapshots, trash older than 30 days), asks once and cleans; `--dry-run` only shows. The bar's red disk icon opens it. `niructl storage review` looks at your own files. |
| Wi-Fi, sound or a screen is wrong after sleep | NIRUWM runs `nirux resume-check --notify` a few seconds after the computer wakes: it switches a Wi-Fi that does not reconnect off and on, restarts PipeWire when it does not answer, re-applies the display profile and checks Tailscale (a root sleep hook restarts its daemon). It notifies only when it fixed something or could not. Run `nirux resume-check` yourself; the last 50 runs are in `~/.local/state/nirux/resume-check.log`. |
| `nirux status` says system changes are waiting | The nightly update left root steps for you: run `nirux update` once. See [Keeping NIRUX up to date](11-updates.md). |
| Downloads from GitHub fail | NIRUX falls back to the GitLab mirror by itself; see [Keeping NIRUX up to date](11-updates.md). |
| Wi-Fi cannot be controlled | See [WIFI.md](https://github.com/nirucon/nirux/blob/main/docs/WIFI.md) for the supported backends and their limits. |

## Try a new login screen safely

When you switch to NIRU Login (or another display manager), keep a working one, or a
text console login, available until you know the new one works on that machine.
From a text console you can always start the session with
`startx "$HOME/.local/bin/niruwm-session"` (never over SSH).

## Start over

Usually one part is enough, and every step can be undone:

```sh
niructl config undo         # back to the version before your last change
niructl config reset bar    # only the bar back to the defaults
niructl config diff         # what you have changed from the defaults
```

See [History, undo and reset](14-configuration-reference.md#history-undo-and-reset).
To replace the whole file:

```sh
nirux snapshot --note "before reset"   # keep what you have
nirux reset-config                     # config.toml back to the current example
```

`reset-config` keeps a `.nirux-backup` copy next to the file and discards your theme,
browser, key and bar choices in it. `nirux restore` brings back a snapshot.

## Report a problem

Include the NIRUX version (`nirux --version`), the distribution, the output of
`nirux doctor` and the relevant part of the session log. Remove anything private
before you share a log. Issues go to the repository of the component, or to
[nirucon/nirux](https://github.com/nirucon/nirux/issues) when you are not sure.

## See also

- [Keeping NIRUX up to date](11-updates.md)
- [Configuration reference](14-configuration-reference.md)
- [Command reference](16-commands.md)
