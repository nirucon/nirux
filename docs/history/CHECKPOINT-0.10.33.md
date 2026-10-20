# Checkpoint 0.10.33 — theme wallpapers and follow-theme

Recorded **2026-10-20** for the owner-requested wallpaper integration. Builds on
the [0.10.32 Helium checkpoint](CHECKPOINT-0.10.32.md).

## Delivered

- NIRUX installs the four theme wallpaper sets (Noir, Nord, Satie, Carl Larsson;
  4K and 8K) into `~/Pictures/Wallpapers/NIRU` on new and existing installs.
  `XDG_PICTURES_DIR` is respected.
- A checksummed `nirux-wallpapers.tar.xz` is a release asset. Older releases
  without it are still installable.
- Wallpaper ownership is recorded in `$PREFIX/share/nirux/wallpapers.sha256`.
  An update replaces only untouched NIRUX copies; a user-edited file is kept.
  Normal uninstall keeps the pictures. `--purge` removes only unmodified owned
  copies.
- The shared config gains:
  - `[wallpaper] follow_theme = true`
  - `[wallpaper] theme_dir = "~/Pictures/Wallpapers/NIRU"`
- A fresh config enables the wallpaper. Existing configs keep their `enabled`
  value, so a NIRUPI-owned background is not taken over.
- NIRUWM applies the theme wallpaper on startup, reload and theme change when
  the wallpaper is enabled and `follow_theme` is true. Mode `single` and
  custom `mode`, `file`, `files`, `dir`, rotation and scale settings still work.
  A custom theme `foo` may provide `nirux-wallpaper-foo-4k.png` (or `-8k.png`).
- NIRUBAR accepts the new shared keys; NIRUWM 0.16.32 / NIRUBAR 0.18.16 are the
  pinned pair. NIRUWM 0.16.31 was published first and its standalone
  `install.sh` still expected 0.16.30; 0.16.32 fixes that. Both tags are
  immutable; NIRUX pins 0.16.32.

## Verification

- `cargo fmt --check`, `cargo test --locked`, and
  `cargo clippy --locked --all-targets -- -D warnings` passed for NIRUWM and
  NIRUBAR. Wallpaper unit tests cover theme slug lookup and the `single` mode
  exception.
- NIRUWM CI for 0.16.32 passed `verify` plus Arch, Debian and Void session jobs.
- The NIRUBAR 0.18.16 release published, but its `Rust and X11` CI job still has
  the existing flaky `popup_and_reload_cycles_release_server_pixmaps` failure
  ("opening information changed audio/playback"). This is the C06 area, not the
  config-key change.
- NIRUX `tests/integration.sh` covers wallpaper install, update, normal
  uninstall, purge, modified-file preservation and the new config migration.
- `tests/release-smoke.sh` passed on local Arch, Debian and Void containers with
  the real pinned components, including the startx theme-change root-pixmap
  assertion.
- Full NIRUX CI and owner-host deployment results are added after the release.

## Limits

The 4K asset is the default; 8K is installed for users who select it. S03, S04
and H01 remain open.
