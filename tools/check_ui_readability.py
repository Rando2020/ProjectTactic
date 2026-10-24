#!/usr/bin/env python3
"""Run UI policy and real scene geometry checks without touching player settings/saves."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

with tempfile.TemporaryDirectory(prefix="tactics-ui-") as data:
    result = subprocess.run(
        [sys.argv[1] if len(sys.argv) > 1 else "godot", "--headless", "--path", "godot",
         "--script", "res://tests/test_ui_readability.gd"],
        cwd=Path(__file__).resolve().parents[1],
        env={**os.environ, "XDG_DATA_HOME": data, "XDG_CONFIG_HOME": data, "XDG_CACHE_HOME": data},
        capture_output=True, text=True, timeout=60,
    )
    output = result.stdout + result.stderr
    print(output)
    if result.returncode or "ERROR:" in output or "0 failures" not in output:
        raise SystemExit(1)
