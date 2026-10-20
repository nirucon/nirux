# Checkpoint 0.10.38 — theme colours in the bar and working power actions

Recorded **2026-10-20** after the owner reported two regressions on the rebooted
ThinkPad: the bar kept Noir colours after a theme change, and Reboot in the
launcher did nothing.

## Bar theme identity

Root cause: `appearance.example.toml` was installed with explicit Noir colour
overrides. NIRUWM and NIRUBAR apply appearance colours over built-in themes when
no user theme file exists, so Noir won for every theme. Wallpaper and kitty
followed the theme name, but the bar/launcher remained Noir. This is the C01
precedence defect already noted in the roadmap.

Fixes:

- The shipped appearance example no longer activates `[colors]`; colour
  overrides are commented optional examples. The selected NIRU theme owns the
  palette.
- NIRUX migrates an existing appearance file only when all twelve colours are
  the exact old Noir defaults. Typography, spacing, focus and custom colour
  values are preserved. A custom appearance override is left untouched.
- Fresh installs therefore show Noir/Nord/Satie/Carl Larsson correctly in the
  bar and other appearance consumers.

Verified in an isolated Xvfb session: bar background changed from Noir
`#0f0f10` (pixel 15,15,16) to Nord `#2e3440` (46,52,64) after `niructl theme
niru-nord`, and changed back to Noir. `nirubar --check-config` already reported
the new theme; the reload path itself was correct.

C01 still has the broader live-reload/last-good and pixel acceptance work, but
the shipped theme-identity bug is fixed.

## Reboot / shutdown

Root cause: no Polkit authentication agent was provisioned or started in the
standalone session. `niructl reboot`/`shutdown` correctly uses `loginctl` /
`systemctl`, and those need Polkit for a normal user's local session. Without an
agent the call fails after the launcher has already closed, so the user sees
nothing.

Fixes:

- NIRUX installs `polkit-gnome` on Arch/Void and `policykit-1-gnome` on Debian.
- `niruwm-session` starts the first available agent once per session, unless a
  graphical session already owns the Polkit agent role, and cleans it up on
  logout.
- `niructl` now sends a critical notification if a suspend/logout/reboot/
  shutdown login action fails, instead of failing silently.

The agent path is optional for standalone NIRUWM; no WM dependency is added.

## Evidence

- `sh tests/integration.sh` covers old-default appearance migration and custom
  appearance preservation.
- Bar colour change was reproduced and verified in a real Xvfb session using
  `xwd` before/after and the bar's own reload log.
- NIRUWM `cargo test`, clippy, fmt and session shell syntax passed.
- Full CI, release and owner-host deployment are recorded after publication.
