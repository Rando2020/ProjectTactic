#!/usr/bin/env python3
"""Run real battle/route regressions without touching developer/player saves."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

with tempfile.TemporaryDirectory(prefix='tactics-test-') as data:
    result = subprocess.run(
        [sys.argv[1] if len(sys.argv) > 1 else 'godot', '--headless', '--path', 'godot', 'res://tests/test_playable_loop.tscn'],
        cwd=Path(__file__).resolve().parents[1], env={**os.environ, 'XDG_DATA_HOME': data},
        capture_output=True, text=True, timeout=120,
    )
    output = result.stdout + result.stderr
    print(output)
    if result.returncode or 'SCRIPT ERROR:' in output or '0 failures' not in output:
        raise SystemExit(1)
