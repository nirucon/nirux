# 0.10.54 — P4 reliable workspace autostart

Date: 2026-10-21. P4 implemented; the owner has deferred the edge-case test
matrix.

## What changed

NIRUWM 0.16.51 adds standard EWMH `_NET_WM_DESKTOP` ClientMessage handling for a
specific window, without changing focus. `niructl autostart` uses it:

- optional `class = "..."` on `[[autostart.apps]]`, matched case-insensitively
  against WM_CLASS instance/class;
- with `class`, wait up to `window_timeout_ms` (default 5000) for a new matching
  window, then move it to the configured workspace;
- without `class`, keep the legacy 250 ms spacing and do not wait, so scripts
  and single-instance entries are not delayed;
- abort the remaining sequence if the user switches workspace, and never move
  the user back afterwards;
- keep saved-session precedence and the existing return-to-workspace rule.

The shared examples document `window_timeout_ms` and `class`. Missing values use
the previous behaviour.

## Verification

- NIRUWM 0.16.51: fmt, clippy and all unit tests passed.
- Manual real-X test: a window that slept one second before mapping was placed
  on workspace 2, `_NET_WM_DESKTOP=1`, and the sequence returned to workspace 1
  (`_NET_CURRENT_DESKTOP=0`).
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- Deferred by owner: slow/missing/single-instance/multiple-window automated
  matrix and the remaining P3 greeter/lock/hotplug pixel tests.
- P2 remains partial for owner-present lock/suspend/audio/power/external-display
  checks.

## Release and deployment evidence

NIRUWM v0.16.51 is published; NIRUX 0.10.54 pins it. CI, release and host
deployment results are added after publication.
