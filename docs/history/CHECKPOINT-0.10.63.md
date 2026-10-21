# 0.10.63 — N5 nirushot first delivery

## Released tool

NIRUSHOT 0.1.0 provides region, active-window and full-screen capture with an
optional delay. It uses slop for selection, maim for capture, xprop for the
active window, xclip for the X11 clipboard and notify-send/NIRUNOTIFY for the
completion message.

- Copy is the default; `--save PATH` writes only that path, or combine with
  `--copy`. Cancel creates no file. No daemon, history, upload or background
  process.
- Helper failures are reported; `--delay` and unknown options are validated.
- The CLI fake-provider smoke test covers region geometry, save, clipboard and
  notification, and full-screen copy cleanup.

The native review surface with crop, rectangle/arrow annotation and opaque mask
is the remaining N5 delivery. Existing Super+Print/maim bindings stay as fallback
until that surface is released and verified.

## NIRUX installation and integration

- Manifest pins `nirushot 0.1.0`, and `nirushot` is part of `PROGRAMS`, status,
  generation staging and release verification.
- Dependencies `xclip` are added on Arch, Debian and Void; maim/slop already
  existed. `doctor` lists xclip as an optional runtime tool.
- Release assets and checksum verification include the new repository.
- Integration fixtures and real-release staging include nirushot.
- No new service or daemon is introduced.

## Verification

- NIRUSHOT 0.1.0: fmt, clippy, tests, CLI smoke and release asset published.
- NIRUX integration tests pass with the new manifest/component fixture.
- NIRUX release smoke on Arch, Debian and Void pending before tag.

Owner-present real screenshot/selection, clipboard consumers and multi-output
geometry remain hardware checks. N5 review/annotation is next.

## Release and deployment evidence

NIRUSHOT v0.1.0 and NIRUX v0.10.63 are published. Both ThinkPad and Void run
NIRUX 0.10.63 / NIRUSHOT 0.1.0. `maim`, `slop` and `xclip` are installed, and a
real full-screen capture on each host produced a valid 1920x1080 RGBA PNG in a
temporary directory. The test file was removed afterwards. No session was forced
to log out. Existing Super+Print/maim bindings remain the declared fallback until
the native review/annotation surface is delivered and verified.
