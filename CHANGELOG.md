# Changelog

## 2.2.1 — 2026-09-24

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
