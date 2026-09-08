#!/usr/bin/env python3
"""Native callback/cold-process checks for the combined Web/persistence branch.

This is NOT browser refresh or IndexedDB coverage. Floor 2 is bypassed by a
fixture to exercise the real boon callback at a generated floor-3 boon node.
"""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
if not sys.platform.startswith('linux'):
    raise SystemExit('Run on Linux/WSL for isolated XDG_DATA_HOME storage.')
with tempfile.TemporaryDirectory(prefix='tactic-integration-') as directory:
    for mode in ['prepare', 'before', 'victory', 'boon', 'abandon']:
        result = subprocess.run([
            args.godot, '--headless', '--path', str(ROOT / 'godot'),
            '--script', 'tests/test_integration_checkpoints.gd', '--', mode,
        ], env=dict(os.environ, XDG_DATA_HOME=directory), capture_output=True,
            text=True, timeout=30)
        output = result.stdout + result.stderr
        print(output, flush=True)
        if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
            raise SystemExit(f'Integration checkpoint failed: {mode}')
print('Native integration checkpoints passed; browser checks remain separate.')
