# Checkpoint 0.10.37 — terminal integration and target-owned assets

Recorded **2026-10-20**. The kitty/fish work is described in the
[0.10.36 checkpoint](CHECKPOINT-0.10.36.md); this release adds a target-apply
fix found while deploying it.

## Target-owned assets

The 0.10.35 caller did not know about the new `nirux-terminal.tar.xz` asset, so
a 0.10.35 → 0.10.36 update installed programs but skipped the terminal step.
The same class of bug would affect any future asset added only to a target
release.

`_apply` now fetches and verifies the target's optional wallpapers and terminal
archives itself before changing user/system files. A synthetic 99.5.0 target in
`tests/integration.sh` adds an asset the caller has never heard of; only the
target apply can fetch it, and the test asserts it appears after one update.

## Terminal integration

- NIRUX 0.10.37 installs kitty + fish, a fast two-line fish prompt, persistent
  fish history/autosuggestions/completion, `nirux`/`niructl` completions and a
  `nirux-update` helper.
- Existing kitty/fish configs receive one reversible managed block with
  `.nirux-backup`; user settings and fish history are preserved.
- NIRUWM 0.16.35 runs the optional `nirux-theme-hook` on theme change/reload and
  the session runs it at login. Kitty reloads via `SIGUSR1`; fish re-sources
  colours on the next prompt.
- All built-in terminal palettes pass the contrast test (foreground >= 7:1,
  muted/ANSI >= 4.5:1, selection foreground >= 4.5:1). Carl Larsson is handled
  as a light terminal theme.
- No fisher, Pure, starship, zoxide, eza or bat is required.

## Evidence

- `sh tests/integration.sh` passes, including existing-config preservation and
  the 99.5.0 target-only asset test.
- `python3 tests/terminal-theme.py` passes.
- `tests/release-smoke.sh` passed on local Arch, Debian and Void containers with
  the real 0.16.35/0.18.17 components, including fish syntax, prompt output,
  kitty config parsing and theme-change regeneration.
- Full CI, release and owner-host deployment are recorded after publication.
