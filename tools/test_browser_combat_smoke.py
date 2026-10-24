import copy
import json
import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from browser_combat_smoke import CDP, canvas_point, button_point, assert_cancelled, assert_moved, choose_destination, Smoke, main, ability_button, assert_quickstep_ready, assert_quickstep_turn_ended


def idle():
    return {'schema': 2, 'frame': 5, 'phase': 'PLAYER_TURN', 'viewport': [1920, 1080],
            'unit': {'id': 'lyra', 'position': [2, 5], 'hp': 90, 'mp': 20, 'moved': False, 'acted': False},
            'command': '', 'ability_id': '', 'menu_visible': False, 'resolving': False,
            'highlights': {'ability': 0, 'move': 0, 'attack': 0, 'aoe': 0, 'path': 0}}


class InputGeometryTests(unittest.TestCase):
    canvas = {'x': 20, 'y': 10, 'width': 960, 'height': 540}

    def test_logical_coordinates_scale_and_offset_to_canvas_css(self):
        self.assertEqual(canvas_point([960, 540], [1920, 1080], self.canvas), (500, 280))

    def test_button_uses_real_rect_center(self):
        button = {'rect': [200, 100, 80, 40], 'visible': True, 'disabled': False}
        self.assertEqual(button_point(button, [1920, 1080], self.canvas), (140, 70))
        for field in ['visible', 'disabled']:
            invalid = {**button, field: not button[field]}
            with self.assertRaises(AssertionError):
                button_point(invalid, [1920, 1080], self.canvas)

    def test_missing_zero_nan_and_out_of_canvas_geometry_is_rejected(self):
        for point, viewport, canvas in [([-1, 20], [1920, 1080], self.canvas),
                                        ([2000, 20], [1920, 1080], self.canvas),
                                        ([20, 20], [0, 1080], self.canvas),
                                        ([float('nan'), 20], [1920, 1080], self.canvas),
                                        ([20, 20], [1920, 1080], {**self.canvas, 'width': 0})]:
            with self.assertRaises(AssertionError):
                canvas_point(point, viewport, canvas)
        with self.assertRaises(AssertionError):
            button_point({'rect': [0, 0, 0, 10], 'visible': True, 'disabled': False}, [1920, 1080], self.canvas)

    def test_destination_is_legal_unoccupied_visible_and_not_origin(self):
        state = idle()
        state['legal_moves'] = [{'position': [2, 5], 'point': [200, 300]},
                                {'position': [2, 4], 'point': [-50, 300]},
                                {'position': [3, 5], 'point': [400, 300]}]
        self.assertEqual(choose_destination(state, self.canvas)['position'], [3, 5])
        state['legal_moves'] = state['legal_moves'][:2]
        with self.assertRaisesRegex(AssertionError, 'legal'):
            choose_destination(state, self.canvas)


class InvariantTests(unittest.TestCase):
    def test_cancel_preserves_resources_actions_and_position(self):
        before = idle()
        assert_cancelled(before, idle())
        for key, value in [('mp', 19), ('hp', 89), ('moved', True), ('acted', True), ('position', [2, 4]), ('id', 'mira')]:
            after = idle(); after['unit'][key] = value
            with self.assertRaises(AssertionError):
                assert_cancelled(before, after)

    def test_cancel_rejects_stale_highlights_or_selection(self):
        for key, value in [('command', 'ability'), ('ability_id', 'long_shot'), ('menu_visible', True), ('resolving', True)]:
            after = idle(); after[key] = value
            with self.assertRaises(AssertionError):
                assert_cancelled(idle(), after)
        for kind in idle()['highlights']:
            after = idle(); after['highlights'][kind] = 1
            with self.assertRaises(AssertionError):
                assert_cancelled(idle(), after)

    def test_move_spends_only_movement_and_reaches_requested_tile(self):
        before = idle(); after = idle()
        after['unit'].update(position=[3, 5], moved=True)
        assert_moved(before, after, [3, 5])
        for key, value in [('mp', 19), ('hp', 89), ('acted', True), ('moved', False), ('position', [4, 5])]:
            wrong = copy.deepcopy(after); wrong['unit'][key] = value
            with self.assertRaises(AssertionError):
                assert_moved(before, wrong, [3, 5])
        after['highlights']['ability'] = 1
        with self.assertRaises(AssertionError):
            assert_moved(before, after, [3, 5])


class QuickstepTests(unittest.TestCase):
    def moved(self):
        state = idle()
        state['unit'].update(instance_id='engine-41', moved=True)
        state['player_turn_serial'] = 7
        state['active_hud'] = {'name': {'text': 'Lyra\nScout', 'instance_id': 'label-50', 'visible': True},
                               'mp': {'text': 'MP: 20', 'instance_id': 'label-51', 'visible': True}}
        return state

    def ready(self):
        state = self.moved()
        state['unit'].update(mp=15, moved=False, acted=True)
        state['active_hud']['mp']['text'] = 'MP: 15'
        state['buttons'] = {
            'move': {'visible': True, 'disabled': False},
            'attack': {'visible': True, 'disabled': True},
            'ability': {'visible': True, 'disabled': True},
        }
        return state

    def handed_off(self):
        state = self.ready()
        actor = {key: state['unit'][key] for key in ('instance_id', 'id', 'position', 'hp', 'mp')}
        actor.update(position=[3, 5], hp=70)  # A later enemy hit is not a Quickstep HP cost.
        state['roster'] = {'engine-41': actor}
        state['unit'] = {**state['unit'], 'id': 'mira', 'instance_id': 'engine-52', 'acted': False, 'moved': False}
        state['player_turn_serial'] = 9
        return state

    def test_quickstep_uses_unique_rendered_label_not_menu_index(self):
        first = {'labels': ['Long Shot', 'free']}
        quickstep = {'labels': ['physical', 'Quickstep', '5MP', '1 move; spends action']}
        self.assertIs(ability_button({'abilities': [first, quickstep]}, 'Quickstep'), quickstep)
        for buttons in ([first], [quickstep, quickstep]):
            with self.assertRaisesRegex(AssertionError, 'one'):
                ability_button({'abilities': buttons}, 'Quickstep')

    def test_quickstep_spends_exactly_five_mp_and_only_action_before_handoff(self):
        before = self.moved(); after = self.ready()
        assert_quickstep_ready(before, after)
        for key, value in [('mp', 10), ('mp', 20), ('hp', 85), ('position', [3, 5]),
                           ('instance_id', 'another-lyra'), ('acted', False), ('moved', True)]:
            wrong = copy.deepcopy(after); wrong['unit'][key] = value
            with self.assertRaises(AssertionError):
                assert_quickstep_ready(before, wrong)
        wrong = copy.deepcopy(after); wrong['player_turn_serial'] += 1
        with self.assertRaises(AssertionError):
            assert_quickstep_ready(before, wrong)
        for key in ('attack', 'ability', 'move'):
            wrong = copy.deepcopy(after); wrong['buttons'][key]['disabled'] = not wrong['buttons'][key]['disabled']
            with self.assertRaises(AssertionError):
                assert_quickstep_ready(before, wrong)

    def test_quickstep_rejects_stale_hidden_or_wrong_active_resource_control(self):
        before = self.moved(); after = self.ready()
        for label, field, value in [('mp', 'text', 'MP: 20'), ('mp', 'text', 'MP: 10'),
                                     ('mp', 'visible', False), ('mp', 'instance_id', 'other-control'),
                                     ('name', 'text', 'Mira\nCleric'), ('name', 'visible', False),
                                     ('name', 'instance_id', 'other-name')]:
            wrong = copy.deepcopy(after); wrong['active_hud'][label][field] = value
            with self.subTest(label=label, field=field, value=value):
                with self.assertRaises(AssertionError):
                    assert_quickstep_ready(before, wrong)

    def run_quickstep_scenario(self, change_hover=None, hover_anchor_frame=8):
        before = self.moved()
        before['buttons'] = {'ability': {'visible': True, 'disabled': False, 'rect': [10, 10, 40, 20]}}
        menu = copy.deepcopy(before)
        menu.update(frame=7, menu_visible=True, command='ability', abilities=[
            {'labels': ['Long Shot'], 'visible': True, 'disabled': False, 'rect': [400, 100, 80, 40]},
            {'labels': ['Quickstep', '5MP'], 'visible': True, 'disabled': False, 'rect': [100, 100, 80, 40]},
        ])
        anchor = copy.deepcopy(menu); anchor['frame'] = hover_anchor_frame
        hovered = copy.deepcopy(menu); hovered['frame'] = hover_anchor_frame + 2
        hover_envelope = {'state': hovered, 'canvas': InputGeometryTests.canvas.copy()}
        if change_hover:
            change_hover(hover_envelope)
        stale_hover = copy.deepcopy(hover_envelope)
        stale_hover['state']['frame'] = hover_anchor_frame + 1
        ready = self.ready(); ready['frame'] = hover_anchor_frame + 4
        ready['buttons']['move']['rect'] = [200, 100, 80, 40]
        moving = copy.deepcopy(ready); moving.update(frame=hover_anchor_frame + 6, command='move')
        moving['legal_moves'] = [{'position': [3, 5], 'point': [400, 300]}]
        moving['highlights']['move'] = 1
        ended = self.handed_off(); ended['frame'] = hover_anchor_frame + 8
        settled = copy.deepcopy(ended); settled['frame'] = hover_anchor_frame + 10
        envelopes = iter([{'state': menu, 'canvas': InputGeometryTests.canvas},
                          {'state': anchor, 'canvas': InputGeometryTests.canvas}, stale_hover, hover_envelope,
                          *[{'state': state, 'canvas': InputGeometryTests.canvas}
                            for state in (ready, moving, ended, settled)]])
        class ScenarioConnection:
            def __init__(self):
                self.sent = []
            def send(self, value):
                message = json.loads(value); self.sent.append(message)
                result = {}
                if message['method'] == 'Runtime.evaluate':
                    value = True if message['params']['expression'] == 'true' else next(envelopes)
                    result = {'result': {'value': value}}
                self.reply = {'id': message['id'], 'result': result}
            def recv(self):
                return json.dumps(self.reply)
        connection = ScenarioConnection(); client = CDP(connection)
        self.last_connection = connection
        with tempfile.TemporaryDirectory() as output:
            smoke = Smoke(client, Path(output), 1)
            with patch.object(smoke, 'screenshot'), patch('browser_combat_smoke.time.sleep'):
                smoke.run_quickstep({'state': before, 'canvas': InputGeometryTests.canvas})
        return connection, smoke

    def test_quickstep_extension_dispatches_four_cdp_mouse_click_sequences(self):
        connection, smoke = self.run_quickstep_scenario()
        self.assertEqual([item['name'] for item in smoke.checkpoints], [
            'quickstep-menu-open', 'quickstep-hover-stable', 'quickstep-action-spent-move-reopened',
            'quickstep-second-movement-range', 'quickstep-second-movement-ended-turn'])
        inputs = [message for message in connection.sent if message['method'] == 'Input.dispatchMouseEvent']
        self.assertEqual([item['params']['type'] for item in inputs], ['mouseMoved', 'mousePressed', 'mouseReleased'] * 4)
        self.assertEqual([(item['params']['x'], item['params']['y']) for item in inputs[::3]],
                         [(35, 20), (90, 70), (140, 70), (220, 160)])
        hover_index = next(i for i, item in enumerate(connection.sent)
                           if item['method'] == 'Input.dispatchMouseEvent' and item['params']['type'] == 'mouseMoved'
                           and item['params']['x'] == 90)
        press_index = next(i for i, item in enumerate(connection.sent)
                           if item['method'] == 'Input.dispatchMouseEvent' and item['params']['type'] == 'mousePressed'
                           and item['params']['x'] == 90)
        self.assertEqual(sum(item['method'] == 'Runtime.evaluate'
                             for item in connection.sent[hover_index + 1:press_index]), 3,
                         'Anchor after mouseMoved at frame 8, skip frame 9, observe frame 10 before pressing')

    def test_hover_anchor_rejects_reflow_after_screenshot_advances_engine_frames(self):
        # The menu screenshot may take many engine frames. Frame 41 is still
        # pre-hover; the shifted row at frames 42/43 must be read before press.
        with self.assertRaises(AssertionError):
            self.run_quickstep_scenario(
                lambda e: e['state']['abilities'][1].update(rect=[100, 400, 80, 40]),
                hover_anchor_frame=41)
        presses = [item for item in self.last_connection.sent
                   if item['method'] == 'Input.dispatchMouseEvent' and item['params']['type'] == 'mousePressed']
        self.assertEqual(len(presses), 1, 'Do not press Quickstep using an old menu-frame baseline')

    def test_hover_reflow_or_hidden_row_fails_before_quickstep_mouse_press(self):
        mutations = [
            lambda e: e['state']['abilities'][1].update(rect=[100, 400, 80, 40]),
            lambda e: e['state']['abilities'][1].update(rect=[100, 100, 88, 40]),
            lambda e: e['state']['abilities'][1].update(visible=False),
            lambda e: e['state']['abilities'][1].update(disabled=True),
            lambda e: e['state']['abilities'][1].update(labels=['A different ability']),
            lambda e: e['canvas'].update(height=600),
            lambda e: e['state']['unit'].update(mp=15),
        ]
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                with self.assertRaises(AssertionError):
                    self.run_quickstep_scenario(mutate)
                presses = [item for item in self.last_connection.sent
                           if item['method'] == 'Input.dispatchMouseEvent' and item['params']['type'] == 'mousePressed']
                self.assertEqual(len(presses), 1, 'Only opening Ability may be pressed before unstable hover rejects')

    def test_second_move_checks_original_instance_after_handoff_without_hp_attribution(self):
        before = self.ready(); after = self.handed_off()
        assert_quickstep_turn_ended(before, after, [3, 5])
        after['unit']['id'] = 'lyra'  # A different active instance may share the archetype ID.
        assert_quickstep_turn_ended(before, after, [3, 5])
        for field, value in [('position', [2, 5]), ('mp', 10), ('instance_id', 'replacement')]:
            wrong = copy.deepcopy(after); wrong['roster']['engine-41'][field] = value
            with self.assertRaises(AssertionError):
                assert_quickstep_turn_ended(before, wrong, [3, 5])
        wrong = copy.deepcopy(after)
        wrong['roster']['another-instance'] = wrong['roster'].pop('engine-41')
        with self.assertRaises(AssertionError):
            assert_quickstep_turn_ended(before, wrong, [3, 5])
        wrong = copy.deepcopy(after); wrong['player_turn_serial'] = before['player_turn_serial']
        with self.assertRaises(AssertionError):
            assert_quickstep_turn_ended(before, wrong, [3, 5])
        wrong = copy.deepcopy(after); wrong['phase'] = 'ENEMY_TURN'
        with self.assertRaises(AssertionError):
            assert_quickstep_turn_ended(before, wrong, [3, 5])


class FakeConnection:
    def __init__(self, replies):
        self.replies = iter(replies)
        self.sent = []
    def send(self, value):
        self.sent.append(json.loads(value))
    def recv(self):
        return json.dumps(next(self.replies))


class CDPTests(unittest.TestCase):
    def test_async_console_exception_and_log_events_are_retained(self):
        events = [{'method': 'Runtime.consoleAPICalled', 'params': {'type': 'error', 'args': [{'value': 'SCRIPT ERROR: bad'}]}},
                  {'method': 'Runtime.exceptionThrown', 'params': {'exceptionDetails': {'text': 'Uncaught'}}},
                  {'method': 'Log.entryAdded', 'params': {'entry': {'level': 'error', 'text': 'failed'}}}]
        client = CDP(FakeConnection([*events, {'id': 1, 'result': {'ok': True}}]))
        self.assertEqual(client.command('Runtime.enable'), {'ok': True})
        self.assertEqual(client.events, events)
        self.assertEqual(len(client.errors), 3)

    def test_eval_exception_is_not_treated_as_an_absent_snapshot(self):
        client = CDP(FakeConnection([{'id': 1, 'result': {'exceptionDetails': {'text': 'bad JS'}}}]))
        with self.assertRaisesRegex(RuntimeError, 'evaluation'):
            client.evaluate('bad JS')

    def test_click_dispatches_mouse_move_press_release_not_game_actions(self):
        connection = FakeConnection([{'id': i, 'result': {}} for i in range(1, 4)])
        client = CDP(connection)
        client.click(200, 300)
        self.assertEqual([m['method'] for m in connection.sent], ['Input.dispatchMouseEvent'] * 3)
        self.assertEqual([m['params']['type'] for m in connection.sent], ['mouseMoved', 'mousePressed', 'mouseReleased'])
        self.assertTrue(all(m['params']['x'] == 200 and m['params']['y'] == 300 for m in connection.sent))


class WaitAndFailureTests(unittest.TestCase):
    def test_resize_captures_wait_for_actual_compact_and_restored_canvas(self):
        original = {'x': 0, 'y': 0, 'width': 1600, 'height': 900}
        compact = {'x': 0, 'y': 0, 'width': 1366, 'height': 768}
        rectangles = [original, original, {**compact, 'height': 900}, compact,
                      compact, {**original, 'x': 10}, original]
        frames = []
        for index, rectangle in enumerate(rectangles):
            state = idle(); state.update(frame=5 + index * 2, intro_visible=False)
            frames.append({'state': state, 'canvas': rectangle})
        observations = iter(frames)
        client = SimpleNamespace(evaluate=lambda expression: next(observations), errors=[],
                                 command=lambda *args: {})
        captures = {}
        class ResizeFinished(Exception):
            pass
        def capture(name, envelope):
            captures[name] = envelope
            if name == 'ashvale-battle-settled':
                raise ResizeFinished()
        with tempfile.TemporaryDirectory() as output:
            smoke = Smoke(client, Path(output), 1)
            with patch.object(smoke, 'checkpoint', side_effect=capture), patch('browser_combat_smoke.time.sleep'):
                with self.assertRaises(ResizeFinished):
                    smoke.run('http://unit.test')
        self.assertEqual(captures['ashvale-battle-compact-1366x768']['canvas'], compact)
        self.assertEqual(captures['ashvale-battle-compact-1366x768']['state']['frame'], 11)
        self.assertEqual(captures['ashvale-battle-settled']['canvas'], original)
        self.assertEqual(captures['ashvale-battle-settled']['state']['frame'], 17)

    def test_wait_ignores_pre_click_snapshot_until_two_new_frames(self):
        with tempfile.TemporaryDirectory() as output:
            states = []
            for frame in (10, 11, 12):
                state = idle(); state['frame'] = frame
                states.append({'state': state, 'canvas': InputGeometryTests.canvas})
            observations = iter(states)
            client = SimpleNamespace(evaluate=lambda expression: next(observations), errors=[])
            smoke = Smoke(client, Path(output), 1)
            with patch('browser_combat_smoke.time.sleep'):
                result = smoke.wait('fresh frame', lambda state: True, after=10)
            self.assertEqual(result['state']['frame'], 12)
            self.assertEqual(smoke.latest, result)

    def test_wait_times_out_with_last_snapshot_retained(self):
        with tempfile.TemporaryDirectory() as output:
            envelope = {'state': idle(), 'canvas': InputGeometryTests.canvas}
            client = SimpleNamespace(evaluate=lambda expression: envelope, errors=[])
            smoke = Smoke(client, Path(output), 1)
            with patch('browser_combat_smoke.time.monotonic', side_effect=[0, 0, 2]), patch('browser_combat_smoke.time.sleep'):
                with self.assertRaisesRegex(TimeoutError, 'last snapshot'):
                    smoke.wait('missing movement', lambda state: False)
            self.assertEqual(smoke.latest, envelope)

    def test_connection_failure_still_writes_machine_readable_diagnostics(self):
        with tempfile.TemporaryDirectory() as output:
            dependencies = {
                'websocket': SimpleNamespace(create_connection=lambda *args, **kwargs: None),
                'capture_browser_screenshots': SimpleNamespace(devtools_target=lambda *args: (_ for _ in ()).throw(TimeoutError('no browser'))),
            }
            with patch.dict('sys.modules', dependencies), patch('sys.argv', ['smoke', '--output', output]):
                self.assertEqual(main(), 1)
            report = json.loads((Path(output) / 'report.json').read_text())
            self.assertEqual(report['status'], 'failed')
            self.assertIn('no browser', report['failure'])
            self.assertEqual(json.loads((Path(output) / 'browser-events.json').read_text()), [])


if __name__ == '__main__':
    unittest.main()
