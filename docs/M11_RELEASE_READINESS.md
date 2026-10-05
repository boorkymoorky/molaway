# M11 macOS verification and release preparation

Current follow-up: the owner explicitly authorized regular **3.0.0 / build 11** publication on 2026-10-05, superseding the earlier beta-only decision. See [release authorization and notes](MACOS_3_RELEASE.md). M11 evidence below is historical; the physical gaps remain unverified.

## Scope and outcome — 2026-10-04

M11 starts from main `762131604067be20d975dd4e4eb97572db94eca5`, after [M10 PR #20](https://github.com/boorkymoorky/molaway/pull/20) and its [main verification](https://github.com/boorkymoorky/molaway/actions/runs/37224825683) passed. It adds integrated M1–M9 regression coverage and a repeatable offline built-bundle guard, and prepares the release handoff. It changes no application feature, English/Turkish text, entitlement, dependency, version or published asset. Windows PR #2 and local Windows work remain separate.

**Automated verification and release preparation are complete within the evidence below; release readiness remains pending.** The published download and Homebrew cask still contain 2.2.5, without M1–M9 development changes. Development bundle metadata is still 2.2.5/build 10; a main build with that metadata is not the published 2.2.5 asset or an approved release candidate. No future version is assigned, tag created, GitHub release drafted/published or tap version changed by M11.

The maintainer’s policy remains daily-use feedback with structured physical checks deferred. This review does not restart that checklist or treat deferred checks as passed. M10’s original quarantined first launch remains independently pending; the end-user tap command stays withheld.

## Automated evidence

| Area | Evidence | Limits |
| --- | --- | --- |
| Baseline | All 199 existing Swift tests in 19 suites passed from the starting main snapshot. | Deterministic/component coverage, not physical OS behavior. |
| Integrated development lifecycle | Three new AppContainer composition regressions; the full suite passed **202 tests in 20 suites**. | Injected wall/monotonic time, quiet readings and disposable synthetic files; no app launch or real notification/device transition. |
| Build and original signature | Release-mode Apple Silicon build and native deep/strict signature verification passed locally. | Ad hoc hardened runtime, without Developer ID/notarization. A successful build is not approval to distribute. |
| Built-bundle guard | Metadata matches reviewed source; arm64 executable, macOS 15 target, original MIT license, exact sandbox/user-selected-file entitlements, hardened runtime and original EN/TR resources verified. All **372** keys and current format placeholders match. Eight negative fixtures were rejected. | Targeted packaging invariants and a personal-home-path pattern check, not a comprehensive binary/secret/security audit or translation/accessibility judgment. |
| Source/publication/distribution guards | Source privacy guard, curated publication guard and offline pinned cask/download consistency passed. | The distribution guard still verifies 2.2.5; no new online asset or first-launch claim. |
| Local installer | The existing running-Molaway guard stopped local installer verification. The personal app was left running. | This is a protected refusal, not a local installation pass. Clean-environment installer evidence is recorded separately below. |
| Hosted verification | [PR #21](https://github.com/boorkymoorky/molaway/pull/21) [Verify run 37226017129](https://github.com/boorkymoorky/molaway/actions/runs/37226017129) passed source/publication/distribution guards, tests, build, bundle self-tests and isolated installation/update/failure checks at `f378f2b`. | A clean CI runner verifies installation paths without touching the personal app. It does not verify interactive Gatekeeper approval or original first launch. The required check must also pass for the final PR head before merge. |

### Integrated regression scenarios

- A confirmed work cycle reaches the pointer-countdown boundary, then overlapping audio/fullscreen/selected-app quiet signals hold the due reminder. After the last signal ends, the 60-second quiet return and one 30-second typing budget precede the five-second Balanced skip gate. Skip resolves one unsuccessful opportunity without advancing cadence; subsequent completed short and long breaks produce 2/3 opportunities (67/100) and reset long-break cadence.
- A due quiet reminder crosses Office Hours closure, manual pause and an overnight suspension. Opening the next selected work period does not clear manual pause, accrue off-hours work, invent a natural break or penalize the unresolved opportunity. Resuming and completing the requested rest credits that opportunity once.
- A synthetic 2.2.5-era settings/statistics fixture migrates to the cycle model without enabling summary recording or new opt-in sensors. After explicit opt-in and a completed short rest, reopening preserves cadence, language, independent manual/Office Hours pauses and old eye/movement totals, without fabricating historical scores. Settings backups exclude score data and live cadence.

These scenarios use the unchanged application code. They are not a replay of personal settings, usage or logs. Existing tests retain coverage of all reminder styles, skip modes, timing/pause/calendar bounds, hostile settings/statistics, display geometry, cursor accessibility metadata and score consent/retention.

### Repeatable checks

```sh
swift test
python3 Scripts/verify-security.py
python3 Scripts/verify-publication.py --tracked
python3 Scripts/verify-distribution.py
bash Scripts/build-app.sh
python3 Scripts/verify-bundle.py --self-test
python3 Scripts/verify-installation.py
```

The bundle guard reads only the specified built app and reviewed resources. It never launches or installs an app and makes no network requests. Its self-test uses disposable tables/bundle copies, including a separately ad hoc signed fixture with a forbidden network entitlement, solely to confirm rejection. It does not change production permissions or bypass first-launch security. CI runs it after the build and before the existing isolated installer checks. Do not bypass the installer’s running-app guard to obtain a local pass.

## Physical evidence remains separate

| Area | Current status |
| --- | --- |
| Complete-app countdown transitions, restart/pause persistence, displays/Spaces and sleep/lock | Partial historical observations and automated regressions; remaining full-app cases stay unverified in [M6 readiness](M6_READINESS.md). The earlier cadence observation is not declared explained by these new synthetic tests. |
| Native notification delivery/actions and all alert-style keyboard/VoiceOver flows | Earlier permission approval is recorded; delivery/action timing and full accessibility traversal remain unverified. |
| Turkish countdown speech and manual VoiceOver access | Unverified; the previously accepted single-announcement policy is unchanged. |
| Positive audio-input/fullscreen/foreground transitions | Query availability/limited interface observations only; [M8 limits](M8_QUIET_SIGNALS.md) remain. Automatic sharing and microphone-only classification remain deferred. |
| Real multi-day Screen Score and daily summary experience | Automated/limited layout evidence only; [M9 limits](M9_SCREEN_SCORE.md) remain. |
| Original Homebrew download’s Gatekeeper approval and first launch | Deferred at the maintainer’s request; [M10 gate](M10_DISTRIBUTION.md) remains. Installer checks do not close it. |
| Intel, oldest supported OS, all display/player combinations and sustained energy use | Unverified; Apple Silicon-only distribution and existing honest limits remain. |

No new physical-test session is requested by this preparation. Daily-use failures should be reproduced and fixed in focused PRs with relevant regressions; update only the evidence actually established. A future distribution decision must address the unresolved readiness items explicitly rather than treating this automated pass as physical verification.

## Post-merge evidence and decision draft — 2026-10-04

[PR #21](https://github.com/boorkymoorky/molaway/pull/21) merged at `39e7d8dbf5089fe04632d5f29aca57e864e1a834`. Its final head `fbda4c203ffee047e42c76726da43a336e0d7af9` passed [Verify run 37226345150](https://github.com/boorkymoorky/molaway/actions/runs/37226345150), and the merged main passed [Verify run 37226551952](https://github.com/boorkymoorky/molaway/actions/runs/37226551952). Both passed every verification step, including isolated installation/update/failure checks. This closes the final-head/main CI follow-up, not the physical readiness gaps.

The [post-M11 decision and release-notes draft](MACOS_RELEASE_DECISION.md) recommends keeping publication on hold, with `3.0.0-beta.1`/build `11` proposed only for a later separately approved opt-in prerelease. It records version rationale, open evidence, migration/downgrade risks and future candidate/publication gates. No version is assigned or GitHub release draft created; stable readiness, M6's deferred checks and M10's independent first-launch gate remain pending.

## Prepared release handoff

[CHANGELOG.md](../CHANGELOG.md) has a clearly labeled **Unreleased development** section summarizing M1–M9 and M11. README screenshots, download instructions, user-facing feature claims and the tap remain scoped to the actually published 2.2.5 app.

Before any future app release:

1. Obtain an explicit publishing decision and decide the new version/build on a focused branch. Use a new version; do not replace the existing 2.2.5 ZIP with different main-source bytes. Preserve the bundle identity for local settings compatibility and state the migration/downgrade limits.
2. Review outstanding physical evidence and the intended release status/claims. Preparation does not silently waive those gaps. Keep unperformed checks unverified and keep signing/support limits clear.
3. Run the full checks above and the protected PR workflow for the exact intended source revision. A signed development build is not the old release asset; confirm final version/build, architecture, license, localization and entitlements before packaging.
4. Prepare versioned app/source archives and `SHA256SUMS.txt` from that reviewed revision. Inspect their public contents for private data and review release notes. Do not include local settings, summaries, raw logs, caches, credentials, signing material or machine paths.
5. Publish only after the separate publishing decision. Then download the actual new public ZIP and compare its computed hash with its checksum file and GitHub digest, inspect the extracted original signature/architecture, and update public claims/download links only to shipped behavior.
6. Update the tap through its protected PR workflow only after that real asset verification. Repeat the appropriate isolated lifecycle checks; retain quarantine and manual updates. Complete the separate original-app first-launch gate before publishing end-user tap instructions.

No updater, app networking, broad permission, private API or privileged helper is part of this handoff. Windows readiness follows its own preview plan and is not advanced by M11.
