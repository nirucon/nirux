#!/bin/sh
# The nightly update helper and the sleep hook against a fixture root with stub
# tools: who counts as logged in, the battery rule, the order of the steps,
# validated package names, the restore after a regression, the reports, the
# Discord post without the URL in any argument, and the Tailscale restart.
set -eu
ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
HELPER=$ROOT_DIR/checkup/nirux-autoupdate
HOOK=$ROOT_DIR/checkup/nirux-sleep
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT INT TERM
fail() { echo "FAIL autoupdate: $*" >&2; exit 1; }
[ "$(id -u)" != 0 ] || { echo 'SKIP autoupdate: the fixture tests need an unprivileged user'; exit 0; }

U=$(id -un)
R=$T/root
H=$R/home/$U
mkdir -p "$R/etc/nirux" "$R/var/lib" "$R/run" "$H/.local/bin" "$H/.local/share/nirux" "$T/bin" "$R/sys/class/power_supply"
printf 'ID=debian\n' > "$R/etc/os-release"
printf 'testhost\n' > "$R/etc/hostname"
printf 'enabled=yes\nuser=%s\nwindow=00:00-23:59\ndiscord=warnings\n' "$U" > "$R/etc/nirux/autoupdate.conf"

# Stub system tools: record every call.
for tool in apt-get apt curl loginctl who; do
  cat > "$T/bin/$tool" <<EOF
#!/bin/sh
printf '%s %s\n' "$tool" "\$*" >> "$T/calls"
case "$tool \$1" in
  "apt list") printf 'Listing...\n' ;;
  "curl -K") cat > "$T/curl-config" ;;
  "loginctl list-sessions") [ -f "$T/session" ] && cat "$T/session" ;;
  "loginctl show-session") case "\$*" in *Class*) cat "$T/session-class" ;; *State*) echo active ;; esac ;;
esac
exit 0
EOF
  chmod +x "$T/bin/$tool"
done

# A stand-in for the user's NIRUX.
cat > "$H/.local/bin/nirux" <<EOF
#!/bin/sh
printf 'nirux %s\n' "\$*" >> "$T/calls"
case "\$1" in
  --version) echo "NIRUX \$(cat "$T/version")" ;;
  doctor) cat "$T/doctor"; [ -f "$T/doctor-after" ] && [ -f "$T/updated" ] && cat "$T/doctor-after"; exit 1 ;;
  update)
    [ "\$2" = --auto ] || exit 9
    [ "\${NIRUX_AUTO:-}" = 1 ] || exit 8
    touch "$T/updated"; echo 99.0.0 > "$T/version"
    mkdir -p "\$HOME/.local/state/nirux/snapshots"
    touch "\$HOME/.local/state/nirux/snapshots/\$(date +%Y%m%d-%H%M%S)-0.12.268-to-99.0.0-\$\$.tar.gz"
    [ -f "$T/want" ] && cp "$T/want" "\$HOME/.local/share/nirux/wanted-packages" && rm -f "$T/want"
    exit 0 ;;
  extras|rollback|restore) exit 0 ;;
esac
EOF
chmod +x "$H/.local/bin/nirux"
echo 0.12.268 > "$T/version"
printf 'installed niruwm\nmissing optional dunst\nall NIRUX packages installed\n' > "$T/doctor"

export NIRUX_AUTOUPDATE_ROOT="$R" NIRUX_AUTOUPDATE_PATH="$T/bin:$PATH" NIRUX_AUTOUPDATE_SESSIONS=0
st=$R/var/lib/nirux/autoupdate

# Window and once a day.
sh "$HELPER" due || fail 'a run must be due inside the window'
sed -i "s/^window=.*/window=$(date -d '+2 hour' +%H):00-$(date -d '+3 hour' +%H):00/" "$R/etc/nirux/autoupdate.conf"
if sh "$HELPER" due; then fail 'a run outside the window must not be due'; fi
out=$(sh "$HELPER" run --scheduled)
printf '%s\n' "$out" | grep -q 'outside the update window' || fail "scheduled run outside the window: $out"
[ ! -e "$T/calls" ] || fail 'a run outside the window did something'
sed -i 's/^window=.*/window=00:00-23:59/' "$R/etc/nirux/autoupdate.conf"

# Somebody logged in: skipped, no report, nothing run.
NIRUX_AUTOUPDATE_SESSIONS=1 sh "$HELPER" run --scheduled | grep -q 'skipped: somebody is logged in' || fail 'a logged-in user did not skip the run'
[ ! -e "$st/latest" ] || fail 'a skipped run wrote a report'
grep -q 'apt-get' "$T/calls" 2>/dev/null && fail 'a skipped run upgraded packages'
# Through loginctl: a greeter session does not count, a user session does.
printf '3 1000 %s seat0 tty7\n' "$U" > "$T/session"
echo greeter > "$T/session-class"
(unset NIRUX_AUTOUPDATE_SESSIONS; sh "$HELPER" due) || fail 'due check failed'
echo user > "$T/session-class"
(unset NIRUX_AUTOUPDATE_SESSIONS; sh "$HELPER" run --scheduled) | grep -q 'skipped: somebody is logged in' || fail 'a loginctl user session did not skip the run'
echo greeter > "$T/session-class"

# On battery below 50 % without the charger: skipped.
mkdir -p "$R/sys/class/power_supply/BAT0" "$R/sys/class/power_supply/AC"
echo Battery > "$R/sys/class/power_supply/BAT0/type"; echo 30 > "$R/sys/class/power_supply/BAT0/capacity"
echo Mains > "$R/sys/class/power_supply/AC/type"; echo 0 > "$R/sys/class/power_supply/AC/online"
(unset NIRUX_AUTOUPDATE_SESSIONS; sh "$HELPER" run --scheduled) | grep -q 'skipped: on battery below 50' || fail 'a low battery did not skip the run'
echo 1 > "$R/sys/class/power_supply/AC/online"

# A full run, with packages the release asked for (one of them invalid). Only
# names in the root-owned allowlist are installed; a list in the user's home
# is never read.
: > "$T/calls"
# Void names can start with a capital (Vulkan-Tools); a leading dash or
# underscore and shell characters are refused.
printf '# NIRUX owner: x\nfake-pkg\nlib2.0-dev\nVulkan-Tools\n' > "$R/etc/nirux/autoupdate-packages"
printf 'fake-pkg\n-oops\n_under\nfoo;rm\nlib2.0-dev\nVulkan-Tools\nnot-listed\n' > "$T/want"
printf 'not-listed\n' > "$H/.local/share/nirux/autoupdate-packages"
out=$(sh "$HELPER" run --scheduled) || fail "the run failed: $out"
printf '%s\n' "$out" | grep -q '^NIRUX nightly update: testhost .* updated · 1 warning' || fail "no summary with the refusal: $out"
grep -q 'apt-get -y -q -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold full-upgrade' "$T/calls" || fail 'no non-interactive full-upgrade'
grep -qx 'apt-get install -y -q --no-install-recommends fake-pkg lib2.0-dev Vulkan-Tools' "$T/calls" || fail "wanted packages not installed as validated, allowed names: $(grep 'apt-get install' "$T/calls")"
grep 'apt-get install' "$T/calls" | grep -q not-listed && fail 'a package outside the allowlist was installed'
[ "$(cat "$H/.local/share/nirux/wanted-packages")" = not-listed ] || fail 'a refused package does not stay waiting for nirux update'
printf '%s\n' "$out" | grep -q 'not in .*autoupdate-packages, left for nirux update: not-listed' || fail "the refused package is not reported: $out"
rm -f "$H/.local/share/nirux/wanted-packages"
order=$(grep '^nirux ' "$T/calls" | grep -v -- '--version' | cut -d' ' -f2-3 | tr '\n' '|')
[ "$order" = 'doctor|update --auto|update --auto|doctor|' ] || fail "wrong order of the user steps: $order"
printf '%s\n' "$out" | grep -q 'NIRUX: 0.12.268 → 99.0.0' || fail 'the NIRUX version change is not reported'
[ "$(cat "$st/last-day")" = "$(date +%Y-%m-%d)" ] || fail 'the run did not record the day'
[ -f "$st/latest" ] || fail 'no report'
grep -q -- '---- log ----' "$st/latest" || fail 'the report has no log'
sh "$HELPER" run --scheduled | grep -q 'already ran today' || fail 'a second scheduled run on the same day was not skipped'

# Worse after the update: roll back and restore the snapshot, warn on Discord.
rm -f "$st/last-day" "$T/updated"
echo 0.12.268 > "$T/version"
printf 'missing nirubar\nnirubar: error: unknown key\n' > "$T/doctor-after"
printf 'https://discord.com/api/webhooks/1/secret-token\n' > "$R/etc/nirux/checkup-webhook"
mkdir -p "$H/.local/share/nirux/generations/a" "$H/.local/share/nirux/generations/b"
ln -sfn "$H/.local/share/nirux/generations/a" "$H/.local/share/nirux/current"
# The update switches the generation.
sed -i "s|touch \"$T/updated\";|touch \"$T/updated\"; ln -sfn \"$H/.local/share/nirux/generations/b\" \"$H/.local/share/nirux/current\";|" "$H/.local/bin/nirux"
: > "$T/calls"
out=$(sh "$HELPER" run)
printf '%s\n' "$out" | grep -q 'restored' || fail "a regression was not restored: $out"
grep -qx 'nirux rollback' "$T/calls" || fail 'no rollback after a regression'
grep -Eqx 'nirux restore [0-9]{8}-[0-9]{6}-0\.12\.268-to-99\.0\.0-[0-9]+ --yes' "$T/calls" || { cat "$T/calls" >&2; fail 'the snapshot the update took was not restored'; }
grep -q 'secret-token' "$T/curl-config" || fail 'the warning was not posted'
if grep '^curl' "$T/calls" | grep -q 'secret-token'; then fail 'the webhook URL appeared in curl arguments'; fi
rm -f "$T/doctor-after"
# Without warnings, discord=warnings posts nothing.
rm -f "$st/last-day" "$T/curl-config"
out=$(sh "$HELPER" run)
printf '%s\n' "$out" | grep -q 'updated · OK' || fail "no OK summary: $out"
[ ! -e "$T/curl-config" ] || fail 'discord=warnings posted a run without warnings'

# Seven reports are kept.
for _ in 1 2 3 4 5 6 7 8; do sleep 1; rm -f "$st/last-day"; sh "$HELPER" run >/dev/null; done
n=$(ls "$st"/report-*.txt | wc -l)
[ "$n" = 7 ] || fail "kept $n reports, expected 7"

# enable / disable.
sh "$HELPER" disable >/dev/null
grep -qx 'enabled=no' "$R/etc/nirux/autoupdate.conf" || fail 'disable did not switch it off'
if sh "$HELPER" due; then fail 'a disabled update is due'; fi
sh "$HELPER" run --scheduled | grep -q 'disabled' || fail 'a disabled scheduled run did something'
sh "$HELPER" enable >/dev/null
grep -qx 'enabled=yes' "$R/etc/nirux/autoupdate.conf" || fail 'enable did not switch it on'
sh "$HELPER" status | grep -q '^Nightly update: yes' || fail 'status does not show the setting'

# An invalid user= is refused.
sed -i 's/^user=.*/user=root/' "$R/etc/nirux/autoupdate.conf"
if sh "$HELPER" run >/dev/null 2>&1; then fail 'user=root was accepted'; fi
sed -i "s/^user=.*/user=$U/" "$R/etc/nirux/autoupdate.conf"

# ---- the sleep hook ----
mkdir -p "$T/sleep/run/systemd/system" "$T/sleepbin"
cat > "$T/sleepbin/tailscale" <<EOF
#!/bin/sh
cat "$T/ts-out"; exit 1
EOF
cat > "$T/sleepbin/systemctl" <<EOF
#!/bin/sh
echo "systemctl \$*" >> "$T/sleep-calls"
EOF
cat > "$T/sleepbin/systemd-run" <<EOF
#!/bin/sh
echo "systemd-run \$*" >> "$T/sleep-calls"
EOF
chmod +x "$T/sleepbin/tailscale" "$T/sleepbin/systemctl" "$T/sleepbin/systemd-run"
export NIRUX_SLEEP_ROOT="$T/sleep" NIRUX_SLEEP_PATH="$T/sleepbin:$PATH" NIRUX_SLEEP_DELAY=0 NIRUX_SLEEP_FOREGROUND=1
echo 'failed to connect to local tailscaled' > "$T/ts-out"
sh "$HOOK" pre suspend
[ ! -e "$T/sleep-calls" ] || fail 'the sleep hook acted before sleep'
sh "$HOOK" post suspend
grep -qx 'systemctl restart tailscaled.service' "$T/sleep-calls" || fail 'the sleep hook did not restart tailscaled'
: > "$T/sleep-calls"
echo 'Logged out.' > "$T/ts-out"
sh "$HOOK" post suspend
[ ! -s "$T/sleep-calls" ] || fail 'the sleep hook restarted a logged-out Tailscale'
# The background path returns at once.
start=$(date +%s)
NIRUX_SLEEP_FOREGROUND=0 NIRUX_SLEEP_DELAY=3 sh "$HOOK" post suspend
[ $(( $(date +%s) - start )) -lt 2 ] || fail 'the sleep hook blocked resume'
grep -q "systemd-run --no-block --quiet --collect --unit=nirux-resume-[0-9]* $HOOK check" "$T/sleep-calls" ||
  fail 'on systemd the check does not run as its own unit'
echo 'PASS autoupdate'
