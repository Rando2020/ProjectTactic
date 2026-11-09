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
                assert state['schema'] == 1, 'Unexpected courtyard observer schema'
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
        # Load the actual public package too, with no test observer present.
        self.check_production(production_url)

    def check_production(self, production_url):
        nav = self.cdp.command('Page.navigate', {'url': production_url})
        assert not nav.get('errorText'), nav
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            ready = self.cdp.evaluate("""(() => {
             const c = document.querySelector('canvas'), s = document.getElementById('status');
             return !!c && c.width > 0 && c.height > 0 && (!s || getComputedStyle(s).visibility === 'hidden'
                 || getComputedStyle(s).display === 'none');
            })()""")
            assert not self.cdp.errors, 'Browser errors in production package'
            if ready and self.cdp.evaluate('location.href') == production_url:
                time.sleep(2)
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
              'mouse confirmation', 'resource-preserving movement', '1366/1920 layouts', 'production package boot']}
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
