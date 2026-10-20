#!/bin/sh
# Test this checkout's installer against its pinned, real component releases.
# Only this not-yet-published NIRUX release is supplied as a local fixture.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT
export HOME=$TEST/home NIRUX_PREFIX=$TEST/prefix NIRUX_SYSTEM_ROOT=$TEST/system
export XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state NIRUX_LIBRARY=1
mkdir -p "$HOME" "$NIRUX_SYSTEM_ROOT/etc/pam.d" "$TEST/release"
. "$SOURCE/nirux"
unset NIRUX_LIBRARY
cp "$SOURCE/nirux" "$SOURCE/manifest" "$SOURCE/config.example.toml" "$SOURCE/appearance.example.toml" "$TEST/release/"
(cd "$SOURCE"; tar -cJf "$TEST/release/nirux-wallpapers.tar.xz" wallpaper/*.png; tar -cJf "$TEST/release/nirux-terminal.tar.xz" terminal)
(cd "$TEST/release"; sha256sum nirux manifest config.example.toml appearance.example.toml nirux-wallpapers.tar.xz nirux-terminal.tar.xz > SHA256SUMS)
for include in system-auth common-auth common-account; do
  [ ! -f "/etc/pam.d/$include" ] || ln -s "/etc/pam.d/$include" "$ROOT/etc/pam.d/$include"
done
fetch() {
  case "$1" in
    "https://github.com/nirucon/nirux/releases/download/v$VERSION/"*) cp "$TEST/release/${1##*/}" "$2" ;;
    *) curl -fsSL --connect-timeout 20 --max-time 300 --retry 3 -o "$2" "$1" ;;
  esac
}
# The target installer runs in a subprocess, so give it the local NIRUX
# fixture through a curl shim; component releases still use the real network.
REAL_CURL=$(command -v curl)
mkdir -p "$TEST/bin"
cat > "$TEST/bin/curl" <<EOF
#!/bin/sh
out=; url=; prev=
for arg in "\$@"; do
  [ "\$prev" = "-o" ] && out=\$arg
  case "\$arg" in http*) url=\$arg ;; esac
  prev=\$arg
done
case "\$url" in
  https://github.com/nirucon/nirux/releases/download/v*)
    cp "$TEST/release/\${url##*/}" "\$out" ;;
  *) exec "$REAL_CURL" "\$@" ;;
esac
EOF
chmod +x "$TEST/bin/curl"
export PATH="$TEST/bin:$PATH"

(install_or_update install --no-packages --browser helium --display-manager startx --release "$VERSION")
status
doctor
[ -x "$BIN/helium" ]
"$BIN/helium" --version | grep -q "Helium $HELIUM_VERSION"
[ -f "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ]
[ -f "$PREFIX/share/applications/helium.desktop" ]
grep -qF "Exec=\"$BIN/helium\"" "$PREFIX/share/applications/helium.desktop"
[ -f "$XDG_CONFIG_HOME/nirux/theme/kitty.conf" ]
grep -q 'NIRUX terminal integration' "$XDG_CONFIG_HOME/fish/config.fish"
[ -x "$BIN/nirux-theme-hook" ]
fish -n "$XDG_CONFIG_HOME/fish/config.fish"
fish -n "$XDG_CONFIG_HOME/nirux/fish/nirux.fish"
fish -n "$XDG_CONFIG_HOME/fish/completions/nirux.fish"
fish -n "$XDG_CONFIG_HOME/fish/completions/niructl.fish"
fish -c "source '$XDG_CONFIG_HOME/nirux/fish/nirux.fish'; fish_prompt" > "$HOME/fish-prompt.out"
grep -Eq '❯|# ' "$HOME/fish-prompt.out"
first_generation=$(readlink "$STATE/current")
sed -i 's/browser = \["helium"\]/browser = ["brave"]/' "$XDG_CONFIG_HOME/niruwm/config.toml"
grep -qx 'browser = \["brave"\]' "$XDG_CONFIG_HOME/niruwm/config.toml"
(install_or_update update --no-packages --browser helium --release "$VERSION")
[ "$(readlink "$STATE/current")" != "$first_generation" ]
grep -qx 'browser = \["helium"\]' "$XDG_CONFIG_HOME/niruwm/config.toml"
"$BIN/helium" --version | grep -q "Helium $HELIUM_VERSION"
[ "$(browser_policy)" = helium ]
doctor >/dev/null
(rollback)
[ "$(readlink "$STATE/current")" = "$first_generation" ]
"$BIN/helium" --version | grep -q "Helium $HELIUM_VERSION"
mkdir -p "$XDG_CONFIG_HOME/net.imput.helium"
printf 'keep my profile\n' > "$XDG_CONFIG_HOME/net.imput.helium/Preferences"
sh "$SOURCE/tests/config-contract.sh" "$BIN/niruwm" "$BIN/nirubar"
sh "$SOURCE/tests/startx-smoke.sh" "$BIN" "$HOME"
(uninstall --purge)
[ ! -e "$BIN/niruwm" ]
[ ! -e "$ROOT/etc/pam.d/nirulock" ]
[ ! -e "$BIN/helium" ]
[ ! -f "$PREFIX/share/applications/helium.desktop" ]
[ ! -e "$XDG_CONFIG_HOME/nirux" ]
[ ! -e "$BIN/nirux-theme-hook" ]
[ ! -e "$HOME/Pictures/Wallpapers/NIRU/nirux-wallpaper-noir-4k.png" ]
[ "$(cat "$XDG_CONFIG_HOME/net.imput.helium/Preferences")" = 'keep my profile' ]
printf 'PASS: real pinned releases install, Helium is managed, diagnose, startx and owned uninstall\n'
