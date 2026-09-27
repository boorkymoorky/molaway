# Molaway project context

This file gives new Codex chats the durable context needed to continue Molaway without replaying the full development conversation. It intentionally omits private data and short-lived implementation notes.

## Product intent

Molaway helps people take independent eye and movement breaks without manual timer restarts. It should recognize active use, pause after real inactivity, continue through supported video playback, and use reminders that can be noticeable without taking over the screen. The experience should feel native, calm, accessible, and predictable across multiple displays.

Privacy and security are product features. Molaway should work locally, request the least possible access, store only bounded optional summaries, and make limitations clear. It is not a medical device and should not make health or security guarantees that the evidence cannot support.

## Durable decisions

- Product name: **Molaway**.
- Maintainer and product owner: **Burak Yelkenci**.
- Origin: a personal derivative of Offscreen by Dayo Akinkuowo, retaining its MIT license and attribution.
- Development disclosure: built through vibe coding with ChatGPT/Codex; automated work must still be reviewed and tested.
- Purpose: personal, non-commercial, and open source. The MIT license still permits third-party commercial use.
- Communication with Burak is normally Turkish. Public GitHub material is English; the app is localized in English and Turkish.
- There is no paid Apple Developer membership for this project. macOS downloads are ad hoc signed and not notarized. Installation guidance must keep Gatekeeper enabled and describe only Apple's per-app approval flow.
- The app does not check GitHub for updates. Updates are manual so the released app stays offline.

## Current platform status

### macOS

The public macOS release line is **2.2.x**; the latest documented version in this checkout is **2.2.5**. It includes independent timers, idle/return handling, supported video detection plus manual watching mode, configurable reminder surfaces, multi-monitor placement, localization, sounds, optional local statistics, and overdue escalation. Use `CHANGELOG.md` as the version history and verify GitHub before publishing a newer release.

Distribution is Apple Silicon, ad hoc signed, and unnotarized. Intel and all player/display combinations are not claimed as verified. Release and security limitations are documented in `README.md`, `SECURITY.md`, and `VERIFICATION.md`.

### Windows

A separate native WPF/.NET Windows 11 preview is being developed under `Windows/` on feature work separate from the macOS release. Mac-side scheduler tests and cross-builds are useful, but a real Windows environment is required before calling it ready for daily use. The physical handoff checklist is authoritative in `Windows/PLAN.md`.

At the start of Windows work, inspect the current branch, working tree, pull request, and CI state. Do not assume this document captures unfinished edits.

## Product priorities

1. Correct timer, snooze, break, idle, sleep/wake, and return behavior.
2. Minimal permissions, local-only data, safe import/export, and honest public claims.
3. Calm native interface, clear dual-ring meaning, accessibility, and correct display placement.
4. Low CPU/energy impact and responsive statistics views.
5. Simple installation, transparent attribution, and maintainable releases.

## Completion standard

A change is complete when its user-visible behavior is coherent, relevant regressions are covered, privacy/security impact is reviewed, English and Turkish surfaces remain consistent where applicable, and documentation reflects only verified behavior. Physical platform checks remain explicitly pending when the current Mac cannot perform them.
