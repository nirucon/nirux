# 0.10.57 — N1 microphone module

## Implementation

- Optional `[bar] modules` entry `microphone`, with `microphone_visibility`
  `always` or `muted`. Missing input/provider remains visible. Existing module
  arrays are preserved; enable the module explicitly.
- The bar displays mute, gain, no input or unavailable state. Its read-only
  information panel names the selected input and explicitly says recording
  activity is not monitored. Left click has no side effects.
- Right click uses `niructl audio mic-mute`; scrolling uses `mic-level up/down`
  and never unmutes. Middle click opens `nirulauncher --microphone` for keyboard
  mute/gain/input selection. The launcher also exposes these in actions mode.
- `niructl audio mic-status` returns a read-only snapshot with selected audio
  source ID/name, gain and mute, or an explicit unavailable/no-input state.
  Cameras are excluded and invalid audio device IDs are rejected before changes.
- `mic-level up|down|set N` limits gain to 100%; `mic-mute on|off|toggle` changes
  mute explicitly. This is configured gain, not an audio amplitude meter.
- One worker per enabled bar polls the shared CLI every two seconds. Rendering
  and opening a panel read memory only. Provider calls have two-second deadlines
  and output limits; the worker also has an outer deadline. No new daemon or
  dependency service is added.

## Verification

- Rust fmt/clippy/unit suites for bar, WM/CLI and launcher.
- Offline fake-provider CLI regression: status is read-only, cameras cannot be
  selected as audio inputs, gain preserves mute, invalid gain is rejected,
  no-input/error states and a hung provider are handled within the deadline.
- Real Xvfb bar regression with fake CLI: an external source/gain/mute snapshot
  change updates the painted module, opening information writes no audio
  command, and explicit controls call the shared CLI/keyboard selector.
- Launcher X11 regression: opening the microphone view performs no change;
  keyboard selection of a named USB input sends the exact source ID. Large-font
  and existing launch/singleton checks remain in the same suite.
- Shared configuration accepts `microphone_visibility = "muted"` and rejects
  unsupported values in both NIRUWM and NIRUBAR.

Release CI and host verification are recorded after publication. Owner-present
audible microphone and USB hotplug checks remain separate from fixture/Xvfb
evidence. Next feature is N2 Bluetooth.
