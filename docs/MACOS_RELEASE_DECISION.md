# Post-M11 macOS release decision and notes draft

## Recommendation — 2026-10-04

**Keep publication on hold now. Target `3.0.0-beta.1` (build `11`) for a separately approved, opt-in macOS prerelease; do not call it stable or a release candidate.** This is a repository document for review, not a GitHub draft release, version assignment or publishing authorization. No release date is proposed.

The major version communicates the change from independent eye/movement timers to one work/short/long cycle, different ring meanings and a settings-schema migration. A 2.2.x patch would obscure that change. Beta status communicates that complete-app physical behavior is still incompletely verified; passing automated checks does not justify a stable or RC label. The currently published non-preview release remains **2.2.5**.

| Decision | Proposal | Effect |
| --- | --- | --- |
| Current action (recommended) | Approve this decision/notes document only; keep publishing on hold. | No version metadata, tag, release, archive upload, tap or user download changes. |
| Later opt-in beta | Explicitly approve `3.0.0-beta.1`, build `11`, with the gaps below acknowledged. | A separate preparation PR must verify the exact candidate before any publishing decision. Future GitHub release settings: prerelease enabled, latest disabled. Keep 2.2.5 as the default non-preview download and the tap pinned to it. |
| Stable release | Defer `3.0.0` and stable claims. | Requires a later evidence/acceptance decision covering unresolved physical risks; this draft neither restarts M6 nor waives its checks. |

The proposed future tag is `v3.0.0-beta.1`. Proposed bundle fields are `CFBundleShortVersionString = 3.0.0` and `CFBundleVersion = 11`, with identity `local.mola.desktop` retained. The numeric Settings version alone would not identify beta status; the beta release title, notes and download label must identify the prerelease explicitly. These fields remain **2.2.5/build 10** in this PR. Recheck version/build availability before preparing a candidate; later betas need distinct tags and increasing builds. Never replace the existing 2.2.5 asset with development bytes.

## Verified baseline

This is a snapshot, not an evergreen release dashboard. Live authenticated GitHub reads and a refreshed `origin/main` agreed on the following state during this review:

| Item | Observed state |
| --- | --- |
| Reviewed development source | `main` at `39e7d8dbf5089fe04632d5f29aca57e864e1a834`, the merge of [PR #21](https://github.com/boorkymoorky/molaway/pull/21). |
| Final PR #21 head | `fbda4c203ffee047e42c76726da43a336e0d7af9`; [Verify run 37226345150](https://github.com/boorkymoorky/molaway/actions/runs/37226345150) succeeded. |
| Merge verification | [Main Verify run 37226551952](https://github.com/boorkymoorky/molaway/actions/runs/37226551952) succeeded for `39e7d8d`. Both final runs passed source/publication/distribution guards, tests, build, bundle self-tests and isolated installation/update/failure checks. |
| M11 coverage | 202 Swift tests in 20 suites; bundle guard covers 372 EN/TR keys and format placeholders, original signature/entitlements and eight negative fixtures. See [M11 evidence and limits](M11_RELEASE_READINESS.md). |
| Publication | Latest non-preview release [v2.2.5](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5); no draft or prerelease returned by the release list. Remote tags are v2.2.2–v2.2.5; no 3.0.0 tag exists. |
| Existing download | GitHub metadata still reports app ZIP asset `591372855`, 1,809,628 bytes, SHA256 `f1430159bdc05ebf141cd6ff583412784b572a0766c90b61254cb942f8bd5882`. This review rechecks metadata, not a new download/signature/first-launch session; byte-level evidence remains in [M10](M10_DISTRIBUTION.md). |
| Protected workflow | Main requires a PR, an up-to-date successful `verify` check and resolved conversations; protection includes administrators. This documentation PR needs its own successful check. |
| Separate Windows work | [Windows PR #2](https://github.com/boorkymoorky/molaway/pull/2) remains open. It is outside this macOS proposal; local unfinished Windows work is preserved. |

The PR #21 and main passes concern unchanged development metadata, not a built `3.0.0-beta.1` candidate. A future version change requires another full verification of the final revision. The personal app is not stopped, launched, installed over or used as a test target by this review.

## Open physical evidence and release consequences

| Gap | What the evidence establishes | Decision consequence |
| --- | --- | --- |
| Complete-app countdown/cadence, pause/relaunch, displays/Spaces, real sleep/lock | Partial historical observations and synthetic regressions; [M6 readiness](M6_READINESS.md) retains the unverified cases and earlier unexplained cadence observation. | Beta must disclose these limits; stable confidence is not established. Do not restart the structured M6 checks; continue the accepted daily-use feedback policy. |
| Native notification delivery/actions; keyboard, Escape/close and VoiceOver across alert surfaces | Permission approval and component checks do not establish real delivery/action timing or full navigation. | No complete notification/accessibility verification claim. Reproduce reported failures in focused PRs. |
| Turkish countdown speech and manual VoiceOver access to the badge | English single-announcement observation only; other speech/navigation cases remain unverified. | Preserve the accepted once-per-countdown announcement policy and existing EN/TR strings; do not claim bilingual VoiceOver verification. |
| Positive audio-input/native fullscreen/selected-app transitions | Public-query availability and limited UI observations, not broad physical coverage; [M8 limits](M8_QUIET_SIGNALS.md) apply. | Optional signals remain off by default. No meeting guarantee, automatic sharing or microphone-only classification claim. |
| Real multi-day Screen Score and summary use; sustained energy impact | Automated scoring/storage tests and limited layout evidence, not longitudinal or battery testing. | Explain score semantics and limits; no productivity, health or energy-efficiency guarantee. |
| Original quarantined Homebrew app first launch after Apple's per-app approval | Isolated install/reinstall/removal passed; original first launch did not. No separate user/Mac is available for this review. | **M10 remains pending.** Keep the end-user tap command withheld. A future beta decision cannot close this independent gate or advance the tap. |
| Intel, oldest supported macOS, all display/player combinations | Unverified. Build deployment target is not physical compatibility evidence. | Apple Silicon-only proposal, macOS 15 minimum, with older-OS/player/display limits explicit. |

No new physical-check session is initiated here. Document only evidence actually obtained. A later stable decision must resolve or explicitly scope physical limitations with truthful support claims; this draft grants no such acceptance.

## Migration and downgrade limits

- Retaining `local.mola.desktop` retains the data location, **not a promise of lossless downgrade**. Two app copies in the same user session can share settings and summaries. Do not run a beta over the personal app as a test; isolated original first launch needs a separate macOS user or Mac.
- Legacy eye interval becomes work interval; eye rest becomes short rest; movement rest becomes long rest. Short-break cadence approximates the old movement interval, which has no exact equivalent. Review the migration notice and schedule before relying on reminders. Old eye/movement totals retain their historical meaning.
- Development settings use schema 3. Published 2.2.5 accepts only schemas 1–2; loading newer settings can fall back to defaults. A settings export made by 2.2.5 before opting into a future beta can preserve the old configurable preferences, but a beta export is not a 2.2.5 rollback file. No automatic pre-upgrade backup or downgrade migration is promised.
- Settings exports omit summaries, live cadence and manual pause state and cannot enable recording or grant permission. They are not a full data backup. Older builds may discard Screen Score fields when writing summaries; scores cannot be reconstructed after that loss. Do not describe replacing the app ZIP as a complete rollback.
- Summary recording and new opt-in signals are not enabled by migration. Existing opt-in consent remains in effect. Relaunch starts a fresh work session; Screen Score does not reconstruct historical or unresolved opportunities.

## Future candidate gates (not executed by this draft)

1. Obtain the owner's version/status decision and review the physical-gap disclosure. Prepare only the approved candidate on a focused branch, retaining identity, permissions, attribution and EN/TR text. No app networking, updater, new dependency, broad permission or privileged helper is authorized.
2. Run the [M11 full check sequence](M11_RELEASE_READINESS.md#repeatable-checks) on the exact candidate revision and pass protected PR CI. Local installation checks must retain the running-app refusal; hosted isolated checks can provide installation evidence without stopping the personal app. Neither establishes original Gatekeeper first launch.
3. After the candidate is reviewed, prepare versioned app/source archives and `SHA256SUMS.txt`; inspect contents, signature, architecture, metadata, license, localization and private-data exclusions. Proposed names are `Molaway-3.0.0-beta.1-macOS-arm64.zip` and `Molaway-3.0.0-beta.1-Source.zip`. They do not exist as approved/uploaded assets; no candidate checksum is available yet.
4. Obtain a separate explicit publishing instruction before creating the tag or GitHub draft/published release or uploading assets. A merged documentation or candidate PR does not authorize publication. Recheck main/CI/tag/version state immediately beforehand.
5. If a beta is later published, label it prerelease and do not make it latest. Download the actual uploaded ZIP, compare its computed hash with `SHA256SUMS.txt` and GitHub's digest, and inspect the extracted original signature/architecture. Keep the default README/install guide and tap scoped to 2.2.5; any beta download guidance must be clearly separate and disclose migration risks. Screenshots must use synthetic data.
6. Tap changes require a separate protected PR after live asset verification and appropriate isolated lifecycle checks. Keep the independent M10 original first-launch gate pending and end-user tap instructions withheld until separate-environment evidence actually closes it. Do not quietly move the non-preview tap to beta.

## Proposed release notes — not published

The following English text is a draft for a future separately approved prerelease. The proposed version/build has not been assigned, built or packaged yet.

### Molaway 3.0.0-beta.1 — macOS preview

An opt-in preview of Molaway's new work/short/long break cycle. **2.2.5 remains the default non-preview download.** This beta is not a stable release or release candidate. Complete-app notification, accessibility, display/lifecycle and multi-day behavior still have unverified cases.

Changes prepared on main:

- One work/short/long cycle replaces independent eye and movement timers. The outer ring shows work/rest progress; the inner ring shows completed short breaks toward a long break. Deep Focus offers a reversible timing preset.
- Shared pause choices and optional Office Hours support overnight schedules and independent pause reasons. Casual, Balanced and Hardcore define Skip behavior across reminders.
- An optional pointer countdown provides one localized announcement per visible countdown. Smart Pause shares existing activity/quiet signals, with optional typing deferral capped at 30 seconds.
- Off-by-default audio-input, active native fullscreen and selected-foreground-app options quiet alerts within the documented public-API limits. Automatic screen sharing, microphone-only classification and broader fullscreen detection remain deferred.
- Optional local summaries gain Screen Score: completed divided by resolved full-cycle opportunities, shown after at least three outcomes. Snoozes and unresolved/early breaks do not create failures or extra points; earlier days have no invented scores.
- Integrated lifecycle/migration regressions and offline bundle/signature/permission/EN/TR guards extend automated coverage. Final versioned-candidate results must be added before publication; existing M11 checks cover development source only.

Before trying a future beta, export settings from 2.2.5 and keep that file private. Review the migrated schedule: the former movement interval is approximated. A beta settings file cannot be read by 2.2.5, and older app versions may discard new score fields. Settings export excludes summaries and is not a full rollback backup.

Apple Silicon only; macOS 15 minimum, with the oldest supported OS and Intel unverified. The download is intended to remain ad hoc signed and unnotarized. Keep Gatekeeper enabled and use only Apple's per-app approval flow; original quarantined first launch remains unverified. Homebrew continues to target 2.2.5 and its end-user command remains withheld pending the separate first-launch check.

Molaway remains local-first, account-free, telemetry-free and manually updated, with no app network access or broader permissions. Screen Score is not a health or productivity measurement. This is a personal MIT-licensed derivative of Offscreen by Dayo Akinkuowo, maintained by Burak Yelkenci with ChatGPT/Codex assistance. Windows remains a separate development preview with no release or stable claim from this macOS work.
