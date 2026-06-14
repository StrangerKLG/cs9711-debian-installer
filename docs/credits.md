# Credits and related projects

This project is a small installer/documentation wrapper around existing open-source fingerprint work.

## Core upstream projects

- `libfprint` upstream: <https://gitlab.freedesktop.org/libfprint/libfprint>
- `fprintd` upstream: <https://gitlab.freedesktop.org/libfprint/fprintd>
- Community CS9711 fork used by this installer: <https://github.com/ericlinagora/libfprint-CS9711>
  - Pinned commit tested here: `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`

## Documentation references

- ArchWiki fprint: <https://wiki.archlinux.org/title/Fprint>
- Debian PAM documentation: <https://wiki.debian.org/PAM>

## AI disclosure

The installer script and documentation in this repository were drafted with help from an AI assistant, based on manual testing logs and a verified Debian 13 setup.

The AI did not create the fingerprint driver. The CS9711 driver support comes from the community fork listed above. This project only automates and documents a tested installation flow.

Before running the script, read it. It modifies system libraries, udev rules, and optionally PAM configuration.
