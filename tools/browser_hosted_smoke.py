#!/usr/bin/env python3
"""Capture actual hosted gameplay for visual review, without game-state hooks."""
import argparse
import json
from pathlib import Path
import re
import time
import urllib.request

from browser_combat_smoke import CDP
from browser_courtyard_smoke import CourtyardSmoke

BASE = 'https://rando2020.github.io/ProjectTactic/'
SCENE = 'res://prototypes/blooming/BloomingBattle.tscn'


def validate_expected_commit(value):
    if not re.fullmatch(r'[0-9a-f]{40}', value):
        raise ValueError('Expected a full lowercase commit SHA')
    return value


def validate_build(info, expected, route):
    validate_expected_commit(expected)
    assert info.get('source_commit') == expected, f'{route} hosted commit does not match release'
    if route == 'courtyard':
        assert info.get('scene') == SCENE, 'Hosted courtyard scene is incorrect'


def capture_inputs(smoke):
    # These are real keyboard controls. No observer, forced state or action calls.
    groups = [
        ([('Escape', 'Escape', 27)], 'hosted-settings'),
        ([('Escape', 'Escape', 27), ('Enter', 'Enter', 13), ('m', 'KeyM', 77),
          ('ArrowRight', 'ArrowRight', 39), ('Enter', 'Enter', 13)], 'hosted-move-review'),
        ([('Escape', 'Escape', 27)], 'hosted-move-cancelled'),
        ([('Enter', 'Enter', 13), ('Enter', 'Enter', 13)], 'hosted-move-completed'),
    ]
    for keys, name in groups:
        for key, code, keycode in keys:
            smoke.key(key, code, keycode)
            time.sleep(0.5)
        time.sleep(1)
        smoke.screenshot(name)
        smoke.cdp.evaluate('document.readyState')  # Drain events after capture.
        assert not smoke.cdp.errors, 'Browser errors during hosted input capture'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--expected-commit', required=True, type=validate_expected_commit)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--port', type=int, default=9222)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'expected_commit': args.expected_commit,
              'scope': 'Live provenance and boot assertions; gameplay outcomes require screenshot review'}
    connection = cdp = None
    try:
        info = {}
        for route in ('courtyard', 'tactics'):
            url = BASE + route + '/build-info.json?release=' + args.expected_commit
            with urllib.request.urlopen(url, timeout=30) as response:
                assert response.status == 200, 'Hosted provenance request failed'
                info[route] = json.load(response)
            validate_build(info[route], args.expected_commit, route)
        report['builds'] = info
        import websocket
        from capture_browser_screenshots import devtools_target
        connection = websocket.create_connection(devtools_target(args.port, 60), timeout=15,
                                                 http_proxy_host=None, origin='http://localhost:9222')
        cdp = CDP(connection)
        report['browser'] = cdp.command('Browser.getVersion')
        for domain in ('Page', 'Runtime', 'Log'):
            cdp.command(domain + '.enable')
        cdp.command('Emulation.setDeviceMetricsOverride',
                    {'width': 1920, 'height': 1080, 'deviceScaleFactor': 1, 'mobile': False})
        for route in ('tactics', 'courtyard'):
            output = args.output / route
            output.mkdir()
            smoke = CourtyardSmoke(cdp, output, 90)
            smoke.check_production(BASE + route + '/?release=' + args.expected_commit)
            if route == 'courtyard':
                capture_inputs(smoke)
        assert not cdp.errors, 'Browser errors before hosted acceptance'
        report['status'] = 'captured_for_visual_review'
    except Exception as error:
        report['failure'] = f'{type(error).__name__}: {error}'
    finally:
        report['browser_errors'] = cdp.errors if cdp else []
        report['inputs'] = cdp.inputs if cdp else []
        report['events'] = cdp.events if cdp else []
        (args.output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        if connection:
            connection.close()
    print(json.dumps({'status': report['status'], 'failure': report.get('failure')}))
    return 0 if report['status'] == 'captured_for_visual_review' else 1


if __name__ == '__main__':
    raise SystemExit(main())
