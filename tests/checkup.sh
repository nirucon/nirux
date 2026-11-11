#!/bin/sh
# The weekly checkup helper against a fixture root with stub tools: the due
# rule, the report, three kept reports, clean-up by age that never follows
# links, the Discord post without the URL in any argument, and webhook input.
set -eu
ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
HELPER=$ROOT_DIR/checkup/nirux-checkup
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT INT TERM
fail() { echo "FAIL checkup: $*" >&2; exit 1; }

R=$T/root
mkdir -p "$R/etc/nirux" "$R/var/lib" "$R/home/niru/.local/share/nirux/current" \
  "$R/home/niru/.cache/thumbnails" "$R/tmp" "$R/var/tmp" "$R/run/systemd/system" "$T/bin"
printf 'ID=debian\n' > "$R/etc/os-release"
printf 'testhost\n' > "$R/etc/hostname"
printf 'suite 0.12.254\n' > "$R/home/niru/.local/share/nirux/current/manifest"
printf 'enabled=yes\ndiscord=always\nclean=full\ndisk_warn=85\nuser=%s\n' "$(id -un)" > "$R/etc/nirux/checkup.conf"
mkdir -p "$R/home/$(id -un)/.cache/thumbnails"

# Stub tools: record every call, answer with fixtures.
for tool in apt-get apt smartctl systemctl journalctl timedatectl curl tailscale ufw uname; do
  cat > "$T/bin/$tool" <<EOF
#!/bin/sh
printf '%s %s\n' "$tool" "\$*" >> "$T/calls"
case "$tool \$1" in
  "smartctl --scan") echo '/dev/nvme0 -d nvme # nvme0' ;;
  "smartctl -H") printf 'SMART overall-health self-assessment test result: PASSED\nPercentage Used: 3%%\nMedia and Data Integrity Errors: 0\n' ;;
  "apt list") printf 'Listing...\nfoo/stable 1 amd64\nbar/stable-security 2 amd64\n' ;;
  "uname -r") echo 6.12.1 ;;
  "timedatectl show") echo yes ;;
  "ufw status") echo 'Status: active' ;;
  "curl -fsS") echo '{"tag_name": "v0.12.254"}' ;;
  "curl -K") cat > "$T/curl-config" ;;
esac
exit 0
EOF
  chmod +x "$T/bin/$tool"
done
mkdir -p "$R/lib/modules/6.12.1"
export PATH="$T/bin:$PATH" NIRUX_CHECKUP_ROOT="$R"

# Due: never run, then not until the next Monday 07:00.
sh "$HELPER" due || fail 'a first run must be due'
mkdir -p "$R/var/lib/nirux/checkup"
date +%s > "$R/var/lib/nirux/checkup/last-run"
if sh "$HELPER" due; then fail 'a run just now must not be due'; fi
# A run two weeks ago always passed a Monday 07:00.
echo $(( $(date +%s) - 14 * 86400 )) > "$R/var/lib/nirux/checkup/last-run"
sh "$HELPER" due || fail 'a two-week-old run must be due'
sed -i 's/^enabled=yes/enabled=no/' "$R/etc/nirux/checkup.conf"
if sh "$HELPER" due; then fail 'a disabled checkup must not be due'; fi
sed -i 's/^enabled=no/enabled=yes/' "$R/etc/nirux/checkup.conf"

# Old and new temporary files; a link to a file outside must survive.
touch -d '20 days ago' "$R/tmp/old-file"
touch -d '100 days ago' "$R/home/$(id -un)/.cache/thumbnails/old.png"
touch "$R/tmp/new-file"
printf 'keep\n' > "$T/outside"
ln -s "$T/outside" "$R/tmp/link-out"

# Dry run changes nothing.
out=$(sh "$HELPER" run --dry-run)
printf '%s\n' "$out" | grep -q 'would delete' || fail 'dry run does not list deletions'
[ -f "$R/tmp/old-file" ] || fail 'dry run deleted a file'
grep -q 'apt-get clean' "$T/calls" 2>/dev/null && fail 'dry run ran apt-get clean'

# Webhook input is validated and stored 0600.
if printf 'https://example.com/x\n' | sh "$HELPER" webhook-set 2>/dev/null; then fail 'accepted a non-Discord URL'; fi
printf 'https://discord.com/api/webhooks/1/secret-token\n' | sh "$HELPER" webhook-set >/dev/null
[ "$(stat -c %a "$R/etc/nirux/checkup-webhook")" = 600 ] || fail 'webhook file is not 0600'

# A real run: report, clean-up, Discord.
: > "$T/calls"
out=$(sh "$HELPER" run)
printf '%s\n' "$out" | grep -q '^NIRUX checkup: testhost' || fail "report header missing: $out"
printf '%s\n' "$out" | grep -q 'SMART .*OK (1 drive)' || fail 'SMART line missing'
printf '%s\n' "$out" | grep -q 'Updates.*2 packages (1 security)' || fail 'update count missing'
printf '%s\n' "$out" | grep -q '1 warning' || fail 'the security update should be one warning'
grep -q 'apt-get clean' "$T/calls" || fail 'apt-get clean did not run'
grep -q 'apt-get -y autoremove' "$T/calls" || fail 'autoremove did not run at clean=full'
grep -q 'journalctl --vacuum-size=200M' "$T/calls" || fail 'journal was not vacuumed'
[ ! -e "$R/tmp/old-file" ] || fail 'an old temporary file was kept'
[ -e "$R/tmp/new-file" ] || fail 'a new temporary file was deleted'
[ -L "$R/tmp/link-out" ] || [ -e "$T/outside" ] || fail 'a link target outside was touched'
[ -e "$T/outside" ] || fail 'deleted a file outside through a link'
[ ! -e "$R/home/$(id -un)/.cache/thumbnails/old.png" ] || fail 'old thumbnail kept'
# The URL went to curl as a config on stdin, never as an argument.
grep -q 'secret-token' "$T/curl-config" || fail 'curl did not get the webhook config'
if grep 'curl' "$T/calls" | grep -q 'secret-token'; then fail 'the webhook URL appeared in curl arguments'; fi
[ -f "$R/var/lib/nirux/checkup/latest" ] || fail 'no latest report'
sh "$HELPER" last | grep -q 'testhost' || fail 'last does not print the report'

# Only three reports are kept.
for _ in 1 2 3 4; do sleep 1; sh "$HELPER" run >/dev/null; done
n=$(ls "$R/var/lib/nirux/checkup"/report-*.txt | wc -l)
[ "$n" = 3 ] || fail "kept $n reports, expected 3"

# Disk warning above the limit.
sed -i 's/^disk_warn=85/disk_warn=1/' "$R/etc/nirux/checkup.conf"
sh "$HELPER" run --dry-run | grep -q '⚠ Disk' || fail 'no disk warning above the limit'

# discord=off posts nothing.
sed -i 's/^discord=always/discord=off/' "$R/etc/nirux/checkup.conf"
rm -f "$T/curl-config"
sh "$HELPER" run >/dev/null
[ ! -e "$T/curl-config" ] || fail 'discord=off still posted'
echo 'PASS checkup'
