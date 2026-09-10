#!/usr/bin/env python3
"""Exercise production texture loaders against exported resources, without source PNGs."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--godot', default='godot')
p.add_argument('--pack', type=Path, default=ROOT/'build/web/index.pck')
a = p.parse_args()
with tempfile.TemporaryDirectory(prefix='tactic-pack-assets-') as data:
    r = subprocess.run([a.godot, '--headless', '--main-pack', str(a.pack.resolve()),
        '--script', str(ROOT/'godot/tests/test_exported_assets.gd')],
        env=dict(os.environ, XDG_DATA_HOME=data), text=True, capture_output=True, timeout=60)
    output = r.stdout + r.stderr
    print(output)
    if r.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise SystemExit('Exported asset regression failed')
