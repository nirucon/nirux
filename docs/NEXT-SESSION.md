# Next session — read this after restarting OpenCode

Canonical raw URL:
https://raw.githubusercontent.com/nirucon/nirux/main/docs/NEXT-SESSION.md

This brief is independent of local session memory. **N1 is done; start with N2.**
The active feature order is **N2 Bluetooth → N3 built-in display profiles →
N4 power profiles → N5 nirushot** (N1 microphone is done). The first section of
[ROADMAP.md](../ROADMAP.md) defines scope and completion criteria. P1–P6 are
recorded as implemented with deferred verification; P2 remains partial.
S01/S02, S03, S04, theme/extra wallpapers, kitty/fish, the wallpaper launcher, mouse move/resize, workspace autostart, live notification themes, the power menu, greeter themes and the session welcome are done in 0.10.57.
H01 is partially complete: Debian and Arch passed fresh VMs. A fresh Void VM and physical audio/lock/suspend checks remain.

## Copy-ready prompt

```text
Fortsätt utvecklingen av NIRU-sviten. Läs först aktuella GitHub-filer:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/history/CHECKPOINT-0.10.57.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/REPOSITORIES.md

Utgå från NIRUX 0.10.57:
niruwm 0.16.54, nirubar 0.18.23, niruscreensaver 0.8.3,
nirulock 0.16.10, nirulauncher 0.2.8, nirunotify 0.3.7.
Kontrollera manifest, git-status, GitHub main och senaste fulla CI på nytt.
Versionslistan är en startpunkt, inte ett skäl att skriva över nyare arbete.

VIKTIGT: S01/S02 och S03 är klara. Target apply-protokoll 2 gör att en ny
installatör äger config, integration och aktivering; en äldre 0.10.34-caller
uppdaterar en gång till en syntetisk target med nytt config-nyckel, asset och
program. Ett injicerat fel återställer originalconfig och aktiv generation.
Helium är pinnat till 0.19.4.1 med SHA-256. CI-containrar är stödjande evidens,
inte fysisk clean-OS-certifiering.

P1 är klar. P2 har gröna icke-störande tester på båda värdarna: power-polkit,
DND, ljudnoder, display, inhibit och processöversikt. Kvar för P2 är att ägaren
är närvarande för lock/unlock, suspend/resume, hörbart ljud, faktisk poweroff
och extern skärm. Lämna P2 öppen.

N1 är klar i 0.10.57: valfri microphone-modul, mute/ingång/nivå via samma CLI,
läsning utan sidoeffekter, nivåändring som bevarar mute och tangentbordsval i
launchern. Fortsätt nu med N2.

Arbeta sedan exakt N2 → N3 → N4 → N5:
- N2: BlueZ-status och kontroll av parade Bluetooth-enheter. Börja här.
- N3: skärmprofiler INBYGGT i niructl/WM/bar/launcher, med preview och revert.
  Vänta med större nytt skärmrepo; skapa inte nirudisplay.
- N4: strömprofiler via en befintlig provider och ärlig capability-detektering.
- N5: nirushot som eget on-demand-verktyg; capture/copy/save först, sedan enkel
  crop/markering/maskning. Skapa repot först när arbetet med N5 börjar.

Läs första steg och klarkriterier för aktuell punkt innan kodändringar.
Gamla P1–P6/H01/C01–C07/R01 är krav och evidens, inte en konkurrerande arbetskö.
Ägaren har skjutit upp närvarokrävande tester. Bevara dem som öppna punkter,
markera inte P2 klar utifrån containertester och fortsätt det oberoende arbetet
enligt N1–N5.

Krav:
- Stöd vanilla Void glibc, Debian och Arch, x86_64/glibc.
- NIRUX ska installera alla svitrelaterade beroenden; inga manuella extrafixar.
- Rör inte NIRUPI. Bevara användarkonfig, egna teman, browser-val, Helium-profil
  och rollback.
- Ingen ny obligatorisk daemon, GUI-framework, tjänst eller repo när befintliga
  komponenter räcker. Använd launcher/WM/bar/niructl för små innovationer.
- Arbeta i små verifierade checkpoints med riktig evidens, en N1–N5-punkt
  åt gången. Samla närliggande småfixar inom respektive punkt och följ dess
  klarkriterier samt relevanta C01–C07-krav. Uppdatera status i roadmapen.
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

Börja med en kort sammanfattning av verifierat läge och första steget i N2 samt
vilka filer du behöver ändra. Fortsätt sedan arbetet.
```

## Current state

| Task | State | Evidence |
|---|---|---|
| S01 reproduce/fix full CI | DONE | original failure in 39406911647, green 39420180581 |
| S02 managed Helium + opt-out + sandbox | DONE | 39420180581, [checkpoint](history/CHECKPOINT-0.10.32.md) |
| W01 theme wallpapers and follow-theme | DONE | [0.10.33 checkpoint](history/CHECKPOINT-0.10.33.md) |
| W02 kitty/fish terminal integration | DONE | [0.10.41 checkpoint](history/CHECKPOINT-0.10.41.md) |
| W03 bar theme + working power actions | DONE | [0.10.41 checkpoint](history/CHECKPOINT-0.10.41.md) |
| W04 wallpaper choices in Super+Shift+P | DONE | [0.10.41 checkpoint](history/CHECKPOINT-0.10.41.md) |
| W05 mouse move/resize + autostart | DONE | [0.10.41 checkpoint](history/CHECKPOINT-0.10.41.md) |
| W06 live notification theme | DONE | [0.10.42 checkpoint](history/CHECKPOINT-0.10.42.md) |
| W07 power menu, greeters + session welcome | DONE | [0.10.44/0.10.45 checkpoint](history/CHECKPOINT-0.10.44.md) |
| P1 notification stacking + provider-aware DND | DONE | [0.10.46 checkpoint](history/CHECKPOINT-0.10.46.md) |
| P2 live acceptance | PARTIAL — owner-present tests open | [0.10.47 checkpoint](history/CHECKPOINT-0.10.47.md) |
| S03 target-owned apply | DONE | [0.10.34 checkpoint](history/CHECKPOINT-0.10.34.md) |
| S04 vanilla runtime audit | DONE | [S04 audit](history/AUDIT-S04-0.10.35.md) |
| H01 fresh OS/VM acceptance | PARTIAL — included in P2 | Debian/Arch VMs pass; fresh Void VM + physical audio/lock/suspend open |
| R01 performance/resource baseline | BASELINE | [baseline](history/AUDIT-R01-BASELINE.md); enforce after H01 |

0.10.35 updates the system module icon; S04 normal-user runtime audit is complete. A green
release workflow alone is not proof of the distro matrix; check both.
