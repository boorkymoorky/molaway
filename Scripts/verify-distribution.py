#!/usr/bin/env python3
"""Check pinned download/cask consistency offline; optionally check a downloaded ZIP.

This maintainer tool does not download, execute, install or update the app.
"""
import argparse
import hashlib
from pathlib import Path
import plistlib
import re
import sys
import zipfile


def check(root, archive=None):
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
    install = (root / 'docs/INSTALL.md').read_text()
    readme = (root / 'README.md').read_text()
    if url not in install or url not in readme:
        raise ValueError('README and installation guide must link the pinned cask asset.')
    if f'{checksum}  {filename}' not in install or release + 'SHA256SUMS.txt' not in install:
        raise ValueError('Installation guide checksum or checksum-file link disagrees with the cask.')

    if archive is not None:
        digest = hashlib.sha256()
        with archive.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(chunk)
        if digest.hexdigest() != checksum:
            raise ValueError('Downloaded ZIP checksum does not match the pinned cask.')
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
    print(f'Distribution consistency passed for Molaway {version}' +
          (' and the downloaded ZIP.' if archive is not None else ' (offline; asset not downloaded).'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, help='Previously downloaded Molaway app ZIP')
    args = parser.parse_args()
    try:
        check(Path(__file__).resolve().parents[1], args.archive)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, plistlib.InvalidFileException) as error:
        print(f'Distribution verification failed: {error}', file=sys.stderr)
        sys.exit(1)
