# 0.10.65 — N5 nirushot polish

Date: 2026-10-21

## Delivered

- NIRUSHOT 0.3.0 review window has a themed toolbar and typography.
- Palettes match NIRUWM's Niru Noir, Nord, Satie and Carl Larsson themes; the
  configured `font_path` or fontconfig monospace is used.
- Pointer and keyboard mode selection: Crop, Rect, Arrow, Mask.
- Save notification offers Open, Copy and Show in folder when `notify-send`
  supports actions; a plain notification is used otherwise.
- NIRUX pins NIRUSHOT 0.3.0. Super+Print, Print and Super+Shift+Print continue
  to route through nirushot.

## Evidence

- NIRUSHOT: fmt, clippy, unit target, CLI smoke.
- Xvfb visual review: toolbar, active mode, image fit and 900x560 capture.
- Xvfb crop: 200x100 capture exported as 100x50.
- Xvfb annotations: red rectangle, opaque black mask and red arrow verified in
  the exported PNG.
- Notification-helper test: Show in folder invoked the expected directory.
- NIRUWM 0.16.59 tests and clippy remain green.
- NIRUX integration passed; CI passed on Arch, Debian and Void with the real
  pinned releases.
- NIRUX v0.10.65 was published and deployed to ThinkPad and Void. Both report
  NIRUX 0.10.65, NIRUWM 0.16.59 and NIRUSHOT 0.3.0.
- A real full-screen direct save on both hosts produced a valid 1920x1080 RGBA
  PNG in a temporary directory; the test file was removed.

## Limits

- Physical multi-output geometry and the new shortcuts need a new graphical
  session; no session was forced to log out. Automated XTest key injection did
  not reach windows in the running real session, so interaction evidence comes
  from the isolated Xvfb tests.
- Notification actions depend on the installed `notify-send`; the plain
  notification fallback is intentional.
