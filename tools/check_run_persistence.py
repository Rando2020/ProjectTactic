#!/usr/bin/env python3
"""Run cold-process persistence regressions with isolated, disposable user data."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot')
args = parser.parse_args()

def run(mode, directory):
    env = dict(os.environ, XDG_DATA_HOME=str(directory))
    result = subprocess.run([args.godot, '--headless', '--path', str(ROOT/'godot'),
        '--script', 'tests/test_run_persistence.gd', '--', mode],
        env=env, capture_output=True, text=True, timeout=60)
    output = result.stdout + result.stderr
    print(output)
    if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise SystemExit(f'Persistence regression failed: {mode}')

# XDG_DATA_HOME isolation is supported by Godot on Linux; do not touch real saves.
if not __import__('sys').platform.startswith('linux'):
    raise SystemExit('Run this isolated checker on Linux/WSL or in CI.')
with tempfile.TemporaryDirectory(prefix='projecttactic-saves-') as temp:
    base = Path(temp)
    imported = subprocess.run([args.godot, '--headless', '--path', str(ROOT/'godot'),
        '--editor', '--import'], env=dict(os.environ, XDG_DATA_HOME=str(base/'import')),
        capture_output=True, text=True, timeout=600)
    import_log = imported.stdout + imported.stderr
    if imported.returncode or 'SCRIPT ERROR:' in import_log or '\nERROR:' in import_log:
        print(import_log)
        raise SystemExit('Godot import failed')
    print('Godot import passed.')
    for mode in ['write', 'read', 'ended']:
        run(mode, base/'roundtrip')
    for case in ['legacy', 'slot2']:
        data = base/case/'godot/app_userdata/ProjectTactic'
        data.mkdir(parents=True)
        (data/'save.json').write_text(json.dumps({'version':1,'gold':91,'unit_jp':{'zane':17}}))
        (data/'meta-progression.json').write_text(json.dumps({'version':1,'currencies':{'soul-shards':44}}))
        if case == 'slot2':
            (data/'save_1.json').write_text(json.dumps({'schema':2,'gold':23,'story_flags':True,
                'active_run':{'run_id':'old','seed':42,'floor':1,'node':0,'floor_plan':[
                    {'id':'f1_b0','floor':1,'type':'battle','completed':False}]}}))
        run(case, base/case)
print('All persistence regression modes passed.')
