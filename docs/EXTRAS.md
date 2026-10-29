# Optional suite extras

NIRUX keeps its core manifest small. Applications in this document are optional
suite members: they are maintained in their own repositories, installed only on
explicit request, and never pulled in by a core `nirux update`.

| Extra | Release | Role |
|---|---|---|
| niruorg | 0.5.1 | File and folder management |
| nirunote | 0.5.0 | Markdown editor |
| nirupres | 2.1.4 | Presentation studio |
| nplay | 1.6.0 | Terminal music, radio and podcast player |
| niruflow | 0.5.0 | Local maintenance and automation |

## Commands

```sh
nirux extras list
nirux extras select niruflow
nirux extras install niruflow
nirux extras update
nirux extras unselect niruflow
```

`select` records a preference in
`~/.local/state/nirux/extras-selected` without installing anything. `install`
downloads the pinned source tag, verifies its SHA-256 before extraction, and
runs that project's own installer. `update` updates only selected extras to the
versions pinned by the installed NIRUX release.

Vendor installers can ask for sudo and may install runtime packages; review their
output. NIRUX never deletes an extra's user data as part of unselecting it. Use
the project's own uninstaller when one is available.

## Why outside the manifest

The core manifest is reserved for components that form the NIRUX desktop and
whose releases are verified as one coherent set. Extras have independent release
cadences and larger optional dependency trees. Keeping them in a separate table
lets NIRUX present them as suite members without making every desktop install
carry an editor, a presentation application or a media player.
