# M7 Smart Pause (development, not shipped)

## Scope — 2026-10-04

This focused macOS change starts from main `5b54689`, after M6 notification prompt/approval was recorded in PR #15. M6's existing pointer countdown and accepted one-announcement VoiceOver policy remain unchanged. Structured physical checks are deferred at the owner's request; daily-use reports continue. Windows PR #2 and unfinished Windows work remain separate. M8 and publishing are outside this work.

## Behavior

Existing signals share a Smart Pause decision with two independent effects:

- Video and manual Watching mode override inactivity so work keeps counting. An opted-in running-camera signal retains its existing activity override and quiet-alert behavior.
- Opted-in camera/shared Focus and manual Presentation mode quiet alerts. Quiet alerts do not themselves freeze work; the normal inactivity rule still applies. The existing 60-second quiet-return period remains.
- Manual pause, Office Hours, sleep/lock and active rest take precedence under their existing M1–M6 rules. Unavailable camera/Focus readings do not invent activity or suppress reminders. No additional media/player, microphone, screen-sharing, fullscreen or focus-app detector was added.

The new **While typing** option defaults off. When a reminder is pending and otherwise eligible, keyboard activity within the last two seconds starts one delay budget. A two-second typing pause releases it; continuous activity can hold it for at most 30 monotonic seconds. The visible timer/status explains the temporary delay while work continues counting. Automatic waiting does not credit a break, change completed-short cadence, or increment deliberate snoozes.

Each due work cycle has one budget. Delivery retries, dismissal, snoozes, preview, quiet mode and overlapping pauses cannot refresh an active or consumed budget. A new work cycle following a completed/natural break, skip or reset may use another budget. The budget is transient and never restored across process launches. Manual rests and previews remain directly available.

## Privacy and failure behavior

The option queries only aggregate time since keyboard activity through Apple's public [elapsed-event-time API](https://developer.apple.com/documentation/coregraphics/cgeventsource/secondssincelasteventtype(_:eventtype:)). It reads no key code, character, typed text, event count, application identity or content. No event tap/global event monitor or new permission is used. Only the preference is persisted and included in user-requested settings backups; no timing/history is written.

Invalid/unavailable timing releases the reminder. A stale reading does not start a delay; even a continuously recent reading cannot exceed the 30-second budget. These are defensive rules, not proof that the OS query detects typing reliably in every app, input method, secure-input state or supported macOS version.

## Automated verification

- All 166 Swift tests in 17 suites passed. New coverage exercises the activity/quiet signal combinations; inactive, locked and manually paused precedence; opt-in defaults, migration and strict settings round-trip; typing pause, continuous typing, invalid/stale/missing readings, backwards time, repeated reminders, overlapping pauses and preview; manual rest/new-cycle behavior; long-break cadence and snooze preservation; and the common gate across all modes and reminder styles.
- Source/security and tracked publication guards passed. These are scoped checks, not an independent security audit.
- Release build, ad hoc signature verification and isolated fresh/update/failure-path installation checks passed. No release metadata, entitlement, dependency or application networking change.

## Limited installed-app UI observation

The normally installed app built from M7 source `51449db` opened successfully. UI automation inspected the Turkish Smart Pause/While typing settings and their visible layout; the new preference remained off and no user timing or signal preferences were changed. Local data files were unchanged immediately after installation, before launch resumed normal app writes. Only one Molaway app remained installed. The app's notification settings reported **Granted** after the update, consistent with the owner's earlier prompt/approval report. This does not establish notification delivery/actions, an English UI layout check, real typing detection or physical accessibility.

## Physical limits

Automated model/controller tests do not establish real typing detection or notification/panel delivery. Physical behavior during real typing, dictation, secure input, remote sessions, supported video players, camera/Focus, multi-display/Space changes, sleep/lock, keyboard/VoiceOver traversal and prolonged energy use remains unverified. Tests with synthetic time or injected elapsed readings are not full-app physical checks. Turkish/English resources are present; audible pronunciation and full keyboard traversal remain unclaimed.

M6's owner-confirmed notification prompt/approval and the later installed-app Granted status do not establish notification action/delivery timing. Earlier isolated-copy rejection remains historical with an unknown cause. Release readiness remains pending; no release is authorized by this change.
