# Third-party notices

This repository contains a small installer script and documentation. It does **not** vendor, copy, or redistribute the `libfprint`, `fprintd`, or `libfprint-CS9711` source code.

The installer downloads and builds the following upstream project on the user's machine:

- `ericlinagora/libfprint-CS9711`
  - URL: <https://github.com/ericlinagora/libfprint-CS9711>
  - Tested pinned commit: `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`
  - Upstream license: GNU Lesser General Public License v2.1 (`LGPL-2.1`), inherited from `libfprint`

Related upstream projects:

- `libfprint`: <https://gitlab.freedesktop.org/libfprint/libfprint>
- `fprintd`: <https://gitlab.freedesktop.org/libfprint/fprintd>

## License separation

The files in this repository are licensed under the repository `LICENSE` file.

That license applies only to this installer/documentation wrapper. It does **not** relicense upstream `libfprint`, `fprintd`, or the `libfprint-CS9711` fork. Those projects remain under their own licenses and copyright notices.

When the installer builds and installs `libfprint-CS9711`, the resulting library is governed by the upstream LGPL-2.1 terms. Users should review the upstream license before using or redistributing the built library.

## No binary redistribution

This repository does not publish prebuilt binaries of `libfprint-CS9711` or `libfprint`. It only automates a local build from the pinned upstream source commit.
