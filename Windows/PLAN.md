# Windows delivery plan

## Scope and isolation

- Develop on macOS in the `feat/windows-preview` branch, under `Windows/`.
- Leave the shipping macOS source and release untouched.
- Implement a native WPF/.NET 10 Windows 11 preview. Reuse behavior and regression scenarios, not macOS platform APIs.
- Use framework APIs only, bounded local files, least-privilege execution, no telemetry or capture.
- Keep Windows limitations explicit; an unpackaged WPF app does not inherit the macOS network sandbox.

## Mac-side work

1. Deterministic scheduler and activity accounting, tested directly on macOS.
2. Native Windows tray, settings, reminders, monitor placement and playback-status adapters.
3. English/Turkish interface, accessibility labels, keyboard dismissal, system/high-contrast support.
4. Cross-build and prepare a portable x64 preview, with upstream notices.
5. Source/privacy checks and Windows CI for build, scheduler tests and a synthetic WPF smoke test.
6. Review and merge through the protected-branch pull-request process. Do not mark a Windows release stable.

## Windows handoff gate

A real interactive Windows session is needed for:

- Install/extract/first launch under a standard user, Defender/SmartScreen, clean exit and replacing an old build.
- Tray placement, notification buttons, repeated snoozes, natural absence and manual-rest return.
- Lock/unlock, real suspend/resume, display disconnect, mixed-DPI multi-monitor placement, virtual desktops.
- Chrome/Edge/local-player playback, paused/audio-only/unsupported sessions and manual watching fallback.
- Windows notification availability and Do Not Disturb; camera/meeting detection is deferred until a reliable permission-minimal API is validated.
- Narrator, high contrast, scaling, keyboard-only navigation and sustained CPU/memory measurements.

## Later parity work

Only after the preview is validated: camera/meeting suppression if reliable, startup registration, richer monthly/comparison charts and summary notifications, state-specific sounds, installer/signing, Microsoft runtime/SDK binary distribution review and an explicit update strategy. Never silently turn on network access or broaden permissions to gain parity.

## References

- [Cross-building Windows targets](https://learn.microsoft.com/en-us/dotnet/core/tools/sdk-errors/netsdk1100)
- [Elapsed input time](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getlastinputinfo)
- [System media sessions](https://learn.microsoft.com/en-us/uwp/api/windows.media.control.globalsystemmediatransportcontrolssessionmanager)
- [Notification availability](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryusernotificationstate)
