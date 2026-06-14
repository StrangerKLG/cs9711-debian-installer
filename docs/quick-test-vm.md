# Clean Debian VM test guide

This guide is for testing the installer in a clean Debian 13 VM.

## 1. Install Debian 13 in VirtualBox

Recommended VM settings:

- OS: Debian 64-bit
- RAM: 2-4 GB
- CPU: 2 cores
- Disk: 25+ GB
- USB Controller: USB 3.0/xHCI
- Add USB filter for the fingerprint scanner:

```text
Vendor ID: 2541
Product ID: 0236
Name: Chipsailing CS9711Fingprint
```

For a simple text-console VM, if VirtualBox graphics is broken on KDE/Wayland, use:

Guest GRUB after install:

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet nomodeset"
GRUB_TERMINAL=console
GRUB_GFXPAYLOAD_LINUX=text
```

Then run:

```bash
sudo update-grub
sudo reboot
```

## 2. Install git and download this project

Inside the VM:

```bash
sudo apt update
sudo apt install -y git ca-certificates
cd ~
git clone https://github.com/OWNER/REPO.git cs9711-debian-installer
cd cs9711-debian-installer
```

Replace `OWNER/REPO` with the final GitHub repository path.

## 3. Driver + enroll + verify

```bash
sudo ./install.sh --user "$USER" --driver-only --enroll --verify --yes
```

During enrollment, touch the same finger repeatedly, lifting it between touches and slightly changing position.

Expected success markers:

```text
Enroll result: enroll-completed
Verify result: verify-match (done)
```

## 4. Enable sudo fingerprint auth

Only after `verify-match`:

```bash
sudo ./install.sh --user "$USER" --no-driver --sudo --yes
```

Test it safely:

```bash
sudo -k
sudo true
```

Expected behavior: sudo asks for the enrolled finger. If fingerprint fails or times out, password remains fallback.

Optional KDE/Polkit admin prompts on desktop installs:

```bash
sudo ./install.sh --user "$USER" --no-driver --polkit --yes
```

This enables fingerprint in Polkit authorization dialogs only; it does not enable KDE lockscreen or wallet fingerprint.

## 5. Optional: SDDM login

Only if you use SDDM and understand the caveat about KDE lockscreen:

```bash
sudo ./install.sh --user "$USER" --no-driver --sddm --yes
```

Test by logging out to SDDM, pressing Enter on the password field, then touching the enrolled finger.

## Do not test with apt install

Use this instead:

```bash
sudo -k && sudo true
```

It tests authentication without changing packages.
