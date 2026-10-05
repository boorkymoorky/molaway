# Molaway project context

This file gives new Codex chats the durable context needed to continue Molaway without replaying the full development conversation. It intentionally omits private data and short-lived implementation notes.

## Product intent

Molaway helps people follow a planned short/long break cycle without manual timer restarts. The latest 3.0.2 release uses one work/short/long cycle; legacy 2.2.x used independent eye/movement timers. It should recognize active use, pause after real inactivity, continue through supported video playback, and use reminders that can be noticeable without taking over the screen. The experience should feel native, calm, accessible, and predictable across multiple displays.

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

The current regular release and latest direct download is **3.0.2 / build 13**, containing the manual-rest start fix and retained countdown alignment. Protected PR/main CI and actual public app/source/checksum downloads passed; see `docs/MACOS_3_0_2_RELEASE.md`. No beta was published. The 3.x cycle, ring meanings, shared pauses/Office Hours, bounded optional quiet signals and Screen Score first shipped in 3.0.0. Migration from 2.2.5 is approximate; 2.2.5 cannot read schema 3 and app replacement is not a complete rollback. Keep `docs/download.json` consistent with the public latest asset. The Homebrew tap independently remains **2.2.5**, and end-user commands stay withheld until M10 first launch passes.

Distribution is Apple Silicon, ad hoc signed and unnotarized. Intel, oldest supported macOS, all player/display/lifecycle combinations and sustained energy use are not claimed verified. The regular release designation does not close physical gaps. M6 structured checks stay deferred under daily-use feedback; M10 original quarantined first launch stays pending and end-user tap instructions remain withheld. Do not launch an original-identity test copy over the personal session. See `VERIFICATION.md`, `docs/M6_READINESS.md` and `docs/M10_DISTRIBUTION.md`.

The 3.0.2 release passed 213 tests in 21 suites, 372 unchanged EN/TR keys, original signature/entitlement checks, eight negative bundle fixtures and isolated installation checks. The existing timer is rephased after countdown-second boundaries and manual breaks count from their actual start; real elapsed-time bounds and sensor gating are preserved. No new dependency, permission or app networking capability is added. Publication was explicitly authorized; no personal installation was requested. Local installer verification kept the running-app refusal and clean CI passed isolated installer checks. Automated checks do not establish physical readiness.

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
