# Checkpoint 0.10.34 — target-owned apply (S03)

Recorded **2026-10-20**. Completes the S03 handoff gap: a new target installer
now owns configuration, integration and activation, not only component staging.

## Protocol

The staged-binary handoff stays at protocol 1 for compatibility. A separate
discovery command avoids breaking older callers:

| Command | Result |
|---|---|
| `_handoff-version` | `1` (staging protocol, unchanged) |
| `_apply-version` | `2` (target-owned apply) |
| `_stage 1` | stage components, PAM asset and manifest |
| `_apply 2` | run target `browser_install`, `install_config`, wallpaper install, PAM/session integration, startx/DM setup, activation and bar-restart message |

A 0.10.34 caller queries `_apply-version`. When it is `2`, the caller stages
through the target and then invokes the target's `_apply 2` with the same prefix,
system root, work directory, DM, browser policy and operation. It does not run
its own old config/integration/activation code. Targets that only advertise
protocol 1 keep the previous fallback behaviour.

## Failure safety

Before target apply, the target backs up the resolved `config.toml` and
`appearance.toml` (including symlink targets). Its EXIT trap restores them if any
step before activation fails. Activation remains the last mutation. A synthetic
failure injected immediately after target `install_config` therefore leaves the
original config hash and the active generation unchanged. Existing config
candidates, controlled system-file writes and generation switching still apply.

## Regression coverage

New synthetic targets exercise a genuinely newer feature set than the caller:

- `99.4.0` adds a `newfeature = true` config key, a new wallpaper asset and a
  new `nirunew` component. One update links the component, writes the key,
  installs the asset and reports target apply.
- `99.4.1` injects a target apply failure after config migration. The update
  fails, restores the exact config hash, leaves the generation unchanged and
  reports both the simulated failure and the caller's failure.

Existing integration tests now also exercise target apply for install, update,
rollback, new-component, new-library, config-rejection and checksum-failure
paths. `NIRUX_TEST_AS_ROOT=1` is an integration-only hook for the target-apply
subprocess against a temporary system root; production never sets it.

## Evidence

- `sh tests/integration.sh` passed, including the new S03 one-update and failure
  cases.
- `tests/release-smoke.sh` passed on local Arch, Debian and Void containers with
  the real 0.16.32/0.18.16 components, real wallpapers, Helium, startx and
  target apply.
- Full CI and owner-host deployment are recorded after the release.

## Remaining

S04 (full vanilla runtime audit) and H01 (fresh physical OS acceptance) are next.
Existing 0.10.33 hosts need one update to install the 0.10.34 caller; subsequent
updates use target apply in one pass.
