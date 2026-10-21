# 0.10.48 — P3 visual scale, launcher layout and welcome setting

Date: 2026-10-21. First P3 checkpoint. P3 remains in progress.

## Shared scale

`docs/STYLE.md` now records the common rules used across the suite: semantic
colour roles, the 4/8/12/16 px spacing steps, font-aware row and padding sizing,
a 3 px accent focus bar, measured text, monitor clamping and the 800×600 /
1366×768 / 1920×1080 test matrix. Components keep their own drawing code but
share the same roles and measurements.

## Launcher

NIRULAUNCHER 0.2.4 measures the configured font before creating its window:

- row height = `max(configured row_height, font line height + 8)`;
- padding = `max(configured padding, font line height / 2, 8)`;
- selected rows keep the surface fill and gain a 3 px theme-accent left bar;
- header, footer, row hit-testing and drawing all use the same effective
  geometry.

The UI smoke test runs a second launcher at 26 px with `max_rows = 3` and
requires the window to grow beyond the old fixed-row height. It also retains
the existing app launch, singleton and Escape tests.

## Configurable welcome

NIRUWM 0.16.45 reads `WELCOME_NOTIFICATION` from
`~/.config/niruwm/session.conf`:

- `always` (default) — every NIRU session;
- `once` — only until `~/.local/state/niruwm/welcome-shown` exists;
- `off` — never.

Unknown values log a warning and keep the default. The startx smoke test still
asserts the welcome notification in a real session.

## Verification

- NIRULAUNCHER 0.2.4: fmt, clippy, unit tests and the X11 UI smoke test passed,
  including the large-font growth check.
- NIRUWM 0.16.45: fmt, clippy, all unit tests and session shell syntax passed.
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- P2 remains partial for owner-present lock/suspend/audio/power/external-display
  checks. P3 remains open for audio/display controls and rendered-value checks
  across every component.

## Release and deployment evidence

NIRULAUNCHER v0.2.4 and NIRUWM v0.16.45 are published. NIRUX 0.10.48 CI run
39549220456 passed check, Arch, Debian and Void; release v0.10.48 was published.
Both `niru@void` and `niru@thinkpad` now run NIRUX 0.10.48 / NIRUWM 0.16.45 /
NIRULAUNCHER 0.2.4 / NIRUNOTIFY 0.3.7. The running session processes are older,
so the launcher focus bar and welcome setting activate after logout/login. No
session was forced to log out.
