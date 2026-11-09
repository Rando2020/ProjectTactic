"""Release staging must preserve source and keep QA out of the public package."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


class CourtyardWebTests(unittest.TestCase):
    def module(self):
        path = ROOT / 'tools/export_courtyard_web.py'
        self.assertTrue(path.is_file(), 'Courtyard release exporter is not implemented')
        spec = importlib.util.spec_from_file_location('courtyard_export', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def source(self, root):
        source = root / 'source'
        source.mkdir()
        (source / 'project.godot').write_text('[application]\nrun/main_scene="res://prototypes/isometric/Skirmish.tscn"\nconfig/custom_user_dir_name="ProjectTactic-IsometricProof"\n\n[autoload]\nVFX="*res://vfx.gd"\n')
        (source / 'export_presets.cfg').write_text('[preset.0]\nname="Web"\n')
        (source / '.godot').mkdir()
        (source / '.godot/stale').write_text('old import')
        return source

    def test_release_stage_changes_only_copy_and_is_always_removed(self):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            source = self.source(Path(temp))
            original = (source / 'project.godot').read_bytes()
            with runner.staged_project(source) as stage:
                text = (stage / 'project.godot').read_text()
                self.assertIn('run/main_scene="res://prototypes/blooming/BloomingBattle.tscn"', text)
                self.assertIn('config/custom_user_dir_name="ProjectTactic-Courtyard"', text)
                self.assertFalse((stage / '.godot').exists())
                self.assertFalse((stage / 'courtyard_browser_qa').exists())
            self.assertFalse(stage.exists())
            self.assertEqual((source / 'project.godot').read_bytes(), original)

    def test_exception_restores_source_and_removes_stage(self):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            source = self.source(Path(temp))
            original = (source / 'project.godot').read_bytes()
            with self.assertRaisesRegex(RuntimeError, 'simulated export failure'):
                with runner.staged_project(source) as stage:
                    raise RuntimeError('simulated export failure')
            self.assertFalse(stage.exists())
            self.assertEqual((source / 'project.godot').read_bytes(), original)

    def test_unexpected_entry_point_is_rejected(self):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            source = self.source(Path(temp))
            (source / 'project.godot').write_text('[application]\nrun/main_scene="res://unknown.tscn"\n')
            with self.assertRaisesRegex(ValueError, 'entry point'):
                with runner.staged_project(source):
                    self.fail('Unexpected entry point was accepted')

    def test_production_pack_rejects_observer_and_invalid_pack(self):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            pack = Path(temp) / 'index.pck'
            for content in (b'not pck', b'GDPCcourtyard_browser_qa/Observer.gdc', b'GDPC__courtyardQA'):
                pack.write_bytes(content)
                with self.assertRaises(ValueError):
                    runner.assert_production_pack(pack)
            pack.write_bytes(b'GDPCclean production fixture')
            runner.assert_production_pack(pack)

    def test_stale_output_is_rejected_before_any_export(self):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / 'web'
            output.mkdir()
            (output / 'index.html').write_text('stale')
            with self.assertRaisesRegex(RuntimeError, 'empty'):
                runner.require_empty_output(output)

    def test_silent_script_error_and_fail_marker_fail_closed(self):
        runner = self.module()
        for message in ('SCRIPT ERROR: Parse error', 'ERROR: asset missing', 'FAIL: regression'):
            with self.subTest(message=message), self.assertRaises(RuntimeError):
                runner.check_output(0, message)
        with self.assertRaises(RuntimeError):
            runner.check_output(2, 'no error text')
        runner.check_output(0, '18 checks, 0 failures')

    def test_browser_outcome_checks_reject_cancel_cost_and_noop_move(self):
        path = ROOT / 'tools/browser_courtyard_smoke.py'
        self.assertTrue(path.is_file(), 'Courtyard browser acceptance is not implemented')
        spec = importlib.util.spec_from_file_location('courtyard_browser', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        before = {'id': 'zane', 'position': [3, 8], 'hp': 320, 'mp': 90, 'moved': False, 'acted': False}
        module.assert_unchanged(before, dict(before))
        with self.assertRaises(AssertionError):
            module.assert_unchanged(before, {**before, 'mp': 78})
        with self.assertRaises(AssertionError):
            module.assert_moved(before, dict(before), [4, 8])
        module.assert_moved(before, {**before, 'position': [4, 8], 'moved': True}, [4, 8])
        with self.assertRaises(AssertionError):
            module.assert_moved(before, {**before, 'position': [4, 8], 'moved': True, 'mp': 78}, [4, 8])

    def test_full_export_packages_both_outputs_and_only_production_has_provenance(self):
        self.export_fixture('')

    def test_production_boot_rejects_errors_arriving_during_settle_or_capture(self):
        spec = importlib.util.spec_from_file_location('courtyard_browser', ROOT / 'tools/browser_courtyard_smoke.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        class LateErrorCDP:
            errors = []
            def evaluate(self, expression):
                if expression == 'location.href': return 'http://localhost/courtyard/index.html'
                if 'typeof window.__courtyardQA' in expression: return 'undefined'
                return True
            def command(self, method, params):
                if method == 'Page.captureScreenshot':
                    self.errors.append({'late_script_error': 'WebGL failure after loader hid'})
                    return {'data': ''}
                return {}
        with tempfile.TemporaryDirectory() as temp, mock.patch.object(module.time, 'sleep'):
            smoke = module.CourtyardSmoke(LateErrorCDP(), Path(temp), 1)
            self.assertTrue(hasattr(smoke, 'check_production'), 'Production boot must have a testable fail-closed gate')
            with self.assertRaisesRegex(AssertionError, 'production'):
                smoke.check_production('http://localhost/courtyard/index.html')

    def test_export_failure_cannot_receive_publishable_provenance(self):
        for failure in ('silent', 'empty', 'observer-leak', 'missing-marker'):
            with self.subTest(failure=failure):
                self.export_fixture(failure)

    def export_fixture(self, failure):
        runner = self.module()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = self.source(root)
            engine = root / 'engine'
            engine.write_text('''#!/usr/bin/env python3
import os, pathlib, sys
args = sys.argv[1:]
failure = os.environ['COURTYARD_TEST_FAILURE']
if args == ['--version']: print('4.6.3.test'); sys.exit(0)
if '--import' in args:
 if failure == 'silent': print('SCRIPT ERROR: fixture import failed')
elif '--script' in args:
 if 'validate_all_scripts.gd' in args[-1]:
  if failure != 'missing-marker': print('Godot script validation: OK (78 scripts loaded)')
 else: print('Courtyard observer: 25 checks, 0 failures')
elif '--export-release' in args:
 out = pathlib.Path(args[-1]).parent
 (out/'index.html').write_text('<html><script src="index.js"></script></html>')
 (out/'index.js').write_text('' if failure == 'empty' else '// engine')
 (out/'index.wasm').write_bytes(b'\\x00asm\\x01\\x00\\x00\\x00')
 (out/'index.pck').write_bytes(b'GDPC__courtyardQA' if failure == 'observer-leak' else b'GDPCfixture')
else: sys.exit('Unexpected arguments')
''')
            engine.chmod(0o755)
            public, qa = root / 'public', root / 'qa'
            with mock.patch.object(runner, 'SOURCE', source), mock.patch.dict(os.environ, {'COURTYARD_TEST_FAILURE': failure}):
                if failure:
                    with self.assertRaises((RuntimeError, ValueError)):
                        runner.export(public, qa, str(engine))
                    self.assertFalse((public / 'build-info.json').exists())
                    self.assertFalse((qa / 'build-info.json').exists())
                else:
                    runner.export(public, qa, str(engine))
                    info = json.loads((public / 'build-info.json').read_text())
                    self.assertEqual(info['godot_version'], '4.6.3.test')
                    self.assertEqual(info['save_namespace'], 'ProjectTactic-Courtyard')
                    self.assertTrue((public / 'asset-parts.json').is_file())
                    self.assertTrue((qa / 'asset-parts.json').is_file())
                    self.assertFalse((qa / 'build-info.json').exists())


if __name__ == '__main__':
    unittest.main()
