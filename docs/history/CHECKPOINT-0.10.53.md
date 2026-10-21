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
- P3 still needs rendered-value assertions across themes and the explicit
  small-screen/hotplug matrix. P2 remains partial for owner-present tests.

## Release and deployment evidence

NIRUBAR v0.18.21 is published and NIRUX 0.10.53 pins it. CI, release and
both-host deployment results are added after publication.
