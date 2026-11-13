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

The bar's update indicator (the `niruxupdate` module) tells you when a newer core
release exists; `updates` counts the system packages that can be upgraded.

**What's new.** After an update that installs a new NIRUX version, the first
graphical login shows one notice, *NIRUX X.Y.Z: what's new*, with the highlights
of every release since the version you had (at most six lines). *Open the manual*
opens this manual. The notice is shown once; `nirux whats-new` prints it again.

**Apps follow upstream.** Helium, LocalSend and OpenCode are not distribution
packages. `nirux update` installs each app's newest stable upstream release when
that release publishes a SHA-256 for its archive (the GitHub release digest; for
OpenCode 2, the sha512 of the npm package `@opencode/cli-linux-x64`, the same
binary opencode.ai serves). The archive is verified before it is unpacked, the
program is started once to check its version, and only then is it switched in. The
upstream answer is cached for an hour. The versions pinned in NIRUX are the
minimum: if the lookup, the checksum or the download fails, the installed version
is kept, and nothing is ever installed below the pin. Prereleases are never used.
`nirux update --apps pinned` (or `NIRUX_APPS=pinned`) keeps the pins; `nirux
status` lists each app's installed and newest version.

**No logout after an update.** When `nirux update` runs inside a NIRU session, it
restarts NIRUWM in place (`niructl restart-wm`): the window manager, the bars and the
session helpers whose program changed (notifications, idle daemon, clipboard and
gesture daemons, NIRUSHARE, the display and night-light watchers) are replaced, and
every window keeps its screen, workspace, layout, floating state and focus. A locked
screen stays locked: the restart waits until you unlock. Run `niructl restart-wm`
yourself after an update over SSH or from outside the session.

A session that is still running NIRUWM 0.22.x or older cannot restart in place. The
update then restarts the bar only and says so: log out and back in once, and from then
on updates apply without logging out. `nirux status` says when the running WM is
still the old generation, and whether `niructl restart-wm` can activate it.

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

## Weekly checkup

Every NIRUX computer checks itself every Monday at 07:00 and cleans up. A computer that was off, or asleep, runs the checkup when it starts, if a Monday 07:00 has passed since the last one. It runs at the lowest priority and takes a few seconds; on battery below 30 % it only checks and leaves the clean-up for later.

**What it checks:** disk use of `/`, `/home`, `/boot`, the EFI partition and mounted data disks (a warning at 85 %), inodes, SMART and NVMe health (wear, media errors, bad sectors), failed services, whether a reboot is needed for a new kernel, waiting package updates (security updates are a warning), whether NIRUX is behind the latest release, the age of the newest `nirux snapshot`, out-of-memory kills and errors in the log this week, time sync, Tailscale, the firewall and battery health.

**What it cleans:** the package cache (`apt clean`, `paccache` keeping two versions, `xbps-remove -O`), unused packages and old kernels (`apt autoremove`, orphaned packages on Arch, `xbps-remove -o` and `vkpurge` on Void), the journal down to 200 MB or four weeks, coredumps older than a week, your own files in `/tmp` and `/var/tmp` older than ten days, thumbnails older than 90 days and unused Flatpak runtimes. It never follows links and never touches your files otherwise.

```sh
nirux checkup               # run it now
nirux checkup --dry-run     # show what it would do, change nothing
nirux checkup last          # the latest report (the last three are kept)
nirux checkup status        # on or off, last and next run
nirux checkup disable       # or enable
nirux checkup discord set   # paste a Discord webhook URL; empty removes it
nirux checkup discord test
```

With a webhook set, each computer posts its report to Discord: its name, OK or the number of warnings, and one line per check. Settings are in `/etc/nirux/checkup.conf` (edit with sudo): `enabled`, `discord` (`always`, `warnings` or `off`), `clean` (`full`, `safe` without unused packages and old kernels, or `off`) and `disk_warn`. Reports are in `/var/lib/nirux/checkup/`. The checkup is a root-owned program, `/usr/libexec/nirux-checkup`, started by a systemd timer (`nirux-checkup.timer`) or, on Void, the runit service `nirux-checkup`; `smartmontools` (and `pacman-contrib` on Arch) are installed with NIRUX.

## Nightly update

Every NIRUX computer updates itself at night, on by default: the system packages
(`apt-get full-upgrade`, `pacman -Syu`, `xbps-install -Su`), NIRUX, the selected
extras and the apps above. It starts at 03:00 (a random delay of up to half an
hour on systemd; every quarter hour between 03:00 and 05:00 on Void) and only
when **nobody is logged in**: no user session in `loginctl` (the login screen does
not count) and no one in `who`, SSH included. On battery it waits for the charger
or at least 50 %. A computer that is off at night simply updates the next night.
It never restarts the computer and never touches a running session.

A run checks with `nirux doctor`, runs `nirux update --auto` (which saves a
configuration snapshot before it changes anything, like every update), `nirux
extras update` and `nirux doctor` again. When the second doctor finds a problem
the first did not, the run goes back: `nirux rollback` to the previous program
generation and `nirux restore` of that snapshot, and it posts a warning. A night
with nothing new installs nothing and takes no snapshot, so your own snapshots
stay among the kept ones.

```sh
nirux autoupdate            # status: on or off, user, window, last run
nirux autoupdate last       # the latest report (the last seven are kept)
nirux autoupdate run-now    # run it now (also while you are logged in)
nirux autoupdate disable    # or enable
```

**Waiting system changes.** The nightly update runs your NIRUX as you, without a
password. Whatever needs root and would change something (a new rule, a changed
helper, a package NIRUX now needs) is left for later and listed in `nirux
status`, `nirux autoupdate status` and the what's-new notice, as *Run nirux
update once to finish*. The bar does not show it. Packages a release needs are
installed by the nightly run itself, from your distribution's repositories,
before it runs the update once more, but only names in
`/etc/nirux/autoupdate-packages`: the complete list of packages this NIRUX
version may install on your distribution, root-owned and written by every
interactive `nirux update` (never by the nightly one). Any other name waits for
your next `nirux update`.

Settings are in `/etc/nirux/autoupdate.conf` (edit with sudo): `enabled`, `user`,
`window` (`03:00-05:00`) and `discord` (`warnings`, `always` or `off`; it uses the
webhook of `nirux checkup discord set`). Reports are in `/var/lib/nirux/autoupdate/`.
The nightly update is a root-owned program, `/usr/libexec/nirux-autoupdate`,
started by `nirux-autoupdate.timer` or, on Void, the runit service
`nirux-autoupdate`. It runs only the distribution's package manager as root; your
NIRUX in `~/.local` always runs as you.

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
