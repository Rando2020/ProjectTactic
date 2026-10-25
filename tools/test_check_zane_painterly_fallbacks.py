"""Runner unit fixtures only; no imported-asset or visual acceptance claim."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

RUNNER = Path(__file__).with_name('check_zane_painterly_fallbacks.py')


class PainterlyFallbackRunnerTests(unittest.TestCase):
    def run_fixture(self, diagnostic=''):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            project = root / 'godot'
            for name in ('zane_painterly_v1', 'zane_impact_v1', 'zane_v2'):
                directory = project / 'assets/3d/characters' / name
                directory.mkdir(parents=True)
                (directory / (name + '.glb')).write_bytes(b'synthetic runner unit fixture, never rendered')
                (directory / (name + '.glb.import')).write_text('synthetic import marker')
                (directory / 'presentation.json').write_text(json.dumps({'profile_id':name,
                    'motion_source':{'model_sha256':'b'*64}}))
            before = {p.relative_to(project):p.read_bytes() for p in project.rglob('*') if p.is_file()}
            fake = root / 'fake-godot'
            fake.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
project = Path(sys.argv[sys.argv.index('--path') + 1])
assert str(project) != os.environ['ORIGINAL_PROJECT']
assert os.environ['XDG_DATA_HOME'] == os.environ['XDG_CACHE_HOME'] == os.environ['XDG_CONFIG_HOME']
with open(os.environ['CALLS'], 'a') as out:
    out.write(json.dumps({'project':str(project),'args':sys.argv[1:],'data':os.environ['XDG_DATA_HOME']})+'\\n')
print(os.environ.get('DIAGNOSTIC',''))
print('Painterly fallback: 25 checks, 0 failures')
''')
            fake.chmod(0o755)
            result = subprocess.run(['python', str(RUNNER), '--project', str(project), '--godot', str(fake),
                                     '--output', str(root/'logs')], capture_output=True,text=True,
                env={**os.environ,'ORIGINAL_PROJECT':str(project),'CALLS':str(root/'calls'),'DIAGNOSTIC':diagnostic},timeout=20)
            after = {p.relative_to(project):p.read_bytes() for p in project.rglob('*') if p.is_file()}
            calls = [json.loads(line) for line in (root/'calls').read_text().splitlines()] if (root/'calls').exists() else []
            return result,before,after,calls

    def test_all_seven_cases_are_isolated_and_original_assets_unchanged(self):
        result,before,after,calls = self.run_fixture()
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(before,after)
        self.assertEqual(len(calls),7)
        self.assertEqual(len({c['data'] for c in calls}),7)
        self.assertEqual(sum('--fallback=impact' in c['args'] for c in calls),5)
        self.assertEqual(sum('--fallback=original' in c['args'] for c in calls),1)
        self.assertEqual(sum('--fallback=sprite' in c['args'] for c in calls),1)
        self.assertEqual(sum('--broken-import' in c['args'] for c in calls),1)
        self.assertTrue(all(not Path(c['project']).exists() for c in calls))

    def test_script_or_shutdown_errors_fail_even_after_success_marker(self):
        for diagnostic in ('SCRIPT ERROR: unit fixture failure', 'ERROR: 2 resources still in use at exit.'):
            with self.subTest(diagnostic=diagnostic):
                result,before,after,calls = self.run_fixture(diagnostic)
                self.assertEqual(result.returncode,1,result.stdout+result.stderr)
                self.assertEqual(before,after)
                self.assertEqual(len(calls),7)


if __name__ == '__main__': unittest.main()
