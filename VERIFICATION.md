# Verification

## 2.2.2 local checks — 2026-09-25

- 108 tests in 10 suites passed, including eight new lifecycle regressions using isolated local test data.
- Covered: due while away, automatic return, explicit Continue, uncounted manual-rest rollback, return on the completion tick, and sleep without an intervening timer tick.
- The installed release opened successfully; the manual break → Continue flow visibly restarted the eye timer at 20:00.
- The local source installer was exercised. Signature verification passed and the installed sandbox probe returned `networkDenied=true`.
- Publication review covered tracked files, all 90 unique historical file blobs before this update, commit authors, scripts, permissions, and image metadata. No credentials, private email addresses, local home paths, or private network addresses were found by the targeted checks. Commit email uses GitHub noreply.
- Historical icon EXIF contained only color-space and image dimensions. The current source PNG has that metadata removed. The unused upstream website and icon are removed from the current tree; they remain in historical commits and contain no identified personal secrets.
- Build bundles are excluded from Spotlight indexing; old test/distribution bundles were removed and one installed Molaway remained in the Spotlight query.
- These results do not replace independent review or real-world testing of every sleep/video/monitor combination.

## GitHub verification — 2026-09-25

- [Verify run #2](https://github.com/boorkymoorky/molaway/actions/runs/36090875946) succeeded for code commit `a8027c8` on the macOS 26 runner using Swift 6.3.3.
- The workflow passed source/publication guards, tests, release build, and signature verification. The link requires repository access while the project remains private.
- The first run encountered a Swift compiler crash while converting an actor-isolated method to a binding setter. An explicit closure resolved it; no test was removed or disabled.

## 2.2.1 local checks — 2026-09-24

- 100 tests in 9 suites passed, covering timers, idle rollback, natural/manual breaks, settings validation, data retention, hostile file inputs, calendar validation, and chart snapshots.
- 7/30/90-day charts and active/break/rest selections were exercised in a separate release preview with synthetic data.
- The 90-day and metric interactions completed with UI inspection in approximately 0.8–0.9 seconds. This includes automation overhead, not frame-time instrumentation.
- Thirty chart-data snapshots across all periods took about 0.022 seconds in a local test. This measures preparation only, not chart rendering.
- The previous nested 90-day preparation pattern took about 167 seconds in an isolated reproduction. This is evidence of the removed repeated work, not an end-to-end benchmark of the old app.
- English screenshots use synthetic daily totals and only app windows. Screenshot metadata is removed for publication.
- The user confirmed both dashboard and Settings opened on the second monitor. Display disconnect/reconnect and every Space arrangement still need physical testing.

## Security checks

- Targeted source guard verifies expected sandbox/file entitlements and flags selected network/capture APIs and credential patterns.
- A separate publication guard checks the curated copy for private data files, local paths, common secret patterns, and image metadata.
- Release signature verification passed. The 2.2.1 release probe returned `networkDenied=true`; no network/capture entitlement was added.
- These checks do not constitute an independent security audit or prove absence of vulnerabilities.

## Prior verified behavior

- Daily summaries default off, remain separate from settings import/export, and are created only after opt-in.
- Synthetic weekly-report delivery and cancellation after opt-out were verified in a separate preview.
- The sandbox network probe previously returned `networkDenied=true`; it attempts a loopback connection without sending data.
- Native alert fallback/error handling, quiet modes, and supported video signals have local test coverage. Universal player support is not claimed.

## Not yet verified

- Long-term use, battery/GPU/WindowServer impact, every accessibility contrast and VoiceOver flow.
- All monitor/Space arrangements, physical sleep/lock/restart scenarios, all cameras/meeting apps, and available shared Focus configurations.
- Intel and every supported macOS version.
- Apple Developer ID signing and notarization. Current packages are ad hoc signed.

No identifying machine inventory, personal usage data, raw logs, local file paths, credentials, or signing materials are included in this report.
