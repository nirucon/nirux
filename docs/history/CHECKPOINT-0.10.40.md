# Checkpoint 0.10.40 — safe wallpaper mode cycle

Recorded **2026-10-20** as a small follow-up to
[0.10.39](CHECKPOINT-0.10.39.md).

The 0.10.39 launcher cycled `random → fixed → single` even when no explicit
wallpaper file was selected. Choosing `single` with an empty `file` could make
the desktop wallpaper disappear. 0.10.40 exposes `single` in the cycle only when
the current config already has a non-empty `file`; otherwise it cycles
`random ↔ fixed`. Selecting a specific image still sets `mode = single` with its
absolute path.

Evidence: NIRULAUNCHER 0.2.3 fmt/test/clippy and release passed; NIRUX
integration/release smoke and host deployment are recorded after publication.
