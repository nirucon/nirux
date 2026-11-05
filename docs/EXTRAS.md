# Optional suite extras

NIRUX keeps its core manifest small. Applications in this document are optional
suite members: they are maintained in their own repositories, installed only on
explicit request, and never pulled in by a core `nirux update`.

| Extra | Release | Role |
|---|---|---|
| niruorg | 0.6.0 | File and folder management |
| nirunote | 0.6.0 | Markdown editor |
| nirupres | 2.2.0 | Presentation studio |
| nplay | 1.8.0 | Terminal music, radio and podcast player; standalone |
| niruamp | 0.4.0 | Graphical frontend for NPLAY with themed fullscreen visual mode; requires NPLAY 1.7.3+, 1.8.0 for the visualization stream |
| niruflow | 0.6.0 | Local maintenance and automation |
| nirusec | 0.2.0 | Firewall, ports, updates, firmware and security overview GUI |
| nirugame | 0.1.4 | Steam, RetroArch, native games and optional user-supplied SID music |
| niruremote | 0.2.0 | Graphical remote desktop over Tailscale and SSH (no open port); Linux/X11 host, Windows/macOS clients |

## Commands

```sh
nirux extras list
nirux extras select niruflow
nirux extras install niruflow
nirux extras update
nirux extras unselect niruflow
```

`select` records a preference in
`~/.local/state/nirux/extras-selected` without installing anything. Use
`nirux extras status` to see pinned, installed and selected versions. NIRUBAR's
suite-update module intentionally tracks the core generation only; it does not
poll each extra's GitHub repository. `install`
downloads the pinned source tag, verifies its SHA-256 before extraction, and
runs that project's own installer. `update` updates only selected extras to the
versions pinned by the installed NIRUX release.

Vendor installers can ask for sudo and may install runtime packages; review their
output. NIRUX never deletes an extra's user data as part of unselecting it. Use
the project's own uninstaller when one is available.

NIRUAMP depends on NPLAY and is a frontend only. `nirux extras install niruamp`
installs or updates the pinned NPLAY release first. NPLAY remains usable alone
and NIRUAMP cannot run without it. The dependency is enforced by the NIRUX extras
installer and by NIRUAMP's own installer check.

## Why outside the manifest

The core manifest is reserved for components that form the NIRUX desktop and
whose releases are verified as one coherent set. Extras have independent release
cadences and larger optional dependency trees. Keeping them in a separate table
lets NIRUX present them as suite members without making every desktop install
carry an editor, a presentation application or a media player.
