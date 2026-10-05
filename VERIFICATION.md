# Verification

## 3.0.2 regular release — 2026-10-05

- [PR #32](https://github.com/boorkymoorky/molaway/pull/32) and [merged-main Verify](https://github.com/boorkymoorky/molaway/actions/runs/37307859769) passed all steps for tag source `3d6e984a4b613cf36494a711cb978de4fc0c7351`: 213 tests in 21 suites, source/publication/distribution guards, release build, original signature/entitlements, 372 unchanged EN/TR keys, eight rejected bundle fixtures and clean-environment isolated installer checks. Local tests/build/bundle guards passed; local installer checks retained the running-personal-app refusal.
- Actual public app/source ZIPs and checksum file matched reviewed bytes and GitHub digests. The source ZIP equals all 136 tracked tag files; the extracted original app is arm64, 3.0.2/build 13 and ad hoc signed. [Exact package evidence and limits](docs/MACOS_3_0_2_RELEASE.md). Latest/direct-download promotion is handled by the protected documentation update; tap remains 2.2.5, M6 remains deferred and M10 first launch remains pending. No personal installation or physical full-app/energy claim is made.

## Daily-use rest-start boundary — 2026-10-05 (initial development; shipped in 3.0.2)

- Two deterministic regressions failed on 3.0.1 source: a short/long break started between polls included pre-break time in its first decrement and could complete early; a break started before the first poll lost its initial elapsed interval. The fix resets the rest sample timestamp at the actual manual start. The existing countdown timer, elapsed-time bounds and sensor gate remain unchanged.
- **213 tests in 21 suites passed** locally with synthetic temporary settings/statistics. The new coverage checks fractional start offsets, the first displayed decrement, no completion before the configured duration and the short/long cadence result. Existing pause, idle, sleep/wake, snooze and genuine-stall regressions also passed. These tests do not establish full-app appearance, physical lifecycle behavior or sustained energy use; daily-use observations remain separate.
- The initial fix PR #31 did not bump the version/build or publish a release. The subsequent owner-authorized 3.0.2/build 13 publication is recorded above. No personal installation, Windows change, EN/TR string change, networking capability, permission or dependency is added. M6 stays deferred, M10 original first launch stays pending and the Homebrew tap remains 2.2.5 with end-user commands withheld.

## 3.0.1 regular release — 2026-10-05

- [PR #29](https://github.com/boorkymoorky/molaway/pull/29) and [merged-main Verify](https://github.com/boorkymoorky/molaway/actions/runs/37298207328) passed all steps for tag source `c6ea02b57c29705b4e73e036439fcce3f7a7139e`: 211 tests in 21 suites, source/publication/distribution guards, release build, original signature/entitlements, 372 unchanged EN/TR keys, eight negative bundle fixtures and isolated installer checks. Local isolated installer checks also passed before installation.
- The actual public app/source ZIPs and checksum file matched reviewed bytes and GitHub digests. The source ZIP equals all 135 tracked tag files; the original extracted app is arm64, version 3.0.1/build 12 and ad hoc signed. [Exact package evidence and remaining limits](docs/MACOS_3_0_1_RELEASE.md). Direct-download metadata now targets 3.0.1; the tap remains 2.2.5. M6 is deferred, M10 original quarantined first launch is pending, and end-user tap commands remain withheld.

## Countdown cadence fix — 2026-10-05 (initial development; shipped in 3.0.1)

- A deterministic regression reproduces `20:00 → 20:00 → 19:58` when a fixed one-second poll's late delivery varies across the rounding boundary. The existing real elapsed-time accounting is correct. The fix rephases that same timer after the next countdown boundary, with a 50 ms margin and the existing 200 ms tolerance. Processing time is subtracted from the next wait; paused/empty counters keep a one-second poll. A bounded short correction can occur after a transition or genuine stall; no continuously faster timer or separate visual clock is added.
- **211 tests in 21 suites passed**, including nine new regressions: the original symptom, changing allowed lateness and fractional phases, short/long rest completion, manual pause/resume, automatic idle pause, sleep/wake, honest long-stall recovery, snoozed-reminder countdown and bounded scheduling after processing. Synthetic model tests do not establish physical sleep/wake or full-app behavior.
- An isolated native Foundation timer probe with compiled model code, a distinct identity and temporary synthetic settings reproduced two repeated labels and one double step under the old cadence. The rephased probe produced 17 successive one-second decrements in the same 18-second scenario, without either symptom. No application services or real sensors were started. This is scoped scheduling evidence, not sustained performance, energy or full UI verification.
- Source/publication/distribution guards, release-mode build and original bundle guard passed locally: Apple Silicon, 372 matching EN/TR keys, unchanged permissions and eight rejected bundle fixtures. Protected PR #28 and merged-main checks passed. At initial development, local installer checks retained their refusal while the personal Molaway was running; subsequent release checks are recorded above.
- The code fix is absent from the unchanged public 3.0.0 assets and ships in 3.0.1/build 12. The initial fix PR did not publish a release; the subsequent owner-authorized publication is recorded above. No tap or Windows change is included. M6 structured checks remain deferred and M10 original first launch remains pending; end-user Homebrew commands stay withheld.

## Initial 3.0.0 latest-download homepage — 2026-10-05 (historical)

- The owner instructed the homepage to use the latest 3.0.0 release. README and the installation guide now describe its cycle; the static local download button targets GitHub's latest-download route for the verified 3.0.0 app ZIP. Old independent-timer screenshots are not presented as current 3.0.0 UI.
- The distribution guard checks direct-download version/SHA256 in `docs/download.json` independently of the 2.2.5 tap. Both retained real ZIPs passed their respective checksum/metadata checks; six disposable negative fixtures were rejected. CI runs those fixtures. Live latest routing must resolve to the same public 3.0.0 bytes before this change is delivered.
- App code, identity, version/build, EN/TR strings, entitlements, release assets/tag, tap cask and personal/Windows work are unchanged. Homebrew status is visible; its command remains withheld while M10 first launch is pending. M6 structured checks are not restarted.

## 3.0.0 regular release — 2026-10-05

- [PR #24](https://github.com/boorkymoorky/molaway/pull/24) and [merged-main Verify](https://github.com/boorkymoorky/molaway/actions/runs/37271481158) passed all steps for tag source `7d675c40d2819188843209f19901e59481b8931f`. Local tests passed 202 cases in 20 suites; source/publication/distribution guards, release build and bundle guard passed (127 curated files, 372 unchanged EN/TR keys, exact original permissions, eight rejected negative fixtures). Hosted isolated installation checks passed; local verification kept the running-app refusal. No personal app/data was used as a test target.
- [3.0.0](https://github.com/boorkymoorky/molaway/releases/tag/v3.0.0) is a regular release at the owner's explicit request; no beta was published. The actual public app/source ZIPs and checksum file were downloaded, matched byte-for-byte with the reviewed local packages and GitHub digests, and passed tracked-source and extracted original-signature/metadata/arm64/license/resource inspection. See [exact package evidence and migration limits](docs/MACOS_3_RELEASE.md).
- At initial publication the default/latest release and tap remained 2.2.5. The subsequent homepage decision makes 3.0.0 the latest/direct download; the tap separately stays on 2.2.5. M6 structured checks are not restarted; M10 original first launch is still pending and the tap command withheld. Complete-app notification/accessibility/display/lifecycle, optional-signal, multi-day/energy, Intel and oldest-supported-OS cases retain their unverified limits. Regular publication does not prove these physical results. No app networking, broader permission or Windows release is added.
- Milestone reports below are historical observations at their stated dates; their then-unshipped status does not describe the now-published 3.0.0 release.

## M11 integrated verification — 2026-10-04 (development; no app release)

- Starting main `7621316` and its GitHub verification passed; the local baseline passed 199 Swift tests in 19 suites. Three new AppContainer composition regressions bring the full successful local suite to **202 tests in 20 suites**. They use synthetic settings/statistics, injected clocks and quiet readings, not personal data or real OS transitions.
- Release-mode Apple Silicon build, original ad hoc hardened-runtime signature, source/publication guards and offline 2.2.5 cask consistency passed. The new built-bundle guard verifies source-matching metadata/license/resources, exact sandbox/file entitlements and **372** matching EN/TR keys/format placeholders. Eight negative fixtures were rejected. The guard is included in CI before isolated installation checks.
- Local installer verification stopped at its existing running-Molaway guard; the personal app was kept running. [PR #21 Verify run 37226017129](https://github.com/boorkymoorky/molaway/actions/runs/37226017129) passed the full workflow, including clean-environment install/update/failure verification. The final PR head must also pass before merge. No local installation pass or physical first-launch claim is inferred.
- M11 preparation does not close deferred physical notification, accessibility, sleep/lock, display, M8 device/app transition, multi-day Screen Score or M10 Gatekeeper-first-launch gaps. No application text, behavior, permission, version/tag/release or Windows work was changed. See [M11 evidence, physical limits and release handoff](docs/M11_RELEASE_READINESS.md).

## M10 tap continuation — 2026-10-04 (no new app release)

- [Molaway PR #20](https://github.com/boorkymoorky/molaway/pull/20), [tap PR #1](https://github.com/boorkymoorky/homebrew-molaway/pull/1) and [tap verification PR #2](https://github.com/boorkymoorky/homebrew-molaway/pull/2) passed required CI and merged. The public maintainer-owned tap installs the existing 2.2.5 ZIP; a fresh download again matched both published digests. Native Homebrew style/strict online audit, exact public-reference installation, fetch/reinstall/current-version upgrade no-op/uninstall, quarantine, original signature, simulated platform bounds and synthetic collision/data-preservation checks passed within [M10’s documented limits](docs/M10_DISTRIBUTION.md).
- Original first launch after normal Gatekeeper approval is deferred and unverified; the end-user tap command remains withheld. The installed original app’s signing scan returned the expected Developer ID/notarization requirement. No security override, personal app/data replacement, new version/release or physical M6 checklist was performed.

## Initial M10 preparation (PR #19; historical) — 2026-10-04 (no new app release)

- Downloaded the actual public `Molaway-2.2.5-macOS-arm64.zip` (asset ID `591372855`, 1,809,628 bytes). Its computed SHA256 matched the release's exact app entry in `SHA256SUMS.txt` and GitHub's asset digest. Bundle identity/version, arm64 architecture, macOS 15 target, English/Turkish resources, ad hoc hardened-runtime signature and unchanged sandbox/file entitlements were inspected; extracted signature verification passed. This does not verify publisher identity, absence of malware or physical first launch. See [M10 distribution verification](docs/M10_DISTRIBUTION.md) for the pinned values and limits.
- The Homebrew candidate was loaded with the native cask DSL, and selected offline source audits passed. The repository guard passed both offline and against the downloaded ZIP; negative checks rejected a missing checksum, foreign release URL, inconsistent documented hash/download, executable install hook and modified ZIP. The CI guard is offline and does not prove live download availability.
- All 199 Swift tests in 19 suites, source/publication guards, English/Turkish localization syntax, release build and ad hoc signature verification passed locally. Local installation verification stopped at its existing running-app guard; the personal app was left running and unchanged. PR CI includes isolated installation checks.
- At the initial PR #19 check, the tap was unpublished and end-user installation unverified: no Homebrew install command is published. M1–M9 are merged development work, absent from published 2.2.5. No app source, entitlement, local installation, user data, localization text, Windows work or release metadata was changed. M6 structured physical checks remain deferred for daily-use feedback; M11 had not started at that initial check.

## M9 Screen Score development checks — 2026-10-04 (not shipped)

- 199 Swift tests in 19 suites passed locally, including retained M1–M8 coverage and 15 Screen Score regressions for calculation, sample threshold, weighted periods, migration, hostile counts/types, full-cycle eligibility, provisional rollback, duplicate outcomes, cadence, early/extra breaks, snoozes/retries/early returns, quiet/preview, pause/sleep, opt-out/deletion, retention, relaunch, resolution-day attribution and clock discontinuity.
- Source/publication guards, English/Turkish localization syntax, release build and ad hoc signature verification passed. No entitlement, dependency, sensor, network capability or release metadata change. Local isolated installation checks stop at their running-app guard while the personal M8 app remains open; the PR workflow supplies isolated checks.
- Limited English/Turkish layout inspection used a disposable AppKit rendering harness with the compiled settings view and synthetic daily totals. It showed the explanatory score and counts, preserved legacy totals, and the narrow layout. This does not establish complete app, keyboard/chart selection or VoiceOver behavior.
- Real multi-day use and physical lifecycle/notification transitions remain unverified. M6 structured physical checks remain deferred in favor of daily-use feedback. See [M9 Screen Score](docs/M9_SCREEN_SCORE.md). No release was published.

## M8 development checks — 2026-10-04 (not shipped)

- 184 Swift tests in 18 suites passed locally, including retained M1–M7 coverage and new optional audio-input, native-fullscreen and selected-frontmost-app policies, settings attacks, quiet return and lifecycle interactions.
- Source/publication guards, TR/EN localization syntax, release build and ad hoc signature verification passed. No entitlement, dependency, network capability or release metadata change. Local installation verification stopped because the personal app was running; the normal PR CI includes isolated installation checks.
- A same-entitlement signed probe established query availability only. A separately identified complete app copy exposed readable English/Turkish settings, working app choice/removal and available audio/fullscreen status without a permission prompt. These observations do not verify positive microphone/fullscreen/foreground-switch detection or notification delivery.
- Automatic screen sharing, microphone-only classification and broader fullscreen inference are explicitly deferred. Real device/app transitions, accessibility and energy use remain unverified. M6 structured physical checks stay deferred in favor of daily-use feedback. See [M8 quiet signals](docs/M8_QUIET_SIGNALS.md).

## M7 Smart Pause development checks — 2026-10-04 (not shipped)

- All 166 Swift tests in 17 suites, source/security and tracked publication guards, release build, ad hoc signature verification and isolated installation checks passed. New regressions exercise signal combinations and the bounded typing gate across all reminder styles/modes, fallbacks, repeated delivery, preview, independent pause reasons, completed rest, cadence and snoozes.
- Typing deferral is off by default and uses only aggregate elapsed keyboard time, with one 30-second budget per due work cycle and release after a two-second typing pause. No keys/content/history, event monitoring, new permission, entitlement, dependency or application networking.
- The installed M7 app opened; limited Turkish settings/layout inspection passed, the new typing preference stayed off, and notification settings reported Granted after update. Only one Molaway app remained installed; local data was unchanged immediately after installation, before normal app writes resumed.
- Physical typing detection, actual reminder delivery/actions, broader media/system/input cases and full keyboard/VoiceOver traversal remain unverified. Existing M6 behavior is retained; its structured physical checklist remains deferred. See [M7 Smart Pause](docs/M7_SMART_PAUSE.md). No M8 or release.

## M6 usability follow-up — 2026-10-04 (not shipped)

- 150 Swift tests in 16 suites, source/publication guards, release build, ad hoc signature verification and isolated installation checks passed.
- Limited full-app TR/EN inspection confirmed the separated dashboard labels and notification error/style-selection flows. The earlier isolated test copy rejected native authorization. After installing the current development copy, the owner reported that the macOS permission prompt appeared and was approved. Prompt/approval is user-confirmed for that installation; later UI automation of the updated M7 installation reported Granted. Notification delivery and action timing remain unverified.
- The owner reported the initial paused menu-bar icon missing while the app remained running. A follow-up uses a fixed drawable pause glyph and an explicit icon-only menu-bar slot; the owner confirmed the updated paused icon was visible and opened the dashboard. The owner also confirmed a resume/re-pause repeat with a clock-only active title and an accessible paused icon. Broader checks and release readiness remain pending. See [M6 usability checks](docs/M6_USABILITY_CHECKS.md) and the [full-app readiness report](docs/M6_READINESS.md). M7 and publishing are outside this work.

## M6 readiness review — 2026-09-30 (not shipped)

- Reviewed main commit `5f7d1a9`, which merged PR #12. [Main Verify run 36686346076](https://github.com/boorkymoorky/molaway/actions/runs/36686346076) passed. A fresh local run passed all 141 Swift tests in 14 suites, source/security and tracked publication guards, release build, ad hoc signature verification, and isolated installation/update/failure checks.
- Limited full-app UI automation used the same compiled application code, re-signed under a disposable bundle identity with isolated local data. English/Turkish settings and a real manual short-break completion advancing the cadence were observed. This does not verify every lifecycle transition or physical VoiceOver, display/Space, sleep/lock behavior.
- The initial remaining physical checks could not be completed with the product owner unavailable. Later user observations are recorded separately; on 2026-10-04 the owner deferred structured physical checks in favor of daily-use feedback. Unperformed checks remain explicitly pending in [M6 readiness](docs/M6_READINESS.md); prior harness observations are not promoted to full-app results. Release readiness remains pending. No M7 work, release, version bump, network access, or permission expansion was performed.

## M5 break-skip development checks — 2026-09-27 (not shipped)

- 135 Swift tests in 13 suites passed locally, including seven M5 regressions for Casual/Balanced/Hardcore, the five-second gate, closing, snoozing, preview isolation, cadence, persistence, manual pause, and an Office Hours notification boundary.
- The targeted source security guard, publication guard, release build with ad hoc signature verification, and isolated fresh/update/failure installation checks passed. These are scoped checks, not a security audit.
- M5 adds one local settings field and no new network, permission, dependency, capture, or activity-history capability. A user-requested settings backup can include the skip mode.
- Physical checks remain pending: real macOS notification action timing, VoiceOver and keyboard traversal of all alert styles and the menu dashboard, Escape/close behavior, and monitor/Space placement. M1–M4 remain in review; this change is not in the released app.

## M4 Office Hours development checks — 2026-09-27 (not shipped)

- 128 tests in 12 suites passed locally, including 15 Office Hours regressions. These cover calendar boundaries, overnight ownership, DST gaps/repeated hours, travel, settings migration/validation, relaunch, independent pause reasons, frozen work/snooze time, and manual/natural break cadence. The existing M3 lock test now supplies a deterministic idle sample.
- The local release build, ad hoc signature verification, source/publication guards, and isolated fresh-install/update/failure-path checks passed.
- An isolated preview was inspected in English and Turkish. The Office Hours settings, dashboard, and tomorrow menu rendered; keyboard increment and Tab traversal of the time fields worked. This is a limited UI smoke check, not full VoiceOver or physical lifecycle verification.
- No network, permission, dependency, capture, or activity-history capability was added. Schedule preferences remain local; only a user-requested settings backup includes them.
- Full keyboard/VoiceOver flows, all window sizes, real sleep/lock/relaunch at schedule boundaries, and monitor/Space combinations remain pending. See the M4 checklist in `docs/ROADMAP.md`.

## 2.2.5 checks — 2026-09-26

- 116 tests in 10 suites passed. Regressions first reproduced a second timer interrupting a snooze and a pending delivery retry returning immediately after snooze; both passed after the fix. Four consecutive snoozes were exercised, preserving a later movement deadline and counting only shown reminders as deliberate deferrals. Preview controls leave timers unchanged.
- Release build, signature verification and isolated installer checks passed. The installed sandbox probe returned `networkDenied=true`. No new permission or networking capability was added.
- The repository is public. Main requires a pull request, the GitHub Actions `verify` check, an up-to-date branch and resolved conversations, including for administrators. Force pushes and branch deletion are disabled.
- Private vulnerability reporting, secret scanning, push protection and Dependabot alerts are enabled. External contributors require approval before their workflows run; default workflow access is read-only and actions are pinned to full commit identifiers.

## Public release review — 2026-09-25

- At commit `cc101b6`, the curated tree contained 87 files. Targeted privacy checks also covered all 137 unique historical file blobs and the six uploaded 2.2.2–2.2.4 app/source ZIPs. No matching credentials, personal home paths, private email addresses, or private network addresses were found. All commit author/committer email addresses use GitHub noreply.
- [Verify run #6](https://github.com/boorkymoorky/molaway/actions/runs/36186975860) passed on the GitHub macOS runner, including the new isolated installer checks.
- MIT notices, upstream links, English installation guidance, synthetic screenshots, unsigned-publisher limitations and manual-update behavior were reviewed. The release ZIP digests matched the values displayed by GitHub.
- Public availability does not change the unverified device, accessibility and long-term energy scenarios listed below. These checks are not an independent security audit.

## 2.2.4 local checks — 2026-09-25

- 114 tests in 10 suites passed. New regressions first reproduced early merging of an explicit snooze and short sleep counted as work; both passed after the fixes.
- An eight-hour simulated schedule exercised repeated manual/natural rests, snoozes, early returns and sleep, checking finite countdowns and consistent rest states. This is not eight hours of physical use.
- The actual installer passed isolated fresh-install, replacement, staging-cleanup, damaged-source, unrelated-app, symlink-destination and relative-path checks. Failed cases preserved the existing test installation.
- Version 2.2.4 was installed locally; existing interval settings remained unchanged and the dashboard opened with named eye/movement countdowns. Signature verification passed and the installed sandbox probe returned `networkDenied=true`.

- A 60-second local sample with app windows closed measured about 1.25% of one CPU core and 92–95 MiB resident memory. User activity was uncontrolled; this is neither a battery/energy measurement nor a sustained-use guarantee. The earlier 2.2.3 sample was about 1.28%, so no meaningful performance improvement is claimed.

## 2.2.3 checks — 2026-09-25

- 111 tests passed, including explicit snooze → completed manual rest and snooze → natural absence regressions.
- Reproduced the ambiguous 20-minute eye / 5-minute movement case: the shorter eye rest satisfies only the eye target. The next timer is now named and uses the same readout in the menu and dashboard.
- This explains one reproducible source of different numbers; it does not establish which exact sequence a user took without their confirmation.

## 2.2.2 local checks — 2026-09-25

- 108 tests in 10 suites passed, including eight new lifecycle regressions using isolated local test data.
- Covered: due while away, automatic return, explicit Continue, uncounted manual-rest rollback, return on the completion tick, and sleep without an intervening timer tick.
- The installed release opened successfully; the manual break → Continue flow visibly restarted the eye timer at 20:00.
- The local source installer was exercised. Signature verification passed and the installed sandbox probe returned `networkDenied=true`.
- Publication review covered tracked files, all 90 unique historical file blobs before this update, commit authors, scripts, permissions, and image metadata. No credentials, private email addresses, local home paths, or private network addresses were found by the targeted checks. Commit email uses GitHub noreply.
- Historical icon EXIF contained only color-space and image dimensions. The current source PNG has that metadata removed. The unused upstream website and icon are removed from the current tree; they remain in historical commits and contain no identified personal secrets.
- Build bundles are excluded from Spotlight indexing; old test/distribution bundles were removed and one installed Molaway remained in the Spotlight query.
- These results do not replace independent review or real-world testing of every sleep/video/monitor combination.

## GitHub verification — 2026-09-25

- [Verify run #2](https://github.com/boorkymoorky/molaway/actions/runs/36090875946) succeeded for code commit `a8027c8` on the macOS 26 runner using Swift 6.3.3.
- The workflow passed source/publication guards, tests, release build, and signature verification. The link requires repository access while the project remains private.
- The first run encountered a Swift compiler crash while converting an actor-isolated method to a binding setter. An explicit closure resolved it; no test was removed or disabled.

## 2.2.1 local checks — 2026-09-24

- 100 tests in 9 suites passed, covering timers, idle rollback, natural/manual breaks, settings validation, data retention, hostile file inputs, calendar validation, and chart snapshots.
- 7/30/90-day charts and active/break/rest selections were exercised in a separate release preview with synthetic data.
- The 90-day and metric interactions completed with UI inspection in approximately 0.8–0.9 seconds. This includes automation overhead, not frame-time instrumentation.
- Thirty chart-data snapshots across all periods took about 0.022 seconds in a local test. This measures preparation only, not chart rendering.
- The previous nested 90-day preparation pattern took about 167 seconds in an isolated reproduction. This is evidence of the removed repeated work, not an end-to-end benchmark of the old app.
- English screenshots use synthetic daily totals and only app windows. Screenshot metadata is removed for publication.
- The user confirmed both dashboard and Settings opened on the second monitor. Display disconnect/reconnect and every Space arrangement still need physical testing.

## Security checks

- Targeted source guard verifies expected sandbox/file entitlements and flags selected network/capture APIs and credential patterns.
- A separate publication guard checks the curated copy for private data files, local paths, common secret patterns, and image metadata.
- Release signature verification passed. The 2.2.1 release probe returned `networkDenied=true`; no network/capture entitlement was added.
- These checks do not constitute an independent security audit or prove absence of vulnerabilities.

## Prior verified behavior

- Daily summaries default off, remain separate from settings import/export, and are created only after opt-in.
- Synthetic weekly-report delivery and cancellation after opt-out were verified in a separate preview.
- The sandbox network probe previously returned `networkDenied=true`; it attempts a loopback connection without sending data.
- Native alert fallback/error handling, quiet modes, and supported video signals have local test coverage. Universal player support is not claimed.

## Not yet verified

- Long-term use, battery/GPU/WindowServer impact, every accessibility contrast and VoiceOver flow.
- All monitor/Space arrangements, physical sleep/lock/restart scenarios, all cameras/meeting apps, and available shared Focus configurations.
- Intel and every supported macOS version.
- Apple Developer ID signing and notarization. Current packages are ad hoc signed.

No identifying machine inventory, personal usage data, raw logs, local file paths, credentials, or signing materials are included in this report.
