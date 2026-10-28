# NIRUSOUND — tillfällig agentinstruktion

> **TILLFÄLLIG FIL.**
> När hela uppdraget är implementerat, testat, mergat och pinat i NIRUX ska
> denna fil raderas av agenten. Se **Slutsteg** längst ner.

Du arbetar med ljudfunktionerna i NIRUX-sviten. Målet är en liten, snabb och
snygg ljudpanel som känns som en del av NIRUX – inte en stor mixer.

Läs först:

- `README.md`
- `docs/STYLE.md`
- `docs/INSTALL.md`, särskilt avsnittet **Audio and microphone**
- `config.example.toml`
- `manifest`

---

## 1. Målbild

Användaren ska kunna:

1. Öppna en ljudpanel från `Super+Shift+P` genom att skriva `sound`, `audio`,
   `mic` eller `volume`.
2. Se och ändra:
   - aktuell utgång
   - utgångsvolym och mute
   - aktuell mikrofon
   - mikrofonnivå och mute
   - aktiva ljudströmmar/appar
3. Göra ett **mikrofontest** som visar om signalen är för svag, lagom eller
   klipper.
4. Snabbt mute:a eller justera mikrofonen från NIRUBAR och launchern.
5. Få NIRUX-temats färger automatiskt, utan hårdkodade paletter.

MVP ska vara en **kompakt GUI-panel i `nirulauncher`**. Bygg inte en separat
stor app i första steget.

---

## 2. Icke-mål

Bygg inte:

- en full `pavucontrol`-klon
- en PipeWire-patchbay eller graf över alla noder
- en egen ljudserver
- en ny global shortcut om `Super+Shift+P` eller `Super+A` redan räcker
- en separat TUI innan backend och launcherpanel fungerar
- en ny app/repo innan panelen faktiskt har vuxit ur launcherns ansvar

Avancerad routing ska även fortsättningsvis kunna skötas av `qpwgraph`,
`pavucontrol` eller motsvarande om användaren installerar det separat.

---

## 3. Nuvarande grund

NIRUX har redan:

- `niructl audio outputs`
- `niructl audio sources`
- `niructl audio output ID`
- `niructl audio source ID`
- `niructl audio mute`
- `niructl audio mic-status`
- `niructl audio mic-mute on|off|toggle`
- `niructl audio mic-level up|down|set N`
- `nirubar` med en `microphone`-modul
- `nirulauncher --microphone`
- `Super+Shift+P` som unified launcher
- NIRU Actions via `Super+A`

Använd detta. Duplicera inte logiken i tre komponenter.

På den aktuella HP ZBook-maskinen ligger en fungerande mikrofon på ungefär:

```text
wpctl source volume: 0.30
ALSA Capture:        97 %
Internal Mic Boost:   0 dB
```

Det är en **uppmätt referens**, inte en universell sanning. Sätt inte 0.9
blint: WirePlumber kan då mappa om till 100 % capture + 20 dB boost och
överstyra ingången.

---

## 4. Repon och ansvar

Arbeta i komponentreporna, inte bara i NIRUX-metarepot:

| Repo | Ansvar |
|---|---|
| `nirux` | dokumentation, manifest, suite-pin och release |
| `niruwm` | `niructl`, inklusive `audio`-backend |
| `nirubar` | `microphone`-modulen och popup/status |
| `nirulauncher` | `--sound`-panelen och actions |

Klona till exempel:

```sh
git clone https://github.com/nirucon/niruwm
git clone https://github.com/nirucon/nirubar
git clone https://github.com/nirucon/nirulauncher
```

Följ respektive repos README, `Cargo.toml` och tester. Använd inte force-push.

---

## 5. MVP: `nirulauncher --sound`

Lägg till en ny launcher-vy:

```sh
nirulauncher --sound
```

Den ska följa samma visuella och tekniska mönster som
`--microphone`, `--bluetooth`, `--power` och `--displays`.

### Innehåll

```text
Output
  aktuell utgång
  volym
  mute
  lista över utgångar

Input
  aktuell mikrofon
  gain
  mute
  live-nivå
  [Test microphone]

Applications
  aktiva ljudströmmar
  appnamn
  riktning (input/output)
  volym/mute där det är rimligt
```

### Tangentbord och layout

- Fungerar i 800×600 och större.
- Tydlig fokusmarkering enligt `docs/STYLE.md`.
- Escape stänger.
- Enter/Space aktiverar.
- Tab/Shift+Tab går mellan kontroller.
- Inga dolda kontroller utanför skärmen.
- Mus och tangentbord ska ge samma resultat.

### Launcher-actions

Lägg till actions som dyker upp i `Super+Shift+P` och `Super+A`:

```text
Audio
  Open Sound…
  Mute output
  Mute microphone
  Microphone level +
  Microphone level -
  Test microphone…
```

Sökning ska matcha `sound`, `audio`, `mic`, `microphone`, `volume` och `mute`.

---

## 6. Mikrofontest

Testet är en central del av uppdraget.

### Beteende

1. Användaren väljer **Test microphone**.
2. En kort inspelning görs, exempelvis 5 sekunder.
3. Panelen visar:
   - peak
   - RMS
   - om signalen klipper
   - en enkel bedömning: `too quiet`, `good`, `too hot`
4. Användaren kan lyssna på inspelningen.
5. Tempfilen raderas när panelen stängs eller testet avslutas.
6. Inget skickas över nätverket.

### Teknik

- Använd `pw-record`, `arecord` eller motsvarande som redan finns i NIRUX.
- Undvik att kräva `ffmpeg` om det inte redan är en del av NIRUX.
- En enkel WAV-läsare i Rust räcker för peak/RMS.
- Allt ska ha timeout och ett tydligt felmeddelande om PipeWire saknas.
- Inspelning får aldrig starta utan att användaren uttryckligen valt testet.

### Rekommendation

Visa hellre:

```text
Peak: -10 dBFS · no clipping · good
```

än enbart en procentsiffra, eftersom `wpctl`-procenten inte är samma sak som
hårdvarans gain.

---

## 7. Backend

Utöka `niructl` där det behövs, men behåll ett enda backend.

Föreslagna stabila kommandon:

```sh
niructl audio status --json
niructl audio outputs --json
niructl audio sources --json
niructl audio input ID
niructl audio mic-status --json
niructl audio mic-level set N
niructl audio mic-test 5 --json
```

Krav:

- JSON-formatet ska vara stabilt och dokumenterat.
- `nirulauncher` och `nirubar` ska inte behöva parsa intern Rust-struktur.
- Kommandon ska ha rimliga timeouts.
- Inga shell-strängar med användardata.
- Fungera utan ljudserver: visa `unavailable`, krascha inte.
- Använd `wpctl`/PipeWire. `pactl` finns inte i basinstallationen.

`nirulauncher` får anropa `niructl` eller en gemensam modul, men reglerna för
mute, source-val och gain ska finnas på ett ställe.

---

## 8. NIRUBAR

`microphone`-modulen finns redan. Gör följande:

- verifiera att den fungerar med aktuell `niructl audio`
- se till att vänsterklick visar information
- högerklick mute
- scroll justerar gain utan att unmuta
- middle click öppnar `nirulauncher --microphone`
- lägg till `microphone` i dokumentationen och `config.example.toml`
- ändra inte användarens `~/.config/niruwm/config.toml` utan att fråga

Om modulen saknar något, komplettera den i `nirubar`, inte med en ny
ljudpanel i baren.

---

## 9. NIRUX-tema

Använd den befintliga temahanteringen. Hårdkoda inte färger.

Källor:

```text
~/.config/niruwm/appearance.toml
~/.config/niruwm/config.toml
niructl theme-catalog --json
```

Använd semantiska roller enligt `docs/STYLE.md`:

```text
background, surface, foreground, muted, border,
focus/accent, selected, success, warning, error, disabled
```

Krav:

- Panelen följer aktivt NIRUX-tema.
- Temabyte ska slå igenom utan att starta om hela sessionen.
- Ljus kontrast ska fungera för ljusa teman som Carl Larsson.
- Färg får inte vara enda informationsbärare; visa även text/ikon.
- Testa minst `niru-forest-vigil` och `niru-carl-larsson`.

---

## 10. Säkerhet och integritet

- Ingen ljudinspelning utan explicit användaråtgärd.
- Ingen automatisk uppladdning.
- Tempinspelningar ska raderas.
- Inga lösenord, tokens eller ljudfiler i loggar.
- Inga shell-kommandon med användardata.
- Ingen root behövs.
- Misslyckad PipeWire-anslutning får inte lämna en hängande process.
- Testa med både mikrofon och utgång frånkopplad.

---

## 11. Acceptanskriterier

MVP är klar när:

- [ ] `nirulauncher --sound` öppnas och stängs korrekt.
- [ ] Output, Input och Applications visas.
- [ ] Volym, mute och source byte fungerar.
- [ ] Mikrofonens gain kan ändras.
- [ ] `Test microphone` spelar in, visar peak/RMS/klippning och raderar tempfilen.
- [ ] `Super+Shift+P` hittar `sound`, `mic`, `audio`, `volume` och `mute`.
- [ ] `Super+A` visar relevanta ljudactions.
- [ ] `microphone`-modulen fungerar i NIRUBAR.
- [ ] Panelen följer NIRUX-temats färger.
- [ ] Panelen fungerar vid 800×600.
- [ ] Alla berörda Rust-tester, formattering och byggen är gröna.
- [ ] `nirubar --check-config` och `nirulauncher --check-config` är gröna.
- [ ] `nirux status`/`nirux doctor` visar en frisk installation.
- [ ] Dokumentationen i `docs/INSTALL.md` och README är uppdaterad.
- [ ] Inga hemligheter, tempfiler eller testinspelningar finns i git.

---

## 12. TUI

TUI är **inte** en del av MVP.

Om GUI-panelen senare visar sig otillräcklig får en TUI byggas som ett tunt
alternativt gränssnitt, exempelvis:

```sh
nirusound --tui
```

Den ska då använda samma `niructl audio`-backend och samma regler. Bygg inte en
andra ljudimplementation.

En TUI ska inte försöka visa en PipeWire-graf. Avancerad routing hänvisas till
`qpwgraph`/`pavucontrol`.

---

## 13. Release och pinning

När komponenterna är klara:

1. Kör respektive repos tester.
2. Bygg release-binärer enligt repoinstruktionerna.
3. Publicera komponentreleaser.
4. Uppdatera `manifest` i NIRUX med de nya versionerna.
5. Uppdatera `README.md`, `docs/INSTALL.md` och `config.example.toml` vid behov.
6. Verifiera att NIRUX installerar de nya binärerna.
7. Kör `nirux doctor` och manuell test i en riktig X11-session.

Ingen force-push. Ingen överskriven release.

---

## 14. Slutsteg — radera denna fil

När **alla** acceptanskriterier är uppfyllda och ändringarna är mergade och
pinade:

1. Kontrollera att det inte finns några kvarvarande TODOs i denna fil.
2. Radera `docs/AGENT-NIRUSOUND.md` i NIRUX-repot.
3. Ta bort eventuella kopior av denna instruktion i komponentreporna.
4. Committa borttagningen:

```sh
git add -A docs/AGENT-NIRUSOUND.md
git commit -m "docs: remove completed NIRUSOUND agent instruction"
git push
```

5. Verifiera att filen är borta:

```sh
test ! -e docs/AGENT-NIRUSOUND.md
git grep -n "AGENT-NIRUSOUND" || true
```

Radera **inte** kod, dokumentation eller releaseanteckningar. Endast denna
tillfälliga agentinstruktion ska bort.

Om något är ofullständigt eller testarna inte är gröna: lämna filen kvar och
rapportera exakt vad som återstår.

---

## 15. Startprompt

```text
Läs docs/AGENT-NIRUSOUND.md och följ den. Börja med att inspektera niructl
audio, nirubar microphone och nirulauncher --microphone. Implementera MVP:
nirulauncher --sound, actions i Super+Shift+P/Super+A, mikrofontest och
NIRUX-temastöd. Ändra inte användarens config. Kör testerna i varje berört repo.
När allt är mergat och pinat: radera docs/AGENT-NIRUSOUND.md och committa
borttagningen.
```
