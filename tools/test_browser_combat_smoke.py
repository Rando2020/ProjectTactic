import copy
import json
import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from browser_combat_smoke import CDP, canvas_point, button_point, assert_cancelled, assert_moved, choose_destination, Smoke, main


def idle():
    return {'schema': 1, 'frame': 5, 'phase': 'PLAYER_TURN', 'viewport': [1920, 1080],
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
