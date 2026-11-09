#!/usr/bin/env python3
"""Build an isolated courtyard Web package; never alter either source entry point."""
from contextlib import contextmanager
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'demos/isometric-2v2'
MAIN = 'run/main_scene="res://prototypes/isometric/Skirmish.tscn"'
COURTYARD = 'run/main_scene="res://prototypes/blooming/BloomingBattle.tscn"'
ANSI = re.compile(r'\x1b\[[0-9;]*m')


@contextmanager
def staged_project(source=None):
    source = SOURCE if source is None else source
    original = (source / 'project.godot').read_text()
    if original.count(MAIN) != 1:
        raise ValueError('Unexpected standalone entry point; review before release')
    save_name = 'config/custom_user_dir_name="ProjectTactic-IsometricProof"'
    if original.count(save_name) != 1:
        raise ValueError('Unexpected standalone save namespace; review before release')
    with tempfile.TemporaryDirectory(prefix='courtyard-release-') as temporary:
        stage = Path(temporary) / 'project'
        shutil.copytree(source, stage, ignore=shutil.ignore_patterns('.godot', '.git', 'build', 'exports'))
        (stage / 'project.godot').write_text(original.replace(MAIN, COURTYARD).replace(
            save_name, 'config/custom_user_dir_name="ProjectTactic-Courtyard"'))
        yield stage


def require_empty_output(output):
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise RuntimeError(f'Export directory must be empty: {output}')
    output.mkdir(parents=True, exist_ok=True)


def check_output(returncode, output):
    clean = ANSI.sub('', output)
    if returncode or any(marker in clean for marker in ('ERROR:', 'FAIL:', 'Parse Error:')):
        raise RuntimeError(f'Courtyard command failed (exit {returncode}); see diagnostics')


def run(command, env=None, marker=None):
    print('\n=== ' + ' '.join(map(str, command)) + ' ===', flush=True)
    try:
        result = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, errors='replace', timeout=300)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        print(output.decode(errors='replace') if isinstance(output, bytes) else output, flush=True)
        raise RuntimeError('Courtyard command exceeded 300 seconds') from error
    print(result.stdout, flush=True)
    check_output(result.returncode, result.stdout)
    if marker is not None and marker not in result.stdout:
        raise RuntimeError(f'Missing success marker: {marker}')
    return result.stdout.strip()


def assert_production_pack(pack):
    data = pack.read_bytes()
    if data[:4] != b'GDPC':
        raise ValueError(f'Invalid Godot package: {pack}')
    if b'courtyard_browser_qa/' in data or b'__courtyardQA' in data:
        raise ValueError('Browser observer leaked into production courtyard package')


def package(output, production=True):
    for name in ('index.html', 'index.js', 'index.pck', 'index.wasm'):
        file = output / name
        if not file.is_file() or file.stat().st_size == 0:
            raise RuntimeError(f'Missing fresh output: {file}')
    if production:
        assert_production_pack(output / 'index.pck')
    run([sys.executable, 'tools/prepare_playable_web.py', str(output)])
    run(['node', 'tools/check_web_package.mjs', str(output)])


def export(output, qa_output, godot='godot'):
    output, qa_output = output.resolve(), qa_output.resolve()
    if output == qa_output or output in qa_output.parents or qa_output in output.parents:
        raise ValueError('Production and QA exports must be separate directories')
    require_empty_output(output)
    require_empty_output(qa_output)
    with staged_project() as stage, tempfile.TemporaryDirectory(prefix='courtyard-data-') as data:
        env = {**os.environ, 'XDG_DATA_HOME': data, 'XDG_CONFIG_HOME': data, 'XDG_CACHE_HOME': data}
        templates = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'godot/export_templates'
        if templates.is_dir():
            target = Path(data) / 'godot/export_templates'
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(templates.resolve(), target_is_directory=True)
        engine = [godot, '--headless', '--path', str(stage)]
        run([*engine, '--import'], env)
        run([*engine, '--script', 'res://tests/validate_all_scripts.gd'], env,
            'Godot script validation: OK (')
        run([*engine, '--export-release', 'Web', str(output / 'index.html')], env)
        package(output)
        # Only this second, separate export contains the read-only observer.
        shutil.copytree(ROOT / 'tools/courtyard_browser_qa', stage / 'courtyard_browser_qa')
        project = stage / 'project.godot'
        text = project.read_text()
        if text.count('[autoload]') != 1:
            raise ValueError('Expected one autoload section for isolated browser observer')
        project.write_text(text.replace('[autoload]', '[autoload]\nCourtyardWebObserver="*res://courtyard_browser_qa/Observer.gd"'))
        run([*engine, '--import'], env)
        run([*engine, '--script', 'res://courtyard_browser_qa/ObserverContract.gd'], env,
            'Courtyard observer: 25 checks, 0 failures')
        run([*engine, '--export-release', 'Web', str(qa_output / 'index.html')], env)
        package(qa_output, production=False)
    # Provenance is written only after both fresh packages pass integrity checks.
    info = {'source_commit': run(['git', 'rev-parse', 'HEAD']),
            'godot_version': run([godot, '--version']),
            'scene': 'res://prototypes/blooming/BloomingBattle.tscn',
            'save_namespace': 'ProjectTactic-Courtyard'}
    (output / 'build-info.json').write_text(json.dumps(info, indent=2) + '\n')
    print('Courtyard packages prepared; browser acceptance is still required')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--qa-directory', required=True, type=Path)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    try:
        export(args.directory, args.qa_directory, args.godot)
    except (RuntimeError, ValueError, OSError) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        raise SystemExit(1)
