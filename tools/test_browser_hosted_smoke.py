import unittest
from unittest.mock import patch
import browser_hosted_smoke as hosted

SHA = '1' * 40

class FakeCDP:
    def __init__(self):
        self.errors = []
        self.inputs = []
    def evaluate(self, expression):
        return 'complete'

class FakeSmoke:
    def __init__(self, fail_final=False):
        self.cdp = FakeCDP()
        self.keys, self.captures = [], []
        self.fail_final = fail_final
    def key(self, key, code=None, keycode=0):
        self.keys.append(key)
    def screenshot(self, name):
        self.captures.append(name)
        if self.fail_final and name == 'hosted-move-completed':
            self.cdp.errors.append({'late': 'render failure'})

class HostedTest(unittest.TestCase):
    def test_rejects_wrong_live_commit(self):
        with self.assertRaisesRegex(AssertionError, 'commit'):
            hosted.validate_build({'source_commit': '2' * 40}, SHA, 'tactics')
    def test_rejects_wrong_courtyard_scene(self):
        with self.assertRaisesRegex(AssertionError, 'scene'):
            hosted.validate_build({'source_commit': SHA, 'scene': 'Skirmish'}, SHA, 'courtyard')
    def test_accepts_exact_provenance(self):
        hosted.validate_build({'source_commit': SHA}, SHA, 'tactics')
        hosted.validate_build({'source_commit': SHA, 'scene': hosted.SCENE}, SHA, 'courtyard')
    def test_rejects_invalid_expected_commit(self):
        with self.assertRaises(ValueError):
            hosted.validate_expected_commit('main;echo unsafe')
    def test_drives_real_keys_without_game_hooks(self):
        smoke = FakeSmoke()
        with patch.object(hosted.time, 'sleep'):
            hosted.capture_inputs(smoke)
        self.assertEqual(smoke.keys, ['Escape', 'Escape', 'Enter', 'm', 'ArrowRight', 'Enter',
                                     'Escape', 'Enter', 'Enter'])
        self.assertEqual(smoke.captures, ['hosted-settings', 'hosted-move-review',
                                         'hosted-move-cancelled', 'hosted-move-completed'])
    def test_rejects_errors_drained_by_final_capture(self):
        with patch.object(hosted.time, 'sleep'):
            with self.assertRaisesRegex(AssertionError, 'Browser'):
                hosted.capture_inputs(FakeSmoke(fail_final=True))

    def test_production_readiness_is_atomic_and_rechecked_after_settle(self):
        class NavigatingCDP:
            def __init__(self):
                self.errors = []
                self.states = [
                    {'url': 'https://old.test/', 'ready': True},
                    {'url': 'https://new.test/', 'ready': False},
                    {'url': 'https://new.test/', 'ready': True},
                    {'url': 'https://new.test/', 'ready': False},
                    {'url': 'https://new.test/', 'ready': True},
                    {'url': 'https://new.test/', 'ready': True},
                ]
            def command(self, *args):
                return {}
            def evaluate(self, expression):
                if expression == 'location.href':
                    return 'https://new.test/'
                if expression == 'typeof window.__courtyardQA':
                    return 'undefined'
                if 'location.href' in expression:
                    return self.states.pop(0)
                return True
        cdp = NavigatingCDP()
        smoke = hosted.CourtyardSmoke(cdp, None, 5)
        with patch.object(hosted.time, 'sleep'), patch.object(smoke, 'screenshot') as capture:
            smoke.check_production('https://new.test/')
        self.assertEqual(cdp.states, [], 'Accepted readiness from an outgoing or unsettled document')
        capture.assert_called_once_with('courtyard-production-package')

if __name__ == '__main__':
    unittest.main()
