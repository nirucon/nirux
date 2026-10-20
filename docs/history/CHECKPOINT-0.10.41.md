# Checkpoint 0.10.41 — dwm-style mouse and workspace autostart

Recorded **2026-10-20**. Owner-requested quality-of-life patch before returning
to the correctness queue.

## Mouse

NIRUWM now installs passive Super+Button1/Button3 grabs on managed windows:

- **Super+Button1** moves a window. A tiled window becomes floating after the
  drag threshold, like dwm.
- **Super+Button3** resizes from the nearest corner: all four corners are
  supported. Tiled windows become floating first.
- Motion is clamped to the monitor, minimum size is 80x60, and the pointer grab
  is always released, including on errors.
- `Super+Shift+Space` remains the explicit floating ↔ tiling toggle.
- Fullscreen windows are not moved or resized; unmodified clicks go to the app.

The geometry math has unit tests; a real Xvfb/xdotool run moved a tiled xclock
into floating geometry and resized it.

## Autostart

`[[autostart.apps]]` in the shared config starts programs once at login:

```toml
[autostart]
enabled = false
settle_seconds = 2
return_workspace = 1

[[autostart.apps]]
workspace = 1
command = ["kitty"]

[[autostart.apps]]
workspace = 3
command = ["helium"]
```

- Entries are stable-sorted by workspace; same-workspace entries keep config
  order.
- Each group launches on its workspace, waits 250 ms between programs and
  `settle_seconds` after the group.
- The sequence returns to `return_workspace` only if the user has not switched
  away from the last autostart workspace.
- An empty `apps` list does nothing.
- `restore_session = true`, a non-empty saved session, and
  `nirupi_compat = true` suppress the sequence to avoid duplicate launches.
- Commands are argv arrays, never shell strings. A missing program is logged and
  skipped.
- The session launches `niructl autostart` once after the WM is up; no daemon.

Verified in an Xvfb session with two marker scripts: the marker for workspace 2
recorded tag=2, workspace 1 recorded tag=1, and the final active tag was 1.

## Configuration documentation

`config.example.toml` now has an English section index and clear sections for
appearance/layout, programs/font, weather, wallpaper, autostart, night light,
monitors, bar and key bindings. The mouse controls and autostart semantics are
documented next to the settings they affect. NIRUX adds the autostart section to
existing configs during migration.

## Evidence

- NIRUWM 0.16.40 unit tests, fmt and clippy passed; the mouse geometry tests
  cover clamping, top-left resize and minimum size. A real Xvfb/xdotool run
  moved a tiled xclock into floating geometry and resized it from the
  bottom-right corner.
- The autostart session test used two marker scripts on workspaces 2 and 1.
  The workspace-2 marker recorded `tag=2`, the workspace-1 marker recorded
  `tag=1`, and the final active workspace was 1.
- NIRUX CI [39473046652](https://github.com/nirucon/nirux/actions/runs/39473046652)
  passed check, Arch, Debian and Void. Release v0.10.41 published.
- `niru@void` and `niru@thinkpad` run NIRUX 0.10.41 / NIRUWM 0.16.40 /
  NIRUBAR 0.18.18 / NIRULAUNCHER 0.2.3. Both received the autostart config
  section with `enabled = false` by migration.
- The active sessions still ran older WM processes during deployment, so the
  new mouse controls and session-driven autostart activate at the next
  logout/login. `niructl autostart` already returns successfully against the
  active displays. No session was logged out.
