# Contributing

Keep Molaway local, small and permission-minimal. Explain the user-visible reason for a change and its privacy impact. Do not introduce telemetry, automatic update requests, private frameworks or broad permissions.

Build with Swift 6.2+ and the macOS 26+ SDK (for the availability-guarded glass API); the deployment target remains macOS 15. Run `swift test`, `python3 Scripts/verify-security.py` and `bash Scripts/build-app.sh`. Check Turkish and English, keyboard accessibility, permission-denied states and relevant monitor layouts. CI is supplied but must pass on the actual GitHub repository before claiming CI verification.

After building, run `python3 Scripts/verify-bundle.py --self-test`. It checks the assembled Apple Silicon app’s metadata, original signature/hardened runtime, exact entitlements, license and EN/TR resource/format parity against reviewed source. Its negative fixtures are disposable; it never launches or installs the app. This targeted guard is not physical verification or release approval. See [M11 readiness and release handoff](docs/M11_RELEASE_READINESS.md).

Quit Molaway before running `python3 Scripts/verify-installation.py`. It exercises the real installer in disposable folders using `MOLAWAY_INSTALL_DIR`; it does not replace your installed app or change your home directory.

For download or tap changes, run `python3 Scripts/verify-distribution.py --self-test`. It independently checks direct-download metadata in `docs/download.json` against README/installation guidance and the pinned tap against its M10 verification record; those versions may differ. Download the actual published direct app ZIP and run `python3 Scripts/verify-distribution.py --archive <downloaded-app.zip>`. For the tap's pinned release, use `--tap-archive <downloaded-tap-app.zip>`. Compare hashes with each release checksum file and GitHub asset digest. The offline guard does not establish live latest routing or signatures; verify the README's actual latest-download URL after a release is promoted. Keep its versioned asset filename and metadata current at each promotion. Follow [M10 distribution verification](docs/M10_DISTRIBUTION.md) before publishing end-user tap commands. Never point a cask at an unreleased main build or bypass Gatekeeper.

Retain the Offscreen MIT notice and document new assets/dependencies in THIRD_PARTY_NOTICES.md. Contributions are offered under the project's MIT license; contributors must have the right to contribute them. Disclose substantial AI assistance and review generated code.

Do not include personal settings, logs, screen recordings, signing certificates, keys, build caches or machine-specific files in changes. Report security issues privately as described in SECURITY.md.
