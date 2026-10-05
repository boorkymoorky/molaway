# Security policy

Molaway is a local macOS break reminder. It does not claim to be vulnerability-free.

## Boundaries

- App Sandbox and hardened runtime; no network client/server, camera, microphone, Apple Events or input-monitoring entitlements.
- User-selected file read/write is used only for settings import/export and reading metadata for explicitly chosen apps. No persistent security bookmarks or general disk access.
- No privileged helper, downloaded code, plugins, updater, analytics, server, account or browser integration.
- Activity queries read idle duration and transient OS state. The 3.0.0 opt-in typing deferral reads only aggregate time since keyboard activity; no event tap/monitor, key identity or event count is used. Its in-memory delay is bounded to 30 seconds per due cycle. No keyboard contents, URLs, titles, screenshots or captured media are stored.
- Optional camera checks inspect device running state; no capture session. Focus sharing uses the supported Intents API with explicit authorization and handles unavailable status.
- The 3.0.0 M8 options read public audio input-stream running flags, the active native full-screen presentation flag, and an exact selected-app/frontmost match. They default off and only quiet alerts. No audio IO, process tap, screen/window-content query or new permission is added. Audio input includes virtual devices and is not proof of a meeting. Automatic screen-sharing and broader fullscreen inference are deferred. Only up to 32 explicitly chosen app bundle identifiers persist as preferences (including settings backups), never observed app use, names or paths. Live states are transient; failed queries provide no new quiet reason. See `docs/M8_QUIET_SIGNALS.md` for scope and verification limits.
- Imported JSON is capped at 64 KiB, schema/field/type checked, and values bounded. Symlinks and non-regular input files are rejected. Imported settings cannot grant permissions.
- Local preferences persist. Daily aggregates are OFF by default and require explicit opt-in within the app. They are never included in settings import/export. The bounded, versioned statistics file contains only dates and daily totals, not per-event times or app/site identity. Reads reject symlinks, nonregular files, invalid/duplicate days and files over 512 KiB. Writes validate the document, create an exclusive 0600 temporary file and atomically replace the destination. Corruption stops recording until an explicit reset; it is not silently overwritten. Retention is 30 or 90 days and deletion is available in the app. OS backups may retain prior copies. Errors avoid raw paths and system-state dumps. OS crash logs may exist independently.
- 3.0.0 extends optional daily summaries with bounded completed/resolved opportunity counts only. Eligibility and pending state stay in memory; legacy summaries have no fabricated score. Existing consent, retention, deletion, file bounds and settings-backup separation apply. No sensor, permission, dependency or network capability is added. See `docs/M9_SCREEN_SCORE.md`.
- A separate local pause file holds only the current manual choice and optional deadline for relaunch recovery. It has no history, is excluded from settings export, and is removed when manual pause ends. Reads are bounded and reject symlinks and nonregular files.

The operating system, apps chosen by the user and the user's account are outside this boundary. Sandbox is defense in depth, not a promise against every local attack. A compromised administrator account or OS is outside the supported threat model.

## Reporting a vulnerability

Use **Security → Advisories → Report a vulnerability** on this repository to send a private report to the maintainer. Include the affected version, a minimal reproduction with synthetic data, the expected impact, and any suggested fix. Do not include real credentials or personal files.

If the private reporting button is unavailable, do not post exploit details in a public issue. A public issue may ask the maintainer to enable private reporting, without disclosing the vulnerability. There is no published contact email. This is a personal project; response times are not guaranteed.

3.0.1 is the current macOS release and default direct download; the tap separately remains on 2.2.5. Older 3.0.0 and 2.2.5 packages remain available. This personal project promises no maintenance window. Regular publication does not close the physical verification gaps documented in VERIFICATION.md and docs/MACOS_3_0_1_RELEASE.md.

## Verification

`Scripts/verify-security.py` checks a narrow set of source/release invariants. It is not a penetration test. Functional tests include settings attacks, stale/pending reminder behavior and display geometry. See VERIFICATION.md for actual results and untested scenarios.

Developer ID signing/notarization is a separate distribution step. Do not disable Gatekeeper to install this project. Signing keys must never be committed or made available to pull-request CI runs.
