#!/usr/bin/env python3
"""Inspect a built development bundle without launching, installing or downloading it."""
import argparse
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_ENTITLEMENTS = {
    'com.apple.security.app-sandbox': True,
    'com.apple.security.files.user-selected.read-write': True,
}
# Current tables use only object, integer and literal-percent placeholders.
PLACEHOLDER = re.compile(r'%(?:@|d|%)')
ENTRY = re.compile(r'^"(?:[^"\\]|\\.)*"\s*=\s*"(?:[^"\\]|\\.)*"\s*;', re.MULTILINE)


def run(args):
    result = subprocess.run(args, capture_output=True, timeout=30)
    if result.returncode:
        raise ValueError('Native bundle/resource verification failed.')
    return result


def table(path):
    if path.is_symlink() or not path.is_file():
        raise ValueError('Missing or linked localization table.')
    values = json.loads(run(['/usr/bin/plutil', '-convert', 'json', '-o', '-', str(path)]).stdout)
    if not isinstance(values, dict) or any(not isinstance(v, str) for v in values.values()):
        raise ValueError('Localization table must contain strings.')
    if len(ENTRY.findall(path.read_text())) != len(values):
        raise ValueError('Duplicate or unsupported localization entries.')
    return values


def check_localizations(en_path, tr_path):
    en, tr = table(en_path), table(tr_path)
    if not en or en.keys() != tr.keys():
        raise ValueError('English/Turkish localization keys differ.')
    for key in en:
        if any("%" in PLACEHOLDER.sub("", value) for value in [key, en[key], tr[key]]):
            raise ValueError("Unsupported localization format placeholder; review required.")
        expected = PLACEHOLDER.findall(key)
        if PLACEHOLDER.findall(en[key]) != expected or PLACEHOLDER.findall(tr[key]) != expected:
            raise ValueError('Localization format placeholders differ.')
    return len(en)


def check(app):
    if app.is_symlink() or not app.is_dir():
        raise ValueError('Bundle must be a real directory.')
    contents = app / 'Contents'
    info_path = contents / 'Info.plist'
    if info_path.is_symlink():
        raise ValueError('Linked bundle metadata.')
    info = plistlib.loads(info_path.read_bytes())
    source = plistlib.loads((ROOT / 'Resources/Info.plist').read_bytes())
    if info != source:
        raise ValueError('Built bundle metadata differs from reviewed source.')
    if info.get('CFBundleIdentifier') != 'local.mola.desktop' or info.get('LSMinimumSystemVersion') != '15.0':
        raise ValueError('Unexpected app identity or minimum OS.')
    binary = contents / 'MacOS/Molaway'
    if binary.is_symlink():
        raise ValueError('Linked executable.')
    if run(['/usr/bin/lipo', '-archs', str(binary)]).stdout.decode().split() != ['arm64']:
        raise ValueError('Expected an Apple Silicon bundle.')
    if re.search(rb'/Users/[A-Za-z0-9_.-]+/', binary.read_bytes()):
        raise ValueError('Executable contains a personal home path.')
    run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)])
    signature = run(['/usr/bin/codesign', '-d', '--verbose=4', str(app)]).stderr.decode()
    if not re.search(r'^CodeDirectory .*flags=.*\badhoc\b.*\bruntime\b', signature, re.MULTILINE):
        raise ValueError('Expected ad hoc signing with hardened runtime.')
    entitlements = plistlib.loads(run(['/usr/bin/codesign', '-d', '--entitlements', '-', '--xml', str(app)]).stdout)
    if entitlements != EXPECTED_ENTITLEMENTS:
        raise ValueError('Unexpected built-bundle entitlements.')
    resources = contents / 'Resources'
    if (resources / 'LICENSE.txt').is_symlink() or (resources / 'LICENSE.txt').read_bytes() != (ROOT / 'LICENSE').read_bytes():
        raise ValueError('Bundled MIT license/attribution differs.')
    for language in ['en', 'tr']:
        compiled = resources / f'{language}.lproj/Localizable.strings'
        original = ROOT / f'Resources/Localization/{language}.lproj/Localizable.strings'
        if compiled.is_symlink() or compiled.read_bytes() != original.read_bytes():
            raise ValueError('Bundled localization differs from reviewed source.')
    count = check_localizations(resources / 'en.lproj/Localizable.strings', resources / 'tr.lproj/Localizable.strings')
    return info['CFBundleShortVersionString'], count


def self_test(app):
    """Negative fixtures prove the guard rejects unsafe or inconsistent packages."""
    checked = 0
    def rejected(body):
        nonlocal checked
        try:
            body()
        except ValueError:
            checked += 1
        else:
            raise AssertionError('Bundle guard accepted a negative fixture.')
    with tempfile.TemporaryDirectory(prefix='molaway-bundle-check-', suffix='.noindex') as temp:
        base = Path(temp)
        linked = base / 'linked.app'; linked.symlink_to(app, target_is_directory=True)
        rejected(lambda: check(linked))
        fixture = base / 'Molaway.app'
        shutil.copytree(app, fixture, symlinks=True)
        metadata = fixture / 'Contents/Info.plist'
        original = metadata.read_bytes()
        info = plistlib.loads(original); info['CFBundleShortVersionString'] = '0.0.0'
        metadata.write_bytes(plistlib.dumps(info)); rejected(lambda: check(fixture)); metadata.write_bytes(original)
        license_file = fixture / 'Contents/Resources/LICENSE.txt'
        original_license = license_file.read_bytes()
        license_file.write_bytes(b'changed license'); rejected(lambda: check(fixture)); license_file.write_bytes(original_license)
        en = base / 'en.strings'; tr = base / 'tr.strings'
        en.write_text('"%d item" = "%d item";\n')
        for text in ['"other key" = "other key";\n', '"%d item" = "%@ item";\n',
                     '"%d item" = "%d item";\n"%d item" = "%d duplicate";\n']:
            tr.write_text(text); rejected(lambda: check_localizations(en, tr))
        en.write_text('"%lld item" = "%lld item";\n')
        tr.write_text('"%lld item" = "%lld item";\n')
        rejected(lambda: check_localizations(en, tr))
        # A separately signed fixture must still fail when its permissions broaden.
        entitlements = dict(EXPECTED_ENTITLEMENTS, **{'com.apple.security.network.client': True})
        entitlements_path = base / 'fixture.entitlements'; entitlements_path.write_bytes(plistlib.dumps(entitlements))
        run(['/usr/bin/codesign', '--force', '--sign', '-', '--options', 'runtime', '--timestamp=none',
             '--entitlements', str(entitlements_path), str(fixture)])
        rejected(lambda: check(fixture))
    if checked != 8:
        raise AssertionError('Incomplete negative bundle checks.')
    return checked


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, default=ROOT / 'build.noindex/Molaway.app')
    parser.add_argument('--self-test', action='store_true', help='Also check disposable negative fixtures.')
    args = parser.parse_args()
    try:
        version, count = check(args.app)
        if args.self_test:
            print(f'Bundle guard rejected {self_test(args.app)} negative fixtures.')
        print(f'Built bundle guard passed: {version}, arm64, {count} matching EN/TR keys. '
              'This is development packaging evidence, not release or physical verification.')
    except (OSError, ValueError, AssertionError, subprocess.SubprocessError, plistlib.InvalidFileException) as error:
        # Do not print raw command outputs or private filesystem paths.
        message = str(error) if isinstance(error, (ValueError, AssertionError)) else 'Could not inspect bundle/resources.'
        print(f'Built bundle guard failed: {message}', file=sys.stderr)
        sys.exit(1)
