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

## Remaining physical checks

Record each row as passed, failed, or not run. Include the tested source commit and whether it was the full app or a harness; omit personal settings, raw logs, screenshots of other apps, and identifying device inventory.

| Check | Full-app acceptance criteria | Current status |
| --- | --- | --- |
| Countdown lifecycle | In a real work cycle, badge appears only in the final ten seconds and disappears at the due reminder; it does not change the deadline or short/long count. | Pending |
| Visibility transitions | While visible, disable/re-enable, manual pause/resume, preview open/close, quiet mode, Office Hours closure and active rest hide/show as eligible without orphan panels or duplicate announcements. | Pending; component/model coverage and earlier harness observations only |
| Quit and reopen | Quit while badge is visible; no badge remains. Reopen creates one app/controller, preserves opt-in and manual pause, and restarts session timers without inventing a completed break. Repeat settings-window close/reopen. | Pending |
| Pointer and focus | Click through the visible badge in another app; typing/click focus stays there. Repeat with Reduce Motion on/off, restoring the original OS setting afterward. | Pending in full app; earlier harness observation only |
| Displays | Move across displays and edges with different origins/scales; disconnect/reconnect the display holding the visible badge. Badge stays within the current visible frame with no stranded copy. | Pending in full app; earlier harness geometry/movement observation only |
| Spaces and full screen | Switch Spaces and enter/exit another app's native full screen while badge is visible. It follows eligible pointer placement without taking focus or changing another Space. | Pending in full app; earlier user observation in harness only |
| Lock/unlock | Lock during countdown and unlock after a measured short absence below both idle and rest thresholds; no stale badge, work accrual during lock, or false break credit. Repeat with overlapping display/session events and an existing manual pause. Unlock requires the user. | Pending in full app; earlier harness callback check only |
| System sleep/wake | Sleep during countdown; measure actual absence. Test below and above qualifying natural-rest thresholds, then wake. Short absence preserves progress; qualifying absence credits only the appropriate single break/cadence step. Manual pause and Office Hours remain independent. | Pending in full app; earlier measured short harness repeat only |
| Turkish VoiceOver announcement | With Turkish UI and appropriate speech, hear one intelligible localized short/long countdown announcement on entry; no per-second repetition or pointer-induced duplicate. The user judges pronunciation and intelligibility. | Pending; English single-announcement behavior was previously accepted in harness |
| Manual VoiceOver text access | Navigate to the floating countdown window and then its stable read-only text; read the current localized label, including after a second update, without activating it or taking keyboard focus from the underlying app. Repeat in TR/EN. | Pending; accessible metadata/unit tests are not proof of manual navigation |

The reviewed session does not close the remaining M4/M5 physical notification, keyboard/VoiceOver, panel-close, schedule-boundary or display checks listed in the roadmap. Long-term energy use and broader supported-system coverage also remain unclaimed.

A physical failure should be reproduced and fixed on a separate focused `codex/` branch/PR with relevant regression and distribution checks. Keep the single-announcement decision, local privacy boundary, TR/EN consistency and M1–M6 behavior. Update this report with bounded evidence before reconsidering release readiness.
