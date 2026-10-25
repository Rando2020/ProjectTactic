#!/usr/bin/env python3
"""Run unchanged painterly asset validators in a disposable input hierarchy.

Requires only the validators' existing NumPy dependency, not Blender or Godot.
Source reports/metadata are never rewritten. Reports and child diagnostics are
retained in --output, which must be outside the checkout or under build/.
"""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

SOURCE = Path('assets/source/zane-painterly-v1')
GATES = (('validate_export.py', 'validation_report.json'),
         ('test_validate_export.py', None),
         ('check_motion_clearance.py', 'motion_clearance_report.json'))


def run_gates(root: Path, output: Path, timeout: float = 300) -> int:
    root, output = root.resolve(), output.resolve()
    if output.is_relative_to(root) and not output.is_relative_to(root / 'build'):
        raise ValueError('Output must be outside the checkout or under build/')
    if not math.isfinite(timeout) or timeout <= 0:
        raise ValueError('Timeout must be a positive finite number of seconds')
    output.mkdir(parents=True, exist_ok=True)
    for _, report in GATES:
        if report:
            (output / report).unlink(missing_ok=True)
    summary = {'status': 'failed', 'timeout_seconds_per_gate': timeout, 'gates': []}
    exit_code = 0
    # Do not allow inherited PYTHONOPTIMIZE to disable the unchanged assertions.
    env = {k: v for k, v in os.environ.items() if k != 'PYTHONOPTIMIZE'}
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    try:
        with tempfile.TemporaryDirectory(prefix='painterly-asset-gates-') as folder:
            stage = Path(folder)
            files = [SOURCE / name for name, _ in GATES]
            files += [SOURCE / 'textures/zane_painterly_atlas.png',
                      Path('tools/validate_zane_impact_asset.py')]
            for relative in files:
                target = stage / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(root / relative, target)
            for asset in ('zane_v2', 'zane_impact_v1', 'zane_painterly_v1'):
                relative = Path('godot/assets/3d/characters') / asset
                shutil.copytree(root / relative, stage / relative)
            for name, report in GATES:
                log_name = Path(name).stem + '.log'
                command = [sys.executable, '-B', str(SOURCE / name)]
                with (output / log_name).open('w') as log:
                    try:
                        result = subprocess.run(command, cwd=stage, env=env, stdout=log,
                                                stderr=subprocess.STDOUT, timeout=timeout)
                        code = result.returncode
                        status = 'passed' if code == 0 else 'failed'
                    except subprocess.TimeoutExpired:
                        code, status = 124, 'timeout'
                        log.write(f'\nTIMEOUT after {timeout} seconds\n')
                if report:
                    generated = stage / SOURCE / report
                    if generated.is_file():
                        shutil.copyfile(generated, output / report)
                    elif code == 0:
                        code, status = 1, 'missing-report'
                summary['gates'].append({'script': name, 'command': command, 'status': status,
                                         'returncode': code, 'log': log_name, 'report': report})
                print(f'{name}: {status} (exit {code})', flush=True)
                if code and not exit_code:
                    exit_code = code if 0 < code < 256 else 1
    except OSError as error:
        summary['error'] = str(error)
        print(f'Asset gate setup/execution failed: {error}', file=sys.stderr)
        exit_code = exit_code or 1
    summary['status'] = 'failed' if exit_code else 'passed'
    (output / 'release-gates.json').write_text(json.dumps(summary, indent=2) + '\n')
    return exit_code


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--timeout', type=float, default=300,
                        help='Maximum seconds per validator (default: 300)')
    args = parser.parse_args()
    try:
        return run_gates(Path(__file__).resolve().parents[1], args.output, args.timeout)
    except ValueError as error:
        parser.error(str(error))


if __name__ == '__main__':
    raise SystemExit(main())
