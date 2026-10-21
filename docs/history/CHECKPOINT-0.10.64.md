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
- NIRUX integration passed; CI passed on Arch, Debian and Void with the real
  pinned releases.
- NIRUX v0.10.64 was published and deployed to ThinkPad and Void. Both report
  NIRUX 0.10.64, NIRUWM 0.16.59 and NIRUSHOT 0.2.0.
- A real full-screen direct save on both hosts produced a valid 1920x1080 RGBA
  PNG in a temporary directory; the test file was removed.
- No session was forced to log out, so the new NIRUWM shortcut bindings become
  active on the next login. Automated key injection in the running real session
  did not reach the review window; the Xvfb review test remains the interaction
  evidence.

## Limits

- Notification actions Open/Copy/Show in folder are not implemented yet.
- The review window uses the WM title for instructions; an in-window themed
  toolbar and typography pass remain.
- Real multi-output geometry and shortcut behaviour need verification after the
  next login; no session was forced to log out.
- The review window is 90% of the root geometry and does not yet do per-output
  placement.
