#!/usr/bin/env python3
"""Import and validate opt-in terrain assets with isolated Godot user data."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot')
parser.add_argument('--proof', action='store_true')
args = parser.parse_args()
if not sys.platform.startswith('linux'):
    raise SystemExit('Use Linux/WSL to isolate test user data.')
with tempfile.TemporaryDirectory(prefix='terrain-art-') as directory:
    commands = [['--editor', '--import'], ['--script', 'tests/test_terrain_art.gd']]
    if args.proof:
        commands[-1] += ['--', '--proof']
    for command in commands:
        result = subprocess.run([args.godot, '--headless', '--path', str(ROOT/'godot'), *command],
            env=dict(os.environ, XDG_DATA_HOME=directory), capture_output=True, text=True, timeout=180)
        output = result.stdout + result.stderr
        if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
            print(output)
            raise SystemExit('Terrain validation failed')
        if '--script' in command:
            print(output)
print('Terrain import, alpha, adjacency and lab regressions passed.')
