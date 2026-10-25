"""Staging must be absent from production and reversible even on export failure."""
import tempfile
import io
import subprocess
from contextlib import redirect_stdout
from unittest.mock import patch
import unittest
from pathlib import Path

from export_browser_qa import staged_qa_project, assert_no_qa_resources, run_godot


class StagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'godot/tests').mkdir(parents=True)
        (self.root / 'tools/browser_qa').mkdir(parents=True)
        (self.root / 'tools/browser_qa/BattleBrowserQA.tscn').write_text('fixture')
        self.project = self.root / 'godot/project.godot'
        self.original = b'[application]\nrun/main_scene="res://scenes/StartScreen.tscn"\n'
        self.project.write_bytes(self.original)
        self.stage = self.root / 'godot/tests/browser_qa'

    def test_stages_only_during_context_and_restores_exact_bytes(self):
        with staged_qa_project(self.root):
            self.assertTrue((self.stage / 'BattleBrowserQA.tscn').is_file())
            self.assertIn(b'res://tests/browser_qa/BattleBrowserQA.tscn', self.project.read_bytes())
        self.assertEqual(self.project.read_bytes(), self.original)
        self.assertFalse(self.stage.exists())

    def test_exception_restores_configuration_and_cleans_stage(self):
        with self.assertRaisesRegex(RuntimeError, 'export failed'):
            with staged_qa_project(self.root):
                raise RuntimeError('export failed')
        self.assertEqual(self.project.read_bytes(), self.original)
        self.assertFalse(self.stage.exists())

    def test_timeout_keeps_partial_text_or_byte_logs_and_restores_staging(self):
        for stdout, stderr, expected in [('import progress\n', 'export stalled\n', 'import progress\nexport stalled\n'),
                                         (b'import progress\n', b'export stalled \xff\n', 'import progress\nexport stalled \ufffd\n'),
                                         (None, b'only stderr\n', 'only stderr\n')]:
            with self.subTest(stdout=stdout, stderr=stderr):
                expired = subprocess.TimeoutExpired(['godot'], 180, output=stdout, stderr=stderr)
                output = io.StringIO()
                with patch('export_browser_qa.subprocess.run', side_effect=expired), redirect_stdout(output):
                    with self.assertRaises(subprocess.TimeoutExpired) as caught:
                        with staged_qa_project(self.root):
                            run_godot('godot', ['--import'], {})
                self.assertIs(caught.exception, expired)
                self.assertEqual(output.getvalue(), expected)
                self.assertEqual(self.project.read_bytes(), self.original)
                self.assertFalse(self.stage.exists())

    def test_existing_stage_is_rejected_without_mutation(self):
        self.stage.mkdir()
        sentinel = self.stage / 'keep.txt'
        sentinel.write_text('unrelated')
        with self.assertRaises(FileExistsError):
            with staged_qa_project(self.root):
                self.fail('must refuse preexisting staged directory')
        self.assertEqual(sentinel.read_text(), 'unrelated')
        self.assertEqual(self.project.read_bytes(), self.original)

    def test_unexpected_main_scene_is_rejected_without_mutation(self):
        self.project.write_text('run/main_scene="another.tscn"\n')
        with self.assertRaisesRegex(ValueError, 'main_scene'):
            with staged_qa_project(self.root):
                pass
        self.assertFalse(self.stage.exists())
        self.assertEqual(self.project.read_text(), 'run/main_scene="another.tscn"\n')

    def test_partial_copy_failure_is_cleaned(self):
        from unittest.mock import patch
        def interrupted_copy(src, dest, **kwargs):
            dest.mkdir()
            (dest / 'partial.gd').write_text('partial')
            raise OSError('copy failed')
        with patch('export_browser_qa.shutil.copytree', side_effect=interrupted_copy):
            with self.assertRaises(OSError):
                with staged_qa_project(self.root):
                    pass
        self.assertFalse(self.stage.exists())
        self.assertEqual(self.project.read_bytes(), self.original)

    def test_workflow_checks_raw_production_pack_before_packager_removes_it(self):
        workflow = (Path(__file__).resolve().parents[1] / '.github/workflows/godot-validate.yml').read_text()
        self.assertLess(workflow.index('Export Godot Web build'), workflow.index('python tools/export_browser_qa.py'))
        self.assertLess(workflow.index('python tools/export_browser_qa.py'), workflow.index('python tools/prepare_playable_web.py'))

    def test_pck_guard_rejects_qa_path_and_invalid_pack(self):
        pack = self.root / 'index.pck'
        # PCK resource names remain plaintext even when script source is compiled.
        pack.write_bytes(b'GDPC' + b'\0' * 100 + b'res://scenes/Battle.tscn\0')
        assert_no_qa_resources(pack)
        pack.write_bytes(b'GDPC' + b'\0' * 100 + b'res://tests/browser_qa/BattleBrowserQA.gdc\0')
        with self.assertRaisesRegex(ValueError, 'QA'):
            assert_no_qa_resources(pack)
        pack.write_bytes(b'not a pack')
        with self.assertRaisesRegex(ValueError, 'PCK'):
            assert_no_qa_resources(pack)

class ShowcaseStagingTests(unittest.TestCase):
    setUp = StagingTests.setUp
    def test_optional_showcase_main_is_selected_only_in_staging(self):
        with staged_qa_project(self.root, scenario='zane-showcase'):
            self.assertIn(b'res://tests/browser_qa/ZaneShowcaseBootstrap.tscn', self.project.read_bytes())
        self.assertEqual(self.project.read_bytes(), self.original)
        self.assertFalse(self.stage.exists())

    def test_unknown_scenario_fails_without_changing_project(self):
        with self.assertRaises(ValueError):
            with staged_qa_project(self.root, scenario='unknown'):
                pass
        self.assertEqual(self.project.read_bytes(), self.original)
        self.assertFalse(self.stage.exists())


class DuelStagingTests(unittest.TestCase):
    setUp = StagingTests.setUp

    def test_duel_export_runs_normal_and_slow_tail_observer_contracts(self):
        from export_browser_qa import main
        pack = self.root / 'production.pck'
        pack.write_bytes(b'GDPC' + b'\0' * 100)
        with patch('export_browser_qa.ROOT', self.root), patch('export_browser_qa.run_godot') as run:
            with patch('sys.argv', ['export', '--scenario', 'zane-duel', '--production-pck', str(pack), '--validate-only']):
                main()
        args = [call.args[1] for call in run.call_args_list]
        self.assertIn(['res://tests/browser_qa/ObserverDuelContract.tscn'], args)
        self.assertIn(['res://tests/browser_qa/ObserverDuelContract.tscn', '--', '--duel-observer-slow-tail'], args)

    def test_duel_main_is_isolated_and_failure_restores_exact_project(self):
        with self.assertRaisesRegex(RuntimeError, 'duel export failed'):
            with staged_qa_project(self.root, scenario='zane-duel'):
                self.assertIn(b'res://tests/browser_qa/ZaneDuelBootstrap.tscn', self.project.read_bytes())
                raise RuntimeError('duel export failed')
        self.assertEqual(self.project.read_bytes(), self.original)
        self.assertFalse(self.stage.exists())


if __name__ == '__main__':
    unittest.main()
