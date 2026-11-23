# Bookworm ships libcups2/libgtk-3-0/libasound2; trixie renamed them to *t64.
# Pick whichever name this apt knows about so one source supports both.
# Every package the runtime needs on this distribution, one per line.
required_packages() {
  # shellcheck disable=SC2046 # the list is fixed and space separated
  printf '%s\n' $(packages_for "$OS")
}
# A Debian library renamed with the 64-bit time_t transition. Prints the name
# this repository knows, or nothing when it uses the plain one.
_debian_t64_name() {
  if command -v apt-cache >/dev/null 2>&1 && apt-cache show "${1}t64" >/dev/null 2>&1; then
    say "${1}t64"
  fi
}
# `name<TAB>installed-name` for every renamed package this system has. A name
# the database does not know is left out, so the original name is tried.
required_package_map() {
  [ "$OS" = debian ] || return 0
  command -v apt-cache >/dev/null 2>&1 || return 0
  required_packages | while IFS= read -r base; do
    corrected=$(_debian_t64_name "$base")
    [ -z "$corrected" ] || printf '%s\t%s\n' "$base" "$corrected"
  done
}
_debian_t64() {
  if command -v apt-cache >/dev/null 2>&1 && apt-cache show "$1" >/dev/null 2>&1; then say "$1"
  else say "$2"
  fi
}
# TLP and power-profiles-daemon both manage CPU and platform power profiles
# and fight each other; Arch and Debian also refuse to install both. A machine
# that uses TLP keeps it, and NIRUX neither installs nor starts the daemon.
tlp_in_use() {
  [ -x "$ROOT/usr/bin/tlp" ] || [ -x "$ROOT/usr/sbin/tlp" ]
}
packages_for() {
  if tlp_in_use; then
    distribution_packages_for "$1" | awk '{ out = ""; for (i = 1; i <= NF; i++) if ($i != "power-profiles-daemon") out = out (out == "" ? "" : " ") $i; print out }'
  else
    distribution_packages_for "$1"
  fi
}
distribution_packages_for() {
  # The root-owned, restricted standalone Wi-Fi helper uses the system Python.
  case "$1" in arch) say python ;; debian|void) say python3 ;; esac
  case "$1" in
    arch) say "xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xprop xorg-xdpyinfo xorg-xwininfo xorg-xrdb xorg-xsetroot xorg-setxkbmap xorg-xinput xf86-input-libinput libinput-tools xkeyboard-config noto-fonts-emoji ttf-liberation noto-fonts udisks2 gvfs gvfs-mtp gvfs-smb gvfs-afc gvfs-nfs gvfs-dnssd glib2 xarchiver 7zip unzip zip unrar-free exfatprogs dbus pam pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber alsa-utils alsa-ucm-conf rtkit fontconfig libglvnd ttf-dejavu ttf-jetbrains-mono-nerd kitty fish polkit-gnome libayatana-appindicator libayatana-indicator ayatana-ido bluez bluez-utils power-profiles-daemon dunst picom feh maim slop xdotool xclip tesseract tesseract-data-swe tesseract-data-eng ffmpeg mpv v4l-utils xorg-xrandr xorg-xprop poppler ffmpegthumbnailer gdk-pixbuf2 playerctl libnotify brightnessctl gammastep iproute2 iw xdg-utils xdg-user-dirs unzip procps-ng util-linux smartmontools pacman-contrib gnome-keyring" ;;
    debian) say "xserver-xorg xserver-xorg-input-libinput xinput libinput-tools xinit xauth x11-xserver-utils x11-utils x11-xkb-utils xkb-data fonts-liberation fonts-noto-core udisks2 gvfs gvfs-backends gvfs-fuse libglib2.0-bin xarchiver 7zip unzip zip unrar-free exfatprogs dbus-x11 dbus-user-session libpam0g pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils alsa-ucm-conf rtkit fontconfig libgles2 fonts-dejavu-core fonts-font-awesome fonts-jetbrains-mono fonts-noto-color-emoji kitty fish lxpolkit libayatana-appindicator3-1 libayatana-indicator3-7 libayatana-ido3-0.4-0 bluez libspa-0.2-bluetooth power-profiles-daemon dunst picom feh maim slop xdotool xclip tesseract-ocr tesseract-ocr-swe tesseract-ocr-eng ffmpeg mpv sidplayfp v4l-utils x11-utils poppler-utils ffmpegthumbnailer libgdk-pixbuf2.0-bin playerctl libnotify-bin brightnessctl gammastep iproute2 iw rfkill xdg-utils xdg-user-dirs unzip procps util-linux smartmontools gnome-keyring libpam-gnome-keyring" ;;
    void) say "xorg-minimal xinit xauth xrandr xset xprop xdpyinfo xwininfo xrdb xsetroot setxkbmap xinput libinput xkeyboard-config liberation-fonts-ttf noto-fonts-ttf udisks2 gvfs gvfs-mtp gvfs-smb gvfs-afc glib xarchiver 7zip unzip zip exfatprogs dbus elogind pam pam-base pipewire wireplumber alsa-utils alsa-ucm-conf rtkit fontconfig libglvnd dejavu-fonts-ttf nerd-fonts-symbols-ttf noto-fonts-emoji kitty fish-shell polkit-gnome libayatana-appindicator libayatana-indicator ayatana-ido bluez libspa-bluetooth power-profiles-daemon dunst picom feh maim slop xdotool xclip tesseract-ocr tesseract-ocr-swe tesseract-ocr-eng ffmpeg mpv sidplayfp v4l-utils xrandr xprop poppler-utils ffmpegthumbnailer gdk-pixbuf playerctl libnotify brightnessctl gammastep iproute2 iw xdg-utils xdg-user-dirs unzip procps-ng util-linux smartmontools gnome-keyring" ;;
  esac
}
# Runtime libraries and extraction tools for the pinned Helium archive. These
# are only provisioned when the persistent browser policy is `helium`.
browser_packages_for() {
  case "$1" in
    arch) say "nss nspr cups gtk3 libxcomposite libxdamage libxfixes libxrandr libxkbcommon mesa alsa-lib xz" ;;
    debian) say "libnss3 libnspr4 $(_debian_t64 libcups2 libcups2t64) $(_debian_t64 libgtk-3-0 libgtk-3-0t64) libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libxkbcommon0 libgbm1 $(_debian_t64 libasound2 libasound2t64) xz-utils" ;;
    void) say "nss nspr cups gtk+3 libXcomposite libXdamage libXfixes libXrandr libxkbcommon mesa alsa-lib xz" ;;
  esac
}
browser_packages() {
  case "${BROWSER_EFFECTIVE:-${NIRUX_PROVISION_BROWSER:-keep}}" in
    helium) browser_packages_for "$1" ;;
  esac
}
# Debian package post-install scripts start display managers immediately. NIRUX
# has not installed the session yet at that point, so a newly started LightDM
# or SDDM can take over the console before NIRUWM exists. Defer only display
# managers: blocking D-Bus reloads leaves new polkitd identities unknown to the
# running bus. All other services retain the administrator's previous policy.
restore_policy() {
  [ -n "$POLICY_TARGET" ] || return 0
  if [ "$POLICY_HAD" = 1 ] && [ -f "$POLICY_BACKUP" ]; then
    as_root cp -p "$POLICY_BACKUP" "$POLICY_TARGET" || :
  else
    as_root rm -f "$POLICY_TARGET" || :
  fi
  POLICY_TARGET=
  POLICY_BACKUP=
  POLICY_HAD=0
  [ -z "$POLICY_TMP" ] || rm -rf "$POLICY_TMP"
  POLICY_TMP=
}

disable_service_starts() {
  [ "$OS" = debian ] || return 0
  POLICY_TARGET=$ROOT/usr/sbin/policy-rc.d
  POLICY_TMP=$(mktemp -d "${TMPDIR:-/tmp}/nirux-policy.XXXXXX") || die 'could not create policy temp directory'
  POLICY_BACKUP=$POLICY_TMP/policy-rc.d.saved
  POLICY_HAD=0
  if [ -e "$POLICY_TARGET" ]; then
    as_root cp -p "$POLICY_TARGET" "$POLICY_BACKUP" || die 'could not preserve policy-rc.d'
    POLICY_HAD=1
  fi
  cat > "$POLICY_TMP/policy-rc.d" <<'EOF'
#!/bin/sh
case "${1:-}" in --quiet) service=${2:-} ;; *) service=${1:-} ;; esac
service=${service##*/}
case "$service" in
  lightdm|lightdm.service|sddm|sddm.service|display-manager|display-manager.service) exit 101 ;;
esac
EOF
  if [ "$POLICY_HAD" = 1 ]; then
    # Quote the generated pathname even when TMPDIR contains shell characters.
    policy_quoted=$(printf '%s' "$POLICY_BACKUP" | sed "s/'/'\\\\''/g")
    printf "exec '%s' \"\$@\"\n" "$policy_quoted" >> "$POLICY_TMP/policy-rc.d"
  else
    printf 'exit 0\n' >> "$POLICY_TMP/policy-rc.d"
  fi
  as_root install -d -m 755 "$ROOT/usr/sbin"
  as_root install -m 755 "$POLICY_TMP/policy-rc.d" "$POLICY_TARGET" || die 'could not disable package service starts'
}

# Packages add D-Bus policies/users and X11 input rules after the machine has
# already booted. Refresh live state before a first greeter/session starts.
# Never restart the system bus, change the configured layout, or touch a test
# system root. Void may not have started D-Bus yet; its first start is fresh.
refresh_runtime_state() {
  [ -z "$ROOT" ] || return 0
  if command -v dbus-send >/dev/null 2>&1 && as_root test -S /run/dbus/system_bus_socket; then
    as_root dbus-send --system --type=method_call --print-reply --reply-timeout=5000 \
      --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig >/dev/null ||
      die 'could not reload system D-Bus configuration; reboot before starting the desktop'
  fi
  if command -v udevadm >/dev/null 2>&1 && as_root test -S /run/udev/control; then
    as_root udevadm control --reload-rules || die 'could not reload input device rules'
    as_root udevadm trigger --action=change --subsystem-match=input || die 'could not refresh input device properties'
    # A slow device elsewhere (a disk, a dock) can keep the queue busy past the
    # timeout. The input rules are already reloaded and triggered, so a late
    # queue is no reason to stop the update half way.
    as_root udevadm settle --timeout=30 ||
      say 'nirux: input devices are still being refreshed; continuing (a new keyboard or touchpad setting may need a replug or the next login)'
  fi
}

# Leave out what is already installed: pacman --needed and xbps-install print a
# warning or an "ERROR: ... already installed" line for each of them, which
# buried the real messages of a fresh install under ~40 alarming lines.
not_installed() {
  for package in "$@"; do
    case "$OS" in
      arch) command pacman -Qq "$package" >/dev/null 2>&1 || printf '%s ' "$package" ;;
      void) command xbps-query "$package" >/dev/null 2>&1 || printf '%s ' "$package" ;;
      *) printf '%s ' "$package" ;;
    esac
  done
}
install_packages() {
  install_only=0
  if [ "$#" -gt 0 ]; then
    # The caller named exactly what is missing. Do not perform a full system
    # upgrade as a side effect of installing a runtime dependency.
    pkgs=$1
    install_only=1
  else
    pkgs="curl ca-certificates $(packages_for "$OS") $(browser_packages "$OS")"
    case "$OS" in
      arch) pkgs="$pkgs mesa" ;;
      debian) pkgs="$pkgs libgl1-mesa-dri" ;;
      void) pkgs="$pkgs mesa-dri" ;;
    esac
    case "$DM" in
      nirulogin)
        case "$OS" in
          debian) pkgs="$pkgs greetd xserver-xorg-legacy" ;;
          arch|void) pkgs="$pkgs greetd" ;;
          *) die "NIRU Login is unsupported on $OS" ;;
        esac
        ;;
      sddm)
        pkgs="$pkgs sddm"
        # Arch's sddm-greeter links Qt5 but the package only recommends the
        # Qt5 QML runtime. Without it the greeter cannot start.
        [ "$OS" = arch ] && pkgs="$pkgs qt5-declarative"
        ;;
      lightdm) pkgs="$pkgs lightdm lightdm-gtk-greeter" ;;
    esac
  fi
  if [ "$install_only" = 1 ]; then
    say "Installing missing $OS packages: $pkgs"
  else
    say "Installing $OS packages: $pkgs"
  fi
  # Package names are fixed above; splitting this list is intentional.
  # shellcheck disable=SC2086
  case "$OS" in arch|void) pkgs=$(not_installed $pkgs) ;; esac
  # shellcheck disable=SC2086
  case "$OS" in
    arch)
      if [ "$install_only" = 1 ] && [ -z "$pkgs" ]; then
        :
      elif [ "$install_only" = 1 ]; then
        # Never refresh the sync database without upgrading Arch. Use the
        # current database; if its packages expired, pacman fails and the user
        # can explicitly run pacman -Syu before retrying the update.
        as_root pacman -S --needed --noconfirm $pkgs
      else
        as_root pacman -Syu --needed --noconfirm $pkgs
      fi
      ;;
    debian)
      as_root apt-get update
      disable_service_starts
      if as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $pkgs; then
        apt_status=0
      else
        apt_status=$?
        # Debian renamed libraries with the 64-bit time_t transition and some
        # release notes dropped the old name from the package list. When the
        # whole install fails before changing anything, try again with the
        # names this database actually knows.
        # shellcheck disable=SC2086
        retried=
        for name in $pkgs; do
          corrected=$(_debian_t64_name "$name")
          retried="$retried ${corrected:-$name}"
        done
        if [ "$retried" != " $pkgs" ] &&
          as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $retried; then
          apt_status=0
        fi
      fi
      restore_policy
      [ "$apt_status" = 0 ] || return "$apt_status"
      ;;
    void)
      if [ -z "$pkgs" ]; then
        :
      elif [ "$install_only" = 1 ]; then
        as_root xbps-install -Sy $pkgs
      else
        # Install the requested runtime packages without forcing a full kernel
        # and system upgrade as a side effect of a clean desktop install. If
        # the configured mirror is inconsistent, retry from the official one.
        if ! as_root xbps-install -Sy $pkgs; then
          say 'Void mirror failed; retrying with the official repository.'
          as_root xbps-install -Sy --ignore-conf-repos \
            -R https://repo-default.voidlinux.org/current $pkgs
        fi
      fi
      ;;
  esac
  refresh_runtime_state
}

# NIRULOCK's pause music plays SID tunes through sidplayfp. Debian and Void
# package it (see distribution_packages_for); on Arch it is only in the AUR, on
# top of libsidplayfp from extra. Build it with an installed AUR helper, or
# else with makepkg as this user. This is never fatal: without sidplayfp the
# lock simply plays no music. A failed build is remembered so that every later
# update does not rebuild; remove the marker to try again.
SIDPLAYFP_AUR_MARKER=
sidplayfp_aur_marker() { say "${SIDPLAYFP_AUR_MARKER:-$STATE/sidplayfp-aur-failed}"; }
sidplayfp_aur_warn() {
  say "nirux: warning: sidplayfp could not be installed from the AUR ($1); NIRULOCK plays no pause music." >&2
  say "nirux: install the AUR package sidplayfp yourself, then remove $(sidplayfp_aur_marker) so updates try again." >&2
  mkdir -p "$(dirname "$(sidplayfp_aur_marker)")" 2>/dev/null && : > "$(sidplayfp_aur_marker)" 2>/dev/null || :
}
# An AUR helper asks sudo itself. A supplied password goes to it through
# askpass, as as_root does, never in its arguments.
sidplayfp_aur_helper() {
  aur_tool=$1
  if [ -n "${SUDO_SECRET_FILE:-}" ] && [ -f "$SUDO_SECRET_FILE" ]; then
    aur_askpass=$(mktemp "${TMPDIR:-/tmp}/.nirux-askpass.XXXXXX") || return 1
    chmod 700 "$aur_askpass" 2>/dev/null || :
    printf '#!/bin/sh\ncat %s\n' "$SUDO_SECRET_FILE" > "$aur_askpass" || { rm -f "$aur_askpass"; return 1; }
    SUDO_ASKPASS=$aur_askpass "$aur_tool" -S --needed --noconfirm --sudoflags -A sidplayfp < /dev/null
    aur_status=$?
    rm -f "$aur_askpass"
    return "$aur_status"
  fi
  "$aur_tool" -S --needed --noconfirm sidplayfp
}
sidplayfp_aur_makepkg() {
  # The PKGBUILD lists neither perl (pod2man) nor the autotools it runs.
  as_root pacman -S --needed --noconfirm base-devel git libsidplayfp alsa-lib mpg123 libpulse autoconf automake gettext pkgconf perl || return 1
  aur_build=$(mktemp -d "${TMPDIR:-/tmp}/nirux-sidplayfp.XXXXXX") || return 1
  # A login shell puts /usr/bin/core_perl (pod2man) on PATH.
  if git clone --quiet --depth 1 https://aur.archlinux.org/sidplayfp.git "$aur_build/sidplayfp" &&
    bash -lc 'cd "$1" && makepkg --noconfirm' sh "$aur_build/sidplayfp"; then
    aur_pkg=
    for aur_file in "$aur_build"/sidplayfp/sidplayfp-[0-9]*.pkg.tar.*; do
      [ -f "$aur_file" ] && aur_pkg=$aur_file
    done
    if [ -n "$aur_pkg" ]; then
      as_root pacman -U --needed --noconfirm "$aur_pkg"
      aur_status=$?
    else
      aur_status=1
    fi
  else
    aur_status=1
  fi
  rm -rf "$aur_build"
  return "$aur_status"
}
provision_sidplayfp_aur() {
  [ "$OS" = arch ] || return 0
  # An AUR build needs sudo for pacman -U; the nightly update leaves it.
  [ "$NIRUX_AUTO" = 0 ] || return 0
  if distribution_package_present sidplayfp || command -v sidplayfp >/dev/null 2>&1; then return 0; fi
  if [ -f "$(sidplayfp_aur_marker)" ]; then
    say "sidplayfp is not installed (an earlier AUR build failed); NIRULOCK plays no pause music."
    return 0
  fi
  if [ "${NIRUX_PACKAGES_DRY_RUN:-0}" = 1 ]; then say 'would build sidplayfp from the AUR'; return 0; fi
  if [ "$(id -u)" = 0 ]; then sidplayfp_aur_warn 'makepkg does not run as root'; return 0; fi
  say 'Installing sidplayfp from the AUR (NIRULOCK pause music).'
  for aur_tool in paru yay; do
    command -v "$aur_tool" >/dev/null 2>&1 || continue
    if sidplayfp_aur_helper "$aur_tool"; then return 0; fi
    say "$aur_tool could not install sidplayfp; building it with makepkg."
    break
  done
  if sidplayfp_aur_makepkg; then return 0; fi
  sidplayfp_aur_warn 'the build failed'
  return 0
}

# The package query itself, overridable by the test suite: a plain shell
# function cannot be redefined and used by code loaded from another file.
NIRUX_PACKAGE_QUERY=
internal_package_query() {
  NIRUX_PACKAGE_QUERY=$1
  export NIRUX_PACKAGE_QUERY
}
# Is this distribution package installed? Queries are deliberately local: an
# update must not install a package the repository only mentions.
distribution_package_present() {
  if [ -n "$NIRUX_PACKAGE_QUERY" ]; then "$NIRUX_PACKAGE_QUERY" "$@"; return; fi
  case "$OS" in
    arch) pacman -Q "$1" >/dev/null 2>&1 ;;
    debian) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed' ;;
    void) xbps-query "$1" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

# Print the runtime packages this release needs but the machine lacks.
#
# The list comes from the script doing the update, so an older installed NIRUX
# can provision a dependency introduced by the release it is installing.
required_missing_packages() {
  # The distribution's own list, in the order packages_for gives it. A caller
  # may replace that list in tests, and the staged target has its own copy.
  for required_pkg in $(packages_for "$OS"); do
    distribution_package_present "$required_pkg" || say "$required_pkg"
  done
  return 0
}

# The same list with the names this machine's package database uses. The
# running installer resolves the renames (Debian trixie's *t64 libraries) and
# passes them to the staged target, so an update never asks apt to install a
# name the release has replaced.
resolved_missing_packages() {
  for pkg_name in $(required_missing_packages); do
    # A command substitution runs in a subshell, where a function defined by a
    # caller is not visible. A rename is therefore asked of the package
    # database through NIRUX_T64_NAME (the test suite supplies its own), and
    # only a true rename changes the name: the plain one missing, the
    # suffixed one present.
    renamed=
    if [ "$OS" = debian ] && ! distribution_package_present "$pkg_name"; then
      renamed=$("${NIRUX_T64_NAME:-_debian_t64_name}" "$pkg_name")
    fi
    if [ -n "$renamed" ]; then say "$renamed"; else say "$pkg_name"; fi
  done
  return 0
}

# Install or check this release's runtime dependencies. Called from the newly
# downloaded script after verification, so updates use the new package list
# instead of the old installed one.
# Packages an earlier release installed and this one replaced: pcmanfm by
# NIRUFM (0.12.317). A `nirux update` in a terminal removes them once; the
# nightly update only notes it, as it never removes software.
retired_packages() { say pcmanfm; }
retire_packages() {
  rp_list=
  for rp in $(retired_packages); do
    case "$OS" in
      arch) if pacman -Q "$rp" >/dev/null 2>&1; then rp_list="$rp_list $rp"; fi ;;
      debian) if dpkg-query -W -f='${Status}' "$rp" 2>/dev/null | grep -q 'install ok installed'; then rp_list="$rp_list $rp"; fi ;;
      void) if xbps-query "$rp" >/dev/null 2>&1; then rp_list="$rp_list $rp"; fi ;;
    esac
  done
  [ -n "$rp_list" ] || return 0
  if [ "$NIRUX_AUTO" = 1 ]; then
    auto_pending "remove replaced packages:$rp_list"
    return 0
  fi
  if [ "${NIRUX_PACKAGES_DRY_RUN:-0}" = 1 ]; then say "would remove replaced packages:$rp_list"; return 0; fi
  say "Removing packages NIRUX no longer uses:$rp_list"
  # shellcheck disable=SC2086 # fixed package names, one per word
  case "$OS" in
    arch) as_root pacman -R --noconfirm $rp_list || say 'could not remove them; they are harmless and can stay' ;;
    debian) as_root env DEBIAN_FRONTEND=noninteractive apt-get remove -y $rp_list || say 'could not remove them; they are harmless and can stay' ;;
    void) as_root xbps-remove -y $rp_list || say 'could not remove them; they are harmless and can stay' ;;
  esac
}
provision_packages() {
  mode=${1:-missing}
  OS=${NIRUX_PROVISION_OS:-$(distro)}
  platform
  DM=${NIRUX_PROVISION_DM:-keep}
  BROWSER_EFFECTIVE=${NIRUX_PROVISION_BROWSER:-keep}
  case "$mode" in
    full)
      if [ "${NIRUX_PACKAGES_DRY_RUN:-0}" = 1 ]; then say "would install: $(packages_for "$OS")"; provision_sidplayfp_aur; return; fi
      install_packages || return $?
      provision_sidplayfp_aur
      ;;
    missing)
      retire_packages
      # Renames (Debian trixie's *t64 libraries) come from this machine's own
      # package database. An explicit value from the caller is kept.
      if [ -z "${NIRUX_PACKAGE_MAP:-}" ]; then
        NIRUX_PACKAGE_MAP=$(required_package_map)
      fi
      missing=$(resolved_missing_packages)
      if [ -z "$missing" ]; then say 'OS runtime packages are present'; provision_sidplayfp_aur; return; fi
      if [ "${NIRUX_PACKAGES_DRY_RUN:-0}" = 1 ]; then say "would install missing: $missing"; provision_sidplayfp_aur; return; fi
      # The nightly update has no sudo: the root helper installs these from
      # the distribution's repositories and runs the update once more.
      if [ "$NIRUX_AUTO" = 1 ]; then
        # shellcheck disable=SC2086 # fixed package names, one per word
        auto_want_packages $missing
        return 0
      fi
      # One argument on purpose: install_packages splits this fixed package
      # list, exactly as it does for the full list.
      # shellcheck disable=SC2086
      install_packages "$missing" || return $?
      provision_sidplayfp_aur
      ;;
    *) die "unknown provisioning mode: $mode" ;;
  esac
}
