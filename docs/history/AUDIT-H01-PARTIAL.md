# H01 fresh OS/VM acceptance — partial

Recorded **2026-10-20**. Fresh isolated VMs were used for Debian Bookworm and
Arch; Void has fresh container evidence plus the existing physical host, but no
fresh Void VM image is available in the LXD image server. H01 therefore remains
partially open.

## Environments

| System | Environment | Fresh OS evidence |
|---|---|---|
| Debian Bookworm | LXD VM, 2 vCPU / 2 GiB, Debian 12 image 2026-10-20, kernel 6.1.0-54-amd64 | yes |
| Arch Linux | LXD VM, 2 vCPU / 2 GiB, Arch image 2026-10-20, kernel 7.2.11-arch1-1 | yes |
| Void glibc | disposable fresh container + existing physical `niru@void` | container only; physical host is not fresh |

The host bridge had IPv4 forwarding blocked by the existing host firewall, so
the VMs reached the real release/GitHub endpoints through a local HTTP proxy
published by a temporary Docker container. The VM guest was a normal clean OS;
the proxy was transport only. No packages or release files were injected into
the guest.

## Procedure and results

Both VMs:

1. Created an empty normal user `niru` with sudo and a test password.
2. Cloned NIRUX main and ran:
   `./nirux install --release 0.10.35 --display-manager startx --browser helium`
   as that user.
3. `nirux status` and `nirux doctor` returned 0. Helium 0.19.4.1 was installed
   with its desktop entry and the eight theme wallpapers were installed.
4. Ran the real generated `~/.xinitrc` through `startx` under Xvfb:
   WM + bar started, `niructl restart-bar` worked, theme change replaced the
   root wallpaper and the bar remained present, and `maim` wrote a 1280×800
   screenshot.
5. Launched managed Helium headless as the same normal user; it rendered
   `about:blank` with no "No usable sandbox" error.
6. Tested the `nirulock` PAM service against the fresh user password:
   - Debian: `pamtester nirulock niru authenticate` succeeded.
   - Arch: a small PAM test program against `nirulock` succeeded.
7. Ran `nirux update --release 0.10.35` (target-owned apply), then `rollback`,
   then `uninstall --purge`. A second generation was created and the previous
   one restored. Purge removed programs, PAM service, session entry, config and
   owned wallpapers.

Screenshots: Debian 199,342 bytes (SHA-256
`43ed63a3050fb4f0ac829e98930367916d9e92add91179ca8366a6c2bea55fe1`), Arch
184,838 bytes (SHA-256
`9af9f2bad686212c5cd9fcc27c04afe06912e298b45d7af621590ed29d1d1913`). Both show
the NIRUX wallpaper and bar; the Arch test also asserts the bar survives the
theme change before capturing.

Void container/owner host evidence: the S04 audit installed 0.10.35 and ran
status/doctor, startx, WM/bar, theme wallpaper and screenshot. The physical Void
host runs the same release after an in-place update.

## Remaining H01 work

- Fresh **Void VM** or fresh physical Void OS; the available physical host is
  not a clean install.
- Physical audio output/microphone (VM/container has no sound hardware).
- Physical PAM lock/unlock in a real session (PAM authentication itself passed
  in both VMs).
- Suspend/resume and display/output hotplug.

Debian/Arch VM paths are accepted as fresh VM evidence. Void and physical
hardware remain open until the owner supplies a clean Void VM/host or accepts
the current physical host as the final physical check.
