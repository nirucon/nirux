# 0.10.56 — P6 work modes and workspace recipes

Date: 2026-10-21. Final feature milestone in the active queue. Tests remain
deferred by the owner.

## Work modes

`niructl mode focus|presentation|stop|status [MINUTES]`:

- focus defaults to 25 minutes, presentation to 60;
- enables DND and idle/DPMS inhibition, but only owns what it changed;
- a state file records the expiry, a unique token, the initial DND state and
  the idle expiry the mode wrote;
- a short-lived helper restores the mode at expiry; a stopped or restarted mode
  invalidates the old token;
- session cleanup calls `niructl mode stop --quiet`, so a timer from a previous
  login cannot change the next one;
- a new NIRUBAR `mode` module reads the state and shows a live countdown; it is
  hidden when no mode is active.

## Workspace recipes

The shared config accepts `[[recipes]]` with `name` and `[[recipes.apps]]`
using the same `workspace`, optional `class` and `command` fields as autostart.
`niructl recipe list|run NAME` reuses the P4 window-matching/move engine and
returns to the workspace the recipe was started from. User workspace changes
abort the sequence.

NIRULAUNCHER 0.2.7 lists recipes under **Recipes** and work modes under
**Work modes**, so both are available from Super+Shift+P without a new daemon.

## Verification

- NIRUWM 0.16.53, NIRUBAR 0.18.22 and NIRULAUNCHER 0.2.7: fmt, clippy, unit
  tests and the X11 launcher smoke test passed.
- Manual mode test with a fake notification provider: focus mode set DND on,
  wrote idle inhibition, reported one minute remaining, and stop restored DND to
  off and removed the idle state.
- Manual recipe test: a delayed xmessage mapped on workspace 2, `_NET_WM_DESKTOP`
  became 1, and the sequence returned to workspace 1.
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- Deferred by owner: timeout/expiry, manual-override, repeated-mode, recipe
  failure and the remaining P2/P3/P4/P5 test matrices. P2 remains partial for
  owner-present hardware checks.

## Release and deployment evidence

NIRUWM v0.16.53, NIRUBAR v0.18.22 and NIRULAUNCHER v0.2.7 are published.
NIRUX CI run 39586727800 passed check, Arch, Debian and Void; v0.10.56 was
released and deployed to both hosts. They now run NIRUX 0.10.56 / NIRUWM
0.16.53 / NIRUBAR 0.18.22 / NIRULAUNCHER 0.2.7. `niructl mode status`
reports `mode off` and `niructl recipe list` runs cleanly. The running session
still uses the older WM/launcher, so the launcher entries and bar countdown
activate after logout/login. No session was forced to log out.
