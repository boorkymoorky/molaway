# Local data and detection

## What is stored

- Preferences in the app's sandbox container.
- The current manual pause choice and its deadline, if timed, in a separate local file. It is removed when the pause ends and is excluded from settings backups. No pause history is kept.
- Only after opt-in: daily active/video/manual-watching/observed seconds, completed eye/movement/natural/total break counts (and, in the unreleased M1 cycle, separate short/long counts; older eye/movement totals keep their original meaning), capped rest seconds, retention preference, and last weekly-report attempt day.
- No per-event log, app/site identity, typed content, media capture, or exact usage timeline.
- Statistics are separate from settings backups; importing preferences cannot enable recording.

## Counting rules

- Unconfirmed idle time stays in memory and is discarded when it becomes a qualifying absence.
- Video and manual watching are subsets of active time, never extra time added to it.
- One absence can meet both break targets but counts once overall.
- Natural rest records only the qualifying target duration, not hours of sleep or absence.
- The app cannot prove that a person stood up or rested their eyes.
- A sample crossing midnight can assign up to five seconds to its start day. A timezone change does not redistribute past records.
- Missing days are distinct from recorded zero use. Comparisons exclude today and require at least 70% day coverage in each period plus sufficient recorded time.

## Storage and deletion

- Retention: 30 or 90 days. Pruning occurs while running or at the next launch.
- Daily totals publish to the UI about every 15 seconds; normal writes occur at most once a minute, plus break, preference, and exit events.
- A crash can lose the last minute. Corrupt data stops recording and shows an error rather than silently overwriting history.
- Files have bounded size and validated schema, dates, and values. Statistics reads reject symlinks and nonregular files; writes use an exclusive temporary file with owner-only access and atomic replacement.
- Turning recording off offers keep/delete options. OS backups can preserve older copies outside the app's control.

## Signals and permissions

- Idle detection reads elapsed time since input, not keys or text; no Input Monitoring permission.
- Video detection reads known macOS video power assertions transiently; it does not inspect browser pages or screen pixels. Signals vary by player and playback state.
- Camera checks query whether a device is running; no capture session is started. Shared Focus uses the public macOS API and may be unavailable.
- Lock and sleep stop counting. A video playing unattended cannot be distinguished from a person watching it.
- Optional native notifications require permission. The app uses no push service.
- Weekly summaries are separately opt-in, quiet, at most weekly with sufficient data, and contain no usage figures on the lock screen. A failed send attempt also consumes that week's interval. No service runs while the app is closed.
- macOS may create system crash logs independently of Molaway.
