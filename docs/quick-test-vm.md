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


## 1.1 Attach the USB scanner to the running VM

For VirtualBox testing, plugging the scanner into the host is not enough. Attach it to the VM:

```text
VirtualBox VM window → Devices → USB → Chipsailing CS9711Fingprint
```

or select the device with USB ID `2541:0236`.

The menu item should become checked. Then verify inside the VM:

```bash
lsusb
```

Expected: one line contains `2541:0236`.

On a real physical Linux machine, skip this whole VirtualBox USB passthrough step.


## 1.2 Optional: install VirtualBox Guest Additions for clipboard

This step is useful only for VirtualBox testing. It enables shared clipboard, better mouse integration, and display integration.

If you install on a real physical Linux machine, skip this step.

In the VirtualBox VM window menu, choose:

```text
Devices → Insert Guest Additions CD image...
```

Then inside the VM open Konsole and run:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-amd64 bzip2 perl make gcc wget
sudo mkdir -p /mnt/vboxga
sudo mount /dev/sr0 /mnt/vboxga
sudo sh /mnt/vboxga/VBoxLinuxAdditions.run
sudo reboot
```

After reboot, log in again. In VirtualBox settings/menu, make sure shared clipboard is enabled:

```text
Devices → Shared Clipboard → Bidirectional
```

Expected result: copying text from the host and pasting it into the VM terminal works.

Note: Debian 13/trixie repositories may not provide `virtualbox-guest-utils` / `virtualbox-guest-x11` packages by default. The Guest Additions CD image method above is the tested path.

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
sudo -k && sudo true
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


## Troubleshooting: pasted command became `truesudo`

If the terminal says:

```text
sudo: truesudo: command not found
```

then the PDF viewer or clipboard merged two lines into one. Run the sudo test as one explicit line:

```bash
sudo -k && sudo true
```
