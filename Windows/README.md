# Molaway for Windows — development preview

This is a separate native Windows implementation. The macOS app is unchanged.

- Target: Windows 11, x64 initially. No Windows release is declared stable yet.
- .NET 10 + WPF, with no third-party application packages or embedded browser.
- English/Turkish/system language; independent eye and movement timers; local preferences.
- Automatic idle pause/resume, natural rests, five-active-minute snooze for both reminders.
- Windows media-session playback signal and a timed manual watching mode.
- Tray rings, banner/card/full-screen/system reminders, display selection, optional sounds.
- Optional local daily summaries, off by default, retained for 90 days.

## Security and privacy

- Runs as the current user. No administrator prompt, service, driver or background installer.
- No network requests, telemetry, accounts, browser extension, global keyboard hook, screenshot capture, microphone/camera capture, media title or URL collection.
- Idle detection reads only elapsed time since input. Media handling reads only playback status exposed by participating apps; audio may also count. Unsupported players need manual watching mode.
- Data is stored under the current user's Local Application Data, in `Molaway/Windows`. No app usage history or window titles are stored.
- Unlike the macOS build, this unpackaged desktop preview does **not** have an OS-enforced network sandbox. Offline behavior is an implementation property, not a Windows isolation guarantee.
- The Windows notification-availability signal is not a promise of complete Do Not Disturb detection. Manual quiet mode is available. Camera/meeting detection is not implemented in this preview.
- No signing certificate, automatic updater, startup registration or registry modification. Unsigned downloads may trigger SmartScreen. Do not disable Windows security protections.

## Build

Install the .NET 10 SDK from Microsoft, then from the repository root:

```sh
dotnet run --project Windows/Molaway.Core.Tests -c Release
dotnet build Windows/Molaway.Windows -c Release
```

A non-Windows machine can build with `EnableWindowsTargeting`; it cannot run the UI. The project sets that property. Restore downloads Microsoft targeting packs from NuGet.

On Windows:

```powershell
.\Windows\scripts\build.ps1
```

The portable folder includes the .NET runtime. Extract the entire folder and run `Molaway.exe`; do not copy only the executable. Closing Settings keeps the tray timer running; Exit in the tray menu quits the app. Deleting the portable folder removes the app; optional local data can be removed separately.

## Verification boundary

Automated scheduler tests and cross-compilation are not a substitute for interactive Windows tests. Before a stable release: verify tray placement, mixed-DPI monitors, notifications, media, lock/sleep, startup/shutdown, keyboard accessibility, performance and Defender/SmartScreen behavior. Do not publish a stable Windows installer until these pass.

## Credits

Molaway is a personal, non-commercial project by Burak Yelkenci, developed with ChatGPT/Codex assistance. The Windows scheduler follows the Molaway behavior built on the MIT-licensed Offscreen project by Dayo Akinkuowo. The original license and attribution remain in the repository and portable folder. See [upstream attribution](../UPSTREAM.md).
