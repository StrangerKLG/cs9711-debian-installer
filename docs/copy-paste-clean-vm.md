# Copy-paste test instructions for a clean Debian 13 VM

These steps are intentionally simple: log in to a clean Debian 13 VM console, paste commands, and verify that CS9711 enrollment works.

> Replace `OWNER/REPO` with the final GitHub repository path once the repository is published.

## 0. VirtualBox USB setup

Power off the VM and add a USB filter for the scanner:

```text
Vendor ID: 2541
Product ID: 0236
Name: Chipsailing CS9711Fingprint
```

Recommended VM settings:

```text
USB Controller: USB 3.0 / xHCI
Graphics: VMSVGA
Video memory: 128 MB
3D acceleration: off
```

Then boot the VM and log in.

## 1. Install basic tools

On minimal Debian, `sudo` and `git` may be missing. Run this first:

```bash
su -c "apt-get update && apt-get install -y sudo git ca-certificates && /usr/sbin/usermod -aG sudo $USER"
```

Enter the root password when asked.

Then log out and log back in so the new `sudo` group membership is applied:

```bash
exit
```

Log in again.

Check sudo:

```bash
sudo true
```

## 2. Download the installer project

```bash
cd ~
git clone https://github.com/OWNER/REPO.git cs9711-debian-installer
cd cs9711-debian-installer
```

## 3. Read what the script will do

```bash
less README.md
less docs/credits.md
less docs/manual-guide.md
./install.sh --help
```

## 4. First run: driver + enroll + verify

```bash
sudo ./install.sh --user "$USER" --driver-only --enroll --verify --yes
```

When enrollment starts, touch the same finger repeatedly:

- touch;
- lift;
- touch again with a slightly different position;
- repeat until enrollment completes.

Expected success markers:

```text
Enroll result: enroll-completed
Verify result: verify-match (done)
```

If verify does not match, rerun enrollment before enabling PAM.

## 5. Enable sudo fingerprint authentication

Only after successful `verify-match`:

```bash
sudo ./install.sh --user "$USER" --no-driver --sudo --yes
```

Test safely:

```bash
sudo -k
sudo true
```

Expected behavior: sudo asks for the enrolled finger. Password remains fallback if fingerprint fails or times out.

## 6. Optional: enable SDDM login

Only if the VM uses SDDM:

```bash
sudo ./install.sh --user "$USER" --no-driver --sddm --yes
```

Test by logging out to SDDM, pressing Enter on the password field, then touching the enrolled finger.

## 7. Do not enable global common-auth

This project intentionally does **not** enable fingerprint globally via `pam-auth-update` / `common-auth`.

Reason: KDE lockscreen fingerprint was unstable in the tested setup, and KDE Wallet still needs a password.

## 8. Rollback info

Print rollback instructions:

```bash
sudo ./install.sh --rollback
```

Backups are stored under:

```text
/root/cs9711-installer-backups/<timestamp>/
```
