# Keeping NIRUX up to date

How to update NIRUX, undo an update, protect and restore your configuration, and
keep several machines in step.

## How an update works

NIRUX installs a *generation*: every core program at the versions pinned in the
release's `manifest`, downloaded as release assets and checked against their
SHA-256 sums before anything changes.

| Path | What it is |
|---|---|
| `~/.local/share/nirux/generations/` | The installed generations, one directory per release |
| `~/.local/share/nirux/current` | Link to the active generation |
| `~/.local/share/nirux/previous` | Link to the generation `nirux rollback` returns to |
| `~/.local/share/nirux/current/manual` | This manual, as shipped with the active release |
| `~/.local/bin/` | Links to the programs of the active generation |

A failed download, a checksum mismatch or a rejected configuration stops the update
and keeps the current installation. Your settings are kept: an update only adds new
keys with their defaults.

## Update

```sh
nirux update                     # the newest release
nirux update --release 0.12.245  # a specific release
nirux update --no-packages       # do not install missing OS packages
nirux status                     # what is installed and active
```

The bar's update indicator (the `updates` module) tells you when a newer core
release exists. It follows the core suite only; extras are updated separately.

**Log out and back in after an update.** The running window manager, idle daemon and
session are only replaced at a new login. The bar is restarted by the update when it
runs inside a session (or run `niructl restart-bar`). `nirux status` says when the
running WM is still the old generation.

## Update everything, then power off or restart

```sh
nirux update-shutdown            # system packages, NIRUX, extras, then power off
nirux update-reboot              # ... then restart
nirux update-reboot --dry-run    # print the plan, change nothing
nirux update-reboot --no-power   # run the updates, keep the machine running
```

These run in a terminal so the sudo and package prompts stay visible. They update
the distribution (`apt-get full-upgrade`, `pacman -Syu` or `xbps-install -Suy`),
then run `nirux update`, then `nirux extras update` when extras are selected, and
only power off or restart when every step succeeded. They never force a shutdown.
`--yes` skips the final confirmation. The same actions are in NIRU Actions and Quick
Settings (*Update and restart*, *Update and shut down*), and `niructl update-reboot`
or `niructl update-shutdown` opens them in a terminal.

Not included: AUR helpers, Flatpak, Snap, Docker images and firmware. The log is
`~/.local/state/nirux/update-power.log`.

## Undo an update: rollback

```sh
nirux rollback
```

This switches `current` back to the previous generation (and back again if you run
it twice). Log out and in afterwards. A rollback restores **programs only**: not OS
packages, not PAM configuration and not your configuration files. For those, use a
snapshot.

Old generations are removed after every update. Kept are the current one, the
previous one, any generation a running program still uses, and the five newest:

```sh
nirux gc --dry-run      # what would be removed
nirux gc --keep 3       # keep the three newest (plus current and previous)
```

## Configuration snapshots

Every `nirux update` first saves your suite configuration; so do
`nirux extras update` (when it installs something) and `nirux reset-config`.

```sh
nirux snapshot --note "before trying a new theme"   # save one now
nirux snapshot list                                   # what is there
nirux restore latest --dry-run                        # what a restore would change
nirux restore 20261109-153000-0.12.243-to-0.12.244    # restore one, after y/N
```

Snapshots are in `~/.local/state/nirux/snapshots/<time>-<from>-to-<to>.tar.gz`; the
newest three are kept. Each has a `MANIFEST` with the time, the reason, the NIRUX
version and every file with its size and SHA-256.

A snapshot holds `~/.config/niruwm` (themes and display profiles included),
`niruui`, `nirubar`, `nirulauncher`, `nirunotify`, `nirulock`, `niruscreensaver`,
`niruclip`, `nirushot`, `niruwallpaper`, `nirudisplay`, `niruthemeselector`,
`nirux`, `niru` (quotes and keys), `NIRU` and the extras' config directories,
`picom.conf`, `kitty/kitty.conf`, `fish/config.fish`, the registered keys in
`~/.local/share/niru/keys.d` and the launcher favourites. It leaves out
`~/.config/nirushare` (it holds an upload token), anything that looks like a token,
password or key, files over 16 MiB, caches, other state and your music.

`nirux restore` lists each file it would bring back, with added and removed lines,
and keeps files that are newer than the snapshot. After you answer `y` it first takes
a safety snapshot, so a restore can itself be undone. It then tells you what to
reload: most changes need `niructl reload`; lock settings apply at the next lock.

`~/.config/nirux/snapshots.toml`:

```toml
[snapshots]
keep = 3          # how many snapshots to keep
strict = false    # true: an update stops when its snapshot fails
```

A failed snapshot (a full disk, for example) only warns, unless `strict = true` or
`NIRUX_SNAPSHOT_STRICT=1`.

## Several machines: fleet

```sh
nirux fleet setup            # once: SSH key login from this machine to the others
nirux fleet                  # status of every NIRUX machine
nirux fleet status --json    # the same, machine-readable
nirux fleet update othala    # update named hosts, one at a time
nirux fleet update --behind  # every host older than the latest release
nirux fleet update --all     # every online host
```

The machines are the Linux peers on your Tailscale network that have
`~/.local/bin/nirux`. The table shows each host's NIRUX version, whether it is
behind, whether a **relogin** is needed (the running WM or bar is not from the active
generation), whether the screen is locked, the distribution, the uptime and the time
of the last update. Offline hosts show the version they had when last seen.

The **HEALTH** column says `ok`, or lists what needs a look:

| Shown | Meaning |
|---|---|
| `disk 93%` | The home file system is at least 90% full, or has less than 5 GiB free |
| `2 failed units` | Failed systemd units, system and user (`systemctl --failed`, `systemctl --user --failed`). Not checked on runit (Void) |
| `1 stale session` | Another graphical session of yours on seat0 beside the one that runs NIRUWM, usually left over from an earlier login. `loginctl list-sessions` shows it |
| `lock: no PAM file` | `/etc/pam.d/nirulock` is missing, so the lock screen cannot check a password. `nirux update` writes it again |
| `lock: niruidle not running` | The session has no idle locker (unless `START_IDLE=0` in `~/.config/niruwm/session.conf`) |
| `lock: nirulock missing` | No `nirulock` in the active generation |

`--json` has the same under `health` for each online host. `NIRUX_FLEET_DISK_WARN`
changes the disk threshold (percent).

`nirux fleet update` runs `nirux update`, and `nirux extras update` where extras are
selected, over `ssh -t`, so each host's sudo prompt appears in your terminal. It never
logs anyone out or locks a session.

`nirux fleet setup` creates `~/.ssh/id_ed25519` if you have none, runs `ssh-copy-id`
to each host without access (it asks for that host's password once) and checks the
key login. It does not change Tailscale, sshd or PAM.

Without Tailscale, or to choose the hosts, use `~/.config/nirux/fleet.toml`:

```toml
[fleet]
hosts = ["othala", "niruxwork"]   # replaces Tailscale discovery
exclude = ["proxmox"]             # never listed
```

`NIRUX_FLEET_TIMEOUT` sets the SSH connect timeout in seconds (default 5).

## Share settings between machines: sync

```sh
nirux sync status                  # what differs from every fleet host
nirux sync status othala --files   # one host, every differing file
nirux sync push othala quotes      # copy this machine's quotes to othala
nirux sync push --all theme lock   # ... to every online host
nirux sync pull othala sid         # copy othala's SID tunes here
nirux sync items                   # the items and their paths
```

`sync` uses the SSH access of `nirux fleet`. `push` and `pull` show what they will copy
and ask y/N (`--yes` for scripts, `--dry-run` for the preview only). The receiving
machine takes a snapshot first. Nothing is deleted on the receiving side.

| Item | What |
|---|---|
| `quotes` | `~/.config/niru/quotes.txt` and `~/.config/niru/quotes/` |
| `keys.d` | Registered keys for the cheat sheet |
| `theme` | The `theme` key of `config.toml`, `~/.config/niruwm/themes/`, `theme-preferences.toml` |
| `lock` | `~/.config/niruui/lock.toml`, `screensaver.toml`, `~/.config/nirulock`, `~/.config/niruscreensaver` |
| `launcher` | `~/.config/nirulauncher` and the launcher favourites |
| `sounds` | `~/.config/nirux/sounds.toml` and `~/.config/nirux/sounds/` |
| `sid` | `~/Music/SID` with `Songlengths.md5` |

`config.toml` is never copied as a whole, since it holds each machine's monitors,
display profiles, brightness device and autostart; only its `theme` key travels.
Display profiles, secrets, state and caches are never synced.
`~/.config/nirux/sync.toml` changes the default set:

```toml
[sync]
items = ["quotes", "theme", "lock"]          # default: all items
exclude = ["sid", "~/.config/niru/quotes/"]  # item names, or paths under your home
```

## When GitHub is down: the GitLab mirror

NIRUX downloads its releases from GitHub. When a download or the latest-release lookup
fails there after its retries, NIRUX tries the public backup mirror on GitLab.com
(`gitlab.com/rudolfsson`) for the same file and prints
`nirux: GitHub failed; trying the GitLab mirror`. The checksums in the release's
`SHA256SUMS` still have to match, so the mirror cannot change what is installed.

| Variable | Effect |
|---|---|
| `NIRUX_MIRROR=none` | Never use the mirror |
| `NIRUX_MIRROR_GITLAB=NAME` | Another GitLab namespace (default `rudolfsson`) |
| `NIRUX_FETCH_ATTEMPTS`, `NIRUX_MIRROR_ATTEMPTS` | Download attempts on GitHub (8) and on the mirror (3) |

## Extras

Extras have their own release cadence and are not part of a `nirux update`:

```sh
nirux extras list      # pinned, installed and selected
nirux extras update    # update the selected extras to the versions this release pins
```

See [Extras](12-extras.md).

## Uninstall

```sh
nirux uninstall          # remove NIRUX-owned programs, links and integration
nirux uninstall --purge  # also its configuration and state, including user themes
```

Uninstall extras first with `nirux extras uninstall NAME`. OS packages and the chosen
display manager are kept. Purge is not a lossless undo of every change; see
[INSTALL.md](https://github.com/nirucon/nirux/blob/main/docs/INSTALL.md#uninstall).

## See also

- [Command reference](16-commands.md)
- [Troubleshooting](13-troubleshooting.md)
- [Extras](12-extras.md)
