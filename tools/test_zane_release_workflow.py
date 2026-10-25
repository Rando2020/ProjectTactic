"""Execute CI shell blocks at external process boundaries; no browser claim here."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github/workflows/godot-validate.yml'
EXPORT = 'Export isolated Zane showcase Web QA build'
PACKAGE = 'Package isolated Zane showcase Web QA build'
BROWSER = 'Exercise Zane showcase input and capture browser evidence'
EVIDENCE = 'docs/qa/browser-zane-captures'
FILES = ('zane-practice-actual-3d-loaded.png', 'zane-3d-movement-completed.png',
         'zane-fire-outcome-and-cleanup.png', 'report.json', 'browser-events.json')


def shell_block(name):
    """Read the actual multiline run block without a new YAML CI dependency."""
    sections = re.split(r'^      - name: ', WORKFLOW.read_text(), flags=re.M)
    for section in sections[1:]:
        if section.splitlines()[0] == name:
            lines = section.splitlines()
            start = lines.index('        run: |') + 1
            return '\n'.join(line[10:] for line in lines[start:] if line.startswith('          '))
    raise AssertionError(f'Missing CI step: {name}')


class ZaneReleaseWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        (self.root / 'tools').mkdir()
        shutil.copy(ROOT / 'tools/export_browser_qa.py', self.root / 'tools')
        fake = self.bin / 'fake'
        fake.write_text('#!' + sys.executable + '\n' + r'''
import json, os, signal, subprocess, sys, time
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open('calls.jsonl', 'a') as log:
    log.write(json.dumps([name, *args]) + '\n')
mode = os.environ.get('GATE_TEST_MODE', '')
if name == 'google-chrome' or (name == 'python' and args[:2] == ['-m', 'http.server']):
    kind = 'browser' if name == 'google-chrome' else 'server'
    def stop(*_):
        Path(kind + '.stopped').write_text('stopped')
        sys.exit(0)
    signal.signal(signal.SIGTERM, stop)
    Path(kind + '.started').write_text(str(os.getpid()))
    print(kind + ' process diagnostics', flush=True)
    while True: time.sleep(.01)
if name == 'python' and args[:1] in (['-c'], ['-']):
    sys.exit(subprocess.call([sys.executable, *args]))
if name == 'python' and args[:1] == ['tools/export_browser_qa.py']:
    print('export diagnostics', flush=True)
    output = Path(args[args.index('--output') + 1])
    output.parent.mkdir(parents=True, exist_ok=True)
    for suffix in ('.html', '.pck', '.wasm'): output.with_suffix(suffix).write_bytes(b'GDPCfixture')
    if mode == 'export-fails': sys.exit(7)
if name == 'python' and args[:1] == ['tools/prepare_playable_web.py']:
    print('package preparation diagnostics', flush=True)
    if mode == 'prepare-fails': sys.exit(5)
if name == 'node' and args[:1] == ['tools/check_web_package.mjs']:
    print('package validation diagnostics', flush=True)
    if mode == 'package-check-fails': sys.exit(6)
if name == 'godot':
    output = Path(args[-1])
    if str(output).startswith('../'): output = Path(str(output)[3:])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.with_suffix('.pck').write_bytes(b'GDPC' + (b'res://tests/browser_qa/leaked.gdc' if mode == 'leak' else b'production'))
    print('production re-export diagnostics', flush=True)
    if mode == 'reexport-script-error': print('SCRIPT ERROR: simulated re-export failure', flush=True)
if name == 'python' and args[:1] == ['tools/browser_combat_smoke.py']:
    until = time.monotonic() + 2
    while not all(Path(k + '.started').exists() for k in ('browser', 'server')):
        if time.monotonic() > until: raise RuntimeError('fake server/browser did not start')
        time.sleep(.01)
    output = Path(args[args.index('--output') + 1])
    output.mkdir(parents=True, exist_ok=True)
    files = ('zane-practice-actual-3d-loaded.png', 'zane-3d-movement-completed.png',
             'zane-fire-outcome-and-cleanup.png', 'report.json', 'browser-events.json')
    if '--scenario' in args and args[args.index('--scenario') + 1] == 'zane-duel':
        files = ('zane-duel-actual-3d-loaded.png', 'zane-duel-3d-movement-completed.png',
                 'zane-duel-sword-outcome-and-cleanup.png', 'report.json', 'browser-events.json')
    for filename in files:
        if mode != 'omit:' + filename: (output / filename).write_bytes(b'evidence fixture')
    print('browser smoke diagnostics', flush=True)
    if mode == 'smoke-fails': sys.exit(9)
''')
        fake.chmod(0o755)
        for name in ('python', 'godot', 'git', 'node', 'google-chrome'):
            (self.bin / name).symlink_to(fake)

    def run_step(self, name, mode=''):
        for kind in ('browser', 'server'):
            for suffix in ('started', 'stopped'):
                (self.root / f'{kind}.{suffix}').unlink(missing_ok=True)
        result = subprocess.run(['bash', '--noprofile', '--norc', '-e', '-c', shell_block(name)],
                              cwd=self.root, env={**os.environ, 'PATH': f'{self.bin}:{os.environ["PATH"]}',
                                                 'GATE_TEST_MODE': mode},
                              text=True, capture_output=True, timeout=10)
        if (self.root / 'calls.jsonl').exists():
            for call in self.calls():
                if call[0] == 'google-chrome':
                    profile = next(a.partition('=')[2] for a in call if a.startswith('--user-data-dir='))
                    self.addCleanup(shutil.rmtree, profile, True)
        return result

    def calls(self):
        return [json.loads(line) for line in (self.root / 'calls.jsonl').read_text().splitlines()]

    def test_separate_export_and_package_do_not_replace_quickstep_output(self):
        result = self.run_step(EXPORT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        export = next(c for c in self.calls() if c[1:2] == ['tools/export_browser_qa.py'])
        self.assertEqual(export[export.index('--scenario') + 1], 'zane-showcase')
        self.assertEqual(export[export.index('--production-pck') + 1], 'build/web/index.pck')
        self.assertEqual(export[export.index('--output') + 1], 'build/web-qa-zane/index.html')
        self.assertFalse((self.root / 'build/web-qa').exists())
        result = self.run_step(PACKAGE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(['python', 'tools/prepare_playable_web.py', 'build/web-qa-zane'], self.calls())
        self.assertIn(['node', 'tools/check_web_package.mjs', 'build/web-qa-zane'], self.calls())
        self.assertTrue((self.root / EVIDENCE / 'export.log').stat().st_size)
        self.assertTrue((self.root / EVIDENCE / 'production-reexport.log').stat().st_size)

    def test_export_failure_survives_tee_and_retains_log(self):
        result = self.run_step(EXPORT, 'export-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('export diagnostics', (self.root / EVIDENCE / 'export.log').read_text())
        self.assertFalse(any(c[0] == 'godot' for c in self.calls()))

    def test_reexported_production_pack_cannot_contain_qa_resources(self):
        result = self.run_step(EXPORT, 'leak')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('QA observer leaked', result.stdout + result.stderr)

    def test_reexport_script_error_fails_even_when_engine_exits_zero(self):
        result = self.run_step(EXPORT, 'reexport-script-error')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('SCRIPT ERROR: simulated re-export failure',
                      (self.root / EVIDENCE / 'production-reexport.log').read_text())

    def test_browser_uses_separate_build_and_emits_required_diagnostics(self):
        result = self.run_step(BROWSER)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(['python', '-m', 'http.server', '8000', '--directory', 'build/web-qa-zane'], self.calls())
        smoke = next(c for c in self.calls() if c[1:2] == ['tools/browser_combat_smoke.py'])
        self.assertEqual(smoke[smoke.index('--scenario') + 1], 'zane-showcase')
        self.assertEqual(smoke[smoke.index('--budget') + 1], '180')
        self.assertEqual(smoke[smoke.index('--max-player-turns') + 1], '20')
        chrome = next(c for c in self.calls() if c[0] == 'google-chrome')
        profile = next(a.partition('=')[2] for a in chrome if a.startswith('--user-data-dir='))
        self.assertNotEqual(profile, '/tmp/projecttactic-chrome')
        self.addCleanup(shutil.rmtree, profile, True)
        for filename in (*FILES, 'server.log', 'chrome.log', 'smoke.log'):
            self.assertTrue((self.root / EVIDENCE / filename).stat().st_size, filename)
        for kind in ('browser', 'server'):
            self.assertTrue((self.root / (kind + '.stopped')).exists())

    def test_browser_failure_survives_tee_and_still_stops_processes(self):
        result = self.run_step(BROWSER, 'smoke-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('browser smoke diagnostics', (self.root / EVIDENCE / 'smoke.log').read_text())
        for kind in ('browser', 'server'):
            self.assertTrue((self.root / (kind + '.stopped')).exists())

    def test_successful_driver_without_each_mandatory_capture_or_report_fails(self):
        for filename in FILES:
            with self.subTest(filename=filename):
                path = self.root / EVIDENCE / filename
                if path.exists(): path.unlink()
                result = self.run_step(BROWSER, 'omit:' + filename)
                self.assertNotEqual(result.returncode, 0, filename)


if __name__ == '__main__':
    unittest.main()
