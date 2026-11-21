# Changelog

Earlier releases are described in their release notes and commit messages.

## 0.12.320 (2026-11-21)

- **NIRUTERM 0.1.0, the NIRUX terminal.** Installed beside kitty, which
  stays on `Super+Enter` for now: NIRUTERM in the launcher or `niruterm`.
  It opens in about 40 ms, uses 12 to 25 MB, follows the theme live, draws
  box lines as exact pixels and shows pictures (`niruterm icat FILE`, the
  kitty graphics protocol).
- **NIRUPROMPT:** the fish prompt now comes from `niruprompt` when it is
  installed, with the same layout as before plus styles (`niruprompt styles`,
  `niruprompt style runes`), aliases for bash and fish from
  `~/.config/nirux/aliases.toml`, and `niruprompt install bash` for the
  prompt and a large shared history in bash.
- **NIRUFM 0.2.2:** going between Recent and Home shows each one.

## 0.12.319 (2026-11-21)

- **NIRUFM 0.2.1:** Recent marks its own row in the side panel instead of
  Home, and its bar says "Recently used files".

## 0.12.318 (2026-11-21)

- **The nightly update keeps a release that needs a new package.** A package
  the release asks for but the root-owned list does not have yet waits for
  `nirux update` in a terminal; the doctor no longer counts it as a new
  problem, which rolled 0.12.317 (NIRUFM's thumbnail and PDF packages) back
  every night.

## 0.12.317 (2026-11-21)

- **NIRUFM, the new file manager (NIRUFM 0.2.0).** `Super+Shift+F` opens
  it, and folders that other programs open go there too. It starts in a few
  hundredths of a second, uses about 15 MB and is drawn in the NIRU theme:
  icons, thumbnails, compact and list views that each folder remembers, a
  gallery for photos and films, Space preview (pictures, PDF, text),
  search below a folder, tabs and two panes, drag and drop, the trash with
  undo, packing and unpacking, USB drives, sftp/ftp/smb servers, Nextcloud
  links and sync badges. `F1` shows every key.
- **pcmanfm and NIRUORG leave the suite.** A `nirux update` in a terminal
  removes pcmanfm and moves a `Super+Shift+F` binding that still started it
  to NIRUFM (a binding changed to something else is kept). `nirux extras
  update`, which the nightly update runs, removes NIRUORG with its own
  uninstaller; its settings stay.
- **Thumbnails and previews:** the runtime packages now include poppler
  (PDF), ffmpegthumbnailer (video) and the gdk-pixbuf thumbnailer.
- **NIRUWM 0.36.2:** NIRUFM is the default file manager of a new
  configuration.

## 0.12.316 (2026-11-21)

- **Dialogs that wait for you are shown (NIRUWM 0.36.1).** NIRUWM hides a
  dialog whose parent window is hidden, unless you just clicked the app in
  the tray, so tray apps cannot pop up windows by themselves. Qt names a
  hidden helper window as the parent of every parentless dialog, so the
  Nextcloud account wizard and its folder chooser stayed invisible. A modal
  dialog (one that waits for an answer) is now always shown.

## 0.12.315 (2026-11-21)

- **Links open in Helium again from other programs.** The Helium entry had
  its command in quotes, which `xdg-open` on Debian cannot read, so it gave
  up with "no method available". That broke the Nextcloud login and every
  link opened by a program that uses `xdg-open`. The command is now written
  without quotes (quotes are kept only for a path that needs them).

## 0.12.314 (2026-11-21)

- **Hardware video on Intel machines installed by NIRUBOOT.** Debian's
  non-free Intel video driver (`intel-media-va-driver-non-free`, which also
  encodes) now counts as the Intel driver, so hardware video in Helium turns
  on without swapping drivers.
- **`nirux doctor` on a new Debian 13.** polkit keeps `rules.d` readable by
  root only there, so the power rule cannot be seen from an account. Doctor
  says it was not checked instead of reporting it missing.

## 0.12.313 (2026-11-21)

- **A NIRUX demo (NIRUDEMO 0.1.0).** `Super+Alt+D`, `demo` in the launcher
  or `nirux demo` plays "Ginnungagap", a demoscene demo in the theme colours
  with its own music: stars, a turning N in fog, plasma with a sine scroller
  and a tunnel. Any key ends it. The launcher has a Demos view
  (NIRULAUNCHER 0.18.0), and the screensaver a silent `demo` scene
  (NIRUSCREENSAVER 0.18.0).
- **The NIRUX music.** Eleven original chiptunes in minor keys, from dark
  ambient to the C64 sound and calm Satie-like pieces, installed in
  `~/.local/share/nirux/music` (`nirux-1-ginnungagap` to `nirux-11-gimle`).
  They are the new default pause music of the lock and the music scenes of
  the screensaver (NIRULOCK 0.29.0); `folder = "~/Music/SID"` under
  `[pause_music]` plays your own SID tunes instead.
- **The screensaver on a key.** `Super+Alt+Z` starts the screensaver now
  (NIRUWM 0.36.0).

## 0.12.312 (2026-11-20)

- **Fewer voices, chosen by ear.** The voice now speaks only for battery low
  and critical, reminders, a ready meeting check and a wrong password. The
  network, timer, meeting problem, update, startup and Teams sounds are tones
  again. Shutdown says "Goodbye" and then plays its tune, and the logout waits
  up to 4.5 seconds for it (NIRUWM 0.35.1).

## 0.12.311 (2026-11-20)

- **A retro robot voice for rare events.** Battery low and critical, network
  lost and back, reminders, the timer, the meeting check, a wrong password,
  updates, startup and shutdown now speak in the espeak-ng voice of "You got
  mail". Every other sound stays a tone. `nirux sounds voice on|off` switches
  at once; your own sound files still win.
- **Teams notifications speak "Teams message" (NIRUNOTIFY 0.9.0).** A web
  page's notification names its site, so `[sounds.apps]` can give a site its
  own sound, for example `nirux sounds app teams.cloud.microsoft off`.

## 0.12.310 (2026-11-20)

- **No more device sounds from built-in hardware (NIRUNOTIFY 0.8.1).** A
  fingerprint reader that wakes when a finger comes near drops off USB and
  comes back, which played the connect and disconnect sounds. Devices on
  ports the firmware marks as built in are now silent; sticks, headsets and
  docks still sound.

## 0.12.309 (2026-11-20)

- **Web apps from a catalogue (NIRUWEBAPP 0.3.0).** `nirux install` now
  offers sets of web apps: `work` (Teams, Outlook, Outlook Calendar,
  Copilot, Loop, Planner, OneDrive), `ai` (Claude, ChatGPT, Gemini, Grok,
  Gemini Notebook), `google`, `proton`, `media` (YouTube, YouTube Music,
  SVT Play) and `other`, plus your own Nextcloud. `--webapps SET,...` and
  `--nextcloud ADDRESS` answer without asking, also on `nirux update`;
  `nirux webapps [add|check]` later. Addresses checked 2026-11-20; a
  service you already have is not added twice.
- **Profile groups.** The Google apps share one sign-in, the Proton apps
  another, apart from normal browsing; Microsoft 365 keeps the browser's
  own profile. `--profile-group NAME` for your own groups.
- **Addresses that move.** Every update moves a web app from a service's
  former address to its current one (`notebooklm.google.com` to
  `notebook.google.com`, `outlook.office.com` to `outlook.cloud.microsoft`).
  The weekly checkup warns about a web app whose address no longer answers
  or now leads elsewhere; `nirux webapps check` shows it at once.

## 0.12.308 (2026-11-20)

- **Sleep that saves to disk (NIRUSLEEP 0.1.0, new; NIRUWM 0.35.0).**
  `nirux hibernate on` gives a laptop an encrypted swap file of its own;
  after `[battery] hibernate_after_minutes` of sleep (120 by default, on
  battery) it saves its memory and switches off, and the disk password at
  the next start brings every window back. The suspend key, the power menu
  and the lid all use it. Every kernel and boot entry resumes; only on LUKS,
  never with kernel lockdown. `nirux hibernate delay|apply|doctor|off`.
  Tested on encrypted Debian, Arch and Void VMs (hibernate, resume on the
  splash, remove). Off until turned on.

## 0.12.307 (2026-11-20)

- **Shutting down in the NIRUX look (NIRUSPLASH 0.2.0).** Powering off and
  restarting show the banner, `[ ok ] session closed` and `[ .. ] powering
  off` (or `restarting`) with the blinking cursor, in the theme's colours.
  Debian and Arch use Plymouth's own shutdown units; Void gets a file in
  `/etc/runit/shutdown.d`. Tested on encrypted Debian, Arch and Void VMs.
- **While you were away (NIRUNOTIFY 0.8.0).** After a lock of 10 minutes or
  more, what came meanwhile is one card: how many per app with the newest
  line, and new files in Downloads, instead of a pile of popups. Urgent
  notifications still show on their own. `away_summary` and
  `away_after_minutes` in `~/.config/nirunotify/config.toml`.
- **Places: settings that follow the network (NIRUWM 0.34.0).**
  `niructl place save NAME` remembers the network you are on (the router's
  address and hardware address, cable or wifi); `niructl place set` chooses
  Do Not Disturb, a display profile and a sound output for it, and
  `places.toml` takes commands for arrival and leaving. The session's watcher
  follows route changes from the kernel, without NetworkManager too, and
  leaves a place only after 20 seconds without it. Manual chapter 10.

## 0.12.306 (2026-11-20)

- NIRUWM 0.33.3: the screens keep their layout through a suspend. Some
  graphics cards reset during a suspend (amdgpu does) and the screens came
  back side by side without rotation, so a screen set to inverted was upside
  down after the wake, and the watcher kept that as if it were your choice.
  For 45 seconds after a wake the layout from before the sleep is now put
  back, rotation included, also with automatic switching off.

## 0.12.305 (2026-11-19)

- NIRUSPLASH 0.1.2: the NIRUX boot look also on Arch installations that
  start a Unified Kernel Image from GRUB (GRUB 2.14 and later). There
  0.1.1 found no kernel line in the boot menu and safely kept the plain
  boot; now the image itself gets the splash, it is backed up and put back
  on any error, and `quiet splash` go into `/etc/kernel/cmdline` when they
  are missing.

## 0.12.304 (2026-11-19)

- **The NIRUX boot look (NIRUSPLASH 0.1.1, new).** The computer now starts
  in the same style as the lock and login screens. The GRUB menu shows the
  NIRUX banner and every installed kernel straight in the menu, so another
  kernel is one arrow key away. The boot splash types the banner in, and an
  encrypted disk asks for its password at `$ unlock disk` in the same look,
  with `[ .. ] unlocking` and `[ fail ] wrong password, try again`. Every
  update makes it in the colours of the active theme. `nirux boot` shows it,
  `nirux boot off` puts the plain boot back and `nirux boot apply` makes it
  again after a theme or monitor change. It never touches the boot loader
  binary, the disk encryption or the kernel; older kernels keep their
  previous initramfs as a fallback. NIRUBOOT installs it on new computers.

## 0.12.303 (2026-11-19)

- NIRULOGIN 0.3.1: the 0.3.0 login screen was built against a newer C
  library than Debian 12, Debian 13 and Void have, so 0.12.302 could not be
  installed there (an update stopped safely and kept the installed version).
  Everything else is as in 0.12.302 below.

## 0.12.302 (2026-11-19, withdrawn)

- **Meeting check: `Super+Alt+M` or `nirux meet-check`.** In about five
  seconds it checks the camera (one picture, thrown away), the speakers, the
  microphone level, apps that still run an old version, and how fast Teams
  answers, and tells you with a notice and a sound whether you are ready.
- **`nirux stale` and a restart symbol in the bar (NIRUBAR 0.31.0).** After an
  update, `nirux stale` names programs that still run their old version and
  what to do; the bar shows `↻` and the name while something waits, and a
  click restarts what can restart in place (NIRUWM, NIRUBAR) and tells you
  about the rest. Added to the bar once on existing installations.
- **`nirux fleet top`:** every NIRUX machine live, with a small load graph,
  memory, disk, lock state and what waits for a restart. `q` quits.
- **The login screen has the NIRUX ascii look (NIRULOGIN 0.3.0).** The banner
  is typed above the clock and the form; `style = "classic"` in
  `/etc/nirulogin/theme.toml` brings back the previous look.
- **Ten new event sounds, on by default** and switchable in `nirux sounds`,
  the launcher and `sounds.toml`: `mic-mute` and `mic-unmute` (NIRUWM
  0.33.1), `record-start` and `record-stop` (NIRUCLIP 0.8.0), `timer-done`
  and `reminder` (NIRUBAR 0.31.0), `network-down` and `network-up` (NIRUNOTIFY
  0.7.0, from the kernel's route changes, no polling), and `meet-ready` and
  `meet-problem`. An existing `sounds.toml` gets the new keys once.
  NIRUNOTIFY now honours the standard `suppress-sound` hint, so a timer or a
  reminder plays its own sound and not two.

## 0.12.301 (2026-11-19)

- The release of 0.12.300 stopped at a test (its stand-in program did not
  run on the build machine); 0.12.301 is the same release with that fixed.

## 0.12.300 (2026-11-19, not published)

- **An update never removes an app version that is running.** Updating
  Helium removed the directory of the version that was still open. Helium
  starts helper processes from that directory long after it started, so on
  niruxwork the camera never came up in Teams until Helium was restarted.
  Helium, LocalSend and OpenCode now keep an old version while any program
  runs from it (also when its files were already replaced), say so in the
  update and send a notice asking to restart the app; a later update removes
  the old version. NIRUX's own program generations were already kept while
  they run.

## 0.12.299 (2026-11-19)

- **A retro NIRUX lock screen by default (NIRULOCK 0.28.0).** The new
  default layout `ascii-cava` types the NIRUX banner slowly on every
  monitor like an old terminal, with "A MINIMAL X11 DESKTOP" and a blinking
  block cursor under it, the newest character glowing white and scanlines
  through a large banner. Under it, the CAVA spectrum as wide as the banner
  while music plays, then the password prompt, which works from the first
  moment. `ascii` is the same without the spectrum and now types at the
  same calm pace. `layout = "cava"` brings back the previous lock screen.
- **`nirux fleet set lock.KEY VALUE`** changes a lock screen setting on every
  machine, for example `nirux fleet set lock.layout cava`. A value NIRULOCK
  does not accept is rolled back on that host and reported.

## 0.12.298 (2026-11-19)

- **NIRUX ascii on the lock screen (NIRULOCK 0.27.0).** `layout = "ascii"`
  in `~/.config/niruui/lock.toml` types the NIRUX banner on every monitor
  when the screen locks, in the theme's accent colour, with the password
  prompt under it. `layout = "cava"` goes back to the spectrum. Manual,
  chapter 6.

## 0.12.297 (2026-11-19)

- The release of 0.12.296 stopped at a script check; 0.12.297 is the same
  release with that fixed.

## 0.12.296 (2026-11-19, not published)

- **One setting on every machine: `nirux fleet set KEY VALUE [HOST...]`.**
  It changes a NIRUWM setting such as `idle.screensaver_timeout` (through
  the new `niructl config set`, which keeps comments and checks the whole
  file first) or a screensaver setting (`screensaver.scene`) on this machine
  and every other NIRUX machine at once. The running sessions reload at
  once, also over SSH. A machine that is offline gets the setting later:
  at the next `nirux fleet` command, login or wake-up here while it is
  online. `nirux fleet pending` lists what waits.
- **Lock when your phone leaves (NIRUWM 0.33.0).** With
  `niructl proximity set NAME` the session locks when the paired phone has
  been out of Bluetooth reach for 30 seconds, also while a video or
  `niructl idle on` keeps the screen awake. It only locks after the phone
  was seen since the login or unlock, wakes the display for the password
  when the phone returns (it never unlocks) and does nothing with
  Bluetooth off. Off by default; see the manual, chapter 6.

## 0.12.295 (2026-11-18)

- **NIRUX ascii is centred on every screen and follows the theme
  (NIRUSCREENSAVER 0.17.1).** The banner is centred and sized for each
  monitor, shifted a little each time so the same pixels do not stay lit,
  and takes the theme's accent colour when it reads on black. It is erased
  backwards at a calm pace, line first, and the screen stays black for a few
  seconds before it is typed again.

## 0.12.294 (2026-11-18)

- **A new screensaver scene, NIRUX ascii (NIRUSCREENSAVER 0.17.0).**
  `ascii` shows a large NIRUX banner in ASCII with "A MINIMAL X11 DESKTOP"
  under it on a black screen, typed out one character at a time behind a
  block cursor that blinks once a second when the text is done. After a
  minute it is erased backwards and typed again somewhere else, so no pixel
  stays lit. `ascii-sid` does the same with C64 SID tunes, like `dark-sid`.
  Choose it in the launcher's Screensaver view or with
  `niruscreensaver --set scene ascii`.

## 0.12.292 (2026-11-18)

- **The microphone no longer disappears after a restart (NIRUIO 0.2.0,
  NIRUWM 0.32.4).** On some laptops the speaker amplifiers load their
  firmware while the sound service starts. WirePlumber then met the sound
  card half ready, kept only a profile with the speakers, and the microphone
  was gone (the bar showed "none") until the sound service was restarted.
  After each login NIRUX now checks once whether a card came up without its
  microphone or its output, and if so probes it again by restarting only
  WirePlumber. It does nothing when every card looks right. `niruio heal`
  does the same by hand, `niruio heal --force` probes every card again, and
  `niruio doctor` warns about such a card with the same fix.

## 0.12.291 (2026-11-17)

- **The night light no longer turns deep red during the evening (NIRUWM
  0.32.3).** The gradual schedule changes the temperature a little every 30
  seconds, and each change was laid on top of the previous one instead of
  replacing it, so the screen got redder and redder than the schedule said.
  Each step now starts from a neutral screen, so 3500 K looks like 3500 K.

## 0.12.290 (2026-11-17)

- **The shutdown sound is heard again (NIRUWM 0.32.2).** Logging out,
  shutting down or restarting ends every process in the session at once, the
  sound server too, so the shutdown sound was cut off before it started
  (always on Void, where the session runs its own PipeWire). NIRUX now plays
  it first and waits for it, at most about 3.5 seconds.

## 0.12.289 (2026-11-16)

- **NIRUWM 0.32.1: picture-in-picture.** `Super+Alt+P` puts the focused
  window small in a corner of its screen, on every workspace there and above
  the rest, without ever taking the focus; pressed again it goes back exactly
  as it was. `Super+Ctrl+P` moves it to the next corner. YouTube's own PiP
  button (Helium, Chromium, Brave, Firefox) lands in the corner by itself.
  `[pip] size`, `corner` and `auto`; `niructl pip toggle|corner`.
- **Smart gaps can be switched off.** A single tiled window still fills the
  screen without gap or border; `smart_gaps = false` keeps them.
- **A softer night light.** The gradual evening now fades in from daylight
  over 15 minutes instead of jumping, starts at 5500 K and stops at a
  moderate 3500 K at 22:00 (was 4500 K to 2700 K, which turned very red).
  Super+N continues the glide instead of jumping to the deepest value.
  Installations that still have the previous temperatures get the new ones
  once (`niructl config undo` goes back).
- **NIRUBAR 0.30.0: three new modules,** added to the default bar:
  - `drives`: USB sticks and SD cards (hidden without one); right-click
    unmounts and powers them off and says when they can be pulled out,
    middle-click opens them. Fixed disks (fstab, crypttab) are never shown.
  - `timer`: a focus and egg timer; scroll sets the minutes, right-click
    starts and pauses, middle-click resets, a notice and a short sound at the
    end, optional Do Not Disturb while it runs (`[timer]` in
    `~/.config/nirubar/config.toml`).
  - `headset`: the battery of connected Bluetooth devices, red with one
    notice at 15 %.

## 0.12.288 (2026-11-16)

- **NIRUSCREENSAVER 0.16.0: choose what the screensaver shows.** Besides the
  clock there are now four scenes:
  - `photos`: a slide show of the NIRUX wallpapers (or any folder), drifting
    slowly and crossfading, with a small clock in the corner.
  - `dark`: black, with only "NIRUX - A MINIMAL X11 DESKTOP" gliding across
    each screen.
  - `dark-sid`: the same with C64 SID tunes, played like the lock's pause
    music but also when the screensaver starts by itself. The music stops
    when the display goes off, when you come back and when the lock takes
    over.
  - `shuffle`: a new pick from your list every time.
- **NIRULAUNCHER 0.17.0: a Screensaver view** (NIRUX Settings,
  `nirulauncher --screensaver`) to choose and preview a scene, pick what
  shuffle may show and step through the clock and photo settings. The same
  from a terminal with `niruscreensaver --set KEY VALUE`; the settings file
  keeps its comments. See "Choose a scene" in `nirux manual screensaver`.

## 0.12.287 (2026-11-16)

- Supersedes 0.12.286, which was tagged but never published: NIRUWM ships its
  own NIRUBAR, and it is now 0.29.0 too (NIRUWM 0.31.6).
- **NIRUBAR 0.29.0: the same space after every icon.** Icons wider than a
  character (display, layout, brightness, Tailscale, updates, Wi-Fi) covered
  the space after them, so the text looked glued to the icon. They now take
  two character cells and sit centred in them. Works with any Nerd Font
  version, on Debian, Arch and Void.
- **Arrange the bar without editing the file.** NIRULAUNCHER 0.16.0 adds a
  Bar view (NIRUX Settings, `nirulauncher --bar`): Enter turns a module on or
  off, Alt+Up/Down moves it, and rows switch position, icons, window title,
  date, time, tray and panels. The same from a terminal with `nirubar
  --modules ...` and `nirubar --set KEY VALUE`. The configuration file stays
  the only description of the bar, with its comments; an arranged list sets
  `follow_default_modules = false`, so updates keep it.

## 0.12.285 (2026-11-15)

- **NIRUSCREENSAVER 0.15.0: the screensaver on every monitor.** With two or
  more monitors the clock, the panel and the away time sit in the middle of
  each one, not across the seam between them, and the bars no longer show
  through: the saver raises itself again whenever the window manager restacks
  its bars.

## 0.12.284 (2026-11-15)

- **Fonts stay out of a backup.** `~/.local/share/fonts` is no longer part of
  the default copy; add it with `include` if you want it.

## 0.12.283 (2026-11-15)

- **Backup files stay out of a backup.** Files and folders named `*.bak`,
  `*.bak-*`, `*.old`, `*.orig`, `*.rej`, `*~` or `*.swp` are left out of every
  copy, in both modes: an old `retroarch.bak-<date>` folder made a copy three
  times larger than it needed to be.

## 0.12.282 (2026-11-15)

- **A backup holds your settings, not your data.** By default a copy now holds
  `~/.config`, `~/.local/bin`, Thunderbird (without its copy of IMAP mail), your
  keys, NIRUX and the NIRU apps' files and the shell and X files in your home:
  some hundred MB instead of several GB. Documents and pictures belong in
  Nextcloud. Add paths with `include`, or set `what = "home"` in
  `~/.config/nirux/backup.toml` for the whole home directory as before.
- Program versions, Python environments, speech models, RetroArch assets,
  Nextcloud logs and saved wallpapers are left out in both modes.

## 0.12.281 (2026-11-15)

- **Backup keeps what makes the computer yours, not media.** Music, videos,
  films, downloads, Docker, Lutris, Heroic, Bottles and Wine are now left out
  too, as is Thunderbird's copy of IMAP mail (the server keeps it). Settings,
  keys, notes, projects, documents and pictures are kept as before.
- **`include` in `backup.toml` works.** It was documented but did nothing.
  `include = [ "Games/Saves" ]` now keeps the saves inside a folder that is
  otherwise left out.

## 0.12.280 (2026-11-15)

- **Backup** (`nirux backup`). Encrypted, compressed copies of your home directory,
  one file per copy, in `~/Nextcloud/Backup/nirux/<computer>/`; the two newest are
  kept. A computer takes part only after `nirux backup setup` (or `enabled = true`
  in `~/.config/nirux/backup.toml`). The nightly update makes a copy when one is
  due, weekly by default, at the lowest priority. Nextcloud folders, caches,
  browsers, games, ISO images and files over 1 GB are left out. The secret key lies
  passphrase-protected in `~/Nextcloud/Vault`; computers need only the public key
  to write a copy. `nirux backup restore` unpacks a copy into a new directory.
- **Move to a new computer** (`nirux migrate from HOST`). Brings the old
  computer's settings, keys and files from its newest copy, after a preview; keeps
  the new computer's display, sound and backup settings, keeps every file it
  replaces, takes a snapshot first and offers the old computer's extras.
- The `nirux` script is now built from parts in `src/` (`tools/build.sh`); the
  installed file is the same single script as before.

## 0.12.279 (2026-11-15)

- **The keyring follows a new password.** On Arch and Void, `passwd` changed
  the login password but not the keyring's, so the next login could not
  unlock the keyring and apps asked for the old password. NIRUX now adds one
  marked line, `-password optional pam_gnome_keyring.so`, to
  `/etc/pam.d/passwd` when neither that file nor a file it includes calls the
  keyring module. Debian already does this in `common-password` and is left
  alone. `nirux uninstall` removes only the line NIRUX added. Change your
  password with `passwd` in your own session; a password set by root
  (`sudo passwd USER`) cannot change the keyring, because the old password is
  not known.

## 0.12.278 (2026-11-14)

- **The compositor draws on the graphics card.** NIRUX's default
  `~/.config/picom.conf` used picom's xrender backend, which draws every frame
  on the processor inside Xorg. With empty workspaces, where only the wallpaper
  shows, the screen stopped keeping up: workspace changes looked ignored and
  the launcher stuttered, although NIRUWM switched at once. New files use
  `backend = "glx"` with `vsync = true`. A picom.conf that NIRUX wrote and that
  is still on xrender without a vsync line moves to glx once, at the next
  update; the old file is kept as `picom.conf.bak-xrender-0.12.278`, your own
  lines stay, and a later return to xrender is never undone. It applies at the
  next login.
- **Never without a compositor** (NIRUWM 0.31.4). Where glx cannot start, the
  session and `niructl compositor on` run picom on xrender instead.
- **The startup sound is heard on Void** (NIRUWM 0.31.4). It was played right
  after login, before the default output and the sound card were ready, and
  was lost. It now waits for them in the background.
- **Lock screen music on Void** (NIRULOCK 0.26.1). Void's sidplayfp 3.2.3 is
  built with sidlite only but still asks for reSIDfp, so every tune failed
  ("Requested SID emulation not built in") and the lock stayed silent.
  NIRULOCK reads what the player was built with and passes `--sidlite` there.

## 0.12.277 (2026-11-14)

- **No keyring prompt after login** (NIRUWM 0.31.3). The session hook added in
  0.12.276 woke the keyring that PAM starts at login even where that keyring
  could not unlock, and it then asked for a password, while the machine's own
  unlock (here a D-Bus service that unlocks the keyring by itself) never got
  to run. The hook is gone, and the session starts exactly as in NIRUWM 0.31.1.
  The keyring package and NIRU Login's PAM lines stay: where the keyring has
  the login password, logging in is all it takes.

## 0.12.276 (2026-11-14)

- **Saved logins survive a reboot.** NIRUX now installs gnome-keyring on Arch,
  Debian and Void (with `libpam-gnome-keyring` on Debian), and NIRU Login
  unlocks it with your password. Before, a machine without it
  made the Nextcloud client ask for its login after every reboot. On Arch and
  Void the greetd PAM file gets two marked lines once (Debian's file already
  has them), and removing NIRU Login takes them out again. The session hands
  its D-Bus to the keyring that PAM started, which Void needs (NIRUWM 0.31.2),
  and starts nothing when no keyring runs. `nirux doctor` says whether the
  keyring runs; after the first install, log out and in once.

## 0.12.275 (2026-11-14)

- **The sound doctor leaves working fallback profiles alone** (NIRUIO 0.1.1).
  A card in a fallback profile is reported once, not once per output and
  input, and only as information when its outputs and inputs work, as on the
  HP ZBook 8 G1a. It never offers Pro Audio or a profile that would lose the
  speakers or the microphone, so `niruio doctor --fix` and `nirux doctor --fix`
  no longer change such a card. Information and warnings never make
  `nirux doctor` fail; only real problems do.

## 0.12.274 (2026-11-14)

- **NIRUIO, the new sound tool** (core component, NIRUIO 0.1.0). One terminal
  window with every output, input, program and camera: live level meters,
  volume up to 150 %, mute, balance, the default device, ports and card
  profiles, ALSA microphone boost, a five second mic test, a meter per input of
  a multichannel interface such as the UMC1820, and moving a program to
  another device. `Super+Shift+A` (NIRUWM 0.31.1) opens it as a centred
  floating window, and the launcher's sound and actions views have an
  **Open NIRUIO** row (NIRU Launcher 0.15.0).
- **Remembered mutes are visible and reversible.** WirePlumber remembers volume
  and mute per media role and per program; one muted video in mpv mutes every
  video after it, because mpv tags them all as `Movie`. NIRUIO's Saved tab and
  `niruio saved` list these entries, and a reset (`niruio reset --silencing`)
  goes through WirePlumber itself, without playing anything.
- **A sound doctor.** `niruio doctor` follows the sound from the program to the
  device: the remembered role or program setting, a muted or silent device, a
  fallback card profile, an unplugged port, an ALSA switch that is off, a
  missing device, and for cameras access and which program holds them. Each
  finding has a fix; `niruio doctor --fix` applies them. `nirux doctor` shows
  its findings and `nirux doctor --fix` offers its fixes.
- **Cameras and NIRUCLIP.** NIRUIO's Cameras tab shows which program holds a
  camera, its formats and its controls (brightness, exposure, focus, white
  balance), a live preview (pictures in kitty), and sets NIRUCLIP's camera; the
  In tab sets the inputs NIRUCLIP records from a multichannel interface.
- **Bluetooth headsets** switch between hi-fi playback and headset mode with a
  microphone in NIRUIO's Cards tab, with the codec shown.

## 0.12.273 (2026-11-13)

- **The nightly update also runs behind a locked screen.** A desktop session
  that is left locked overnight now counts as away, so computers that stay
  logged in are updated too. An unlocked desktop, an SSH login or a text
  console still makes it wait, and it never logs you out or restarts the window
  manager. `nirux autoupdate` shows whether the computer counts as in use now.

## 0.12.272 (2026-11-13)

- **A night light that glides.** NIRUWM 0.30.0 adds `mode = "gradual"`, now the
  default: the evening starts at sunset but never before 19:00
  (`not_before`), at 4500 K (`start_temperature`), and grows warmer in steps
  too small to see until 2700 K (`temperature`) at 22:00 (`deepest_at`), or one
  hour after the start after a late summer sunset. In the morning it glides
  back to 6500 K over 30 minutes, done by sunrise or 07:00 (`off`), whichever
  is earlier. `Super+N` works as before; `niructl nightlight status` shows
  tonight's start, deepest time and morning.
- **Night-light edits apply within seconds.** The watcher reads `config.toml`
  again when it changes and applies the new settings at once, also a switch
  between `manual` and a schedule, without a new login. A file with a mistake
  keeps the last good settings.
- **Existing installations move to gradual once.** A `[nightlight]` that still
  has the previous defaults (`solar`, 2700 K, 20:00, 07:00, 6500 K, any
  location) becomes `gradual` with the new keys on the next `nirux update`;
  the file as it was goes to the config history (`niructl config undo`). Any
  other choice is kept, and setting `solar` again later is never undone.
- **NIRUBAR 0.28.0** accepts the new night-light keys in the shared file.

## 0.12.271 (2026-11-13)

- **Videos and calls keep the screen awake.** NIRUWM 0.29.0: NIRUIDLE answers
  programs that ask the screen to stay awake (Helium during a video or a Teams
  call, VLC), so the screensaver and idle lock wait while they play;
  `[idle] honor_app_inhibit = false` turns that off and `niructl idle status`
  lists the requests.
- **Screensaver history in the log.** NIRUIDLE, NIRUNOTIFY and the night light
  watcher now write to the session log also after a restart in place (they
  went to nowhere), and PATH no longer grows with every restart.
- **Video on the graphics card in Helium.** Videos in the managed Helium are
  decoded by the GPU instead of the CPU (measured: 1080p H264, VP9 and AV1 from
  about 95 % of a core to about 32 %); web calls such as Teams use the same
  decoder. NIRUX finds the
  card that drives the display, installs its VA-API and Vulkan drivers, checks
  them with `vainfo` and `vulkaninfo`, and only then starts Helium with the
  Vulkan video path. AMD and Intel are on by default, NVIDIA is opt-in;
  `[browser] hardware_video = "auto"|"on"|"off"` in the new NIRUX-only
  `~/.config/nirux/browser.toml`. `nirux doctor` shows the card, the formats it
  decodes and the flags; `nirux doctor --fix` installs what is missing. The
  nightly update never turns it on by itself the first time.
- **A Helium launcher.** `~/.local/bin/helium` is now a small NIRUX launcher
  that adds these flags (your own flags still win), not a link; it is
  rewritten on every install and update.
- The nightly update may now install Void packages whose names start with a
  capital letter (`Vulkan-Tools`).

## 0.12.270 (2026-11-13)

- **Presenting you can see.** NIRUPRES 2.4.0: the fade in and out now show in
  the presenter view too (in laptop mode they only happened behind it), aim
  Spotlight, Focus and Zoom by pointing at the current slide in the presenter
  view, and Next on the last slide fades to black. Fixes: notes size at start,
  keys with Ctrl/Shift, zoom near the edge, see-through windows under picom.

## 0.12.269 (2026-11-13)

- **Safe presenting in Teams.** NIRUPRES 2.3.0 names its windows so the share
  dialog cannot mix them up (`AUDIENCE · share this · NIRUPRES` and a red
  `PRIVATE presenter · do not share`), checks the share before you start, and
  gives a laptop presenter view with notes, next slide and timer on one screen.
- **Switch workspaces while you present.** NIRUWM keeps the shared audience
  window live while you look elsewhere (`_NIRUWM_KEEP_MAPPED`); before, the
  audience saw a frozen slide.
- **Presenting mode.** `niructl present on|off|status` turns on Do Not Disturb
  and hides private bar modules (`[bar] presenting_hide`); NIRUPRES uses it and
  it ends by itself if NIRUPRES stops.
- **Slides that fit.** Text shrinks to fit its box and never spills over;
  deck health marks slides that do not fit. New layouts: CODE, IMAGE +
  CAPTION, THREE COLUMN; tables wrap.
- NIRUWM 0.28.0, NIRUBAR 0.27.0, NIRUPRES 2.3.0 (extra).

## 0.12.268 (2026-11-13)

- **Nightly updates.** Between 03:00 and 05:00, when nobody is logged in, the
  computer updates its system packages, NIRUX, the extras and the apps by
  itself. `nirux doctor` runs before and after; if something got worse, the
  previous NIRUX and settings come back and a warning is posted. On battery it
  waits for the charger or 50 %. `nirux autoupdate status|last|disable` (on by
  default; Debian, Arch and Void).
- **Apps follow upstream.** Helium, LocalSend and OpenCode update to their
  newest stable release at every `nirux update`, verified against the
  publisher's checksum; the version NIRUX names is the lowest it installs
  (Helium 0.21.2.1, OpenCode 2.2.7). `--apps pinned` keeps the pins.
- **Disk warning in the bar.** A red disk icon left of the gear appears when
  the disk is 90 % full (`[bar] disk_warn`); a click runs `nirux clean`, which
  shows what it would remove and asks first.
- **Fixes after sleep.** After a wake-up NIRUX checks Wi-Fi, sound, screens
  and Tailscale and repairs the common failures; a notice only when it fixed
  something or could not (`nirux resume-check`).
- **Battery health.** The battery panel shows the health in percent of the
  design capacity, the charge cycles and a graph of the last 24 hours.
- **What's new after an update.** The first login on a new version shows its
  highlights once, with a button to the manual (`nirux whats-new`).
- **The bar follows the NIRUX defaults.** Every `nirux update` keeps
  `[bar] modules` on the default list and order, which now includes `updates`
  (system package count) and `disk`; the previous list stays in the settings
  history (`niructl config undo`). `follow_default_modules = false` keeps your
  own list.
- NIRUWM 0.27.1, NIRUBAR 0.26.1.

## 0.12.267 (2026-11-12)

- `nirux extras update` installs NIRUDICTATE 0.3.0 (voice commands); 0.12.266
  had the wrong checksum for it and kept 0.2.1.

## 0.12.266 (2026-11-12)

- **Voice commands: `Super+Alt+Space`** (NIRUDICTATE 0.3.0, an extra). Say
  "öppna terminalen", "open the browser", "gå till arbetsyta tre", "lås
  skärmen", "höj volymen", "anteckning köp mjölk" and more, in Swedish or
  English. A fixed, local list, no AI and never an arbitrary command; closing
  a window and the power commands ask first. `nirudictate command list` shows
  every phrase.
- **Workspace overview: `Super+E`.** Every workspace on every screen as a
  small picture with its window titles; a digit, the arrows or a click go
  there. Pictures stay in memory, only for you, and are deleted when the
  screen locks (NIRUWM 0.26.0, NIRULAUNCHER 0.14.0).
- **`niructl do ACTION`** runs any key binding's action by name from a script
  (`niructl do terminal`, `niructl do tag 3`); it never starts arbitrary
  programs.
- **Privacy dot in the bar.** A red dot while an app uses the microphone, a
  camera or NIRUCLIP screen recording; click it to see which (NIRUBAR
  0.25.0). Added to existing bars once.
- **The power profile follows the charger:** `power-saver` on battery,
  `balanced` on the charger, on laptops. `[battery] auto_profile`,
  `profile_on_battery`, `profile_on_ac`; a profile you pick yourself holds
  until the next plug or unplug, and studio mode still wins.
- **Typewriter clicks in the lock screen** while you type the password
  (`lock-typing`, on by default; `nirux sounds toggle lock-typing` turns it
  off). NIRULOCK 0.26.0, NIRUNOTIFY 0.6.0, which can also pick between
  `EVENT-2.ogg`, `EVENT-3.ogg` variants of any sound.
- **`nirux doctor --fix`** repairs what doctor finds and can safely fix:
  missing packages, the backlight and battery udev rules, a missing bar,
  notification daemon, idle daemon or night-light schedule, and PipeWire
  user services. It asks once (`--yes` for scripts).
- Fixed: after the 0.12.264 update the night light schedule did not start
  until the next login; restarting NIRUWM in place now starts a missing
  night-light or power-profile watcher.

## 0.12.265 (2026-11-12)

- The window jump (`Ctrl+Alt+W`) shows the letters on its labels; in
  0.12.264 they were plain boxes (NIRULAUNCHER 0.13.1).

## 0.12.264 (2026-11-12)

- **Jump to a window: `Ctrl+Alt+W`.** Every visible window on every screen
  gets a short label; type it and that window has the focus. Letters by
  default (home row first), or numbers with `[hints] style = "numbers"` in
  `~/.config/nirulauncher/config.toml` (NIRULAUNCHER 0.13.0).
- **Quick note: `Super+Shift+N`.** One line, added to `~/Notes/inbox.md`
  (`[note] file`) with the time, for NIRUNOTE or any editor. Before `Enter`,
  `↑`/`↓` choose whether it also goes to a Discord webhook or a trusted
  device through NIRUSHARE.
- **The night light follows the sun by default:** warm, reddish 2700 K from
  sunset to sunrise. `Super+N` switches it by hand until the next sunset or
  sunrise; `mode = "manual"` turns the schedule off. Without a location it
  uses Stockholm's. `nirux update` moves a file that still has the old
  defaults (manual, 3400 K) to the schedule once. The schedule changes the
  temperature without notifications.
- **Battery charge limit, 80 % by default** (`[battery] charge_limit`, 100
  for no limit). It is set at every login by `niructl battery`; *Charge to
  100 % once* in Quick Settings (or `niructl battery full`) lasts until the
  next login. It needs firmware support, which `niructl battery status` and
  `nirux doctor` report; many HP models lack it. NIRUX installs a udev rule
  so the limit can be set without root; log in again after the first
  installation. `nirux update` adds the `[battery]` section to the file.

## 0.12.263 (2026-11-12)

- **Settings history and undo.** NIRUWM 0.25.1 keeps every version of
  `config.toml` that loads (the last 30, in
  `~/.local/state/niruwm/config-history/`). `niructl config history` lists
  them with the sections each one changed, `niructl config undo` goes back
  one version (again for one more), `niructl config restore N` picks one and
  `niructl config diff N` shows what changed since. Each command prints the
  change and asks first; `--yes` applies at once. The file being replaced is
  kept first, so every step can be undone, and the session reloads.
- **What you have changed.** `niructl config diff` lists only the values
  that differ from the defaults (changed, added, removed); `--all` also names
  the default keys your file does not have.
- **Reset one part.** `niructl config reset bar` (any section, a key such as
  `bar.modules`, or `all`) takes that part from the NIRUX example, comments
  included, and leaves the rest of the file alone. The picture folders NIRUX
  chose for this machine are kept. `reset all` also works when the file no
  longer parses.
- **The bar reset no longer loses the previous backup.** `nirubar
  --reset-config` (NIRUBAR 0.24.0) runs the reset above, keeps the old file
  in the history instead of overwriting one backup file, and reloads the bars
  itself.
- **`Super+A`, Appearance:** *Undo the last settings change*, *Settings
  history* and *Settings that differ from the defaults* (NIRULAUNCHER 0.12.1).
- **New default bar modules** for new installations and resets: workspaces,
  dictation, recording, scratchpad, layout, media, volume, microphone,
  brightness, display, tailscale, network, wifi, mode, battery, niruxupdate,
  agent, nirusec, dnd, quicksettings, share and clock. Modules for something
  that is not installed (NIRUDICTATE, NIRUSEC, Tailscale, a battery) show
  nothing. An existing `modules` list is not changed.

## 0.12.262 (2026-11-11)

- **An update no longer removes the NIRUX Signature pictures.** The update
  that installs the release's own Noir picture removed other NIRUX pictures
  it did not recognise, and the Signature set (0.12.258) was missing from the
  list it keeps. Run `nirux wallpapers download signature` once if your
  Signature pictures are gone.

## 0.12.261 (2026-11-11)

- **The bar keeps your settings with the Signature wallpaper style (NIRUBAR
  0.23.2, NIRUWM 0.24.4).** NIRUBAR did not know `[wallpaper] theme_style`,
  which `nirux wallpapers style signature` writes. It refused every reload,
  and from 0.12.260 a restarted bar fell back to the default modules. It now
  accepts the key, and when the bar itself has to fall back it says so in a
  notification. `tests/config-contract.sh` checks every key NIRUWM writes
  against NIRUBAR.
- **New wallpapers for seven themes, same colours, new style:** Nord, Forest
  Vigil, Blood of Urðr, Root and Stone, Blue Horizon, The Norns and Winter
  Nights (4K and 8K, nirux-wallpapers v1.2.0). `nirux update` replaces the
  old pictures of the themes you have; a picture you changed yourself stays.
  Satie, Carl Larsson, the extras and Signature are unchanged.

## 0.12.260 (2026-11-11)

(0.12.259 did not publish: NIRUWM had to bundle the new NIRUBAR.)
Nothing to fiddle with after an install:

- **A typing error in the settings no longer logs you out (NIRUWM 0.24.3,
  NIRUBAR 0.23.1).** A stray character in `config.toml` used to stop the bar
  and, at the next login, end the session straight back at the login screen.
  Now both start with the last settings that worked (or the defaults), and a
  notification says where the error is, such as `config.toml line 213`. Fix
  it and reload with `Super+Shift+R`.
- **Tailscale at install.** `nirux install` asks (default yes), installs and
  starts Tailscale on Void, Arch and Debian and shows the link that adds the
  computer to your network. `--tailscale yes|no` chooses it without asking;
  an update changes nothing unless the flag is given.
- **Touchpads tap from the start.** On machines with a touchpad: one finger
  clicks, two right-click, three middle-click, tap and drag, two-finger
  scrolling, and no taps while typing, also on the login screen.
- **Void: sound on every start.** A sound card whose firmware loads late
  (Intel SOF laptops) appeared while runit handed udevd over and stayed
  root-only, so PipeWire offered only "Dummy Output". The new runit service
  `nirux-udev-replay` replays those device events once at start.
- Manual chapters 1 and 13.

## 0.12.258 (2026-11-11)

- **A new default wallpaper.** The Noir picture is now a misty Swedish lake
  (photo by Nicklas Rudolfsson, 2025), 4K and 8K. It replaces the old one on
  update unless you changed the file yourself.
- **NIRUX Signature (NIRUWM 0.24.1).** Every built-in theme can show the same
  photograph toned in its own colours instead of its own artwork:
  `nirux wallpapers style signature` (downloads the 47 MiB pack the first
  time), `Alt+S` in NIRU Theme Selector 0.3.0 or `S` in NIRU Wallpaper 0.3.0.
  Art stays the default; the login screen follows the chosen style.
- Manual chapter 8 and docs/WALLPAPERS.md: Art or Signature.

## 0.12.257 (2026-11-11)

- **Void: elogind no longer restarts every second.** At boot the login
  screen asked for logind before runit had started elogind, D-Bus started a
  copy of its own, and the runit service failed in a loop for as long as the
  machine ran. NIRUX now installs a D-Bus activation file that asks runit to
  start its supervised elogind instead. It takes effect at the next start.

## 0.12.256 (2026-11-11)

- **`nirux checkup` and the Wi-Fi helper no longer ask for a password on
  Void.** sudo uses the last matching rule, and Void's wheel rule sorted
  after the NIRUX rules. The rules are now `zz-nirux-checkup` and
  `zz-nirux-wifi` in `/etc/sudoers.d`, which sort last (sudo and sudo-rs).

## 0.12.255 (2026-11-11)

- **A weekly checkup on every computer (`nirux checkup`).** Monday 07:00,
  or at start when it was missed: disks and the EFI partition, SMART and
  NVMe health, failed services, reboot needed, waiting and security updates,
  NIRUX behind, snapshot age, OOM kills, time sync, Tailscale, firewall and
  battery health. It also cleans the package cache, unused packages and old
  kernels, the journal, coredumps, old temporary files and thumbnails. The
  last three reports are kept, and with a webhook each computer posts its
  report to Discord. Root-owned helper, systemd timer or runit service.
- `smartmontools` (and `pacman-contrib` on Arch) are now installed with NIRUX.
- Manual chapter 11: Weekly checkup.

## 0.12.254 (2026-11-10)

- **NIRUFETCH 0.3.0: a distribution mark in the theme's colours.** A small
  Debian, Arch, Void, Ubuntu or Fedora mark (Tux for others) beside the
  summary, a strip of the terminal colours, and the machine model (`Host`).
  `--full` adds the init system and names displays as xrandr does.
  `~/.config/nirufetch/config.toml` turns the mark off, picks the NIRUX rune
  or the distribution's colours, hides the strip, and chooses the rows.
- Manual chapter 12 and the configuration reference cover the new settings.

## 0.12.253 (2026-11-10)

- **A new volume and brightness OSD (NIRUNOTIFY 0.5.0).** An icon, the name,
  the value in large type and a level bar in the theme accent that glides to
  the new level. A held key keeps the same box, `Muted` shows the last level
  greyed out, and pressing against 0 % or 100 % lights the bar briefly.
- **Notifications and the OSD appear on the focused screen.** Before, the
  screen was chosen once when the session started, so with several screens
  they could land on the wrong screen or across two. They now follow the
  NIRUWM focused screen, keep clear of that screen's bar only, and move at
  once on hotplug or docking. `monitor = "pointer"`, `"primary"` or an output
  name in `nirunotify/config.toml` choose differently.
- Manual chapter 10: the OSD and screen choice.

## 0.12.252 (2026-11-10)

- **Closing the lid while docked locks (NIRUWM 0.23.3).** With external
  screens the laptop stays awake as before, but the screen now locks.
  `[idle] lock_on_lid_close = false` turns it off. Undocked, the lid locks and
  suspends as before.

## 0.12.251 (2026-11-10)

- **An update waiting for the unlock is not lost (NIRUWM 0.23.2).** When the
  screen was locked again within seconds of an unlock, the in-place restart
  gave up until the next login; it now waits for the next unlock.
- The sound rate limit no longer depends on a printf in a command
  substitution (a held volume key could tick twice).

## 0.12.250 (2026-11-10)

- **Locking works while the screensaver is up (NIRUWM 0.23.1).** A manual
  lock, `Super+Shift+Escape` or the lock before a lid-close suspend failed
  while NIRUSCREENSAVER held the pointer; the screensaver is now closed first.
- **The display no longer goes dark before the lock.** The X server's own
  10-minute blank and DPMS timers are kept at zero, so the idle ladder
  (screensaver, lock, display off) runs as configured.
- Manual chapter 6: these fixes, lid behaviour when docked, and how to make
  the idle lock come sooner.

## 0.12.249 (2026-11-10)

- **Updates without logging out (NIRUWM 0.23.0).** `nirux update` inside a
  session now runs `niructl restart-wm`: the window manager, bars and changed
  helpers restart in place with every window, workspace, layout and scratchpad
  kept. A locked screen stays locked; the restart waits for the unlock. A
  session on NIRUWM older than 0.23.0 needs one last login.
- **`lock_after_screensaver = 0` locks.** It locks at `screensaver_timeout`
  instead of only showing the screensaver.
- **Calendar reminders (NIRUBAR 0.23.0).** A notification before timed events,
  10 minutes by default; `remind_minutes` in `calendars.toml` (0 = off).
- **NIRUNOTE 0.7.1.** Full CommonMark and GitHub Markdown in the preview
  (tables, footnotes, alerts, highlighted code), `--read-only`, `--heading`,
  find in the preview, back after links, faster on big files. `nirux manual`
  opens read-only at the chosen heading.
- **Fleet health.** `nirux fleet` has a HEALTH column: disk, failed units,
  stale sessions and lock readiness (also in `--json`).
- **Multichannel inputs (NIRUCLIP 0.7.0, NIRULAUNCHER 0.11.0).** Record one
  input or a pair of an interface such as the UMC1820 with `--mic-channels`;
  the launcher's Capture view shows a Mic inputs row only when such an
  interface is present.

## 0.12.248 (2026-11-09)

- **Panels you read stay open (NIRUBAR 0.22.1, NIRUWM 0.22.4).** The calendar,
  weather, tasks, pulse and notifications panels stay until you close them
  (click or Escape); quick-glance panels still close after
  `popup_timeout_seconds`. Per-panel timeouts in `[popup_timeout]` of
  `~/.config/nirubar/config.toml`.
- **Calendar changes apply by themselves.** `calendars.toml` is re-read when
  it changes and on `niructl reload`; new calendars are fetched at once.
- The manual (chapter 4) describes calendar events and panel timeouts.

## 0.12.247 (2026-11-09)

- **NIRUCLIP 0.6.1: the HP laptop camera no longer switches off after a
  second.** NIRUCLIP turned the camera's dynamic exposure framerate off for a
  steady 30 fps; the HP 5MP camera answers that with its privacy image. The
  setting is now opt-in (`camera_steady_framerate = true`).

## 0.12.246 (2026-11-09)

- **The NIRUX manual.** A thorough English manual ships with every release
  and matches the installed version: `nirux manual [TOPIC]`, Super+Shift+F1 or
  the launcher's Manual view (NIRU Launcher 0.10.0, NIRUWM 0.22.3). Key
  bindings, niructl commands and the configuration reference are generated
  and checked before each release.
- **Calendar events in the clock popup (NIRUBAR 0.21.0).** Read-only Google
  Calendar (or any iCal) feeds from `~/.config/nirubar/calendars.toml` (mode
  600): dots on days with events, the next days listed, a click opens the
  calendar on that date. See the manual, chapter 4.
- **NIRUCLIP 0.6.0:** `--mic SOURCE` and `--list-mics` record from a chosen
  microphone without changing the system default; `mic = "..."` per profile.

- **The NIRUX manual.** An English manual in `docs/manual/` (16 chapters:
  getting started, windows and layouts, workspaces and scratchpads, the bar,
  the launcher, lock and screensaver, capture, themes, displays, sound and
  notifications, updates, extras, troubleshooting, and generated configuration,
  key binding and command references). It ships with every release as
  `nirux-manual.tar.xz` and is installed read-only into the program generation
  (`~/.local/share/nirux/current/manual`), so it matches the installed
  programs, works offline and follows a rollback.
- **`nirux manual [TOPIC]`** opens it: the index, or a chapter or heading by
  number, name, heading text, `CHAPTER#ANCHOR` or a Swedish word (`lås`,
  `skärmdump`, `studioläge`). It uses NIRUNOTE when installed, else `xdg-open`,
  else `less` at the heading. `--list` lists the chapters, `--path` prints the
  directory, `--where TOPIC` prints the file and line. `nirux status` names the
  installed manual.
- **Generated sections stay current.** `tools/manual-gen.sh` regenerates the
  key bindings (`niructl keys --markdown` for a fresh NIRUX configuration), the
  niructl command list and the configuration reference from vendored inputs in
  `tools/manual-inputs/`; `--refresh` fetches them for the versions pinned in
  `manifest`. `tests/manual.sh` (CI and the release workflow) fails on a stale
  section or input, a `nirux` command without an entry, a broken link or
  anchor, or a long dash.

## 0.12.245 (2026-11-09)

- **The lock screen plays SID music only when you lock it yourself
  (NIRULOCK 0.25.0, NIRUWM 0.22.1, NIRU Launcher 0.9.0).** Super+Escape, the
  launcher, Quick Settings and `niructl lock` typed in a terminal are manual
  locks; idle locks, suspend, lid and scripts (`niructl lock --silent`) lock
  silently. Esc still returns to the quotes. `[pause_music] on = [...]`
  changes which locks play.
- **Super+Ctrl+O** copies the text in a screen region (`nirushot ocr`).

- **Text from the screen (NIRUSHOT 0.7.0).** `nirushot ocr` reads the text in
  a selected region (Swedish and English) and copies it. tesseract with Swedish
  and English data is now installed with NIRUX on Debian, Arch and Void.

- **GitLab mirror as a fallback source.** When GitHub still fails after its
  retries, a NIRUX release asset (and the latest-release lookup) comes from the
  public backup mirror on GitLab.com (`gitlab.com/rudolfsson/<repo>`, generic
  packages at the same repo/version/file). SHA256SUMS still has to match.
  `NIRUX_MIRROR=none` turns it off.

- **Configuration snapshots: `nirux snapshot` and `nirux restore`.** Every
  `nirux update` first saves the suite configuration to
  `~/.local/state/nirux/snapshots/<time>-<from>-to-<to>.tar.gz` with a
  manifest (file list, sizes, SHA-256). A newer target installer takes it
  when the running installer predates snapshots. `nirux extras update` (when
  it installs something) and `nirux reset-config` take one too. Included: the
  suite's and the extras' config directories, picom/kitty/fish files NIRUX
  writes, registered keys and launcher favourites. Left out: nirushare (upload
  token), token/password-like files (reported), files over 16 MiB, caches,
  state and music. `[snapshots] keep = 3` and `strict = false` in
  `~/.config/nirux/snapshots.toml`; a failed snapshot warns and the update
  goes on unless strict. `nirux snapshot [--note TEXT]`, `nirux snapshot list`,
  `nirux restore [ID|latest] [--dry-run] [--yes]`: a file list with line
  counts, y/N, a safety snapshot first, and what to reload afterwards.
  `nirux rollback` now points to restore for configuration.
- **`nirux sync`: share settings between your NIRUX machines.** Over the
  `nirux fleet` SSH access: `sync status [HOST...]` (same, changed, only here,
  only there and excluded per item, by content hash), `sync push HOST...|--all
  [ITEM...]` and `sync pull HOST [ITEM...]` with a preview, y/N (`--yes`,
  `--dry-run`) and a snapshot on the receiving machine first (a backup tarball
  on an older NIRUX). Items: quotes, keys.d, theme, lock, launcher, sounds and
  sid; `[sync] items`/`exclude` in `~/.config/nirux/sync.toml`. NIRUWM's
  `config.toml` is never copied whole (monitors and displays are per machine);
  only its `theme` key travels. Display profiles, secrets, state and caches
  are never synced, and nothing is deleted on the receiver. rsync when both
  ends have it, else tar over SSH; no new dependencies. From a machine
  without NIRUX, `sync status HOST1 HOST2` compares the hosts with each other.
- New tests `tests/snapshot.sh` and `tests/sync.sh` (fake ssh, remote homes
  as local directories) run in CI and are shellchecked.

## 0.12.244 (2026-11-09)

- **Studio mode (NIRUWM 0.20.0, NIRUBAR 0.20.0, NIRU Launcher 0.8.0).**
  `niructl studio on|off|toggle`, a Quick Settings row, the `studio_toggle`
  action and the phrases "studio mode"/"studioläge": pauses idle locking for
  the session, turns on Do Not Disturb, stops the compositor and sets the
  performance power profile; off restores exactly what it changed. The bar
  shows it. Optional `[studio]` settings, including auto-enable for REAPER
  (off by default).
- **NIRU Launcher 0.8.0:** a window swallowing toggle in Quick Settings and
  NIRU Actions; no "/ for files" hint when file search is off; optional
  `[files] locate_db`, and real plocate verified.
- **NIRUCLIP 0.5.1: the camera recovers.** A camera that is unplugged or
  stalls during a recording is reattached when it returns (the screen keeps
  recording meanwhile); the camera check always runs before a recording, also
  with a short countdown; the HP "camera off" placeholder makes NIRUCLIP reopen
  the camera in another mode.

- **`nirux fleet`: see and update all your NIRUX machines.** `nirux fleet`
  (or `fleet status`, `--json`) lists the Linux Tailscale peers that have
  NIRUX, asked in parallel with a short timeout: online/offline, version,
  behind the latest release, relogin needed (running NIRUWM/NIRUBAR not the
  active generation's binary), locked, distribution, uptime and last update.
  Offline machines seen before are listed with their last version; machines
  without SSH key access show *no access*. `nirux fleet update HOST...|--all|--behind`
  runs `nirux update` (and `nirux extras update` when extras are selected)
  host by host over `ssh -t`, so sudo asks in your terminal, and never logs
  anyone out. `nirux fleet setup` is a one-time, confirmed helper that creates
  an ed25519 key if needed, runs `ssh-copy-id` and verifies key login; it
  changes no Tailscale, sshd or PAM settings. Hosts can be fixed with
  `[fleet] hosts`/`exclude` in `~/.config/nirux/fleet.toml`. Remote commands
  are `sh -s` with the script on standard input, so a fish login shell works.
  New test `tests/fleet.sh`.

## 0.12.243 (2026-11-09)

- **`nirux update` survives GitHub 504s.** GitHub caches a failed response
  per URL, so retrying the same download failed the same way for minutes and
  updates stopped with a 504. Every attempt now asks with its own query (same
  asset, same checksum), up to eight attempts with a short backoff
  (`NIRUX_FETCH_ATTEMPTS` changes the count). A failed download leaves no
  partial file. New test `tests/fetch-retry.sh`.

## 0.12.242 (2026-11-09)

- **NIRUWM 0.19.1: tiles stay below floating windows.** A tiled window that
  took the focus (the pointer crossing into it, a click, a new window) went to
  the very top, so a NIRUSHOT review window or an Open/Save dialog that
  overlapped two tiles ended up half under one of them. A focused tile now
  stays below every floating window; only its own dialogs go on top.
- **Super+O** opens the NIRU Launcher file search.

## 0.12.241 (2026-11-09)

- **NIRUWM 0.19.0: urgent windows and window swallowing.**
  - A window that asks for attention (the urgency hint or
    `_NET_WM_STATE_DEMANDS_ATTENTION`) gets the theme's attention colour on its
    border and its workspace cell in NIRUBAR. `Super+Shift+U` jumps to the most
    recent one, switching screen, workspace or scratchpad as needed;
    `niructl urgent` lists them.
  - A graphical program started from a terminal takes the terminal's place, and
    the terminal comes back when the program closes. On by default for common
    terminals; `[swallow]` in `config.toml` changes it and
    `niructl swallow on|off|toggle` switches it for the session. Existing
    configuration files need no changes.
- **NIRUBAR 0.19.0** paints urgent workspace cells and marks an urgent
  scratchpad. NIRUWM 0.19.0 bundles it.
- **NIRU Launcher 0.6.0: file search.** Type `/` and a query in the launcher,
  or choose *Find files* in NIRU Actions. Searches the home folder (hidden
  folders, caches and build folders skipped) with recent files first; Enter
  opens, Ctrl+Enter opens the folder, Shift+Enter copies the path.

## 0.12.240 (2026-11-08)

- Supersedes 0.12.239, which was tagged but not published: NIRUWM bundles
  NIRUBAR, so the new NIRUBAR needs NIRUWM 0.18.3 (bundles NIRUBAR 0.18.91;
  no window manager changes).
- **NIRUCLIP 0.4.0: the camera works properly.** It used to record whatever
  mode the camera driver last used, YUYV 640x480 on most webcams (camera-only
  clips were 640x480 at about 40 kb/s with many repeated frames). It now asks
  for MJPEG 1280x720 for the overlay and 1920x1080 for camera-only, skips
  infrared and metadata nodes, and keeps camera, screen and microphone on one
  clock, so the overlay face no longer lags the voice by about 0.3 s.
  A camera that shows its privacy image (such as HP's crossed-out camera),
  freezes, stops delivering frames or is in use by another program is
  detected during the countdown and while recording, and reported in a
  notification, `niruclip --status`, NIRUBAR and NIRU Launcher. The overlay
  is sized from the video height with the camera's aspect, rounded (or
  circle/rect) with a thin theme-coloured border, and can be mirrored. New:
  `--check-camera`, `--preview`, `--export mp4|gif` and `--share`.
- **NIRU Launcher 0.5.1:** the capture view (`--clip`) has Check camera,
  Camera preview, Last recording to MP4/GIF and Share last recording, and
  shows a camera problem while recording.
- **NIRUBAR 0.18.91:** the recording timer shows `· cam off` or `· cam !`
  when NIRUCLIP reports a camera problem.

## 0.12.238 (2026-11-08)

- **NIRULOCK 0.23.1 and NIRUSCREENSAVER 0.14.1:** includes everything listed
  for 0.12.237, which was tagged but never published because GitHub's
  release downloads failed (504) during its release check. Also, Esc during
  the pause music now brings the quote back within about a second. Before,
  a flat spectrum stayed for about six seconds while the audio detector's
  silence window ran out. Other music that is really playing keeps the
  spectrum.

## 0.12.237 (2026-11-08)

- **NIRULOCK 0.23.0 and NIRUSCREENSAVER 0.14.0:** a cleaner, properly centred
  lock and idle screen, with the same elements, colours and fonts. Every
  line is centred by its glyph ink; before, the clock sat 5–8 px right of
  centre and "password:" 3 px left. The `cava` layout is one evenly spaced
  column at the optical centre of the prompt output. Rows for a failure or
  PAM message, Caps Lock and the pause-music line are reserved, so the entry
  never moves, and typing no longer slides it. Long PAM messages wrap to two
  lines, the music line is cut to the panel, quotes wrap evenly, and the
  spectrum lines up with its bars. CAVA pacing is unchanged.

## 0.12.236 (2026-11-08)

- **NIRULOCK 0.22.2:** pause music was silent on sessions started from a text
  console (void), although the lock showed the tune: sidplayfp's own
  `/dev/tty` keyboard handling got it stopped by SIGTTOU as a background
  process group. The player now runs in its own session without a terminal.

## 0.12.235 (2026-11-08)

- **NIRULOCK 0.22.1 and NIRUSCREENSAVER 0.13.1:** the CAVA spectrum is smooth
  now, like NIRUAMP's. It was repainted on a 30 fps timer of its own that
  drifted against CAVA's clock, so a frame was shown twice and another skipped
  every second or so (in bursts lasting several seconds) and each frame was up
  to 34 ms late. Each CAVA frame is now painted the moment it arrives: no
  repeated or skipped frames and 0.1 ms from arrival to paint. Silence pause,
  display-off stop and pause music are unchanged.

## 0.12.234 (2026-11-08)

- **NIRUWM 0.18.1:** on Swedish, German and other layouts where `/` is
  Shift+7, the new Super+/ cheat-sheet key took over Super+7, which opened the
  cheat sheet instead of workspace 7. Now the binding for what a key types
  without Shift wins, so Super+7 is workspace 7 again, and **Super+F1** opens
  the cheat sheet on every layout. The dropped key is named in the session
  log.
- `config.example.toml` and the README list Super+F1.

## 0.12.233 (2026-11-08)

New keys, a color picker and pause music on the lock screen.

- **NIRUWM 0.18.0:** `niructl keys --json` is the live source for a
  keybinding cheat sheet; `[[keys]]` takes an optional `description`; programs
  register their own keys in `~/.local/share/niru/keys.d/<app>.toml`.
  New default keys:
  - `Super+/` keybinding cheat sheet;
  - `Super+.` emoji and symbols;
  - `Super+Ctrl+C` color picker.
  - **Moved:** "focus the next screen" is now `Super+Alt+.` (it was `Super+.`),
    with `Super+Alt+,` as its pair. `Super+,` still focuses the previous
    screen. Add one `[[keys]]` entry to get the old key back.
  - Bundles NIRUBAR 0.18.90 (unchanged).
- **NIRULAUNCHER 0.5.0:** the cheat sheet (`--keys`: grouped, search by words
  or key, Enter runs, Ctrl+R tells what a combo does, clashes flagged), the
  emoji and symbol picker (`--emoji`, `:name` in the launcher; recents, skin
  tones, Enter pastes and restores the clipboard, Shift+Enter copies) and a
  Colors view (`--colors`) of the last ten picked colors.
- **NIRUSHOT 0.6.0:** `nirushot pick`, a freeze-frame color picker with a
  loupe; arrows move 1 px (Shift: 10 px), Tab cycles hex/rgb/hsl, Esc cancels.
- **NIRULOCK 0.22.0:** optional `[pause_music]` (off by default): SID tunes
  from `~/Music/SID` through `sidplayfp` while locked and nothing else plays;
  Esc stops it, and it always stops before suspend.
- **NIRUDICTATE 0.2.1** (extra): registers its shortcuts in the cheat sheet.
- **New dependency `sidplayfp`:** Debian and Void install the distribution
  package. On Arch it is AUR only: NIRUX uses paru or yay when installed, or
  builds it with `makepkg` (perl and the autotools included). A failed build
  only warns and is not retried by every update.
- `config.example.toml` lists the new keys and the moved screen keys.
