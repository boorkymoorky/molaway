# Molaway 3.0.1 release record

## Published packages — 2026-10-05

[Molaway 3.0.1](https://github.com/boorkymoorky/molaway/releases/tag/v3.0.1) is a regular release, published at 10:46 UTC. Tag `v3.0.1` points to `c6ea02b57c29705b4e73e036439fcce3f7a7139e`, the protected merge of [PR #29](https://github.com/boorkymoorky/molaway/pull/29). [Required PR Verify](https://github.com/boorkymoorky/molaway/actions/runs/37297789981) and [merged-main Verify](https://github.com/boorkymoorky/molaway/actions/runs/37298207328) passed every step. Local checks also passed 211 tests in 21 suites, source/publication/distribution guards, release build, original bundle checks and isolated installation/update/failure checks.

| Public asset | Bytes | SHA256 |
| --- | ---: | --- |
| [Molaway-3.0.1-macOS-arm64.zip](https://github.com/boorkymoorky/molaway/releases/download/v3.0.1/Molaway-3.0.1-macOS-arm64.zip) | 1,951,145 | `d7fac265381266da673fb0f960155097ccd360470e3914b031a0af7c1d1e80e2` |
| [Molaway-3.0.1-Source.zip](https://github.com/boorkymoorky/molaway/releases/download/v3.0.1/Molaway-3.0.1-Source.zip) | 3,120,924 | `ebda062157670523a998605ddfff88f2832835caf5e1ef295b10bf8e7065e729` |
| [SHA256SUMS.txt](https://github.com/boorkymoorky/molaway/releases/download/v3.0.1/SHA256SUMS.txt) | 187 | `9ae58986f7bcadb703c75d12095e4920380e001690b3514c8df11491a26b8319` |

All three actual public downloads were byte-identical to the reviewed packages and matched GitHub's asset digests. The source ZIP contains exactly all 135 tracked files at the tag revision. The original extracted app passed deep/strict signature verification, ad hoc hardened runtime, arm64 architecture, 3.0.1/build 12 metadata, macOS 15 target, MIT license, exact sandbox/file entitlements and 372 unchanged EN/TR resource keys. Eight negative bundle fixtures and six negative distribution fixtures were rejected. No re-signing was used for these checks. This verifies package consistency, not independent publisher identity or absence of malware.

The direct-download metadata is updated separately from the immutable tag source through a protected documentation PR. Promotion to GitHub Latest follows successful required checks for that PR, with immediate verification of the latest-download route. Existing 3.0.0 assets remain unchanged. The tap still pins 2.2.5; M6 structured checks remain deferred and M10 original quarantined first launch stays pending. Private installation and backup evidence is kept outside the repository and release assets.

## Owner authorization — 2026-10-05

The owner explicitly requested publication and installation of the countdown fix. Prepare a regular **3.0.1 / build 12** release from protected main, tag `v3.0.1`, and the app/source ZIPs plus `SHA256SUMS.txt`. After public-asset verification, make 3.0.1 the latest direct download and update README/install metadata through a protected PR. Do not modify existing 3.0.0 assets. The Homebrew tap separately remains pinned to 2.2.5; its first-launch gate and withheld end-user commands are unchanged.

## Change and verification scope

[PR #28](https://github.com/boorkymoorky/molaway/pull/28) rephases the existing timer after countdown-second boundaries. Normal permitted timer lateness no longer repeats a displayed second and then skips the next. Real elapsed-time accounting, bounded long-stall recovery, pauses, rests and the existing sensor gate are preserved. No continuously faster timer, separate visual clock, new sensor, permission, dependency or networking capability is added.

The fix passed 211 tests in 21 suites, required PR CI and merged-main CI. A disposable native timer probe using compiled model code and synthetic data observed every displayed second under changing permitted lateness. This does not establish full UI, physical lifecycle, sustained CPU or battery performance. The release revision separately passed source/publication/distribution guards, tests, release build, exact original signature/entitlements/372 EN/TR resource checks, and isolated installation/update checks before publication.

## Publication and installation sequence

1. Merge the version/build preparation only after protected PR checks pass; verify merged main.
2. Package the reviewed Apple Silicon app and all tracked tag-source files, excluding local/build/private state. Inspect archive paths, exact bytes, source equality, metadata, architecture, original signature, attribution and English/Turkish resources. Create fresh checksum entries.
3. Create `v3.0.1` at the verified release revision, stage only the two ZIPs and checksum file in a draft, compare GitHub asset digests and then publish a regular release. Keep latest on 3.0.0 until the new download route and README metadata are ready.
4. Download all actual public assets and compare bytes/digests with the local packages. Inspect the extracted original bundle without re-signing. Update direct-download metadata through a protected PR, promote 3.0.1 to latest and verify the live latest-download URL.
5. For the owner's requested installation, quit the old app gracefully and privately back up the old app plus settings/statistics/pause files. Retain an old-format settings copy for migration/rollback. Run isolated installer checks, install the verified new bundle at the existing app location and launch one copy. Check version/signature, preserved preferences and migration using private local evidence. Do not publish backup contents, local paths or personal observations.

## Upgrade and remaining limits

3.0.1 uses the same settings schema and cycle as 3.0.0. From 2.2.5, eye interval/rest becomes work/short timing, movement rest becomes long rest, and the independent movement interval is approximated by short-break cadence. Language, appearance and compatible preferences are preserved. Summary recording and new optional signals are not enabled by migration. Review the migrated schedule; [the 3.0.0 migration and downgrade limits](MACOS_3_RELEASE.md) continue to apply. Replacing the app alone is not a full rollback.

Apple Silicon, macOS 15 minimum, ad hoc signed and unnotarized. Keep Gatekeeper enabled; public downloads may require Apple's per-app approval. A local upgrade does not establish M10's original quarantined first-launch result. M6 structured checks remain deferred, M10 first launch stays pending and no Windows stable release or installer is added. Original Offscreen copyright/MIT attribution and AI-assistance disclosure remain intact.
