# 0.10.53 — P3 multi-display status

Date: 2026-10-21. P3 remains in progress.

## Display module

NIRUBAR 0.18.21 adds an optional `display` module:

- samples `xrandr --query` at most every five seconds through the bounded probe
  runner;
- stays hidden with one connected display, so a laptop bar is not cluttered;
- shows an icon and count when two or more displays are connected;
- its panel lists output name, current resolution and which output is primary.

`display` is in the default module list and the shared example config. Existing
user configs keep their current module list; add `"display"` to
`[bar] modules` to opt in. A missing `xrandr` or failed probe hides the text and
explains the missing state in the panel instead of failing the bar.

## Verification

- NIRUBAR 0.18.21: fmt, clippy and all unit tests passed. A parser test covers a
  primary laptop output, a secondary HDMI output and a disconnected output.
- The example-config validation test now accepts the documented `display`
  module.
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- Follow-up test-only commit: `tests/theme-colors.sh` samples the actual bar
  background for Noir, Nord, Satie, Carl Larsson and a custom theme. All five
  matched the theme file (`0f0f10`, `2e3440`, `141414`, `f3ece0`, `212121`).
  NIRUBAR CI and release now run this check, together with the existing
  800/1366/1920 render matrix. NIRUBAR CI run 39567976680 passed after also
  installing `xprop` for the test and narrowing its fake `playerctl` script to
  count only real playback actions.

Additional rendered-value coverage:

- NIRULAUNCHER `tests/theme-colors.sh` samples a real X11 window for all four
  built-in themes. Background and 3 px focus accents matched
  (`0f0f10`/`5a5a60`, `2e3440`/`88c0d0`, `141414`/`b08d7d`,
  `f3ece0`/`a63d2f`). CI run 39573277282 passed.
- NIRUNOTIFY's UI smoke now checks a real notification window for the theme
  error strip `d77a7a` and surface `202021`. CI run 39573363779 passed.
- NIRUBAR continues to verify all four themes plus a custom theme and the
  800/1366/1920 render matrix; CI run 39567976680 passed.

P3 still needs rendered-value assertions for greeters and lock, plus the
complete small-screen/hotplug matrix. P2 remains partial for owner-present
tests.

## Release and deployment evidence

NIRUBAR v0.18.21 is published and NIRUX 0.10.53 pins it. NIRUX CI run
39562979674 passed check, Arch, Debian and Void; v0.10.53 was published and
deployed to both hosts. They now run NIRUX 0.10.53 / NIRUBAR 0.18.21 /
NIRUWM 0.16.50 / NIRULAUNCHER 0.2.5.

Both hosts have one connected display, so the new module stays hidden until a
second output is connected or `"display"` is added to `[bar] modules` and the
session is restarted. The parser and panel are covered by unit tests. No session
was forced to log out.
