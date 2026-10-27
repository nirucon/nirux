# Wallpapers and optional packs

Use **NIRU Wallpaper** from the launcher to preview and choose images. Theme
selection and an explicit wallpaper override are separate choices. Following the
theme uses its default image; choosing a colour variant does not rewrite the theme.

```sh
nirux wallpapers status
nirux wallpapers download themes
nirux wallpapers download extras
nirux wallpapers download carl-larsson
nirux wallpapers download satie
nirux wallpapers download all
```

The main ten-theme set includes 4K/8K images (about 326 MB). On a fresh install
that requests the set, it is downloaded before the first NIRUWM session starts,
so the selected theme has its image immediately. Running the command from an
existing session refreshes the active theme after the download finishes; no
logout is needed. The two additional
packs contain **Carl Larsson** and **Erik Satie** in red, blue, green and noir:
four images per pack with 4K and 8K versions, eight files each. Together the extra
packs are about 255 MiB. The launcher has an additional-wallpaper download action.

NIRUX pins the download origins, byte counts and SHA-256 checksums. Downloads are
explicit; opening the graphical app does not contact the server. Complete packs
are reused. Installed variants belong in the Official themes tab, including when
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
