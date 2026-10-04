# M6 usability follow-up (not shipped)

## Scope — 2026-10-04

This focused macOS follow-up starts from main `5f7d1a9`, where M6 and accessibility PR #12 are merged. The M6 readiness report remains in [PR #13](https://github.com/boorkymoorky/molaway/pull/13). Windows [PR #2](https://github.com/boorkymoorky/molaway/pull/2) and unfinished local Windows work remain separate. This work does not start M7 or publish a release.

## Changes

- The menu-bar title shows only the countdown. Break kind remains available in the tooltip/accessibility value and dashboard.
- Pause and other state symbols replace the tiny menu-bar rings instead of being drawn over them. Normal tracking still shows the progress rings; overdue colors and named accessibility information remain.
- Dashboard labels and a larger countdown sit below the rings in a full-width text block, avoiding the narrow ring center in both languages.
- Notification permission errors have a distinct session-only state instead of continuing to say “Not requested.” Refreshes preserve a failed request while macOS still reports an undetermined permission; successful permission changes clear it. Duplicate requests and stale refresh results are guarded. Raw system error text is not displayed or stored.
- When a request fails, an explicit button selects the existing Small card alert style. The app never silently changes the selected style or grants itself permission.

The accepted pointer VoiceOver behavior is unchanged: one low-priority localized announcement per visible countdown, with no announcement on each second. No new network access, entitlement, permission, dependency, stored history, or release metadata was added.

## Verification

- All 150 Swift tests in 16 suites passed, including six notification permission regressions, two rendered-image checks (visible state images and two distinct pause bars), and a clock-only readout check for both break kinds and work/rest states. Existing M1–M6 tests still pass.
- Release build, ad hoc signature verification, and the isolated fresh/update/failure-path installation checks passed. No personal installation was replaced.
- The source security and tracked publication guards passed. These guards are scoped checks, not an independent security audit.
- The complete application was inspected using a separately identified, re-signed test copy with isolated settings. Turkish long-break and English short-break dashboards were visibly readable with labels below the rings. This is a limited UI check, not coverage of every display, appearance, duration, or accessibility setting.
- In the actual app, the permission button called macOS but received `UNErrorDomain` / `notificationsNotAllowed`. No permission prompt appeared. The updated UI showed “Could not request permission” and a localized explanation in TR/EN; tab changes and refresh did not replace it with “Not requested.” The Small card button selected that style and opened its alert settings. This establishes the request-failure and style-selection flows, not notification or panel delivery.

## Notification limitation and release readiness

Native notification authorization remains blocked for the tested ad hoc-signed application copy. The exact signing/registration or system cause is not established; do not generalize the result to every installation or infer that a new entitlement would fix it. Apple's [error reference](https://developer.apple.com/documentation/usernotifications/unerror/code/notificationsnotallowed) describes the authorization failure, not this machine's cause. No system permissions were reset, security protection bypassed, signing account changed, or push capability added.

Native permission prompt, notification delivery and action timing remain **not verified**. Small card, Top panel and Full screen are existing alternatives that require no notification permission; physical delivery checks remain distinct from selecting a style.

Release readiness is still **pending**. The full-app checklist in the M6 report remains open: visible-badge pause/preview/quiet/Office Hours/rest transitions; direct badge click-through and Reduce Motion; display edges/disconnect/reconnect; Spaces/full screen; measured lock/sleep; Turkish VoiceOver speech and manual TR/EN badge-text navigation. Quit/reopen has a partial user observation, with a cadence transition still requiring a controlled repeat. Earlier harness results do not close these rows.

The owner confirmed that the menu-bar icon itself was absent after manual pause in the initial follow-up build `c3575f9`. The process remained running and the settings retained the manual pause. A standalone bitmap check of the original symbol did not reproduce the absence, so the exact AppKit/menu-bar cause is unestablished. The follow-up uses a stable 20-point drawable canvas with two pause bars, explicitly selects image-only layout when the clock is hidden, and reserves a 28-point menu-bar slot. In the complete updated app built from `0191f78`, the owner confirmed that the paused menu-bar icon was visible and clicking it opened the dashboard. This is one user-operated check under the isolated test identity; the initial failure remains recorded above. Resume/re-pause repetition and other menu states remain pending. Full dashboard keyboard/VoiceOver traversal, maximum countdown lengths, all appearance/display layouts and broader supported-system behavior also remain unclaimed. Keep these limits visible before any release decision.
