"""Third CI lane shell contracts, not actual browser/rendering acceptance."""
import unittest
import test_zane_release_workflow as existing

EXPORT = 'Export isolated Zane duel Web QA build'
PACKAGE = 'Package isolated Zane duel Web QA build'
BROWSER = 'Exercise Zane duel input and capture browser evidence'
EVIDENCE = 'docs/qa/browser-zane-duel-captures'
FILES = ('zane-duel-actual-3d-loaded.png', 'zane-duel-3d-movement-completed.png',
         'zane-duel-sword-outcome-and-cleanup.png', 'report.json', 'browser-events.json')


class ZaneDuelReleaseWorkflowTests(unittest.TestCase):
    # Reuse only controlled external-process fixtures, not the existing tests.
    setUp = existing.ZaneReleaseWorkflowTests.setUp
    run_step = existing.ZaneReleaseWorkflowTests.run_step
    calls = existing.ZaneReleaseWorkflowTests.calls

    def test_export_and_package_use_third_output_without_touching_existing_lanes(self):
        for directory in ('web-qa', 'web-qa-zane'):
            sentinel = self.root / 'build' / directory / 'keep'
            sentinel.parent.mkdir(parents=True)
            sentinel.write_bytes(directory.encode())
        result = self.run_step(EXPORT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        export = next(c for c in self.calls() if c[1:2] == ['tools/export_browser_qa.py'])
        self.assertEqual(export[export.index('--scenario') + 1], 'zane-duel')
        self.assertEqual(export[export.index('--production-pck') + 1], 'build/web/index.pck')
        self.assertEqual(export[export.index('--output') + 1], 'build/web-qa-duel/index.html')
        result = self.run_step(PACKAGE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(['python', 'tools/prepare_playable_web.py', 'build/web-qa-duel'], self.calls())
        self.assertIn(['node', 'tools/check_web_package.mjs', 'build/web-qa-duel'], self.calls())
        for directory in ('web-qa', 'web-qa-zane'):
            self.assertEqual((self.root / 'build' / directory / 'keep').read_bytes(), directory.encode())
        for name in ('export.log', 'production-reexport.log', 'package.log'):
            self.assertTrue((self.root / EVIDENCE / name).stat().st_size, name)

    def test_export_failure_with_existing_outputs_still_fails_through_tee(self):
        result = self.run_step(EXPORT, 'export-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('export diagnostics', (self.root / EVIDENCE / 'export.log').read_text())
        self.assertFalse(any(c[0] == 'godot' for c in self.calls()))

    def test_post_duel_production_reexport_rejects_leaks_and_zero_exit_script_errors(self):
        for mode, diagnostic in [('leak', 'QA observer leaked'),
                                 ('reexport-script-error', 'SCRIPT ERROR: simulated re-export failure')]:
            with self.subTest(mode=mode):
                result = self.run_step(EXPORT, mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(diagnostic, (self.root / EVIDENCE / 'production-reexport.log').read_text())

    def test_both_package_failures_survive_tee_and_keep_diagnostics(self):
        (self.root / EVIDENCE).mkdir(parents=True)
        for mode, diagnostic in [('prepare-fails', 'package preparation diagnostics'),
                                 ('package-check-fails', 'package validation diagnostics')]:
            with self.subTest(mode=mode):
                result = self.run_step(PACKAGE, mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(diagnostic, (self.root / EVIDENCE / 'package.log').read_text())

    def test_browser_uses_duel_build_fresh_profiles_and_mandatory_evidence(self):
        for _ in range(2):
            result = self.run_step(BROWSER)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(['python', '-m', 'http.server', '8000', '--directory', 'build/web-qa-duel'], self.calls())
        smoke = next(c for c in self.calls() if c[1:2] == ['tools/browser_combat_smoke.py'])
        self.assertEqual(smoke[smoke.index('--scenario') + 1], 'zane-duel')
        self.assertEqual(smoke[smoke.index('--timeout') + 1], '45')
        self.assertEqual(smoke[smoke.index('--budget') + 1], '180')
        profiles = [next(a.partition('=')[2] for a in c if a.startswith('--user-data-dir='))
                    for c in self.calls() if c[0] == 'google-chrome']
        self.assertEqual(len(profiles), 2)
        self.assertNotEqual(profiles[0], profiles[1])
        self.assertTrue(all(p.startswith('/tmp/projecttactic-duel-chrome.') for p in profiles))
        for name in (*FILES, 'server.log', 'chrome.log', 'smoke.log'):
            self.assertTrue((self.root / EVIDENCE / name).stat().st_size, name)
        for kind in ('browser', 'server'):
            self.assertTrue((self.root / (kind + '.stopped')).exists())

    def test_browser_failure_keeps_diagnostics_and_reaps_both_processes(self):
        result = self.run_step(BROWSER, 'smoke-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('browser smoke diagnostics', (self.root / EVIDENCE / 'smoke.log').read_text())
        for kind in ('browser', 'server'):
            self.assertTrue((self.root / (kind + '.stopped')).exists())

    def test_missing_each_mandatory_screenshot_report_or_events_fails(self):
        for name in FILES:
            with self.subTest(name=name):
                (self.root / EVIDENCE / name).unlink(missing_ok=True)
                result = self.run_step(BROWSER, 'omit:' + name)
                self.assertNotEqual(result.returncode, 0, name)


if __name__ == '__main__':
    unittest.main()
