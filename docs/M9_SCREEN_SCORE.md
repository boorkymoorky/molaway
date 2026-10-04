# M9 Screen Score (development, not shipped)

Screen Score describes completion of observed break opportunities. It is not a health, presence or productivity measurement, and has no target based on a fixed 30-minute interval.

## Policy

- A cycle is eligible only when daily summaries are enabled from its beginning. Relaunch starts a fresh scheduler cycle; earlier work and pending opportunities are never reconstructed. Enabling summaries during work or a rest waits for the next cycle.
- The configured work interval must become due using confirmed work. Provisional idle time does not create an opportunity. Idle rollback can withdraw an unconfirmed deadline.
- Completing the requested manual rest or a qualifying natural absence resolves that opportunity successfully. Skip resolves it unsuccessfully. Each work cycle can resolve at most once, regardless of short/long cadence or extra reminders.
- Snoozes, notification retries, closing an alert, early return and Smart Pause do not resolve an opportunity. A pending opportunity has no score penalty. Extra manual or natural breaks before the deadline do not add score points; existing completed-break totals retain their meaning.
- Manual pause, Office Hours and short sleep/lock preserve the cycle without adding opportunities. Natural rest still follows the existing Office Hours boundary rules. A timing edit during work or a detected wall-clock discontinuity discards uncertain eligibility; the next full cycle can count.
- Outcomes belong to the local day on which they resolve, including a cycle spanning midnight. Time-zone changes do not redistribute existing summaries. Unresolved state is memory-only: quitting or crashing never saves it as a failure.

## Calculation and interface

`score = round(100 × completed opportunities ÷ resolved opportunities)`

At least **three resolved opportunities** are required. For example, two completed opportunities and one Skip produce **67 / 100**. Below the threshold the interface shows a dash and the actual counts. This is a minimum sample rule, not statistical confidence.

The English/Turkish Overview shows the score, completed/resolved counts and its explanation. The selected 7/30/90-day period combines opportunity counts rather than averaging daily percentages. Selecting a day in the existing chart shows that day's score. Missing or pre-M9 data never becomes zero or an invented score. Today's partial results remain identified as in progress.

## Privacy and compatibility

- No new setting, permission, sensor, dependency, network access or release metadata change. Existing daily-summary consent stays unchanged and defaults off. Recording can be stopped while keeping previous summaries, or deleted with the existing controls.
- Only an optional pair of bounded integer totals (`completed`, `opportunities`) is added to each existing daily summary. There are no event times, durations specific to score, identities, pending records or usage history. Each daily counter is bounded to 8,640.
- Old version-1 summaries decode with an absent score. Existing eye/movement and short/long totals keep their meaning. The additive field stays in the existing bounded statistics file, with the same schema validation, owner-only atomic writes, 30/90-day retention and corruption handling. Older builds do not understand the new field and may drop it on writing; downgrades cannot reconstruct scores.
- Settings import/export still excludes statistics and cannot enable recording. Weekly notifications remain unchanged and contain no score or usage figures on the lock screen.

## Verification limits

- Automated regressions cover calculation/threshold, weighted periods, legacy and malformed data, full-cycle opt-in, timing edits, short/long cadence, extra early breaks, duplicate observation, rollback, completion, Skip, snooze/retry/close/early return, quiet/preview, pause/sleep, retention/deletion, relaunch, outcome-day attribution and clock discontinuity.
- A disposable AppKit rendering harness used the compiled settings view and synthetic daily totals to inspect English and Turkish layouts. This establishes limited layout inspection, not complete app or physical accessibility behavior.
- Real multi-day use, keyboard/chart selection, VoiceOver traversal and physical lifecycle/notification transitions remain unverified. M6 structured physical checks remain deferred; continue with daily-use feedback. No release is published by M9.
