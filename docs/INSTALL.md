# Install Molaway

## Current availability

- macOS only; minimum target macOS 15.
- The prepared app download is for Apple Silicon (M-series Macs).
- Intel builds and the oldest supported macOS versions have not been verified.
- No public release is available yet. The local build is ad hoc signed, not Developer ID signed or notarized.
- Windows is planned; there is no Windows installer or release date.

## Once an app release is available

1. On the GitHub project page, click **Releases** on the right.
2. Open the latest release and expand **Assets**.
3. Download the **Molaway** app ZIP. The automatically generated “Source code” files are for developers, not installers.
4. Open the ZIP in Downloads. Drag **Molaway.app** to **Applications**.
5. Open Molaway. It lives in the menu bar, so it does not need a Dock icon.
6. Click the two rings, then the gear button for Settings.

No GitHub account or Git knowledge is needed to download a public release. No Molaway account is needed to use the app.

If macOS blocks an unsigned or unnotarized download, do not disable Gatekeeper, run quarantine-removal commands, or grant unrelated permissions. Wait for a notarized release, or build the reviewed source locally if you are comfortable doing so. If macOS reports malware or a damaged app, stop and verify the source of the download.

## First setup

- **Breaks:** choose eye/movement intervals. Outer ring means eyes; inner ring means movement.
- **Activity:** choose the idle threshold, video handling, and optional meeting suppression.
- **Alerts:** choose a reminder style and display target. Only native notifications need notification permission.
- **Appearance & sound:** choose language, theme, and optional sounds.
- **Overview:** enable only if you want local daily summaries. Recording starts from that point, not retroactively.

## Update

1. Quit Molaway using the power button in its menu panel.
2. Replace the old app in Applications with the new app.
3. Reopen it. Keep only one installed version.

The app has no automatic updater. The existing app identifier is retained, so settings survive updates from the earlier Mola builds. Session timers restart when the app exits.

## Remove

1. If desired, delete summaries from **Settings → Overview** first.
2. Turn off **Launch at login** in Settings.
3. Quit Molaway and move the app from Applications to Trash.

macOS may keep the app's local preferences, backups, and system crash logs. Removing the app is not a claim that every operating-system backup has been erased.
