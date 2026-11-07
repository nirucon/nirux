# Optional suite extras

NIRUX keeps its core manifest small. Applications in this document are optional
suite members: they are maintained in their own repositories, installed only on
explicit request, and never pulled in by a core `nirux update`.

| Extra | Release | Role |
|---|---|---|
| niruorg | 0.6.1 | File and folder management |
| nirunote | 0.6.1 | Markdown editor |
| nirupres | 2.2.1 | Presentation studio |
| nplay | 1.8.2 | Terminal music, radio and podcast player; standalone |
| niruamp | 0.5.2 | Graphical frontend for NPLAY with themed fullscreen visual mode; requires NPLAY 1.7.3+ (1.8.0+ recommended for the visualization stream) |
| niruflow | 0.6.1 | Local maintenance and automation |
| nirusec | 0.2.0 | Firewall, ports, updates, firmware and security overview GUI |
| nirugame | 0.1.4 | Steam, RetroArch, native games and optional user-supplied SID music |
| niruremote | 0.2.0 | Graphical remote desktop over Tailscale and SSH (no open port); Linux/X11 host, Windows/macOS clients |
| nirudictate | 0.1.0 | Local speech-to-text dictation: Ctrl+Alt+Space, Swedish (KB-Whisper) by default, English; whisper.cpp on the CPU, nothing leaves the computer |

## Commands

```sh
nirux extras list
nirux extras select niruflow
nirux extras install niruflow
nirux extras update
nirux extras unselect niruflow
nirux extras uninstall niruflow          # the extra's own uninstaller; keeps its data
nirux extras uninstall niruflow --purge  # also its data, where the extra supports it
```

`select` records a preference in
`~/.local/share/nirux/extras-selected` without installing anything. Use
`nirux extras status` to see pinned, installed and selected versions. NIRUBAR's
suite-update module intentionally tracks the core generation only; it does not
poll each extra's GitHub repository. `install`
downloads the pinned source tag, verifies its SHA-256 before extraction, and
runs that project's own installer. `update` updates only selected extras to the
versions pinned by the installed NIRUX release.

Vendor installers can ask for sudo and may install runtime packages; review their
output. In a terminal they ask before installing packages as usual. Without a
terminal (a deployment script, a graphical update) nobody can answer, so NIRUX
sets `NIRUX_ASSUME_YES=1` for the installer: asking NIRUX for the extra is the
consent. When there is no terminal and NIRUX holds no password either, an
extra that needs `sudo` fails at once with a clear message instead of trying
sudo (each failed attempt counts toward `pam_faillock`, and three lock the
account, screen lock included, for ten minutes). NIRUX never deletes an
extra's user data as part of unselecting it.

`uninstall` downloads the same pinned source, runs the extra's own
`uninstall.sh` and unselects it. Every extra keeps its user data on a normal
uninstall; `--purge` is passed on to the uninstallers that support it (NPLAY,
NIRUAMP, NIRUPRES, NIRUFLOW, NIRUREMOTE, NIRUDICTATE). Uninstall extras before
`nirux uninstall`, which removes the `nirux` command itself.

NIRUAMP depends on NPLAY and is a frontend only. `nirux extras install niruamp`
installs or updates the pinned NPLAY release first. NPLAY remains usable alone
and NIRUAMP cannot run without it. The dependency is enforced by the NIRUX extras
installer and by NIRUAMP's own installer check.

NIRUDICTATE starts its background service in the running session when it is
installed (also over SSH, from the session's environment), and the NIRUX
session (NIRUWM 0.17.3+) starts it at every login. Models are downloaded from
its own settings panel (`nirudictate settings`), not by NIRUX. NIRUBAR's
`dictation` module shows a red dot while it records; the `dictation` sound
category belongs to `nirux sounds`.

## Why outside the manifest

The core manifest is reserved for components that form the NIRUX desktop and
whose releases are verified as one coherent set. Extras have independent release
cadences and larger optional dependency trees. Keeping them in a separate table
lets NIRUX present them as suite members without making every desktop install
carry an editor, a presentation application or a media player.
