#!/usr/bin/env python3
"""Release guard: no network/capture entitlements, private APIs or embedded credentials."""
from pathlib import Path
import plistlib, re, sys
root = Path(__file__).resolve().parents[1]
entitlements = plistlib.loads((root / 'Resources/Mola.entitlements').read_bytes())
expected = {'com.apple.security.app-sandbox': True, 'com.apple.security.files.user-selected.read-write': True}
errors = []
if entitlements != expected: errors.append('Unexpected entitlements; review required.')
info = plistlib.loads((root / 'Resources/Info.plist').read_bytes())
for key in ['NSCameraUsageDescription','NSMicrophoneUsageDescription','NSAppleEventsUsageDescription']:
    if key in info: errors.append('Unexpected capture/automation purpose: '+key)
patterns = [r'URLSession\s*\.', r'WKWebView\s*\(', r'NSAppleScript\s*\(', r'\bProcess\s*\(', r'CGEvent\.tapCreate', r'AVCaptureSession\s*\(', r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', r'gh[pousr]_[A-Za-z0-9]{30,}']
for path in (root/'Sources').rglob('*.swift'):
    source = path.read_text()
    for pattern in patterns:
        if re.search(pattern, source): errors.append('Review required: '+str(path.relative_to(root))+' / '+pattern)
for language in ['en','tr']:
    path=root/'Resources/Localization'/f'{language}.lproj/Localizable.strings'
    if not path.is_file(): errors.append('Missing localization: '+language)
license = (root/'LICENSE').read_text()
if 'Dayo Akinkuowo' not in license or 'Burak Yelkenci' not in license: errors.append('Missing attribution.')
if errors:
    print('\n'.join(errors)); sys.exit(1)
print('Release source guard passed. This is a targeted check, not a comprehensive security audit.')
