# CS9711 Fingerprint Installer for Debian 13

Experimental installer for USB fingerprint scanners detected as:

```text
2541:0236 Chipsailing CS9711Fingprint
```

Tested with this specific USB fingerprint reader bought by the maintainer:

- <https://www.ozon.ru/product/usb-skaner-otpechatkov-paltsev-windows-hello-dl-ya-pk-noutbuka-chernoe-1410552111/>

This is **not advertising or an affiliate recommendation**. It is only a reference to the exact device that was purchased and tested.

It automates the working Debian 13 flow tested on a live system:

- install build/runtime dependencies;
- build pinned [`ericlinagora/libfprint-CS9711`](https://github.com/ericlinagora/libfprint-CS9711) commit `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`;
- patch old Meson `udev` dependency to Debian 13 `libudev`;
- install `libfprint` into `/usr/local`;
- add udev rule to disable USB autosuspend for `2541:0236`;
- optionally enable fingerprint authentication for `sudo`, SDDM, and KDE/Polkit admin prompts, with password fallback.



## Russian documentation

Russian documentation is available in [`docs/ru/README.ru.md`](docs/ru/README.ru.md).

## AI-generated installer disclosure

This installer script and documentation were drafted by an AI agent, with human direction and review, based on manual testing on Debian 13.

The AI agent did **not** create the fingerprint driver. This repository wraps and automates installation of the community fork [`ericlinagora/libfprint-CS9711`](https://github.com/ericlinagora/libfprint-CS9711), pinned to the tested commit `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`. See [Credits and related projects](docs/credits.md) and [Third-party notices](THIRD_PARTY_NOTICES.md).

Please read the script before running it. It modifies `/usr/local` libraries, udev rules, and optionally PAM files.

## Big warning

This is not an official Debian/libfprint package. It installs a forked `libfprint` into `/usr/local` so `fprintd` loads it before the stock library.

This repository does not vendor or redistribute the upstream driver source or binaries. The installer downloads and builds upstream `libfprint-CS9711` locally. The wrapper files in this repository are MIT-licensed, but upstream `libfprint`/`libfprint-CS9711` remains under its own LGPL-2.1 license.

Do **not** enable fingerprint globally in `/etc/pam.d/common-auth` unless you know exactly what you are doing. In the tested KDE setup, KDE lockscreen fingerprint crashed `fprintd`. The installer deliberately uses targeted PAM snippets for `sudo`, SDDM, and optional Polkit instead.

Keep a password/root/SSH recovery path open while testing.


## Step-by-step for absolute beginners

This section is intentionally very explicit.

### 1. Open the terminal

After logging into KDE, open the application menu and start **Konsole** / **Terminal**.

You should see a window with a prompt similar to:

```text
stranger@cs9711-github:~$
```

### 2. Copy and paste the project download commands

Copy this whole block and paste it into the terminal:

```bash
git clone https://github.com/StrangerKLG/cs9711-debian-installer.git
cd cs9711-debian-installer
```

Press Enter if the terminal does not start automatically.

Expected result: Git downloads the repository, then the prompt changes so the current folder ends with:

```text
cs9711-debian-installer$
```

### 3. Run the first install step

Copy and paste:

```bash
sudo ./install.sh --user "$USER" --driver-only --enroll --verify --yes
```

The terminal will ask for your password. Type your Linux login password and press Enter.

Important: while typing the password, nothing may be shown on screen. This is normal.

The script will install packages, build the driver, and then start fingerprint enrollment.

### 4. Enroll the finger

When the terminal asks to touch the fingerprint reader, place the same finger on the reader several times. Move it slightly between touches.

Look for a successful verification result:

```text
verify-match
```

If you see `verify-no-match`, repeat the enrollment step.

### 5. Enable fingerprint login/auth prompts

Only after `verify-match`, copy and paste:

```bash
sudo ./install.sh --user "$USER" --no-driver --sudo --sddm --polkit --yes
```

Expected result: the script finishes with `Done` and prints recommended checks.

### 6. Test sudo

Copy and paste:

```bash
sudo -k
sudo true
```

Expected result: the system asks for the enrolled finger. Touch the reader. If fingerprint fails or times out, enter the password.

### 7. Test SDDM login

Log out of KDE. On the login screen, select the user, press Enter in the password field, then touch the enrolled finger.

Expected result: you log in without typing the password. The password must still work as fallback.

### 8. Test KDE/Polkit admin prompt

Open a KDE settings action that asks for administrator authentication. When the dialog says “Authentication is required”, touch the enrolled finger.

Expected result: the admin prompt accepts the fingerprint. The password must still work as fallback.

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
