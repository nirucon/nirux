# Next session — copy this prompt

Use this after restarting OpenCode. It assumes the published state recorded in
[ROADMAP.md](../ROADMAP.md) and keeps work scoped to one verified checkpoint.

```text
Läs först den aktuella planen och kontexten:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://github.com/nirucon/nirux/blob/main/docs/REVIEW-2026-10-20.md
- https://github.com/nirucon/nirux/blob/main/docs/REPOSITORIES.md

Utgå från publicerad NIRUX 0.10.16 (niruwm 0.16.20, nirubar 0.18.7). Maskinerna
niru@void och niru@thinkpad är uppdaterade. Fråga efter SSH-/sudo-uppgifter om de
behövs; spara dem aldrig i filer, commits eller dokumentation.

Fortsätt med roadmapens nästa uppgift, I07. Arbeta i små checkpoints och visa
evidens.

Krav:
- Stöd vanilla Void glibc, Debian och Arch Linux; x86_64/glibc är nuvarande release.
- Rör inte NIRUPI. Bevara användarkonfiguration, rollback-generationer och
  orelaterade systemfiler.
- Ingen bloat: inga nya obligatoriska daemons, GUI-ramverk, tjänster eller repon
  om befintliga komponenter kan lösa uppgiften.
- Läs roadmapens acceptanskriterier för I07 innan du ändrar kod.
- Kör relevanta tester: nirux tests/integration.sh, shellcheck, berörda Rust-tester,
  fmt/clippy samt Arch/Debian/Void där det är relevant.
- Committa, pusha, tagga och publicera varje avslutad checkpoint. Installera på
  niru@void och niru@thinkpad när checkpointen innehåller något att installera.
- Fråga om något är otydligt eller om en ändring kräver ett vägval.

Börja med att kontrollera git-status i berörda repon och sammanfatta:
1. vad du verifierat,
2. din plan för I07,
3. vilka filer som behöver ändras.
```

## Task reminder

**I07:** forward staging to the verified target installer through a versioned
internal handoff so new components install on the **first** update. Provision new
shared-library dependencies before running staged components. Finish the
old-installer -> synthetic new-component and missing-library fixtures before
moving to I08.
