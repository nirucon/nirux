#!/bin/sh
# NIRUX: install a complete X11 desktop, or maintain an existing installation.
set -eu

VERSION=0.12.341
PREFIX=${NIRUX_PREFIX:-$HOME/.local}
BIN=$PREFIX/bin
STATE=$PREFIX/share/nirux
CONFDIR=${XDG_CONFIG_HOME:-$HOME/.config}/niruwm
NIRUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/nirux
SOUNDS_STATE=$STATE/sounds
SOUNDS_CONFIG=$NIRUX_CONFIG/sounds.toml
ROOT=${NIRUX_SYSTEM_ROOT:-}
PROGRAMS="niruwm niructl niruidle nirubar niruscreensaver nirulock nirulauncher nirunotify nirushot niruclip nirufetch niruwebapp niruwallpaper nirudisplay niruthemeselector niruwm-session niruclipboard nirugestured nirulogin nirushare niruio nirusplash nirusleep nirudemo nirufm niruterm niruprompt nirux"
WORK=
POLICY_TARGET=
POLICY_BACKUP=
POLICY_TMP=
POLICY_HAD=0
LOCKED=0
CONFIG_TMP=
CONFIG_CANDIDATE=
APPLY_PROTOCOL=0
APPLY_OK=0
# The sudo password never lives in the environment: a program NIRUX starts can
# read its own environment, and a build or a plugin listing processes would
# then see it. It is kept in a private file that only a subshell handed the
# location can read, which is the case that matters: parts of an install run in
# a subshell, and a shell variable would be lost there.
SUDO_SECRET=
sudo_secret_file() {
  [ -n "${SUDO_SECRET_FILE:-}" ] && [ -f "$SUDO_SECRET_FILE" ] || return 1
  sudo_secret_read=$(cat "$SUDO_SECRET_FILE" 2>/dev/null) || return 1
  [ -n "$sudo_secret_read" ] || return 1
  SUDO_SECRET=$sudo_secret_read
  unset sudo_secret_read
}
# Store the password NIRUX is allowed to reuse, then forget the original.
sudo_secret_keep() {
  secret_value=$1
  [ -n "$secret_value" ] || return 1
  if [ -z "${SUDO_SECRET_FILE:-}" ] || [ ! -f "$SUDO_SECRET_FILE" ]; then
    SUDO_SECRET_FILE=$(mktemp "${TMPDIR:-/tmp}/.nirux-secret.XXXXXX") || return 1
    chmod 600 "$SUDO_SECRET_FILE" 2>/dev/null || :
  fi
  ( umask 077; printf '%s\n' "$secret_value" > "$SUDO_SECRET_FILE" ) || return 1
  export SUDO_SECRET_FILE
  SUDO_SECRET=$secret_value
  unset secret_value
}
# Remove the file on every normal and failing exit path.
sudo_secret_forget() {
  if [ "${SUDO_SECRET_BORROWED:-0}" != 1 ] && [ -n "${SUDO_SECRET_FILE:-}" ]; then
    rm -f "$SUDO_SECRET_FILE"
  fi
  SUDO_SECRET_FILE=
  SUDO_SECRET=
}
SUDO_ASK_LATER=0
TRAPS_ARMED=0
# Pinned upstream releases: the minimum NIRUX installs. `nirux update` follows
# each app's newest stable upstream release when it publishes a checksum
# (NIRUX_APPS=pinned or --apps pinned keeps the pins). Every archive is
# verified before extraction, and the extracted program is still checked for
# shared libraries and its reported version before the stable link is
# switched. OpenCode 2 comes from opencode.ai (the GitHub anomalyco/opencode
# releases are OpenCode 1); its binary is identical to the npm package
# @opencode/cli-linux-x64, whose sha512 integrity anchors the pin.
HELIUM_VERSION=0.21.2.1
HELIUM_SHA256=e55c253e082f78fb5ae094ca465a59e06882fd7c87ebf383165beb3560e0b519
LOCALSEND_VERSION=1.18.2
LOCALSEND_SHA256=287690a9a8eb6da9c83cc97b3e3030ac67daf32a7331fcf307d0939300658d16
OPENCODE_VERSION=2.2.7
OPENCODE_SHA256=89a6cee227b54bc011179c528a5e63176032462b1a5e21723b616801cddc2ca7
BROWSER_CHOICE=
WALLPAPER_CHOICE=
BROWSER_EFFECTIVE=keep
BROWSER_EXPLICIT=0
ICONS_CHOICE=
ICONS_EFFECTIVE=none
ICONS_EXPLICIT=0
LOCALSEND_CHOICE=
LOCALSEND_EFFECTIVE=yes
LOCALSEND_EXPLICIT=0
OPENCODE_CHOICE=
OPENCODE_EFFECTIVE=yes
OPENCODE_EXPLICIT=0
TAILSCALE_CHOICE=
TAILSCALE_EFFECTIVE=keep
TAILSCALE_EXPLICIT=0
BROWSER_ADDON_CHOICE=
BROWSER_ADDON_EFFECTIVE=keep
BROWSER_ADDON_EXPLICIT=0
EXTRAS_SELECTED=$STATE/extras-selected
# nirux update --auto (the nightly update) sets this; see auto_root.
NIRUX_AUTO=${NIRUX_AUTO:-0}
PENDING_SYSTEM=$STATE/pending-system
WANTED_PACKAGES=$STATE/wanted-packages
SYSTEM_SUMS=$STATE/system-sums

say() { printf '%s\n' "$*"; }
die() { say "nirux: $*" >&2; sudo_secret_forget; exit 1; }
usage() {
  say "NIRUX $VERSION"
  say "Usage: nirux install [--minimal|--no-packages] [--display-manager auto|startx|nirulogin|sddm|lightdm]"
  say "                    [--browser helium|none|keep] [--wallpapers all|default]"
  say "                    [--localsend yes|no] [--opencode yes|no] [--tailscale yes|no] [--icons none|papirus]"
  say "                    [--webapps none|all|SET,...] [--nextcloud ADDRESS]"
  say "       nirux update [--no-packages] [--release VERSION] [--browser helium|none|keep] [--browser-addon bonjourr|none|keep]"
  say "                    [--wallpapers all|default] [--localsend yes|no] [--opencode yes|no] [--icons keep|none|papirus]"
  say "                    [--apps latest|pinned] [--auto] [--webapps SET,...] [--nextcloud ADDRESS]"
  say "       nirux login-wallpaper [list|set FILE|reset|sync]"
  say "       nirux wallpapers [status|download [themes|signature|extras|all|theme NAME]|style art|signature|toggle|remove]"
  say "       nirux layout list|save NAME|apply NAME|rotate OUTPUT normal|left|right|inverted|auto"
  say "       nirux reset-config"
  say "       nirux repair-session | repair-wallpaper"
  say "       nirux remove helium|localsend|opencode"
  say "       nirux browser-addon bonjourr|none|status"
  say "       nirux browser-m365 on|off|status"
  say "       nirux extras [list|status|select NAME|unselect NAME|install [NAME...]|uninstall NAME... [--purge]|update]"
  say "       nirux sounds [status|list|on|off|toggle|test|app ...] (see docs/SOUNDS.md)"
  say "       nirux fleet [status [--json]|update HOST...|--all|--behind|setup [HOST...]|set KEY VALUE [HOST...]|pending [apply|clear]|top]"
  say "       nirux sync status [HOST...] | push HOST...|--all [ITEM...] | pull HOST [ITEM...] | items"
  say "       nirux snapshot [--note TEXT] | snapshot list | restore [ID|latest] [--dry-run]"
  say "       nirux backup [status|setup|now|list [HOST]|restore [HOST|FILE] [--to DIR]|off]"
  say "       nirux migrate from HOST [--dry-run|--yes]"
  say "       nirux manual [TOPIC] | manual --list | manual --path"
  say "       nirux checkup [--dry-run] | last | status | enable | disable | discord set|test"
  say "       nirux autoupdate [status|last|enable|disable|run-now]"
  say "       nirux whats-new [--notify] | resume-check [--notify] | clean [--yes] [--dry-run]"
  say "       nirux meet-check [--notify] | stale [--json] | stale restart"
  say "       nirux boot [status|on|off|apply|doctor]"
  say "       nirux hibernate [status|on|off|apply|delay MINUTES|doctor]"
  say "       nirux webapps [list [SET...]|add SET|KEY... [--url URL] [--dry-run]|check]"
  say "       nirux demo [N|KEY|list|songs]"
  say "       nirux update-shutdown [--yes] [--dry-run] [--no-power]"
  say "       nirux update-reboot [--yes] [--dry-run] [--no-power]"
  say "       nirux rollback | gc [--keep N] [--dry-run] | status | doctor [--fix [--yes]] | uninstall [--purge] | --version | --help"
  say "Default: keep an existing display manager; a fresh install uses NIRU Login, with startx/SDDM/LightDM available."
  say "Browser: a fresh install offers Helium (default Helium) and remembers the choice."
  say "         --browser none is a persistent opt-out; --browser keep preserves the current policy."
  say "         --localsend/--opencode choose optional apps; without a flag an install prompts and an update preserves the current choice."
  say "Tailscale: a fresh install offers it (default yes), starts it and shows the link that adds the computer; --tailscale no skips it."
  say "Web apps: a fresh install offers NIRUWEBAPP sets (work, ai, google, proton, media, other; default ai media) and a Nextcloud address."
  say "Papirus: --icons papirus installs Papirus-Dark with grey folders per user (~112-190 MB); none opts out."
  say "--minimal/--no-packages: binaries and integration only; required OS packages must already exist."
  say "Updates check and install missing runtime packages from the downloaded release unless --no-packages is given."
  say "Every update first saves a snapshot of your configuration (nirux snapshot list; nirux restore)."
  say "Apps (Helium, LocalSend, OpenCode) follow their newest verified upstream release; --apps pinned keeps the NIRUX pins."
  say "--auto: the nightly update (nirux autoupdate): no questions, no sudo; root steps wait for the next nirux update."
}
cleanup() {
  if [ -n "${SUDO_KEEPALIVE_PID:-}" ]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || :
    SUDO_KEEPALIVE_PID=
  fi
  restore_policy
  # The password file never outlives the command, whether it succeeded or not.
  sudo_secret_forget
  [ -z "$CONFIG_TMP" ] || rm -f "$CONFIG_TMP"
  [ -z "$CONFIG_CANDIDATE" ] || rm -f "$CONFIG_CANDIDATE"
  [ -z "$WORK" ] || rm -rf "$WORK"
  [ "$LOCKED" = 0 ] || rmdir "$STATE/.lock" 2>/dev/null || :
}
lock() {
  mkdir -p "$STATE"
  mkdir "$STATE/.lock" 2>/dev/null || die "another operation is running ($STATE/.lock)"
  LOCKED=1
  WORK=$(mktemp -d "$STATE/.work.XXXXXX")
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  TRAPS_ARMED=1
}
distro() {
  if [ -r /etc/os-release ]; then
    os_id=$(. /etc/os-release; printf '%s' "${ID:-}")
    case "$os_id" in void|arch|debian) say "$os_id"; return ;; esac
  fi
  if [ -f /etc/void-release ] || command -v xbps-install >/dev/null 2>&1; then say void
  elif [ -f /etc/arch-release ]; then say arch
  elif [ -f /etc/debian_version ]; then say debian
  else die "supported distributions: Void, Arch and Debian"
  fi
}
platform() {
  [ "$(uname -m)" = x86_64 ] || die "release binaries currently support x86_64 only"
  getconf GNU_LIBC_VERSION >/dev/null 2>&1 || die "release binaries require glibc; Void musl is not supported yet"
}
# True when version $1 is at least $2 (dotted numbers, e.g. 0.23.0).
version_at_least() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    n = split(a, x, "."); m = split(b, y, ".")
    for (i = 1; i <= (n > m ? n : m); i++) {
      if ((x[i] + 0) > (y[i] + 0)) exit 0
      if ((x[i] + 0) < (y[i] + 0)) exit 1
    }
    exit 0
  }'
}
# The first NIRUWM that restarts in place (`niructl restart-wm`).
RESTART_WM_SINCE=0.23.0
# Activate a new generation in the running NIRU session. $1 starts the message.
#
# NIRUWM 0.23.0 and later restart in place: the window manager, its bars and
# every session helper whose program changed are replaced, and every window
# stays where it was. A locked screen stays locked; the restart then waits for
# the unlock. An older running manager cannot: only the bar is replaced, and
# one more login activates the rest (after that, updates apply in place).
# NIRUX_SESSION_RESTART=0 (update-reboot and update-shutdown) skips the
# restart, since the machine powers off next.
apply_to_running_session() {
  ars_lead=$1
  if [ -z "${DISPLAY:-}" ] || [ ! -x "$BIN/niructl" ]; then
    say "$ars_lead Log out/in to activate the updated programs, or run niructl restart-wm in the NIRU session."
    return 0
  fi
  if [ "${NIRUX_SESSION_RESTART:-1}" = 0 ]; then
    say "$ars_lead The running session keeps its programs until the power action."
    return 0
  fi
  if "$BIN/niructl" restart-wm --check --quiet >/dev/null 2>&1; then
    if ars_out=$("$BIN/niructl" restart-wm 2>&1); then
      case "$ars_out" in
        *locked*) say "$ars_lead $ars_out" ;;
        *) say "$ars_lead ${ars_out:-NIRUWM restarted in place.} Open windows are kept; no logout is needed." ;;
      esac
      return 0
    fi
    say "niructl restart-wm failed: $ars_out"
  fi
  if "$BIN/niructl" restart-bar >/dev/null 2>&1; then
    say "$ars_lead Running bar restarted. The running NIRUWM is older than $RESTART_WM_SINCE: log out and back in once to activate the rest; later updates apply without logging out."
  else
    say "$ars_lead Log out/in to activate all updated programs. In a new NIRU session: niructl restart-bar."
  fi
}
# The `nirux status` line for a running window manager that is not the
# installed one: a manager that can restart in place needs no new login.
running_wm_status() {
  rws_version=$("$1" --version 2>/dev/null | awk '{print $NF; exit}') || rws_version=
  if [ -n "$rws_version" ] && version_at_least "$rws_version" "$RESTART_WM_SINCE"; then
    say "running WM: old generation (NIRUWM $rws_version); niructl restart-wm activates the update without logging out"
  else
    say "running WM: old generation${rws_version:+ (NIRUWM $rws_version)}; log out and back in once to activate the update (later updates apply in place)"
  fi
}
component_matches_running() {
  running=$1
  current=$2
  [ -n "$running" ] && [ -n "$current" ] || return 1
  [ "$running" = "$current" ] && return 0
  running_sum=$(sha256sum "$running" 2>/dev/null | cut -d ' ' -f1) || return 1
  current_sum=$(sha256sum "$current" 2>/dev/null | cut -d ' ' -f1) || return 1
  [ -n "$running_sum" ] && [ "$running_sum" = "$current_sum" ]
}
# Refresh sudo's timestamp until cleanup. The loop is a child of this shell and
# is killed by cleanup, so it never outlives the command.
#
# The loop is started only once lock() has armed the cleanup trap. Started any
# earlier, it would outlive the installer, because a shell exits without running
# EXIT traps when no trap is set. It also closes stdin so a credential helper
# waiting there cannot block it.
start_sudo_keepalive() {
  [ -z "${SUDO_KEEPALIVE_PID:-}" ] || return 0
  [ "${TRAPS_ARMED:-0}" = 1 ] || return 0
  (
    while sleep 45; do sudo -n -v >/dev/null 2>&1 || exit 0; done
  ) </dev/null >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
}
# Refresh the sudo timestamp with the password NIRUX holds.
#
# sudo keeps one timestamp per terminal, and when there is no terminal it keys
# the timestamp on how its password came in: a pipe and a file are two
# different keys, so a password piped once does not unlock a later `sudo -n`.
# A deployment script or a CI step has no terminal at all. The password
# therefore always arrives the same way, through a temporary file, so the
# timestamp every later call checks is the one that was just written. With a
# terminal the loop below keeps that timestamp fresh instead.
sudo_refresh() {
  [ -n "${SUDO_SECRET:-}" ] || return 1
  ticket=$(mktemp "${TMPDIR:-/tmp}/.nirux-sudo.XXXXXX") || return 1
  chmod 600 "$ticket" 2>/dev/null || :
  printf '%s\n' "$SUDO_SECRET" > "$ticket"
  sudo -S -p '' -v < "$ticket" >/dev/null 2>&1
  result=$?
  rm -f "$ticket"
  return "$result"
}
sudo_with_secret() {
  [ -n "${SUDO_SECRET_FILE:-}" ] && [ -f "$SUDO_SECRET_FILE" ] || return 1
  helper=$(mktemp "${TMPDIR:-/tmp}/.nirux-askpass.XXXXXX") || return 1
  chmod 700 "$helper" 2>/dev/null || :
  printf '#!/bin/sh\ncat %s\n' "$SUDO_SECRET_FILE" > "$helper" || {
    rm -f "$helper"
    return 1
  }
  SUDO_ASKPASS=$helper sudo -A -p '' "$@"
  status=$?
  rm -f "$helper"
  return "$status"
}
as_root() {
  # Integration tests exercise the target-apply subprocess against a temporary
  # system root. Production never sets this variable.
  if [ "${NIRUX_TEST_AS_ROOT:-0}" = 1 ]; then
    "$@" || return $?
    [ "$1" != install ] || system_sum_note "$@"
    return 0
  fi
  # The nightly update never asks for a password: what needs root is checked
  # as this user and, when it would change something, left for later.
  if [ "$NIRUX_AUTO" = 1 ]; then auto_root "$@"; return; fi
  if [ "$(id -u)" = 0 ]; then
    "$@" || return $?
    [ "$1" != install ] || system_sum_note "$@"
    return 0
  fi
  command -v sudo >/dev/null 2>&1 || die "install sudo and grant this user access, then retry"
  # A supplied password is replayed through askpass for every command. Relying
  # on a sudo timestamp created from a piped password is not portable: sudo can
  # key that timestamp to the terminal and then reject a later `sudo -n`.
  if [ -n "${SUDO_SECRET:-}" ]; then
    sudo_with_secret "$@"
    return $?
  fi
  if ! sudo -n id -u >/dev/null 2>&1; then
    # A supplied password (a deployment script or a host that keeps sudo set
    # for this program) is tried first. This used to be asked of sudo before
    # piping, because sudo then read the already-entered line as the password.
    if [ -n "${NIRUX_SUDO_PASSWORD:-}" ]; then
      sudo_secret_keep "$NIRUX_SUDO_PASSWORD"
      unset NIRUX_SUDO_PASSWORD
    fi
    [ -n "$SUDO_SECRET" ] || sudo_secret_file || :
    if [ -n "$SUDO_SECRET" ] && sudo_refresh; then
      # A deployment script has no terminal: sudo will not keep a timestamp
      # for it, so later calls pass the password again. The keepalive keeps
      # the timestamp fresh where sudo does use one.
      SUDO_ASK_LATER=1
      # A long download or package install can outlive sudo's timestamp.
      start_sudo_keepalive
    elif [ -t 0 ]; then
      NIRUX_SUDO_PASSWORD=
      sudo -v || return $?
    else
      printf 'Password for sudo: ' >&2
      IFS= read -r password || die "sudo needs a password (use a terminal or pipe one line on stdin)"
      if printf '%s\n' "$password" | sudo -S -p "" -v; then
        # The staged target installer is a separate process with its own sudo
        # context, so hand the password to that one child only.
        sudo_secret_keep "$password"
        unset password
      else
        result=$?
        unset password
        return "$result"
      fi
    fi
  fi
  # `-S` reads a password only when sudo asks for one; a cached timestamp
  # means it never reads, so the line stays in the pipe unread. `-p ''`
  # keeps the prompt out of the log.
  if [ "${SUDO_ASK_LATER:-0}" = 1 ] && [ -n "${SUDO_SECRET:-}" ]; then
    sudo_refresh
  fi
  sudo -n "$@" || return $?
  [ "$1" != install ] || system_sum_note "$@"
}
