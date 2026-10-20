# Next session — copy this prompt

Use this after restarting OpenCode. It assumes the published state recorded in
[ROADMAP.md](../ROADMAP.md) and keeps work scoped to one verified checkpoint.

```text
Läs först den aktuella planen och kontexten:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://github.com/nirucon/nirux/blob/main/docs/REVIEW-2026-10-20.md
- https://github.com/nirucon/nirux/blob/main/docs/REPOSITORIES.md

Utgå från publicerad NIRUX 0.10.19 (niruwm 0.16.21, nirubar 0.18.7). Maskinerna
niru@void och niru@thinkpad är uppdaterade. Fråga efter SSH-/sudo-uppgifter om de
behövs; spara dem aldrig i filer, commits eller dokumentation.

H03 är IN_PROGRESS: suspend/resume, lock-cover, native notification privacy,
locked resize och logout-cleanup är verifierade. Lid close och fysisk extern
skärm återstår och kräver att användaren är vid maskinerna. Slutför dessa när de
är tillgängliga; fortsätt annars med U01 (WM/bar config validation contract).
Arbeta i små checkpoints och visa evidens.

Krav:
- Stöd vanilla Void glibc, Debian och Arch Linux; x86_64/glibc är nuvarande release.
- Rör inte NIRUPI. Bevara användarkonfiguration, rollback-generationer och
  orelaterade systemfiler.
- Ingen bloat: inga nya obligatoriska daemons, GUI-ramverk, tjänster eller repon
  om befintliga komponenter kan lösa uppgiften.
- Läs roadmapens acceptanskriterier för H03/U01 innan du ändrar kod.
- Kör relevanta tester: nirux tests/integration.sh, shellcheck, berörda Rust-tester,
  fmt/clippy samt Arch/Debian/Void där det är relevant.
- Committa, pusha, tagga och publicera varje avslutad checkpoint. Installera på
  niru@void och niru@thinkpad när checkpointen innehåller något att installera.
- Fråga om något är otydligt eller om en ändring kräver ett vägval.

Börja med att kontrollera git-status i berörda repon och sammanfatta:
1. vad du verifierat,
2. din plan för H03-resten eller U01,
3. vilka filer som behöver ändras.
```

## Task reminder

**H03 remaining:** lid close/open on ThinkPad and external output attach/remove
on Void. Do not claim these until performed physically. If the owner is not at
the machines, proceed with **U01**: WM/bar config validation contract, invalid
values, hidden modules, stale vs zero data, and bounded hardware helpers.
