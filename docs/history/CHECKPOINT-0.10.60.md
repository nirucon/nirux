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

## Follow-up 0.10.61

The first deployment exposed two integration defects: the service-enable block
was missing from the released installer, leaving `power-profiles-daemon` disabled
on Arch and unlinked on Void, and a failed provider query printed an audio-specific
error. NIRUWM 0.16.58 makes provider errors generic; NIRUX 0.10.61 restores the
Bluetooth/PPD service enabling for both installs and updates. The service state
was verified on both hosts after the follow-up deployment.
