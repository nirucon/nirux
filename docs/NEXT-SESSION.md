# Next session — copy this prompt

Use this after restarting OpenCode. It assumes the published state recorded in
[ROADMAP.md](../ROADMAP.md) and keeps work scoped to one verified checkpoint.

```text
Läs först den aktuella planen och kontexten:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://github.com/nirucon/nirux/blob/main/docs/REVIEW-2026-10-20.md
- https://github.com/nirucon/nirux/blob/main/docs/REPOSITORIES.md

Utgå från publicerad NIRUX 0.10.15 (niruwm 0.16.20, nirubar 0.18.7). Maskinerna
niru@void och niru@thinkpad är uppdaterade. Fråga efter SSH-/sudo-uppgifter om de
behövs; spara dem aldrig i filer, commits eller dokumentation.

Fortsätt med roadmapens nästa uppgift, I06, och sedan I07 om I06 är klar och
verifierad. Arbeta i små checkpoints och visa evidens.

Krav:
- Stöd vanilla Void glibc, Debian och Arch Linux; x86_64/glibc är nuvarande release.
- Rör inte NIRUPI. Bevara användarkonfiguration, rollback-generationer och
  orelaterade systemfiler.
- Ingen bloat: inga nya obligatoriska daemons, GUI-ramverk, tjänster eller repon
  om befintliga komponenter kan lösa uppgiften.
- Läs roadmapens acceptanskriterier för I06/I07 innan du ändrar kod.
- Kör relevanta tester: nirux tests/integration.sh, shellcheck, berörda Rust-tester,
  fmt/clippy samt Arch/Debian/Void där det är relevant.
- Committa, pusha, tagga, publicera eller deploya INTE utan att jag uttryckligen ber
  om det. Fråga om något är otydligt eller om en ändring kräver en ny release.

Börja med att kontrollera git-status i berörda repon och sammanfatta:
1. vad du verifierat,
2. din plan för I06,
3. vilka filer som behöver ändras.
```

## Task reminder

**I06:** make configuration migration safe for the supported TOML subset. Stop
rather than damage unsupported input, preserve user values and permissions, and
validate a staged candidate with both components before activation. No mandatory
Python/TOML runtime just for migration. Finish its acceptance before I07.
