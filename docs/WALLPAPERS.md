# Wallpapers and optional packs

Use **NIRU Wallpaper** from the launcher to preview and choose images. Theme
selection and an explicit wallpaper override are separate choices. Following the
theme uses its default image; choosing a colour variant does not rewrite the theme.

```sh
nirux wallpapers status
nirux wallpapers download themes
nirux wallpapers download theme nord
nirux wallpapers download extras
nirux wallpapers download carl-larsson
nirux wallpapers download satie
nirux wallpapers download signature
nirux wallpapers download all
nirux wallpapers style signature   # or art, or toggle
```

## Art and Signature

Every built-in theme has two pictures to choose from:

- **Art** (default): the theme's own artwork.
- **NIRUX Signature**: the Noir photograph (photo by Nicklas Rudolfsson, 2025)
  toned in the theme's own colours, so the whole suite shares one picture.

`nirux wallpapers style signature` downloads the Signature archive (one 4K
picture per theme, about 47 MiB, from release `v1.1.0` of nirux-wallpapers)
when it is missing and sets `[wallpaper] theme_style`. NIRU Theme Selector and
NIRU Wallpaper switch the style with one key, and `niructl wallpaper style
toggle` does it from a terminal. A theme without a Signature picture keeps its
artwork, and the login screen follows the same style.

The default Noir picture is the same photograph, shipped with NIRUX in 4K and 8K.

The nine optional theme wallpapers are 4K/8K images (about 284 MiB) and are
downloaded as verified archives from the release assets in
[`nirucon/nirux-wallpapers`](https://github.com/nirucon/nirux-wallpapers).
Noir is shipped with NIRUX itself. On a fresh install that requests the set, the
optional images are downloaded before the first NIRUWM session starts, so the
selected theme has its image immediately. Running the command from an existing
session refreshes the active theme after the download finishes; no logout is
needed. The two additional packs contain **Carl Larsson** and **Erik Satie** in
red, blue, green and noir: four images per pack with 4K and 8K versions, eight
files each. Together the extra packs are about 254 MiB. The launcher has an
additional-wallpaper download action.

NIRUX pins the GitHub release, per-asset byte counts and SHA-256 checksums.
Downloads are explicit; opening the graphical app does not contact GitHub.
Complete archives and installed files are reused. No Nextcloud URL is used. Installed variants belong in the Official themes tab, including when
the Pictures directory is a symlink. Images are installed under the XDG Pictures
directory's `Wallpapers/NIRU` folder; configure NIRUWM's theme directory accordingly
if using another location.

```sh
nirux wallpapers remove
```

Removal keeps the default Noir images and must retain personal/modified files.
An ownership record tracks package bytes, never adopts a user's changed bytes.
Theme removal conservatively retains wallpaper data when deletion ownership is
uncertain. See [installation](INSTALL.md) for update and purge behavior.

## Release asset verification

On 2026-11-01 the optional archives were downloaded from
`nirucon/nirux-wallpapers` v1.0.0 in a temporary home on `algiz`. All nine
theme archives and both extra colour packs verified their pinned byte counts and
SHA-256 checksums; the completed set contained 34 PNG files. The installed
NIRUX 0.12.178 release was then used to download a single theme into a temporary
home with the same result. Existing real wallpaper directories were not
re-downloaded or replaced.
