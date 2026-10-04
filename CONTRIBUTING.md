# Contributing

Keep Molaway local, small and permission-minimal. Explain the user-visible reason for a change and its privacy impact. Do not introduce telemetry, automatic update requests, private frameworks or broad permissions.

Build with Swift 6.2+ and the macOS 26+ SDK (for the availability-guarded glass API); the deployment target remains macOS 15. Run `swift test`, `python3 Scripts/verify-security.py` and `bash Scripts/build-app.sh`. Check Turkish and English, keyboard accessibility, permission-denied states and relevant monitor layouts. CI is supplied but must pass on the actual GitHub repository before claiming CI verification.

After building, quit Molaway and run `python3 Scripts/verify-installation.py`. It exercises the real installer in disposable folders using `MOLAWAY_INSTALL_DIR`; it does not replace your installed app or change your home directory.

For download or tap changes, run `python3 Scripts/verify-distribution.py` to check the pinned cask against the README and installation guide. Download the actual published app ZIP and run `python3 Scripts/verify-distribution.py --archive <downloaded-app.zip>`; also compare its hash with the release checksum file and GitHub asset digest. The offline CI guard does not verify live availability, signing, or Homebrew installation. Follow [M10 distribution verification](docs/M10_DISTRIBUTION.md) before publishing any tap command. Never point a cask at an unreleased main build or bypass Gatekeeper.

Retain the Offscreen MIT notice and document new assets/dependencies in THIRD_PARTY_NOTICES.md. Contributions are offered under the project's MIT license; contributors must have the right to contribute them. Disclose substantial AI assistance and review generated code.

Do not include personal settings, logs, screen recordings, signing certificates, keys, build caches or machine-specific files in changes. Report security issues privately as described in SECURITY.md.
