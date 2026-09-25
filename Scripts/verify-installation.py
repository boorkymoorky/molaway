#!/usr/bin/env python3
"""Exercise the real installer in a disposable destination, without changing HOME."""
from pathlib import Path
import hashlib
import os
import plistlib
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / 'build.noindex/Molaway.app'
assert source.is_dir(), 'Build the release app first.'
# The production installer refuses any running Molaway. Tests never bypass that check.
if subprocess.run(['/usr/bin/pgrep', '-x', 'Molaway'], capture_output=True).returncode == 0:
    raise SystemExit('Quit Molaway before running installation verification.')

with tempfile.TemporaryDirectory(prefix='molaway-install-check-', suffix='.noindex') as temp:
    base = Path(temp).resolve()
    fixture = base / 'source'
    (fixture / 'Scripts').mkdir(parents=True)
    (fixture / 'build.noindex').mkdir()
    shutil.copy2(root / 'Scripts/install-local.sh', fixture / 'Scripts/install-local.sh')
    bundle = fixture / 'build.noindex/Molaway.app'
    shutil.copytree(source, bundle, symlinks=True)
    apps = base / 'Applications'
    destination = apps / 'Molaway.app'
    checks = []

    def install(folder=apps, success=True):
        env = dict(os.environ, MOLAWAY_INSTALL_DIR=str(folder))
        result = subprocess.run(['/bin/bash', str(fixture / 'Scripts/install-local.sh')],
                                env=env, capture_output=True, timeout=30)
        assert (result.returncode == 0) == success, 'Installer returned an unexpected result.'

    def digest(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    install()
    executable = destination / 'Contents/MacOS/Molaway'
    expected = digest(source / 'Contents/MacOS/Molaway')
    assert digest(executable) == expected
    subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(destination)],
                   check=True, capture_output=True)
    checks.append('fresh installation and signature')
    install()
    assert digest(executable) == expected
    assert not list(apps.glob('.molaway-install.*'))
    checks.append('replacement and staging cleanup')

    # A damaged download must fail before replacing the installed bundle.
    license_file = bundle / 'Contents/Resources/LICENSE.txt'
    original = license_file.read_bytes()
    license_file.write_bytes(original + b'\ninvalid modification\n')
    install(success=False)
    assert digest(executable) == expected
    license_file.write_bytes(original)
    checks.append('damaged source preserves existing installation')

    foreign = base / 'foreign'
    foreign_bundle = foreign / 'Molaway.app/Contents'
    foreign_bundle.mkdir(parents=True)
    foreign_info = foreign_bundle / 'Info.plist'
    foreign_info.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'test.unrelated.app'}))
    before = foreign_info.read_bytes()
    install(foreign, success=False)
    assert foreign_info.read_bytes() == before
    checks.append('unrelated app is never replaced')

    linked = base / 'linked'
    linked.symlink_to(apps, target_is_directory=True)
    install(linked, success=False)
    linked_app = base / 'linked-app'
    linked_app.mkdir()
    (linked_app / 'Molaway.app').symlink_to(destination, target_is_directory=True)
    install(linked_app, success=False)
    assert digest(executable) == expected
    checks.append('symlink destinations refused')
    install('relative-directory', success=False)
    checks.append('relative destination refused')

print('Installation verification passed: ' + '; '.join(checks) + '.')
