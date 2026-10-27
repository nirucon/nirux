# NIRU Actions, tasks and OpenCode

## One catalogue, two routes

`Super+A` opens the focused NIRU Actions view. The same entries are included in
`Super+Shift+P`, so an action has one identity and one execution path. The view is
part of `nirulauncher` (`nirulauncher --system-actions`); it is not another shell or
daemon.

Deterministic actions cover:

- storage review: cache, trash, old downloads and NIRUX generations; nothing is
  removed by the review;
- off-screen window recovery;
- installed/running NIRUX status;
- focus and presentation work contexts with a timer;
- recent NIRU tasks;
- existing diagnostics, updates, themes, audio, layout, recipes and settings.

The action list is built from the same `niructl` commands used by the CLI. Review
output is shown in a terminal; no personal file is deleted by a silent default.
Informational terminal actions keep the window open after the command exits and
wait for Enter, so storage reviews, task history and diagnostics remain readable.

## Intent phrases

Typing a small, fixed phrase in the normal launcher resolves it to the same
catalogue entry before ordinary app results. English and Swedish forms are
supported, including lock/lås, logout/logga ut, restart/starta om, shut
down/stäng av, focus/fokusläge, presentation/mötesläge, DND/stör ej, keep
awake/håll vaken, volume/microphone mute, brightness, night light, compositor,
off-screen window recovery and Wi-Fi radio on/off through NetworkManager.
Matching is exact after normalization and bounded; unknown text stays a search
and never becomes a shell command.

## Saved actions

Save any selected application or command row with **Ctrl+S**, or store an argv
directly:

```sh
niructl action save "Night desk" -- niructl nightlight on
niructl action list [--json]
niructl action run "Night desk"
niructl action pin "Night desk"
niructl action rename "Night desk" "Evening"
niructl action delete "Evening"
```

Saved actions are user-owned TOML under `~/.config/niruwm/actions.toml`, run
without a shell, and appear in both the Actions and System Actions views plus
normal search. A stored favourite uses the existing star/pin behaviour. Only
name and argv are stored; no transcript, password or model prompt is saved.

## Display transitions

`niructl display watch` is started as a session helper. When the set of
connected outputs changes it waits for xrandr to settle, applies the configured
startup profile if every output in it is present, and otherwise moves managed
windows that are outside every connected display. A manual enable/disable change
does not re-apply a profile, so it cannot undo a deliberate `xrandr` choice; it
still recovers off-screen windows. `niructl display watch --once` prints the
current state for diagnostics.

## Tasks

`niructl task list` shows recent tasks. `nirubar` can show the optional `tasks`
module while a task is running or waiting; click it to open NIRU Actions. Task
records contain a bounded label, state, age and short result, not credentials or
full model prompts.

## Optional OpenCode

OpenCode is optional and is never installed, started, logged in or selected as a
model provider automatically. When `opencode` is present, NIRU Actions offers
**Ask OpenCode…**. This is a terminal handoff: `niructl agent` writes a small
context file under the user's state directory and starts the installed OpenCode
interface with a prompt. OpenCode's own permissions and authentication apply.

The handoff never uses `--auto`, never disables permissions, never reads stored
credentials, and never grants root. It asks OpenCode to inspect current state with
`nirux status`, `nirux doctor`, `niructl explain` and the relevant `niructl`
command, and to ask before destructive changes. Closing the terminal, failing to
authenticate, or an unavailable provider is reported honestly; deterministic NIRU
Actions continue to work.

## Storage review

`niructl storage review` reports sizes for cache, trash, downloads older than 90
days and old NIRUX generations. It is deliberately read-only. A future cleanup
action must show the exact scope and preserve personal files, projects and the
current/previous generation. `niructl storage clean cache --yes` removes only the
regenerable NIRUBAR cache and is not exposed as a silent click action.
