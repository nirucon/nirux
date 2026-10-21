# 0.10.60 — N4 capability-aware power profiles

## Installation and dependencies

NIRUX installs `power-profiles-daemon` on Arch, Debian and Void and enables the
platform service (`power-profiles-daemon.service` on Arch/Debian and the
`power-profiles-daemon` runit service on Void). Service activation is
best-effort in containers without the init system running; normal installs and
updates still provision the package. Integration tests assert the package on all
three distro lists; `doctor` reports `powerprofilesctl` as an optional runtime
tool, and a missing provider keeps the UI hidden instead of guessing at sysfs.

## Power-profile controls

NIRUWM 0.16.57 adds:

```text
niructl powerprofile status
niructl powerprofile list
niructl powerprofile set NAME
niructl powerprofile next
```

It reads the active profile and available profiles from `powerprofilesctl`,
reports the AC/battery source from `/sys/class/power_supply`, rejects names the
provider does not advertise, and verifies a requested change before reporting
success. Status/list are read-only. No automatic switching by battery state is
performed.

NIRUBAR 0.18.26 adds an optional `powerprofile` module: hidden when the provider
is unavailable, otherwise shows the active profile (perf/bal/save). Its panel
lists active/available profiles and the power source. Right click advances to
the next profile; middle click opens `nirulauncher --power`.
NIRULAUNCHER 0.2.11 lists only provider-supported profiles and changes nothing
until a profile is chosen.

## Verification

- NIRUWM 0.16.57: fmt, clippy, all unit tests and fake-`powerprofilesctl`
  regression covering read-only status/list, set and next.
- NIRUBAR 0.18.26: fmt, clippy, unit tests (provider state, no invented
  capability) and release build.
- NIRULAUNCHER 0.2.11: fmt, clippy, unit tests and X11 UI smoke.
- NIRUX integration: package lists and configuration contract.
- NIRUX release smoke pending on Arch, Debian and Void.

Real PPD service interaction and hardware profile changes remain host tests.
Tests for earlier P1–P6 work remain deferred by the owner. Next feature is N5
nirushot.

## Release and deployment evidence

NIRUWM v0.16.57, NIRUBAR v0.18.26 and NIRULAUNCHER v0.2.11 are published;
NIRUX 0.10.60 pins them. CI, release and host deployment results are added after
publication.
