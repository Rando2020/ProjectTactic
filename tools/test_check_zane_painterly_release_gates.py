"""Real child-process boundary fixtures, not asset or rendering acceptance."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

RUNNER = Path(__file__).with_name('check_zane_painterly_release_gates.py')
SOURCE = Path('assets/source/zane-painterly-v1')
SCRIPTS = ('validate_export.py', 'test_validate_export.py', 'check_motion_clearance.py')
REPORTS = ('validation_report.json', 'motion_clearance_report.json')


class PainterlyAssetGateTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(RUNNER.is_file(), 'Portable staged asset gate is not implemented')
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'checkout'
        self.output = Path(self.tmp.name) / 'evidence'
        (self.root / 'tools').mkdir(parents=True)
        shutil.copyfile(RUNNER, self.root / 'tools' / RUNNER.name)
        (self.root / 'tools/validate_zane_impact_asset.py').write_text('# parser fixture\n')
        source = self.root / SOURCE
        (source / 'textures').mkdir(parents=True)
        (source / 'textures/zane_painterly_atlas.png').write_bytes(b'fixture atlas')
        (source / 'zane_painterly_v1.blend').write_bytes(b'must not stage Blender source')
        for report in REPORTS:
            (source / report).write_text('old source report must not be reused')
        for name in ('zane_v2', 'zane_impact_v1', 'zane_painterly_v1'):
            directory = self.root / 'godot/assets/3d/characters' / name
            directory.mkdir(parents=True)
            (directory / (name + '.glb')).write_bytes(b'fixture ' + name.encode())
            (directory / 'presentation.json').write_text('{"approved": true}\n')
        for script in SCRIPTS:
            self.write_script(script)

    def write_script(self, name, *, exit_code=0, report=True, wait=False):
        report_name = {'validate_export.py': 'validation_report.json',
                       'check_motion_clearance.py': 'motion_clearance_report.json'}.get(name)
        body = '''import json, sys, time
from pathlib import Path
here = Path(__file__).resolve().parent
root = here.parents[2]
if sys.flags.optimize:
    raise RuntimeError('Assertions disabled')
assert sys.argv[1:] == [], 'Validator flags changed'
assert (root / 'tools/validate_zane_impact_asset.py').is_file()
assert (here / 'textures/zane_painterly_atlas.png').read_bytes() == b'fixture atlas'
assert not (here / 'zane_painterly_v1.blend').exists(), 'Unneeded Blender source copied'
for asset in ('zane_v2', 'zane_impact_v1', 'zane_painterly_v1'):
    directory = root / 'godot/assets/3d/characters' / asset
    assert (directory / (asset + '.glb')).is_file()
    (directory / 'presentation.json').write_text('stage-only mutation')
print('child diagnostic ' + Path(__file__).name, flush=True)
print('STAGE=' + str(root), flush=True)
'''
        if wait:
            body += 'time.sleep(5)\n'
        if report_name and report:
            body += f"(here / {report_name!r}).write_text(json.dumps({{'fresh': True, 'exit_code': {exit_code}}}))\n"
        body += f'raise SystemExit({exit_code})\n'
        (self.root / SOURCE / name).write_text(body)

    def snapshot(self):
        return {str(p.relative_to(self.root)): p.read_bytes()
                for p in self.root.rglob('*') if p.is_file()}

    def run_gate(self, timeout=10, output=None):
        return subprocess.run([sys.executable, str(self.root / 'tools' / RUNNER.name),
                               '--output', str(output or self.output), '--timeout', str(timeout)],
                              cwd=self.root, capture_output=True, text=True, timeout=20,
                              env={**os.environ, 'PYTHONOPTIMIZE': '2'})

    def test_stages_only_required_inputs_preserves_source_and_retains_fresh_reports(self):
        before = self.snapshot()
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        for report in REPORTS:
            self.assertEqual(json.loads((self.output / report).read_text()),
                             {'fresh': True, 'exit_code': 0})
        summary = json.loads((self.output / 'release-gates.json').read_text())
        self.assertEqual(summary['status'], 'passed')
        self.assertEqual([g['returncode'] for g in summary['gates']], [0, 0, 0])
        for script in SCRIPTS:
            log = (self.output / (Path(script).stem + '.log')).read_text()
            self.assertIn('child diagnostic ' + script, log)
            stage = next(line[6:] for line in log.splitlines() if line.startswith('STAGE='))
            self.assertFalse(Path(stage).exists(), 'Temporary stage leaked')

    def test_each_failed_child_preserves_exit_code_diagnostics_reports_and_source(self):
        for script, code in zip(SCRIPTS, (7, 8, 9)):
            with self.subTest(script=script):
                self.write_script(script, exit_code=code)
                before = self.snapshot()
                result = self.run_gate()
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                self.assertEqual(self.snapshot(), before)
                summary = json.loads((self.output / 'release-gates.json').read_text())
                self.assertEqual(summary['status'], 'failed')
                self.assertEqual(len(summary['gates']), 3)
                gate = next(g for g in summary['gates'] if g['script'] == script)
                self.assertEqual(gate['returncode'], code)
                self.assertEqual(gate['status'], 'failed')
                self.assertIn('child diagnostic', (self.output / gate['log']).read_text())
                self.assertTrue(all((self.output / report).is_file() for report in REPORTS))
                self.write_script(script)

    def test_missing_fresh_report_fails_and_cannot_reuse_old_source_or_output(self):
        self.write_script('validate_export.py', report=False)
        self.output.mkdir()
        (self.output / 'validation_report.json').write_text('{"old": true}')
        before = self.snapshot()
        result = self.run_gate()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        self.assertFalse((self.output / 'validation_report.json').exists())
        summary = json.loads((self.output / 'release-gates.json').read_text())
        self.assertEqual(summary['gates'][0]['status'], 'missing-report')

    def test_timeout_fails_retains_partial_output_and_cleans_stage(self):
        self.write_script('validate_export.py', wait=True)
        before = self.snapshot()
        result = self.run_gate(timeout=.2)
        self.assertEqual(result.returncode, 124, result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        summary = json.loads((self.output / 'release-gates.json').read_text())
        self.assertEqual(summary['gates'][0]['status'], 'timeout')
        log = (self.output / 'validate_export.log').read_text()
        self.assertIn('child diagnostic validate_export.py', log)
        self.assertIn('TIMEOUT', log)
        stage = next(line[6:] for line in log.splitlines() if line.startswith('STAGE='))
        self.assertFalse(Path(stage).exists())

    def test_output_cannot_overwrite_source_files(self):
        before = self.snapshot()
        result = self.run_gate(output=self.root / SOURCE)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.snapshot(), before)
        self.assertIn('outside the checkout or under build/', result.stderr)


if __name__ == '__main__':
    unittest.main()
