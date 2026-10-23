#!/bin/sh
set -eu
SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
export NIRUX_PREFIX=$T/prefix
export NIRUX_SYSTEM_ROOT=$T/root
export NIRUX_LIBRARY=1
export NIRUX_TEST_AS_ROOT=1
mkdir -p "$HOME" "$T/prefix/bin" "$T/root/var/lib/sddm"
printf '#!/bin/sh\nexec nirupi-session\n' > "$HOME/.xinitrc"
printf '[Last]\nSession=/usr/share/xsessions/nirupi-dwm.desktop\n' > "$T/root/var/lib/sddm/state.conf"
# shellcheck source=/dev/null
. "$SOURCE/nirux"
WORK=$(mktemp -d)
setup_startx
repair_legacy_sddm_session
grep -q 'niruwm-session' "$HOME/.xinitrc" || { echo 'legacy xinitrc was not repaired' >&2; exit 1; }
[ -f "$HOME/.xinitrc.nirux-backup" ] || { echo 'xinitrc backup missing' >&2; exit 1; }
grep -q 'Session=/usr/share/xsessions/niruwm.desktop' "$T/root/var/lib/sddm/state.conf" || { echo 'SDDM session was not repaired' >&2; exit 1; }
[ -f "$T/root/var/lib/sddm/state.conf.nirux-backup" ] || { echo 'SDDM backup missing' >&2; exit 1; }
echo 'PASS: legacy xinitrc and SDDM session repair'
