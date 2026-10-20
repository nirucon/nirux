# Checkpoint 0.10.40 — safe wallpaper mode cycle

Recorded **2026-10-20** as a small follow-up to
[0.10.39](CHECKPOINT-0.10.39.md).

The 0.10.39 launcher cycled `random → fixed → single` even when no explicit
wallpaper file was selected. Choosing `single` with an empty `file` could make
the desktop wallpaper disappear. 0.10.40 exposes `single` in the cycle only when
the current config already has a non-empty `file`; otherwise it cycles
`random ↔ fixed`. Selecting a specific image still sets `mode = single` with its
absolute path.

Evidence:

- NIRULAUNCHER 0.2.3 fmt/test/clippy and release passed.
- NIRUX CI [39467536699](https://github.com/nirucon/nirux/actions/runs/39467536699)
  passed check, Arch, Debian and Void. Release v0.10.40 published.
- `niru@void` and `niru@thinkpad` are on NIRUX 0.10.40 / NIRUWM 0.16.37 /
  NIRULAUNCHER 0.2.3. `niructl wallpaper list` returns the three extras
  (Håvamål 19, Rooted in Less, Space to Think Silhouette) plus the four theme
  defaults. Both hosts report the expected wallpaper status.
- The real startx smoke test selects Håvamål 19, verifies the root pixmap change
  and checks mode/rotation/scale/follow-theme through `niructl wallpaper status`.
- Thinkpad Tailscale remains enabled + active; Void's tailscaled runit service
  link is present.
