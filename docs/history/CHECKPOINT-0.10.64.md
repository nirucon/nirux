# 0.10.64 — N5 nirushot review surface

Date: 2026-10-21

## Delivered

- NIRUSHOT 0.2.0 adds an on-demand X11 review window after capture.
- Review operations: crop, red rectangle, red arrow and opaque black mask.
- `s`/Enter saves to `~/Pictures/Screenshot-YYYY-MM-DD_HH-MM-SS.png` and copies
  the result to the clipboard. `y` copies without saving. Escape keeps no file.
- Default `nirushot --region|--window|--full` opens review; `--copy` and
  `--save PATH` remain direct-output paths.
- NIRUWM 0.16.59 binds Super+Print to full-screen review, Print to region
  review and Super+Shift+Print to active-window review.
- NIRUX pins NIRUSHOT 0.2.0 and NIRUWM 0.16.59; xclip, maim and slop remain
  provisioned dependencies.

## Evidence

- NIRUSHOT: fmt, clippy, unit target and fake-provider CLI smoke passed.
- Xvfb review test saved a valid PNG at the default `~/Pictures` path.
- Xvfb crop test reduced a 200x100 capture to a 100x50 PNG.
- NIRUWM: fmt, 70 tests and clippy passed.
- NIRUX integration and release-smoke are recorded after publication.

## Limits

- Notification actions Open/Copy/Show in folder are not implemented yet.
- The review window uses the WM title for instructions; an in-window themed
  toolbar and typography pass remain.
- Real multi-output geometry and shortcut behaviour need verification in a new
  graphical session; no session was forced to log out.
