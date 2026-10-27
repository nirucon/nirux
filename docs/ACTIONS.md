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
