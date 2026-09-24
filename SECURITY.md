# Security policy

Molaway is a local macOS break reminder. It does not claim to be vulnerability-free.

## Boundaries

- App Sandbox and hardened runtime; no network client/server, camera, microphone, Apple Events or input-monitoring entitlements.
- User-selected file read/write is used only for settings import/export. No persistent security bookmarks or general disk access.
- No privileged helper, downloaded code, plugins, updater, analytics, server, account or browser integration.
- Activity queries read idle duration and transient OS state. No keyboard contents, URLs, titles, screenshots or captured media are stored.
- Optional camera checks inspect device running state; no capture session. Focus sharing uses the supported Intents API with explicit authorization and handles unavailable status.
- Imported JSON is capped at 64 KiB, schema/field/type checked, and values bounded. Symlinks and non-regular input files are rejected. Imported settings cannot grant permissions.
- Local preferences persist. Daily aggregates are OFF by default and require explicit opt-in within the app. They are never included in settings import/export. The bounded, versioned statistics file contains only dates and daily totals, not per-event times or app/site identity. Reads reject symlinks, nonregular files, invalid/duplicate days and files over 512 KiB. Writes validate the document, create an exclusive 0600 temporary file and atomically replace the destination. Corruption stops recording until an explicit reset; it is not silently overwritten. Retention is 30 or 90 days and deletion is available in the app. OS backups may retain prior copies. Errors avoid raw paths and system-state dumps. OS crash logs may exist independently.

The operating system, apps chosen by the user and the user's account are outside this boundary. Sandbox is defense in depth, not a promise against every local attack. A compromised administrator account or OS is outside the supported threat model.

## Reporting a vulnerability

When this repository becomes public, the owner must enable GitHub Private Vulnerability Reporting and verify the private “Report a vulnerability” link. That feature is available for public repositories. Until then, do not publish vulnerability details; there is no advertised public reporting channel. Once enabled, use that private channel for details. Do not put credentials, personal data or unpatched exploit details in a public issue. No contact email is invented or embedded in this repository.

The current 2.2 release line is the intended maintained line. Support begins when the repository/release is actually published. Earlier local builds have no promised maintenance window.

## Verification

`Scripts/verify-security.py` checks a narrow set of source/release invariants. It is not a penetration test. Functional tests include settings attacks, stale/pending reminder behavior and display geometry. See VERIFICATION.md for actual results and untested scenarios.

Developer ID signing/notarization is a separate distribution step. Do not disable Gatekeeper to install this project. Signing keys must never be committed or made available to pull-request CI runs.
