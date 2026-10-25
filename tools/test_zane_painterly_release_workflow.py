"""Execute new CI shell blocks; fixtures are not actual asset/fallback evidence."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from test_zane_release_workflow import shell_block

TESTS = 'Test painterly release gate contracts'
ASSET = 'Validate painterly exported asset in isolation'
FALLBACK = 'Validate seven painterly fallback probes'
UNIT_FILES = ('test_check_zane_painterly_fallbacks.py',
              'test_check_zane_painterly_release_gates.py',
              'test_zane_painterly_release_workflow.py')


class PainterlyReleaseWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        binary = self.root / 'python'
        binary.write_text('#!' + sys.executable + '\n' + '''import json, os, sys
from pathlib import Path
with Path('calls.jsonl').open('a') as log:
    log.write(json.dumps(sys.argv[1:]) + '\\n')
print('fixture gate diagnostic', flush=True)
if os.environ.get('FAIL_COMMAND') in sys.argv[1:]:
    sys.exit(7)
''')
        binary.chmod(0o755)

    def run_step(self, name, failure=''):
        return subprocess.run(['bash', '--noprofile', '--norc', '-e', '-c', shell_block(name)],
                              cwd=self.root, capture_output=True, text=True, timeout=10,
                              env={**os.environ, 'PATH': f'{self.root}:{os.environ["PATH"]}',
                                   'FAIL_COMMAND': failure})

    def calls(self):
        return [json.loads(line) for line in (self.root / 'calls.jsonl').read_text().splitlines()]

    def test_workflow_runs_all_three_focused_regression_files(self):
        result = self.run_step(TESTS)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.calls(), [['-m', 'unittest', 'discover', '-s', 'tools', '-p', name]
                                       for name in UNIT_FILES])

    def test_each_unit_failure_stops_the_step(self):
        for name in UNIT_FILES:
            with self.subTest(name=name):
                result = self.run_step(TESTS, name)
                self.assertEqual(result.returncode, 7, result.stdout + result.stderr)

    def test_asset_and_actual_fallback_gates_keep_separate_artifact_paths_and_exit_codes(self):
        for step, script, output in (
                (ASSET, 'tools/check_zane_painterly_release_gates.py',
                 'build/painterly-release-gates/assets'),
                (FALLBACK, 'tools/check_zane_painterly_fallbacks.py',
                 'build/painterly-release-gates/fallbacks')):
            with self.subTest(step=step):
                result = self.run_step(step)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(self.calls()[-1], [script, '--output', output])
                result = self.run_step(step, script)
                self.assertEqual(result.returncode, 7, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
