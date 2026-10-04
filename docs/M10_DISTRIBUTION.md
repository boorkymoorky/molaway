# M10 distribution verification

## Scope and status — 2026-10-04

The direct macOS download and the public Molaway-owned Homebrew tap installation lifecycle are verified within the limits below. **First launch after Apple’s per-app approval remains pending**, so the end-user Homebrew command remains withheld from the installation guide and tap README. This first-launch check is deferred at the maintainer’s request. This work publishes no app release, changes no version, and does not start M11.

GitHub's latest published non-preview release is [v2.2.5](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5), whose source tag resolves to `b6fcc3cb2bf9ff8339b9107347d2b6f36276b460`. M1–M9 are merged development work on `main`; they are not in this release. The installation guide and cask deliberately use the existing release, not an artifact built from current main. Windows PR #2 remains separate.

## Verified download

- Asset: [Molaway-2.2.5-macOS-arm64.zip](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/Molaway-2.2.5-macOS-arm64.zip), GitHub asset ID `591372855`, 1,809,628 bytes.
- Downloaded bytes SHA256: `f1430159bdc05ebf141cd6ff583412784b572a0766c90b61254cb942f8bd5882`.
- The computed hash matched the exact app ZIP entry in [SHA256SUMS.txt](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/SHA256SUMS.txt) and GitHub's `sha256:` asset digest. These are same-publisher checks, not independent authentication or malware analysis.
- The archive contains `Molaway.app` at its root. Bundle version is `2.2.5` (build `10`), identifier `local.mola.desktop`, minimum macOS `15.0`, executable architecture `arm64`, and English/Turkish resources are present.
- Extracted-bundle verification passed with `codesign --verify --deep --strict`. Signature metadata reports ad hoc signing and hardened runtime, with only App Sandbox and user-selected file read/write entitlements. The app is not Developer ID signed or notarized. No first-launch, network runtime, or physical behavior claim is made by these checks; the original downloaded app was not launched. Its later isolated Homebrew installation lifecycle is described below.

The [installation guide](INSTALL.md) keeps Gatekeeper enabled and uses Apple's per-app approval flow. A future replacement asset must be downloaded and rechecked before updating the documented URL or checksum, even if the filename is unchanged.

## Published tap

The public tap is [boorkymoorky/homebrew-molaway](https://github.com/boorkymoorky/homebrew-molaway), owned by the same maintainer as Molaway. The published cask was merged through [tap PR #1](https://github.com/boorkymoorky/homebrew-molaway/pull/1), after its native Homebrew `verify` check passed. Its merge commit is `7b095b4bfaceeb8240cbad3e3d8f7a0574165bbe`. The cask is byte-for-byte identical to [homebrew/Casks/molaway.rb](homebrew/Casks/molaway.rb), retained here for the offline distribution guard.

The tap contains the pinned cask, the root MIT license preserving both copyright notices, an English README with Molaway/Offscreen attribution, Codex assistance disclosure and signing limitations, and a pinned-checkout CI workflow. Main requires a PR, the successful `verify` check, an up-to-date branch and resolved conversations; protection also applies to administrators and disallows force pushes/deletion. There is no automatic cask version bump.

The cask pins the verified version, ZIP URL and SHA256; `app "Molaway.app"` matches the archive layout. It requires Apple Silicon and macOS 15 or later. There are no formula dependencies, installer hooks, privileged steps, security overrides, automatic updater, or `zap` deletion of preferences/statistics. Its caveat explains the unnotarized first launch and manual updates. App removal preserves user data; users can choose the app's existing summary deletion controls separately.

## Verification evidence and limits

The actual release was downloaded again during this continuation. Asset ID, size, version, URL and all three SHA256 values still agree with the verified download above. Extracted signature, arm64 executable and English/Turkish resources agree with PR #19. No app code, strings, entitlements or release assets were changed.

- Native Homebrew 7.0.7 style and full strict online cask audit passed for the public tap cask. Tap CI separately passed native style and strict cask audit. Third-party strict audit does not establish Developer ID/notarization acceptance; a separate `gktool scan` of the installed quarantined app failed with the expected distributor-signing requirement. No audit skiplist or security override was added.
- A disposable Homebrew checkout used its own prefix, Caskroom, tap checkout, cache, logs and temporary directories. `HOMEBREW_CASK_OPTS` redirected the app artifact to a disposable destination. This is a nonstandard-prefix Homebrew configuration (Tier 3), not proof of every default-prefix/OS combination. The personal Homebrew installation and personal Molaway app/data were not targets of the test.
- With no pre-existing Molaway tap or Molaway download in that environment, the exact public reference in `brew install --cask boorkymoorky/molaway/molaway` automatically tapped the public repository, fetched the versioned ZIP, enforced its pinned checksum and installed `Molaway.app` successfully in the disposable destination. The public tap’s default main branch supplied the cask; no local-file cask or branch URL was substituted. The installed app’s original signature passed `codesign --verify --deep --strict`.
- Native `fetch`, `reinstall` and `uninstall` succeeded using the same fully qualified cask reference. Reinstallation kept quarantine present and passed signature verification. `upgrade` correctly reported that 2.2.5 was already current. This is a current-version no-op and a same-version replacement check, **not a cross-version upgrade verification**; no later release exists to test.
- Uninstall removed only the disposable app and its cask metadata. Synthetic settings and summary fixtures outside the app remained byte-identical. The cask still has no `zap` or hooks. This is installer/static evidence, not an app-runtime settings migration check.
- Native requirement evaluation accepted Apple Silicon/macOS 15 and rejected Intel/macOS 14 in bounded simulated checks. Physical Intel and oldest-supported-OS installation remain unverified.
- Gatekeeper stayed enabled; the installed bundle retained normal Homebrew quarantine. The original app was never launched, re-signed, adopted or installed over the personal app. No quarantine was removed. An existing-app conflict was tested separately with a synthetic destination: installation refused replacement, preserved the fixture and cleaned failed-install metadata without `force` or `adopt`.

These are distribution checks. Windows PR #2 and its local unfinished work remain separate. M6’s structured physical checklist remains deferred, and M1–M9 remain absent from the published 2.2.5 download.

## Remaining gate before publishing end-user tap instructions

Only the original released app’s first launch after normal Gatekeeper approval remains pending for this tap. A separate macOS user or Mac is required to keep the personal app, login item, settings and summaries isolated: the original bundle identifier is `local.mola.desktop`, so opening another copy in the personal session can use the same sandbox data.

In that separate environment, repeat the public tap installation with quarantine enabled, observe the initial warning, and use **System Settings → Privacy & Security → Open Anyway** following [Apple’s instructions](https://support.apple.com/en-us/102445). Stop on malware, damaged-app or organization-policy warnings. Confirm that the original 2.2.5 app launches, without re-signing, disabling Gatekeeper, removing quarantine or adding permissions. Record only non-private outcome evidence. This is a first-launch distribution check, not a restart of M6 verification.

After that check passes, publish the tested fully qualified command in the tap README and [installation guide](INSTALL.md), with manual update/removal instructions and the signing limitations. Future cask changes must repeat the live asset/digest checks and relevant isolated lifecycle checks through protected PRs. Homebrew’s external downloads do not add network access to Molaway. No new app release or M11 work is authorized by this continuation.

## Repeatable repository checks

```sh
python3 Scripts/verify-distribution.py
python3 Scripts/verify-distribution.py --archive <downloaded-app.zip>
```

The first command is an offline CI guard that compares the cask with the README and installation guide. The second checks a previously downloaded ZIP's bytes and bounded bundle metadata without extracting, launching or installing it. Neither contacts the network, checks signatures, proves live availability or verifies Homebrew installation/first launch. Maintainers must separately compare GitHub's live asset metadata and checksum file, inspect the extracted signature/architecture, and repeat the relevant lifecycle checks and complete the first-launch gate above.
