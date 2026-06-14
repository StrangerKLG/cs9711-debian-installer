#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="cs9711-debian-installer"
UPSTREAM_REPO="https://github.com/ericlinagora/libfprint-CS9711.git"
UPSTREAM_COMMIT="c242a40fcc51aec5b57d877bdf3edfe8cb4883fd"
BUILD_ROOT="${BUILD_ROOT:-/usr/local/src/libfprint-CS9711}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/cs9711-installer-backups}"
DEFAULT_FINGER="right-index-finger"

ASSUME_YES=0
INSTALL_DRIVER=1
SETUP_UDEV=1
SETUP_SUDO=0
SETUP_SDDM=0
ENROLL=0
VERIFY=0
ROLLBACK=0
TARGET_USER="${SUDO_USER:-${USER:-}}"
FINGER="$DEFAULT_FINGER"

log(){ printf '\033[1;34m[%s]\033[0m %s\n' "$PROJECT_NAME" "$*"; }
warn(){ printf '\033[1;33m[%s warn]\033[0m %s\n' "$PROJECT_NAME" "$*" >&2; }
err(){ printf '\033[1;31m[%s error]\033[0m %s\n' "$PROJECT_NAME" "$*" >&2; }
need_root(){ [ "$(id -u)" -eq 0 ] || { err "Run as root: sudo $0 ..."; exit 1; }; }
confirm(){
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf '%s [y/N] ' "$*" >&2
  read -r ans
  case "$ans" in y|Y|yes|YES|да|Да) return 0;; *) return 1;; esac
}
usage(){ cat <<USAGE
Usage: sudo ./install.sh [options]

Install Chipsailing CS9711 (USB ID 2541:0236) fingerprint support on Debian 13.
The script builds the pinned libfprint-CS9711 fork, installs udev power rule,
and can optionally enable fingerprint auth for sudo and SDDM only.

Options:
  --user USER          Target login user for enrollment/PAM (default: sudo user)
  --finger FINGER      Finger name for enrollment (default: right-index-finger)
  --driver-only        Build/install driver + udev only; no PAM changes (default PAM-safe mode)
  --sudo               Enable fingerprint auth for sudo for --user, password fallback kept
  --sddm               Enable fingerprint auth for SDDM login for --user, password fallback kept
  --enroll             Run fprintd-enroll after driver install
  --verify             Run fprintd-verify after enroll/install
  --no-driver          Skip driver build/install; useful for PAM-only changes
  --no-udev            Skip CS9711 USB autosuspend udev rule
  -y, --yes            Non-interactive yes to prompts
  --rollback           Print rollback instructions and exit
  -h, --help           Show this help

Recommended first run:
  sudo ./install.sh --user "$USER" --driver-only --enroll --verify

Then, after verify-match:
  sudo ./install.sh --user "$USER" --no-driver --sudo --sddm

Deliberately NOT supported by default:
  global pam-auth-update --enable fprintd / common-auth fingerprint auth.
  KDE lockscreen fingerprint, because it crashed fprintd in the tested setup.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user) TARGET_USER="${2:-}"; shift 2;;
    --finger) FINGER="${2:-}"; shift 2;;
    --driver-only) SETUP_SUDO=0; SETUP_SDDM=0; shift;;
    --sudo) SETUP_SUDO=1; shift;;
    --sddm) SETUP_SDDM=1; shift;;
    --enroll) ENROLL=1; shift;;
    --verify) VERIFY=1; shift;;
    --no-driver) INSTALL_DRIVER=0; shift;;
    --no-udev) SETUP_UDEV=0; shift;;
    -y|--yes) ASSUME_YES=1; shift;;
    --rollback) ROLLBACK=1; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage >&2; exit 2;;
  esac
done

print_rollback(){ cat <<'ROLLBACK'
Rollback notes:

1) PAM:
   Backups are stored under /root/cs9711-installer-backups/*/pam.d
   Restore one backup, for example:
     sudo cp -a /root/cs9711-installer-backups/<stamp>/pam.d/* /etc/pam.d/

   Or manually remove blocks between:
     # BEGIN cs9711-fingerprint-installer
     # END cs9711-fingerprint-installer

2) Driver:
   Remove local libfprint override:
     sudo rm -f /etc/ld.so.conf.d/local-libfprint.conf
     sudo mkdir -p /root/libfprint-cs9711-disabled
     sudo mv /usr/local/lib*/**/libfprint-2.so* /root/libfprint-cs9711-disabled/ 2>/dev/null || true
     sudo ldconfig
     sudo systemctl restart fprintd || true

3) Udev power rule:
     sudo rm -f /etc/udev/rules.d/99-cs9711-fingerprint-power.rules
     sudo udevadm control --reload-rules
     sudo udevadm trigger -s usb || true
ROLLBACK
}

[ "$ROLLBACK" -eq 1 ] && { print_rollback; exit 0; }
need_root
[ -n "$TARGET_USER" ] || { err "Target user is empty. Use --user USER"; exit 1; }
getent passwd "$TARGET_USER" >/dev/null || { err "User not found: $TARGET_USER"; exit 1; }

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
mkdir -p "$BACKUP_DIR"

check_debian(){
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    log "Detected OS: ${PRETTY_NAME:-unknown}"
    if [ "${ID:-}" != "debian" ]; then warn "This was tested on Debian 13; current ID=${ID:-unknown}."; fi
    if [ "${VERSION_ID:-}" != "13" ]; then warn "This was tested on Debian 13; current VERSION_ID=${VERSION_ID:-unknown}."; fi
  fi
}

detect_device(){
  if lsusb 2>/dev/null | grep -qiE '2541:0236|Chipsailing.*CS9711|CS9711'; then
    log "CS9711-like USB device is visible:"
    lsusb | grep -iE '2541:0236|Chipsailing|CS9711' || true
  else
    warn "USB device 2541:0236 not visible right now. Install can continue, but enrollment will fail until it is connected."
  fi
}

install_deps(){
  log "Installing Debian build/runtime dependencies"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git meson ninja-build pkg-config cmake \
    fprintd libpam-fprintd usbutils \
    libglib2.0-dev libgusb-dev libgudev-1.0-dev libnss3-dev \
    libusb-1.0-0-dev libsystemd-dev libcairo2-dev \
    libopencv-dev doctest-dev
}

backup_libfprint(){
  local d="$BACKUP_DIR/libfprint"
  mkdir -p "$d"
  shopt -s nullglob
  local files=(/usr/lib/*/libfprint-2.so.2* /usr/local/lib/*/libfprint-2.so.2* /usr/local/lib/libfprint-2.so.2*)
  if [ "${#files[@]}" -gt 0 ]; then
    cp -a "${files[@]}" "$d/" || true
    log "Backed up existing libfprint files to $d"
  else
    warn "No existing libfprint-2.so.2 files found to back up"
  fi
  shopt -u nullglob
}

build_install_driver(){
  install_deps
  backup_libfprint
  log "Cloning/updating $UPSTREAM_REPO at $UPSTREAM_COMMIT"
  mkdir -p "$(dirname "$BUILD_ROOT")"
  if [ -d "$BUILD_ROOT/.git" ]; then
    git -C "$BUILD_ROOT" fetch --all --tags
  else
    rm -rf "$BUILD_ROOT"
    git clone "$UPSTREAM_REPO" "$BUILD_ROOT"
  fi
  git -C "$BUILD_ROOT" checkout "$UPSTREAM_COMMIT"

  log "Patching Meson udev dependency for Debian 13 when needed"
  cp -n "$BUILD_ROOT/meson.build" "$BUILD_ROOT/meson.build.orig" || true
  sed -i "s/dependency('udev')/dependency('libudev')/g; s/dependency(\"udev\")/dependency(\"libudev\")/g" "$BUILD_ROOT/meson.build"

  log "Configuring/building libfprint-CS9711"
  rm -rf "$BUILD_ROOT/builddir"
  meson setup "$BUILD_ROOT/builddir" \
    --prefix=/usr/local \
    --buildtype=release \
    -Ddoc=false \
    -Dintrospection=false \
    -Dinstalled-tests=false \
    -Dgtk-examples=false \
    -Dudev_rules_dir=/usr/lib/udev/rules.d
  ninja -C "$BUILD_ROOT/builddir"

  log "Installing libfprint-CS9711 into /usr/local"
  ninja -C "$BUILD_ROOT/builddir" install
  printf '/usr/local/lib/%s\n/usr/local/lib\n' "$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || true)" > /etc/ld.so.conf.d/local-libfprint.conf
  ldconfig
  systemctl restart fprintd || true
}

setup_udev(){
  log "Installing CS9711 USB autosuspend udev rule"
  cat > /etc/udev/rules.d/99-cs9711-fingerprint-power.rules <<'EOF'
# Keep Chipsailing CS9711 fingerprint scanner awake for reliable fprintd enrollment/verify.
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2541", ATTR{idProduct}=="0236", TEST=="power/control", ATTR{power/control}="on"
EOF
  udevadm control --reload-rules
  udevadm trigger -s usb || true
  for d in /sys/bus/usb/devices/*; do
    if [ -r "$d/idVendor" ] && [ "$(cat "$d/idVendor")" = "2541" ] && [ "$(cat "$d/idProduct")" = "0236" ]; then
      echo on > "$d/power/control" 2>/dev/null || true
      log "$d power/control=$(cat "$d/power/control" 2>/dev/null || echo '?')"
    fi
  done
}

fprintd_binary(){
  for p in /usr/libexec/fprintd /usr/lib/fprintd/fprintd /usr/lib/*/fprintd; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  command -v fprintd 2>/dev/null || true
}

verify_driver(){
  log "Checking fprintd/libfprint linkage"
  local bin; bin="$(fprintd_binary)"
  if [ -n "$bin" ]; then
    ldd "$bin" | grep libfprint || warn "Could not see libfprint in ldd output for $bin"
  else
    warn "Could not locate fprintd binary for ldd check"
  fi
  systemctl restart fprintd || true
  log "Running fprintd-list for $TARGET_USER"
  if ! fprintd-list "$TARGET_USER"; then
    warn "fprintd-list failed. If it says 'No devices available', confirm device is USB ID 2541:0236 and driver install succeeded."
  fi
}

pam_backup(){
  mkdir -p "$BACKUP_DIR/pam.d" "$BACKUP_DIR/pam-configs"
  cp -a /etc/pam.d/* "$BACKUP_DIR/pam.d/" 2>/dev/null || true
  cp -a /usr/share/pam-configs/* "$BACKUP_DIR/pam-configs/" 2>/dev/null || true
  log "Backed up PAM to $BACKUP_DIR"
}

remove_global_common_auth(){
  if command -v pam-auth-update >/dev/null; then
    log "Ensuring fprintd is disabled in global common-auth"
    pam-auth-update --disable fprintd --force || true
  fi
}

install_pam_block(){
  local file="$1" tries="$2" timeout="$3" label="$4"
  [ -f "$file" ] || { warn "$file not found; skipping $label"; return 0; }
  if grep -q 'BEGIN cs9711-fingerprint-installer' "$file"; then
    log "$label PAM block already present in $file"
    return 0
  fi
  if ! grep -q '^@include common-auth' "$file"; then
    warn "$file has no '@include common-auth'; not editing automatically"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk -v user="$TARGET_USER" -v tries="$tries" -v timeout="$timeout" '
    /^@include common-auth/ && !done {
      print "# BEGIN cs9711-fingerprint-installer"
      print "# Fingerprint auth only for " user "; password remains fallback via common-auth."
      print "auth [success=ignore default=1] pam_succeed_if.so quiet user = " user
      print "auth sufficient pam_fprintd.so max-tries=" tries " timeout=" timeout
      print "# END cs9711-fingerprint-installer"
      done=1
    }
    { print }
  ' "$file" > "$tmp"
  cp "$tmp" "$file"
  rm -f "$tmp"
  log "Installed $label PAM block in $file"
}

setup_pam(){
  pam_backup
  remove_global_common_auth
  [ "$SETUP_SUDO" -eq 1 ] && install_pam_block /etc/pam.d/sudo 5 30 sudo
  [ "$SETUP_SDDM" -eq 1 ] && install_pam_block /etc/pam.d/sddm 5 30 SDDM
  log "Current pam_fprintd references:"
  grep -RIn 'pam_fprintd' /etc/pam.d /usr/share/pam-configs 2>/dev/null || true
  warn "KDE lockscreen fingerprint is intentionally not enabled. Password fallback remains via common-auth."
}

run_enroll(){
  log "Starting enrollment: user=$TARGET_USER finger=$FINGER"
  warn "Touch the scanner repeatedly with the same finger, slightly varying position."
  fprintd-enroll -f "$FINGER" "$TARGET_USER"
}

run_verify(){
  log "Starting verification: user=$TARGET_USER finger=$FINGER"
  fprintd-verify -f "$FINGER" "$TARGET_USER"
}

main(){
  check_debian
  detect_device
  if [ "$INSTALL_DRIVER" -eq 1 ]; then
    confirm "Build and install pinned libfprint-CS9711 to /usr/local?" || { warn "Driver install skipped by user"; INSTALL_DRIVER=0; }
  fi
  [ "$INSTALL_DRIVER" -eq 1 ] && build_install_driver
  [ "$SETUP_UDEV" -eq 1 ] && setup_udev
  verify_driver
  if [ "$SETUP_SUDO" -eq 1 ] || [ "$SETUP_SDDM" -eq 1 ]; then setup_pam; fi
  [ "$ENROLL" -eq 1 ] && run_enroll
  [ "$VERIFY" -eq 1 ] && run_verify
  log "Done. Backups: $BACKUP_DIR"
  log "Recommended checks: fprintd-list '$TARGET_USER'; sudo -k && sudo true; SDDM Enter -> finger if --sddm was enabled."
}
main
