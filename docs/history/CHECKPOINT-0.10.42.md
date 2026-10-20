# 0.10.42/0.10.43 — notification colours follow the current theme

Date: 2026-10-20. Owner request: native notification popups and OSD should use
the colours of the active NIRU theme and look right after a live theme change.

## Root cause

NIRUNOTIFY already derived its palette from `theme` in
`~/.config/niruwm/config.toml` at startup, but never re-read it. `niructl theme`
and `niructl reload` updated NIRUWM, NIRUBAR, the terminal hook and the
wallpaper, while the already running notifier kept the old palette. Custom
themes could also keep the default Noir surface because only the five theme
file colours were merged.

## Changes

- NIRUNOTIFY 0.3.4 reads the active theme palette at startup and on live
  changes to `_NIRU_CONFIG_SERIAL` or `_NIRUWM_THEME`.
- Existing notifications and an OSD are rebuilt in place after a visual config
  change, preserving notification ids, actions, order and expiry.
- Reloads that only affect timeouts update future behaviour without flickering
  visible surfaces. An invalid config keeps the last working palette.
- Custom theme files now derive `surface` from background/foreground when the
  file does not provide it. Shared appearance colours are treated the same way.
- `nirunotify --check-config` prints the effective theme and full palette, so
  colour mistakes are visible without a screenshot.
- README, design contract and config example document that colours are not
  duplicated in nirunotify.

## Verification

- `cargo fmt --check`, clippy with `-D warnings`, five unit tests and the
  D-Bus/X11 UI smoke test passed for NIRUNOTIFY 0.3.4.
- New unit test covers Nord colours and a custom theme surface derived from
  background/foreground.
- UI smoke test sends a live `_NIRU_CONFIG_SERIAL` change (theme Nord, width
  500) and waits for the already visible notification to be rebuilt at the new
  width. All existing action, DND, expiry, lock-privacy and OSD checks still
  pass.
- NIRUNOTIFY v0.3.4 published from commit `2448776`.

## Follow-up 0.10.43

The first run exposed a reporting bug: colours were correct, but
`nirunotify --check-config` printed `theme: niru-noir` because it read a
non-existent `theme` key from the notifier config instead of the effective
NIRUWM theme. NIRUNOTIFY 0.3.5 reads the validated theme name from
`niruwm/config.toml`; the palette was already doing this. A NIRUX
appearance-contract assertion now requires the printed theme to match the
selected built-in or custom theme.

## Integration

NIRUX 0.10.42 pins NIRUNOTIFY 0.3.4. No config migration is needed: the
notifier follows the existing NIRUWM theme file and the existing appearance
contract. H01 remains the next roadmap task.

CI, release and host deployment evidence is added after publication.
