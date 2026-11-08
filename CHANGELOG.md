# Changelog

Earlier releases are described in their release notes and commit messages.

## 0.12.234 (2026-11-08)

- **NIRUWM 0.18.1:** on Swedish, German and other layouts where `/` is
  Shift+7, the new Super+/ cheat-sheet key took over Super+7, which opened the
  cheat sheet instead of workspace 7. Now the binding for what a key types
  without Shift wins, so Super+7 is workspace 7 again, and **Super+F1** opens
  the cheat sheet on every layout. The dropped key is named in the session
  log.
- `config.example.toml` and the README list Super+F1.

## 0.12.233 (2026-11-08)

New keys, a color picker and pause music on the lock screen.

- **NIRUWM 0.18.0:** `niructl keys --json` is the live source for a
  keybinding cheat sheet; `[[keys]]` takes an optional `description`; programs
  register their own keys in `~/.local/share/niru/keys.d/<app>.toml`.
  New default keys:
  - `Super+/` keybinding cheat sheet;
  - `Super+.` emoji and symbols;
  - `Super+Ctrl+C` color picker.
  - **Moved:** "focus the next screen" is now `Super+Alt+.` (it was `Super+.`),
    with `Super+Alt+,` as its pair. `Super+,` still focuses the previous
    screen. Add one `[[keys]]` entry to get the old key back.
  - Bundles NIRUBAR 0.18.90 (unchanged).
- **NIRULAUNCHER 0.5.0:** the cheat sheet (`--keys`: grouped, search by words
  or key, Enter runs, Ctrl+R tells what a combo does, clashes flagged), the
  emoji and symbol picker (`--emoji`, `:name` in the launcher; recents, skin
  tones, Enter pastes and restores the clipboard, Shift+Enter copies) and a
  Colors view (`--colors`) of the last ten picked colors.
- **NIRUSHOT 0.6.0:** `nirushot pick`, a freeze-frame color picker with a
  loupe; arrows move 1 px (Shift: 10 px), Tab cycles hex/rgb/hsl, Esc cancels.
- **NIRULOCK 0.22.0:** optional `[pause_music]` (off by default): SID tunes
  from `~/Music/SID` through `sidplayfp` while locked and nothing else plays;
  Esc stops it, and it always stops before suspend.
- **NIRUDICTATE 0.2.1** (extra): registers its shortcuts in the cheat sheet.
- **New dependency `sidplayfp`:** Debian and Void install the distribution
  package. On Arch it is AUR only: NIRUX uses paru or yay when installed, or
  builds it with `makepkg` (perl and the autotools included). A failed build
  only warns and is not retried by every update.
- `config.example.toml` lists the new keys and the moved screen keys.
