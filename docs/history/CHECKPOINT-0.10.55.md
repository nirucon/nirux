# 0.10.55 — P5 “Why is this unavailable?” diagnostics

Date: 2026-10-21. P5 implemented; the owner has deferred the test matrix.

## What changed

NIRUWM 0.16.52 adds `niructl explain [--launcher]`. It is read-only and checks:

- running NIRUWM versus the installed binary, with a log-out/in hint;
- native NIRUNOTIFY or Dunst ownership;
- default audio output and WirePlumber availability;
- backlight device;
- NIRU lock-before-suspend inhibitor;
- connected RandR outputs;
- whether weather coordinates are still the unset `0,0` pair.

Human output is grouped by level and name. The `--launcher` form emits
tab-separated rows for the action launcher. It performs no HTTP request, asks for
no privilege and changes no setting.

NIRULAUNCHER 0.2.6 adds those rows to a **Diagnostics** group. A relevant action
opens `nirux doctor`, `niructl audio outputs`, DND or reload as appropriate;
informational rows are inert. A fixed “Run diagnostics” action opens the full
`nirux doctor` report.

## Verification

- NIRUWM 0.16.52 and NIRULAUNCHER 0.2.6: fmt, clippy, unit tests and the X11
  launcher smoke test passed.
- Manual isolated X test: `niructl explain` produced human and launcher rows for
  missing notifier, audio, backlight, sleep protection and weather without
  failing.
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- Deferred by owner: injected-provider/permission/stale-state tests and the
  remaining P3/P4 test matrices. P2 remains partial for owner-present hardware
  checks.

## Release and deployment evidence

NIRUWM v0.16.52 and NIRULAUNCHER v0.2.6 are published. NIRUX CI run
39579534088 passed check, Arch, Debian and Void; v0.10.55 was released and
deployed to both hosts. They now run NIRUX 0.10.55 / NIRUWM 0.16.52 /
NIRULAUNCHER 0.2.6.

Live `niructl explain --launcher` on both hosts reported only one warning:
the running session was NIRUWM 0.16.40 while 0.16.52 is installed, with the
explicit “log out/in to activate” cause and a `doctor` action. Notifications,
audio, display, sleep protection and weather produced no warnings. The launcher
Diagnostics group will show the same row after logout/login.
