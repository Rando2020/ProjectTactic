#!/usr/bin/env python3
"""Exercise exported Godot controls through CDP mouse input; never call game actions."""
from __future__ import annotations

import argparse
import base64
import json
import math
from pathlib import Path
import time



class CDP:
    def __init__(self, connection):
        self.connection = connection
        self.message_id = 0
        self.events = []
        self.errors = []
        self.inputs = []

    def command(self, method: str, params: dict | None = None) -> dict:
        self.message_id += 1
        self.connection.send(json.dumps({'id': self.message_id, 'method': method, 'params': params or {}}))
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            response = json.loads(self.connection.recv())
            if response.get('id') == self.message_id:
                if 'error' in response:
                    raise RuntimeError(f'DevTools {method}: {response["error"]}')
                return response.get('result', {})
            event = response.get('method', '')
            if event in ('Runtime.consoleAPICalled', 'Runtime.exceptionThrown', 'Log.entryAdded'):
                self.events.append(response)
                details = response.get('params', {})
                if (event == 'Runtime.exceptionThrown'
                        or (event == 'Runtime.consoleAPICalled' and details.get('type') in ('error', 'assert'))
                        or (event == 'Log.entryAdded' and details.get('entry', {}).get('level') == 'error')):
                    self.errors.append(response)
        raise TimeoutError(f'DevTools {method} response deadline exceeded')

    def evaluate(self, expression: str):
        result = self.command('Runtime.evaluate', {'expression': expression, 'returnByValue': True})
        if 'exceptionDetails' in result:
            self.errors.append({'evaluation_exception': result['exceptionDetails']})
            raise RuntimeError(f'JavaScript evaluation failed: {result["exceptionDetails"]}')
        return result.get('result', {}).get('value')

    def click(self, x: float, y: float, *, move_first: bool = True) -> None:
        self.inputs.append({'type': 'mouse', 'x': x, 'y': y})
        if move_first:
            self.command('Input.dispatchMouseEvent', {'type': 'mouseMoved', 'x': x, 'y': y})
        self.command('Input.dispatchMouseEvent', {'type': 'mousePressed', 'button': 'left', 'buttons': 1,
                                                 'clickCount': 1, 'x': x, 'y': y})
        self.command('Input.dispatchMouseEvent', {'type': 'mouseReleased', 'button': 'left', 'buttons': 0,
                                                 'clickCount': 1, 'x': x, 'y': y})


def canvas_point(point: list, viewport: list, canvas: dict) -> tuple[float, float]:
    x, y = point
    width, height = viewport
    values = [x, y, width, height, *[canvas[k] for k in ('x', 'y', 'width', 'height')]]
    assert all(isinstance(v, (int, float)) and math.isfinite(v) for v in values), 'Non-finite input geometry'
    assert width > 0 and height > 0 and canvas['width'] > 0 and canvas['height'] > 0, 'Empty viewport/canvas'
    assert 0 <= x < width and 0 <= y < height, 'Input point outside Godot viewport'
    return canvas['x'] + x / width * canvas['width'], canvas['y'] + y / height * canvas['height']


def button_point(button: dict, viewport: list, canvas: dict) -> tuple[float, float]:
    assert button['visible'] and not button['disabled'], 'Control is hidden or disabled'
    x, y, width, height = button['rect']
    assert width > 0 and height > 0, 'Control has no layout rectangle'
    return canvas_point([x + width / 2, y + height / 2], viewport, canvas)


def choose_destination(state: dict, canvas: dict) -> dict:
    for candidate in state['legal_moves']:
        if candidate['position'] == state['unit']['position']:
            continue
        try:
            canvas_point(candidate['point'], state['viewport'], canvas)
        except AssertionError:
            continue
        return candidate
    raise AssertionError('No visible legal movement destination supplied by the real grid')


def assert_idle_selection(state: dict) -> None:
    assert state['phase'] == 'PLAYER_TURN' and not state['resolving'], 'Player turn is not idle'
    assert not state['command'] and not state['ability_id'] and not state['menu_visible'], 'Selection not cleared'
    assert all(count == 0 for count in state['highlights'].values()), 'Stale highlights remain'


def assert_cancelled(before: dict, after: dict) -> None:
    assert before['unit'] == after['unit'], 'Cancel changed active unit, resources, position or action flags'
    assert_idle_selection(after)


def assert_moved(before: dict, after: dict, destination: list) -> None:
    assert not before['unit']['moved'] and not before['unit']['acted'], 'Movement fixture already spent a turn action'
    for field in ('id', 'hp', 'mp', 'acted'):
        assert after['unit'][field] == before['unit'][field], f'Movement changed {field}'
    assert destination != before['unit']['position'], 'Movement destination is the origin'
    assert after['unit']['position'] == destination and after['unit']['moved'], 'Legal movement did not complete'
    assert_idle_selection(after)


def ability_button(state: dict, label: str) -> dict:
    matches = [button for button in state['abilities'] if label in button['labels']]
    assert len(matches) == 1, f'Expected exactly one visible {label} menu entry'
    return matches[0]


def assert_active_mp_display(before: dict, after: dict) -> None:
    for name in ('name', 'mp'):
        prior = before['active_hud'][name]
        label = after['active_hud'][name]
        assert label['visible'], f'Active HUD {name} Control is hidden'
        assert label['instance_id'] and label['instance_id'] == prior['instance_id'], f'Active HUD {name} Control identity changed'
    assert after['active_hud']['name']['text'] == before['active_hud']['name']['text'], 'Active HUD changed actor identity before handoff'
    assert after['active_hud']['mp']['text'] == f"MP: {after['unit']['mp']}", 'Rendered active-unit MP is stale or disagrees with backend MP'


def assert_quickstep_ready(before: dict, after: dict) -> None:
    assert before['unit']['moved'] and not before['unit']['acted'], 'Quickstep requires the first move and unused action'
    assert after['player_turn_serial'] == before['player_turn_serial'], 'Quickstep unexpectedly ended the turn'
    for field in ('instance_id', 'id', 'position', 'hp'):
        assert after['unit'][field] == before['unit'][field], f'Quickstep changed {field} before handoff'
    assert after['unit']['mp'] == before['unit']['mp'] - 5, 'Quickstep must charge exactly 5 MP once'
    assert_active_mp_display(before, after)
    assert after['unit']['acted'] and not after['unit']['moved'], 'Quickstep must spend action and reopen movement'
    assert_idle_selection(after)
    assert after['buttons']['move']['visible'] and not after['buttons']['move']['disabled'], 'Quickstep did not enable Move'
    for name in ('attack', 'ability'):
        assert after['buttons'][name]['visible'] and after['buttons'][name]['disabled'], f'Quickstep incorrectly enabled {name}'


def assert_quickstep_turn_ended(before: dict, after: dict, destination: list) -> None:
    assert after['phase'] == 'PLAYER_TURN', 'No subsequent player turn observed'
    assert after['player_turn_serial'] > before['player_turn_serial'], 'Second move did not end the original turn'
    identity = before['unit']['instance_id']
    actor = after['roster'].get(identity)
    assert actor and actor['instance_id'] == identity and actor['id'] == before['unit']['id'], 'Original actor instance lost at handoff'
    assert destination != before['unit']['position'] and actor['position'] == destination, 'Original actor did not reach second destination'
    assert actor['mp'] == before['unit']['mp'], 'Second move/handoff changed original actor MP after Quickstep'
    # Do not compare HP or current manager action flags after handoff: enemy/terrain
    # activity and the next active unit are legitimate and are not Quickstep costs.


OBSERVATION_JS = """
(() => {
  const canvas = document.querySelector('canvas');
  const state = window.__projectTacticQA;
  if (!canvas || !state) return null;
  const status = document.getElementById('status');
  if (status) {
    const style = getComputedStyle(status);
    if (style.visibility !== 'hidden' && style.display !== 'none') return null;
  }
  const r = canvas.getBoundingClientRect();
  return {state, canvas: {x:r.x, y:r.y, width:r.width, height:r.height}};
})()
"""


class Smoke:
    def __init__(self, cdp: CDP, output: Path, timeout: float):
        self.cdp, self.output, self.timeout = cdp, output, timeout
        self.checkpoints = []
        self.latest = None
        output.mkdir(parents=True, exist_ok=True)

    def wait(self, label: str, predicate, after: int = -2, *, expected_canvas: dict | None = None) -> dict:
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            envelope = self.cdp.evaluate(OBSERVATION_JS)
            if self.cdp.errors:
                raise AssertionError(f'Browser errors while waiting for {label}; see browser-events.json')
            if envelope:
                self.latest = envelope
                state = envelope['state']
                if state.get('schema') != 2:
                    raise AssertionError(f'Unsupported QA snapshot schema: {state.get("schema")}')
                # Require a new rendered/layout opportunity, not a stale pre-click snapshot.
                geometry_matches = expected_canvas is None or all(
                    envelope['canvas'].get(key) == value for key, value in expected_canvas.items())
                if state['frame'] > after + 1 and geometry_matches and predicate(state):
                    return envelope
            time.sleep(0.1)
        raise TimeoutError(f'Timed out waiting for {label}; last snapshot saved in report.json')

    def screenshot(self, name: str) -> None:
        data = self.cdp.command('Page.captureScreenshot', {'format': 'png', 'fromSurface': True,
                                                          'captureBeyondViewport': False})
        (self.output / f'{name}.png').write_bytes(base64.b64decode(data['data']))

    def checkpoint(self, name: str, envelope: dict) -> None:
        self.checkpoints.append({'name': name, **envelope})
        self.screenshot(name)

    def click_button(self, envelope: dict, name: str) -> None:
        state = envelope['state']
        self.cdp.click(*button_point(state['buttons'][name], state['viewport'], envelope['canvas']))

    def run(self, url: str) -> None:
        for domain in ('Page', 'Runtime', 'Log'):
            self.cdp.command(f'{domain}.enable')
        # The CI browser begins at about:blank; capture errors from the first navigation.
        navigation = self.cdp.command('Page.navigate', {'url': url})
        assert not navigation.get('errorText'), f'Navigation failed: {navigation}'
        envelope = self.wait('initial player turn', lambda s: s['phase'] == 'PLAYER_TURN' and bool(s['unit']))
        initial = envelope['state']
        original_canvas = envelope['canvas']
        assert initial['unit']['id'] == 'lyra', 'Unexpected initial unit; use a fresh disposable browser profile'
        assert not initial['unit']['moved'] and not initial['unit']['acted'], 'Fixture is not fresh'
        assert_idle_selection(initial)
        self.checkpoint('ashvale-battle-loaded', envelope)

        self.cdp.command('Emulation.setDeviceMetricsOverride', {'width': 1366, 'height': 768,
                          'deviceScaleFactor': 1, 'mobile': False, 'screenWidth': 1366, 'screenHeight': 768})
        compact = self.wait('compact canvas', lambda s: True, after=initial['frame'],
                            expected_canvas={'width': 1366, 'height': 768})
        assert_cancelled(initial, compact['state'])
        self.checkpoint('ashvale-battle-compact-1366x768', compact)
        self.cdp.command('Emulation.clearDeviceMetricsOverride')
        envelope = self.wait('normal canvas restored and intro dismissed', lambda s: not s['intro_visible'],
                             after=compact['state']['frame'], expected_canvas=original_canvas)
        assert_cancelled(initial, envelope['state'])
        self.checkpoint('ashvale-battle-settled', envelope)

        self.click_button(envelope, 'ability')
        menu = self.wait('ability menu opened', lambda s: s['menu_visible'] and s['command'] == 'ability',
                         after=envelope['state']['frame'])
        self.checkpoint('ability-menu-open', menu)
        self.click_button(menu, 'cancel')
        cancelled = self.wait('ability menu Cancel', lambda s: not s['menu_visible'] and not s['command'],
                              after=menu['state']['frame'])
        assert_cancelled(initial, cancelled['state'])
        self.checkpoint('ability-menu-cancelled', cancelled)

        self.click_button(cancelled, 'ability')
        menu = self.wait('ability menu reopened', lambda s: s['menu_visible'] and bool(s['abilities']),
                         after=cancelled['state']['frame'])
        self.cdp.click(*button_point(menu['state']['abilities'][0], menu['state']['viewport'], menu['canvas']))
        targeting = self.wait('Long Shot target selection', lambda s: s['command'] == 'ability_target'
                              and s['ability_id'] == 'long_shot' and s['highlights']['ability'] > 0,
                              after=menu['state']['frame'])
        assert not targeting['state']['menu_visible'], 'Ability menu remained visible during targeting'
        assert targeting['state']['unit'] == initial['unit'], 'Selecting target mode spent resources/actions'
        self.checkpoint('ability-targeting', targeting)
        self.click_button(targeting, 'cancel')
        cancelled = self.wait('target Cancel', lambda s: not s['command'] and not s['ability_id'],
                              after=targeting['state']['frame'])
        assert_cancelled(initial, cancelled['state'])
        self.checkpoint('ability-target-cancelled', cancelled)

        self.click_button(cancelled, 'move')
        moving = self.wait('legal movement range', lambda s: s['command'] == 'move' and bool(s['legal_moves']),
                           after=cancelled['state']['frame'])
        assert not moving['state']['ability_id'] and moving['state']['highlights']['ability'] == 0, 'Stale CAST highlights after Move'
        assert moving['state']['unit'] == initial['unit'], 'Selecting Move spent resources/actions'
        destination = choose_destination(moving['state'], moving['canvas'])
        self.checkpoint('legal-movement-range', moving)
        self.cdp.click(*canvas_point(destination['point'], moving['state']['viewport'], moving['canvas']))
        moved = self.wait('legal movement completed', lambda s: s['unit'].get('moved') and not s['resolving'],
                          after=moving['state']['frame'])
        assert_moved(initial, moved['state'], destination['position'])
        self.checkpoint('legal-movement-completed', moved)
        # Observe a later frame too: catch late script errors or post-animation state changes.
        final = self.wait('post-movement idle', lambda s: not s['resolving'], after=moved['state']['frame'])
        assert_moved(initial, final['state'], destination['position'])
        self.run_quickstep(final)
        self.cdp.evaluate('true')  # Drain preceding console/exception events before reporting success.
        assert not self.cdp.errors, 'Browser errors after final checkpoint'

    def run_quickstep(self, moved: dict) -> None:
        before = moved['state']
        actor_key = before['unit']['instance_id']
        self.click_button(moved, 'ability')
        menu = self.wait('Quickstep ability menu', lambda s: s['menu_visible'] and any(
                         'Quickstep' in b['labels'] and b['visible'] and not b['disabled']
                         and b['rect'][2] > 0 and b['rect'][3] > 0
                         and 0 <= b['rect'][1] and b['rect'][1] + b['rect'][3] <= s['viewport'][1]
                         for b in s['abilities']),
                         after=before['frame'])
        assert menu['state']['unit'] == before['unit'], 'Opening Quickstep menu changed actor resources/actions'
        button = ability_button(menu['state'], 'Quickstep')
        self.checkpoint('quickstep-menu-open', menu)
        point = button_point(button, menu['state']['viewport'], menu['canvas'])
        self.cdp.inputs.append({'type': 'hover', 'x': point[0], 'y': point[1]})
        self.cdp.command('Input.dispatchMouseEvent', {'type': 'mouseMoved', 'x': point[0], 'y': point[1]})
        # Screenshot capture may have advanced many frames since the menu read.
        # Anchor AFTER dispatch, then allow two genuinely newer layout frames.
        hover_anchor = self.wait('Quickstep post-move frame anchor', lambda s: True)
        hovered = self.wait('Quickstep hover layout', lambda s: True, after=hover_anchor['state']['frame'])
        hovered_button = ability_button(hovered['state'], 'Quickstep')
        assert hovered['canvas'] == menu['canvas'] and hovered['state']['viewport'] == menu['state']['viewport'], 'Hover changed canvas geometry'
        assert hovered_button['visible'] and not hovered_button['disabled'], 'Hovered Quickstep row is hidden or disabled'
        assert hovered_button['rect'] == button['rect'] and hovered_button['labels'] == button['labels'], 'Hover moved or replaced the Quickstep row'
        assert hovered['state']['unit'] == menu['state']['unit'], 'Hover changed actor resources/actions'
        self.checkpoint('quickstep-hover-stable', hovered)
        # Do not reacquire/chase a moved row: press/release the original point.
        self.cdp.click(*point, move_first=False)
        ready = self.wait('Quickstep recovery and reopened movement', lambda s:
                          s['unit'].get('instance_id') == actor_key and s['unit'].get('acted')
                          and not s['unit'].get('moved') and not s['resolving'] and not s['command'],
                          after=hovered['state']['frame'])
        assert_quickstep_ready(before, ready['state'])
        self.checkpoint('quickstep-action-spent-move-reopened', ready)

        self.click_button(ready, 'move')
        moving = self.wait('Quickstep second legal movement range', lambda s:
                           s['command'] == 'move' and bool(s['legal_moves']), after=ready['state']['frame'])
        assert moving['state']['unit'] == ready['state']['unit'], 'Second Move selection changed resources/actions'
        assert_active_mp_display(ready['state'], moving['state'])
        assert moving['state']['player_turn_serial'] == before['player_turn_serial'], 'Turn changed before second move'
        assert not moving['state']['ability_id'] and moving['state']['highlights']['ability'] == 0, 'Stale CAST selection after Quickstep'
        destination = choose_destination(moving['state'], moving['canvas'])
        self.checkpoint('quickstep-second-movement-range', moving)
        self.cdp.click(*canvas_point(destination['point'], moving['state']['viewport'], moving['canvas']))
        ended = self.wait('second move ends turn and reaches subsequent player turn', lambda s:
                          s['phase'] == 'PLAYER_TURN' and s['player_turn_serial'] > before['player_turn_serial']
                          and s['roster'].get(actor_key, {}).get('position') == destination['position'],
                          after=moving['state']['frame'])
        assert_quickstep_turn_ended(ready['state'], ended['state'], destination['position'])
        self.checkpoint('quickstep-second-movement-ended-turn', ended)
        settled = self.wait('original actor persists after turn handoff', lambda s: s['phase'] == 'PLAYER_TURN',
                            after=ended['state']['frame'])
        assert_quickstep_turn_ended(ready['state'], settled['state'], destination['position'])
        self.cdp.evaluate('true')
        assert not self.cdp.errors, 'Browser errors after Quickstep turn handoff'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scenario', choices=['quickstep', 'zane-showcase', 'zane-duel'], default='quickstep')
    parser.add_argument('--max-player-turns', type=int, default=20, help='Zane scenario normal Wait budget')
    parser.add_argument('--budget', type=float, default=180, help='Zane scenario total wall-clock budget')
    parser.add_argument('--port', type=int, default=9222)
    parser.add_argument('--url', default='http://127.0.0.1:8000/index.html')
    parser.add_argument('--timeout', type=float, default=45)
    parser.add_argument('--output', type=Path, default=Path('docs/qa/browser-captures'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    connection = cdp = smoke = None
    report = {'status': 'failed', 'url': args.url, 'coverage': ['ability-menu Cancel', 'target Cancel', 'legal movement',
              'Quickstep action/5 MP tradeoff', 'second legal movement ends turn']}
    if args.scenario == 'zane-showcase':
        from browser_zane_showcase import COVERAGE
        report.update(scenario=args.scenario, coverage=COVERAGE)
    elif args.scenario == 'zane-duel':
        from browser_zane_duel import COVERAGE
        report.update(scenario=args.scenario, coverage=COVERAGE)
    try:
        import websocket
        from capture_browser_screenshots import devtools_target
        connection = websocket.create_connection(devtools_target(args.port, args.timeout), timeout=10, http_proxy_host=None)
        cdp = CDP(connection)
        if args.scenario == 'zane-showcase':
            from browser_zane_showcase import ZaneShowcaseSmoke
            smoke = ZaneShowcaseSmoke(cdp, args.output, args.timeout, max_player_turns=args.max_player_turns, budget=args.budget)
        elif args.scenario == 'zane-duel':
            from browser_zane_duel import ZaneDuelSmoke
            smoke = ZaneDuelSmoke(cdp, args.output, args.timeout, max_player_turns=args.max_player_turns, budget=args.budget)
        else:
            smoke = Smoke(cdp, args.output, args.timeout)
        report['browser'] = cdp.command('Browser.getVersion')
        smoke.run(args.url)
        report['status'] = 'passed'
        if args.scenario in ('zane-showcase', 'zane-duel'):
            report['observed_coverage'] = smoke.coverage
    except Exception as error:
        report['failure'] = f'{type(error).__name__}: {error}'
        if smoke:
            try:
                smoke.screenshot('failure')
            except Exception as capture_error:
                report['failure_screenshot_error'] = str(capture_error)
        print(report['failure'], flush=True)
    finally:
        report.update(checkpoints=smoke.checkpoints if smoke else [], last_observation=smoke.latest if smoke else None,
                      inputs=cdp.inputs if cdp else [], browser_errors=cdp.errors if cdp else [])
        (args.output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        (args.output / 'browser-events.json').write_text(json.dumps(cdp.events if cdp else [], indent=2) + '\n')
        if connection:
            connection.close()
    print(f'Browser combat smoke: {report["status"]}; evidence: {args.output}', flush=True)
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
