# R01 performance and resource baseline — 0.10.35

Recorded **2026-10-20** from the owner's request to verify that the desktop feels
fast and does not waste memory. This is a baseline, not a claim that every
optimization is finished.

## Method

- Container sessions: the isolated normal-user S04 installs on Arch, Debian and
  Void. Startx-to-bar latency was polled at 20 ms. After five idle seconds,
  `Pss` was summed from `/proc/<pid>/smaps_rollup` for the UI processes
  (`niruwm`, `nirubar`, `niruidle`, `nirunotify`, `niruwm-session`).
- Owner hosts: the already-running sessions on `niru@void` and
  `niru@thinkpad`, measured without logging out. Audio and browser processes
  are reported separately.
- No browser was launched for the container measurements.

## Results

| Metric | Arch container | Debian container | Void container |
|---|---|---|---|
| startx → bar visible | 170 ms | 105 ms | 205 ms |
| UI PSS idle | 12.4 MB | 8.2 MB | 10.7 MB |
| UI processes (live) | 6 | 6 | 6 |
| Helium running when not launched | no | no | no |

Owner hosts, active sessions:

| Metric | niru@void | niru@thinkpad |
|---|---|---|
| UI PSS (niruwm/bar/idle/notify/session) | ~12.8 MB | ~13.5 MB |
| UI + session bus + PipeWire/WirePlumber PSS | ~42.8 MB | ~32.3 MB |
| Idle CPU per UI component | ≤ 0.4% | ≤ 0.3% |
| Helium processes | 13 (browser was open) | 0 |
| All user processes | 63 (includes browser) | 25 |

The Void session had several old `dbus-daemon`/at-spi buses from earlier
sessions. The current-session bus is separate. Stale session-bus cleanup belongs
to C07; it is not caused by the 0.10.35 binary measurement itself.

## Budgets

These are the working budgets for R01:

- Idle UI core PSS (WM, bar, idle daemon, notifier, session shells) **≤ 25 MB**.
  Baseline is 8–14 MB.
- Idle UI CPU **≤ 2% total**, averaged over 30 seconds. Baseline is well below
  0.5% per component.
- **≤ 8 live UI processes** per user session. No duplicate bar, notifier or idle
  ladder.
- startx → bar visible **≤ 2 s** on supported container/VM hardware; physical
  login-to-usable-session target **≤ 5 s** to be measured in H01.
- Helium/Chromium processes are excluded from the idle-core budget and must be
  absent unless the user launched the browser.
- Bar redraw stays at its 1 Hz cadence; no idle busy loop or network poll while
  nothing changes.
- Audio processes are reported separately; PipeWire/WirePlumber memory is
  expected to be larger than the UI core.

## Remaining work

- Repeat measurements on fresh physical/VM installs in H01.
- Add an automated resource smoke test that fails on a clear regression once CI
  can provide stable measurements.
- Investigate stale session buses under C07; do not kill active sessions.
- Optimize only measured hot paths. The current baseline does not justify
  speculative micro-optimization of the UI core.
