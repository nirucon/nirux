# S04 vanilla dependency and normal-user runtime audit — 0.10.35

Recorded **2026-10-20**. Purpose: check the complete provisioning/run matrix on
vanilla Arch, Debian Bookworm and Void glibc, not only package lookups.

## Method

For each disposable container:

1. Install the published NIRUX 0.10.35 release as an unprivileged user into an
   isolated home/prefix/system root with `--no-packages --browser helium
   --display-manager startx`.
2. Run `nirux status` and `nirux doctor` (exit 0 required).
3. Run the real generated `~/.xinitrc` through `startx` with Xvfb: WM and bar
   start, theme change replaces the root wallpaper, `maim` writes a screenshot,
   and `niructl quit` exits the session.
4. Start PipeWire/WirePlumber as the same normal user and query `wpctl`.
5. Record package versions from the native package manager.

The `NIRUX_TEST_AS_ROOT=1` integration hook was used only to redirect system
integration into the disposable system root; no production sudo/PAM was touched.

## Package matrix (key packages)

| Component | Arch | Debian Bookworm | Void glibc |
|---|---|---|---|
| X server | xorg-server 21.1.25 | xserver-xorg 7.7+23 | xorg-minimal 1.2_2 |
| xinit | 1.4.4 | 1.4.0 | 1.4.4 |
| D-Bus | 1.16.2 | 1.14.10 | 1.16.2 |
| terminal | kitty 0.49.2 | kitty 0.26.5 | kitty 0.48.2 |
| launcher | rofi 2.0.0 | rofi 1.7.3 | rofi 2.0.0 |
| audio | pipewire 1.6.9, wireplumber 0.5.18 | pipewire 0.3.65, wireplumber 0.4.13 | pipewire 1.6.9, wireplumber 0.5.18 |
| fontconfig | 2.18.3 | 2.14.1 | 2.17.1 |
| Nerd/icons | ttf-jetbrains-mono-nerd 3.5.1 | fonts-font-awesome 4.7.0 fallback | nerd-fonts-symbols-ttf 3.5.0 |
| Helium libs | nss 3.131, gtk3 3.24.52, mesa 26.2.5 | libnss3 3.87.1, libgtk-3-0 3.24.38, libgbm1 22.3.6 | nss 3.130, gtk+3 3.24.52, mesa 26.2.5 |
| xz | 5.8.4 | 5.4.1 | 5.8.3 |

PAM, D-Bus user/session, fonts, cursors (Adwaita), `feh`, `maim`, `slop`,
`pcmanfm`, `brightnessctl`, `gammastep`, `notify-send`, `playerctl`, `wpctl`,
`amixer`, `xprop`, `xwininfo` and the optional display-manager packages were
present on all three. No manual suite package fixes were needed.

## Normal-user runtime results

| Check | Arch | Debian | Void |
|---|---|---|---|
| release install as normal user | passed | passed | passed |
| `nirux status` | exit 0 | exit 0 | exit 0 |
| `nirux doctor` (no live DISPLAY) | exit 0 | exit 0 | exit 0 |
| `startx` via generated xinitrc | passed | passed | passed |
| WM + bar start/restart/exit | passed | passed | passed |
| theme change replaces root wallpaper | passed | passed | passed |
| `maim` screenshot under Xvfb | passed (~190 KB PNG) | passed (~200 KB PNG) | passed (~187 KB PNG) |
| Helium installed and normal-user sandbox launch | passed separately in CI/browser smoke | passed | passed |
| PipeWire + WirePlumber start as normal user | passed (no hardware sink) | package/runtime present; no hardware | passed (no hardware sink) |

Audio hardware, PAM password authentication, physical lock/suspend and display
hotplug remain H01 evidence. Containers cannot prove those.

## Preliminary resource baseline

Idle Arch Xvfb session after five seconds, no browser running:

| Process | RSS |
|---|---|
| nirubar | 4.7 MB |
| niruwm-session (two processes) | 7.4 MB |
| nirunotify | 3.2 MB |
| niruwm | 1.5 MB |
| niruidle | 0.8 MB |
| **Total core session** | **~17.5 MB** |

Idle CPU was 0.0–0.1% for the components. Some defunct children from repeated
container test sessions were present; the container's PID 1 does not reap them.
That is a container artifact, not a session regression. This is a baseline for
the new performance/resource task, not a full optimization result.

## Outcome

- S04: DONE for package provisioning and normal-user core runtime on all three
  supported distributions. No missing mandatory suite dependency was found.
- H01: next. It must cover fresh physical/VM OS, real audio, PAM unlock,
  suspend/output changes and a full release install/update/rollback/uninstall.
- R01 (new owner-requested task): define and enforce idle CPU/RSS/process and
  login-latency budgets, with measurements on all three distros.
