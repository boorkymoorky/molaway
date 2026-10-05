#!/usr/bin/env python3
"""Check the direct download and separately pinned tap offline; optionally check ZIPs.

This maintainer tool does not download, execute, install or update the app.
"""
import argparse
import hashlib
import json
import shutil
import tempfile
from pathlib import Path
import plistlib
import re
import sys
import zipfile


def check_archive(archive, version, checksum):
    digest = hashlib.sha256()
    with archive.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    if digest.hexdigest() != checksum:
        raise ValueError('Downloaded ZIP checksum does not match its pinned release.')
    with zipfile.ZipFile(archive) as bundle:
        entry = bundle.getinfo('Molaway.app/Contents/Info.plist')
        if entry.file_size > 64 * 1024:
            raise ValueError('Unexpected bundle metadata size.')
        info = plistlib.loads(bundle.read(entry))
    expected = {'CFBundleIdentifier': 'local.mola.desktop',
                'CFBundleShortVersionString': version, 'CFBundleExecutable': 'Molaway',
                'LSMinimumSystemVersion': '15.0'}
    if any(info.get(key) != value for key, value in expected.items()):
        raise ValueError('Downloaded bundle identity, version or minimum OS disagrees.')


def check(root, archive=None, tap_archive=None, verbose=True):
    recipe = (root / 'docs/homebrew/Casks/molaway.rb').read_text()

    def field(name, pattern):
        values = re.findall(rf'^  {name} "({pattern})"$', recipe, re.MULTILINE)
        if len(values) != 1:
            raise ValueError(f'Cask needs one pinned {name}.')
        return values[0]

    version = field('version', r'\d+\.\d+\.\d+')
    checksum = field('sha256', r'[0-9a-f]{64}')
    url = field('url', r'[^"\n]+').replace('#{version}', version)
    release = f'https://github.com/boorkymoorky/molaway/releases/download/v{version}/'
    filename = f'Molaway-{version}-macOS-arm64.zip'
    if url != release + filename:
        raise ValueError('Cask must use the versioned Molaway Apple Silicon release asset.')
    for stanza in ['cask "molaway" do', '  depends_on arch: :arm64',
                   '  depends_on macos: :sequoia', '  app "Molaway.app"']:
        if recipe.splitlines().count(stanza) != 1:
            raise ValueError('Cask identity, platform or app artifact changed; review required.')
    if re.search(r'^\s*(?:system|installer|preflight(?:_steps)?|postflight(?:_steps)?|uninstall(?:_preflight_steps|_postflight_steps)?|zap|binary|pkg|auto_updates)\b', recipe, re.MULTILINE):
        raise ValueError('Cask must not execute install hooks or remove user data.')
    tap_doc = (root / 'docs/M10_DISTRIBUTION.md').read_text()
    if url not in tap_doc or checksum not in tap_doc or release + 'SHA256SUMS.txt' not in tap_doc:
        raise ValueError('Tap verification record disagrees with the pinned cask.')

    pin_path = root / 'docs/download.json'
    if pin_path.stat().st_size > 4096:
        raise ValueError('Unexpected direct-download metadata size.')
    pin = json.loads(pin_path.read_text())
    if not isinstance(pin, dict) or set(pin) != {'version', 'sha256'}:
        raise ValueError('Direct-download metadata needs version and sha256 only.')
    if not isinstance(pin['version'], str) or not re.fullmatch(r'\d+\.\d+\.\d+', pin['version']):
        raise ValueError('Invalid direct-download version.')
    if not isinstance(pin['sha256'], str) or not re.fullmatch(r'[0-9a-f]{64}', pin['sha256']):
        raise ValueError('Invalid direct-download SHA256.')
    filename = f"Molaway-{pin['version']}-macOS-arm64.zip"
    latest_url = 'https://github.com/boorkymoorky/molaway/releases/latest/download/' + filename
    checksums_url = f"https://github.com/boorkymoorky/molaway/releases/download/v{pin['version']}/SHA256SUMS.txt"
    install = (root / 'docs/INSTALL.md').read_text()
    readme = (root / 'README.md').read_text()
    for text in [install, readme]:
        if latest_url not in text or checksums_url not in text or 'M10_DISTRIBUTION.md' not in text:
            raise ValueError('README/install guide disagree with the direct download or omit tap limits.')
    if f"{pin['sha256']}  {filename}" not in install:
        raise ValueError('Installation guide checksum disagrees with the direct download.')
    if archive is not None:
        check_archive(archive, pin['version'], pin['sha256'])
    if tap_archive is not None:
        check_archive(tap_archive, version, checksum)
    if verbose:
        print(f"Distribution consistency passed: direct {pin['version']}, tap {version}. "
              'Offline guard; live latest routing and signatures require separate verification.')


def self_test(root):
    files = ['README.md', 'docs/INSTALL.md', 'docs/download.json',
             'docs/M10_DISTRIBUTION.md', 'docs/homebrew/Casks/molaway.rb']
    with tempfile.TemporaryDirectory(prefix='molaway-distribution-', suffix='.noindex') as temp:
        fixture = Path(temp)
        for name in files:
            target = fixture / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(root / name, target)
        originals = {name: (fixture / name).read_bytes() for name in files}
        check(fixture, verbose=False)  # Direct and tap pins may intentionally differ.
        rejected = 0

        def reject(action):
            nonlocal rejected
            try:
                action()
            except ValueError:
                rejected += 1
            else:
                raise AssertionError('Distribution guard accepted an invalid fixture.')
            for name, data in originals.items():
                (fixture / name).write_bytes(data)

        pin = json.loads(originals['docs/download.json'])
        readme = fixture / 'README.md'
        readme.write_text(readme.read_text().replace(
            f"latest/download/Molaway-{pin['version']}-macOS-arm64.zip",
            'latest/download/Molaway-0.0.0-macOS-arm64.zip'))
        reject(lambda: check(fixture, verbose=False))
        install = fixture / 'docs/INSTALL.md'
        install.write_text(install.read_text().replace(pin['sha256'], '0' * 64))
        reject(lambda: check(fixture, verbose=False))
        cask = fixture / 'docs/homebrew/Casks/molaway.rb'
        cask.write_text(cask.read_text() + '\n  preflight do\n  end\n')
        reject(lambda: check(fixture, verbose=False))
        tap_doc = fixture / 'docs/M10_DISTRIBUTION.md'
        tap_doc.write_text(re.sub(r'[0-9a-f]{64}', '0' * 64, tap_doc.read_text()))
        reject(lambda: check(fixture, verbose=False))
        archive = fixture / 'invalid.zip'
        archive.write_bytes(b'changed download')
        reject(lambda: check(fixture, archive=archive, verbose=False))
        # Even a checksum-matching ZIP must not pass with a foreign bundle identity.
        with zipfile.ZipFile(archive, 'w') as bundle:
            bundle.writestr('Molaway.app/Contents/Info.plist', plistlib.dumps({
                'CFBundleIdentifier': 'test.foreign.app', 'CFBundleShortVersionString': pin['version'],
                'CFBundleExecutable': 'Molaway', 'LSMinimumSystemVersion': '15.0'}))
        foreign_hash = hashlib.sha256(archive.read_bytes()).hexdigest()
        changed = dict(pin, sha256=foreign_hash)
        (fixture / 'docs/download.json').write_text(json.dumps(changed))
        install.write_text(install.read_text().replace(pin['sha256'], foreign_hash))
        reject(lambda: check(fixture, archive=archive, verbose=False))
        if rejected != 6:
            raise AssertionError('Incomplete distribution negative fixtures.')
    print('Distribution guard rejected 6 negative fixtures.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, help='Previously downloaded direct/default app ZIP')
    parser.add_argument('--tap-archive', type=Path, help='Previously downloaded pinned tap app ZIP')
    parser.add_argument('--self-test', action='store_true', help='Check disposable invalid fixtures')
    args = parser.parse_args()
    try:
        root = Path(__file__).resolve().parents[1]
        check(root, args.archive, args.tap_archive)
        if args.self_test:
            self_test(root)
    except (OSError, ValueError, KeyError, AssertionError, zipfile.BadZipFile, plistlib.InvalidFileException) as error:
        message = str(error) if isinstance(error, (ValueError, AssertionError)) else 'Could not read distribution files.'
        print(f'Distribution verification failed: {message}', file=sys.stderr)
        sys.exit(1)
