#!/usr/bin/env python3
"""Fail closed before Pages upload, including when Godot logs errors but exits 0."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ANSI = re.compile(r'\x1b\[[0-9;]*m')
# Existing audio shutdown diagnostics are documented in docs/qa/integration-checkpoint-2026-10-24.md.
# Keep them visible; never exempt script, import, preload, or other resource errors.
SHUTDOWN_RESOURCE_LEAK = re.compile(
    r'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
)


def run_checked(command, success_marker=None):
    print('\n=== ' + ' '.join(map(str, command)) + ' ===', flush=True)
    try:
        result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, errors='replace', timeout=300)
    except subprocess.TimeoutExpired as error:
        partial = error.stdout or ''
        print(partial.decode(errors='replace') if isinstance(partial, bytes) else partial, flush=True)
        raise RuntimeError('Command exceeded the 300-second limit') from error
    print(result.stdout, flush=True)
    output = ANSI.sub('', result.stdout)
    errors = [line for line in output.splitlines()
              if 'ERROR:' in line and not SHUTDOWN_RESOURCE_LEAK.fullmatch(line.strip())]
    if result.returncode or errors:
        raise RuntimeError(f'Command failed (exit {result.returncode}); see diagnostics above')
    if success_marker and success_marker not in output:
        raise RuntimeError(f'Missing success marker: {success_marker}')
    return output.strip()


def export(output, godot='godot'):
    output = output.resolve()
    # Do not let stale exports satisfy fresh-output checks after a failed export.
    if output.exists() and any(output.iterdir()):
        raise RuntimeError(f'Export directory must be empty: {output}')
    output.mkdir(parents=True, exist_ok=True)
    engine = [godot, '--headless', '--path', 'godot']
    run_checked([*engine, '--import'])
    run_checked([*engine, '--script', 'res://tests/validate_all_scripts.gd'],
                'Godot script validation: OK (')
    run_checked([*engine, '--script', 'res://tests/test_asset_manifest.gd'],
                'Asset manifest contract: OK (')
    run_checked([*engine, '--export-release', 'Web', str(output / 'index.html')])
    for name in ('index.html', 'index.js', 'index.pck', 'index.wasm'):
        path = output / name
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f'Missing or empty fresh Web output: {path}')
    run_checked([sys.executable, 'tools/prepare_playable_web.py', str(output)],
                'Prepared playable Web export:')
    run_checked(['node', 'tools/check_web_package.mjs', str(output)], 'Web package:')
    # A failed build must never acquire provenance that looks ready to publish.
    info = {
        'source_commit': run_checked(['git', 'rev-parse', 'HEAD']),
        'godot_version': run_checked([godot, '--version']),
    }
    (output / 'build-info.json').write_text(json.dumps(info, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    try:
        export(args.directory, args.godot)
    except (RuntimeError, OSError) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        raise SystemExit(1)
