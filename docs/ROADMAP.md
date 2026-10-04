# Planned product roadmap

This roadmap describes planned work, not shipped features. Each milestone is a separate focused change. macOS work comes first; the Windows implementation remains a separate preview until its physical Windows checks pass.

## macOS

| Milestone | Planned scope | Status |
| --- | --- | --- |
| M1 | One work/short/long break cycle, migration from independent eye and movement timers, Deep Focus timing profile, and a minimal usable interface. | Merged to main; not shipped |
| M2 | Reconnect the two rings to work/rest and short-break cadence; simplify the menu panel and settings controls. | Merged to main; not shipped |
| M3 | A shared pause model with 30-minute, one-hour, tomorrow, and manual-resume options. | Merged to main; not shipped |
| M4 | Office Hours, including overnight shifts and tomorrow's next working start. | Merged to main; not shipped |
| M5 | Explicit Casual, Balanced, and Hardcore skip behavior across all reminder surfaces. | Merged to main; not shipped |
| M6 | Optional cursor countdown before a break. | Merged to main; not shipped; physical checks pending |
| M7 | Unify existing activity signals under Smart Pause and add bounded typing deferral. | Implemented; not shipped; physical behavior unverified |
| M8 | Evaluate microphone, sharing, fullscreen, and selected focus-app signals within public APIs and current permissions. | Planned |
| M9 | An explainable Screen Score based on actual break opportunities and bounded optional daily summaries. | Planned |
| M10 | Verified direct macOS download and a Molaway-owned Homebrew tap. | Planned |
| M11 | Integrated macOS verification and release preparation, with physical checks stated separately. | Planned |

## Windows preview, after macOS

| Milestone | Planned scope | Status |
| --- | --- | --- |
| W1 | Bring the verified macOS behavior to the separate Windows core. | Planned |
| W2 | Align Windows interface, controls, and English/Turkish text with the completed macOS design. | Planned |
| W3 | Package and physically verify on Windows 11 before considering a stable claim. | Planned |

## Planned behavior details

- A setting of three completed short breaks before a long break means short → short → short → long. Skips and snoozes do not advance the count; one qualifying natural absence satisfies one break. A completed manual long break resets the count. Long breaks may be disabled.
- The proposed legacy migration maps eye interval to work interval, eye rest to short rest, and movement rest to long rest. The old independent movement interval has no exact equivalent, so users review an approximate cadence. Old eye/movement statistics keep their historical meaning.
- Deep Focus timing is planned as 45 minutes of work, 30 seconds of short rest, and 8 minutes of long rest, with one short break before a long break. Changing profile should preserve a route back to earlier custom timing.
- M2 will make the outer ring show work or rest progress and the inner ring show completed short breaks toward the next long break. The center will show the next break and remaining time. If long breaks are off, the inner ring will not act as a cadence counter.
- M3 pause options preserve distinct manual, Office Hours, sleep/lock, and automatic reasons. In M4, “until tomorrow” uses the next selected work start when Office Hours is enabled; otherwise it retains the next local 09:00. Reopening, schedule edits, and local time-zone changes re-evaluate the deadline without clearing other pause reasons.
- M4 (merged, not shipped): Office Hours defaults off and supports selected weekdays with one shared local start/end time. Overnight shifts belong to their starting day; equal times mean a 24-hour shift. With no days selected, tracking stays paused and no automatic resume is scheduled. Starts are inclusive and ends exclusive. Missing daylight-saving times move to the next valid time; repeated starts use the first occurrence and repeated ends the last. Work progress and snooze time freeze outside the schedule; off-hours absence does not itself complete a break. Manual rests continue across boundaries, with the normal completion/cancellation and short/long cadence rules.
- M5 (merged, not shipped): Casual allows immediate skip; Balanced unlocks after a visible five-second countdown; Hardcore offers no skip control. The gate applies to due reminders and active rests in panels, the menu dashboard, and notification actions. Closing a surface, snoozing, and returning early do not credit a completed break. Quitting remains available, including from the full-screen alert. A preview does not change the real break state.
- M6 (merged, not shipped): An off-by-default pointer badge shows the final ten seconds before a due break. It never takes focus or pointer events, stays within the pointer display's visible frame, and freezes its position with Reduce Motion. Pause, Office Hours, sleep/lock, active rests, and previews hide it. It does not change break timing or request permissions.
- M7–M8 will distinguish video activity from suppressing breaks. Camera and microphone features may read use state only, not content. Selected focus apps would be local preferences only, never usage history. Signals that cannot be trusted under current sandbox permissions will be documented or deferred.
- M9's proposed score uses completed real break opportunities rather than a fixed 30-minute expectation. Snoozes should not cause repeated penalties, and extra manual breaks should not inflate it. Insufficient data and days before the new schedule will not receive invented scores. Optional storage stays in bounded daily summaries, with existing retention and deletion controls.
- M10 installation instructions will use a verified Molaway asset and checksum. No unverified Homebrew command will be published. The app itself will remain offline and manually updated.

The project remains local-first, account-free, telemetry-free, and permission-minimal. Planned work does not authorize new network access, broad permissions, private APIs, or application usage history.

## M4 verification and handoff

- Automated coverage includes weekday/week/month boundaries, overnight and 24-hour shifts, no selected days, DST gaps/repeated hours, local time-zone changes, preference validation/migration, relaunch, overlapping pause reasons, snooze, manual rest, and natural-rest accounting.
- Limited English/Turkish preview and time-field keyboard smoke checks passed. Physical checks remain pending: full VoiceOver and keyboard traversal of weekday toggles, pause menus, and the menu panel; real sleep/lock/relaunch around a boundary; and monitor/Space placement. Synthetic clock tests do not establish these physical results.
- M4 and M5 are merged but remain unshipped pending physical verification.

## M5 verification and handoff

- Automated regression coverage checks all three modes, the five-second gate, settings persistence, due and active break skipping, closing, snoozing, preview isolation, completed-short cadence, independent manual pause, and notification suppression at an Office Hours boundary.
- Local Swift tests, source/publication guards, release build, ad hoc signature, and isolated installation checks passed. These checks do not establish physical notification delivery or accessibility behavior.
- Physical checks remain pending for notification actions and timing, VoiceOver and keyboard traversal, Escape and close behavior on each panel style, and multi-display/Space placement.

## M6 verification and handoff

- Local verification passed: 139 Swift tests in 14 suites, including opt-in persistence, the final-ten-second boundary, preview isolation, manual and automatic pause, quiet mode, Office Hours, sleep/lock, active rest, and negative-origin display placement. Source and publication guards, release build, ad hoc signature verification, and isolated installation checks also passed. These checks are narrower than physical platform verification.
- A limited AppKit UI smoke check used the unchanged M6 model and cursor controller in a disposable harness with synthetic work time and separate settings. The panel appeared for an enabled final-second countdown, disappeared when disabled, during preview, and at the deadline, and returned after preview without changing accrued work. Button interaction remained available while the panel was visible. Runtime inspection confirmed that the visible panel ignored mouse events, was not the key window, and stayed inside a display's visible frame. This does not establish direct clicks through the badge or full application lifecycle behavior.
- Subsequent user-operated checks in the same isolated harness recorded clicks reaching the underlying test surface while inside the visible badge, stable placement with Reduce Motion, and repeated transitions between displays with the final badge frame inside the visible screen area. The user also reported normal interaction across Spaces and a full-screen application. These are limited harness checks and user observations, not coverage of every display layout or the complete app lifecycle.
- A user-operated lock/unlock check exercised the unchanged sleep/wake monitor, model, and cursor controller in the disposable harness. The recorded suspension/resume callbacks were balanced, the badge was hidden at suspension, and accrued work was unchanged after the short absence. This does not establish system sleep/wake or complete application lifecycle behavior.
- A user-operated system sleep/wake repeat measured an absence shorter than the configured short-rest threshold. Suspension/resume callbacks were balanced, the badge was hidden at suspension and visible again afterward, and accrued work and the completed-short count were unchanged. An earlier attempt reset work but did not measure the absence duration; its natural-rest classification remains unverified. These checks use the disposable harness and do not establish the complete application lifecycle.
- Initial VoiceOver navigation attempts did not read the badge; after a metadata change, the user could find its window but could not read its text. The M6 follow-up exposes a floating-window subrole and one stable native read-only text element, and requests a low-priority localized announcement once per visible countdown. Second/pointer updates do not request another announcement. The user subsequently confirmed hearing the English countdown announcement and accepted the single-announcement behavior. Manual navigation to the badge text and Turkish speech/pronunciation remain unverified; this is not full VoiceOver coverage.
- AppKit and model regression tests cover metadata, parent-child reachability, updated text, input/focus invariants, and announcement eligibility/deduplication. All 141 tests in 14 suites, source/publication guards, release build, ad hoc signature verification, and isolated installation passed locally.
- Broader display layouts and full application lifecycle verification remain unclaimed. M6 remains unshipped; M7 has not started.

## M6 readiness review — 2026-09-30

- Main PR #12 is merged and main CI passed. A fresh main-source run passed 141 tests in 14 suites, source/publication guards, release build, ad hoc signature verification, and isolated installation checks.
- The full application was launched with the same compiled application code, re-signed under a disposable bundle identity to isolate local data. English/Turkish settings, real timer progression, and one completed manual short-break/cadence transition were observed through UI automation. These observations do not close visible-badge lifecycle or physical display, Space, sleep/lock, and VoiceOver checks.
- The product owner was initially unavailable for the remaining physical checks. Later full-app user observations and PR #14 usability fixes are recorded separately in [the M6 readiness report](M6_READINESS.md), including the 150-test follow-up. On 2026-10-04 the owner deferred structured physical checks in favor of daily-use feedback; unperformed checks stay unverified. The report records their acceptance criteria, evidence limits, and distribution preparation that remains necessary before any future release. M6 remains unshipped and readiness remains pending. The accepted one-announcement VoiceOver policy is unchanged; M7 has not started and no release is authorized by this review.

## M7 implementation and verification (not shipped)

- Existing video, manual Watching, camera, shared Focus and Presentation signals share one Smart Pause decision. Activity counting stays distinct from quiet alerts. Idle, manual pause, Office Hours and sleep/lock retain their independent rules; no new microphone, sharing, fullscreen or focus-app detection is added.
- Typing deferral defaults off. Once a reminder is pending and otherwise eligible, recent keyboard activity can delay it until a two-second typing pause, for at most 30 monotonic seconds per due work cycle. Retries, snoozes, previews or overlapping pause/quiet periods do not restart an active budget. Work counting continues; it never credits a break or increments deliberate snoozes. A completed/natural rest or skipped/reset cycle allows a new budget.
- The signal is a public aggregate elapsed-time query, not an event monitor. Missing/invalid timing does not delay a reminder; stale signals simply provide no deferral. No new permissions, entitlements, dependencies, network access or typing history. Only the off-by-default preference is saved/exported.
- See [M7 Smart Pause](M7_SMART_PAUSE.md) for automated evidence and explicit physical limits. M8 and publishing remain outside this work. M6's existing countdown remains enabled only by its own opt-in; structured physical checks stay deferred in favor of daily-use feedback.
