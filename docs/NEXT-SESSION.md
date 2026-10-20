# Next session — read this after restarting OpenCode

Canonical raw URL:
https://raw.githubusercontent.com/nirucon/nirux/main/docs/NEXT-SESSION.md

This brief is independent of local session memory. **Start with S03.**
S01/S02 and the theme-wallpaper request are implemented in 0.10.33;
physical H01 acceptance and the S04 runtime audit are still open.

## Copy-ready prompt

```text
Fortsätt utvecklingen av NIRU-sviten. Läs först aktuella GitHub-filer:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/history/CHECKPOINT-0.10.33.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/REPOSITORIES.md

Utgå från NIRUX 0.10.33:
niruwm 0.16.32, nirubar 0.18.16, niruscreensaver 0.8.3,
nirulock 0.16.10, nirulauncher 0.2.1, nirunotify 0.3.3.
Kontrollera manifest, git-status, GitHub main och senaste fulla CI på nytt.
Versionslistan är en startpunkt, inte ett skäl att skriva över nyare arbete.

VIKTIGT: S01/S02 är klara. Full CI-run 39420180581 passerar Arch, Debian
Bookworm och Void glibc med riktiga pinnade releaser, doctor, config-contract,
startx, en uppdatering, rollback, owned uninstall och normal-user Helium med
sandbox. Helium är pinnat till 0.19.4.1 med SHA-256. CI-containrar är stödjande
evidens, inte fysisk clean-OS-certifiering.

Börja med S03: gör target-installer-handoffen komplett så att en äldre
installatör uppdaterar en gång till en syntetisk target som äger config,
integration och aktivering under ett versionerat protokoll. Därefter S04:
verifiera hela vanilla dependency/runtime-matrisen inklusive Helium och faktisk
normal-user-runtime. Följ H01 för fysisk/ren OS-acceptans på alla tre distros.
Läs acceptanskriterierna innan kodändringar. Implementera inte A04/bloat först.

Krav:
- Stöd vanilla Void glibc, Debian och Arch, x86_64/glibc.
- NIRUX ska installera alla svitrelaterade beroenden; inga manuella extrafixar.
- Rör inte NIRUPI. Bevara användarkonfig, egna teman, browser-val, Helium-profil
  och rollback.
- Ingen ny obligatorisk daemon, GUI-framework, tjänst eller repo när befintliga
  komponenter räcker. Använd launcher/WM/bar/niructl för små innovationer.
- Arbeta i små verifierade checkpoints med riktig evidens. Följ C01–C07.
- Committa/pusha/publicera efter varje verifierad färdig punkt enligt användarens
  stående önskemål. Installera deploybara ändringar på niru@void och
  niru@thinkpad (Arch), kontrollera före/efter. Dokumentationsändringar pushas
  utan konstgjorda binärreleaser. Skriv aldrig över publicerade taggar/assets.
- Fråga efter aktuella SSH-/sudo-uppgifter när de behövs; skriv dem aldrig i filer,
  commits, rapporter eller kommandologgar. Logga inte ut aktiva sessioner med tvång.
- Testa PAM, rena hem och avinstallation isolerat, aldrig mot produktions-PAM.
- Kör sh tests/integration.sh, shellcheck -S warning nirux tests/*.sh, relevanta
  Rust fmt/clippy/test, X11/D-Bus-regressioner, tests/release-smoke.sh,
  tests/browser-smoke.sh som normal user och riktig release-smoke på alla tre
  distros. Skilj mock, container/Xvfb och fysisk verifiering. Använd aldrig
  --no-sandbox för att få ett test att passera.

Lokala kloner kan finnas i ~/.cache/niru-work/{nirux,niruwm,nirubar}.
Lita inte på /tmp/opencode; den katalogen tömdes under tidigare arbete.
Om kloner saknas, klona från https://github.com/nirucon/<repo>.

Börja med en kort sammanfattning av verifierat läge, första steget för S03 och
vilka filer du behöver ändra. Fortsätt sedan arbetet.
```

## Current state

| Task | State | Evidence |
|---|---|---|
| S01 reproduce/fix full CI | DONE | original failure in 39406911647, green 39420180581 |
| S02 managed Helium + opt-out + sandbox | DONE | 39420180581, [checkpoint](history/CHECKPOINT-0.10.32.md) |
| W01 theme wallpapers and follow-theme | DONE | [0.10.33 checkpoint](history/CHECKPOINT-0.10.33.md) |
| S03 target-installer handoff | TODO — start here | roadmap acceptance |
| S04 vanilla runtime audit | TODO | roadmap acceptance |
| H01 fresh OS/VM acceptance | TODO | physical evidence still required |

0.10.32 added the full distro matrix to the normal CI workflow; 0.10.33 adds theme wallpapers. A green
release workflow alone is not proof of the distro matrix; check both.
