# 0.10.44 — power menu, themed greeters and startx welcome

Date: 2026-10-20. Owner requests after testing Arch and Void:

- Shut down from `Super+Shift+P` failed, with a `ctl` error and a lingering
  notification.
- The notification urgency strip should use the active theme.
- SDDM and LightDM should get NIRUX-matching colours and the Rooted in Less
  wallpaper when selected.
- startx should show a welcome message.

## Shutdown and local power actions

Root cause: `niructl` passed the action name directly to `loginctl`. logind has
`poweroff`, `reboot` and `suspend`, but no `shutdown` verb. The same mistake was
present in the `systemctl` fallback. NIRUWM 0.16.41 maps `shutdown` to
`poweroff` for both backends and keeps the existing logind/session handling.
The failure notification now uses the normal eight-second timeout instead of a
long-lived critical notification.

NIRUX installs `/etc/polkit-1/rules.d/49-nirux-power.rules`. It permits
power-off, reboot and suspend without a password only for a **local, active**
user in `wheel` or `sudo`. Remote sessions, inactive sessions and other users
still go through the normal Polkit authentication agent. The rule is installed
even with startx and removed on uninstall.

The host machines were not powered off as a test; the mapping is covered by a
unit test (`shutdown` → `loginctl poweroff`) and the rule by installer
regression tests. The active session picks up the new `niructl` binary from the
generation link immediately.

## Notification strip

NIRUNOTIFY 0.3.6 maps the left urgency strip through the active theme palette:
low urgency uses `muted`, normal uses the theme accent, and critical uses the
theme error colour. The existing live theme reload still restyles an already
visible stack and OSD.

## SDDM and LightDM

NIRUX now ships a small integration archive (`nirux-integration.tar.xz`) with:

- an SDDM QML theme using the Niru Noir palette, with `background.png` taken
  from the Rooted in Less wallpaper and `Current=nirux` in
  `/etc/sddm.conf.d/50-nirux.conf`;
- a LightDM GTK greeter drop-in using the same background, a NIRU GTK theme and
  the standard GTK greeter panel indicators;
- the Polkit power rule.

The theme is installed only when SDDM or LightDM is selected. NIRUX-owned
system files are marked with an owner comment and removed on uninstall. An
existing display manager is not restyled. Updates refresh a NIRUX greeter theme
that is already installed, even though updates keep an existing display manager.

Arch's `sddm-greeter` links Qt5 while the package only recommends the Qt5 QML
runtime, so selecting SDDM now also installs `qt5-declarative` on Arch. Debian
and Void already pull the required QML modules.

## startx welcome

The generated `~/.xinitrc` exports `NIRUX_STARTX=1`; NIRUX refreshes its own
old xinitrc on update. The session sends a six-second NIRUNOTIFY notification,
“Welcome to NIRUX — A minimal X11 desktop”, after NIRUWM starts. Display-manager
sessions do not get the startx marker and therefore no welcome popup.

## Verification

- NIRUWM 0.16.41: fmt, clippy and all unit tests passed, including the
  `shutdown → loginctl poweroff` regression.
- NIRUNOTIFY 0.3.6: fmt, clippy, unit tests and the D-Bus/X11 UI smoke test
  passed.
- The SDDM QML theme was rendered with `sddm-greeter --test-mode` under Xvfb;
  the Rooted in Less background, NIRUX panel and login/shutdown/reboot controls
  were visible without QML errors. LightDM installation and file contents are
  covered by installer tests, but a real LightDM login was not exercised.
- NIRUX integration tests cover the Polkit rule, both greeter themes, owner
  removal, the startx marker and the existing install/update/rollback paths.
- The generated startx session is asserted to publish the welcome notification
  through NIRUNOTIFY before the autostart checks.

Remaining limits: the real power-off path and greeter login buttons were not
executed on the physical hosts; H01 still requires physical audio, lock/unlock
and suspend/output verification.

CI, release and host deployment evidence is added after publication.
