"""Synthetic snapshot/transport tests; these are not exported-browser acceptance."""
import copy
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import browser_zane_showcase as showcase
from browser_combat_smoke import CDP


def state():
    actor = {'id': 'zane', 'instance_id': 'zane-1', 'position': [4, 5], 'hp': 92, 'mp': 80,
             'moved': False, 'acted': False, 'team': 'player', 'temper': 20, 'ether': 20}
    return {'schema': 2, 'frame': 10, 'phase': 'PLAYER_TURN', 'viewport': [1600, 900],
            'unit': actor, 'roster': {'zane-1': actor.copy()}, 'player_turn_serial': 5,
            'command': '', 'ability_id': '', 'menu_visible': False, 'resolving': False,
            'active_hud': {'name': {'text': 'Zane', 'visible': True, 'instance_id': 'name-1'},
                           'mp': {'text': 'MP: 80', 'visible': True, 'instance_id': 'mp-1'}},
            'highlights': {'move': 0, 'ability': 0, 'attack': 0, 'aoe': 0, 'path': 0},
            'zane': {'profile': {'available': True, 'profile_id': 'zane_impact_v1',
                       'asset_path': showcase.MODEL, 'model_sha256': showcase.MODEL_SHA,
                       'output_visible': True, 'model_instance_id': 'model-1', 'skeleton_bones': 33},
                     'lifecycle': {'ticket': 4, 'phase': 'idle'}, 'events': [], 'samples': [],
                     'owners': [], 'overflow': False,
                     'cleanup': {'reaction_marks': 0, 'camera_kick_remaining': 0, 'rig_state': 'idle'}}}


def fire_after(outcomes=None):
    after = state()
    after['unit'].update(mp=68, acted=True)
    after['active_hud']['mp']['text'] = 'MP: 68'
    after['roster']['zane-1'].update(mp=68)
    after['zane']['lifecycle']['ticket'] = 5
    after['zane']['events'] = [
        {'key': 'manager:5', 'kind': kind, 'value': value, 'actor_id': 'zane', 'ability_id': 'fire'}
        for kind, value in [('phase', 'charge'), ('cue', 'fire_charge'), ('phase', 'release'),
                            ('cue', 'fire_release'), ('phase', 'dissipate'), ('cue', 'fire_miss')]]
    after['zane']['events'] += [{'key': 'manager:5', 'kind': 'outcome', 'result': value}
                               for value in (outcomes or [{'missed': True, 'applied_hp_damage': 0}])]
    after['zane']['samples'] = [
        {'key': 'manager:5', 'role': 'charge', 'point': [100, 200], 'hand': [100, 200]},
        {'key': 'manager:5', 'role': 'projectile', 'point': [110, 200], 'origin': [100, 200], 'hand': [101, 200]},
        {'key': 'manager:5', 'role': 'outcome', 'text': 'MISS'}]
    return after


class ShowcaseInvariantTests(unittest.TestCase):
    def test_available_imported_profile_requires_real_model_and_drawable(self):
        showcase.assert_zane_profile(state())
        for field, value in [('available', False), ('asset_path', 'old.glb'), ('profile_id', 'zane_v2'),
                             ('model_sha256', 'not-the-new-model'), ('output_visible', False),
                             ('model_instance_id', ''), ('skeleton_bones', 0)]:
            after = state(); after['zane']['profile'][field] = value
            with self.subTest(field=field), self.assertRaises(AssertionError):
                showcase.assert_zane_profile(after)

    def test_showcase_destination_uses_only_visible_observed_legal_moves(self):
        before = state(); before['unit']['position'] = [1, 6]
        before['legal_moves'] = [{'position': [2, 6], 'point': [100, 200]},
                                 {'position': [4, 5], 'point': [300, 200]}]
        canvas = {'x': 0, 'y': 0, 'width': 1600, 'height': 900}
        self.assertEqual(showcase.choose_showcase_destination(before, canvas)['position'], [4, 5])
        before['legal_moves'][1]['point'] = [-1, 5]
        self.assertEqual(showcase.choose_showcase_destination(before, canvas)['position'], [2, 6])
        before['legal_moves'] = []
        with self.assertRaises(AssertionError):
            showcase.choose_showcase_destination(before, canvas)

    def test_target_requires_observed_legal_living_enemy_not_inferred_range(self):
        before = state()
        before['legal_ability_targets'] = [
            {'id': 'friend', 'team': 'player', 'hp': 90, 'point': [100, 200]},
            {'id': 'dead', 'team': 'enemy', 'hp': 0, 'point': [100, 200]},
            {'id': 'offscreen', 'team': 'enemy', 'hp': 90, 'point': [-1, 200]},
            {'id': 'cultist', 'team': 'enemy', 'hp': 90, 'point': [300, 200]}]
        canvas = {'x': 0, 'y': 0, 'width': 1600, 'height': 900}
        self.assertEqual([x['id'] for x in showcase.legal_enemy_targets(before, canvas)], ['cultist'])

    def test_miss_is_valid_but_never_claims_hit_coverage(self):
        coverage = showcase.assert_fire_result(state(), fire_after(), 'manager:5')
        self.assertEqual(coverage['outcomes'], ['miss'])
        self.assertFalse(coverage['impact_observed'])
        self.assertEqual(coverage['mp_spent'], 12)

    def test_hit_and_immune_feedback_follow_authoritative_outcomes(self):
        for result, label, phase, cue, category in [
            ({'applied_hp_damage': 9, 'ether_damage': 2, 'affinity': 1.0}, '-9 HP\n-2 Ether', 'impact', 'fire_hit', 'hit'),
            ({'applied_hp_damage': 0, 'affinity': 0.0}, 'IMMUNE', 'deflect', 'fire_immune', 'immune')]:
            after = fire_after([result])
            after['zane']['events'][-3]['value'] = phase
            after['zane']['events'][-2]['value'] = cue
            after['zane']['samples'][-1]['text'] = label
            coverage = showcase.assert_fire_result(state(), after, 'manager:5')
            self.assertEqual(coverage['outcomes'], [category])

    def test_rejects_wrong_cost_action_double_cue_stale_fx_and_false_hit(self):
        mutations = [lambda s: s['unit'].update(mp=56), lambda s: s['unit'].update(acted=False),
                     lambda s: s['zane']['lifecycle'].update(ticket=6),
                     lambda s: s['zane']['events'].append(s['zane']['events'][1]),
                     lambda s: s['zane']['events'].append(s['zane']['events'][3]),
                     lambda s: s['zane'].update(owners=['manager:5']),
                     lambda s: s['zane'].update(overflow=True),
                     lambda s: s['zane']['samples'][-1].update(text='-100 HP'),
                     lambda s: s['zane']['events'][-2].update(value='fire_hit'),
                     lambda s: s['zane']['samples'][0].update(point=[200, 200]),
                     lambda s: s['zane']['samples'][1].update(origin=[200, 200])]
        for mutate in mutations:
            after = fire_after(); mutate(after)
            with self.subTest(mutate=mutate), self.assertRaises(AssertionError):
                showcase.assert_fire_result(state(), after, 'manager:5')

    def test_missing_hand_projectile_or_outcome_evidence_fails(self):
        for index in range(3):
            after = fire_after(); after['zane']['samples'].pop(index)
            with self.assertRaises(AssertionError):
                showcase.assert_fire_result(state(), after, 'manager:5')

class ShowcaseDriverTests(unittest.TestCase):
    canvas = {'x': 0, 'y': 0, 'width': 1600, 'height': 900}

    def test_normal_wait_move_ability_fire_use_only_cdp_mouse_input(self):
        import json
        base = state()
        base['buttons'] = {name: {'visible': True, 'disabled': False, 'rect': [x, 800, 80, 40]}
                           for name, x in [('wait', 100), ('move', 200), ('ability', 300), ('cancel', 400)]}
        zane = copy.deepcopy(base); zane['unit']['position'] = [1, 6]
        initial = copy.deepcopy(zane); initial['unit']['id'] = 'lyra'; initial['player_turn_serial'] = 4
        initial['roster'].update({name: {'id': name, 'team': 'player', 'hp': 90} for name in ('lyra', 'mira', 'kael')})
        moving = copy.deepcopy(zane); moving.update(command='move', legal_moves=[{'position': [4, 5], 'point': [600, 400]}])
        moved = copy.deepcopy(zane); moved['unit'].update(position=[4, 5], moved=True)
        following = copy.deepcopy(base); following['player_turn_serial'] = 6
        menu = copy.deepcopy(following); menu.update(command='ability', menu_visible=True, abilities=[
            {'labels': ['Fire', '12MP'], 'visible': True, 'disabled': False, 'rect': [500, 500, 100, 40]}])
        targeting = copy.deepcopy(following); targeting.update(command='ability_target', ability_id='fire',
            legal_ability_targets=[{'id': 'cultist', 'team': 'enemy', 'hp': 90, 'point': [700, 400]}])
        fired = fire_after(); fired['player_turn_serial'] = 6
        settled = copy.deepcopy(fired)
        observations = []
        for frame, snapshot in enumerate([initial, zane, moving, moved, following, menu, targeting, fired, settled], 1):
            snapshot['frame'] = frame * 10
            snapshot['intro_visible'] = False
            observations.append({'state': snapshot, 'canvas': self.canvas})
        envelopes = iter(observations)
        class Connection:
            def __init__(self): self.sent = []
            def send(self, raw):
                message = json.loads(raw); self.sent.append(message)
                result = {}
                if message['method'] == 'Runtime.evaluate':
                    result = {'result': {'value': True if message['params']['expression'] == 'true' else next(envelopes)}}
                self.reply = {'id': message['id'], 'result': result}
            def recv(self): return json.dumps(self.reply)
        connection = Connection()
        with tempfile.TemporaryDirectory() as output:
            driver = showcase.ZaneShowcaseSmoke(CDP(connection), Path(output), 1)
            with patch.object(driver, 'screenshot'), patch('browser_combat_smoke.time.sleep'):
                driver.run('http://unit.test')
        presses = [m['params'] for m in connection.sent if m['method'] == 'Input.dispatchMouseEvent' and m['params']['type'] == 'mousePressed']
        self.assertEqual([(m['x'], m['y']) for m in presses], [(140, 820), (240, 820), (600, 400),
                                                             (140, 820), (340, 820), (550, 520), (700, 400)])
        from browser_combat_smoke import OBSERVATION_JS
        self.assertTrue(all(m['params']['expression'] in (OBSERVATION_JS, 'true')
                            for m in connection.sent if m['method'] == 'Runtime.evaluate'))
        self.assertEqual(driver.coverage['outcomes'], ['miss'])
        self.assertEqual(len(driver.turns_waited), 2)
        self.assertEqual(driver.checkpoints[0]['name'], 'zane-practice-actual-3d-loaded')

    def test_turn_budget_fails_before_dispatching_another_wait(self):
        with tempfile.TemporaryDirectory() as output:
            driver = showcase.ZaneShowcaseSmoke(SimpleNamespace(), Path(output), 1, max_player_turns=0)
            with self.assertRaisesRegex(AssertionError, 'turn budget'):
                driver.next_player({'state': state(), 'canvas': self.canvas})

    def test_total_budget_fails_without_browser_polling(self):
        with tempfile.TemporaryDirectory() as output:
            driver = showcase.ZaneShowcaseSmoke(SimpleNamespace(), Path(output), 1, budget=1)
            driver.deadline = 10
            with patch('browser_zane_showcase.time.monotonic', return_value=11):
                with self.assertRaisesRegex(TimeoutError, 'total.*budget'):
                    driver.wait('Fire', lambda s: True)


class ShowcaseFailureReportTests(unittest.TestCase):
    def test_selected_scenario_is_reported_even_if_browser_connection_fails(self):
        import json
        from browser_combat_smoke import main
        dependencies = {
            'websocket': SimpleNamespace(create_connection=lambda *a, **k: None),
            'capture_browser_screenshots': SimpleNamespace(devtools_target=lambda *a: (_ for _ in ()).throw(TimeoutError('no browser'))),
        }
        with tempfile.TemporaryDirectory() as output:
            with patch.dict('sys.modules', dependencies), patch('sys.argv', ['smoke', '--scenario', 'zane-showcase', '--output', output]):
                self.assertEqual(main(), 1)
            report = json.loads((Path(output) / 'report.json').read_text())
        self.assertEqual(report.get('scenario'), 'zane-showcase')
        self.assertEqual(report['coverage'], showcase.COVERAGE)

class FeedbackMultiplicityTests(unittest.TestCase):
    def test_each_authoritative_recipient_requires_its_own_outcome_label(self):
        after = fire_after([{'missed': True, 'applied_hp_damage': 0}, {'missed': True, 'applied_hp_damage': 0}])
        with self.assertRaisesRegex(AssertionError, 'Label|recipient'):
            showcase.assert_fire_result(state(), after, 'manager:5')


class CompleteOutcomeLabelTests(unittest.TestCase):
    def feedback(self, outcomes, labels):
        after = fire_after(outcomes)
        impact = any(not r.get('missed') and r.get('affinity', 1) != 0 and
                     sum(r.get(k, 0) for k in ('applied_hp_damage', 'temper_damage', 'ether_damage')) > 0
                     for r in outcomes)
        immune = any(not r.get('missed') and r.get('affinity', 1) == 0 for r in outcomes)
        phase = 'impact' if impact else 'deflect' if immune else 'dissipate'
        cue = 'fire_hit' if impact else 'fire_immune' if immune else 'fire_miss'
        for event in after['zane']['events']:
            if event.get('value') == 'dissipate': event['value'] = phase
            if event.get('value') == 'fire_miss': event['value'] = cue
        after['zane']['samples'] = [sample for sample in after['zane']['samples'] if sample['role'] != 'outcome']
        after['zane']['samples'].extend({'key': 'manager:5', 'role': 'outcome', 'text': text} for text in labels)
        return after

    def test_miss_and_immune_reject_unexplained_damage_crit_or_affinity_lines(self):
        for outcome, labels in [
            ({'missed': True, 'applied_hp_damage': 0}, ['MISS\n-999 HP\n-999 Ether', 'MISS\nCRIT', 'MISS [WEAK]']),
            ({'affinity': 0, 'applied_hp_damage': 0}, ['IMMUNE\n-999 HP', 'IMMUNE\n-999 Ether', 'IMMUNE [RESIST]'])]:
            for label in labels:
                with self.subTest(label=label), self.assertRaisesRegex(AssertionError, 'Label'):
                    showcase.assert_fire_result(state(), self.feedback([outcome], [label]), 'manager:5')

    def test_one_recipient_label_cannot_supply_another_recipient_armor_text(self):
        outcomes = [{'applied_hp_damage': 9, 'ether_damage': 2}] * 2
        after = self.feedback(outcomes, ['-9 HP', '-9 HP\n-2 Ether'])
        with self.assertRaisesRegex(AssertionError, 'Label'):
            showcase.assert_fire_result(state(), after, 'manager:5')

    def test_same_hp_different_armor_match_complete_labels_without_order_dependency(self):
        outcomes = [{'applied_hp_damage': 9, 'ether_damage': 2}, {'applied_hp_damage': 9, 'temper_damage': 3}]
        after = self.feedback(outcomes, ['-9 HP\n-3 Temper', '-9 HP\n-2 Ether'])
        coverage = showcase.assert_fire_result(state(), after, 'manager:5')
        self.assertEqual(coverage['outcomes'], ['hit', 'hit'])
        # Multiplicity remains exact even when the first-line HP values collide.
        after['zane']['samples'][-2]['text'] = '-9 HP\n-2 Ether'
        with self.assertRaisesRegex(AssertionError, 'Label'):
            showcase.assert_fire_result(state(), after, 'manager:5')

    def test_hit_requires_exact_armor_critical_and_affinity_semantics(self):
        outcome = {'applied_hp_damage': 9, 'temper_damage': 3, 'ether_damage': 2, 'critical': True, 'affinity': 1.5}
        valid = '-9 HP\n-3 Temper\n-2 Ether\nCRIT [WEAK]'
        showcase.assert_fire_result(state(), self.feedback([outcome], [valid]), 'manager:5')
        for invalid in [valid.replace('\nCRIT', ''), valid.replace(' [WEAK]', ''),
                        valid.replace('[WEAK]', '[RESIST]'), valid + '\n-999 Ether',
                        valid.replace('-2 Ether', '-2 Ether\n-2 Ether')]:
            with self.subTest(label=invalid), self.assertRaisesRegex(AssertionError, 'Label'):
                showcase.assert_fire_result(state(), self.feedback([outcome], [invalid]), 'manager:5')
        plain = {'applied_hp_damage': 9, 'affinity': 1}
        with self.assertRaisesRegex(AssertionError, 'Label'):
            showcase.assert_fire_result(state(), self.feedback([plain], ['-9 HP\nCRIT [WEAK]']), 'manager:5')
        resist = {'applied_hp_damage': 0, 'ether_damage': 2, 'affinity': 0.5}
        showcase.assert_fire_result(state(), self.feedback([resist], ['0 HP\n-2 Ether [RESIST]']), 'manager:5')


class CleanupAndHUDTests(unittest.TestCase):
    def test_cleanup_rejects_lingering_reaction_camera_kick_or_cast_pose(self):
        for field, value in [('reaction_marks', 1), ('camera_kick_remaining', 0.1), ('rig_state', 'cast_release')]:
            after = fire_after(); after['zane']['cleanup'][field] = value
            with self.subTest(field=field), self.assertRaisesRegex(AssertionError, 'cleanup'):
                showcase.assert_fire_result(state(), after, 'manager:5')

    def test_exact_mp_requires_same_visible_actual_hud_control(self):
        for field, value in [('text', 'MP: 80'), ('visible', False), ('instance_id', 'replacement')]:
            after = fire_after(); after['active_hud']['mp'][field] = value
            with self.subTest(field=field), self.assertRaises(AssertionError):
                showcase.assert_fire_result(state(), after, 'manager:5')


if __name__ == '__main__':
    unittest.main()
