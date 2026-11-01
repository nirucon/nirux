# Update and power off / restart

NIRUX can run a full system update in a terminal and then either power off or
restart. The actions are deliberately explicit; they are not part of a normal
`nirux update` and never happen from a hidden background daemon.

## Entry points

- `nirux update-shutdown [--yes] [--dry-run] [--no-power]`
- `nirux update-reboot [--yes] [--dry-run] [--no-power]`
- `niructl update-shutdown` / `niructl update-reboot` opens the same command in
  a terminal.
- NIRU Launcher Quick Settings and NIRU Actions add **Update and restart** and
  **Update and shut down** with a confirmation step.

`niructl` is only a terminal launcher. The package manager and sudo prompt run
in that terminal; NIRUWM itself never runs package commands.

## What runs

1. Validate the distribution and refuse an unsupported one.
2. Check the NIRUX lock and common package-manager processes.
3. Show a confirmation unless `--yes` is supplied.
4. Ask for sudo once in the terminal.
5. Run the native full update:
   - Debian: `apt-get update`, then `apt-get -y full-upgrade`
   - Arch: `pacman -Syu --noconfirm`
   - Void: `xbps-install -Suy`
6. Run `nirux update`.
7. Run `nirux extras update` when extras are selected.
8. Use the logind/runit power path only after every update step succeeds.

The terminal stays open (`--hold` in the terminal launcher) so a failure remains
readable. The update directory log is written to:
`$XDG_STATE_HOME/nirux/update-power.log` (normally
`~/.local/state/nirux/update-power.log`). It records phases and exit success,
not the sudo password or package-manager transcript.

## Safety behaviour

- A failed system, NIRUX or extras update never triggers the power action.
- A previous disabled firewall/profile and other NIRUX settings are not changed
  by this action; it delegates to the normal package and NIRUX update paths.
- Idle/sleep inhibition is held while the update runs where
  `systemd-inhibit`/`elogind-inhibit` exists; NIRUWM's idle marker is used as a
  fallback.
- `systemctl` is used only on a systemd boot. Void/runit uses the logind D-Bus
  interface, then native shutdown as a fallback.
- No `--force` shutdown is used. If a power request is inhibited or rejected,
  the machine stays running and the terminal reports the failure.
- `--dry-run` changes nothing. `--no-power` runs the real updates but leaves the
  machine running.

## Not included

AUR helpers, Flatpak, Snap, Docker image updates and BIOS/firmware flashing are
not implied. They require their own explicit workflows and authority.

## Tested

Live update paths were exercised on `algiz` (Arch), `ingwaz` (Debian) and `void`
(Void) with `--no-power`. The terminal launcher was verified on all three.
The actual restart path was exercised on `void` through the elogind D-Bus
backend. The power-off backend uses the same logind method with `PowerOff`; its
root authorization was checked, but a physical power-off was not performed
because it would require on-site power-on access. Do not claim a full power-off
test without that evidence.
