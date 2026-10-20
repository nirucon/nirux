# Next session — copy this prompt

Use this after restarting OpenCode. It assumes the published state recorded in
[ROADMAP.md](../ROADMAP.md) and keeps work scoped to one verified checkpoint.

```text
Läs först den aktuella planen och kontexten:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://github.com/nirucon/nirux/blob/main/docs/REVIEW-2026-10-20.md
- https://github.com/nirucon/nirux/blob/main/docs/REPOSITORIES.md

Utgå från publicerad NIRUX 0.10.21 (niruwm 0.16.23, nirubar 0.18.8). Maskinerna
niru@void och niru@thinkpad är uppdaterade. Fråga efter SSH-/sudo-uppgifter om de
behövs; spara dem aldrig i filer, commits eller dokumentation.

Fortsätt med roadmapens nästa uppgift, U02 (responsiv bar, prioriteter,
overflow-panel och stabila workspace-celler). Arbeta i små checkpoints och visa
evidens.

Krav:
- Stöd vanilla Void glibc, Debian och Arch Linux; x86_64/glibc är nuvarande release.
- Rör inte NIRUPI. Bevara användarkonfiguration, rollback-generationer och
  orelaterade systemfiler.
- Ingen bloat: inga nya obligatoriska daemons, GUI-ramverk, tjänster eller repon
  om befintliga komponenter kan lösa uppgiften.
- Läs roadmapens acceptanskriterier för U02 innan du ändrar kod.
- Kör relevanta tester: nirux tests/integration.sh, shellcheck, berörda Rust-tester,
  fmt/clippy samt Arch/Debian/Void där det är relevant.
- Committa, pusha, tagga och publicera varje avslutad checkpoint. Installera på
  niru@void och niru@thinkpad när checkpointen innehåller något att installera.
- Fråga om något är otydligt eller om en ändring kräver ett vägval.

Börja med att kontrollera git-status i berörda repon och sammanfatta:
1. vad du verifierat,
2. din plan för U02,
3. vilka filer som behöver ändras.
```

## Task reminder

**U02:** NIRUBAR responsive layout with priorities and an overflow panel; retain
stable workspace cells. Done when 800px, 1366px and 1920px plus two-output tests
pass, hidden summaries remain accessible and hitboxes match visible geometry.
