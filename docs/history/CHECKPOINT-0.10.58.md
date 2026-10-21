# 0.10.58 — N2 Bluetooth module and installation support

## Installation and dependencies

NIRUX now provisions BlueZ as part of the suite:

- Arch: `bluez` + `bluez-utils`.
- Debian: `bluez` (provides `bluetoothctl`).
- Void: `bluez` (provides `bluetoothctl` and `/etc/sv/bluetoothd`).

The installer enables/starts `bluetooth.service` on Arch/Debian when the unit is
present and links the `bluetoothd` runit service on Void. Service activation is
best-effort in containers without systemd PID 1, while package provisioning
still succeeds. Updates run service integration as well as fresh installs.
`doctor` reports `bluetoothctl` as an optional runtime tool rather than failing a
`--no-packages` install; normal installs include it. Integration tests assert
`bluez` on all three package lists and `bluez-utils` on Arch.

## Bluetooth controls

NIRUWM 0.16.55 adds `niructl bluetooth`:

```text
niructl bluetooth status
niructl bluetooth list
niructl bluetooth power on|off|toggle
niructl bluetooth connect MAC
niructl bluetooth disconnect MAC
```

It uses `bluetoothctl` through the bounded provider path. Status/list are
read-only, unpaired/invalid MACs are rejected, redundant power commands are
suppressed, and connect verifies that BlueZ reports the device connected.
Battery appears only when BlueZ reports it; missing battery is empty, never 0%.

NIRUBAR 0.18.24 adds an optional `bluetooth` module. It hides without an adapter,
shows off/on/connected state, and its panel lists paired devices and battery.
Right click toggles power; middle click opens `nirulauncher --bluetooth`.
NIRULAUNCHER 0.2.9 lists power and per-device connect/disconnect actions there
and in actions mode. Opening a panel never connects or pairs.

## Verification

- NIRUWM 0.16.55: fmt, clippy, all unit tests and fake-BlueZ CLI regression.
- NIRUBAR 0.18.24: fmt, clippy, unit tests, fake-provider X11 smoke and existing
  X11 suite.
- NIRULAUNCHER 0.2.9: fmt, clippy, unit tests and X11 UI smoke.
- NIRUX integration: package lists and shared config contract.
- NIRUX release smoke pending on all three distros.

Owner-present pairing, real adapter power, connect/disconnect and battery
reporting remain hardware checks. Tests on the previous P1–P6 work remain
deferred by the owner. Next feature is N3 built-in display profiles.

## Release and deployment evidence

NIRUX 0.10.58 passed CI and was deployed to ThinkPad and Void. Both run
NIRUX 0.10.58 / NIRUWM 0.16.55 / NIRUBAR 0.18.24 / NIRULAUNCHER 0.2.9.
`bluetoothctl`, BlueZ and the platform service are present; `bluetooth.service`
is enabled+active on ThinkPad, and the `bluetoothd` runit service is linked on
Void. Both adapters report `state=ready`, `powered=true`:
ThinkPad 7C:7A:91:3E:25:FF, Void 94:E2:3C:CA:91:7A. No devices were paired on
either host, so connect/disconnect and battery remain unexercised hardware paths.
The modules are optional and existing `[bar] modules` lists are preserved; add
`"bluetooth"` or `"microphone"` to opt in. No session was forced to log out.
