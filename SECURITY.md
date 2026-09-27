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

Use **Security → Advisories → Report a vulnerability** on this repository to send a private report to the maintainer. Include the affected version, a minimal reproduction with synthetic data, the expected impact, and any suggested fix. Do not include real credentials or personal files.

If the private reporting button is unavailable, do not post exploit details in a public issue. A public issue may ask the maintainer to enable private reporting, without disclosing the vulnerability. There is no published contact email. This is a personal project; response times are not guaranteed.

The current 2.2 release line is the intended maintained line. Support begins when the repository/release is actually published. Earlier local builds have no promised maintenance window.

## Verification

`Scripts/verify-security.py` checks a narrow set of source/release invariants. It is not a penetration test. Functional tests include settings attacks, stale/pending reminder behavior and display geometry. See VERIFICATION.md for actual results and untested scenarios.

Developer ID signing/notarization is a separate distribution step. Do not disable Gatekeeper to install this project. Signing keys must never be committed or made available to pull-request CI runs.

## Windows development preview

The macOS sandbox guarantees above do not apply to `Windows/`. The Windows preview is a standard-user, unpackaged WPF desktop app with no OS-enforced network sandbox. Its source makes no network requests and requests no elevation, screen/key/media-content capture, camera or microphone access. It reads session idle duration and supported playback state. Local JSON files are size-bounded, values validated, linked paths refused and writes replaced atomically. Optional summaries default off and retain up to 90 days. No telemetry, automatic update, startup registration or registry write is included. It is not a stable or fully security-reviewed Windows release; see `Windows/PLAN.md` for the physical verification gate.
