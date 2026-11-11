"""Fail closed unless confirmed support actions have real presentation/audio evidence."""
import copy
import unittest
import browser_courtyard_smoke as browser


class SupportFeedbackTests(unittest.TestCase):
    def fixture(self, ability='haste'):
        caster = 'zane' if ability == 'haste' else 'kael'
        status = 'haste' if ability == 'haste' else 'defending'
        units = {'zane': {'mp': 90, 'hp': 320, 'position': [4, 8], 'statuses': []},
                 'kael': {'mp': 30, 'hp': 400, 'position': [3, 7], 'statuses': []}}
        before = {'units': units, 'events': [], 'animation_samples': []}
        after = copy.deepcopy(before)
        after['units'][caster]['mp'] -= 10 if ability == 'haste' else 0
        after['units']['kael']['statuses'].append(status)
        for kind, name in [('phase', 'casting'), ('cue', ability + '_charge'),
                           ('phase', 'formation'), ('phase', 'action'),
                           ('cue', ability + '_release'), ('phase', 'support'), ('cue', ability + '_heal')]:
            after['events'].append({'kind': kind, 'name': name, 'ability_id': ability,
                'actor_id': caster, 'action_key': '1:1', 'pose': '', 'visuals': [{'stage': 'collision' if name == 'support' else name, 'progress': 0.0, 'available': True}],
                'effects': ['spell_tail' if name == 'support' else 'spell_sheet_' + name], 'voices': [{'playing': True, 'bus': 'FX', 'stream': True}]})
        after['animation_samples'] = [{'action_key': '1:1', 'stage': stage, 'progress': 0.5,
            'available': True} for stage in ('casting', 'formation', 'action')]
        return before, after

    def test_valid_haste_and_defend(self):
        for ability in ('haste', 'defend'):
            browser.assert_support_cast(*self.fixture(ability), ability)

    def test_reject_missing_or_wrong_status_cost_pose_effect_phase_and_audio(self):
        before, valid = self.fixture()
        changes = [lambda s: s['units']['zane'].update(mp=90),
                   lambda s: s['units']['kael'].update(statuses=[]),
                   lambda s: s['events'].pop(0),
                   lambda s: s['events'][0].update(visuals=[]),
                   lambda s: s.update(animation_samples=[]),
                   lambda s: s['animation_samples'][0].update(progress=0),
                   lambda s: s['events'][0].update(effects=[]),
                   lambda s: s['events'][1]['voices'][0].update(playing=False),
                   lambda s: s['events'][1]['voices'][0].update(bus='Master'),
                   lambda s: s['events'][1]['voices'][0].update(stream=False),
                   lambda s: s['events'][1].update(action_key='1:2'),
                   lambda s: s['events'][1]['voices'].append({'playing': False, 'bus': 'FX', 'stream': True}),
                   lambda s: s['events'][0].update(effects=['unrelated_effect'])]
        for change in changes:
            state = copy.deepcopy(valid)
            change(state)
            with self.assertRaises(AssertionError):
                browser.assert_support_cast(before, state, 'haste')

    def test_previous_cast_events_cannot_satisfy_new_cast(self):
        before, after = self.fixture()
        before['events'] = copy.deepcopy(after['events'])
        with self.assertRaises(AssertionError):
            browser.assert_support_cast(before, after, 'haste')

if __name__ == '__main__':
    unittest.main()
