# M10 distribution preparation

## Scope and status — 2026-10-04

The direct macOS download is verified. A Molaway-owned Homebrew tap is **prepared, not published or verified for end-user installation**. This work publishes no app release, changes no version, and does not start M11.

GitHub's latest published non-preview release is [v2.2.5](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5), whose source tag resolves to `b6fcc3cb2bf9ff8339b9107347d2b6f36276b460`. M1–M9 are merged development work on `main`; they are not in this release. The installation guide and cask deliberately use the existing release, not an artifact built from current main. Windows PR #2 remains separate.

## Verified download

- Asset: [Molaway-2.2.5-macOS-arm64.zip](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/Molaway-2.2.5-macOS-arm64.zip), GitHub asset ID `591372855`, 1,809,628 bytes.
- Downloaded bytes SHA256: `f1430159bdc05ebf141cd6ff583412784b572a0766c90b61254cb942f8bd5882`.
- The computed hash matched the exact app ZIP entry in [SHA256SUMS.txt](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/SHA256SUMS.txt) and GitHub's `sha256:` asset digest. These are same-publisher checks, not independent authentication or malware analysis.
- The archive contains `Molaway.app` at its root. Bundle version is `2.2.5` (build `10`), identifier `local.mola.desktop`, minimum macOS `15.0`, executable architecture `arm64`, and English/Turkish resources are present.
- Extracted-bundle verification passed with `codesign --verify --deep --strict`. Signature metadata reports ad hoc signing and hardened runtime, with only App Sandbox and user-selected file read/write entitlements. The app is not Developer ID signed or notarized. No first-launch, network runtime, or physical behavior claim is made by these checks; the downloaded app was not launched or installed.

The [installation guide](INSTALL.md) keeps Gatekeeper enabled and uses Apple's per-app approval flow. A future replacement asset must be downloaded and rechecked before updating the documented URL or checksum, even if the filename is unchanged.

## Tap candidate

The candidate is [homebrew/Casks/molaway.rb](homebrew/Casks/molaway.rb). The intended separate repository is `boorkymoorky/homebrew-molaway`, owned by the same maintainer as Molaway. That public tap was not available during this check. This candidate does not establish a live tap, and no user-facing Homebrew install command is provided.

The cask pins the verified version, ZIP URL and SHA256; `app "Molaway.app"` matches the archive layout. It requires Apple Silicon and macOS 15 or later. There are no formula dependencies, installer hooks, privileged steps, security overrides, automatic updater, or `zap` deletion of preferences/statistics. Its caveat explains the unnotarized first launch and manual updates. App removal preserves user data; users can choose the app's existing summary deletion controls separately.

The candidate was loaded through Homebrew's native cask DSL. Version, interpolated URL, SHA256, architecture and minimum OS agreed with the real asset. Selected offline Homebrew source audits passed for required stanzas, uninstall requirements, description, version characters, checksum form, URL format and generic artifacts. A full tap audit, online audit, Homebrew fetch/install/update/uninstall and Homebrew-triggered first launch have **not** been verified. This is preparation only, not an official `homebrew/cask` submission or Homebrew endorsement.

## Remaining gate before publishing a tap command

1. Create the maintainer-owned public tap repository, with `Casks/molaway.rb`, the root MIT license, a short English README retaining Molaway/Offscreen attribution and signing limitations, and PR/check protection. Review the exact public contents; never copy local settings, logs or build caches.
2. Recheck the current published release and download. Keep the candidate on 2.2.5 unless a later release has actually been published and its real asset independently downloaded and compared with both published digests. A main merge alone is not a release.
3. Run native Homebrew style and full cask audits in the tap, with documented exceptions if an audit assumes Developer ID/notarization. Do not work around signing checks by disabling Gatekeeper or removing quarantine.
4. From a fresh disposable Homebrew environment, verify the exact public tap reference resolves, fetches the intended ZIP and enforces its checksum. Exercise install, replacement/update and uninstall against a disposable app destination with synthetic local data; ensure the personal Molaway installation, login item, settings and summaries are untouched. Never use force/adopt flags to take over an existing app.
5. Verify first launch under normal quarantine through Apple's per-app approval flow, keeping signing and physical verification limits explicit. Confirm architecture/OS restrictions and that removing the cask leaves local data intact. These are distribution checks; M6's structured physical checklist stays deferred in favor of daily-use feedback.
6. Only after the exact public installation command has passed those checks, publish it in the tap README and Molaway installation guide. Homebrew's GitHub/package downloads are external tooling; the Molaway app must remain offline with manual updates and unchanged permissions.

Tap publication and these remaining checks require separate follow-up scope. They do not authorize a new app release, M11, or broader permissions.

## Repeatable repository checks

```sh
python3 Scripts/verify-distribution.py
python3 Scripts/verify-distribution.py --archive <downloaded-app.zip>
```

The first command is an offline CI guard that compares the cask with the README and installation guide. The second checks a previously downloaded ZIP's bytes and bounded bundle metadata without extracting, launching or installing it. Neither contacts the network, checks signatures, proves live availability or verifies a working Homebrew tap. Maintainers must separately compare GitHub's live asset metadata and checksum file, inspect the extracted signature/architecture, and complete the tap gate above.
