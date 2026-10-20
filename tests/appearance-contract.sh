#!/bin/sh
# The versioned appearance contract, exercised by all six components.
# Usage: appearance-contract.sh NIRUWM NIRUBAR NIRULAUNCHER NIRUNOTIFY NIRULOCK NIRUSCREENSAVER
set -eu
WM=${1:?}; BAR=${2:?}; LAUNCHER=${3:?}; NOTIFY=${4:?}; LOCK=${5:?}; SAVER=${6:?}
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
CFG=$TEST/home/.config
mkdir -p "$CFG/niruwm/themes"
cat > "$CFG/niruwm/config.toml" <<'CONFIG'
theme = "niru-noir"
terminal = ["kitty"]
launcher = ["rofi"]
CONFIG
cat > "$CFG/niruwm/appearance.toml" <<'APPEARANCE'
schema = 1
[colors]
background = "101010"
surface = "181818"
foreground = "e0e0e0"
muted = "a0a0a0"
border = "303030"
focus = "8080ff"
accent = "8080ff"
selected = "282828"
success = "80c080"
warning = "d0b060"
error = "d07070"
disabled = "606060"
[font]
size = 16.0
[spacing]
gap = 10
padding = 14
margin = 18
bar_height = 30
[focus]
width = 3
[motion]
reduced = true
APPEARANCE
check_all() {
  label=$1
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$WM" --check-config >/dev/null || { echo "FAIL $label: niruwm"; return 1; }
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$BAR" --check-config >/dev/null || { echo "FAIL $label: nirubar"; return 1; }
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$LAUNCHER" --check-config >/dev/null || { echo "FAIL $label: nirulauncher"; return 1; }
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$NOTIFY" --check-config >/dev/null || { echo "FAIL $label: nirunotify"; return 1; }
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$LOCK" --config >/dev/null || { echo "FAIL $label: nirulock"; return 1; }
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$SAVER" --config >/dev/null || { echo "FAIL $label: niruscreensaver"; return 1; }
}
for theme in niru-noir niru-nord niru-satie niru-carl-larsson; do
  sed "s/^theme = .*/theme = \"$theme\"/" "$CFG/niruwm/config.toml" > "$TEST/config.tmp"
  mv "$TEST/config.tmp" "$CFG/niruwm/config.toml"
  check_all "$theme" || exit 1
  HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$NOTIFY" --check-config | grep -qx "theme: $theme" || {
    echo "FAIL $theme: notifier theme label"; exit 1;
  }
done
cat > "$CFG/niruwm/themes/custom.toml" <<'THEME'
name = "custom"
background = "212121"
foreground = "f0f0f0"
muted = "aaaaaa"
border = "404040"
focus = "ffaa00"
THEME
sed 's/^theme = .*/theme = "custom"/' "$CFG/niruwm/config.toml" > "$TEST/config.tmp"
mv "$TEST/config.tmp" "$CFG/niruwm/config.toml"
check_all custom || exit 1
HOME=$TEST/home XDG_CONFIG_HOME=$CFG "$NOTIFY" --check-config | grep -qx 'theme: custom' || {
  echo "FAIL custom: notifier theme label"; exit 1;
}

# An invalid contract must be ignored, not replace the working theme.
printf '%s\n' 'schema = 9' > "$CFG/niruwm/appearance.toml"
check_all invalid-schema || exit 1
printf '%s\n' 'schema = 1' '[colors]' 'foreground = "not-a-colour"' > "$CFG/niruwm/appearance.toml"
check_all invalid-colour || exit 1
printf 'PASS: four built-in themes, custom theme and invalid appearance across six components\n'
