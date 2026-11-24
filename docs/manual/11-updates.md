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
An app that is open while it is updated keeps running from its old version: the
old files stay until nothing runs from them, and a later update removes them
(NIRUX 0.12.301 and later; before, they were removed at once, so a long-running
Helium could no longer start its camera helper and Teams showed no camera).
The update says `Keeping helium-... while it runs`, and a notice asks you to
restart the app; close all its windows and open it again to use the new version.
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

## Teams and Microsoft 365 in Helium

Helium blocks third-party cookies and pop-ups. Teams, Outlook and the other
Microsoft 365 web apps renew their sign-in in a hidden frame from
`login.microsoftonline.com`; when that is blocked they show a "sign in again"
banner, and its button opens a pop-up that is blocked too, so nothing happens.

```sh
nirux browser-m365 on       # allow Microsoft 365 sign-in in Helium
nirux browser-m365 status
nirux browser-m365 off
```

`on` installs a managed policy (`/etc/chromium/policies/managed/nirux-m365.json`,
sudo) that lets only Microsoft's sign-in and Microsoft 365 sites keep their
cookies and open pop-ups, keeps the storage of Teams and Outlook in one piece,
and lets Teams use the microphone, camera and notifications without asking
every time. Every other site keeps Helium's defaults. Quit Helium once, every
window, so it reads the policy; `helium://policy` lists it. The choice is kept
across updates.

## Hardware video in Helium

Video in Helium, and the video in Teams calls, is decoded by the graphics card
instead of the processor when the card can do it. `nirux install` and `nirux
update` set it up for the managed Helium:

1. Find the graphics card that drives the display. On a computer with two
   cards (a laptop with Intel and NVIDIA, a desktop with an idle Intel chip and
   an AMD card) this is the one the screen is connected to, else the integrated
   one.
2. Install the video driver and the tools to check it, through the normal
   package step (sudo):

   | Distribution | AMD | Intel | Always |
   |---|---|---|---|
   | Debian | `mesa-va-drivers` | `intel-media-va-driver` | `vainfo`, `vulkan-tools`, `mesa-vulkan-drivers` |
   | Arch | `mesa`, `vulkan-radeon` | `intel-media-driver`, `vulkan-intel` | `libva-utils`, `vulkan-tools`, `vulkan-mesa-implicit-layers` |
   | Void | `mesa-vaapi`, `mesa-vulkan-radeon` | `intel-media-driver`, `mesa-vulkan-intel` | `libva-utils`, `Vulkan-Tools`, `mesa-vulkan-overlay-layer` |

3. Check the card: `vainfo` must list decoding (H264, VP9, AV1 or HEVC) on its
   render node, and Vulkan must see the same card. Only then does Helium get
   the flags `--use-angle=vulkan` and
   `--enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks`.
   On a computer with two cards NIRUX also keeps the video decoder and Vulkan on
   the chosen card.

The nightly update never turns it on by itself: the first time happens when
you run `nirux update` or `nirux doctor --fix`, so a change in how Helium draws
is something you see and can try straight away. Once it is on, the nightly
update keeps it current, and turns it off if the check stops passing.

Restart Helium after an update that turns it on. A video in a format the card
cannot decode still plays: Helium decodes it in software, as before. Hardware
video encoding is not turned on; it failed in tests.

`~/.local/bin/helium` is a small NIRUX launcher. It reads
the flags from `~/.local/share/nirux/helium-flags` and starts Helium with them
in front of your own arguments, so a flag you give yourself wins. When the card
the flags were made for is gone (an unplugged external GPU), Helium starts
without them. A Helium that NIRUX did not install is not changed.

**The setting** lives in `~/.config/nirux/browser.toml`. It is a NIRUX file, not
part of `config.toml`, because NIRUWM and NIRUBAR refuse keys they do not know:

```toml
[browser]
# auto: AMD and Intel on, NVIDIA off (the default, also without this file)
# on:   NVIDIA too (needs the proprietary driver and nvidia-vaapi-driver;
#       experimental, Chromium does not support it)
# off:  never; Helium starts as upstream ships it
hardware_video = "auto"
```

Run `nirux update` after a change. The open-source nouveau driver and the old
`radeon` kernel driver are not supported.

**Check it** with `nirux doctor`:

```text
hardware video: GPU AMD 0x150e (amdgpu, 0000:c4:00.0, /dev/dri/renderD128), setting auto
hardware video: VA-API ok, decodes H264 HEVC VP9 AV1; Vulkan sees the GPU
hardware video: Helium flags enabled (--use-angle=vulkan --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks)
```

When it is off, doctor says why (no supported card, NVIDIA, a package missing,
no decoding on the card). When only packages are missing, `nirux doctor --fix`
installs them and turns it on. In Helium, `chrome://gpu` shows *Video Decode:
Hardware accelerated* and, under *Video Acceleration Information*, the formats;
`chrome://media-internals` names `VaapiVideoDecoder` for a playing video.

The nightly update installs these packages too. It asks for them in the
nightly run, and installs them when the list of packages it may install (written
by `nirux update`) names them, so the first `nirux update` after 0.12.271 adds
them to that list.

## Netflix and other protected video in Helium

Netflix, Disney+, Max, Prime Video, Spotify on the web and other services that
protect their video need Google's Widevine module. Helium does not include it,
so NIRUX adds it: `nirux update` downloads the module from Google, checks it
against the checksum Mozilla publishes for Firefox, and points Helium at it.
Helium itself is not changed, and it works for a Helium NIRUX did not install
too. It is on by default.

```sh
nirux widevine            # is it on, and which version
nirux widevine off        # remove it; nirux update leaves it off
nirux widevine on         # download it now and turn it back on
```

Quit Helium (every window) and start it again after it is installed. A newer
module comes with the next `nirux update` or the nightly update; the previous
one is kept until then, because a running Helium may still use it.

- The module lives in `~/.local/share/nirux/widevine/VERSION`, and Helium finds
  it through `~/.config/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm`.
- If that file names another module that exists (one you set up yourself),
  NIRUX leaves it alone, and `nirux doctor` says so.
- On Linux, Netflix and most services play at most 720p in a browser, the same
  as in Chrome. That is the services' limit, not Helium's.
- Google does not allow the module to be passed on, so every computer downloads
  its own copy, and no NIRUX release contains it.
- When Helium ships its own Widevine support, NIRUX will stop adding it.

`nirux doctor` shows `widevine: 4.10.3050.0 on, Netflix and other protected
video play in Helium`, or offers to install it (`nirux doctor --fix`).

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

## Programs that need a restart: nirux stale

An update installs new versions, but a program that already runs keeps the
version it started with. Usually that is fine; sometimes it is not, as when an
old Helium could no longer start its camera in Teams. `nirux stale` names what
still runs an old version:

```sh
nirux stale            # the list, and what to do for each
nirux stale --json     # the same for NIRUBAR's restart module
nirux stale restart    # restart what can restart in place, and say what needs you
```

NIRUWM and NIRUBAR restart in place (your windows stay). Session helpers such
as NIRUIDLE need you to log out and in once; apps (Helium, LocalSend,
OpenCode) need all their windows closed and opened again. The lock screen that
is up is never counted: the next lock starts the new version. NIRUBAR's
`restart` module shows `↻` and the name in the bar while something waits;
click it to run `nirux stale restart`.

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

## Backup and moving to a new computer

`nirux backup` keeps encrypted copies of your settings, keys and mail settings in a folder that
Nextcloud carries off the computer. A computer takes part only when you switch it
on; nothing is copied before that.

```sh
nirux backup setup                 # once per computer: key, then on
nirux backup                       # on or off, the last copy, the copies kept
nirux backup now                   # a copy now
nirux backup list                  # the copies of every computer
nirux backup restore niruxwork --to ~/old-files   # unpack the newest copy
nirux backup off                   # this computer takes no more copies
nirux migrate from niruxwork       # a new computer takes the old one's settings
```

**A copy** is one file, `~/Nextcloud/Backup/nirux/<computer>/<computer>-<date>-<time>.tar.zst.age`:
your settings (or your whole home directory) as tar, compressed with zstd and encrypted with
[age](https://age-encryption.org). The two newest copies of each computer are kept.
It is written as a `.part` file that Nextcloud does not upload, and renamed when it
is complete. The nightly update makes it while you are away (the screen locked or
the computer idle at night), at the lowest processor and disk priority, when one is
due: weekly by default.

**What is kept** (`what = "settings"`, the default): what makes the computer
yours, not your data. That is `~/.config`, `~/.local/bin`, Thunderbird (its
settings and local folders, not its copy of IMAP mail: the server keeps that),
your keys (`~/.ssh`, `~/.gnupg`, the keyring, `~/.password-store`), NIRUX and the
NIRU apps (`~/.local/share/nirux` and `~/.local/share/niru*`), your own launcher
entries, and the shell and X files in your home (`.bashrc`, `.profile`,
`.xinitrc`, `.gitconfig` and the like). Documents, pictures, projects, fonts and
other data are not copied: keep them in Nextcloud.

Even inside those folders some things are left out: caches, browsers and chat
apps (Helium, Chromium, Firefox, Discord, Signal: they sync or need a new login),
downloaded programs, models and game assets (RetroArch's assets, databases,
shaders and cores; its settings and playlists are kept), log files, backup files
(`*.bak`, `*.bak-*`, `*.old`, `*.orig`, `*~` and the like, files or folders), and
every file larger than 1 GB. Files you cannot read (owned by root, for example) are
counted and skipped.

**More or less.** `include = [ "Pictures", "Games/Saves" ]` adds paths;
`exclude = [ ".config/retroarch" ]` leaves more out. `what = "home"` copies the whole
home directory instead, except Nextcloud, caches, games and launchers (Steam,
Proton, Lutris, Heroic, Bottles, Wine), `~/Music`, `~/Videos`, `~/Movies`,
`~/Downloads`, Docker and ISO images.

**The key.** `nirux backup setup` on the first computer creates a key and asks for a
passphrase. The secret key is saved in `~/Nextcloud/Vault/nirux-backup-key.age`,
encrypted with that passphrase, and the public key next to it (`.pub`). The other
computers find both through Nextcloud and only need the public key to write a copy.
The passphrase is asked only to restore or to move. Keep it safe: without it no copy
can be opened.

`~/.config/nirux/backup.toml` (written by `nirux backup setup`):

```toml
[backup]
enabled = true                 # false: this computer takes no copies
every = "weekly"               # or "daily"
keep = 2                       # copies kept for this computer
destination = "~/Nextcloud/Backup/nirux"
key = "~/Nextcloud/Vault/nirux-backup-key.age"
recipient = "age1..."          # the public key
what = "settings"              # or "home": the whole home directory
max_file_mb = 1024             # larger files are left out
exclude = [ ]                  # more paths to leave out, relative to your home
include = [ "Games/Saves" ]    # more paths to keep, even inside a left-out folder
```

**Restore** unpacks a copy into a new directory (`~/nirux-restore-...` unless you
give `--to`) and never changes your home directory: copy back what you need.

**Moving to a new computer.** Install it (niruboot and NIRUX), sign in to Nextcloud
and let it sync `Backup` and `Vault`, then run `nirux migrate from OLD-COMPUTER`.
It unpacks the old computer's newest copy, shows how many files it brings and how
many would replace a file here (`--dry-run` lists them and stops), and copies them
into your home after a `y`. Before that it takes a configuration snapshot, and every
file it replaces is kept in `~/.local/state/nirux/migrate-<time>/`. It never copies
the old computer's display settings (`displays.toml`), sound state, backup choice or
NIRUX installation state: the new computer keeps its own. It then offers to install
the extras the old computer had, and lists what is left: log out and in once, sign
in to Nextcloud, Teams and the browser again, and link Signal from your phone. If
your login password on the new computer differs from the old one, the keyring asks
for the old password once; change it to the new one in Passwords and Keys.

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

### The fleet, live: nirux fleet top

```sh
nirux fleet top                 # refreshes every 5 seconds; q quits
nirux fleet top --interval 10
nirux fleet top --once          # one table, for scripts or a quick look
```

Every NIRUX machine on one screen: state, version (`behind` when older than
the latest release), the 1-minute load with a small graph of the last 20 rounds
(load per core), memory and disk in use, whether the screen is locked, and
what waits for a restart (`nirux stale` on that machine; NIRUX 0.12.302 and
later). It uses the same SSH access as the rest of `nirux fleet` and asks
GitHub for the latest release once, not every round.

### One setting on every machine

```sh
nirux fleet set idle.screensaver_timeout 5          # every NIRUX machine
nirux fleet set idle.lock_after_screensaver 5 othala void
nirux fleet set screensaver.scene ascii              # the screensaver's own file
nirux fleet set lock.layout ascii-cava               # the lock screen (lock.toml)
nirux fleet pending                                  # what waits for an offline machine
nirux fleet pending clear [HOST]
```

`nirux fleet set KEY VALUE` changes one setting on this machine and every other
NIRUX machine, or only on the hosts you name. A key like `idle.screensaver_timeout`
goes to `~/.config/niruwm/config.toml` through `niructl config set` on each host:
comments are kept, the file must still load, and a key NIRUWM does not know is
refused there with the reason. The running session reloads at once, also over SSH.
A key that starts with `screensaver.` goes to `~/.config/niruui/screensaver.toml`
through `niruscreensaver --set`. A key that starts with `lock.` is a top-level key
of `~/.config/niruui/lock.toml` (`lock.layout`, `lock.visual`, `lock.show_hostname`):
it is replaced or added above the first `[table]`, and when NIRULOCK then complains
about the file, the old file comes back and the host reports the reason.

A machine that is offline gets the setting later. It is kept in
`~/.local/share/nirux/fleet-pending` on this machine and sent when this machine
next runs a `nirux fleet` command, logs in or wakes from sleep while the other one
is online (the login and wake-up delivery is logged to
`~/.local/share/nirux/fleet-pending.log`). A newer value for the same key replaces
the waiting one. `nirux fleet status` says when something is waiting.

The value is read as TOML when it can be (`5`, `true`, `["a", "b"]`) and as text
otherwise, so `nirux fleet set theme niru-nord` needs no quotes. On one machine,
`niructl config set KEY VALUE` does the same, and `niructl config get KEY` shows
the current value.

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

**What it checks:** disk use of `/`, `/home`, `/boot`, the EFI partition and mounted data disks (a warning at 85 %), inodes, SMART and NVMe health (wear, media errors, bad sectors), failed services, whether a reboot is needed for a new kernel, waiting package updates (security updates are a warning), whether NIRUX is behind the latest release, the age of the newest `nirux snapshot`, out-of-memory kills and errors in the log this week, time sync, Tailscale, the firewall, battery health and whether the addresses of your web apps still answer (a site that turns scripts away counts; one that is gone, answers 404 or now leads to another site is a warning; `nirux webapps check` shows them one by one).

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
when **nobody is using the computer**. A desktop session left **locked** counts
as away (the lock screen is up: NIRULOCK runs, or logind's locked hint), so a
computer that stays logged in overnight is still updated. An unlocked desktop,
an SSH login or a text console login makes it wait; the login screen does not
count. Without `loginctl`, anyone in `who` makes it wait. On battery it waits for the charger
or at least 50 %. A computer that is off at night simply updates the next night.
It never restarts the computer and never touches a running session: it does
not log you out or restart the window manager, so new NIRUWM programs start
with your next login or `niructl restart-wm`, and Helium uses a new version
after you restart it. `nirux autoupdate` shows whether the computer counts as
in use right now.

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

**A computer that sleeps at night.** A laptop that is asleep or off between
03:00 and 05:00 misses the nightly update, every night. At login and after a
wake-up NIRUX checks for a newer release (at most every six hours) and for
selected extras that are behind their pins. When the same thing has been waiting
for more than 30 hours, a notice says so once, with **Update now**, which runs
the nightly update straight away (`nirux autoupdate run-now`), while you keep
working. `nirux update-check` shows the same answer in a terminal.

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
