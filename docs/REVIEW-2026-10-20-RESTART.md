# Restart review — published 0.10.30

> **Status update:** this review documents 0.10.30. S01/S02 are implemented in
> 0.10.31; see the [0.10.31 checkpoint](history/CHECKPOINT-0.10.31.md) and the
> current [roadmap](../ROADMAP.md). The findings below remain the historical
> reproduction and the S03/S04/C01–C07 worklist.

Reviewed **2026-10-20** for the owner's OpenCode restart. This is a targeted
installation/integration review and a correction of acceptance claims, not a
line-by-line audit of every optional repository.

## Main conclusion

The suite has published, useful implementations and regressions. **Do not claim
complete vanilla installation with an optional managed Helium browser yet.**
There is no Helium installer policy in the current source and the complete distro
CI is failing. Restore installation acceptance before implementing A04 or another
application. The authoritative ordered tasks are in [ROADMAP](../ROADMAP.md).

## Revisions and publication

GitHub main heads observed before this documentation update:

| Repository | Revision | Release |
|---|---|---|
| nirux | `27f6661b40f5` | v0.10.30 |
| niruwm | `ceb78000eadf` | v0.16.30 |
| nirubar | `e870f89d369b` | v0.18.15 |
| niruscreensaver | `52173f62718b` | v0.8.3 |
| nirulock | `9929208c898d` | v0.16.10 |
| nirulauncher | `8aa2a9004021` | v0.2.1 |
| nirunotify | `00d9ec47226f` | v0.3.3 |

All expected release listings were found. NIRUX has `nirux`, `manifest`,
`config.example.toml`, `appearance.example.toml`, `SHA256SUMS`. WM includes the
session and bundled-bar metadata; locker includes all three pinned PAM assets.
Asset presence is not a new checksum/download/runtime certification.

## What was actually verified in this review

- `git status -sb` was clean before edits; fetched origin/main.
- `sh tests/integration.sh`: passed on the local host. It uses fake release assets
  and mock package operations while exercising all three distro mappings.
- `shellcheck -S warning nirux tests/*.sh`: passed.
- `git diff --check`: passed before documentation changes.
- `docker run --rm -v <checkout>:/src:ro debian:bookworm-slim sh
  /src/tests/integration.sh`: passed. Still a mocked regression, not provisioning.
- Queried full CI [39406911647](https://github.com/nirucon/nirux/actions/runs/39406911647):
  shell-check job passed; each distro's dependency installation step passed;
  **Arch, Debian and Void all failed at Startx and real release integration**.
  The complete per-distro failure logs were not recovered in this review;
  diagnose before attributing one shared root cause.
- A new disposable Debian provisioning + real-release smoke attempt exceeded
  the 300-second budget during package unpacking, before smoke acceptance. Its
  container was stopped and removed. This is **incomplete**, not pass/fail proof
  for the desktop runtime.
- No SSH, desktop, package, suspend, browser or PAM changes on the owner's
  machines were made by this documentation checkpoint.

Previous sessions recorded 0.10.30 deployment and owner-confirmed lid/output
behaviour. Those records remain history, not new clean-install evidence.

## Source-confirmed gaps and follow-ups

### S01/S02 — vanilla acceptance and Helium

`nirux:usage`, `packages_for`, `stage_release` and `install_or_update` contain no
Helium flag, download, dependency or opt-out persistence. The canonical
`config.example.toml` still has `browser = ["brave"]`. Provisioning installs
neither Brave nor Helium. The docs explicitly say browsers are not provisioned.
`doctor` now fails missing configured commands, so an empty installation with
that browser setting cannot be certified as a complete passing experience.

The user has explicitly requested a Helium **option**. This must be implemented,
not described as already delivered. Upstream
[imputnet/helium-linux](https://github.com/imputnet/helium-linux/releases) exists;
the release listing observed was `0.19.4.1`, including x86_64 tar.xz, AppImage and
Debian assets. This is discovery only. Recheck release policy and sandbox/runtime
requirements when implementing; do not hardcode an unverified mutable download
or assume the three distributions have identical shared-library packages.

Prefer a documented common upstream-asset path with pinned identity/integrity,
owned files and persistent opt-out. Validate a normal-user sandboxed browser
launch on all three systems. AppImage/FUSE and build-from-AUR should not become
unexamined mandatory requirements. Preserve an existing browser selection.

### S03 — one-update semantics remain incomplete

`nirux:stage_release` invokes the target's `_stage` protocol for component
staging. `install_or_update` then calls the running old script's `install_config`,
system integration and activation. Previous A01/A02 deployments explicitly
required a second update for new appearance/config changes. A shell fixture using
the same implementation for both releases does not prove an actual historical
caller completes new integration semantics in one update.

### C01 — appearance acceptance is overstated

`appearance.example.toml` installs explicit Noir colour overrides. WM/bar theme
loaders apply them over built-ins when no user theme file exists: simply checking
that Nord/Satie/Carl Larsson loaders exit successfully does not assert that their
rendered palette still differs. The loaders discard invalid appearance and fall
back to another source; they do not store a last-good appearance snapshot.
`tests/appearance-contract.sh` checks exit codes, not live reload preservation,
semantic values or pixels. Font/spacing/focus validation differs between readers.
Recheck actual lock opacity/background after local palette overrides too.

### C02 — night-light claims need actual event and ownership tests

In `niruwm/src/bin/niructl.rs:nightlight`, the coordinate requirement precedes
the command dispatch: even `off`, `status` and manual mode can be rejected when
both coordinate sources are zero. Fixed time-of-day scheduling should not need
a geographic location. In `reconcile`, an unchanged Kelvin string suppresses
the gamma call; polling that same state every 30 seconds does **not** prove
reapply after resume or a newly attached output. `watch` has no singleton owner
protocol. Process `.output()` calls have no deadline and parsing gammastep's
human-readable output needs locale/exit-status tests.

### C03 — input and launcher follow-ups

Keep the shipped Shift/Caps/MOD5 changes and argv safeguards. Real XKB modifier
group selection and MappingNotify still need Swedish/US/AltGr acceptance; a
synthetic four-element keysym test does not prove the server mapping. Dead-key
compose/IME are explicitly unimplemented. Group prefixes are not a full grouped
palette design. EWMH focus requests should be tested with the actual WM, not
only launcher exit under Xvfb without a WM. Usage-state writing needs atomicity
and bounded/untrusted-key fixtures.

### C04 — battery/network follow-ups

`nirubar/src/status.rs` sums power/current even when only part of the pack set has
matching energy/charge data; remaining-time estimates need complete compatible
inputs. `Not charging` is not proof of a full battery. A global default route can
belong to a different interface than the icon selected from sysfs. IPv6 default
route detection needs flags/device/reject filtering. A route is not measured
Internet connectivity; keep wording precise and avoid an obligatory ping service.

### C05 — weather follow-ups

`nirubar/src/weather.rs` still converts missing probabilities/hourly temperature
to `0.0`, compares forecast-local timestamps against the machine's local clock,
and uses the first daily sunrise/sunset even when cache days are stale. The fetch
URL does not explicitly request m/s while the panel labels wind as m/s. The stale
label is tied to an error rather than only data age. Keep the existing cached
background fetching, but assert unknown/timezone/unit/polar/date semantics before
claiming full A03 acceptance.

## Test/deployment boundaries

`--no-packages` is useful for isolated binary tests and existing-host updates; it
is never proof that a vanilla OS has all dependencies. Successful root-container
PAM tests are different from normal-user login and physical sleep. The release
workflow currently runs mocked integration and asset-list checks, whereas full
CI also installs packages and runs real releases/startx. Record both outcomes.

Prior production installations used the owner's separate NIRUPI session on Void.
Preserve it, all custom config/theme files and rollback generations. Never log
credentials or conduct destructive PAM/clean-home tests against the owner's home.

## Resume order

S01 → S02 → S03 → S04/H01 → C01–C07 → A04 → gated innovations/optional apps.
Consult the current roadmap for acceptance criteria and repository boundaries.
