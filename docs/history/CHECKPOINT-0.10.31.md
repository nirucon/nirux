# Checkpoint 0.10.31 — S01/S02, managed Helium and full CI

Recorded **2026-10-20**. This supersedes the 0.10.30 Helium/CI findings in the
[restart review](../REVIEW-2026-10-20-RESTART.md) while preserving them as
history. Remaining work is tracked in [ROADMAP.md](../../ROADMAP.md).

## Reproduction and diagnosis (S01)

The examined 0.10.30 run was
[CI 39406911647](https://github.com/nirucon/nirux/actions/runs/39406911647).
Shell checks, mocked regressions, dependency provisioning and the optional-DM
lookups passed. All three distro jobs failed in the step named
`Startx and real release integration`.

The retained per-job logs show the same final lines on Arch, Debian and Void:

```text
missing configured brave (selected in config.toml)
##[error]Process completed with exit code 1.
```

The install itself completed, `status` passed, PAM includes were readable and
all component config checks ran. `doctor` then failed because the canonical
config selected `brave`, which NIRUX did not provision. The release-smoke script
stopped there, so config-contract and the actual startx step had not run in that
job. This was a browser-policy defect, not an X server or starter failure.

## Implemented in 0.10.31 (S02)

- Canonical browser is `helium`; a fresh install selects it and offers an
  interactive opt-out. `--browser helium|none|keep` is accepted by install and
  update, with `none` persisted in `$PREFIX/share/nirux/browser-policy`.
- Helium is downloaded from the official upstream release, pinned to
  **0.19.4.1**, with SHA-256
  `6ca6e4a00fef5916821fb1af8a9607cc6b386f678a7eb422e55f19116ba30469`.
- The archive is checksum-verified, extracted with `xz`, checked for missing
  shared libraries and started for its version before the stable links switch.
- Runtime packages are provisioned only when Helium is selected:
  NSS/NSPR, CUPS, GTK3/ATK, X composite/damage/fixes/randr, xkbcommon, GBM/Mesa,
  ALSA and xz, using each distro's package names.
- The managed command is `$PREFIX/bin/helium`; the desktop entry lives under
  `$PREFIX/share/applications` and uses the absolute managed command and icon.
  Existing external Helium installations are not overwritten.
- `status` reports the persistent policy and broken/missing managed files.
  `doctor` already fails a configured browser that is not installed.
- Update keeps the recorded policy unless a browser flag is supplied. Explicit
  `--browser none` removes NIRUX-owned browser files but never the Helium
  profile. Uninstall removes only owned browser files; `--purge` does not remove
  an external browser profile.

## Evidence

Full CI: [run 39420180581](https://github.com/nirucon/nirux/actions/runs/39420180581)
on commit `de45d5b`.

| Job | Result |
|---|---|
| check (syntax, shellcheck, offline integration) | passed |
| Arch Linux base | passed |
| Debian Bookworm slim | passed |
| Void Linux glibc | passed |

The distro jobs now run, in order:

1. distribution-shell regression tests;
2. the complete vanilla package list with Helium runtime packages;
3. optional display-manager package lookups;
4. real pinned release install, doctor, update once, rollback, uninstall, plus
   config-contract and startx under Xvfb;
5. a fresh normal-user browser install and sandboxed headless launch of the
   real pinned Helium archive.

The browser test never passes `--no-sandbox`. On the Ubuntu CI host the container
runs privileged so the test can clear the host-only
`kernel.apparmor_restrict_unprivileged_userns` restriction; the supported target
distros provide unprivileged user namespaces directly. This is container
evidence, not a physical clean-OS certification.

Local supporting runs used the same commands in disposable Arch, Debian and Void
containers. All three passed `tests/release-smoke.sh` and
`tests/browser-smoke.sh`, including the normal-user Helium launch.

Offline regressions additionally cover: persistent opt-out, fresh opt-out config
`browser = []`, update preserving the policy, a corrupt Helium archive leaving
the active browser unchanged, version replacement with old-file cleanup, and
owned removal while preserving the external profile.

## Remaining limits

- S03: target-installer handoff still needs to own config/integration/activation,
  not only component staging.
- S04: the full dependency/runtime matrix still needs a recorded package-version
  and normal-user-runtime audit beyond successful provisioning.
- H01: no fresh physical OS/VM install on all three distributions yet. The
  owner's Void and Arch laptops need the 0.10.31 deployment check.
- Helium relies on the upstream archive, which does not ship a setuid
  `chrome-sandbox`; supported Debian/Arch/Void defaults use unprivileged user
  namespaces. No unsandboxed fallback is provided.
