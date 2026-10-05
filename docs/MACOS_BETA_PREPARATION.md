# macOS 3.0.0-beta.1 preparation — not published

Current decision: on 2026-10-05 the owner explicitly authorized regular **3.0.0 / build 11** publication instead of a beta. See [the current release authorization](MACOS_3_RELEASE.md). The beta proposal, hold decision and verification below are historical; their publishing-status instructions are superseded. The unchanged physical and migration limits still apply. No beta is published.

## Owner decision and scope — 2026-10-04

The owner explicitly approved **3.0.0-beta.1 / build 11, beta preparation only**, acknowledging the physical verification gaps and migration/downgrade risks in the [PR #22 decision and notes](MACOS_RELEASE_DECISION.md). This is an opt-in beta proposal, **not a stable release or release candidate**. Publication remains on hold; no release date is assigned.

Candidate bundle metadata is `CFBundleShortVersionString = 3.0.0`, `CFBundleVersion = 11`, with unchanged identity `local.mola.desktop`, Apple Silicon architecture and macOS 15 minimum. Settings continues to display the numeric bundle version. No EN/TR string is changed; the beta status must remain explicit in candidate filenames, documentation and any future separately authorized release title/download label.

The candidate changes version metadata and preparation documents. Review also hardens the existing source installer and isolated verification script: an unavailable process list now stops installation instead of being treated as no running Molaway. App behavior, settings/statistics, localization, permissions, attribution and Windows work are preserved. The app stays local-first, account-free, telemetry-free and manually updated; no networking, broader permission, dependency or helper is added. The personal app is not stopped, launched or installed over as a test target.

## Refreshed baseline

- [PR #22](https://github.com/boorkymoorky/molaway/pull/22) is merged at `93639ffd394184bd8a6ae87728b0c2824cc51624`, the preparation starting point. Its final head `921038c` passed [Verify 37228772097](https://github.com/boorkymoorky/molaway/actions/runs/37228772097); merged main passed [Verify 37229000959](https://github.com/boorkymoorky/molaway/actions/runs/37229000959). Every guard, test, build, bundle self-test and isolated installation step succeeded. These runs predate the candidate metadata.
- Authenticated GitHub reads found only v2.2.2–v2.2.5 releases/tags, with no draft or prerelease and no conflicting 3.0.0 tag. The latest non-preview release remains [v2.2.5](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5). Build 11 follows the published build 10.
- Main still requires a PR, an up-to-date successful `verify` check and resolved conversations, including for administrators. [Windows PR #2](https://github.com/boorkymoorky/molaway/pull/2) and unfinished local Windows edits remain separate.
- README, installation instructions, screenshots and the Homebrew cask remain scoped to the published 2.2.5 app. No beta download link or end-user tap command is added.

## Candidate verification

| Check | Candidate evidence | Limit |
| --- | --- | --- |
| Swift regression suite | **202 tests in 20 suites passed** on the 3.0.0/build 11 source. | Synthetic/component coverage; no new physical app session. |
| Source/publication/distribution | All three guards passed; 126 curated files reviewed by the publication guard. Live tap main matches the pinned 2.2.5 cask byte-for-byte. | Targeted patterns and 2.2.5 consistency, not a security audit or beta live-asset check. |
| Release build and bundle | arm64 release build and original deep/strict ad hoc hardened-runtime signature passed. Metadata matches 3.0.0/build 11; identity/macOS 15 target, MIT license, exact existing sandbox/file entitlements and **372** unchanged EN/TR keys/placeholders passed. Eight negative bundle fixtures were rejected. | No Developer ID/notarization, app launch or physical first-launch evidence. |
| Scope and documents | Metadata-only plist comparison, unchanged app source/tests/EN/TR/entitlements/build scripts/workflows/README/installation guide/cask; installer process-query failures stop before staging, relative document links and diff checks passed. | Windows work and personal data are outside the candidate tree. |
| Local installation | Stopped at the unchanged running-Molaway guard; the personal app was left running. | **No local installation pass.** Hosted isolated installation/update/failure evidence must come from this candidate PR. |
| Protected PR CI | [PR #23](https://github.com/boorkymoorky/molaway/pull/23) initial head `f103e3d` passed [Verify 37229876245](https://github.com/boorkymoorky/molaway/actions/runs/37229876245), including hosted isolated installation. The reviewed revision requires its own successful final-head check before merge. | Prior PR #22/M11 runs do not substitute for the candidate check; CI is not physical verification. |

A passing source guard is not an independent security audit; a signed build is not publishing approval. Final local archive digests and inspection evidence are supplied in the candidate PR/handoff, outside the tracked source.

Run the [M11 full sequence](M11_RELEASE_READINESS.md#repeatable-checks) against this candidate: Swift tests, source security guard, tracked publication guard, pinned 2.2.5 distribution guard, release build, bundle/signature/EN/TR self-tests and isolated installation verification. Retain the running-app refusal; never stop the personal app or bypass that guard for a local pass. Protected PR CI must pass for the final revision.

## Candidate review — 2026-10-05

Live Git/PR/CI/release/tag/protection reads reconfirmed the preparation baseline, successful initial candidate CI, no beta tag/release/draft and 2.2.5 as the latest non-preview release. The live tap cask must remain byte-identical to the pinned 2.2.5 copy. Windows PR #2 and local unfinished edits remain separate.

Review reproduced an installer false pass when the process query failed: `pgrep` returned an error rather than the documented no-match status. Both installation scripts now accept only status 1 as no running app; status 0 retains the running-app refusal and all other statuses stop before creating or replacing an installation. The restricted-environment pass is not accepted as installation evidence. A normal process query confirms the personal app is running, so local installation remains refused. Hosted final-head CI supplies disposable installation evidence; this does not close M10 or restart M6.

Revalidate and rebuild local app/source archives from the reviewed final revision. Initial `f103e3d` archives are historical packaging evidence, not the final source package after this installer correction. Final digests and CI links belong in the PR/handoff, outside tracked source.

## Local package handoff

After candidate verification, prepare local-only `Molaway-3.0.0-beta.1-macOS-arm64.zip`, `Molaway-3.0.0-beta.1-Source.zip` and `SHA256SUMS.txt` from the final candidate revision. Source packaging must use the tracked revision, not the working directory or private Windows branch. Keep generated archives outside the publication tree. Inspect archive paths/contents, private-data exclusions, metadata, original signature, architecture, license and EN/TR resources after extraction. Compute both hashes and compare them again before any later upload. Local archives are not published assets; no live beta asset/digest or original first-launch evidence exists.

## Open gates and beta disclosure

- M6 structured physical checks remain deferred under the accepted daily-use feedback policy. Complete-app countdown/cadence, native notification actions, keyboard/VoiceOver, displays/Spaces, real sleep/lock, positive M8 signal transitions and real multi-day Screen Score/energy use retain their documented gaps. No new physical session is initiated and no stable/RC readiness is claimed.
- **M10 original quarantined first launch after Apple's per-app approval remains pending.** The user-facing tap command stays withheld; beta preparation does not close that independent gate. Keep Gatekeeper enabled; no quarantine removal, re-signing or security bypass is permitted by this handoff.
- Legacy timing migration is approximate: eye interval/rest becomes work/short timing and movement rest becomes long rest; the old movement interval has no exact cycle equivalent. Review the migrated schedule. Old eye/movement summaries retain historical meaning.
- Published 2.2.5 rejects schema 3 settings and can fall back to defaults. Before a future opt-in beta, export 2.2.5 settings and keep them private. Beta exports are not 2.2.5 rollback files; exports omit summaries and live pause/cadence. Older summary writers may drop Screen Score totals. Replacing an app ZIP is not a complete or lossless rollback.
- No app launch is authorized in the personal session: another original-identity copy can share its sandbox settings and summaries. Any later original first-launch check needs a separate macOS user or Mac.
- Distribution remains Apple Silicon, ad hoc signed and unnotarized. Intel, oldest supported macOS and all player/display configurations remain unverified. Windows remains a separate development preview.

## Separate decision required before publication

Review the final candidate PR and its successful checks first. This preparation authorizes **no tag, GitHub draft/published release or asset upload**. A later publishing instruction must recheck main/CI/version/tag state and use prerelease enabled, latest disabled, leaving 2.2.5 as the default non-preview download. After any authorized publication, download the actual beta app ZIP, compare its bytes with both `SHA256SUMS.txt` and GitHub's asset digest, and inspect its original signature/architecture. A tap change requires separate protected work and must not silently move the non-preview cask to beta. The [English release-notes draft](MACOS_RELEASE_DECISION.md#proposed-release-notes--not-published) remains available for that later review.
