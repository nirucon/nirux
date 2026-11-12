# The launcher

NIRU Launcher (`nirulauncher`) is the keyboard entry point to NIRUX: applications, windows, NIRU Actions, files, emoji, web search, clipboard history, colours and every settings view. This chapter covers each view, the keys inside the launcher, the typed shortcuts (`/`, `:`, phrases, arithmetic), the command-line options and the configuration.

## Open the launcher

| Keys | Opens | Command |
|---|---|---|
| `Super+P` | Applications | `nirulauncher --apps` |
| `Super+Shift+P` (also `Super+Shift+B`, `Super+Shift+M`) | Unified view: applications, windows, actions and settings | `nirulauncher --actions` |
| `Super+A` | NIRU Actions | `nirulauncher --system-actions` |
| `Super+S` | Web search | `nirulauncher --search` |
| `Super+V` | Clipboard history | `nirulauncher --clipboard` |
| `Super+O` | Find files in the home folder | `nirulauncher --files` |
| `Super+.` | Emoji and symbols | `nirulauncher --emoji` |
| `Super+/` or `Super+F1` | Keybinding cheat sheet | `nirulauncher --keys` |
| `Super+Shift+F1` | The NIRUX manual | `nirulauncher --manual` |
| `Super+W`, `Alt+Tab`, `` Super+` `` | Window switcher | `nirulauncher --windows` |

On Swedish, German and similar layouts `/` is `Shift+7`, so `Super+/` is the workspace 7 key there; use `Super+F1` for the cheat sheet.

The launcher is one process per opening. It has no daemon, no index service and makes no network requests of its own.

## Keys inside the launcher

| Keys | Action |
|---|---|
| Type | Filter the rows |
| `Up` / `Down`, `Tab` / `Shift+Tab` | Move the selection |
| `PageUp` / `PageDown` | Page |
| `Home` / `End` | First / last row |
| Mouse wheel, click | Scroll, activate a row |
| `Enter` | Open or run the selected row |
| `Escape` | Close (or cancel a prompt) |
| `Backspace`, `Ctrl+Backspace` | Delete a character, a word |
| `Ctrl+P` | Pin or unpin the row as a favourite |
| `Ctrl+S` | Save an application or command row as a NIRU Action |

Dead keys compose (`´` then `e` gives `é`), AltGr levels follow the XKB layout, and Swedish letters work. Every view paints at once: rows that need a provider show "…" until they arrive, and `Enter` pressed before that acts on the best match so far.

## Start an application

Press `Super+P` and type part of the name. Matching:

- takes several words in any order;
- reads the `.desktop` `Keywords`, `GenericName` and `Comment` (a row found by a keyword shows that word dimmed);
- ignores diacritics (`e` finds `é`, `a` finds `å` and `ä`) but ranks exact text first;
- adds a conservative fuzzy match after exact, prefix and word matches.

Favourites come first. Among equally good matches, rows launched often and recently come first (history in `~/.local/state/nirulauncher/usage.tsv`, last 500 launches). With an empty field, up to five recent rows (marked ↺) follow the favourites.

`Exec` lines are run as argument lists, never through a shell. Applications with `Terminal=true` start in the configured `terminal`.

When nothing matches, the launcher says so; press `Tab` to send the same text to web search.

## Use the unified view

`Super+Shift+P` shows applications, open windows, NIRU Actions and settings in one list. Type to search across all of them. The typed prefixes below also work here (and in `Super+P` and `Super+A`).

| You type | You get |
|---|---|
| `firefox` | Applications, windows and actions that match |
| `/ faktura` | Files in the home folder (see below) |
| `:heart` | The best eight emoji and symbols |
| `2+2*3` | A calculator row |
| `lock`, `fokusläge` | Intent rows (see below) |

On Swedish layouts type `/` as `Shift+7`.

## Switch windows

`Super+W`, `Alt+Tab` or `` Super+` `` opens the window switcher. Type to filter the open windows, then `Enter` switches to the selected one.

## Jump to a window

`Ctrl+Alt+W` puts a short label on every visible window on every screen. Type a label and that window gets the focus, and the pointer moves there. `Escape`, a click or a key that matches no label closes the labels.

Labels are letters, home row first (`a`, `s`, `d`, …), or numbers:

```toml
# ~/.config/nirulauncher/config.toml
[hints]
style = "letters"        # or "numbers"
```

With more windows than one character can name, every label gets two characters, so a window is chosen the moment its label is complete. From a terminal: `nirulauncher --hints`.

## Quick note

`Super+Shift+N` opens one line. Type the note and press `Enter`: it is added to the inbox, a Markdown file that NIRUNOTE (or any editor) opens, as `- 2026-11-12 09:41 your note`.

Below the line, the rows choose where the note also goes. The first row keeps it local. When NIRUSHARE is installed, there is a row for each Discord webhook and each trusted device. Pick one with `↑` and `↓` before `Enter`.

```toml
# ~/.config/nirulauncher/config.toml
[note]
file = "~/Notes/inbox.md"
```

From a terminal: `nirulauncher --note`.

## NIRU Actions

`Super+A` opens the NIRU Actions catalogue: practical system actions grouped as System, Display, Power, Appearance, Wallpaper, Wi-Fi, Workspaces, Windows and NIRUX Settings. The same entries are in the unified view.

It includes, among others:

- output volume and mute, input sources, microphone mute and gain, a five-second microphone test, active audio streams;
- Bluetooth device actions;
- display profiles (preview, keep, revert), arrange side by side, a "turn this screen" entry for each rotation, and NIRU Display when installed;
- power profiles, layouts with their shortcuts, theme selection and a compositor toggle;
- NIRU Wallpaper, and the optional colour wallpaper packs when NIRUX is installed;
- settings history: undo the last settings change, the history list, what differs from the defaults, and resetting the bar;
- focus and presentation work modes with a timer, workspace recipes;
- storage review (read-only), off-screen window recovery, recent tasks, diagnostics, installed/running status;
- **Studio mode** and **Window swallowing** with their current state;
- confirmed session actions (log out, reboot, shut down, update and restart, update and shut down).

The list is alphabetical with up to five pinned favourites first. Informational actions that run in a terminal (storage review, task history, diagnostics) keep the terminal open until you press `Enter`.

When `opencode` is installed, **Ask OpenCode…** hands a prompt to OpenCode in a terminal through `niructl agent`. It never auto-approves, never installs OpenCode and keeps OpenCode's own permissions. `nirulauncher --agent` (also the bar's `agent` module) is the short form: type one prompt, `Enter` opens a centred floating terminal.

More on actions, tasks and OpenCode: [docs/ACTIONS.md](https://github.com/nirucon/nirux/blob/main/docs/ACTIONS.md).

### Save your own actions

Select an application or command row and press `Ctrl+S`, or save an argument list from a terminal:

```sh
niructl action save "Night desk" -- niructl nightlight on
niructl action list
niructl action run "Night desk"
niructl action pin "Night desk"
niructl action rename "Night desk" "Evening"
niructl action delete "Evening"
```

Saved actions live in `~/.config/niruwm/actions.toml`, run without a shell, and appear under **Saved actions** in `Super+A` and `Super+Shift+P` and in normal search. An existing name gets a numeric suffix instead of being overwritten.

## Type a phrase (intents)

Type an exact phrase in `Super+P`, `Super+Shift+P` or `Super+A` and up to three **Intent** rows appear above the normal results. Case, extra spaces and punctuation are ignored. A phrase never becomes a shell command.

| Action | English | Swedish |
|---|---|---|
| Lock | `lock`, `lock screen` | `lås`, `lås skärmen` |
| Log out | `logout` | `logga ut` |
| Reboot | `reboot` | `starta om` |
| Shut down | `shutdown` | `stäng av` |
| Focus mode | `focus mode` | `fokusläge` |
| Presentation mode | `presentation mode` | `mötesläge` |
| Stop context | `stop context` | `avsluta läge` |
| Do Not Disturb | `dnd`, `do not disturb` | `stör ej` |
| Keep awake | `keep awake` | `håll vaken` |
| Volume up / down | `volume up`, `volume down` | `höj volymen`, `sänk volymen` |
| Mute output | `mute` | `ljud av` |
| Mute microphone | `mic mute` | `mikrofon av` |
| Brightness up / down | `brightness up`, `brightness down` | `ljusare`, `mörkare` |
| Night light | `night light` | `nattljus` |
| Compositor | `compositor` | |
| Studio mode | `studio mode`, `daw mode`, `recording mode` | `studioläge`, `inspelningsläge` |
| Window swallowing | `window swallowing`, `swallow` | `fönstersväljning`, `svälj fönster` |
| Restore windows | `bring off-screen windows back` | `hämta tillbaka fönster` |
| Wi-Fi on / off | `wifi on`, `wifi off` | `slå på wifi`, `stäng av wifi` |

Wi-Fi on/off needs NetworkManager (`nmcli`); without it the row says it is unavailable.

## Calculate

Type an arithmetic expression such as `2+2*3`, `(1920/1080)` or `15% of 240`. A `= result` row appears first; `Enter` copies the result (needs `xclip`). Only numbers, `+ - * / ^`, parentheses and percentages are evaluated.

## Find files

Press `Super+O`, or type `/` and a name in `Super+P`, `Super+Shift+P` or `Super+A` (`/ faktura`, `/kvitto 2024`).

- An empty field (or a lone `/`) lists recently used files from `~/.local/share/recently-used.xbel`, newest first, marked ↺.
- Words match in any order, in the file name or its folders, ignoring case and diacritics (`faktura aao` finds `faktura-åäö.pdf`).
- Hidden files and folders are skipped, and so are `.cache`, the trash, `.git`, `node_modules`, `target`, `__pycache__`, `.venv` and similar.

| Keys | Action |
|---|---|
| `Enter` | Open with `xdg-open` |
| `Ctrl+Enter` | Open the containing folder |
| `Shift+Enter` or `Ctrl+C` | Copy the path |

The search uses `plocate` (or mlocate's `locate`) when its database covers your home folder, then `fd`/`fdfind`, then a bounded built-in walk. It stops after 1.5 seconds and shows what it found; the footer names the backend and the time. A `locate` database only knows files from its last `updatedb` run. For scripts: `nirulauncher --list-files WORDS`.

## Insert emoji and symbols

Press `Super+.`, or type `:` and a name in the other views (`:heart`, `:tummen`). About 1 900 emoji and 85 text symbols (©, ®, ™, arrows, °, ±, ×, currency, typographic quotes, no-break space) with English and Swedish names. Recently used ones come first.

| Keys | Action |
|---|---|
| `Enter` | Paste into the window you were typing in, then restore your clipboard |
| `Shift+Enter` | Copy only |
| `Tab` / `Shift+Tab` | Cycle the skin tone (remembered) |

Terminals get `Ctrl+Shift+V` (xterm-like ones `Shift+Insert`). If nothing accepts the paste, the emoji stays on the clipboard. Colour emoji need Noto Color Emoji.

## Search the web

Press `Super+S` (or `nirulauncher --search "phrase"`). Every enabled engine is listed at once; type a phrase and each row becomes a ready search. `Up`/`Down` or `Tab` picks the engine, `Enter` opens it in the browser. A typed `http://` or `https://` address becomes **Open address**.

An alias and a space searches one engine directly: `gh niruwm`, `aw pipewire`, `yt darkthrone`.

| Alias | Engine | Alias | Engine |
|---|---|---|---|
| `ddg` | DuckDuckGo | `crate` | crates.io |
| `brave` | Brave Search | `docs` | docs.rs |
| `g` | Google | `gpt` | ChatGPT |
| `w` | Wikipedia (English) | `gem` | Gemini |
| `wsv` | Wikipedia (Swedish) | `grok` | Grok |
| `yt` | YouTube | `cop` | Microsoft Copilot |
| `gh` | GitHub | `disc` | Discogs |
| `aw` | ArchWiki | `mb` | MusicBrainz |
| | | `ma` | Metal Archives |

The AI engines open their web app with your phrase in the prompt; they may need a signed-in account and may not send it automatically. The browser is `browser` in the launcher config, else NIRUWM's `browser`, else `$BROWSER`, else `xdg-open`. `nirulauncher --list-search` prints every engine.

## Use clipboard history

Press `Super+V`. The list shows recent text clipboard entries from `~/.local/state/niru/clipboard.json` (kept locally, at most 200 entries, obvious secrets filtered, never uploaded). Type to filter; `Enter` copies the entry back to the clipboard, then paste it as usual.

## Pick and reuse colours

`nirulauncher --colors` (or **Colors** in NIRU Actions) lists the last ten colours picked with `nirushot pick` (`Super+Ctrl+C`), newest first, with a swatch. `Enter` copies the hex value. **Pick color** starts the picker. See [07-screenshots-and-recording.md](07-screenshots-and-recording.md).

## Settings views

Each settings view is a front end over the same `niructl`, `nirux` and system providers the rest of NIRUX uses. A missing or too old provider shows "unavailable" instead of pretending.

| Option | View |
|---|---|
| `--quick` | Quick Settings (see [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)) |
| `--settings` | NIRUX Settings: Appearance and themes, Wallpaper, Displays, Audio, Keybindings, Input devices, Idle and lock timing, Wi-Fi |
| `--wifi` | Wi-Fi: radio, connected network, saved and scanned networks. `Enter` connects or disconnects, `Ctrl+R` rescans. Passwords are typed into the launcher and never put in a command line or log |
| `--wired` | Wired Ethernet: link, address, speed; connect or disconnect one interface (NetworkManager), read-only otherwise |
| `--bluetooth` | Bluetooth devices and power |
| `--tailscale` | Tailscale peers |
| `--displays` | Display profiles with preview, keep and revert, rotation |
| `--power` | Power profiles |
| `--themes` | Theme list; `Enter` applies |
| `--sound` | Outputs, inputs, streams, event sounds and per-app notification sounds |
| `--microphone` | Input source, mute, gain and a microphone test |
| `--timing` | Idle, lock and display-off minutes; `Enter` on a value lets you type new minutes |
| `--input` | Keyboard layout and repeat, pointer settings, reset |
| `--keys` | Keybinding cheat sheet |
| `--clip` | NIRUCLIP capture profiles, camera check and preview, export, share, recovery |
| `--share`, `--share-pair` | NIRUSHARE devices, inbox, pairing and Discord webhooks |
| `--health` | Installed/running, session, audio, network, display and capture status |

Wi-Fi works through NetworkManager or standalone `wpa_supplicant`; iwd and ConnMan are detected but not controlled.

### Keybinding cheat sheet

`Super+/` or `Super+F1` lists every key in effect: NIRUWM's defaults, your own `[[keys]]` (with their `description`) and keys other programs register. It is grouped.

| Keys | Action |
|---|---|
| Type words (`scratchpad`) or a key (`super+t`, `ctrl alt space`) | Search |
| Type `conflict` | List keys claimed twice |
| `Enter` | Run the selected binding, as if the key were pressed |
| `Ctrl+R`, then a key combination | Tell what that key does, or that it is free |

## Read this manual

*(nirulauncher 0.10.0 and later)*

Press `Super+A` and type `manual` (or `help`, `hjälp`), or run:

```sh
nirulauncher --manual
```

The view lists the chapters and headings of the installed manual and searches across headings and text. `Enter` opens the chapter at that heading through `nirux manual TOPIC`.

## Command-line options

`nirulauncher` with no option opens application search. Interactive views:

```text
--apps  --actions  --system-actions  --windows (alias --overview)  --search [PHRASE]
--quick  --clipboard  --keys  --emoji  --colors  --files  --settings
--themes  --displays  --power  --timing  --input
--wifi  --wired  --bluetooth  --tailscale  --sound  --microphone
--clip  --share  --share-pair  --health  --agent  --note  --hints
```

Non-interactive helpers for scripts:

| Option | Prints |
|---|---|
| `--list` | Installed applications (name and desktop ID) |
| `--list-actions` | The action catalogue |
| `--list-search` | Web engines: ids, labels, templates and hosts |
| `--list-files [QUERY]` | File search results (kind, tab, path) |
| `--wifi-status`, `--wifi-scan` | Wi-Fi state, with or without a fresh scan |
| `--wired-status` | Wired interfaces |
| `--check-config` | Validates `~/.config/nirulauncher/config.toml` |
| `--version` | The version |

## Configure the launcher

Settings live in `~/.config/nirulauncher/config.toml`; every key is optional. Colours and font come from the NIRUX theme in `~/.config/niruwm/config.toml`.

| Key | Default | Meaning |
|---|---|---|
| `width` | `640` | Window width in pixels, clamped to the monitor |
| `max_rows` | `12` | Visible result rows |
| `row_height` | `26` | Row height in pixels |
| `padding` | `12` | Inner padding in pixels |
| `font_size` | `15.0` | Font size; `font_path` picks a font file |
| `terminal` | `["kitty"]` | For `Terminal=true` applications |
| `browser` | unset | Web search browser (falls back as described above) |
| `favorites` | `[]` | Desktop-file IDs or action names pinned on top |
| `rank_by_usage` | `true` | Order equal matches by launch history; show recent rows |

```toml
favorites = ["firefox.desktop", "Lock screen"]

[search]
default = "duckduckgo"
order = ["duckduckgo", "github", "archwiki", "wikipedia"]
aliases = { gh = "github", aw = "archwiki", yt = "youtube" }

[[search.sources]]          # add an engine, or replace a built-in by id
id = "searx"
label = "SearXNG (home)"
url = "https://searx.example/search?q={query}"
alias = "sx"

[[search.sources]]          # turn a built-in off
id = "grok"
enabled = false

[files]
enabled = true              # false hides file search and the / prefix
roots = ["~"]
backend = "auto"            # auto, plocate, locate, fd, builtin
max_results = 50
show_hidden = false
# locate_db = "~/.cache/files.db"
# exclude = [".cache", ".local/share/Trash", ".git", "node_modules", "target"]
```

`{query}` is replaced by the percent-encoded phrase; only `http` and `https` addresses are opened. `exclude` replaces the built-in list. Favourites pinned with `Ctrl+P` (at most five) are stored in `~/.local/state/nirulauncher/favorites.tsv`.

On HiDPI screens the launcher reads `Xft.dpi` and scales itself. Set `NIRU_UI_SCALE` (0.75 to 2.5, `1` disables) to override.

## Files

| Path | Purpose |
|---|---|
| `~/.config/nirulauncher/config.toml` | Launcher settings |
| `~/.local/state/nirulauncher/usage.tsv` | Launch history |
| `~/.local/state/nirulauncher/favorites.tsv` | Favourites pinned with `Ctrl+P` |
| `~/.local/state/nirulauncher/emoji-recent.txt`, `emoji-tone` | Recent emoji and skin tone |
| `~/.local/state/niru/clipboard.json` | Clipboard history |
| `~/.local/state/nirushot/colors.json` | Picked colours |
| `~/.config/niruwm/actions.toml` | Saved NIRU Actions |

## See also

- [04-bar-and-quick-settings.md](04-bar-and-quick-settings.md)
- [07-screenshots-and-recording.md](07-screenshots-and-recording.md)
- [08-themes-and-wallpapers.md](08-themes-and-wallpapers.md)
- [09-displays.md](09-displays.md)
- [10-sound-notifications-studio.md](10-sound-notifications-studio.md)
- [15-key-bindings.md](15-key-bindings.md)
- [16-commands.md](16-commands.md)
