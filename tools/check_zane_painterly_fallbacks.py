#!/usr/bin/env python3
"""Strict fallback regressions using a disposable copy of actual imported assets.

Run a clean Godot import first. Never mutates the source project or player data.
The broken-import case is explicitly a damaged actual-import unit fixture, not
an authored replacement asset or visual acceptance result.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ANSI = re.compile(r'\x1b\[[0-9;]*m')
CASES = ('missing-candidate', 'corrupt-candidate', 'wrong-profile', 'wrong-provenance',
         'broken-import', 'impact-unavailable', 'all-unavailable')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1] / 'godot')
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    failed = False
    with tempfile.TemporaryDirectory(prefix='painterly-fallback-') as folder:
        project = Path(folder) / 'godot'
        shutil.copytree(args.project, project)
        saved = {}

        def change(relative, data):
            path = project / relative
            if path not in saved:
                saved[path] = path.read_bytes() if path.exists() else None
            if data is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(data)

        def remove_model(name):
            relative = f'assets/3d/characters/{name}/{name}.glb'
            change(relative, None)
            change(relative + '.import', None)

        candidate = 'assets/3d/characters/zane_painterly_v1/'
        impact = 'assets/3d/characters/zane_impact_v1/'
        for case in CASES:
            for path, data in saved.items():
                if data is None:
                    path.unlink(missing_ok=True)
                else:
                    path.write_bytes(data)
            saved.clear()
            expected, extra = 'impact', []
            if case == 'missing-candidate':
                remove_model('zane_painterly_v1')
            elif case == 'corrupt-candidate':
                change(candidate + 'zane_painterly_v1.glb', b'CORRUPT UNIT FIXTURE NOT AN ASSET')
            elif case in ('wrong-profile', 'wrong-provenance'):
                metadata = json.loads((project / candidate / 'presentation.json').read_text())
                if case == 'wrong-profile':
                    metadata['profile_id'] = 'zane_impact_v1'
                else:
                    metadata['motion_source']['model_sha256'] = 'a' * 64
                change(candidate + 'presentation.json', json.dumps(metadata).encode())
            elif case == 'broken-import':
                extra = ['--broken-import']
            else:
                change(candidate + 'presentation.json', b'{}')
                change(impact + 'presentation.json', b'{}')
                expected = 'original'
                if case == 'all-unavailable':
                    remove_model('zane_v2')
                    expected = 'sprite'
            with tempfile.TemporaryDirectory(prefix='painterly-probe-data-') as data:
                try:
                    result = subprocess.run([args.godot, '--headless', '--path', str(project),
                        'res://tests/test_zane_painterly_rig.tscn', '--', '--fallback=' + expected, *extra],
                        capture_output=True, text=True, timeout=30, env={**os.environ,
                            'XDG_DATA_HOME': data, 'XDG_CONFIG_HOME': data, 'XDG_CACHE_HOME': data})
                    output = result.stdout + result.stderr
                    diagnostics = ANSI.sub('', output)
                    passed = result.returncode == 0 and bool(re.search(r'Painterly fallback: \d+ checks, 0 failures', diagnostics)) and 'ERROR:' not in diagnostics
                except subprocess.TimeoutExpired as error:
                    output = 'TIMEOUT: ' + str(error)
                    for partial in (error.stdout, error.stderr):
                        if partial:
                            output += '\n' + (partial.decode(errors='replace') if isinstance(partial, bytes) else partial)
                    passed = False
            (args.output / ('fallback-' + case + '.log')).write_text(output)
            print(case + ': ' + ('PASS' if passed else 'FAIL'), flush=True)
            failed = failed or not passed
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
