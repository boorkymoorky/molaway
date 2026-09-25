# Changelog

## 2.2.4 — 2026-09-25

- Honor an explicit five-minute snooze when another timer becomes due; merged reminders cannot shorten or restart that snooze.
- Exclude short sleep intervals between timer ticks from working time.
- Add regressions and an eight-hour simulated mixed-use schedule.
- Verify fresh installs, replacements, damaged packages and unsafe destinations in isolated installer checks, also run in CI.

## 2.2.3 — 2026-09-25

- Name the eye/movement timer in the menu bar countdown and show the same next reminder in the dashboard.
- Use a shared timer readout to keep dashboard and menu countdown semantics consistent.
- Add three regressions for snoozing followed by manual/natural rest and independent eye/movement resets.
- Clarify that update checks are manual and the app stays offline.

## 2.2.2 — 2026-09-25

- Show a live countdown to deferred reminders instead of leaving timers on “Now”.
- Explicit Continue starts a fresh interval; automatic early return keeps work progress with a five-minute deferral. Unfinished rests do not count as completed.
- Clear stale queued reminders after natural rest and sleep; end an active rest safely when the display/session suspends.
- Do not treat manual rest as provisional work; a return on the completion tick completes the break.
- Add deterministic app lifecycle regression tests with isolated settings/statistics.
- Add a terminal source installer with no administrator access, downloads, or security overrides.
- Place build bundles in `build.noindex` to reduce duplicate Spotlight results.
- Remove the unused upstream website, external font/icon loads, and unrelated installation/signing claims. Upstream attribution and MIT license remain intact.
- Document unnotarized distribution honestly, with Apple's app-specific first-launch instructions.


## 2.2.1 — 2026-09-24

- Use an explicit weekly-summary binding closure for compatibility with the CI Swift compiler.
- Fix severe overview slowdowns: prepare chart data once per data/locale change, cache all periods, and use indexed daily lookups.
- Replace repeated date formatter construction with strict calendar parsing; keep invalid-date validation.
- Identify eye breaks as the outer ring and movement breaks as the inner ring in both timers and settings.
- Reflow the menu panel after display changes; keep Settings on its originating dashboard display.
- Add English project, installation, privacy, and attribution documentation with synthetic-data screenshots.
- Add a curated publication guard; exclude private data, local paths, build artifacts, and development history.

## 2.2.0 — 2026-09-24

- Optional local daily summaries, 7/30/90-day charts, comparisons, retention, and deletion controls.
- Separate opt-in weekly notifications without usage figures on the lock screen.
- Adjustable amber/red overdue indicators based on active delay and deliberate snoozes.
- Original shared two-ring app/interface/menu mark.
- Validated, bounded, owner-only statistics storage with atomic replacement.

## 2.1.0 — 2026-09-24

- Rename Mola to Molaway while retaining settings compatibility.
- Improve display placement, sidebar targets, editable durations, and resizable settings.
- Add reminder opacity, glass/solid surfaces, accessibility-aware transitions, and hover behavior.
- Use one pause indicator, add a context menu, and tolerate accidental mouse movement during rest.
- Show notification-delivery problems and preserve pending reminders.

## 2.0.0

- Personal derivative of Offscreen with independent eye/movement timers, automatic activity handling, video support, watching/presentation modes, four reminder styles, display targeting, localization, sounds, permission explanations, sandbox restrictions, and validated settings transfer.
