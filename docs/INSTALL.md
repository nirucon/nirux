# Installation and maintenance

**Verified-state note, 2026-10-21:** 0.10.45 implements managed Helium,
theme-follow wallpapers, target-owned apply and the kitty/fish terminal
integration. The full distro CI covers real-release install,
doctor, config contract, startx and a normal-user sandboxed Helium launch.
Containers are supporting evidence, not a fresh physical OS certification.
S03, S04 and H01 remain open; follow [the roadmap](../ROADMAP.md) and the
[restart review](REVIEW-2026-10-20-RESTART.md).

Install and maintain the NIRU X11 desktop on **Void Linux (glibc), Arch Linux
and Debian**, including a minimal OS installation without a graphical desktop.
Released binaries currently target x86_64 with glibc. Void musl and other CPU
architectures are detected before installation and are not supported by these
binary releases.

The suite consists of [niruwm](https://github.com/nirucon/niruwm) (window manager,
session, `niructl`, `niruidle`), [nirubar](https://github.com/nirucon/nirubar),
[niruscreensaver](https://github.com/nirucon/niruscreensaver), and
[nirulock](https://github.com/nirucon/nirulock),
[nirulauncher](https://github.com/nirucon/nirulauncher) and
[nirunotify](https://github.com/nirucon/nirunotify).

A personal hobby project. Early software, used at your own risk.

This is a personal desktop for the author's own use; others are welcome to try it.
The implementation roadmap and continuation checkpoints are in [ROADMAP.md](../ROADMAP.md).
The code review and verified findings are in [AUDIT.md](../AUDIT.md).
Native launcher and notifier releases are included. The notification provider
defaults to `auto`: native when installed, with Dunst fallback. Notification and
OSD colours follow the active NIRUWM theme and update live with `niructl theme`
or `niructl reload`.

## Install

Run as your regular login user, with sudo available for OS packages and system
integration. Root is also supported for provisioning, but binaries and settings
are installed for the user running the command. You need networking and Git to
clone; the full installer installs curl and CA certificates with the OS packages.

```sh
git clone https://github.com/nirucon/nirux
cd nirux
./nirux install
```

On a minimal installation this installs Xorg, xinit/startx, Xauth, D-Bus,
fonts, kitty, rofi, audio tools, notifications, the selected Helium browser and
the other default session dependencies. It does not depend on NIRUPI.
Distribution graphics drivers and firmware remain the OS/hardware installation's
responsibility.

### Theme wallpapers

NIRUX installs the four theme wallpaper sets (Niru Noir, Nord, Satie and Carl
Larsson, 4K and 8K) plus three extra NIRUX wallpapers (Håvamål 19, Rooted in
Less and Space to Think Silhouette, 4K/8K) into
`~/Pictures/Wallpapers/NIRU`. Existing files are kept
unless they are untouched copies from an older NIRUX release; a wallpaper the
user edited is never overwritten. The wallpaper directory can be changed with
`XDG_PICTURES_DIR`, or by setting `[wallpaper] theme_dir`.

The shared configuration adds:

```toml
[wallpaper]
enabled = true                 # fresh installs; existing values are preserved
mode = "random"
rotation_minutes = 10
follow_theme = true            # theme change applies that theme's wallpaper
theme_dir = "~/Pictures/Wallpapers/NIRU"
```

`follow_theme` only acts when the wallpaper is enabled and the mode is not
`single`. Your own directory, rotation, explicit `files`, `file` and
`mode = "single"` keep working. A custom theme `foo` gets its own default from
`theme_dir/nirux-wallpaper-foo-4k.png` (or `-8k.png`). If no matching asset
exists, the current wallpaper is left alone. A normal uninstall keeps the
pictures; `--purge` removes only unmodified NIRUX-owned copies.

The same choices are available graphically: press **Super+Shift+P**, type
`wallpaper`, and pick an image or cycle mode, rotation, scale and follow-theme.
Selecting an image writes `mode = "single"` and applies it immediately through
`niructl`. The config file remains authoritative for advanced settings.

### Mouse and autostart

**Super+left-drag** moves a window; a tiled window becomes floating. **Super+
right-drag** resizes from the nearest corner, and all four corners work.
**Super+Shift+Space** toggles floating and tiling again. Fullscreen windows and
ordinary clicks without Super are untouched.

`[[autostart.apps]]` opens programs in workspace order at login:

```toml
[autostart]
enabled = true
settle_seconds = 2
return_workspace = 1

[[autostart.apps]]
workspace = 1
command = ["kitty"]

[[autostart.apps]]
workspace = 3
command = ["helium"]
```

The sequence waits between programs and after each workspace, then returns to
workspace 1 unless you switched away yourself. Empty `apps` does nothing.
Saved-session restore and `nirupi_compat` suppress it to avoid duplicate
launches. Commands are argv arrays, never shell strings.

### Terminal: kitty, fish and theme colours

A normal install adds **fish** and a NIRU kitty configuration. Kitty always uses
fish inside the terminal; the login shell is not changed. Fish keeps its
persistent history, built-in autosuggestions and completion, and NIRUX adds
completions for `nirux` and `niructl`, a two-line NIRU prompt and a
`nirux-update` helper.

Existing kitty/fish configuration is preserved:

- An existing `kitty.conf` gets one managed block that selects fish and includes
  the generated theme. Other settings stay untouched.
- An existing fish `config.fish` gets one managed block at the end. The NIRUX
  prompt and colours therefore win over an older NIRUPI/starship prompt, while
  aliases and user functions remain.
- A backup `*.nirux-backup` is written before the first modification. Uninstall
  removes only the managed blocks and NIRUX-owned files.

Generated files live in `~/.config/nirux/theme/` and are never hand-edited.
`niructl theme`, a theme change through NIRUWM, and login all regenerate them.
Kitty reloads on `SIGUSR1`; existing fish prompts re-source the colours on the
next prompt. Custom themes use the custom background/foreground plus a light or
dark readable ANSI base.

### Browser

A fresh install offers **Helium**, the managed default, and remembers the answer
in the NIRUX state directory. The installer downloads the official pinned x86_64
archive, verifies its recorded SHA-256, checks its shared libraries and reported
version, then exposes it as `~/.local/bin/helium` with an owned desktop entry.
The browser's own profile and settings are never rewritten.

```sh
./nirux install --browser helium   # managed Helium
./nirux install --browser none     # persistent opt-out; no browser is installed
./nirux update --browser helium    # enable it later
./nirux update --browser none      # opt out and remove NIRUX-owned Helium files
```

An update keeps the recorded policy when no browser flag is given. A browser
already installed outside NIRUX is left untouched. Missing configured or managed
browsers are reported by `status` and `doctor`; they are not silently ignored.
Uninstall removes only NIRUX-owned browser files, never a user profile.

### How the graphical session starts

* If a display manager already exists, it is kept and **NIRUWM** is added to its
  session list.
* Otherwise an interactive install offers **startx (default)**, **SDDM**, or
  **LightDM with the GTK greeter**. A noninteractive install defaults to startx.
* An existing `~/.xinitrc` is preserved. If none exists, NIRUX creates one for
  NIRUWM. From a local TTY you can always select the session explicitly:

```sh
startx "$HOME/.local/bin/niruwm-session"
```

To choose without prompting:

```sh
./nirux install --display-manager startx
./nirux install --display-manager sddm
./nirux install --display-manager lightdm
```

NIRUX will not replace another enabled display manager automatically. Selected
display-manager services are enabled for login (runit on Void, systemd on
Arch/Debian). On Void, missing dbus/elogind service links are also enabled.
The session starts a private D-Bus session when one is not already available.

Selecting **SDDM** installs a NIRUX QML greeter with the Niru Noir palette and
the Rooted in Less wallpaper. Selecting **LightDM** installs a matching GTK
greeter theme and the same background. Both are installed as NIRUX-owned system
files and removed on uninstall; an existing display manager is not restyled.

Log out or reboot when OS/service changes require it; do not run startx over SSH.

### Existing desktop / dependencies already installed

```sh
./nirux install --no-packages
```

This installs all NIRU programs and system integration, without touching the
package manager. `--minimal` is an alias for `--no-packages`, not a partial suite.
PAM dependencies must already be installed. Sudo is requested only when a system
file or package actually needs changing; failures are returned to the caller.

NIRUPI remains a separate session. Existing NIRUPI configuration is preserved.

## Updates and reproducibility

When upgrading from NIRUX 0.4.x or older, first update your original clone
with `git pull --ff-only` and run `./nirux update` from that clone. The old
installer cannot update itself. After that first migration the installed
`nirux update` command also updates NIRUX itself.

```sh
nirux update
nirux update --release 0.10.45
nirux rollback
```

Each NIRUX release contains `nirux`, a version manifest, and `SHA256SUMS`.
The manifest pins every component. The session script is a checksummed asset of
the same release as the WM; PAM templates are assets of the lock release.
No installed session is downloaded from a moving main branch.

An update fetches the newest NIRUX release (or the requested version), including
the installer itself. The verified target installer stages its own component
list through a versioned internal handoff, so a component added by the release
is installed and linked on the first update. Package names are not stable across
releases: the target release's own package list is checked and missing runtime
packages are installed before any staged binary is executed. Use
`nirux update --no-packages` to skip provisioning. Missing shared libraries and
wrong binary versions fail before switching programs; checksum, provisioning or
version failures retain the old generation. Operations on the same prefix are
locked.

Missing-only Arch provisioning uses the current pacman database (`pacman -S`),
without refreshing it into a partial upgrade. If package files have expired on
the mirror, run `sudo pacman -Syu` explicitly, then retry. Initial full installs
already use `pacman -Syu`.

Program generations live in `~/.local/share/nirux/generations`. Stable links in
`~/.local/bin` point through one `current` link, which is switched atomically.
Legacy flat installations are adopted with a snapshot of their existing files.
The previous generation remains available with `nirux rollback`.

Rollback restores program files, not OS packages or PAM configuration. Settings
are not overwritten on update. Existing system integration files are backed up
before adoption, and restored on uninstall if still owned by this installation.

In an updated running WM, `niructl restart-bar` restarts the bar through its
owner and waits for acknowledgement. `niructl reload` reloads configuration.
Older running WMs need a logout/login before they support the restart command.
The WM, idle daemon and session changes always require a new login.

Fresh configuration uses suite-native shortcuts. Existing user overrides are
preserved: if an old config explicitly calls `nirupi-power.sh`, `clip-menu.sh`
or Flameshot, replace that binding with an installed action or remove the
override to restore the built-in default. Use `action = "unbind"` to disable a
default. The canonical `browser` default is the managed `helium` command. Set it to
another installed browser if preferred. Screenshots create `~/Pictures` when
needed.

### Night light and brightness

`[nightlight]` accepts `mode = "manual"`, `"fixed"` or `"solar"`. Manual keeps
the existing Super+N toggle. Fixed uses local `on = "20:00"` / `off = "07:00"`
times; solar computes sunrise and sunset from the configured coordinates with
gammastep, without GeoClue. Fixed and solar start one watcher in the NIRUWM
session. Its current implementation polls saved temperature; actual unchanged-
temperature resume/hotplug reapply and single-watcher ownership remain C02 in
the roadmap. `niructl nightlight apply|watch|status` are the controls.

`[brightness]` selects the brightnessctl `device` (empty means default) and the
percentage `step` used by `niructl brightness up|down` and the hardware keys.
`nirux doctor` reports a present backlight that brightnessctl cannot read, so
missing udev/group permissions are visible rather than silent.

### Appearance contract

The optional `~/.config/niruwm/appearance.toml` (schema 1) is shared by NIRUWM,
NIRUBAR, NIRULAUNCHER, NIRUNOTIFY, NIRULOCK and NIRUSCREENSAVER. It carries
semantic colours, font size/path, spacing, focus width and reduced motion.
A user theme file in `~/.config/niruwm/themes/NAME.toml` takes precedence.
Unreadable, unsupported or invalid appearance files are ignored with a diagnostic;
this is fallback loading, not proof of preserving the last applied live theme.
Colour overrides in the example are optional and commented out, so the selected
NIRU theme owns the palette. NIRUX creates the example on a fresh install and
migrates only the exact old Noir-only default; custom colours are preserved.
Live last-good reload and pixel acceptance remain C01. Lock/saver are intended
to retain an opaque black background.

### Microphone module

Add `"microphone"` to the existing `[bar] modules` list in
`~/.config/niruwm/config.toml`. It is optional; updates preserve your module list.
In the same section set `microphone_visibility = "always"` (the default), or
`"muted"` to hide a healthy unmuted input. A missing input/provider stays visible
to explain the problem. Apply with `niructl reload` after activating the updated
session.

The bar shows mute or input gain; left click shows the selected input and level.
Right click toggles mute, scrolling adjusts gain without unmuting, and middle
click opens keyboard source selection via `nirulauncher --microphone`.
The same controls are in Super+Shift+P. Direct commands:

```sh
niructl audio mic-status
niructl audio mic-mute on    # off or toggle
niructl audio mic-level up  # down or set 65
nirulauncher --microphone
```

Gain is limited to 100% for these controls. Status reports the current provider
value, including values set externally. Recording activity is not monitored;
unmuted is not labelled as actively recording. WirePlumber (`wpctl`) and the
suite's `niructl` are required. Queries run off the bar's X11 thread, with bounded
output/timeouts and a two-second refresh interval.

### Graphical privilege prompts

NIRUX installs a Polkit authentication agent (`polkit-gnome` on Arch/Void,
`policykit-1-gnome` on Debian) and the session starts one if no other agent owns
the role. Reboot/shutdown/logout therefore go through `loginctl`/`systemctl`;
shutdown uses the real `poweroff` verb on both backends. If a power action
fails, `niructl` shows a notification instead of failing silently.

NIRUX also installs a narrow Polkit rule: a **local, active** user in `wheel`
or `sudo` may power off, reboot or suspend without a password. Remote sessions
and other identities still use the normal authentication prompt. The rule is
NIRUX-owned and removed on uninstall.

### Configuration migration

Updates add new default keys and sections to an existing `config.toml` without
rewriting values the user already set. The supported migration subset is:
comments and blank lines, bare or quoted keys, `[tables]`, `[[arrays]]`, and
scalar, string, multiline-string, array and inline-table values.

Dotted keys, duplicate tables or keys, unterminated values and any other
unparseable line stop the migration before the file changes. NIRUX writes a
staged candidate next to the target, checks that it parses with both
`niruwm --check-config` and `nirubar --check-config`, preserves the original
file mode, follows a symlink without replacing it, and only then replaces the
target atomically. If anything is rejected, the original configuration and the
active program generation remain unchanged. Migration uses the existing
`awk`/`sed` toolchain; it does not require Python or a TOML runtime.

## Diagnostics

```sh
nirux status
nirux doctor
```

`status` checks program execution, system integration, PAM include files and
permissions, returning a failure status when required parts are missing.
It never launches the session script to discover its version.

`doctor` also checks the required launch tools and component settings. A
configured terminal, browser or launcher command that is not installed is
reported and fails the diagnostic. `status` separately reports whether the
persistent browser policy is Helium, opted out, or missing its managed files.
With `DISPLAY` set it checks the live control channel and WM/bar processes; from
SSH or a TTY it reports that the live-session check was skipped. Reading PAM
configuration does not prove that a user's password can authenticate.

## Uninstall

```sh
nirux uninstall
nirux uninstall --purge
```

Only NIRUX-owned links, the managed browser files, the generated xinitrc,
generated desktop entry and owned system integration are removed. Existing
backed-up system files are restored. A browser profile and wallpaper pictures
are kept by a normal uninstall. `--purge` additionally removes unmodified
NIRUX-owned theme wallpapers. `--purge` additionally removes only these documented
suite-owned directories:

- `~/.config/niruwm`, `~/.config/niruui`
- `~/.config/nirubar`, `~/.config/nirulauncher`, `~/.config/nirunotify`
- `~/.local/state/niruwm`, `~/.local/state/nirulock`,
  `~/.local/state/niruscreensaver`
- `~/.cache/nirubar`

XDG config/state/cache variables are respected. OS packages, the chosen display
manager, NIRUPI and unrelated files are retained. Log out to end already running
programs.

`NIRUX_PREFIX` changes the install prefix (default `$HOME/.local`); XDG config
and state directories are respected. Use the same prefix for future commands.

## Tests

```sh
sh tests/integration.sh
```

Offline regression tests use isolated homes and mock release downloads. They
exercise all three distribution mappings, generation switches, rollback,
checksum failures, status purity, PAM includes, the local power rule, both
greeter themes, managed-browser policy, theme-wallpaper ownership, terminal
config preservation and uninstall/purge. CI also installs the real vanilla
dependency package lists on all three distributions, runs the real pinned
releases through startx, verifies a theme change replaces the root wallpaper,
and starts Helium as a normal user with the Chromium sandbox enabled. The
browser archive is never started with `--no-sandbox`.
`sh tests/release-smoke.sh` tests the actual pinned component releases, diagnostics,
startx/xinit with the generated xinitrc, bar restart and uninstall in an isolated
home (requires the dependencies and Xvfb). `tests/live-acceptance.sh` is a
read-only check for an already running session: versions, displays, power
authorisation, DND, audio nodes, sleep inhibitor, notification owner and a
resource snapshot. It reports owner-present hardware checks as warnings rather
than claiming them as passed. Component repositories additionally test bar crash
recovery, logout cleanup and real non-root PAM authentication.
A physical local-TTY/GPU startx boot is separate from container/Xvfb testing.

MIT. Copyright 2026 Nicklas Rudolfsson.
