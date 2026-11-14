#!/bin/sh
# NIRUX 0.12.276: gnome-keyring is a runtime package on every distribution,
# and NIRU Login's PAM file unlocks the login keyring. Arch's and Void's greetd
# file gets two marked lines once; Debian's own lines are left alone; removing
# NIRU Login takes back exactly what NIRUX added.
# Offline: nothing outside a temporary system root is touched.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1 NIRUX_TEST_AS_ROOT=1
mkdir -p "$HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
WORK=$TEST/work
mkdir -p "$WORK" "$ROOT/etc/pam.d"
PAM=$ROOT/etc/pam.d/greetd

# 1. The package lists.
for os in arch debian void; do
  distribution_packages_for "$os" | tr ' ' '\n' | grep -qx gnome-keyring || fail "$os: gnome-keyring missing"
done
distribution_packages_for debian | tr ' ' '\n' | grep -qx libpam-gnome-keyring || fail 'debian: libpam-gnome-keyring missing'
echo 'OK   gnome-keyring is a runtime package on Arch, Debian and Void'

# 2. Arch's greetd file: the lines are added once and removed exactly.
cat > "$PAM" <<'EOF'
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
account    include      system-local-login
session    include      system-local-login
EOF
cp "$PAM" "$TEST/arch.orig"
ensure_greetd_keyring_pam >/dev/null
grep -qx -- '-auth       optional    pam_gnome_keyring.so' "$PAM" || fail 'auth line missing'
grep -qx -- '-session    optional    pam_gnome_keyring.so auto_start' "$PAM" || fail 'session line missing'
# The auth line comes after every auth rule of the distribution.
last_auth=$(grep -n '^auth' "$PAM" | tail -1 | cut -d: -f1)
ours=$(grep -n -- '^-auth.*pam_gnome_keyring' "$PAM" | cut -d: -f1)
[ "$ours" -gt "$last_auth" ] || fail 'auth line comes before the distribution auth rules'
cp "$PAM" "$TEST/once"
ensure_greetd_keyring_pam >/dev/null
cmp -s "$PAM" "$TEST/once" || fail 'second run changed the file'
[ "$(grep -c pam_gnome_keyring "$PAM")" = 2 ] || fail 'lines duplicated'
remove_greetd_keyring_pam
cmp -s "$PAM" "$TEST/arch.orig" || { diff "$TEST/arch.orig" "$PAM" >&2 || :; fail 'remove did not restore the Arch file'; }
echo 'OK   Arch/Void greetd: added once, removed exactly'

# 3. Debian's greetd file already has the lines: nothing changes either way.
cat > "$PAM" <<'EOF'
#%PAM-1.0
@include login

-auth        optional        pam_gnome_keyring.so
-auth        optional        pam_kwallet5.so

-session     optional        pam_gnome_keyring.so auto_start
-session     optional        pam_kwallet5.so auto_start
EOF
cp "$PAM" "$TEST/debian.orig"
ensure_greetd_keyring_pam >/dev/null
cmp -s "$PAM" "$TEST/debian.orig" || fail 'Debian file was changed'
remove_greetd_keyring_pam
cmp -s "$PAM" "$TEST/debian.orig" || fail 'remove touched Debian lines NIRUX did not add'
echo 'OK   Debian greetd: its own keyring lines are left alone'

# 4. No greetd PAM file (another display manager): nothing is created.
rm -f "$PAM"
ensure_greetd_keyring_pam >/dev/null
remove_greetd_keyring_pam
[ ! -e "$PAM" ] || fail 'a PAM file was created'
echo 'OK   without greetd nothing is written'
echo 'PASS keyring PAM'
