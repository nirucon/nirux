existing_dm() {
  dm_unit=$ROOT/etc/systemd/system/display-manager.service
  if [ -L "$dm_unit" ]; then basename "$(readlink "$dm_unit")" .service; return; fi
  for candidate in sddm lightdm greetd gdm lxdm xdm ly; do
    if [ -e "$ROOT/var/service/$candidate" ] || command -v "$candidate" >/dev/null 2>&1; then
      say "$candidate"; return
    fi
  done
}
choose_dm() {
  EXISTING_DM=$(existing_dm)
  if [ "$DM" = auto ]; then
    if [ -n "$EXISTING_DM" ]; then DM=keep
    elif [ -t 0 ]; then
      say "No display manager found. Choose: 1) NIRU Login (default) 2) startx 3) SDDM 4) LightDM"
      printf 'Choice [1]: '
      IFS= read -r answer || answer=1
      case "$answer" in ''|1|nirulogin) DM=nirulogin ;; 2|startx) DM=startx ;; 3|sddm) DM=sddm ;; 4|lightdm) DM=lightdm ;; *) die "invalid display-manager choice" ;; esac
    else DM=nirulogin
    fi
  fi
  case "$DM" in
    startx|keep) ;;
    nirulogin)
      [ -z "$EXISTING_DM" ] || [ "$EXISTING_DM" = "$DM" ] || die "existing display manager is $EXISTING_DM; disable it explicitly before choosing nirulogin"
      ;;
    sddm|lightdm)
      [ -z "$EXISTING_DM" ] || [ "$EXISTING_DM" = "$DM" ] || die "existing display manager is $EXISTING_DM; disable it explicitly before choosing $DM"
      ;;
    *) die "display manager must be auto, startx, nirulogin, sddm or lightdm" ;;
  esac
  say "Session entry: $DM${EXISTING_DM:+ (existing: $EXISTING_DM)}"
}
# The public backup mirror of the NIRUX suite on GitLab.com. When GitHub fails
# for a NIRUX release asset or the latest-release lookup, the same file comes
# from there (the checksums in SHA256SUMS still have to match).
# NIRUX_MIRROR=none turns the fallback off.
NIRUX_MIRROR_GITLAB=${NIRUX_MIRROR_GITLAB:-rudolfsson}
fetch_mirror_url() {
  [ "${NIRUX_MIRROR:-gitlab}" != none ] || return 1
  case "$1" in
    https://github.com/nirucon/*/releases/download/*/*)
      fm_rest=${1#https://github.com/nirucon/}
      fm_repo=${fm_rest%%/*}
      fm_rest=${fm_rest#*/releases/download/}
      fm_tag=${fm_rest%%/*}
      fm_file=${fm_rest#*/}
      case "$fm_tag" in v[0-9]*) fm_version=${fm_tag#v} ;; *) fm_version=$fm_tag ;; esac
      printf 'https://gitlab.com/api/v4/projects/%s%%2F%s/packages/generic/%s/%s/%s\n' \
        "$NIRUX_MIRROR_GITLAB" "$fm_repo" "$fm_repo" "$fm_version" "$fm_file"
      ;;
    https://api.github.com/repos/nirucon/*/releases/latest)
      fm_repo=${1#https://api.github.com/repos/nirucon/}
      fm_repo=${fm_repo%%/*}
      printf 'https://gitlab.com/api/v4/projects/%s%%2F%s/releases/permalink/latest\n' \
        "$NIRUX_MIRROR_GITLAB" "$fm_repo"
      ;;
    *) return 1 ;;
  esac
}
fetch() {
  if command -v curl >/dev/null 2>&1; then
    fetch_attempts "$1" "$2" "${NIRUX_FETCH_ATTEMPTS:-8}" && return 0
    fetch_mirror=$(fetch_mirror_url "$1") || return 1
    printf 'nirux: GitHub failed; trying the GitLab mirror: %s\n' "${1##*/}" >&2
    fetch_attempts "$fetch_mirror" "$2" "${NIRUX_MIRROR_ATTEMPTS:-3}"
  elif command -v wget >/dev/null 2>&1; then
    if [ -t 2 ]; then wget --show-progress -T 60 -t 3 -O "$2" "$1"
    else wget -q -T 60 -t 3 -O "$2" "$1"; fi
  else die "install curl or wget and ca-certificates first"
  fi
}
fetch_attempts() {
  fetch_try=1
  while :; do
    case "$1" in
      *api.github.com*|*github.com/*/releases/download/*|*github.com/*/archive/*)
        # GitHub's API and CDN cache a response per URL: a stale asset when
        # a release is republished within the cache window, and also a 504
        # from an overloaded edge, so retrying the same URL gets the same
        # failure for minutes. Every attempt asks with its own query; the
        # path, and so the asset and its checksum, stay the same.
        fetch_url="$1?nirux=$(date +%s)-$$-$fetch_try"
        fetch_quiet=1
        ;;
      *)
        fetch_url=$1
        if [ -t 2 ]; then fetch_quiet=; else fetch_quiet=1; fi
        ;;
    esac
    if [ -n "$fetch_quiet" ]; then
      curl -fsSL --connect-timeout 20 --max-time 300 -o "$2" "$fetch_url" && return 0
    else
      curl -fL --progress-bar --connect-timeout 20 --max-time 300 -o "$2" "$fetch_url" && return 0
    fi
    if [ "$fetch_try" -ge "$3" ]; then
      printf 'nirux: download failed after %s attempts: %s\n' "$fetch_try" "$1" >&2
      rm -f "$2"
      return 1
    fi
    printf 'nirux: download failed (attempt %s), retrying: %s\n' "$fetch_try" "${1##*/}" >&2
    sleep $((fetch_try < 5 ? fetch_try * 2 : 10))
    fetch_try=$((fetch_try + 1))
  done
}
valid_version() {
  case "$1" in ''|*[!0-9.]*|.*|*.) return 1 ;; *) return 0 ;; esac
}
verify() {
  expected=$(awk -v n="$2" '$2 == n {print $1}' "$1/SHA256SUMS")
  [ "${#expected}" = 64 ] || die "missing or ambiguous checksum for $2"
  case "$expected" in *[!0-9a-fA-F]*) die "invalid checksum for $2" ;; esac
  actual=$(sha256sum "$1/$2" | cut -d ' ' -f1)
  [ "$actual" = "$expected" ] || die "checksum mismatch for $2; current installation kept"
}
release_files() {
  download_repo=$1; download_version=$2; shift 2
  valid_version "$download_version" || die "invalid version: $download_version"
  download_dir=$WORK/download/$download_repo
  mkdir -p "$download_dir"
  download_base=https://github.com/nirucon/$download_repo/releases/download/v$download_version
  say "Downloading $download_repo $download_version..."
  fetch "$download_base/SHA256SUMS" "$download_dir/SHA256SUMS"
  for download_file in "$@"; do
    fetch "$download_base/$download_file" "$download_dir/$download_file"
    verify "$download_dir" "$download_file"
  done
}
release_optional_file() {
  download_repo=$1; download_version=$2; download_file=$3
  download_dir=$WORK/download/$download_repo
  [ -f "$download_dir/SHA256SUMS" ] || return 0
  awk -v n="$download_file" '$2 == n {found = 1} END {exit !found}' \
    "$download_dir/SHA256SUMS" || return 0
  download_base=https://github.com/nirucon/$download_repo/releases/download/v$download_version
  fetch "$download_base/$download_file" "$download_dir/$download_file"
  verify "$download_dir" "$download_file"
}

# ── Managed Helium browser ──────────────────────────────────────────────────
# The browser is not part of a program generation: it is a large external
# application with its own release cadence. Its verified files live under the
# NIRUX state directory, one stable link is exposed in BIN, and the persistent
# policy file records whether the user selected it or opted out.
BROWSER_ADDON_BONJOURR_ID=dlnejlppicbjfcfcedcflplfjajinajd
BROWSER_ADDON_POLICY=$ROOT/etc/chromium/policies/managed/nirux-bonjourr.json

