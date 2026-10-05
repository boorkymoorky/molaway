# Local data and detection

## What is stored

- Preferences in the app's sandbox container. The 3.0.0 Office Hours preferences contain only selected weekdays and local start/end minutes; they are included in user-requested settings backups. No schedule-use history is recorded.
- The current manual pause choice and its deadline, if timed, in a separate local file. It is removed when the pause ends and is excluded from settings backups. No pause history is kept.
- Only after opt-in: daily active/video/manual-watching/observed seconds, completed eye/movement/natural/total break counts (and, in the 3.0.0 cycle, separate short/long counts; older eye/movement totals keep their original meaning), capped rest seconds, retention preference, and last weekly-report attempt day.
- 3.0.0 Screen Score: two optional daily Screen Score totals (completed and resolved opportunities), under the same summary opt-in, retention and deletion controls. Pending opportunities stay in memory; no score event history is saved. Earlier days are not reconstructed. See [Screen Score](M9_SCREEN_SCORE.md).
- 3.0.0 selected-app preferences: an optional list of up to 32 explicitly chosen app bundle identifiers, stored only as preferences and included in user-requested settings backups. App names and paths are not saved. The current frontmost identifier is compared and discarded, never recorded as usage.
- No per-event log, observed app/site identity, typed content, media capture, or exact usage timeline. The explicit selected-app preference above is not an observed usage record.
- Statistics are separate from settings backups; importing preferences cannot enable recording.

## Counting rules

- Unconfirmed idle time stays in memory and is discarded when it becomes a qualifying absence.
- Video and manual watching are subsets of active time, never extra time added to it.
- A continuous absence counts at most once overall. In 3.0.0 it records one qualifying short/long cycle break; historical 2.2.5 totals retain their independent eye/movement meaning.
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

- Idle detection reads elapsed time since input, not keys or text; no Input Monitoring permission. The 3.0.0 typing option adds one aggregate keyboard elapsed-time query per timer tick when enabled. It defaults off, stores no key identity, content, event counts or typing history, and delays a pending reminder for at most 30 monotonic seconds per due work cycle. Missing or invalid timing does not delay it.
- Video detection reads known macOS video power assertions transiently; it does not inspect browser pages or screen pixels. Signals vary by player and playback state.
- Camera checks query whether a device is running; no capture session is started. Shared Focus uses the public macOS API and may be unavailable.
- M8's off-by-default audio-input option reads only public active input-stream flags, including microphones and virtual input devices. No audio content, device name or process identity is requested. It does not prove a meeting, speech, muting or presence. Output-only device activity is not used as microphone evidence.
- M8's optional native full-screen option reads only the active macOS presentation flag. It does not read window lists, titles, dimensions or screen contents, and does not infer maximized windows, borderless games or other displays.
- M8's optional selected-app option matches only an explicitly chosen exact frontmost bundle identifier. The picker reads app metadata through existing user-selected file access; no app is launched, loaded or monitored in the background and no bookmark is retained.
- These M8 signals only quiet alerts and sounds; normal activity/inactivity counting continues. Five-second polling and the existing 60-second quiet-return interval apply. Unavailable status supplies no new quiet reason. Automatic screen-sharing detection is deferred; manual Presentation remains available. See [M8 quiet signals](M8_QUIET_SIGNALS.md) for verification limits.
- Lock and sleep stop counting. A video playing unattended cannot be distinguished from a person watching it.
- Optional native notifications require permission. The app uses no push service.
- Weekly summaries are separately opt-in, quiet, at most weekly with sufficient data, and contain no usage figures on the lock screen. A failed send attempt also consumes that week's interval. No service runs while the app is closed.
- macOS may create system crash logs independently of Molaway.
