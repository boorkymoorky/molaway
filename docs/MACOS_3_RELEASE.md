# macOS 3.0.0 / build 11 release authorization

## Owner decision — 2026-10-05

The owner explicitly instructed publication as a regular **3.0.0 / build 11** release instead of the prepared beta. This supersedes the earlier beta-only/hold decision. It authorizes tag `v3.0.0`, a GitHub release with prerelease disabled, and the reviewed app/source ZIPs plus `SHA256SUMS.txt`. Preserve **2.2.5 as the default download and tap version**, with latest disabled for 3.0.0. No beta tag or release is created.

This is the authorization/preparation record; publication and downloaded-asset verification follow successful final protected PR and merged-main CI. The original bundle already has numeric version 3.0.0 and build 11. No beta has been published, so no build number is reused across published releases. App identity, code, settings/statistics, EN/TR strings, entitlements and attribution stay unchanged. Windows PR #2/local unfinished work and the personal app/data remain separate.

[PR #23](https://github.com/boorkymoorky/molaway/pull/23) merged at `53e25d670344a151edc72358583c8a6e4fe82f3e`; its [final candidate CI](https://github.com/boorkymoorky/molaway/actions/runs/37269808509) and [merged-main CI](https://github.com/boorkymoorky/molaway/actions/runs/37270063505) passed every step. The new publication revision needs its own checks and tracked source archive. Historical beta preparation is retained in [MACOS_BETA_PREPARATION.md](MACOS_BETA_PREPARATION.md); its beta filenames/digests must not be substituted for the new source archive.

The regular release designation is the owner's distribution decision, not a claim that the missing physical checks have passed. M6 structured checks remain deferred, M10 original quarantined first launch remains pending, and the end-user tap command stays withheld. No application launch over the personal session, Gatekeeper bypass, network capability or broader permission is authorized.

## Publication sequence

1. Pass the M11 full check sequence on the final release revision, retaining the local running-app refusal. Hosted isolated CI supplies installer evidence without stopping the personal app. Merge only through protected PR checks, then verify merged main.
2. Package `Molaway-3.0.0-macOS-arm64.zip` and `Molaway-3.0.0-Source.zip` from that reviewed revision, with a new `SHA256SUMS.txt`. Check tracked-source equality, app bytes, paths/private-data exclusions, metadata, architecture, original signature, MIT license and unchanged EN/TR resources. Keep outputs outside the tracked source.
3. Recheck tag/release availability and main/CI; create `v3.0.0` at the verified release commit. Stage only the three approved assets, then publish a regular GitHub release with latest disabled. No tap update is included.
4. Download the actual uploaded app/source ZIPs and checksum file. Match both hashes with the local files, checksum entries and GitHub asset digests. Inspect the extracted original signature, architecture, metadata and resources without launching or re-signing the app.
5. Record live evidence and add separate 3.0.0 guidance through a protected documentation PR. Keep the default README/install download and tap on 2.2.5. Do not advance physical or Windows claims.

## Approved English release notes

Molaway 3.0.0 introduces a work/short/long break cycle on macOS. This is a regular release, not a beta or release candidate. **2.2.5 remains the repository's default download and Homebrew version by the maintainer's decision.** Choose 3.0.0 explicitly if you want the new cycle.

### What's changed

- One work/short/long cycle replaces independent eye and movement timers. The outer ring shows work/rest progress; the inner ring shows completed short breaks toward a long break. Deep Focus offers a reversible timing preset.
- Shared pause choices and optional Office Hours support overnight schedules and independent pause reasons. Casual, Balanced and Hardcore define Skip behavior across reminders.
- An optional pointer countdown announces once per visible countdown. Smart Pause includes optional typing deferral capped at 30 seconds.
- Optional audio-input, active native fullscreen and explicitly selected foreground-app signals quiet alerts within documented public-API limits. These options default off; automatic sharing and broader detection remain deferred.
- Optional local summaries gain Screen Score: completed divided by resolved full-cycle opportunities, shown after at least three outcomes. Snoozes and unresolved or early breaks do not create failures or extra points; historical days have no invented scores.
- The source installer stops if it cannot determine whether Molaway is running, preserving its running-app protection.

### Before upgrading from 2.2.5

Quit Molaway before replacing the app, and keep only one installed copy. Export your 2.2.5 settings first and keep the file private. Review the migrated schedule: eye interval/rest becomes work/short timing, movement rest becomes long rest, and the old movement interval is approximated by short-break cadence.

3.0.0 settings use schema 3, which 2.2.5 cannot read and may replace with defaults. A 3.0.0 settings export is not a 2.2.5 rollback file. Settings export excludes summaries and live pause/cadence; older summary writers can discard Screen Score fields. Replacing the app alone is not a complete or lossless rollback. Old eye/movement totals keep their historical meaning. Migration does not turn on summary recording or the new optional signals.

### Verification and limits

202 tests in 20 suites passed, together with source/publication/distribution guards, release build, original signature, exact existing entitlements and 372 matching English/Turkish resource keys. Eight negative bundle fixtures were rejected. Required protected PR CI includes isolated installation/update/failure checks. These automated checks do not establish every real-world app/device combination or constitute an independent security audit.

Complete-app notification/actions, keyboard/VoiceOver flows, display/Space/lifecycle combinations, real sleep/lock, positive optional-signal transitions, multi-day Screen Score use and sustained energy impact retain unverified cases. M6 structured checks remain deferred under the accepted daily-use feedback policy. The original Homebrew app's first launch after normal Gatekeeper approval remains pending; end-user tap instructions remain withheld. A regular release does not turn these unperformed checks into verified results.

Apple Silicon only; macOS 15 minimum. Intel and the oldest supported OS remain unverified. The app is ad hoc signed and unnotarized. Keep Gatekeeper enabled and follow [Apple's per-app approval instructions](https://support.apple.com/en-us/102445); do not remove quarantine or disable protection.

### Downloads and privacy

Download `Molaway-3.0.0-macOS-arm64.zip` for the app; `Molaway-3.0.0-Source.zip` is the reviewed source. Compare the app ZIP's SHA256 with `SHA256SUMS.txt` before extracting. Matching hashes detect changed bytes; they do not independently authenticate the publisher or prove absence of malware.

Molaway stays local-first, account-free, telemetry-free and manually updated, with no app network access or broader permissions. Screen Score is not a health or productivity measurement. Windows remains a separate development preview with no installer or stable Windows release from this work.

A personal MIT-licensed derivative of [Offscreen by Dayo Akinkuowo](https://github.com/dayaki/offscreen), maintained by Burak Yelkenci with ChatGPT/Codex assistance. The original copyright and MIT notices are retained.
