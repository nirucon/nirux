# 0.10.47 — P2 live acceptance snapshot

Date: 2026-10-21. P2 is **partial**: every non-disruptive check passed on both
hosts, while owner-present hardware paths remain open.

## New tooling

`tests/live-acceptance.sh` is a read-only check for an already running session.
It discovers the X/DBus environment from NIRUWM, prepends `~/.local/bin`, and
reports versions, displays, power rule and Polkit decisions, DND, audio nodes,
the sleep inhibitor, notification ownership, running helpers and a process/RSS
snapshot. Missing physical tests are warnings, never passes.

`niructl dnd status` now terminates its native output with a newline. This was
the only issue found during the P2 snapshot.

## Arch — niru@thinkpad (clean NIRUX startx)

- Session: `DISPLAY=:0`, one 1920x1080 eDP-1 display, startx/NIRUWM.
- Versions: NIRUX 0.10.46, NIRUWM 0.16.43 (before the 0.10.47/0.16.44 update),
  NIRUBAR 0.18.19, NIRUNOTIFY 0.3.7, NIRULOCK 0.16.10, NIRUSCREENSAVER 0.8.3.
- Polkit: local `power-off`, `reboot` and `suspend` all returned
  `result=yes` for the NIRUWM process. The rule file is installed and the user
  is in `wheel`.
- Power backend: `loginctl` available.
- Audio: one PipeWire sink and one source; built-in ALSA device.
- Sleep: NIRU `Lock before suspend` delay inhibitor held via `systemd-inhibit`.
- Notifications: native owner present; DND status/toggle worked.
- Night light: manual, 3400 K.
- Resource snapshot: 54 processes, about 2166 MiB total RSS (includes Helium).

## Void — niru@void (NIRUX + NIRUPI)

- Session: `DISPLAY=:0`, one 1920x1080 eDP-1 display, startx/NIRUWM.
- Versions matched the same component set.
- Polkit: local `power-off`, `reboot` and `suspend` all returned `result=yes`;
  rule installed and user in `wheel`.
- Power backend: `loginctl` available.
- Audio: four PipeWire sinks and two sources; built-in Tiger Lake audio.
- Sleep: NIRU delay inhibitor held via `elogind-inhibit`.
- Notifications: native owner present; DND status/toggle worked.
- Night light: manual, off.
- Resource snapshot: 30 processes, about 288 MiB total RSS.

## Verification

- NIRUX 0.10.47 integration and real-release smoke pass on Arch, Debian and Void.
- The startx smoke covers logout cleanup, lock privacy in the UI test, DND
  against the native provider and bar restart in an isolated X session.
- SDDM and LightDM themes were rendered/loaded in isolated tests; a real
  greeter login is still not part of this snapshot.

## Open P2 blockers

These require the owner present and were **not** executed:

- Lock/unlock with real PAM and unlock interaction.
- Suspend/resume, including night-light reapply and display re-detection.
- Audible speaker/microphone verification.
- Actual poweroff/reboot from the menu.
- External display/hotplug and mixed-width outputs.
- Fresh Void clean-OS acceptance. The current Void host also runs NIRUPI.
- SDDM/LightDM real login on a clean system.

## Release and deployment evidence

NIRUWM 0.16.44 and NIRUX 0.10.47 fix the DND newline and add the live
acceptance check. CI, release and deployment results are added after
publication.
