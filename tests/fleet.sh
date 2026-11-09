#!/bin/sh
# nirux fleet against fake ssh, tailscale and curl: host discovery, status
# parsing, offline and no-access hosts, relogin detection, --json, the
# [fleet] configuration, host selection for update, and setup.
set -eu
SOURCE=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST=$(mktemp -d)
trap 'rm -rf "$TEST"' EXIT HUP INT TERM
FAKE=$TEST/fake
mkdir -p "$TEST/bin" "$FAKE/hosts"
export FAKE
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# ssh: HOST is a directory under $FAKE/hosts; mode "offline" times out and
# "denied" refuses the key. The remote command runs with that host's HOME. It
# must never contain shell syntax: the real login shell there is fish.
cat > "$TEST/bin/ssh" <<'SSH'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE/ssh.log"
while [ $# -gt 0 ]; do
  case "$1" in
    -o|-i) shift 2 ;;
    -*) shift ;;
    *) break ;;
  esac
done
host=$1; shift
case "$*" in
  *[\;\|\&\$\<\>\(\)\`\'\"\{\}]*) printf '%s\n' "$*" >> "$FAKE/violations"; exit 97 ;;
esac
d=$FAKE/hosts/$host
[ -d "$d" ] || { echo "ssh: Could not resolve hostname $host: Name or service not known" >&2; exit 255; }
case "$(cat "$d/mode" 2>/dev/null)" in
  offline) echo "ssh: connect to host $host port 22: Connection timed out" >&2; exit 255 ;;
  denied) echo "$host: Permission denied (publickey,password)." >&2; exit 255 ;;
esac
cd "$d/home" || exit 255
HOME=$d/home FAKE_HOST_DIR=$d exec "$@"
SSH
cat > "$TEST/bin/tailscale" <<'TS'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE/tailscale.log"
[ "$*" = 'status --json' ] || exit 1
[ -f "$FAKE/tailscale.json" ] || { echo 'failed to connect to local tailscaled' >&2; exit 1; }
cat "$FAKE/tailscale.json"
TS
cat > "$TEST/bin/curl" <<'CURL'
#!/bin/sh
out=
while [ $# -gt 0 ]; do
  case "$1" in -o) out=$2; shift 2 ;; --connect-timeout|--max-time) shift 2 ;; *) shift ;; esac
done
[ -f "$FAKE/latest.json" ] || exit 22
cp "$FAKE/latest.json" "$out"
CURL
# pgrep -u UID -x NAME and readlink /proc/PID/exe read the fake host's table.
cat > "$TEST/bin/pgrep" <<'PGREP'
#!/bin/sh
for name; do :; done
[ -n "${FAKE_HOST_DIR:-}" ] && [ -f "$FAKE_HOST_DIR/pids.$name" ] || exit 1
cat "$FAKE_HOST_DIR/pids.$name"
PGREP
cat > "$TEST/bin/readlink" <<'READLINK'
#!/bin/sh
case "$*" in
  /proc/*/exe)
    pid=${1#/proc/}; pid=${pid%/exe}
    [ -n "${FAKE_HOST_DIR:-}" ] && [ -f "$FAKE_HOST_DIR/exe.$pid" ] || exit 1
    cat "$FAKE_HOST_DIR/exe.$pid"; exit 0 ;;
esac
for real in /usr/bin/readlink /bin/readlink; do [ ! -x "$real" ] || exec "$real" "$@"; done
exit 1
READLINK
cat > "$TEST/bin/ssh-copy-id" <<'COPY'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE/copy.log"
for host; do :; done
rm -f "$FAKE/hosts/$host/mode"
COPY
cat > "$TEST/bin/ssh-keygen" <<'KEYGEN'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE/keygen.log"
while [ $# -gt 0 ]; do case "$1" in -f) f=$2; shift 2 ;; *) shift ;; esac; done
printf 'private\n' > "$f"; printf 'ssh-ed25519 AAAA test\n' > "$f.pub"
KEYGEN
chmod +x "$TEST/bin/"*
export PATH="$TEST/bin:$PATH" HOME="$TEST/home"
unset XDG_CONFIG_HOME NIRUX_PREFIX
mkdir -p "$HOME"
nirux() { sh "$SOURCE/nirux" "$@"; }

# A NIRUX host: generation VERSION, optional running programs. The fake nirux
# logs its arguments and "updates" by switching to generation $FAKE/new.
make_host() {
  h=$FAKE/hosts/$1/home
  gen=$h/.local/share/nirux/generations/$2-x
  mkdir -p "$gen/bin" "$h/.local/bin"
  cat > "$gen/bin/nirux" <<NIRUX
#!/bin/sh
VERSION=$2
printf '%s %s\n' "$1" "\$*" >> "\$FAKE/update.log"
[ ! -f "\$FAKE/hosts/$1/fail" ] || exit 1
if [ "\$1" = update ]; then
  new=\$(cat "\$FAKE/new")
  mkdir -p "\$HOME/.local/share/nirux/generations/\$new-y/bin"
  sed "s/^VERSION=.*/VERSION=\$new/" "\$0" > "\$HOME/.local/share/nirux/generations/\$new-y/bin/nirux"
  chmod +x "\$HOME/.local/share/nirux/generations/\$new-y/bin/nirux"
  printf 'niruwm %s\n' "\$new" > "\$HOME/.local/share/nirux/generations/\$new-y/bin/niruwm"
  cp "\$HOME/.local/share/nirux/current/bin/nirubar" "\$HOME/.local/share/nirux/generations/\$new-y/bin/nirubar"
  ln -sfn "\$HOME/.local/share/nirux/generations/\$new-y" "\$HOME/.local/share/nirux/current"
fi
NIRUX
  chmod +x "$gen/bin/nirux"
  printf 'niruwm %s\n' "$2" > "$gen/bin/niruwm"
  printf 'nirubar\n' > "$gen/bin/nirubar"
  ln -sfn "$gen" "$h/.local/share/nirux/current"
  ln -sfn "$h/.local/share/nirux/current/bin/nirux" "$h/.local/bin/nirux"
}
run_program() { # HOST PID NAME EXE
  printf '%s\n' "$2" >> "$FAKE/hosts/$1/pids.$3"
  printf '%s\n' "$4" > "$FAKE/hosts/$1/exe.$2"
}
printf '0.12.243\n' > "$FAKE/new"
printf '{"tag_name": "v0.12.243", "name": "NIRUX 0.12.243"}\n' > "$FAKE/latest.json"
peer() { printf '"%s": {"HostName": "%s", "DNSName": "%s.tail0.ts.net.", "OS": "%s", "Online": %s},' "$1" "$1" "$1" "$2" "$3"; }
{
  printf '{"BackendState": "Running", "Self": {"HostName": "ygg", "DNSName": "ygg.tail0.ts.net.", "OS": "linux"}, "Peer": {'
  peer alpha linux true; peer bravo linux true; peer carol linux true; peer delta linux false
  peer echo linux false; peer foxtrot linux true; peer golf linux true
  printf '"mac": {"HostName": "mac", "DNSName": "mac.tail0.ts.net.", "OS": "macOS", "Online": true}}}\n'
} > "$FAKE/tailscale.json"

# alpha: current, session running from the current generation, locked.
make_host alpha 0.12.243
A=$FAKE/hosts/alpha/home/.local/share/nirux/generations/0.12.243-x/bin
run_program alpha 101 niruwm "$A/niruwm"; run_program alpha 102 nirubar "$A/nirubar"
run_program alpha 103 nirulock /usr/bin/nirulock
# bravo: one release behind; niruwm runs from an older, different binary,
# nirubar from an older but identical one; two extras selected.
make_host bravo 0.12.242
mkdir -p "$FAKE/hosts/bravo/home/.local/share/nirux/generations/0.12.241-x/bin"
OLD=$FAKE/hosts/bravo/home/.local/share/nirux/generations/0.12.241-x/bin
printf 'niruwm 0.12.241\n' > "$OLD/niruwm"; printf 'nirubar\n' > "$OLD/nirubar"
run_program bravo 201 niruwm "$OLD/niruwm"; run_program bravo 202 nirubar "$OLD/nirubar"
printf 'nirusec\nnplay\n' > "$FAKE/hosts/bravo/home/.local/share/nirux/extras-selected"
# carol: NIRUX, but this machine's key is not accepted.
make_host carol 0.12.243; printf 'denied\n' > "$FAKE/hosts/carol/mode"
# delta: offline, seen before; echo: offline, never seen.
mkdir -p "$HOME/.local/share/nirux"
printf 'delta 0.12.240 %s\n' "$(($(date +%s) - 7200))" > "$HOME/.local/share/nirux/fleet-known"
# foxtrot: answers, no NIRUX. golf: Tailscale says online, SSH times out.
mkdir -p "$FAKE/hosts/foxtrot/home"
make_host golf 0.12.243; printf 'offline\n' > "$FAKE/hosts/golf/mode"

row() { awk -v h="$1" '$1 == h' "$TEST/out"; }
# --- status ------------------------------------------------------------------
nirux fleet > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail "fleet status failed"; }
head -n 1 "$TEST/out" | grep -q '^HOST *STATE *NIRUX *BEHIND *RELOGIN *LOCKED *DISTRO *UP *UPDATED$' || fail "table header"
row alpha | grep -q 'online *0\.12\.243 *no *no *yes ' || fail "alpha row: $(row alpha)"
row bravo | grep -q 'online *0\.12\.242 *yes (0\.12\.243) *yes: niruwm *no ' || fail "bravo row: $(row bravo)"
row carol | grep -q 'no access (run nirux fleet setup)' || fail "carol should be no access: $(row carol)"
row delta | grep -q 'offline *(0\.12\.240).*seen 2h0m ago' || fail "delta should be offline, last seen: $(row delta)"
row golf | grep -q 'offline' || fail "golf (ssh timeout) should be offline: $(row golf)"
[ -z "$(row echo)" ] && grep -q '^Offline, never seen with NIRUX (not listed): echo' "$TEST/out" || fail "echo should be hidden"
[ -z "$(row foxtrot)" ] && grep -q 'Reachable without NIRUX (not listed): .*foxtrot' "$TEST/out" || fail "foxtrot should be hidden"
grep -q 'ygg' "$TEST/out" && ! grep -q '^ygg' "$TEST/out" || fail "this machine without NIRUX should be named below the table only"
! grep -q '^mac' "$TEST/out" || fail "non-Linux peers must be ignored"
grep -q 'run nirux fleet setup' "$TEST/out" || fail "no-access hint"
grep -q '^bravo 0.12.242 ' "$HOME/.local/share/nirux/fleet-known" &&
  grep -q '^delta 0.12.240 ' "$HOME/.local/share/nirux/fleet-known" || fail "fleet-known not updated"
! grep -v -e '-o BatchMode=yes -o ConnectTimeout=5 [a-z]* sh -s$' "$FAKE/ssh.log" || fail "status must use BatchMode sh -s only"
for h in delta echo; do ! grep -q " $h " "$FAKE/ssh.log" || fail "offline $h was contacted"; done
[ "$(sort -u "$FAKE/tailscale.log")" = 'status --json' ] || fail "tailscale used for more than reading status"

# --- json --------------------------------------------------------------------
nirux fleet status --json > "$TEST/json" || fail "fleet --json failed"
python3 -I - "$TEST/json" <<'PY' || fail "json content"
import json, sys
d = json.load(open(sys.argv[1]))
h = {x["host"]: x for x in d["hosts"]}
assert d["latest"] == "0.12.243" and d["source"] == "tailscale", d
assert set(h) == {"alpha", "bravo", "carol", "delta", "golf"}, set(h)
a, b = h["alpha"], h["bravo"]
assert a["state"] == "online" and a["behind"] is False and a["relogin"] is False and a["locked"] is True and a["session"] is True
assert b["behind"] is True and b["relogin"] is True and b["relogin_programs"] == ["niruwm"] and b["extras"] == 2
assert h["carol"]["state"] == "no-access" and h["carol"]["version"] is None
assert h["delta"]["state"] == "offline" and h["delta"]["last_version"] == "0.12.240"
assert isinstance(a["uptime_seconds"], int) and isinstance(a["updated_seconds_ago"], int)
PY

# --- configuration -----------------------------------------------------------
mkdir -p "$HOME/.config/nirux"
cat > "$HOME/.config/nirux/fleet.toml" <<'TOML'
# hosts replace discovery; exclude always applies
[other]
hosts = ["nobody"]
[fleet]
hosts = [
  "alpha",   # desk
  "carol", "foxtrot",
  "-oProxyCommand=bad",
]
exclude = ['carol']
TOML
nirux fleet > "$TEST/out" 2>&1 || fail "status with config failed"
[ "$(awk 'NR > 1 && /^[a-z]/ { print $1 }' "$TEST/out" | tr '\n' ' ')" = 'alpha foxtrot ' ] || { cat "$TEST/out"; fail "config hosts/exclude not applied"; }
row foxtrot | grep -q 'no NIRUX' || fail "a configured host without NIRUX is listed"
grep -q 'ignoring invalid host name' "$TEST/out" || fail "invalid host name accepted"
! grep -q 'ProxyCommand' "$FAKE/ssh.log" || fail "invalid host name passed to ssh"
printf '[fleet]\nexclude = ["bravo", "golf"]\n' > "$HOME/.config/nirux/fleet.toml"
nirux fleet > "$TEST/out" 2>&1
[ -z "$(row bravo)" ] && [ -z "$(row golf)" ] && [ -n "$(row alpha)" ] || fail "exclude with Tailscale discovery"
# Without Tailscale: the configuration only, and say so.
mv "$FAKE/tailscale.json" "$FAKE/tailscale.off"
nirux fleet > "$TEST/out" 2>&1
grep -q 'tailscale is not running, and .*fleet.toml lists no hosts' "$TEST/out" || fail "no tailscale, no config message"
printf '[fleet]\nhosts = ["alpha", "golf"]\n' > "$HOME/.config/nirux/fleet.toml"
nirux fleet > "$TEST/out" 2>&1
grep -q '^Note: tailscale is not running; using the hosts in' "$TEST/out" || fail "config-only note"
row alpha | grep -q online && row golf | grep -q offline || fail "config-only probing"
mv "$FAKE/tailscale.off" "$FAKE/tailscale.json"
rm -f "$HOME/.config/nirux/fleet.toml"

# --- update ------------------------------------------------------------------
: > "$FAKE/ssh.log"
nirux fleet update > "$TEST/out" 2>&1 && fail "update without hosts must fail"
nirux fleet update --behind > "$TEST/out" 2>&1 < /dev/null || { cat "$TEST/out"; fail "update --behind failed"; }
[ "$(cat "$FAKE/update.log")" = "bravo update
bravo extras update" ] || fail "--behind should update only bravo, with extras: $(cat "$FAKE/update.log")"
grep -q -- '-t bravo .local/bin/nirux update$' "$FAKE/ssh.log" || fail "update must run over ssh -t"
grep -q '== bravo: updated, now 0.12.243; relogin needed (niruwm); nothing was logged out' "$TEST/out" || { cat "$TEST/out"; fail "update result"; }
grep -q 'updated: bravo; failed: none' "$TEST/out" || fail "update summary"
! grep -qi 'terminate\|loginctl\|pkill' "$FAKE/ssh.log" || fail "update must not end sessions"
: > "$FAKE/update.log"
nirux fleet update --all > "$TEST/out" 2>&1 < /dev/null || fail "update --all failed"
[ "$(cut -d ' ' -f 1 "$FAKE/update.log" | sort -u | tr '\n' ' ')" = 'alpha bravo ' ] || fail "--all hosts: $(cat "$FAKE/update.log")"
grep -q '== alpha: updated, now 0.12.243; running session is current' "$TEST/out" || fail "alpha result"
: > "$FAKE/update.log"
nirux fleet update carol delta nowhere > "$TEST/out" 2>&1 < /dev/null || { cat "$TEST/out"; fail "skips are not failures"; }
[ ! -s "$FAKE/update.log" ] || fail "an unreachable host was updated"
grep -q 'carol: no SSH access, skipped' "$TEST/out" && grep -q 'delta: offline, skipped' "$TEST/out" &&
  grep -q 'nowhere: offline, skipped' "$TEST/out" || { cat "$TEST/out"; fail "skip messages"; }
touch "$FAKE/hosts/alpha/fail"
nirux fleet update alpha bravo > "$TEST/out" 2>&1 < /dev/null && fail "a failed host must fail the command"
grep -q '== alpha: FAILED' "$TEST/out" && grep -q 'updated: bravo; failed: alpha' "$TEST/out" || { cat "$TEST/out"; fail "failure report"; }
rm -f "$FAKE/hosts/alpha/fail"
nirux fleet update -- > /dev/null 2>&1 && fail "unknown option accepted"
nirux fleet update '-oProxyCommand=x' > /dev/null 2>&1 && fail "option-like host accepted"
[ ! -f "$FAKE/violations" ] || fail "a remote command contained shell syntax: $(cat "$FAKE/violations")"

# --- setup -------------------------------------------------------------------
printf 'n\n' | nirux fleet setup > "$TEST/out" 2>&1 && fail "declined setup must fail"
grep -q 'copy the public key to: carol' "$TEST/out" && grep -q 'Cancelled' "$TEST/out" || { cat "$TEST/out"; fail "setup plan"; }
[ ! -f "$FAKE/copy.log" ] && [ ! -f "$HOME/.ssh/id_ed25519" ] || fail "declined setup changed something"
printf 'y\n' | nirux fleet setup > "$TEST/out" 2>&1 || { cat "$TEST/out"; fail "setup failed"; }
grep -q 'create an ed25519 key' "$TEST/out" && [ -f "$HOME/.ssh/id_ed25519.pub" ] || fail "key not created"
grep -q -- '-t ed25519 -f' "$FAKE/keygen.log" || fail "keygen arguments"
[ "$(cat "$FAKE/copy.log")" = "-i $HOME/.ssh/id_ed25519.pub carol" ] || fail "ssh-copy-id: $(cat "$FAKE/copy.log")"
grep -q -- '-o BatchMode=yes .* carol true$' "$FAKE/ssh.log" && grep -q 'carol: key login works' "$TEST/out" || fail "setup verification"
printf 'y\n' | nirux fleet setup > "$TEST/out" 2>&1 || fail "second setup"
grep -q 'nothing to set up' "$TEST/out" || fail "setup with full access"
printf 'denied\n' > "$FAKE/hosts/golf/mode"
printf 'y\n' | nirux fleet setup golf > "$TEST/out" 2>&1 || fail "named setup"
grep -q 'use your existing key' "$TEST/out" && [ "$(wc -l < "$FAKE/keygen.log")" = 1 ] || fail "existing key reused"
[ "$(sort -u "$FAKE/tailscale.log")" = 'status --json' ] || fail "tailscale settings touched"
nirux fleet bogus > /dev/null 2>&1 && fail "unknown fleet command accepted"
nirux fleet --help | grep -q 'nirux fleet update HOST' || fail "fleet help"
nirux --help | grep -q 'nirux fleet' || fail "usage lists fleet"
echo 'fleet: OK'
