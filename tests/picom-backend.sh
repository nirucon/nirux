#!/bin/sh
# NIRUX 0.12.278: picom draws on the graphics card. A new picom.conf uses glx
# with vsync; one that NIRUX wrote and that is still on xrender moves to glx
# once, with a copy; the user's own files and a later return to xrender are
# left alone.
# Offline: nothing outside a temporary HOME is touched.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_CACHE_HOME=$HOME/.cache
export NIRUX_LIBRARY=1
mkdir -p "$XDG_CONFIG_HOME"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
CONF=$XDG_CONFIG_HOME/picom.conf
MARKER=$STATE/picom-glx-0.12.278
old_default() {
  cat > "$CONF" <<'EOF'
# NIRUX default compositor. Edit or remove this file freely.
backend = "xrender";
inactive-opacity = 0.94;
active-opacity = 1.0;
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.35;
EOF
}

# 1. A new file: glx with vsync, and the old migration leaves it alone.
mkdir -p "$TEST/bin"; printf '#!/bin/sh\nexit 0\n' > "$TEST/bin/picom"; chmod +x "$TEST/bin/picom"
PATH=$TEST/bin:$PATH install_picom_config >/dev/null
grep -qx 'backend = "glx";' "$CONF" || fail 'new file is not on glx'
grep -qx 'vsync = true;' "$CONF" || fail 'new file has no vsync'
cp "$CONF" "$TEST/new"; migrate_picom_backend >/dev/null
cmp -s "$CONF" "$TEST/new" || fail 'migration changed a new glx file'
echo 'OK   a new picom.conf draws on the graphics card'

# 2. NIRUX's old default, with the user's own lines after it: moved once.
rm -f "$MARKER"; old_default
printf "shadow-exclude = [ \"class_g = 'Steam'\" ];\n" >> "$CONF"
cp "$CONF" "$TEST/before"
migrate_picom_backend >/dev/null
grep -qx 'backend = "glx";' "$CONF" || fail 'old default not moved to glx'
grep -qx 'vsync = true;' "$CONF" || fail 'vsync not added'
grep -q "class_g = 'Steam'" "$CONF" || fail 'user lines lost'
cmp -s "$CONF.bak-xrender-0.12.278" "$TEST/before" || fail 'no exact copy kept'
[ "$(grep -c '^backend' "$CONF")" = 1 ] || fail 'backend line duplicated'
echo 'OK   NIRUX'"'"'s old xrender default moves to glx, user lines and a copy kept'

# 3. A return to xrender after the migration is never undone.
sed -i 's/^backend = "glx";/backend = "xrender";/; /^vsync/d' "$CONF"
cp "$CONF" "$TEST/back"; migrate_picom_backend >/dev/null
cmp -s "$CONF" "$TEST/back" || fail 'a later choice of xrender was undone'
echo 'OK   a later return to xrender is kept'

# 4. The user's own file (no NIRUX header) or one with vsync is not touched.
rm -f "$MARKER"; printf 'backend = "xrender";\nshadow = false;\n' > "$CONF"; cp "$CONF" "$TEST/own"
migrate_picom_backend >/dev/null
cmp -s "$CONF" "$TEST/own" || fail "the user's own picom.conf was changed"
rm -f "$MARKER"; old_default; printf 'vsync = false;\n' >> "$CONF"; cp "$CONF" "$TEST/vs"
migrate_picom_backend >/dev/null
cmp -s "$CONF" "$TEST/vs" || fail 'a file with its own vsync choice was changed'
echo 'OK   own files and own vsync choices are left alone'
echo 'PASS picom backend'
