# Next session — read this after restarting OpenCode

Canonical raw URL:
https://raw.githubusercontent.com/nirucon/nirux/main/docs/NEXT-SESSION.md

This brief is independent of local session memory. **P5 is next.**
P3 and P4 are implemented; the owner has deferred the greeter/lock/hotplug,
rendered-value and autostart edge-case tests. P2 remains partly open for
owner-present hardware checks. The active order is **P5 → P6**.
S01/S02, S03, S04, theme/extra wallpapers, kitty/fish, the wallpaper launcher, mouse move/resize, workspace autostart, live notification themes, the power menu, greeter themes and the session welcome are done in 0.10.54.
H01 is partially complete: Debian and Arch passed fresh VMs. A fresh Void VM and physical audio/lock/suspend checks remain.

## Copy-ready prompt

```text
Fortsätt utvecklingen av NIRU-sviten. Läs först aktuella GitHub-filer:
- https://raw.githubusercontent.com/nirucon/nirux/main/ROADMAP.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/history/CHECKPOINT-0.10.54.md
- https://raw.githubusercontent.com/nirucon/nirux/main/docs/REPOSITORIES.md

Utgå från NIRUX 0.10.54:
niruwm 0.16.51, nirubar 0.18.21, niruscreensaver 0.8.3,
nirulock 0.16.10, nirulauncher 0.2.5, nirunotify 0.3.7.
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

P3 är påbörjad i 0.10.54: docs/STYLE.md, fontanpassade launcher-rader med
accentmarkering, WELCOME_NOTIFICATION=always|once|off, niructl audio för
utgång/mikrofon/mute/volym samt NIRUBARs displaymodul för flera skärmar.
NIRUBAR, NIRULAUNCHER och NIRUNOTIFY har nu rendered-value-tester för temafärger.
Fortsätt P3 med greeters och lock samt den kompletta småskärms-/hotplug-matrisen.
P4: tillförlitlig workspace-autostart även för långsamma appar.
P5: förklara saknade funktioner och fel i launchern via doctor/niructl.
P6: arbetslägen och workspace-recept ovanpå P4/P5.

Läs första steg och klarkriterier för aktuell punkt innan kodändringar.
Gamla H01/C01–C07/R01 är krav och evidens, inte en konkurrerande arbetskö.
Dokumentera exakt blockerare om fysisk hårdvara saknas; markera inte P2 klar
utifrån containertester. Fortsätt då oberoende P3-arbete enligt roadmapen.

Krav:
- Stöd vanilla Void glibc, Debian och Arch, x86_64/glibc.
- NIRUX ska installera alla svitrelaterade beroenden; inga manuella extrafixar.
- Rör inte NIRUPI. Bevara användarkonfig, egna teman, browser-val, Helium-profil
  och rollback.
- Ingen ny obligatorisk daemon, GUI-framework, tjänst eller repo när befintliga
  komponenter räcker. Använd launcher/WM/bar/niructl för små innovationer.
- Arbeta i små verifierade checkpoints med riktig evidens, en P1–P6-punkt
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

Börja med en kort sammanfattning av verifierat läge, första steget i P5 och
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
