#!/usr/bin/env python3
"""Check the curated publication tree. A targeted guard, not a secret-audit guarantee."""
from pathlib import Path
import re
import sys

ROOT_FILES = {'.gitignore', 'Package.swift', 'LICENSE', 'README.md', 'CHANGELOG.md',
              'CONTRIBUTING.md', 'SECURITY.md', 'UPSTREAM.md', 'THIRD_PARTY_NOTICES.md', 'VERIFICATION.md'}
DIRECTORIES = {'Sources', 'Tests', 'docs', '.github'}
SCRIPT_FILES = {'build-app.sh', 'make-icon.sh', 'make-icon.swift', 'make-sounds.py', 'verify-security.py', 'verify-publication.py'}
RESOURCE_FILES = {'Info.plist', 'Mola.entitlements', 'AppIcon.icns', 'AppIcon.png'}


def publication_files(root):
    for name in sorted(ROOT_FILES):
        yield root / name
    for name in sorted(DIRECTORIES):
        yield from sorted((root / name).rglob('*'))
    for name in sorted(SCRIPT_FILES):
        yield root / 'Scripts' / name
    for name in sorted(RESOURCE_FILES):
        yield root / 'Resources' / name
    for name in ['Localization', 'Sounds']:
        yield from sorted((root / 'Resources' / name).rglob('*'))


def check(root):
    errors = []
    patterns = [r'/Users/[A-Za-z0-9_.-]+/', r'/home/[A-Za-z0-9_.-]+/',
                r'gh[pousr]_[A-Za-z0-9]{30,}', r'github_pat_[A-Za-z0-9_]{30,}',
                r'AKIA[A-Z0-9]{16}', r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
                r'(?i)(?:https?|ssh)://[^\s/@:]+:[^\s/@]+@',
                r'(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b']
    binary = {'.png', '.jpg', '.icns', '.wav'}
    count = 0
    for path in publication_files(root):
        rel = path.relative_to(root)
        if path.is_symlink():
            errors.append(f'Symlink: {rel}'); continue
        if path.is_dir():
            continue
        if not path.is_file():
            errors.append(f'Missing file: {rel}'); continue
        count += 1
        if path.name in {'settings.json', 'statistics.json', '.DS_Store'} or path.suffix in {'.log', '.p12', '.key', '.pem', '.pfx', '.zip'}:
            errors.append(f'Private or generated file: {rel}')
        data = path.read_bytes()
        if path.suffix in binary:
            # Only screenshots are expected here; reject EXIF/XMP or JPEG comments.
            if path.suffix == '.jpg' and any(x in data for x in [b'Exif\x00\x00', b'http://ns.adobe.com/xap/', b'\xff\xfe']):
                errors.append(f'Screenshot metadata: {rel}')
            continue
        try:
            content = data.decode('utf-8')
        except UnicodeError:
            errors.append(f'Unexpected binary: {rel}'); continue
        for pattern in patterns:
            if re.search(pattern, content):
                errors.append(f'Review private information: {rel}')
                break
    if errors:
        print('\n'.join(errors)); return False
    print(f'Publication guard passed for {count} curated files. Manually review screenshots and git commit metadata too.')
    return True

if __name__ == '__main__':
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    sys.exit(0 if check(root) else 1)
