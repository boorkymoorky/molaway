# Molaway 3.0.2 release record

## Owner authorization — 2026-10-05

The owner explicitly requested publication of the proposed **3.0.2 / build 13** follow-up to 3.0.1. Prepare a regular release from protected main, tag `v3.0.2`, and the Apple Silicon app/source ZIPs plus `SHA256SUMS.txt`. After actual public-download verification, update README/install metadata through a protected PR and make 3.0.2 the latest direct download. Keep existing releases immutable. This request does not include installation on the personal Mac; its application and data are not test targets.

## Change and verification scope

[PR #31](https://github.com/boorkymoorky/molaway/pull/31) makes a manually started short or long break count from its actual start. Previously a break started between countdown polls included pre-break time in its first decrement and could finish early; a break started before the first poll lost its first elapsed interval. Two deterministic regressions failed before the fix and passed after it. The existing countdown-second alignment, timer, elapsed-time bounds and sensor gate remain unchanged.

The follow-up passed **213 tests in 21 suites**, protected PR CI and merged-main CI. Synthetic model tests cover fractional short/long start offsets, the first countdown decrement, completion no earlier than the configured duration and the cadence result, along with the existing pause/idle/sleep/snooze/stall cases. They do not establish physical full-app appearance, lifecycle behavior or sustained CPU/battery use. Actual application stalls can still skip intermediate displayed seconds; samples longer than five seconds retain the existing rule excluding that interval from work/rest elapsed time.

The release preparation must separately pass source/publication/distribution guards, tests, release build and original signature/entitlement/localization checks. Isolated installer checks must pass in a clean environment; a running personal Molaway is never quit or bypassed to make a local check pass.

## Publication sequence

1. Merge version/build preparation through protected main after required checks pass, then verify merged-main CI.
2. Package only the reviewed app and all tracked tag-source files, excluding build caches and private state. Check archive paths, exact source/file bytes, metadata, architecture, original signature, license and unchanged EN/TR resources. Generate checksums.
3. Create `v3.0.2` at the verified main revision. Upload only the app/source ZIPs and checksum file to a draft; verify GitHub digests before publishing a regular release. Keep latest on 3.0.1 until direct-download documentation is ready.
4. Download all actual public assets; compare bytes and hashes against the reviewed packages and GitHub digests. Inspect the extracted original signature without re-signing. Update direct-download metadata and evidence through a protected PR, promote 3.0.2 to latest and verify the live README download route.

## Upgrade and remaining limits

3.0.2 uses the same cycle and settings schema as 3.0.1/3.0.0. It does not change preferences, statistics formats or localization text. The [3.0.0 migration/downgrade limits](MACOS_3_RELEASE.md) continue to apply to 2.2.5; app replacement alone is not a full rollback. Updates remain manual and offline within the app.

Apple Silicon, macOS 15 minimum, ad hoc signed and unnotarized. Keep Gatekeeper enabled and use Apple's per-app approval flow when needed. Intel, oldest supported macOS, complete notification/accessibility/display/lifecycle combinations, optional-signal transitions and sustained energy use retain their unverified limits. Regular publication does not establish physical readiness.

M6 structured checks stay deferred under daily-use feedback. M10 original quarantined first launch stays pending; the Homebrew tap remains 2.2.5 and end-user commands remain withheld. No Windows change, new dependency, broader permission or app network capability is added. Offscreen copyright/MIT attribution and the AI-assistance disclosure are retained.
