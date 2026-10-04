#!/usr/bin/env python3
"""Preserve licenses from the exact runtime packs included by dotnet publish."""
from pathlib import Path
import json, shutil, sys
root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
assets = json.loads((root/'Molaway.Windows/obj/project.assets.json').read_text(encoding='utf-8-sig'))
folders = [Path(x) for x in assets['packageFolders']]
config = json.loads((out/'Molaway.runtimeconfig.json').read_text(encoding='utf-8-sig'))
notices = out/'licenses'
notices.mkdir(exist_ok=True)
for framework in config['runtimeOptions']['includedFrameworks']:
    name = framework['name'].lower() + '.runtime.win-x64'
    pack = next((f/name/framework['version'] for f in folders if (f/name/framework['version']).is_dir()), None)
    if pack is None: raise SystemExit('Missing exact runtime pack notices: '+name)
    license_files = [p for p in pack.iterdir() if p.is_file() and ('license' in p.name.lower() or 'notice' in p.name.lower())]
    if not license_files: raise SystemExit('Missing runtime license: '+name)
    for file in license_files: shutil.copyfile(file, notices/(name+'-'+file.name))
for file in (root/'licenses').glob('*'):
    if file.is_file(): shutil.copyfile(file,notices/file.name)
print('Exact Microsoft runtime notices preserved.')
