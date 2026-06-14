# CS9711 Fingerprint Installer for Debian 13

Experimental installer for USB fingerprint scanners detected as:

```text
2541:0236 Chipsailing CS9711Fingprint
```

It automates the working Debian 13 flow tested on a live system:

- install build/runtime dependencies;
- build pinned [`ericlinagora/libfprint-CS9711`](https://github.com/ericlinagora/libfprint-CS9711) commit `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`;
- patch old Meson `udev` dependency to Debian 13 `libudev`;
- install `libfprint` into `/usr/local`;
- add udev rule to disable USB autosuspend for `2541:0236`;
- optionally enable fingerprint authentication for `sudo`, SDDM, and KDE/Polkit admin prompts, with password fallback.


## AI-generated installer disclosure

This installer script and documentation were drafted with help from an AI assistant, based on manual testing on Debian 13.

The AI did **not** create the fingerprint driver. This repository wraps and automates installation of the community fork [`ericlinagora/libfprint-CS9711`](https://github.com/ericlinagora/libfprint-CS9711), pinned to the tested commit `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`. See [Credits and related projects](docs/credits.md).

Please read the script before running it. It modifies `/usr/local` libraries, udev rules, and optionally PAM files.

## Big warning

This is not an official Debian/libfprint package. It installs a forked `libfprint` into `/usr/local` so `fprintd` loads it before the stock library.

Do **not** enable fingerprint globally in `/etc/pam.d/common-auth` unless you know exactly what you are doing. In the tested KDE setup, KDE lockscreen fingerprint crashed `fprintd`. The installer deliberately uses targeted PAM snippets for `sudo`, SDDM, and optional Polkit instead.

Keep a password/root/SSH recovery path open while testing.

## Quick start

Clone or download this project, then:

```bash
sudo ./install.sh --user "$USER" --driver-only --enroll --verify
```

If you get `verify-match`, optionally enable fingerprint for `sudo`, SDDM login, and KDE/Polkit admin prompts:

```bash
sudo ./install.sh --user "$USER" --no-driver --sudo --sddm --polkit
```

Test `sudo`:

```bash
sudo -k
sudo true
```

For SDDM: log out to the login screen, press Enter on the password field, then touch the enrolled finger. Password should remain a fallback.

For Polkit/KDE admin prompts: trigger a desktop action that opens “Authentication is required” / “Требуется аутентификация”, then touch the enrolled finger. Password should remain a fallback.

## One-shot install

For confident testers only:

```bash
sudo ./install.sh --user "$USER" --sudo --sddm --polkit --enroll --verify
```

This still avoids global `common-auth` fingerprint auth.

## Options

```text
--user USER       Target login user
--finger FINGER   Finger name, default right-index-finger
--driver-only     Driver + udev only; no PAM changes
--sudo            Enable sudo fingerprint auth for USER
--sddm            Enable SDDM fingerprint auth for USER
--polkit          Enable KDE/Polkit admin-prompt fingerprint auth for USER
--enroll          Run fprintd-enroll
--verify          Run fprintd-verify
--no-driver       Skip driver build/install
--no-udev         Skip udev autosuspend rule
-y, --yes         Non-interactive prompts
--rollback        Print rollback notes
```

## What gets changed

- `/usr/local/lib/.../libfprint-2.so*`
- `/etc/ld.so.conf.d/local-libfprint.conf`
- `/etc/udev/rules.d/99-cs9711-fingerprint-power.rules`
- optionally `/etc/pam.d/sudo`
- optionally `/etc/pam.d/sddm`
- optionally `/etc/pam.d/polkit-1` (local override copied from `/usr/lib/pam.d/polkit-1` when needed)

Backups are stored under:

```text
/root/cs9711-installer-backups/YYYYMMDD-HHMMSS/
```

## Rollback

Show rollback notes:

```bash
sudo ./install.sh --rollback
```

Short version:

1. Restore `/etc/pam.d` from the backup folder, or remove blocks between:

```text
# BEGIN cs9711-fingerprint-installer
# END cs9711-fingerprint-installer
```

2. Disable local libfprint override:

```bash
sudo rm -f /etc/ld.so.conf.d/local-libfprint.conf
sudo mkdir -p /root/libfprint-cs9711-disabled
sudo find /usr/local/lib /usr/local/lib64 -name 'libfprint-2.so*' -exec mv -t /root/libfprint-cs9711-disabled/ {} + 2>/dev/null || true
sudo ldconfig
sudo systemctl restart fprintd || true
```

3. Remove udev rule if desired:

```bash
sudo rm -f /etc/udev/rules.d/99-cs9711-fingerprint-power.rules
sudo udevadm control --reload-rules
sudo udevadm trigger -s usb || true
```

## Tested environment

- Debian 13 trixie
- `fprintd 1.94.5-2`
- stock `libfprint-2-2 1:1.94.9-1` did **not** support the scanner
- scanner USB ID `2541:0236`
- fork commit `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`
- `sudo` fingerprint auth: works
- SDDM login fingerprint auth: works via Enter → finger
- KDE/Polkit admin-prompt fingerprint auth: works
- KDE lockscreen fingerprint: not recommended; crashed `fprintd` during testing

## Why not a `.deb` yet?

A proper package would be better, but the first goal is to reduce a 20+ page manual guide to a safe, auditable script. A `.deb`/CI-built release can be added later.

## Clean VM test guide

See [docs/quick-test-vm.md](docs/quick-test-vm.md).

## Copy-paste clean VM instructions

For a fresh Debian 13 VM test, see [docs/copy-paste-clean-vm.md](docs/copy-paste-clean-vm.md).
