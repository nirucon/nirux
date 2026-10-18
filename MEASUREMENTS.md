# M1 resource checkpoint

Measured in a disposable Debian 12 container, Xvfb, DejaVu Sans Mono, Rust
1.99.1, x86_64. Both before/after binaries in the table are static musl builds;
the before binaries are the published nirubar 0.16.4 and niruscreensaver 0.7.0.
100 CPU ticks/second. These are reproducible fixture observations, not promises
about physical laptop power use or a representative benchmark suite.

## Bar: ten seconds of scrolling

`nirubar/tests/resource-check.sh ABSOLUTE_BINARY [baseline]` creates a private
1280x80 X server, fixed volume and playing long-title helpers, and counts tool
calls after one second of startup. Only volume/media/clock modules are enabled.
No real audio server or player is involved. Five playerctl calls form one sample.

| Observation | Before | M1 / 0.16.5 |
|---|---:|---:|
| playerctl calls / 10 seconds | 2535 | 50 |
| wpctl calls / 10 seconds | 507 | 10 |
| Bar threads | 2 | 1 |
| Bar CPU ticks / 10 seconds | 22 | 2 |
| Snapshot RSS (KiB) | 1800 | 1728 |

About 98% fewer helper calls in this sample. Counts and CPU vary with machine
load and timing. Sampling remains synchronous in M1; bounded background probes
are still M3 work. CPU ticks are for the bar itself, not cumulative child CPU.
Short titles no longer request animation ticks just for playback progress.

## Screensaver: repeated exposure

`niruscreensaver/tests/resource-check.sh ABSOLUTE_BINARY [baseline]` creates an
800x600 private X server and sends five xrefresh exposures. It also checks that
a key dismisses the saver after those redraws.

| Observation | Before | M1 / 0.8.0 |
|---|---:|---:|
| Font discoveries | 7 | 1 |
| Snapshot RSS (KiB) | 900 | 1380 |

Retaining both glyph caches trades about 0.5 MiB in this snapshot for avoiding
repeated font loading/rasterizer setup; the renderers share font bytes. This is a deliberate bounded cache, not
a memory-reduction claim. Scheduling tests cover clock-minute, away-threshold
and away-minute deadlines; the loop drains X events before blocking.

## Correctness checks

- Locker: actual non-root PAM accepted the fixture password, refused a wrong
  password and Escape. A separate isolated X test sets both legacy timeout
  inputs, waits past their former deadlines, and verifies that a focused desktop
  spy receives no lock typing, including after a rejected attempt. Legacy keycode
  logs are scrubbed. Another regression holds the keyboard in a fixture client
  and verifies that failed grab acquisition never maps a password surface. This
  failed against 0.16.4 and passes in 0.16.5. Actual WM shortcuts were also checked:
  Super+2 cannot switch tags while locked and works after authenticated unlock.
  These tests do not claim protection against hostile X clients.
- Idle daemon: termination/reaping and completed-child status tests use actual
  child processes; there is no PID-zero sentinel or timeout wrapper.
- Bar: an X image regression verifies progress-only changes with a short paused
  title. Probe-cache tests include cached failure and expiry.

Further workloads (many clients/monitors, package-query stalls, network failures,
notification floods and suspend/resume) remain explicitly scheduled in ROADMAP.md.

## Other idle snapshots

Same container, separate 800x600 private X server, one-second warmup followed by
ten idle seconds. WM bar disabled to isolate the WM process; idle ladder uses its
15-minute defaults; locker receives no input. CPU ticks are fields 14+15 of
`/proc/PID/stat`; RSS and threads come from `/proc/PID/status`.

| Program | Format | CPU ticks / 10 seconds | RSS KiB | Threads |
|---|---|---:|---:|---:|
| niruwm 0.16.4 | static musl | 0 | 1384 | 1 |
| niruidle 0.16.4 | static musl | 0 | 696 | 1 |
| nirulock 0.16.5 | dynamic glibc/PAM | 0 | 3236 | 1 |

These are starting baselines for subsequent work, not before/after improvement
claims. A clock-minute redraw or a different installed font changes the sample.
