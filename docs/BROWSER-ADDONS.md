# Browser addons

NIRUX manages optional browser enhancements separately from the Helium binary.
The current addon is **Bonjourr**, a new-tab page.

## Why opt-in

Chromium's `ExtensionInstallForcelist` policy is a strong mechanism: it can
force-install an extension and applies at the Chromium policy location, not only
inside one profile. NIRUX therefore never enables a third-party extension
silently. A fresh interactive install asks once; unattended installs default to
no addon. The choice is stored in
`${XDG_STATE_HOME:-~/.local/state}/nirux/browser-addon-policy` and survives
updates.

## Commands

```sh
nirux install --browser helium --browser-addon bonjourr
nirux update --browser-addon bonjourr
nirux browser-addon bonjourr
nirux browser-addon none
nirux browser-addon status
```

When Bonjourr is selected, NIRUX writes:

```text
/etc/chromium/policies/managed/nirux-bonjourr.json
```

The policy uses extension id
`dlnejlppicbjfcfcedcflplfjajinajd` and the official Chrome Web Store update
URL. Helium must be restarted after the first enable. Removing the addon removes
only NIRUX's policy file.

## Preset

NIRUX writes an importable JSON preset to:

```text
${XDG_DATA_HOME:-~/.local/share}/nirux/browser-presets/bonjourr-nirux.json
```

The preset is deliberately conservative:

- English UI text.
- European date order and 24-hour time.
- A quiet dark background; no remote weather, quotes, notes, search bar or
  Pomodoro sources.
- No private hostnames, bookmarks or user content.
- Noto Sans typography and restrained link styling.

Bonjourr uses the interface language for localized month and weekday names.
There is no supported mixed “English UI + Swedish date words” mode; Swedish
date *order* and 24-hour time are supported. Use `lang = "sv"` in the preset if
Swedish date words are more important than the English UI. The preset does not
touch an existing Bonjourr configuration: import it through Bonjourr's own
settings if wanted.

## Safety

- Do not edit Bonjourr's localStorage or Helium's profile database directly.
- Do not replace a user's existing Bonjourr settings when enabling the policy.
- Do not force-install any extension other than a deliberately selected,
  documented addon.
- Preserve unrelated `/etc/chromium/policies/managed` files.
- If Helium is absent, skip the policy and report why.
