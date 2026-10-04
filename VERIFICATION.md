# Verification

## M6 usability follow-up — 2026-10-04 (not shipped)

- 148 Swift tests in 15 suites, source/publication guards, release build, ad hoc signature verification and isolated installation checks passed.
- Limited full-app TR/EN inspection confirmed the separated dashboard labels and notification error/style-selection flows. Native authorization still fails for the tested application copy; permission prompting and delivery remain unverified.
- Menu-bar readability, broader physical checks and release readiness remain pending. See [M6 usability checks](docs/M6_USABILITY_CHECKS.md) and the full-app readiness report in [PR #13](https://github.com/boorkymoorky/molaway/pull/13). M7 and publishing are outside this work.

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
