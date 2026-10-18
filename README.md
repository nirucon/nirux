# NIRUX

Install and maintain the NIRU X11 desktop on **Void Linux (glibc), Arch Linux
and Debian**, including a minimal OS installation without a graphical desktop.
Released binaries currently target x86_64 with glibc. Void musl and other CPU
architectures are detected before installation and are not supported by these
binary releases.

The suite consists of [niruwm](https://github.com/nirucon/niruwm) (window manager,
session, `niructl`, `niruidle`), [nirubar](https://github.com/nirucon/nirubar),
[niruscreensaver](https://github.com/nirucon/niruscreensaver), and
[nirulock](https://github.com/nirucon/nirulock).

A personal hobby project. Early software, used at your own risk.

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
fonts, kitty, rofi, audio tools, notifications and the other default session
dependencies. It does not depend on NIRUPI. Distribution graphics drivers and
firmware remain the OS/hardware installation's responsibility.

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

```sh
nirux update
nirux update --release 0.5.0
nirux rollback
```

Each NIRUX release contains `nirux`, a version manifest, and `SHA256SUMS`.
The manifest pins every component. The session script is a checksummed asset of
the same release as the WM; PAM templates are assets of the lock release.
No installed session is downloaded from a moving main branch.

An update fetches the newest NIRUX release (or the requested version), including
the installer itself. All component files are downloaded and verified before
activation. Missing shared libraries and wrong binary versions fail before
switching programs. Operations on the same prefix are locked.

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

## Diagnostics

```sh
nirux status
nirux doctor
```

`status` checks program execution, system integration, PAM include files and
permissions, returning a failure status when required parts are missing.
It never launches the session script to discover its version.

`doctor` also checks the required launch tools and component settings. With
`DISPLAY` set it checks the live control channel and WM/bar processes; from
SSH or a TTY it reports that the live-session check was skipped. Reading PAM
configuration does not prove that a user's password can authenticate.

## Uninstall

```sh
nirux uninstall
nirux uninstall --purge
```

Only NIRUX-owned links, generated xinitrc and owned system integration are
removed. Existing backed-up system files are restored. `--purge` also removes
the NIRU config/state directories. OS packages, the chosen display manager,
and NIRUPI are retained. Log out to end already running programs.

`NIRUX_PREFIX` changes the install prefix (default `$HOME/.local`); XDG config
and state directories are respected. Use the same prefix for future commands.

## Tests

```sh
sh tests/integration.sh
```

Offline regression tests use isolated homes and mock release downloads. They
exercise all three distribution mappings, generation switches, rollback,
checksum failures, status purity, PAM includes and uninstall/purge. CI also
installs the real vanilla dependency package lists on all three distributions
and checks that both optional display managers exist in their repositories.
`sh tests/release-smoke.sh` tests the actual pinned component releases, diagnostics,
startx/xinit with the generated xinitrc, bar restart and uninstall in an isolated
home (requires the dependencies and Xvfb). Component repositories additionally
test bar crash recovery, logout cleanup and real non-root PAM authentication.
A physical local-TTY/GPU startx boot is separate from container/Xvfb testing.

MIT. Copyright 2026 Nicklas Rudolfsson.
