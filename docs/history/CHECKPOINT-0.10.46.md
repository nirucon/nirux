# 0.10.46 — P1 notifications, stacking and provider-aware DND

Date: 2026-10-21. First item in the active P1–P6 queue.

## Notification stacking

Popup windows are override-redirect and do not take keyboard focus. They now:

- publish `_NET_WM_WINDOW_TYPE_NOTIFICATION` and `_NET_WM_STATE_ABOVE`;
- map and restack with `StackMode::ABOVE`;
- select `VisibilityChangeMask` and re-raise themselves when another window
  covers them, throttled to avoid an event loop.

This addresses the reported case where a notification remained underneath a
terminal. It keeps lock-screen hiding and click actions unchanged.

## Font-aware popup sizing

Wrapping and height previously assumed an 8 px character cell and a 20 px line.
NIRUNOTIFY 0.3.7 measures the configured font before creating the popup, wraps
with the same advance used for drawing, and derives the line step from the real
font height. Large fonts and narrow widths therefore size correctly instead of
clipping text or leaving excessive empty space.

## One DND path

`niructl dnd on|off|toggle|status` now tries the running native NIRUNOTIFY
socket first and falls back to `dunstctl` only when no native daemon answers.
The launcher and NIRUWM keybinding already call `niructl`, so they now follow
the active provider. NIRUBAR’s notification popup hint points at the same
command instead of a native-only invocation.

## Verification

- NIRUNOTIFY 0.3.7: fmt, clippy, unit tests, and the D-Bus/X11 UI smoke test
  passed. The smoke test covers actions, replacement, DND state, expiry,
  lock privacy, OSD and live theme reload.
- New stacking regression covers a real covering window: the popup is raised
  above it after the cover is mapped and raised. A manual NIRUWM + Xvfb + xterm
  check also kept the popup above an activated terminal.
- NIRUWM 0.16.43 unit tests cover native-provider preference and Dunst fallback
  for DND. The startx smoke test toggles DND against the running native notifier.
- NIRUBAR 0.18.19 unit tests passed.
- NIRUX integration and real-release startx smoke passed on Arch, Debian and
  Void before release.

Remaining P1 notes: bounded duplicate-message grouping was not added; visible
and history limits still bound repeated notifications. Fullscreen and physical
lock-screen interaction remain part of the P2 hardware/session verification.

CI, release and host deployment evidence is added after publication.
