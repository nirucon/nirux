# Checkpoint 0.10.39 — wallpaper choices in the unified launcher

Recorded **2026-10-20**. Adds the minimalist wallpaper UI requested by the owner,
including the three extra NIRUX wallpaper sets.

## What changed

- NIRUWM 0.16.37 adds `niructl wallpaper`:
  - `list` / `status` (work without X)
  - `set PATH` (enables the wallpaper, stores an absolute path, sets `mode=single`)
  - `mode random|fixed|single`
  - `rotation MINUTES`
  - `scale fill|fit|stretch|center`
  - `follow-theme on|off`
- Config edits use `toml_edit`, so comments and unrelated settings are preserved.
  The WM reload path applies the change immediately; no new daemon.
- NIRULAUNCHER 0.2.2 puts a **Wallpaper** group in Super+Shift+P:
  - all installed NIRUX wallpapers (theme defaults + extras),
  - rotation cycle (0/5/10/30/60),
  - scale cycle,
  - mode cycle,
  - follow-theme toggle.
  Selecting an image applies it immediately. Typing `wallpaper` filters the group.
- The launcher gets the list/status from `niructl`; it does not parse or write
  `config.toml` itself.
- NIRUX 0.10.39 includes the three extra wallpapers, in 4K and 8K:
  - Håvamål 19
  - Rooted in Less
  - Space to Think Silhouette
  They are not theme defaults; they are selectable extras.

## Verification

- `sh tests/integration.sh` covers appearance migration and terminal config.
- `tests/startx-smoke.sh` now lists and selects “Håvamål 19”, verifies the root
  pixmap changes, and checks mode/rotation/scale/follow-theme through
  `niructl wallpaper status`.
- NIRUWM and NIRULAUNCHER fmt/test/clippy passed.
- Release smoke is run on Arch, Debian and Void with real pinned components.
- Full CI/release/owner-host deployment are recorded after publication.
