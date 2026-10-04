# Install Molaway

## Current availability

- macOS only; minimum target macOS 15.
- The prepared app download is for Apple Silicon (M-series Macs).
- Intel builds and the oldest supported macOS versions have not been verified.
- Release packages are locally (ad hoc) signed, not Apple Developer ID signed or notarized.
- Windows is planned; there is no Windows installer or release date.

## Download the app

**[Download Molaway 2.2.5 for Apple Silicon](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/Molaway-2.2.5-macOS-arm64.zip)** · [Release notes](https://github.com/boorkymoorky/molaway/releases/tag/v2.2.5) · [SHA256SUMS.txt](https://github.com/boorkymoorky/molaway/releases/download/v2.2.5/SHA256SUMS.txt)

This is the published app, verified on 2026-10-04. The M1–M9 changes on `main` are development work and are **not included** in this download. This installation and first-setup guide describes 2.2.5.

1. Download the app ZIP above. The “Source code” files on GitHub are for developers, not installers.
2. Open the ZIP in Downloads. Drag **Molaway.app** to **Applications**.
3. Open Molaway. It lives in the menu bar, so it does not need a Dock icon.
4. Click the two rings, then the gear button for Settings.

No GitHub account or Git knowledge is needed to download a public release. No Molaway account is needed to use the app.

### Check download integrity (optional)

Before extracting, open Terminal and check the downloaded file:

```sh
shasum -a 256 ~/Downloads/Molaway-2.2.5-macOS-arm64.zip
```

The SHA256 should be:

```text
f1430159bdc05ebf141cd6ff583412784b572a0766c90b61254cb942f8bd5882  Molaway-2.2.5-macOS-arm64.zip
```

Compare the 64-character hash; Terminal may print a longer file path. If it differs, stop and download the ZIP again from the linked release. The downloaded bytes matched both the release's checksum file and GitHub's asset digest during the check. These values come from the same publisher; a matching checksum detects changed bytes, not publisher identity or malware.

## Homebrew status

A cask candidate for a Molaway-maintained tap is [prepared in this repository](homebrew/Casks/molaway.rb), pinned to the same verified 2.2.5 ZIP and SHA256. It supports Apple Silicon and requires macOS 15 or later.

The tap is **not published or verified for end-user installation**. No Homebrew install command is available yet; use the direct download above. [Tap preparation and remaining checks](M10_DISTRIBUTION.md) are separate from a new app release. Homebrew would contact GitHub to fetch packages; Molaway itself remains offline and manually updated.

## First launch and macOS security

The app does not have Apple Developer ID signing or notarization. An ad hoc signature preserves the app sandbox but does **not** verify the publisher's identity or mean Apple reviewed it.

- Download only from this repository's Releases page. Each release includes `SHA256SUMS.txt` to check download integrity; a checksum is not an independent trust guarantee.
- If you see **“Molaway.app” Not Opened** with **“Apple could not verify … is free of malware”**, this is the expected warning for this unnotarized download; it is not a malware detection. If you have reviewed and trust the release, choose **Done**, then **System Settings → Privacy & Security → Open Anyway** for **Molaway**, and confirm. [Apple's instructions](https://support.apple.com/en-us/102445).
- This creates an exception for this app. Keep Gatekeeper enabled. Do not use quarantine-removal commands or disable system protection.
- If macOS reports malware, damage, or your organization blocks it, stop. Do not override those warnings.
- A free personal Apple account cannot provide Developer ID distribution signing. No paid membership or company account is needed to build Molaway locally. [Apple account options](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Terminal install from source

This builds the app on your Mac. It does not download and immediately execute a remote installer.

1. Install **Xcode 26 or later** from Apple, open it once, and finish its setup. You need Swift 6.2+ and the macOS 26+ SDK. A command-line-tools installation works only if it supplies both.
2. Open **Terminal** and download the versioned source:

   ```sh
   git clone --branch v2.2.5 --depth 1 https://github.com/boorkymoorky/molaway.git Molaway-source
   cd Molaway-source
   ```

   Alternatively, download **Source code (zip)** from the release, extract it, and open Terminal in that folder. Public downloads do not require signing in.

3. Review the source and `Scripts/build-app.sh` / `Scripts/install-local.sh`, then build:

   ```sh
   bash Scripts/build-app.sh
   ```

4. Quit any running Molaway, then install:

   ```sh
   bash Scripts/install-local.sh
   ```

5. Open **Molaway** from Spotlight or your home **Applications** folder.

The installer replaces only `~/Applications/Molaway.app`, refuses a different app or symbolic-link destination, and preserves preferences. It needs no `sudo`, signing account, or network access. The source download contacts GitHub; Xcode is obtained from Apple. Build output stays in `build.noindex` to avoid duplicate Spotlight app results. There are no third-party Swift packages.

If you previously installed Molaway in the shared `/Applications` folder, remove that old copy using Finder after quitting it; keep a single installed copy. This source installer does not remove apps elsewhere.

## First setup

- **Breaks:** choose eye/movement intervals. Outer ring means eyes; inner ring means movement.
- **Activity:** choose the idle threshold, video handling, and optional meeting suppression. A natural absence resets each timer only if it reaches both the idle threshold and that timer's rest target. A video left playing or active watching mode keeps time running; pause playback/end watching before stepping away.
- **Alerts:** choose a reminder style and display target. Only native notifications need notification permission.
- **Appearance & sound:** choose language, theme, and optional sounds.
- **Overview:** enable only if you want local daily summaries. Recording starts from that point, not retroactively.

## Update

Molaway does not check for updates automatically. Visit this repository's **Releases** page and compare the latest version with the version shown at the bottom of Molaway Settings. The app itself stays offline.

1. Quit Molaway using the power button in its menu panel.
2. Replace the old app in Applications with the new app.
3. Reopen it. Keep only one installed version.

The app has no automatic updater. The existing app identifier is retained, so settings survive updates from the earlier Mola builds. Session timers restart when the app exits.

## Remove

1. If desired, delete summaries from **Settings → Overview** first.
2. Turn off **Launch at login** in Settings.
3. Quit Molaway and move the app from Applications to Trash.

macOS may keep the app's local preferences, backups, and system crash logs. Removing the app is not a claim that every operating-system backup has been erased.
