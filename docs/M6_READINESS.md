# M6 physical verification and release readiness

## Scope and decision — 2026-09-30

M6 is merged to main but remains unshipped. Release readiness is **pending physical verification**. This review does not authorize M7 or a release. The accepted VoiceOver behavior remains one low-priority localized announcement per visible countdown, with no announcements on individual second or pointer updates.

The reviewed main commit is `5f7d1a9` (PR #12 merged). GitHub main verification [run 36686346076](https://github.com/boorkymoorky/molaway/actions/runs/36686346076) succeeded. The latest published release was still [2.2.5](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5). Windows [PR #2](https://github.com/boorkymoorky/molaway/pull/2) remained open; unfinished local Windows work was kept separate.

## Evidence boundaries

Earlier pointer click-through, Reduce Motion, display/Space, sleep/lock, and English announcement observations used a disposable harness with synthetic work time. They remain useful evidence for the components but do not establish full-app physical results. Earlier manual VoiceOver navigation did not establish that the badge text could be read.

This review uses the built, sandboxed application with the same compiled application code and real elapsed time. The disposable copy uses a separate bundle name/identifier and is re-signed for that identity, isolating its preferences and local data from the installed release. All 35 compiled Mach-O sections match the standard build; the signed executable files are not byte-identical. It is not a separate model/controller harness. UI automation can inspect accessible text and operate controls; it cannot confirm audible Turkish pronunciation, a physical display disconnect, or user unlocking the screen. The product owner was unavailable for physical checks in this session.

## Automated and distribution preparation

- All 141 Swift tests in 14 suites passed on the reviewed main source, including M1–M6 and countdown accessibility/announcement regressions.
- The targeted source security guard and tracked publication guard passed. These are scoped guards, not an independent security audit.
- Release build, ad hoc signature verification, and isolated fresh/update/failure-path installer checks passed. No personal installation or settings were replaced.
- Sandbox entitlements remain limited to App Sandbox and user-selected file read/write. No new network access, permission, dependency, or activity-history capability was added.
- English/Turkish countdown resources retain the same keys and formatting; the announcement and read-only badge text use the same localized label.
- Current release metadata and installation guidance still describe the shipped 2.2.5 independent-timer product. Before any future M1–M6 release, choose its version/build number and prepare matching changelog, screenshots, installation/migration text, archive and checksums. Do not advertise unreleased cycle behavior as shipped or prepare a new public release in this review.
- Developer ID signing/notarization, Intel, and the oldest supported macOS version remain unverified. The existing ad hoc/unnotarized disclosure and per-app Gatekeeper guidance remain required.

## Full-app observations

Results below are limited UI automation observations; they do not replace the pending physical checklist.

- The complete app launched with fresh isolated settings; countdown defaulted off, Office Hours defaulted off, and English settings exposed the M1 cycle and M5 mode controls.
- The work interval was changed to five minutes, countdown enabled, and language switched to Turkish through the actual settings UI. The Turkish dashboard exposed a named short-break countdown, work progress, and completed-short cadence. Manual watching mode was exercised to keep real time advancing without synthetic clock injection.

- A manual short break showed a 20-second rest and the Balanced five-second skip gate. After it completed in real time, the dashboard showed a new work countdown and completed-short count advancing from zero to one of two. This is one UI-observed cycle, not comprehensive cadence or lifecycle verification.
- Manual watching mode was ended, and the Turkish “until I resume” pause action produced the expected paused status. The disposable app was left manually paused. This does not establish pause persistence through process relaunch or badge removal during a visible countdown.
- No application defect was established in these observations. UI automation did not establish visible-badge lifecycle, graceful quit/relaunch, or manual VoiceOver navigation; those remain pending rather than being inferred from the passing model tests.

## User-operated full-app checks — 2026-10-01

- Tested application code: main `5f7d1a9`, using the complete sandboxed app re-signed under its disposable test identity, not the earlier harness. The Turkish UI and pointer countdown were enabled. A real five-minute work period leading to a long break was prepared through the application controls; the completed-short count remained two of two when the preparation skip started that period.
- Following the final-ten-second observation instructions, the user confirmed that the pointer badge appeared and disappeared on time. This verifies the reported appearance/removal in this one full-app run. No independent onset/deadline measurement was recorded. Subsequent full-app UI inspection still showed the same completed-short count of two of two after the due reminder; showing the reminder did not visibly credit another break in this run.
- The user subsequently confirmed that the badge did not obstruct anything and normal interaction worked without problems. This supports ordinary pointer/keyboard interaction in that run. It does not establish a direct click inside the badge, every focus path, or Reduce Motion. Direct click-through, Reduce Motion, visibility transitions, quit/relaunch, displays/Spaces, sleep/lock, Turkish VoiceOver and manual text navigation remain pending.

- In a second full-app run, the user quit through the menu-bar command while the countdown was visible and confirmed that the badge disappeared and the test app reopened. UI inspection afterward showed Turkish language, five-minute work settings, and countdown opt-in retained. However, the completed-short count changed from the prepared two-of-two state to zero-of-two. This is an unresolved observation, not yet an established relaunch defect: qualifying natural absence or a completed long rest must be ruled out before assigning a cause. The existing deterministic reopening/cadence regression passed again, but it does not explain this physical sequence. The quit/relaunch row remains partial while the sequence is clarified. The disposable app was manually paused for investigation.

## Usability follow-up — 2026-10-04

[PR #14](https://github.com/boorkymoorky/molaway/pull/14), merged to main as `591c601`, addresses user-reported menu-bar/dashboard overlap and misleading notification-permission status on a separate macOS branch. It does not change the accepted cursor announcement policy, start M7 or publish a release. Its detailed verification and limits are in [M6 usability checks](M6_USABILITY_CHECKS.md). The original 141-test main review above is historical; the follow-up passed 150 tests in 16 suites, source/publication guards, release build, ad hoc signature verification, isolated installation checks and GitHub CI before merging.

In the complete, separately identified test copy, macOS rejected the notification authorization request with `notificationsNotAllowed`; no permission prompt appeared. The new UI explains the failure and explicitly offers the existing Small card style. The style-selection flow and TR/EN dashboard layout were inspected, but native prompt/delivery/action checks remain blocked for that tested copy. The exact signing/registration or system cause is unestablished; no new permission or security bypass was introduced. Release readiness remains pending.

The user clarified that the menu-bar icon itself was absent after manual pause in the initial follow-up build `c3575f9`. The process remained running and settings retained the manual pause. PR #14 now includes a fixed drawable pause glyph and an explicit icon-only menu-bar slot. The original standalone bitmap check did not reproduce the absence; the exact cause is unestablished. In the full app built from `0191f78`, the user confirmed the updated paused icon was visible and clicking it opened the dashboard. The user also confirmed a resume/re-pause repeat: normal use showed the clock without a short/long name, and the paused icon remained visible and reopened the dashboard. Other menu states and broader display/appearance combinations remain unverified. The earlier failure remains recorded; this does not close visible-countdown lifecycle or broader accessibility checks.

## Physical-check policy — 2026-10-04

The owner deferred structured physical checks and will report issues encountered during daily use. No new physical-test session is required by this review. Unperformed checks stay unverified; this decision does not close the release-readiness checklist or authorize M7 or publishing. Reproduce and fix reported issues in focused branches/PRs, preserving local privacy and the accepted single-announcement policy.

## Remaining physical checks

Record each row as passed, failed, or not run. Include the tested source commit and whether it was the full app or a harness; omit personal settings, raw logs, screenshots of other apps, and identifying device inventory.

| Check | Full-app acceptance criteria | Current status |
| --- | --- | --- |
| Countdown lifecycle | In a real work cycle, badge appears only in the final ten seconds and disappears at the due reminder; it does not change the deadline or short/long count. | Partial: user confirmed appearance and timely removal in one full-app long-break run on 2026-10-01. Post-reminder UI still showed the starting two-of-two count; independent timing checks remain pending. |
| Visibility transitions | While visible, disable/re-enable, manual pause/resume, preview open/close, quiet mode, Office Hours closure and active rest hide/show as eligible without orphan panels or duplicate announcements. | Pending; component/model coverage and earlier harness observations only |
| Quit and reopen | Quit while badge is visible; no badge remains. Reopen creates one app/controller, preserves opt-in and manual pause, and restarts session timers without inventing a completed break. Repeat settings-window close/reopen. | Partial: user confirmed badge removal on quit and successful reopening; UI confirmed countdown opt-in/TR/timing retained. A two-to-zero short-count transition is under investigation. Duplicate instance, manual-pause persistence and settings-window repeats remain pending. |
| Pointer and focus | Click through the visible badge in another app; typing/click focus stays there. Repeat with Reduce Motion on/off, restoring the original OS setting afterward. | Partial: user reported unobstructed ordinary typing/clicking in the full-app run on 2026-10-01. Direct click inside the badge and Reduce Motion repeats remain pending. |
| Displays | Move across displays and edges with different origins/scales; disconnect/reconnect the display holding the visible badge. Badge stays within the current visible frame with no stranded copy. | Pending in full app; earlier harness geometry/movement observation only |
| Spaces and full screen | Switch Spaces and enter/exit another app's native full screen while badge is visible. It follows eligible pointer placement without taking focus or changing another Space. | Pending in full app; earlier user observation in harness only |
| Lock/unlock | Lock during countdown and unlock after a measured short absence below both idle and rest thresholds; no stale badge, work accrual during lock, or false break credit. Repeat with overlapping display/session events and an existing manual pause. Unlock requires the user. | Pending in full app; earlier harness callback check only |
| System sleep/wake | Sleep during countdown; measure actual absence. Test below and above qualifying natural-rest thresholds, then wake. Short absence preserves progress; qualifying absence credits only the appropriate single break/cadence step. Manual pause and Office Hours remain independent. | Pending in full app; earlier measured short harness repeat only |
| Turkish VoiceOver announcement | With Turkish UI and appropriate speech, hear one intelligible localized short/long countdown announcement on entry; no per-second repetition or pointer-induced duplicate. The user judges pronunciation and intelligibility. | Pending; English single-announcement behavior was previously accepted in harness |
| Manual VoiceOver text access | Navigate to the floating countdown window and then its stable read-only text; read the current localized label, including after a second update, without activating it or taking keyboard focus from the underlying app. Repeat in TR/EN. | Pending; accessible metadata/unit tests are not proof of manual navigation |

The reviewed session does not close the remaining M4/M5 physical notification, keyboard/VoiceOver, panel-close, schedule-boundary or display checks listed in the roadmap. Long-term energy use and broader supported-system coverage also remain unclaimed.

A physical failure should be reproduced and fixed on a separate focused `codex/` branch/PR with relevant regression and distribution checks. Keep the single-announcement decision, local privacy boundary, TR/EN consistency and M1–M6 behavior. Update this report with bounded evidence before reconsidering release readiness.
