#!/usr/bin/env python3
"""Exercise the Pages export gate; only the external Godot process is simulated."""
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

ROOT = Path(__file__).resolve().parents[1]


class PagesExportTests(unittest.TestCase):
    def test_timeout_preserves_partial_diagnostics(self):
        spec = importlib.util.spec_from_file_location('pages_export', ROOT / 'tools/export_pages_web.py')
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        output = io.StringIO()
        timeout = subprocess.TimeoutExpired('godot', 300, output=b'import progress\nSCRIPT ERROR: timed out\n')
        with mock.patch.object(runner.subprocess, 'run', side_effect=timeout), contextlib.redirect_stdout(output):
            with self.assertRaisesRegex(RuntimeError, '300-second limit'):
                runner.run_checked(['godot', '--import'])
        self.assertIn('import progress', output.getvalue())
        self.assertIn('SCRIPT ERROR: timed out', output.getvalue())

    def run_export(self, failure=''):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            engine = root / 'godot'
            log = root / 'calls.jsonl'
            output = root / 'web'
            engine.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ['PAGES_TEST_LOG'], 'a') as out:
    out.write(json.dumps(args) + '\\n')
mode = os.environ['PAGES_TEST_FAILURE']
if args == ['--version']:
    print('4.6.3.stable.official.7d41c59c4')
    sys.exit(0)
if '--import' in args:
    if mode == 'exit': sys.exit(9)
    if mode == 'import': print("ERROR: Not a WAV file. File should start with 'RIFF', but found 'vers'", file=sys.stderr)
elif 'res://tests/validate_all_scripts.gd' in args:
    print('Godot script validation: OK (63 scripts loaded)')
    if mode == 'script': print('SCRIPT ERROR: Parse Error: Could not preload resource file')
    if mode in ('leak', 'leak-script'):
        print('WARNING: ObjectDB instances leaked at exit (run with --verbose for details).')
        print('ERROR: 2 resources still in use at exit (run with --verbose for details).')
        if mode == 'leak-script': print('SCRIPT ERROR: Parse Error: resource still in use')
elif 'res://tests/test_asset_manifest.gd' in args:
    if mode != 'marker': print('Asset manifest contract: OK (94 assertions)')
    if mode == 'asset': print('ERROR: Failed loading resource: res://assets/bad.png.')
elif '--export-release' in args:
    output = pathlib.Path(args[-1]).parent
    (output / 'index.html').write_text('<html><script src="index.js"></script></html>')
    (output / 'index.js').write_text('' if mode == 'empty' else '// Godot loader')
    (output / 'index.wasm').write_bytes(b'bad wasm' if mode == 'package' else b'\\x00asm\\x01\\x00\\x00\\x00')
    (output / 'index.pck').write_bytes(b'GDPCfixture')
    if mode == 'export': print('ERROR: Failed to export resource')
else:
    sys.exit('Unexpected Godot command: ' + repr(args))
''')
            engine.chmod(0o755)
            result = subprocess.run(
                [sys.executable, str(ROOT / 'tools/export_pages_web.py'), str(output), '--godot', str(engine)],
                cwd=ROOT, env={**os.environ, 'PAGES_TEST_LOG': str(log), 'PAGES_TEST_FAILURE': failure},
                capture_output=True, text=True, timeout=15,
            )
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            info = output / 'build-info.json'
            return result, calls, (output / 'asset-parts.js').exists(), json.loads(info.read_text()) if info.exists() else None

    def test_validates_scripts_and_assets_before_export_and_packages_real_bytes(self):
        result, calls, packaged, info = self.run_export()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIsNotNone(info)
        self.assertEqual(info['source_commit'], subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip())
        self.assertEqual(info['godot_version'], '4.6.3.stable.official.7d41c59c4')
        self.assertEqual(len(calls), 5)
        self.assertEqual(calls[4], ['--version'])
        self.assertIn('--import', calls[0])
        self.assertIn('res://tests/validate_all_scripts.gd', calls[1])
        self.assertIn('res://tests/test_asset_manifest.gd', calls[2])
        self.assertIn('--export-release', calls[3])
        self.assertTrue(packaged)
        self.assertIn('Web package:', result.stdout)

    def test_silent_engine_errors_and_missing_markers_stop_before_export(self):
        for failure, call_count, diagnostic in [
            ('import', 1, 'Not a WAV file'),
            ('script', 2, 'SCRIPT ERROR:'),
            ('leak-script', 2, 'SCRIPT ERROR:'),
            ('asset', 3, 'Failed loading resource'),
            ('marker', 3, 'Missing success marker'),
        ]:
            with self.subTest(failure=failure):
                result, calls, packaged, info = self.run_export(failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(diagnostic, result.stdout + result.stderr)
                self.assertEqual(len(calls), call_count)
                self.assertFalse(packaged)
                self.assertIsNone(info)

    def test_nonzero_engine_exit_stops_pipeline(self):
        result, calls, packaged, info = self.run_export('exit')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(calls), 1)
        self.assertFalse(packaged)
        self.assertIsNone(info)

    def test_export_error_stops_before_packaging(self):
        result, calls, packaged, info = self.run_export('export')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(calls), 4)
        self.assertIn('Failed to export resource', result.stdout + result.stderr)
        self.assertFalse(packaged)
        self.assertIsNone(info)

    def test_empty_export_is_rejected_before_packaging(self):
        result, _, packaged, info = self.run_export('empty')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('index.js', result.stdout + result.stderr)
        self.assertFalse(packaged)
        self.assertIsNone(info)

    def test_corrupt_web_package_fails_gate(self):
        result, calls, _, info = self.run_export('package')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(calls), 4)
        self.assertIn('AssertionError', result.stdout + result.stderr)
        self.assertIsNone(info)

    def test_documented_shutdown_leaks_remain_visible_but_do_not_block_export(self):
        result, _, packaged, info = self.run_export('leak')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(packaged)
        self.assertIn('2 resources still in use at exit', result.stdout)


if __name__ == '__main__':
    unittest.main()
