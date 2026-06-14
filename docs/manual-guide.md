# Manual reference

The installer was distilled from the local Obsidian deployment guide:

- `obsidian-vault/03_Resources/Linux/Chipsailing CS9711 CS9711Fingprint — deployment guide.md`

Keep the full guide as the source of detailed troubleshooting notes. This project is the short path for Debian 13 users with the same scanner.


## Optional: KDE/Polkit admin prompts

After `verify-match`, desktop systems can enable fingerprint in KDE/Polkit authorization dialogs:

```bash
sudo ./install.sh --user "$USER" --no-driver --polkit
```

The installer creates/edits `/etc/pam.d/polkit-1` only and keeps password fallback through `common-auth`. It does not enable fingerprint globally via `common-auth`, and it does not enable KDE lockscreen or wallet fingerprint.
