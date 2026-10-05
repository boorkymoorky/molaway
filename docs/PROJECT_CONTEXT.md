# Molaway project context

This file gives new Codex chats the durable context needed to continue Molaway without replaying the full development conversation. It intentionally omits private data and short-lived implementation notes.

## Product intent

Molaway helps people follow a planned short/long break cycle without manual timer restarts. The current 2.2.x release still uses independent eye and movement timers. It should recognize active use, pause after real inactivity, continue through supported video playback, and use reminders that can be noticeable without taking over the screen. The experience should feel native, calm, accessible, and predictable across multiple displays.

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

The default public download and Homebrew tap remain **2.2.5**, with independent eye/movement timers. The owner has explicitly authorized a separate regular **3.0.0 / build 11** release instead of the prepared beta. Publication follows final protected PR/CI and exact package checks; see `docs/MACOS_3_RELEASE.md`. No beta has been published. 3.0.0 uses one work/short/long cycle, changed ring meanings, shared pauses/Office Hours, bounded optional quiet signals and Screen Score. Settings migration is approximate; 2.2.5 cannot read schema 3 and app replacement is not a complete rollback. Keep the default download/tap on 2.2.5 unless separately instructed.

Distribution is Apple Silicon, ad hoc signed and unnotarized. Intel, oldest supported macOS, all player/display/lifecycle combinations and sustained energy use are not claimed verified. The regular release designation does not close physical gaps. M6 structured checks stay deferred under daily-use feedback; M10 original quarantined first launch stays pending and end-user tap instructions remain withheld. Do not launch an original-identity test copy over the personal session. See `VERIFICATION.md`, `docs/M6_READINESS.md` and `docs/M10_DISTRIBUTION.md`.

Protected PR #23 and merged main passed 202 tests in 20 suites, bundle checks for 372 unchanged EN/TR keys, eight negative fixtures and isolated installer checks. The source installer now refuses an unavailable process list. The release revision needs its own final checks; CI does not establish physical readiness. App behavior, permissions and local data remain unchanged by this publishing work.

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

After a planned job is complete, hand off the full next-job prompt and model/effort and suggest a new chat. Keep same-job fixes in this chat.
