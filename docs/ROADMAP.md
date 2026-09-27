# Planned product roadmap

This roadmap describes planned work, not shipped features. Each milestone is a separate focused change. macOS work comes first; the Windows implementation remains a separate preview until its physical Windows checks pass.

## macOS

| Milestone | Planned scope | Status |
| --- | --- | --- |
| M1 | One work/short/long break cycle, migration from independent eye and movement timers, Deep Focus timing profile, and a minimal usable interface. | Implementation in review; not shipped |
| M2 | Reconnect the two rings to work/rest and short-break cadence; simplify the menu panel and settings controls. | Implementation in review; not shipped |
| M3 | A shared pause model with 30-minute, one-hour, tomorrow, and manual-resume options. | Implementation in review; not shipped |
| M4 | Office Hours, including overnight shifts and tomorrow's next working start. | Planned |
| M5 | Explicit Casual, Balanced, and Hardcore skip behavior across all reminder surfaces. | Planned |
| M6 | Optional cursor countdown before a break. | Planned |
| M7 | Unify existing activity signals under Smart Pause and add bounded typing deferral. | Planned |
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
- M3 pause options preserve distinct manual, future office-hours, sleep/lock, and automatic reasons. With Office Hours still planned for M4, “until tomorrow” uses the next local 09:00, including after a time-zone change. M4 will connect it to the next selected Office Hours start.
- M4 Office Hours will support selected weekdays and overnight spans assigned to the start day. Time outside those hours will not accrue break debt; a manual break remains available.
- M5 skip modes are planned as always available, available after a visible delay, and unavailable in normal break controls. Closing a surface must never mark a break complete, and quitting the app remains possible.
- M6's optional cursor countdown will be click-through and active only while shown; display boundaries, pause, and reduced motion need verification.
- M7–M8 will distinguish video activity from suppressing breaks. Camera and microphone features may read use state only, not content. Selected focus apps would be local preferences only, never usage history. Signals that cannot be trusted under current sandbox permissions will be documented or deferred.
- M9's proposed score uses completed real break opportunities rather than a fixed 30-minute expectation. Snoozes should not cause repeated penalties, and extra manual breaks should not inflate it. Insufficient data and days before the new schedule will not receive invented scores. Optional storage stays in bounded daily summaries, with existing retention and deletion controls.
- M10 installation instructions will use a verified Molaway asset and checksum. No unverified Homebrew command will be published. The app itself will remain offline and manually updated.

The project remains local-first, account-free, telemetry-free, and permission-minimal. Planned work does not authorize new network access, broad permissions, private APIs, or application usage history.
