# 0.10.49 — P3 audio device controls

Date: 2026-10-21. P3 remains in progress.

## Audio controls

NIRUWM 0.16.46 adds `niructl audio`:

```text
niructl audio outputs|sources
niructl audio output ID|next
niructl audio source ID|next
niructl audio mute|mic-mute
niructl audio volume up|down
```

The parser reads `wpctl status` by node ID, not by name, because identical
sink/source names can coexist. It ignores the tree drawing characters, marks the
current default with `*`, and uses `wpctl set-default` for selection. Mute and
volume target the default PipeWire sink/source; a missing WirePlumber provider
returns an actionable error instead of guessing at ALSA.

NIRULAUNCHER 0.2.5 lists outputs and microphones as actions from that CLI, marks
the current device, and adds output/microphone mute to the Audio group. The bar
already had right-click output mute and middle-click microphone mute; this keeps
one provider-aware command path instead of duplicating WirePlumber logic.

## Verification

- NIRUWM 0.16.46: fmt, clippy, all unit tests passed. A parser regression covers
  two sinks (one default) and a source while ignoring the Devices section.
- NIRULAUNCHER 0.2.5: fmt, clippy, unit tests and the X11 UI smoke test passed,
  including large-font layout and existing launch/singleton/Escape behavior.
- NIRUX integration and real-release startx smoke pass on Arch, Debian and Void
  before release.
- Live host checks are recorded after deployment: `niructl audio outputs` should
  list the existing PipeWire sinks; selection is tested with `next` only where it
  is safe, followed by restoring the original default.

## Remaining P3

Display, battery and network status still need a clearer shared treatment.
Rendered-value checks for every component and the small-screen/hotplug matrix
remain open. P2 remains partial for owner-present lock/suspend/audio/power/
external-display checks.

## Release and deployment evidence

NIRUWM 0.16.46 and NIRULAUNCHER 0.2.5 are published; NIRUX 0.10.49 pins them.
CI, release and both-host deployment results are added after publication.
