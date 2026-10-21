# NIRU visual language

This is the shared scale behind the appearance contract. Components keep their
own drawing code; they do not copy another component's palette or hard-code a
second set of roles.

## Semantic colours

Use the theme palette by role, never by literal colour:

| Token | Use |
|---|---|
| `background` | Window/page background |
| `surface` | Inputs, selected rows, popup panels, notification body |
| `foreground` | Primary text |
| `muted` | Secondary text, hints, low urgency |
| `border` | Separators and unfocused outlines |
| `accent`/`focus` | Focus, selection, normal urgency |
| `success` | Confirmed/healthy state |
| `warning` | Attention, confirmation prompts |
| `error` | Failure and critical urgency |
| `disabled` | Unavailable controls |

A state must remain understandable without relying on colour alone.

## Type and spacing

- Default body font: 15 px.
- Row/control height: `max(configured row height, font line height + 8)`.
- Inner padding: `max(configured padding, font line height / 2, 8)`.
- Spacing steps: **4, 8, 12, 16 px**. Prefer these over arbitrary values.
- Header/footer separation uses the same padding step as the content.
- Notification padding is 12 px with a 4 px urgency strip.
- Launcher/bar popup padding is 12 px unless the appearance contract or the
  component config overrides it.

Large fonts grow rows and popup height. They must not clip text or move
hitboxes away from the visible control.

## Focus and selection

- Selected launcher row: `surface`/`selected` fill plus a **3 px accent bar** on
  the left edge.
- Keyboard focus and pointer hover must be visually distinct but use the same
  accent.
- Popup and notification surfaces never take keyboard focus unless they contain
  an explicit interactive control.
- Border/focus width is shared with the WM appearance contract.

## Layout bounds

- Text width comes from measured font advances, not character-count guesses.
- Width is clamped to the selected monitor, with a sensible minimum.
- Height is clamped to the monitor work area; overflow must remain reachable.
- Test sizes: **800×600, 1366×768, 1920×1080**, plus mixed-width outputs.
- Popup hitboxes are derived from the same geometry as the painted row.

## Component mapping

| Component | Shared rules |
|---|---|
| NIRUWM | Theme tokens, focus width, layout gap |
| NIRUBAR | Font-aware bar height/popup rows, semantic state text |
| NIRULAUNCHER | Font-aware rows, 3 px focus bar, measured truncation |
| NIRUNOTIFY | Font-aware wrapping/height, 4 px urgency strip, 12 px padding |
| Greeters | Noir palette, consistent panel padding and focus |
| NIRULOCK/NIRUSCREENSAVER | Theme text, opaque black privacy surface |

## Status

Implemented: theme-role palettes across the suite, font-aware notification and
launcher geometry, launcher accent selection, configurable session welcome and
audio output/source/mute controls through `niructl audio` and a multi-display
count/popup. Still open in P3: rendered-value checks for every component and the
small-screen/hotplug matrix.
