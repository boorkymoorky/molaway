# Changelog

## Unreleased

- Count a manually started short or long break from its actual start, including when it begins between countdown refreshes or before the first poll. The first rest countdown no longer includes time spent before the break, and the break cannot finish early for that reason. This follow-up is not included in the published 3.0.1/build 12 download.

## 3.0.1 — 2026-10-05

[3.0.1](https://github.com/boorkymoorky/molaway/releases/tag/v3.0.1), build **12**, is the current regular release and latest direct download. [Release evidence](docs/MACOS_3_0_1_RELEASE.md). Homebrew remains pinned to 2.2.5 with its first-launch gate pending.

- Rephase the existing macOS timer after countdown-second boundaries so normal permitted timer jitter does not repeat a displayed second and then skip the next one. Keep real elapsed-time accounting, pause/rest semantics and the existing sensor gate; genuine main-thread stalls still catch up honestly. Build 12 contains the fix; the existing 3.0.0 assets remain unchanged. Protected release checks and actual public-package verification passed.

## 3.0.0 — 2026-10-05

[3.0.0](https://github.com/boorkymoorky/molaway/releases/tag/v3.0.0), build **11**, is a regular macOS release published at the owner's explicit request. The prepared beta was never published. 3.0.0 became the latest direct download before the subsequent 3.0.1 patch. Homebrew separately remains pinned to 2.2.5 with its first-launch gate pending. [Release evidence and notes](docs/MACOS_3_RELEASE.md) retain migration/downgrade and physical verification limits. A regular release does not establish unperformed physical checks.

- Use one work/short/long break cycle, with approximate migration from independent eye/movement timing and a reversible Deep Focus preset. Rings show work/rest progress and completed-short cadence.
- Add shared manual pause options and optional Office Hours, including overnight schedules and independent pause reasons.
- Add Casual/Balanced/Hardcore skip behavior across reminder surfaces and an optional cursor countdown with one localized announcement per visible countdown.
- Share Smart Pause decisions, with off-by-default typing deferral capped at 30 seconds. Add optional audio-input, active native fullscreen and explicitly selected foreground-app quiet signals within documented public APIs; automatic sharing and broader detection remain deferred.
- Add an explainable Screen Score to opted-in bounded daily summaries, resolving each confirmed full-cycle opportunity once. Historical days and unresolved/early breaks do not fabricate outcomes.
- Stop source installation if the running-process query is unavailable.
- Add integrated lifecycle/migration regressions and offline built-bundle, signing, permission and English/Turkish resource checks to CI.

The Molaway-owned Homebrew tap currently distributes only the existing 2.2.5 asset. Its isolated installation lifecycle is verified; original first launch after normal Gatekeeper approval remains pending. Molaway stays offline, manually updated and permission-minimal.

## 2.2.5 — 2026-09-26

- Snooze gives both break reminders at least five active minutes of quiet, so another timer cannot interrupt earlier. Later deadlines stay unchanged.
- Clear pending delivery retries when snoozing; repeated snoozes start a fresh five-minute period.
- Explain the macOS unnotarized-app warning and the per-app first-launch steps.

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
