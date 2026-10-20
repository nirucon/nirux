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

- `sh tests/integration.sh` covers the exact `brave` default migration and a
  custom `firefox` selection that must not change.
- The real pinned-release smoke, startx smoke and normal-user Helium sandbox are
  expected to remain green; the release workflow publishes only after the
  offline suite passes.
- Remote deployment to `niru@void` and `niru@thinkpad` is recorded in the
  session checkpoint after verification.

## Limits

S03 (target-installer config/integration/activation handoff), S04 (full runtime
audit) and H01 (fresh physical OS) remain open.
