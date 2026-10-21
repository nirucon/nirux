# 0.10.59 — N3 built-in display profiles

## Implementation

`niructl display` now provides:

```text
display list
display save NAME
display apply NAME
display preview NAME [SECONDS]
display keep
display revert
display status
```

Profiles live in `~/.config/niruwm/displays.toml`; `displays.example.toml`
contains Laptop, Desk and Presentation templates to adapt to local RandR names
and modes. The command is built into niructl and needs only the already
installed `xrandr`; it introduces no daemon or new package.

- Save captures the active outputs, modes, positions, rotation and primary.
- Apply validates connected outputs, supported modes, duplicate outputs, exact
  positions and rotation before invoking `xrandr`. Outputs omitted from a
  profile are turned off.
- Preview stores the previous layout, applies the profile, notifies with a
  deadline and automatically restores the previous layout if Keep is not chosen.
  A failed apply attempts the same restore.
- Revert applies the saved previous layout immediately; status reports the
  remaining preview time. Expired backend state cannot be reused by a new
  preview because the helper carries a unique token.
- NIRULAUNCHER lists profiles plus Keep/Revert under Displays and supports
  `--displays`. NIRUBAR's display panel middle-click opens the same selector.
  Opening the panel never applies a layout.

## Verification

- NIRUWM 0.16.56: fmt, clippy, all unit tests and the real Xvfb/RandR profile
  lifecycle test (save → list → apply → preview → status → keep → revert).
- NIRUBAR 0.18.25: fmt, clippy and all unit tests.
- NIRULAUNCHER 0.2.10: fmt, clippy, unit tests and X11 UI smoke.
- NIRUX integration and release smoke pass on Arch, Debian and Void before
  release. The repository includes `displays.example.toml`; existing configs are
  untouched.
- Owner-present multi-output/hotplug, real external-mode changes and failure
  injection remain hardware tests. Revert uses the active connected outputs and
  can only restore outputs that are still present.

## Release and deployment evidence

NIRUWM v0.16.56, NIRUBAR v0.18.25 and NIRULAUNCHER v0.2.10 are published;
NIRUX 0.10.59 pins them. CI, release and host deployment results are added after
publication.
