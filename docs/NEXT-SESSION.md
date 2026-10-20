# Next session — read this after restarting OpenCode

Canonical raw URL:
https://raw.githubusercontent.com/nirucon/nirux/main/docs/NEXT-SESSION.md

This brief is independent of local session memory. **Start with S01, not A04.**
Published versions are available; complete vanilla/Helium acceptance is still open.

## Copy-ready prompt

```text
Fortsätt utvecklingen av NIRU-sviten. Läs först aktuella GitHub-filer:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/REVIEW-2026-10-20-RESTART.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/REPOSITORIES.md

Utgå från publicerad NIRUX 0.10.30:
niruwm 0.16.30, nirubar 0.18.15, niruscreensaver 0.8.3,
nirulock 0.16.10, nirulauncher 0.2.1, nirunotify 0.3.3.
Kontrollera manifest, git-status, GitHub main och senaste fulla CI på nytt.
Versionslistan är en startpunkt, inte ett skäl att skriva över nyare arbete.

VIKTIGT: senaste granskningen hittade att Helium-integration saknas helt i
nirux trots tidigare samtal. Canonical browser är fortfarande brave utan
paketinstallation. Full distro-CI var röd på Arch/Debian/Void i real-release/
startx-steget. Releasepublicering var grön; det är olika tester.

Börja med S01: reproducera och diagnostisera fulla distro-CI-felet. Därefter S02:
implementera och verifiera ett uttryckligt Helium-val med beständigt opt-out,
kompletta distroberoenden, normal-user sandbox, uppdatering och owned uninstall.
Följ S03/S04 och H01 så att en enda uppdatering och vanilla installation fungerar.
Läs acceptanskriterierna innan kodändringar. Implementera inte A04/bloat först.

Krav:
- Stöd vanilla Void glibc, Debian och Arch, x86_64/glibc.
- NIRUX ska installera alla svitrelaterade beroenden; inga manuella extrafixar.
- Rör inte NIRUPI. Bevara användarkonfig, egna teman, browser-val och rollback.
- Ingen ny obligatorisk daemon, GUI-framework, tjänst eller repo när befintliga
  komponenter räcker. Använd launcher/WM/bar/niructl för små innovationer.
- Arbeta i små verifierade checkpoints med riktig evidens. Tidigare RELEASED
  betyder levererad kod, inte att alla acceptanskrav är bevisade. Följ C01–C07.
- Committa/pusha/publicera efter varje verifierad färdig punkt enligt användarens
  stående önskemål. Installera deploybara ändringar på niru@void och
  niru@thinkpad (Arch), kontrollera före/efter. Dokumentationsändringar pushas
  utan konstgjorda binärreleaser. Skriv aldrig över publicerade taggar/assets.
- Fråga efter aktuella SSH-/sudo-uppgifter när de behövs; skriv dem aldrig i filer,
  commits, rapporter eller kommandologgar. Logga inte ut aktiva sessioner med tvång.
- Testa PAM, rena hem och avinstallation isolerat, aldrig mot produktions-PAM.
- Kör sh tests/integration.sh, shellcheck -S warning nirux tests/*.sh, relevanta
  Rust fmt/clippy/test, X11/D-Bus-regressioner och riktig release-smoke på alla
  tre distros. Skilj mock, container/Xvfb och fysisk verifiering.

Lokala kloner kan finnas i ~/.cache/niru-work/{nirux,niruwm,nirubar}.
Lita inte på /tmp/opencode; den katalogen tömdes under tidigare arbete.
Om kloner saknas, klona från https://github.com/nirucon/<repo>.

Börja med en kort sammanfattning av verifierat läge, första reproduktionen
för S01 och vilka filer du behöver ändra. Fortsätt sedan arbetet.
```

## Why the next task changed

The owner requested a restart-safe review of vanilla installations and the
Helium option. The source and full CI contradict earlier completion assumptions.
The refreshed roadmap prioritises those concrete gaps before optional features.

No new mandatory repository is required by the reviewed work. Optional app
integration and conditional `nirudisplay` exploration are listed in the roadmap.
