#!/usr/bin/env python3
"""Regression checks for the isolated Godot validation runner (no engine required)."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

RUNNER = Path(__file__).with_name('check_playable_loop.py')
EXPECTED = {
    'test_combat_formula.tscn', 'test_combat_execution.tscn',
    'test_spell_outcome_feedback.tscn', 'test_healing_contract.tscn',
    'test_hit_secondary_status.tscn',
    'test_turn_order.tscn', 'test_progression_speed.tscn', 'test_cancel_move_input.tscn',
    'test_silence_contract.tscn',
    'test_scout_tradeoff.tscn', 'test_scout_outcome_integration.tscn',
    'test_tactical_contract_integration.tscn',
    'test_kael_presentation.tscn', 'test_mira_presentation.tscn', 'test_zane_presentation.tscn',
    'test_shared_rig_presentation.tscn', 'test_terrain_cleanup.tscn',
    'test_recovered_assets.gd', 'test_ui_readability.gd', 'test_playable_loop.tscn',
}


class ValidationRunnerTests(unittest.TestCase):
    def run_fixture(self, failure=''):
        with tempfile.TemporaryDirectory() as data:
            root = Path(data)
            fake = root / 'fake-godot'
            log = root / 'calls.jsonl'
            fake.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['RUNNER_TEST_LOG'], 'a') as out:
    out.write(json.dumps({'args': sys.argv[1:], 'data': os.environ['XDG_DATA_HOME'], 'config': os.environ.get('XDG_CONFIG_HOME'), 'cache': os.environ.get('XDG_CACHE_HOME')}) + '\\n')
mode = os.environ.get('RUNNER_TEST_FAILURE', '') if 'test_kael_presentation.tscn' in sys.argv[-1] else ''
if mode == 'exit':
    raise SystemExit(1)
if mode == 'script':
    print('SCRIPT ERROR: simulated contract failure')
if mode == 'count':
    print('10 failures')
if mode not in ('missing', 'count'):
    print('0 failures; 0 fail; Terrain cleanup: 10 enable/redraw/disable cycles passed; Recovered asset contract: OK')
''')
            fake.chmod(0o755)
            result = subprocess.run([sys.executable, str(RUNNER), str(fake)],
                env={**os.environ, 'RUNNER_TEST_LOG': str(log), 'RUNNER_TEST_FAILURE': failure},
                capture_output=True, text=True, timeout=10)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            return result, calls

    def test_timeout_preserves_partial_diagnostics(self):
        spec = importlib.util.spec_from_file_location('tactics_runner', RUNNER)
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        output = io.StringIO()
        timeout = subprocess.TimeoutExpired('godot', 120, output=b'progress before timeout\n', stderr=b'engine diagnostic\n')
        with mock.patch.object(runner, 'CONTRACTS', [('test_playable_loop.tscn', '0 failures')]), \
             mock.patch.object(runner.subprocess, 'run', side_effect=timeout), \
             mock.patch.object(sys, 'argv', ['check_playable_loop.py']), contextlib.redirect_stdout(output):
            self.assertEqual(runner.main(), 1)
        self.assertIn('progress before timeout', output.getvalue())
        self.assertIn('engine diagnostic', output.getvalue())
        self.assertIn('120-second limit', output.getvalue())

    def test_all_contracts_run_with_separate_isolated_settings(self):
        result, calls = self.run_fixture()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual({Path(c['args'][-1]).name for c in calls}, EXPECTED)
        self.assertEqual(len(calls), len(EXPECTED))
        self.assertEqual(len({c['data'] for c in calls}), len(EXPECTED))
        for call in calls:
            self.assertEqual(call['data'], call['config'])
            self.assertEqual(call['data'], call['cache'])
        terrain = next(c for c in calls if c['args'][-1].endswith('test_terrain_cleanup.tscn'))
        self.assertNotIn('--script', terrain['args'])

    def test_nonzero_exit_fails_aggregate(self):
        self.assertEqual(self.run_fixture('exit')[0].returncode, 1)

    def test_script_error_fails_even_with_success_marker(self):
        self.assertEqual(self.run_fixture('script')[0].returncode, 1)

    def test_nonzero_failure_count_cannot_match_zero(self):
        self.assertEqual(self.run_fixture('count')[0].returncode, 1)

    def test_missing_contract_marker_fails(self):
        self.assertEqual(self.run_fixture('missing')[0].returncode, 1)


if __name__ == '__main__':
    unittest.main()
