#!/usr/bin/env python3
"""Exercise real browser keyboard/mouse input against the isolated courtyard export."""
import argparse
import base64
import json
from pathlib import Path
import time

from browser_combat_smoke import CDP, button_point

OBSERVE = """(() => {
 const c = document.querySelector('canvas'), s = window.__courtyardQA;
 const status = document.getElementById('status');
 if (!c || !s || (status && getComputedStyle(status).visibility !== 'hidden'
     && getComputedStyle(status).display !== 'none')) return null;
 const r = c.getBoundingClientRect();
 return {state: s, canvas: {x:r.x,y:r.y,width:r.width,height:r.height}};
})()"""


def assert_unchanged(before, after):
    assert before == after, 'Review/cancel/settings changed combat resources or action state'


def assert_moved(before, after, destination):
    assert destination != before['position'], 'Move destination was the origin'
    assert after['position'] == destination and after['moved'], 'Confirmed movement did not complete'
    for field in ('id', 'hp', 'mp', 'acted'):
        assert after[field] == before[field], f'Movement unexpectedly changed {field}'


def assert_command_menu(state, category, school, entries):
    assert state['selected'] == state['unit']['id'], 'Menu is not owned by the active selected hero'
    assert state['command'] == 'ability' and state['menu_visible'], 'Ability menu is not open'
    assert state['category'] == category and state['school'] == school, 'Wrong category or school'
    field = 'magic_school' if category == 'magic' and not school else 'ability_id'
    other = 'ability_id' if field == 'magic_school' else 'magic_school'
    rows = state['entries']
    assert all(row['visible'] and not row.get(other) for row in rows), 'Mixed or hidden menu rows'
    actual = [row.get(field) for row in rows]
    assert len(actual) == len(set(actual)) and set(actual) == set(entries), f'Wrong {category}/{school} entries: {actual}'


def menu_entry(state, field, value):
    matches = [entry for entry in state['entries'] if entry.get(field) == value]
    assert len(matches) == 1, f'Expected one {field}={value} button'
    assert matches[0]['visible'] and not matches[0]['disabled'], f'{value} is hidden or disabled'
    return matches[0]


def assert_commands(state, *, magic, skills):
    assert not state['command'] and not state['menu_visible'] and not state['review'], 'Commands did not reopen'
    for name, enabled in [('magic', magic), ('skills', skills)]:
        button = state['buttons'][name]
        assert button['visible'] and button['disabled'] == (not enabled), f'Wrong {name} command availability'


class CourtyardSmoke:
    def __init__(self, cdp, output, timeout):
        self.cdp, self.output, self.timeout = cdp, output, timeout
        self.latest = None
        self.checkpoints = []

    def wait(self, label, predicate, after=-2, canvas_size=None):
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            envelope = self.cdp.evaluate(OBSERVE)
            assert not self.cdp.errors, f'Browser errors while waiting for {label}'
            if envelope:
                self.latest = envelope
                state = envelope['state']
                assert state['schema'] == 2, 'Unexpected courtyard observer schema'
                geometry_ready = canvas_size is None or [envelope['canvas']['width'], envelope['canvas']['height']] == list(canvas_size)
                if state['frame'] > after + 1 and geometry_ready and predicate(state):
                    return envelope
            time.sleep(0.1)
        raise TimeoutError(f'Timed out waiting for {label}')

    def screenshot(self, name):
        data = self.cdp.command('Page.captureScreenshot', {'format': 'png', 'fromSurface': True,
                                                         'captureBeyondViewport': False})
        (self.output / f'{name}.png').write_bytes(base64.b64decode(data['data']))

    def checkpoint(self, name, envelope):
        self.checkpoints.append({'name': name, **envelope})
        self.screenshot(name)

    def key(self, key, code=None, keycode=0):
        event = {'key': key, 'code': code or key, 'windowsVirtualKeyCode': keycode,
                 'nativeVirtualKeyCode': keycode}
        self.cdp.inputs.append({'type': 'key', **event})
        self.cdp.command('Input.dispatchKeyEvent', {'type': 'keyDown', **event})
        time.sleep(0.08)
        self.cdp.command('Input.dispatchKeyEvent', {'type': 'keyUp', **event})

    def click_button(self, envelope, button):
        self.cdp.click(*button_point(button, envelope['state']['viewport'], envelope['canvas']))

    def wait_menu(self, category, school, entries, after):
        envelope = self.wait(f'{category}/{school} menu', lambda s: s['menu_visible']
                             and s['command'] == 'ability' and s['category'] == category
                             and s['school'] == school, after)
        assert_command_menu(envelope['state'], category, school, entries)
        return envelope

    def back(self, envelope, predicate, *, mouse=False):
        if mouse:
            self.click_button(envelope, envelope['state']['buttons']['back'])
        else:
            self.key('Escape', keycode=27)
        result = self.wait('one Back navigation step', predicate, envelope['state']['frame'])
        assert_unchanged(envelope['state']['unit'], result['state']['unit'])
        return result

    def check_magic_hierarchy(self, commands, size):
        """Use only browser input, including the complete review-to-command Back chain."""
        baseline = commands['state']['unit']
        assert_commands(commands['state'], magic=True, skills=False)
        self.checkpoint(f'courtyard-zane-commands-{size}', commands)
        # The empty category cannot be opened even via its keyboard shortcut.
        self.key('s', 'KeyS', 83)
        disabled = self.wait('empty Skills ignored', lambda s: not s['command'], commands['state']['frame'])
        assert_commands(disabled['state'], magic=True, skills=False)
        self.key('g', 'KeyG', 71)
        schools = self.wait_menu('magic', '', ['black', 'time'], disabled['state']['frame'])
        self.checkpoint(f'courtyard-magic-schools-{size}', schools)
        assert schools['state']['focus'].get('magic_school') == 'black', 'School keyboard focus is missing'
        self.key('Enter', keycode=13)
        black = self.wait_menu('magic', 'black', ['fire', 'thunderstrike', 'void_pulse'], schools['state']['frame'])
        self.checkpoint(f'courtyard-black-magic-{size}', black)
        schools = self.back(black, lambda s: s['menu_visible'] and s['school'] == '', mouse=True)
        assert_command_menu(schools['state'], 'magic', '', ['black', 'time'])
        assert schools['state']['focus'].get('magic_school') == 'black', 'Back lost the originating school focus'
        self.key('Tab', keycode=9)
        focused = self.wait('Time school keyboard focus', lambda s: s['focus'].get('magic_school') == 'time', schools['state']['frame'])
        self.key('Enter', keycode=13)
        time_magic = self.wait_menu('magic', 'time', ['haste'], focused['state']['frame'])
        self.checkpoint(f'courtyard-time-magic-{size}', time_magic)
        self.click_button(time_magic, menu_entry(time_magic['state'], 'ability_id', 'haste'))
        targeting = self.wait('Haste targeting', lambda s: s['command'] == 'ability_target'
                              and s['ability_id'] == 'haste' and not s['review'], time_magic['state']['frame'])
        # Mouse navigation can move the board cursor. Aim at the other ally with real
        # arrow keys rather than invoking a game method through JavaScript.
        ally = targeting['state']['units']['kael']
        assert ally['hp'] > 0 and ally['team'] == 'player', 'Haste target is not a living ally'
        for axis, positive, negative in [(0, ('ArrowRight', 39), ('ArrowLeft', 37)),
                                         (1, ('ArrowDown', 40), ('ArrowUp', 38))]:
            delta = ally['position'][axis] - targeting['state']['cursor'][axis]
            key, code = positive if delta > 0 else negative
            for _ in range(abs(delta)):
                self.key(key, keycode=code)
        on_ally = self.wait('Haste cursor on Kael', lambda s: s['cursor'] == ally['position'],
                             targeting['state']['frame'])
        self.key('Enter', keycode=13)
        review = self.wait('Haste review', lambda s: s['review'] and s['ability_id'] == 'haste', on_ally['state']['frame'])
        assert_unchanged(baseline, review['state']['unit'])
        self.checkpoint(f'courtyard-haste-review-{size}', review)
        targeting = self.back(review, lambda s: not s['review'] and s['command'] == 'ability_target')
        leaf = self.back(targeting, lambda s: s['command'] == 'ability' and s['menu_visible'], mouse=True)
        assert_command_menu(leaf['state'], 'magic', 'time', ['haste'])
        assert leaf['state']['focus'].get('ability_id') == 'haste', 'Back lost the originating spell focus'
        schools = self.back(leaf, lambda s: s['menu_visible'] and s['school'] == '')
        assert_command_menu(schools['state'], 'magic', '', ['black', 'time'])
        commands = self.back(schools, lambda s: not s['command'] and not s['menu_visible'], mouse=True)
        assert_commands(commands['state'], magic=True, skills=False)
        assert_unchanged(baseline, commands['state']['unit'])
        self.checkpoint(f'courtyard-magic-back-complete-{size}', commands)
        return commands

    def check_kael_skills(self, commands):
        # Advance via the real Wait/facing controls. Never replace the active unit,
        # grant abilities, change CT, or add a test hero in the observer.
        self.key('w', 'KeyW', 87)
        facing = self.wait('Zane Wait facing', lambda s: s['waiting_facing'], commands['state']['frame'])
        self.click_button(facing, facing['state']['confirm'])
        kael = self.wait('Kael natural turn', lambda s: s['phase'] == 'PLAYER_TURN'
                         and s['unit']['id'] == 'kael' and not s['resolving'], facing['state']['frame'])
        self.key('Enter', keycode=13)
        selected = self.wait('Kael selected', lambda s: s['selected'] == 'kael', kael['state']['frame'])
        assert_commands(selected['state'], magic=False, skills=True)
        self.checkpoint('courtyard-kael-commands-1366', selected)
        self.key('g', 'KeyG', 71)
        disabled = self.wait('empty Magic ignored', lambda s: not s['command'], selected['state']['frame'])
        assert_commands(disabled['state'], magic=False, skills=True)
        self.key('s', 'KeyS', 83)
        skills = ['mighty_strike', 'defend', 'delay_strike', 'heavy_slash']
        menu = self.wait_menu('skills', '', skills, disabled['state']['frame'])
        assert_unchanged(selected['state']['unit'], menu['state']['unit'])
        self.checkpoint('courtyard-kael-skills-1366', menu)
        self.click_button(menu, menu_entry(menu['state'], 'ability_id', 'defend'))
        review = self.wait('Defend review', lambda s: s['review'], menu['state']['frame'])
        assert_unchanged(selected['state']['unit'], review['state']['unit'])
        self.checkpoint('courtyard-defend-review-1366', review)
        menu = self.back(review, lambda s: not s['review'] and s['menu_visible'])
        assert_command_menu(menu['state'], 'skills', '', skills)
        commands = self.back(menu, lambda s: not s['command'] and not s['menu_visible'], mouse=True)
        assert_commands(commands['state'], magic=False, skills=True)
        assert_unchanged(selected['state']['unit'], commands['state']['unit'])

    def run(self, url, production_url):
        for domain in ('Page', 'Runtime', 'Log'):
            self.cdp.command(f'{domain}.enable')
        self.cdp.command('Emulation.setDeviceMetricsOverride', {'width': 1920, 'height': 1080,
                         'deviceScaleFactor': 1, 'mobile': False})
        nav = self.cdp.command('Page.navigate', {'url': url})
        assert not nav.get('errorText'), nav
        initial = self.wait('courtyard player turn', lambda s: s['phase'] == 'PLAYER_TURN' and not s['resolving'])
        state = initial['state']
        assert state['scene'] == 'res://prototypes/blooming/BloomingBattle.tscn' and state['unit_count'] == 4
        assert state['unit']['id'] == 'zane' and state['unit']['position'] == [3, 8]
        assert state['unit']['hp'] == 320 and state['unit']['mp'] == 90
        assert not state['selected'] and not state['settings'] and not state['unit']['moved']
        self.checkpoint('courtyard-loaded-1920', initial)
        self.key('Escape', keycode=27)
        settings = self.wait('settings open', lambda s: s['settings'], state['frame'])
        assert_unchanged(state['unit'], settings['state']['unit'])
        self.checkpoint('courtyard-settings', settings)
        self.key('Escape', keycode=27)
        closed = self.wait('settings closed', lambda s: not s['settings'], settings['state']['frame'])
        assert_unchanged(state['unit'], closed['state']['unit'])
        self.key('Enter', keycode=13)
        selected = self.wait('Zane selected', lambda s: s['selected'] == 'zane', closed['state']['frame'])
        selected = self.check_magic_hierarchy(selected, 1920)
        self.key('m', 'KeyM', 77)
        aiming = self.wait('Move targeting', lambda s: s['command'] == 'move', selected['state']['frame'])
        self.key('ArrowRight', keycode=39)
        self.key('Enter', keycode=13)
        review = self.wait('movement review', lambda s: s['review'], aiming['state']['frame'])
        destination = review['state']['cursor']
        assert destination != state['unit']['position']
        assert_unchanged(state['unit'], review['state']['unit'])
        self.checkpoint('courtyard-move-review', review)
        self.key('Escape', keycode=27)
        cancelled = self.wait('review cancelled', lambda s: not s['review'] and s['command'] == 'move', review['state']['frame'])
        assert_unchanged(state['unit'], cancelled['state']['unit'])
        self.key('Enter', keycode=13)
        review = self.wait('review reopened', lambda s: s['review'], cancelled['state']['frame'])
        self.cdp.click(*button_point(review['state']['confirm'], review['state']['viewport'], review['canvas']))
        moved = self.wait('confirmed move', lambda s: s['unit']['moved'] and not s['resolving'], review['state']['frame'])
        assert_moved(state['unit'], moved['state']['unit'], destination)
        self.checkpoint('courtyard-move-completed', moved)
        self.cdp.command('Emulation.setDeviceMetricsOverride', {'width': 1366, 'height': 768,
                         'deviceScaleFactor': 1, 'mobile': False})
        compact = self.wait('compact viewport', lambda s: True, moved['state']['frame'], (1366, 768))
        assert_unchanged(moved['state']['unit'], compact['state']['unit'])
        self.checkpoint('courtyard-compact-1366', compact)
        if not compact['state']['selected']:
            self.key('Enter', keycode=13)
            compact = self.wait('Zane reselected', lambda s: s['selected'] == 'zane', compact['state']['frame'])
        commands = self.check_magic_hierarchy(compact, 1366)
        self.check_kael_skills(commands)
        # Load the actual public package too, with no test observer present.
        self.check_production(production_url)

    def check_production(self, production_url):
        nav = self.cdp.command('Page.navigate', {'url': production_url})
        assert not nav.get('errorText'), nav
        deadline = time.monotonic() + self.timeout
        readiness = """(() => {
         const c = document.querySelector('canvas'), s = document.getElementById('status');
         return {url: location.href, ready: document.readyState === 'complete' &&
             !!c && c.width > 0 && c.height > 0 && (!s || getComputedStyle(s).visibility === 'hidden'
             || getComputedStyle(s).display === 'none')};
        })()"""
        while time.monotonic() < deadline:
            state = self.cdp.evaluate(readiness)
            assert not self.cdp.errors, 'Browser errors in production package'
            if state['ready'] and state['url'] == production_url:
                time.sleep(2)
                settled = self.cdp.evaluate(readiness)
                assert not self.cdp.errors, 'Browser errors during production settle'
                if not settled['ready'] or settled['url'] != production_url:
                    continue
                assert self.cdp.evaluate('typeof window.__courtyardQA') == 'undefined', 'Observer leaked into production'
                self.screenshot('courtyard-production-package')
                assert not self.cdp.errors, 'Browser errors during production settle or capture'
                return
            time.sleep(0.2)
        raise TimeoutError('Production courtyard package did not load')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', required=True)
    parser.add_argument('--production-url', required=True)
    parser.add_argument('--port', type=int, default=9222)
    parser.add_argument('--timeout', type=float, default=60)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'coverage': ['settings open/close', 'move review/cancel',
              'mouse confirmation', 'resource-preserving movement', '1366/1920 layouts',
              'Magic/Skills categories and disabled empty categories', 'Black/Time schools and hidden empty White',
              'owned spell and skill leaves', 'Haste review/target/leaf/schools/commands Back chain',
              'Kael natural turn and Defend review/cancel', 'production package boot']}
    connection = cdp = smoke = None
    try:
        import websocket
        from capture_browser_screenshots import devtools_target
        connection = websocket.create_connection(devtools_target(args.port, args.timeout), timeout=15,
                                                http_proxy_host=None, origin='http://localhost:9222')
        cdp = CDP(connection)
        smoke = CourtyardSmoke(cdp, args.output, args.timeout)
        report['browser'] = cdp.command('Browser.getVersion')
        smoke.run(args.url, args.production_url)
        assert not cdp.errors, 'Browser errors before final acceptance'
        report['status'] = 'passed'
    except Exception as error:
        report['failure'] = f'{type(error).__name__}: {error}'
        if smoke:
            try:
                smoke.screenshot('failure')
            except Exception as capture_error:
                report['capture_error'] = str(capture_error)
    finally:
        report.update(checkpoints=smoke.checkpoints if smoke else [], last_observation=smoke.latest if smoke else None,
                      inputs=cdp.inputs if cdp else [], browser_errors=cdp.errors if cdp else [])
        (args.output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        (args.output / 'browser-events.json').write_text(json.dumps(cdp.events if cdp else [], indent=2) + '\n')
        if connection:
            connection.close()
    print(json.dumps({'status': report['status'], 'failure': report.get('failure')}))
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
