# Checkpoint 0.10.35 — system module icon

Recorded **2026-10-20** from the latest `niru@void` screenshot. The `pulse`
module used Font Awesome `f1fe` (`area_chart`). At the bar's 15 px text size the
baseline plus two tiny peaks looked like a coffee cup, not a system/load icon.

## Change

- NIRUBAR 0.18.17 uses `f2db` (`microchip`) for the `pulse` module.
- The existing per-glyph fallback remains: if the font cannot draw the glyph,
  the module renders the plain text `cpu`.
- A regression test asserts the nerd-font codepoint.
- NIRUWM 0.16.33 bundles NIRUBAR 0.18.17; NIRUX 0.10.35 pins the pair.

The microchip matches the wifi/battery Font Awesome family and reads as
CPU/system at tiny sizes. A tachometer was rejected because it resembles the
clock glyph; the area chart was rejected because of the cup silhouette.
Existing module text (`cpu N% mem N%`) and popup semantics are unchanged.

## Evidence

- `cargo fmt --check`, `cargo test --locked`, and clippy passed in NIRUBAR and
  NIRUWM.
- Local render comparison used the actual JetBrainsMono Nerd Font from
  `niru@void`.
- Full CI and host deployment are recorded after the 0.10.35 release.
