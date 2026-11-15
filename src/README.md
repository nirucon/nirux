# The nirux script, in parts

`nirux` in the repository root is built from these files: `tools/build.sh`
joins `src/NN-*.sh` in name order. Hosts, tests and releases use the built
file, exactly as before, so an update still replaces one file in one step.

To change the script:

1. Edit the part in `src/`.
2. Run `tools/build.sh`.
3. Commit both the part and `nirux`.

CI and the release workflow run `tools/build.sh --check` and fail when `nirux`
was edited by hand or not rebuilt.

| Part | What it holds |
|---|---|
| `00-core` | Header, paths, sudo handling, `say`/`die`, usage, distribution detection |
| `10-packages` | Runtime package lists and installation, sidplayfp on Arch |
| `20-config` | Config scanning, validation and migrations, appearance |
| `21-wallpaper-bundle` | Pictures directory and the bundled wallpapers |
| `22-terminal-sounds` | Terminal theme blocks and `nirux sounds` |
| `23-config-install` | Config upgrades (night light, bar, picom) and `install_config` |
| `30-fetch` | Display manager choice, downloads, checksums, release files |
| `31-browser-addon` | Bonjourr start page |
| `32-extras` | `nirux extras` |
| `33-update-power` | `nirux update-shutdown` and `update-reboot` |
| `40-browser-apps` | Helium, hardware video, LocalSend, OpenCode, app choices |
| `41-icons-policy` | Papirus icons and the wallpaper set choice |
| `50-release` | Staging, activating and cleaning release generations |
| `51-owned-files` | Ownership checks for files NIRUX writes |
| `52-wallpapers` | Login wallpaper, `nirux layout`, `nirux wallpapers` |
| `60-system-rules` | Wi-Fi rule, checkup, login picture, keyring PAM lines |
| `61-greeters` | NIRU Login, SDDM, LightDM, startx |
| `62-hardware` | User dirs, backlight, touchpad, battery, Void fixes, Tailscale |
| `70-status-doctor` | Services, `nirux status`, `nirux doctor` |
| `71-lifecycle` | Uninstall, repair, reset, rollback, install and update |
| `80-fleet` | `nirux fleet` |
| `81-snapshot` | `nirux snapshot` and `nirux restore` |
| `82-sync` | `nirux sync` |
| `83-manual` | `nirux manual` |
| `84-autoupdate-state` | The nightly update and its pending root steps |
| `85-whats-new-clean` | `nirux whats-new`, `resume-check`, `clean` |
| `86-bar-apps` | Bar module defaults and upstream app versions |
| `87-sleep-autoupdate` | Installing the sleep hook and the nightly timer |
| `88-backup` | `nirux backup` and `nirux migrate` |
| `99-main` | Command dispatch |
