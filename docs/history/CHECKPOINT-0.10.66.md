# 0.10.66 — nirushot works under NIRUWM

Date: 2026-10-21

## Defects found on Void

- The review window was tiled by NIRUWM and the content stayed at the tile's
  top-left because no dialog type was advertised and `ConfigureNotify` was
  ignored.
- Input did not reach the review surface reliably: focus was requested before
  the window was viewable, and there was no keyboard or pointer grab.
- `s` appeared to do nothing even though the PNG was written. `xclip` inherited
  the capture pipe; waiting for its output blocked nirushot after the save.

## Fixes in NIRUSHOT 0.4.0

- Advertise `_NET_WM_WINDOW_TYPE_DIALOG`; NIRUWM now floats and centres the
  review window instead of tiling it.
- Handle `ConfigureNotify` so the drawing follows the actual client size.
- Grab the keyboard and pointer only while the dialog is open, focus on
  `MapNotify`, and release both on save, cancel, close button or Escape.
- Support `WM_DELETE_WINDOW`, including temporary-file cleanup.
- Spawn `xclip` with the PNG on stdin and do not wait for its background
  selection owner. This removes the post-save freeze.
- Add wheel/`+`/`-` zoom, `0` fit, `v` view mode, drag/middle-drag pan and a
  live zoom label. Draw the toolbar last so a panned image cannot cover it.
- Add collision-safe `Screenshot-…-2.png` names and only claim "copied" when
  `xclip` started successfully.

## Evidence

- Real NIRUWM in Xvfb: review window was a centred 896x608 floating dialog,
  not a tile.
- Toolbar click selected Crop; drag exported 100x50 from a 900x560 capture.
- `m` selected Mask, `s` saved a 900x560 PNG and exited without hanging.
- CLI smoke, fmt and clippy passed.
- NIRUX integration passed; CI passed on Arch, Debian and Void with the real
  pinned releases.
- NIRUX v0.10.66 was published and deployed to ThinkPad and Void. Both report
  NIRUX 0.10.66 / NIRUSHOT 0.4.0.
- Real Void session on the 1920x1080 display: the review window appeared
  centred at 200,86 as a 1516x903 floating dialog. A toolbar click selected
  Crop; a drag followed by `s` saved a 100x49 PNG and exited cleanly. The test
  PNG was removed afterwards.

## Limits

- Physical multi-output still needs the owner's manual check. No session was
  forced to log out; the actual single-output Void session passed.
