"""Synthetic observation/transport tests, not exported-browser acceptance."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import browser_zane_duel as duel
from browser_combat_smoke import CDP, OBSERVATION_JS
from test_browser_zane_showcase import state as showcase_state

CANVAS = {'x': 0, 'y': 0, 'width': 1600, 'height': 900}
KEY = 'manager:5'


def cleanup():
    return {'frame': 49, 'key': KEY, 'owner_instance_id': 'owner-1', 'owner_alive': False,
            'live_effects': 0, 'playing_voices': 0, 'reaction_marks': 0,
            'camera_kick_remaining': 0, 'battle_removed': False}



def presentation(text='-7 HP\n-3 Temper', frame=45):
    return {'key': KEY, 'owner_instance_id': 'owner-1', 'recipient_id': 'Enemy_1',
            'recipient_instance_id': 'imp-1', 'opened_frame': 42, 'overflow': False,
            'binding_error': '', 'closed_frame': 49,
            'samples': [{'frame': frame, 'key': KEY, 'role': 'outcome', 'instance_id': 'label-1',
                         'owner_instance_id': 'owner-1', 'recipient_id': 'Enemy_1',
                         'recipient_instance_id': 'imp-1', 'visible': True,
                         'point': [313, 78.39], 'text': text}]}


def state():
    value = showcase_state()
    value['zane']['profile'].update(profile_id='zane_painterly_v1', asset_path=duel.MODEL,
                                   model_sha256=duel.candidate_model_sha(), skeleton_bones=16)
    value['unit']['archetype'] = 'zane'
    value['roster']['zane-1'] = value['unit'].copy()
    value['roster']['imp-1'] = {'id': 'Enemy_1', 'instance_id': 'imp-1', 'archetype': 'storm_imp',
        'team': 'enemy', 'position': [6, 5], 'hp': 90, 'mp': 50, 'temper': 50, 'ether': 90}
    value.update(duel={'mode': 'zane_duel', 'rig3d': True, 'zane_showcase': False},
                 enemy_turns=0, enemy_outcomes=[], intro_visible=False)
    value['buttons'] = {name: {'visible': True, 'disabled': False, 'rect': [x, 800, 80, 40]}
                       for name, x in [('wait', 100), ('move', 200), ('attack', 300), ('cancel', 400)]}
    return value


def sword_before():
    value = state(); value['unit']['moved'] = True
    return value


def sword_after(result=None, counter=None):
    value = state()
    value['sword_owner'] = {'key': KEY, 'instance_id': 'owner-1'}
    value['unit'].update(acted=True, moved=True)
    value['player_turn_serial'] += 1
    value['zane']['lifecycle']['ticket'] = 5
    result = result or {'feedback_owner': 'zane_impact_v1', 'applied_hp_damage': 7, 'temper_damage': 3}
    value['zane']['events'] = [
        {'key': KEY, 'kind': kind, 'value': text, 'actor_id': 'zane', 'ability_id': ''}
        for kind, text in [('phase', 'charge'), ('cue', 'sword_load'), ('phase', 'release'), ('cue', 'sword_release')]]
    impact = not result.get('missed') and result.get('affinity', 1) != 0 and sum(result.get(k, 0) for k in ('applied_hp_damage', 'temper_damage', 'ether_damage')) > 0
    if impact:
        value['zane']['events'] += [{'key': KEY, 'kind': 'phase', 'value': 'impact'}, {'key': KEY, 'kind': 'cue', 'value': 'sword_hit'}]
    value['zane']['events'].append({'key': KEY, 'kind': 'outcome', 'result': result})
    value['zane']['samples'] = [{'key': KEY, 'role': 'outcome', 'text': 'MISS' if result.get('missed') else 'IMMUNE' if result.get('affinity', 1) == 0 else '-7 HP\n-3 Temper'}]
    for field, outcome in [('hp', 'applied_hp_damage'), ('temper', 'temper_damage'), ('ether', 'ether_damage')]:
        value['roster']['imp-1'][field] -= result.get(outcome, 0)
        if counter:
            value['unit'][field] -= counter.get(outcome, 0)
    if counter:
        value['zane']['events'].append({'key': KEY, 'kind': 'outcome', 'result': counter})
    value['roster']['zane-1'] = value['unit'].copy()
    return value


def assert_result(before, after, key, cleaned):
    # Existing synthetic result cases carry their actual sampled text here.
    shown = presentation(text=after['zane']['samples'][0]['text'], frame=after['frame'])
    shown['opened_frame'] = min(shown['opened_frame'], after['frame'])
    shown['closed_frame'] = cleaned['frame']
    return duel.assert_sword_result(before, after, key, cleaned, shown)


class DuelInvariantTests(unittest.TestCase):
    def test_duel_rejects_old_full_party_profile_instead_of_accepting_both(self):
        # Synthetic snapshot only; full-party impact remains the separate baseline.
        with self.assertRaises(AssertionError):
            duel.assert_zane_profile(showcase_state())

    def test_duel_requires_actual_candidate_identity_and_imported_rig(self):
        duel.assert_zane_profile(state())
        for field, wrong in [('available', False), ('profile_id', 'zane_impact_v1'),
                             ('asset_path', 'res://unapproved.glb'), ('model_sha256', 'a' * 64),
                             ('output_visible', False), ('model_instance_id', ''), ('skeleton_bones', 0),
                             ('skeleton_bones', 15), ('skeleton_bones', 17)]:
            value = state(); value['zane']['profile'][field] = wrong
            with self.subTest(field=field, wrong=wrong), self.assertRaises(AssertionError):
                duel.assert_zane_profile(value)

    def test_candidate_metadata_cannot_claim_bytes_of_a_different_model(self):
        # Deliberately malformed temporary unit fixture, not a renderable asset.
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'zane_painterly_v1.glb').write_bytes(b'synthetic-unit-fixture-only')
            (root / 'presentation.json').write_text(json.dumps({'profile_id': 'zane_painterly_v1',
                'model': duel.MODEL, 'model_sha256': 'a' * 64}))
            with patch.object(duel, 'ASSET_DIRECTORY', root), self.assertRaisesRegex(AssertionError, 'GLB'):
                duel.candidate_model_sha()

    def test_full_party_assertion_still_rejects_candidate(self):
        from browser_zane_showcase import assert_zane_profile
        assert_zane_profile(showcase_state())
        with self.assertRaises(AssertionError):
            assert_zane_profile(state())

    def test_initial_roster_is_exact_and_uses_archetype_not_runtime_enemy_id(self):
        duel.assert_duel_roster(state(), initial=True)
        mutations = [lambda s: s['roster'].update(extra=s['roster']['imp-1'].copy()),
            lambda s: s['roster']['imp-1'].update(archetype='null_drake'),
            lambda s: s['roster']['imp-1'].update(position=[7, 5]),
            lambda s: s['unit'].update(id='lyra'),
            lambda s: s['duel'].update(mode='practice'),
            lambda s: s['duel'].update(zane_showcase=True)]
        for change in mutations:
            value = state(); change(value)
            with self.subTest(change=change), self.assertRaises(AssertionError):
                duel.assert_duel_roster(value, initial=True)

    def test_move_requires_exact_observed_visible_one_step(self):
        value = state(); value['legal_moves'] = [{'position': [5, 5], 'point': [600, 400]}]
        self.assertEqual(duel.choose_duel_destination(value, CANVAS)['position'], [5, 5])
        for moves in ([], [{'position': [4, 6], 'point': [600, 400]}], [{'position': [5, 5], 'point': [-1, 400]}]):
            value['legal_moves'] = moves
            with self.assertRaises(AssertionError): duel.choose_duel_destination(value, CANVAS)

    def test_sword_target_is_observed_legal_living_imp(self):
        value = state(); target = {**value['roster']['imp-1'], 'point': [700, 400]}
        value['legal_attack_targets'] = [target]
        self.assertEqual(duel.duel_sword_target(value, CANVAS), target)
        for field, wrong in [('team', 'player'), ('hp', 0), ('archetype', 'null_drake'), ('instance_id', 'unknown'), ('point', [-1, 400])]:
            invalid = copy.deepcopy(value); invalid['legal_attack_targets'][0][field] = wrong
            with self.subTest(field=field), self.assertRaises(AssertionError): duel.duel_sword_target(invalid, CANVAS)

    def test_sword_hit_and_miss_are_truthful(self):
        coverage = assert_result(sword_before(), sword_after(), KEY, cleanup())
        self.assertEqual(coverage['outcome'], 'hit'); self.assertEqual(coverage['mp_spent'], 0)
        result = {'feedback_owner': 'zane_impact_v1', 'missed': True, 'applied_hp_damage': 0}
        coverage = assert_result(sword_before(), sword_after(result), KEY, cleanup())
        self.assertFalse(coverage['impact_observed']); self.assertEqual(coverage['outcome'], 'miss')

    def test_legitimate_counter_uses_separate_authoritative_resource_deltas(self):
        result = {'feedback_owner': 'zane_impact_v1', 'applied_hp_damage': 7, 'temper_damage': 3, 'counter': True}
        after = sword_after(result, {'applied_hp_damage': 4, 'temper_damage': 2})
        coverage = assert_result(sword_before(), after, KEY, cleanup())
        self.assertTrue(coverage['counter_observed'])
        after['unit']['hp'] -= 1
        with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, cleanup())

    def test_delayed_presentation_rejects_foreign_missing_duplicate_hidden_and_out_of_window_samples(self):
        after = sword_after(); after['frame'] = 44; after['zane']['samples'] = []
        mutations = [lambda p: p.update(overflow=True), lambda p: p.update(binding_error='wrong owner'),
            lambda p: p.update(owner_instance_id='other-owner'),
            lambda p: p.update(recipient_instance_id='other-target'),
            lambda p: p.update(key='other:7'), lambda p: p.update(samples=[]),
            lambda p: p['samples'].append(copy.deepcopy(p['samples'][0])),
            lambda p: p['samples'][0].update(text='-7 HP'),
            lambda p: p['samples'][0].update(key='other:7'),
            lambda p: p['samples'][0].update(owner_instance_id='other-owner'),
            lambda p: p['samples'][0].update(recipient_instance_id='other-target'),
            lambda p: p['samples'][0].update(recipient_id='zane'),
            lambda p: p['samples'][0].update(visible=False),
            lambda p: p['samples'][0].update(frame=41),
            lambda p: p['samples'][0].update(frame=50),
            lambda p: p.update(closed_frame=48)]
        duel.assert_sword_result(sword_before(), after, KEY, cleanup(), presentation())
        for mutate in mutations:
            shown = presentation(); mutate(shown)
            with self.subTest(mutate=mutate), self.assertRaises(AssertionError):
                duel.assert_sword_result(sword_before(), after, KEY, cleanup(), shown)
        self.assertEqual(after['zane']['samples'], [])

    def test_wrong_resources_actions_labels_duplicate_cues_and_cleanup_are_rejected(self):
        mutations = [lambda s: s['unit'].update(mp=79), lambda s: s['unit'].update(acted=False),
            lambda s: s['zane']['lifecycle'].update(ticket=6),
            lambda s: s['zane']['events'].append(s['zane']['events'][1]),
            lambda s: s['zane']['samples'][0].update(text='-7 HP\n-999 Temper'),
            lambda s: s['roster']['imp-1'].update(hp=80),
            lambda s: s['zane'].update(overflow=True),
            lambda s: s.update(player_turn_serial=7)]
        for change in mutations:
            after = sword_after(); change(after)
            with self.subTest(change=change), self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, cleanup())

    def test_handoff_tail_requires_separate_observed_cleanup_not_fabricated_idle(self):
        after = sword_after(); after['zane']['owners'] = ['tail-still-live-at-handoff']
        assert_result(sword_before(), after, KEY, cleanup())
        for change in [lambda c: c.update(owner_alive=True), lambda c: c.update(live_effects=1),
                       lambda c: c.update(reaction_marks=1), lambda c: c.update(camera_kick_remaining=0.1),
                       lambda c: c.update(playing_voices=1), lambda c: c.update(key='different:9'),
                       lambda c: c.update(owner_instance_id='newer-owner')]:
            value = cleanup(); change(value)
            with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, value)
        terminal_cleanup = cleanup(); terminal_cleanup.update(frame=60, battle_removed=True, camera_kick_remaining=None)
        assert_result(sword_before(), after, KEY, terminal_cleanup)
        terminal_cleanup['battle_removed'] = False
        with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, terminal_cleanup)

    def test_false_hit_or_extra_text_on_miss_is_rejected(self):
        result = {'feedback_owner': 'zane_impact_v1', 'missed': True, 'applied_hp_damage': 0}
        for extra in ('\n-999 HP', '\nCRIT', ' [WEAK]'):
            after = sword_after(result); after['zane']['samples'][0]['text'] += extra
            with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, cleanup())
        after = sword_after(result); after['zane']['events'].append({'key': KEY, 'kind': 'cue', 'value': 'sword_hit'})
        with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, cleanup())

    def test_terminal_target_is_allowed_only_with_exact_authoritative_applied_damage(self):
        result = {'feedback_owner': 'zane_impact_v1', 'applied_hp_damage': 90, 'temper_damage': 0, 'defeated': True}
        after = sword_after(result); after['zane']['samples'][0]['text'] = '-90 HP'
        assert_result(sword_before(), after, KEY, cleanup())
        after['roster']['imp-1']['hp'] = 1
        with self.assertRaises(AssertionError): assert_result(sword_before(), after, KEY, cleanup())


class DuelDriverTests(unittest.TestCase):
    def test_unexpected_terminal_fails_immediately_not_stale_poll_timeout(self):
        terminal = {'schema': 2, 'frame': 20, 'phase': 'RESULTS', 'duel': {'mode': 'zane_duel'},
                    'terminal': {'state': 'won', 'scene': 'res://scenes/ResultsScreen.tscn'}}
        cdp = SimpleNamespace(errors=[], evaluate=lambda _: {'state': terminal, 'canvas': CANVAS})
        with tempfile.TemporaryDirectory() as output:
            smoke = duel.ZaneDuelSmoke(cdp, Path(output), 60)
            with self.assertRaisesRegex(AssertionError, 'native.*coverage|native.*contract'):
                smoke.wait('first sword', lambda s: False)
            self.assertEqual(smoke.latest['state'], terminal)

    def test_frame44_handoff_retains_frame45_actual_label_until_frame49_cleanup(self):
        initial = state()
        moving = copy.deepcopy(initial); moving.update(command='move', legal_moves=[{'position': [5, 5], 'point': [600, 400]}])
        moved = copy.deepcopy(initial); moved['unit'].update(position=[5, 5], moved=True); moved['roster']['zane-1'].update(position=[5, 5])
        targeting = copy.deepcopy(moved); targeting.update(command='attack', legal_attack_targets=[{**moved['roster']['imp-1'], 'point': [700, 400]}])
        completed = sword_after(); completed['unit']['position'] = [5, 5]; completed['roster']['zane-1']['position'] = [5, 5]
        completed['frame'] = 44
        completed['zane']['samples'] = []  # Immutable logical handoff precedes actual visual read.
        handed_off = {'schema': 2, 'frame': 44, 'phase': 'ENEMY_TURN', 'completed_sword': completed,
                      'sword_cleanup': {}, 'sword_presentation': {**presentation(), 'samples': []}}
        sampled = {**handed_off, 'frame': 45, 'sword_presentation': presentation()}
        cleaned = {**sampled, 'frame': 49, 'sword_cleanup': cleanup(),
                   'unit': {'hp': 277}, 'zane': {'lifecycle': {'ticket': 6}, 'samples': []}}
        values = [initial, moving, moved, targeting]
        for index, value in enumerate(values): value['frame'] = (index + 1) * 10
        values += [handed_off, sampled, cleaned]
        envelopes = iter({'state': s, 'canvas': CANVAS} for s in values)
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
            smoke = duel.ZaneDuelSmoke(CDP(connection), Path(output), 1)
            with patch.object(smoke, 'screenshot'), patch('browser_combat_smoke.time.sleep'):
                smoke.run('http://unit.test')
        presses = [m['params'] for m in connection.sent if m['method'] == 'Input.dispatchMouseEvent' and m['params']['type'] == 'mousePressed']
        self.assertEqual([(m['x'], m['y']) for m in presses], [(240, 820), (600, 400), (340, 820), (700, 400)])
        self.assertTrue(all(m['params']['expression'] in (OBSERVATION_JS, 'true') for m in connection.sent if m['method'] == 'Runtime.evaluate'))
        self.assertEqual(smoke.coverage['outcome'], 'hit')
        self.assertEqual(completed['zane']['samples'], [])
        self.assertEqual(completed['zane']['lifecycle']['ticket'], 5)
        self.assertIn('native', smoke.coverage['terminal_fire_replay'])

    def test_terminal_with_retained_completed_sword_is_not_mistaken_for_failure(self):
        terminal = {'schema': 2, 'frame': 60, 'phase': 'RESULTS',
                    'terminal': {'state': 'won'}, 'completed_sword': sword_after(), 'sword_cleanup': {**cleanup(), 'frame': 60, 'battle_removed': True, 'camera_kick_remaining': None}}
        cdp = SimpleNamespace(errors=[], evaluate=lambda _: {'state': terminal, 'canvas': CANVAS})
        with tempfile.TemporaryDirectory() as output:
            smoke = duel.ZaneDuelSmoke(cdp, Path(output), 1)
            value = smoke.wait('sword completion', lambda s: bool(s.get('completed_sword')))
            self.assertEqual(value['state'], terminal)

    def test_scenario_failure_report_retains_selected_scope(self):
        from browser_combat_smoke import main
        dependencies = {'websocket': SimpleNamespace(create_connection=lambda *a, **k: None),
            'capture_browser_screenshots': SimpleNamespace(devtools_target=lambda *a: (_ for _ in ()).throw(TimeoutError('no browser')))}
        with tempfile.TemporaryDirectory() as output:
            with patch.dict('sys.modules', dependencies), patch('sys.argv', ['smoke', '--scenario', 'zane-duel', '--output', output]):
                self.assertEqual(main(), 1)
            report = json.loads((Path(output) / 'report.json').read_text())
        self.assertEqual(report['scenario'], 'zane-duel'); self.assertEqual(report['coverage'], duel.COVERAGE)


if __name__ == '__main__': unittest.main()
