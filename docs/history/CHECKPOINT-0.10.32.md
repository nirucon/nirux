# Checkpoint 0.10.32 — one-update browser migration

Recorded **2026-10-20**. This is a small follow-up to the
[0.10.31 Helium checkpoint](CHECKPOINT-0.10.31.md); the full CI evidence and
remaining S03/S04/H01 work are unchanged.

## What changed

An existing 0.10.30 configuration still contained the old shipped default:

```toml
browser = ["brave"]
```

Updating with `--browser helium` installed Helium but preserved that obsolete
default, so `doctor` correctly reported the missing `brave` command. The update
now recognises only the exact old canonical default, checks that `brave` is not
actually installed, and replaces that one line with:

```toml
browser = ["helium"]
```

Custom browser selections are untouched. The change is staged next to the
existing config, validated by both NIRUWm and NIRUBAR, and follows the same
atomic/rollback rules as the other configuration migrations. Opt-out updates
still preserve existing browser settings.

## Evidence

- CI [39421428853](https://github.com/nirucon/nirux/actions/runs/39421428853)
  passed Arch, Debian and Void after one transient GitHub asset-download 500 on
  Debian; the failed job was rerun without code changes. The rerun retained all
  four green jobs.
- Local disposable Arch, Debian and Void containers passed
  `tests/release-smoke.sh` with the 0.10.32 code, including the brave→Helium
  config migration, update, rollback, startx and owned uninstall.
- `sh tests/integration.sh` covers the exact `brave` default migration and a
  custom `firefox` selection that must not change.

## Deployment

Both owner hosts were updated from 0.10.30 with the published 0.10.32 release.
The old 0.10.30 caller does not know `--browser`, so the deployment used two
update invocations: first update the installer, then run the new installer with
`--browser helium`. This is the S03 one-update gap, not a hidden manual fix.

| Host | Result |
|---|---|
| `niru@void` (Void, existing X11 session) | 0.10.32 active; existing external Helium 0.19.3.1 and profile preserved; config migrated brave→helium; `status`/`doctor` exit 0; sandboxed headless launch passed |
| `niru@thinkpad` (Arch, existing startx session) | 0.10.32 active; managed Helium 0.19.4.1 installed; config migrated brave→helium; `status`/`doctor` exit 0; sandboxed headless launch passed |

No active session was logged out. PAM, NIRUPI and the existing browser profile
were not modified. The only config change on each host was the obsolete default
browser line.

## Limits

S03 (target-installer config/integration/activation handoff), S04 (full runtime
audit) and H01 (fresh physical OS) remain open.
