# nirushot — N5 design contract

Status: design started; repository not created yet.

## Existing baseline

NIRUWM currently binds Super+Print to `maim ~/Pictures/screenshot-TIME.png` and
Super+Shift+Print to `maim -s`. `maim` and `slop` are installed by NIRUX. There is
no native review surface, clipboard action or notification workflow.

## CLI

```text
nirushot [--region|--window|--full] [--delay SECONDS]
         [--copy|--save PATH] [--annotate]
```

- `--region` uses slop selection; Escape/cancel exits with a clear status.
- `--window` captures the active window; `--full` captures all outputs.
- Without `--copy`/`--save`, open the review surface and do not write a file
  until the user chooses.
- `--copy` and `--save` are explicit, mutually exclusive outputs.
- Default file names use ISO date/time under `~/Pictures`.

## First delivery

1. Region/window/full capture and delayed capture.
2. Escape/cancel leaves no file, grab or helper process.
3. Save to a chosen path or copy PNG to the X11 clipboard.
4. Notify through nirunotify with Open, Copy and Show in folder actions.
5. Keep the existing Super+Print/maim binding as fallback until the released
   tool passes integration.

## Review surface

Native X11, on demand, NIRU theme/type/spacing. Show the image, cursor position,
crop rectangle, rectangle/arrow annotation and opaque mask. Escape cancels;
Enter applies; saving an edited image never overwrites the original silently.
No upload, recorder, history daemon or required clipboard manager.

## Backend and failure rules

- Reuse maim/slop for capture and selection; use xclip for X11 clipboard.
- Every helper has a deadline and bounded output; no shell string.
- Multi-output geometry is captured from the selected monitor/root; the saved
  file is validated as a readable image with non-zero dimensions.
- Cancel, provider failure and write failure report honestly and clean up grabs.
- No automatic upload or background process.

## NIRUX integration after the release

Pin the checksummed release in `manifest`; install dependencies (maim, slop,
xclip); replace the screenshot bindings and launcher action after the fallback
period; update doctor, rollback, owned uninstall and release smoke fixtures.
