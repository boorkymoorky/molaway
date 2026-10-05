# Install Molaway

## Current availability

- macOS only; minimum target macOS 15.
- The prepared app download is for Apple Silicon (M-series Macs).
- Intel builds and the oldest supported macOS versions have not been verified.
- Release packages are locally (ad hoc) signed, not Apple Developer ID signed or notarized.
- Windows is planned; there is no Windows installer or release date.

## Download the app

**[Download latest release for Apple Silicon](https://github.com/boorkymoorky/molaway/releases/latest/download/Molaway-3.0.1-macOS-arm64.zip)** · [Release notes](https://github.com/boorkymoorky/molaway/releases/latest) · [SHA256SUMS.txt](https://github.com/boorkymoorky/molaway/releases/download/v3.0.1/SHA256SUMS.txt)

The current regular release is **3.0.1 / build 12**, with one work/short/long cycle and a fix for uneven countdown steps during normal use. Its actual app/source downloads matched the reviewed files and GitHub digests; original signature and resources passed inspection. This guide describes 3.0.1. [Release evidence and remaining physical limits](MACOS_3_0_1_RELEASE.md).

1. Download the app ZIP above. GitHub's source archives are for developers, not installers.
2. Quit any running Molaway, open the ZIP and drag **Molaway.app** to **Applications**. Keep one installed copy.
3. Open Molaway. It lives in the menu bar and does not need a Dock icon.
4. Click the two rings, then the gear button for Settings.

No GitHub or Molaway account is needed.

### Check download integrity (optional)

Before extracting, check the downloaded file:

```sh
shasum -a 256 ~/Downloads/Molaway-3.0.1-macOS-arm64.zip
```

The SHA256 should be:

```text
d7fac265381266da673fb0f960155097ccd360470e3914b031a0af7c1d1e80e2  Molaway-3.0.1-macOS-arm64.zip
```

Compare the 64-character hash with the linked checksum file. If it differs, stop and download again from this repository. Matching hashes detect changed bytes; they do not independently authenticate the publisher or prove absence of malware.

### Upgrading from 2.2.5

Export your 2.2.5 settings first and keep that file private. Review the migrated schedule: eye interval/rest becomes work/short timing, movement rest becomes long rest, and the old movement interval is approximated by short-break cadence.

2.2.5 cannot read 3.x settings and may fall back to defaults; older summary writers may lose Screen Score fields. Settings export excludes summaries and live pause/cadence. App replacement alone is not a full or lossless rollback. Read [migration/downgrade limits](MACOS_3_RELEASE.md) before switching.

## Homebrew status

The [Molaway-maintained tap](https://github.com/boorkymoorky/homebrew-molaway) is published and still pins the verified **2.2.5** ZIP and SHA256, independently of the 3.0.1 direct download. It supports Apple Silicon and requires macOS 15 or later. Its cask matches [the copy in this repository](homebrew/Casks/molaway.rb).

The public tap’s installation, fetch, same-version reinstallation and removal passed in a disposable Homebrew environment. **First launch after normal Gatekeeper approval remains unverified**, so end-user Homebrew instructions remain pending; use the direct download above. [Verification evidence and the remaining first-launch gate](M10_DISTRIBUTION.md) state the limits. Homebrew contacts GitHub to fetch packages; Molaway itself remains offline and manually updated. The tap does not yet distribute 3.x; no tap version change is included in this update.

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
   git clone --branch v3.0.1 --depth 1 https://github.com/boorkymoorky/molaway.git Molaway-source
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

- **Breaks:** choose work interval, short/long rest durations and completed-short cadence. Outer ring shows work/rest; inner ring shows progress toward a long break. Deep Focus can restore your prior custom timing.
- **Activity:** choose the idle threshold, video handling and optional quiet signals. Natural absence follows the current cycle and counts once. A video left playing or active Watching keeps time running; pause playback/end Watching before stepping away. Quiet signals do not prove a meeting or presence.
- **Pause & schedule:** choose shared manual pause and optional Office Hours, including overnight schedules.
- **Alerts:** choose a reminder style, Skip mode and display target. Only native notifications need notification permission.
- **Appearance & sound:** choose language, theme, and optional sounds.
- **Overview:** enable only if you want local daily summaries. Recording starts from that point, not retroactively.

## Update

Molaway does not check for updates automatically. Visit this repository's **Releases** page and compare the latest version with the version shown at the bottom of Molaway Settings. The app itself stays offline.

1. Quit Molaway using the power button in its menu panel.
2. Replace the old app in Applications with the new app.
3. Reopen it. Keep only one installed version.

The app has no automatic updater. The existing app identifier is retained, so the existing data location is retained. Timing migration is approximate; schema-3 settings are incompatible with 2.2.5. Session timers restart when the app exits.

## Remove

1. If desired, delete summaries from **Settings → Overview** first.
2. Turn off **Launch at login** in Settings.
3. Quit Molaway and move the app from Applications to Trash.

macOS may keep the app's local preferences, backups, and system crash logs. Removing the app is not a claim that every operating-system backup has been erased.
