#!/usr/bin/env python3
"""Targeted Windows source guard; not a proof of sandboxing or a security audit."""
from pathlib import Path
import re, sys
root = Path(__file__).resolve().parents[1]
errors=[]
for path in list((root/'Molaway.Windows').glob('*.cs')) + list((root/'Molaway.Core').glob('*.cs')):
    text=path.read_text(encoding='utf-8')
    for pattern in [r'\bHttpClient\b',r'\bWebClient\b',r'\bSystem\.Net\b',r'\bProcess\.Start\b',r'\bProcessStartInfo\b',r'SetWindowsHookEx',r'GetAsyncKeyState',r'CopyFromScreen',r'TryGetMediaPropertiesAsync',r'GetWindowText',r'\bMediaCapture\b',r'CreateProcess',r'Registry\.(?:SetValue|CreateSubKey)']:
        if re.search(pattern,text):errors.append(f'Review forbidden capability: {path.name}: {pattern}')
    for dll in re.findall(r'DllImport\("([^"]+)"',text):
        if dll not in ['user32.dll','shell32.dll']:errors.append('Review native library: '+dll)
manifest=(root/'Molaway.Windows/app.manifest').read_text(encoding='utf-8')
if 'level="asInvoker" uiAccess="false"' not in manifest:errors.append('Expected standard-user manifest.')
for project in root.glob('*/*.csproj'):
    if '<PackageReference' in project.read_text(encoding='utf-8'):errors.append('Review additional dependency: '+project.name)
if errors:print('\n'.join(errors));sys.exit(1)
print('Windows targeted source guard passed. Desktop app is not OS-network-sandboxed.')
