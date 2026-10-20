# Checkpoint 0.10.36 — kitty, fish and theme-following terminal colours

Recorded **2026-10-20** as an owner-requested between-patch before the next
roadmap task.

## What is installed

- **fish** on all three distributions (`fish` / `fish` / `fish-shell`) and
  **fonts-jetbrains-mono** on Debian. Arch/Void already provide a Nerd Font.
- A NIRU **kitty** configuration. Kitty always starts fish, without changing
  the user's login shell. The config uses JetBrainsMono Nerd Font with
  JetBrains Mono/DejaVu fallbacks, tab-free tiling-friendly window settings,
  copy-on-select, scrollback, keybindings, and existing NIRUX wallpaper/theme
  behaviour.
- A fast **fish prompt** with directory, git branch/status and command duration.
  It uses fish's built-in persistent history, autosuggestions and completion;
  no fisher/Pure/starship package is required. `Ctrl+F` accepts the current
  autosuggestion. Completions are provided for `nirux` and `niructl`, plus a
  `nirux-update` helper that does not shadow the user's own `update`.
- Generated colours in `~/.config/nirux/theme/kitty.conf` and `fish.fish`.
  The palettes cover Noir, Nord, Satie and the light Carl Larsson theme, with
  readable ANSI colours and per-theme opacity. Custom themes use their five
  theme colours plus a light/dark ANSI base chosen from the background.

## Theme following

NIRUWM 0.16.35 runs an optional `nirux-theme-hook` on theme change/reload; the
session also runs it at login. The hook regenerates kitty/fish colours and sends
kitty `SIGUSR1` to reload. Fish re-sources the colours on the next prompt, so
existing terminals and shells update without a restart. The hook is optional;
NIRUWM has no dependency on NIRUX.

## Existing configuration

- An existing `~/.config/kitty/kitty.conf` receives one reversible managed
  block (`shell fish` + theme include). Other lines are untouched and a
  `.nirux-backup` is written before the first edit.
- An existing `~/.config/fish/config.fish` receives one managed block at the
  end, so NIRUX prompt/colours win over older NIRUPI/starship setup while user
  aliases and functions remain.
- Uninstall removes only the managed blocks and NIRUX-owned files. It does not
  delete the user's kitty/fish config or fish history.

## Verification

- `sh tests/integration.sh` covers install/update/uninstall, idempotent blocks,
  user-config preservation and backup creation.
- `python3 tests/terminal-theme.py` checks foreground >= 7:1, muted/ANSI >=
  4.5:1, selection foreground and visible focus/border colours for every
  built-in palette.
- `tests/release-smoke.sh` passed on local Arch, Debian and Void containers with
  the real 0.16.35/0.18.17 components: config-contract, startx/theme change,
  kitty/fish syntax, fish prompt, terminal colour regeneration and Helium.
- A real kitty config parse under Xvfb succeeded; transparency correctly needs
  the session compositor (picom).

Full CI, release and owner-host deployment are recorded after publication.
