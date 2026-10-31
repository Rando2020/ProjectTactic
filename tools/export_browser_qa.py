#!/usr/bin/env python3
"""Stage a read-only browser observer only while validating/exporting the QA build."""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MAIN = b'run/main_scene="res://scenes/StartScreen.tscn"'
QA_MAIN = b'run/main_scene="res://tests/browser_qa/BattleBrowserQA.tscn"'


@contextmanager
def staged_qa_project(root: Path, scenario: str = 'quickstep'):
    if scenario not in ('quickstep', 'zane-showcase', 'zane-duel', 'chapel'):
        raise ValueError(f'Unknown browser QA scenario: {scenario}')
    qa_main = {'quickstep': QA_MAIN,
               'chapel': b'run/main_scene="res://tests/browser_qa/ChapelBootstrap.tscn"',
               'zane-showcase': b'run/main_scene="res://tests/browser_qa/ZaneShowcaseBootstrap.tscn"',
               'zane-duel': b'run/main_scene="res://tests/browser_qa/ZaneDuelBootstrap.tscn"'}[scenario]
    project = root / 'godot/project.godot'
    stage = root / 'godot/tests/browser_qa'
    if stage.exists() or stage.is_symlink():
        raise FileExistsError(f'Refusing preexisting QA staging directory: {stage}')
    original = project.read_bytes()
    if original.count(MAIN) != 1:
        raise ValueError('Expected exactly one production main_scene before QA staging')
    try:
        shutil.copytree(root / 'tools/browser_qa', stage)
        project.write_bytes(original.replace(MAIN, qa_main))
        yield stage
    finally:
        project.write_bytes(original)
        if stage.exists():
            shutil.rmtree(stage)


def assert_no_qa_resources(pack: Path) -> None:
    data = pack.read_bytes()
    if data[:4] != b'GDPC':
        raise ValueError(f'Not a Godot PCK: {pack}')
    # Unencrypted Godot PCK resource paths are plaintext, including .gdc/remap names.
    if b'tests/browser_qa/' in data or b'__projectTacticQA' in data:
        raise ValueError(f'QA observer leaked into production PCK: {pack}')


def run_godot(executable: str, arguments: list[str], environment: dict) -> None:
    try:
        result = subprocess.run([executable, '--headless', '--path', str(ROOT / 'godot'), *arguments],
                                env=environment, capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired as error:
        # TimeoutExpired may carry bytes even with text=True; retain diagnostics
        # before propagating the original timeout through staging's cleanup.
        for partial in (error.stdout, error.stderr):
            if partial:
                print(partial.decode(errors='replace') if isinstance(partial, bytes) else partial,
                      end='', flush=True)
        raise
    output = result.stdout + result.stderr
    print(output, end='', flush=True)
    if result.returncode or 'SCRIPT ERROR:' in output or 'Parse Error:' in output:
        raise RuntimeError(f'Godot QA validation/export failed (exit {result.returncode})')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--scenario', choices=['quickstep', 'zane-showcase', 'zane-duel', 'chapel'], default='quickstep')
    parser.add_argument('--production-pck', type=Path, default=ROOT / 'build/web/index.pck')
    parser.add_argument('--output', type=Path, default=ROOT / 'build/web-qa/index.html')
    parser.add_argument('--validate-only', action='store_true', help='Validate observer without exporting')
    args = parser.parse_args()
    assert_no_qa_resources(args.production_pck)
    with tempfile.TemporaryDirectory(prefix='tactics-browser-qa-') as data:
        env = {**os.environ, 'XDG_DATA_HOME': data, 'XDG_CONFIG_HOME': data, 'XDG_CACHE_HOME': data}
        # Keep normal template discovery for export while isolating all game save data.
        templates = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'godot/export_templates'
        target = Path(data) / 'godot/export_templates'
        if templates.is_dir():
            target.parent.mkdir(parents=True)
            target.symlink_to(templates.resolve(), target_is_directory=True)
        with staged_qa_project(ROOT, args.scenario):
            run_godot(args.godot, ['--import'], env)
            run_godot(args.godot, ['res://tests/browser_qa/ObserverContract.tscn'], env)
            if args.scenario == 'zane-showcase':
                run_godot(args.godot, ['res://tests/browser_qa/ObserverShowcaseContract.tscn'], env)
            if args.scenario == 'zane-duel':
                run_godot(args.godot, ['res://tests/browser_qa/ObserverDuelContract.tscn'], env)
                run_godot(args.godot, ['res://tests/browser_qa/ObserverDuelContract.tscn', '--', '--duel-observer-slow-tail'], env)
                run_godot(args.godot, ['res://tests/browser_qa/ObserverDuelContract.tscn', '--', '--duel-observer-slow-frame'], env)
            if not args.validate_only:
                args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
                run_godot(args.godot, ['--export-release', 'Web', str(args.output.resolve())], env)
    assert_no_qa_resources(args.production_pck)
    print('QA staging restored; production PCK contains no browser QA resources')


if __name__ == '__main__':
    main()
