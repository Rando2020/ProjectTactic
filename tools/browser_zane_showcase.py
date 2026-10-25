"""Optional real-input Zane Practice3D scenario, not a gameplay control bridge."""
from __future__ import annotations

import math
import time

from browser_combat_smoke import Smoke, ability_button, assert_idle_selection, assert_moved, assert_active_mp_display, button_point, canvas_point

MODEL = 'res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb'
MODEL_SHA = '669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90'
COVERAGE = ['normal initiative/Wait', 'actual imported Zane 3D model screenshot', 'legal Zane movement',
            'Fire 12 MP/one action', 'one charge/release', 'hand/projectile evidence',
            'authoritative outcome-consistent feedback', 'owned-effect cleanup']


def assert_zane_profile(state: dict) -> None:
    profile = state['zane']['profile']
    assert profile['available'] and profile['output_visible'], 'Zane imported 3D profile/output is unavailable'
    assert profile['profile_id'] == 'zane_impact_v1' and profile['asset_path'] == MODEL, 'Wrong Zane presentation/model'
    assert profile['model_sha256'] == MODEL_SHA, 'Wrong new-model metadata identity'
    assert profile['model_instance_id'] and profile['skeleton_bones'] > 0, 'No actual instantiated imported rig'


def _visible(candidates: list, state: dict, canvas: dict) -> list:
    result = []
    for candidate in candidates:
        try:
            canvas_point(candidate['point'], state['viewport'], canvas)
        except AssertionError:
            continue
        result.append(candidate)
    return result


def choose_showcase_destination(state: dict, canvas: dict) -> dict:
    candidates = _visible([c for c in state['legal_moves'] if c['position'] != state['unit']['position']], state, canvas)
    assert candidates, 'No visible observed legal Zane move'
    preferred = next((c for c in candidates if c['position'] == [4, 5]), None)
    if preferred:
        return preferred
    enemies = [u['position'] for u in state['roster'].values() if u.get('team') == 'enemy' and u['hp'] > 0]
    return min(candidates, key=lambda c: min((sum(abs(a-b) for a, b in zip(c['position'], e)) for e in enemies), default=0))


def legal_enemy_targets(state: dict, canvas: dict) -> list:
    return _visible([u for u in state['legal_ability_targets']
                     if u['team'] == 'enemy' and u['hp'] > 0], state, canvas)


def assert_fire_result(before: dict, after: dict, key: str) -> dict:
    assert_zane_profile(after)
    actor = after['unit']
    assert actor['instance_id'] == before['unit']['instance_id'] and actor['id'] == 'zane', 'Fire lost original actor before handoff'
    assert after['player_turn_serial'] == before['player_turn_serial'], 'Fire unexpectedly handed off before action observation'
    assert actor['position'] == before['unit']['position'] and actor['hp'] == before['unit']['hp'], 'Fire moved or damaged its caster'
    assert actor['mp'] == before['unit']['mp'] - 12, 'Fire must spend exactly 12 MP once'
    assert_active_mp_display(before, after)
    assert actor['acted'] and not before['unit']['acted'] and actor['moved'] == before['unit']['moved'], 'Fire must spend one action, not movement'
    assert_idle_selection(after)
    evidence = after['zane']
    assert not evidence['overflow'], 'Observer evidence bound exceeded; coverage would be incomplete'
    assert evidence['lifecycle'] == {'ticket': before['zane']['lifecycle']['ticket'] + 1, 'phase': 'idle'}, 'Fire must admit exactly one lifecycle ticket and finish it'
    assert not evidence['owners'], 'Zane action owner/effects/audio not cleaned up'
    assert evidence['cleanup'] == {'reaction_marks': 0, 'camera_kick_remaining': 0, 'rig_state': 'idle'}, 'Fire presentation cleanup is incomplete'
    events = [e for e in evidence['events'] if e['key'] == key]
    cues = [e['value'] for e in events if e['kind'] == 'cue']
    phases = [e['value'] for e in events if e['kind'] == 'phase']
    for cue in ('fire_charge', 'fire_release'):
        assert cues.count(cue) == 1, f'Expected exactly one {cue}'
    for phase in ('charge', 'release'):
        assert phases.count(phase) == 1, f'Expected exactly one {phase} phase'
    assert phases.index('charge') < phases.index('release'), 'Fire phase order reversed'
    results = [e['result'] for e in events if e['kind'] == 'outcome']
    assert results, 'No authoritative resolver outcome recorded for Fire ticket'
    categories = ['miss' if r.get('missed') else 'immune' if r.get('affinity', 1) == 0 else 'hit' for r in results]
    impact = any(not r.get('missed') and r.get('affinity', 1) != 0 and
                 sum(r.get(k, 0) for k in ('applied_hp_damage', 'temper_damage', 'ether_damage')) > 0 for r in results)
    expected_cue = 'fire_hit' if impact else 'fire_immune' if 'immune' in categories else 'fire_miss'
    assert [c for c in cues if c in ('fire_hit', 'fire_miss', 'fire_immune')] == [expected_cue], 'Fire cue contradicts actual outcome'
    expected_phase = 'impact' if impact else 'deflect' if 'immune' in categories else 'dissipate'
    assert expected_phase in phases, 'Missing truthful outcome phase'
    if not impact:
        assert not any(p in ('impact', 'critical', 'armor', 'kick', 'pause') or p.startswith('hurt:') for p in phases), 'Miss/immune falsely presented a hit'
    samples = [s for s in evidence['samples'] if s['key'] == key]
    charges = [s for s in samples if s['role'] == 'charge']
    projectiles = [s for s in samples if s['role'] == 'projectile']
    labels = [s['text'] for s in samples if s['role'] == 'outcome']
    assert charges and projectiles, 'Missing actual hand charge/projectile samples'
    assert any(math.dist(s['point'], s['hand']) <= 8 for s in charges), 'Charge is detached from observed hand'
    assert any(math.dist(s['origin'], s['hand']) <= 16 for s in projectiles), 'Projectile launch is detached from imported hand'
    assert len(labels) == len(results), 'Each authoritative recipient requires its own rendered outcome Label'
    remaining_labels = labels.copy()
    for result, category in zip(results, categories):
        hp = int(result.get('applied_hp_damage', 0))
        expected = 'MISS' if category == 'miss' else 'IMMUNE' if category == 'immune' else (
            f"-{hp} HP" if hp > 0 else '0 HP')
        armor = 0
        for field, name in [('temper_damage', 'Temper'), ('ether_damage', 'Ether')]:
            loss = int(result.get(field, 0))
            armor += loss
            if loss > 0:
                expected += f"\n-{loss} {name}"
        if result.get('critical') and category == 'hit' and (hp > 0 or armor > 0):
            expected += '\nCRIT'
        if category == 'hit':
            affinity = float(result.get('affinity', 1))
            if affinity > 1:
                expected += ' [WEAK]'
            elif affinity < 1:
                expected += ' [RESIST]'
        # Consume one complete actual Label per authoritative recipient. Neither
        # unexplained trailing damage nor another recipient's armor text counts.
        assert expected in remaining_labels, f'No exact rendered outcome Label for {expected!r}'
        remaining_labels.remove(expected)
    return {'outcomes': categories, 'impact_observed': impact, 'mp_spent': 12, 'action_tickets': 1,
            'charge_cues': 1, 'release_cues': 1, 'audio_scope': 'cue-start signals only; no listening claim'}


class ZaneShowcaseSmoke(Smoke):
    def __init__(self, cdp, output, timeout, *, max_player_turns=20, budget=180):
        super().__init__(cdp, output, timeout)
        self.max_player_turns, self.budget = max_player_turns, budget
        self.deadline = None
        self.coverage = {}
        self.turns_waited = []

    def wait(self, label, predicate, after=-2, **kwargs):
        original = self.timeout
        if self.deadline is not None:
            remaining = self.deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(f'Zane showcase total {self.budget}s budget exhausted at {label}')
            self.timeout = min(original, remaining)
        try:
            return super().wait(label, predicate, after, **kwargs)
        finally:
            self.timeout = original

    def next_player(self, envelope):
        assert len(self.turns_waited) < self.max_player_turns, 'Zane showcase player-turn budget exhausted'
        state = envelope['state']
        self.turns_waited.append({'id': state['unit']['id'], 'serial': state['player_turn_serial']})
        self.click_button(envelope, 'wait')
        return self.wait('normal Wait/initiative handoff', lambda s: s['phase'] == 'PLAYER_TURN'
                         and not s['resolving'] and s['player_turn_serial'] > state['player_turn_serial'], after=state['frame'])

    def move_zane(self, envelope):
        before = envelope['state']
        self.click_button(envelope, 'move')
        moving = self.wait('Zane observed legal movement', lambda s: s['command'] == 'move' and bool(s['legal_moves']), after=before['frame'])
        assert moving['state']['unit'] == before['unit'], 'Move selection spent resources'
        destination = choose_showcase_destination(moving['state'], moving['canvas'])
        self.checkpoint('zane-legal-move-range', moving)
        self.cdp.click(*canvas_point(destination['point'], moving['state']['viewport'], moving['canvas']))
        moved = self.wait('Zane movement settled', lambda s: s['unit'].get('moved') and not s['resolving'], after=moving['state']['frame'])
        assert_moved(before, moved['state'], destination['position'])
        self.checkpoint('zane-3d-movement-completed', moved)
        return moved

    def fire_targeting(self, envelope):
        self.click_button(envelope, 'ability')
        menu = self.wait('Zane Fire menu', lambda s: s['menu_visible'] and any('Fire' in b['labels'] for b in s['abilities']), after=envelope['state']['frame'])
        assert menu['state']['unit'] == envelope['state']['unit'], 'Ability menu spent resources'
        self.cdp.click(*button_point(ability_button(menu['state'], 'Fire'), menu['state']['viewport'], menu['canvas']))
        return self.wait('normal Fire targeting', lambda s: s['command'] == 'ability_target' and s['ability_id'] == 'fire', after=menu['state']['frame'])

    def run(self, url):
        self.deadline = time.monotonic() + self.budget
        for domain in ('Page', 'Runtime', 'Log'):
            self.cdp.command(f'{domain}.enable')
        navigation = self.cdp.command('Page.navigate', {'url': url})
        assert not navigation.get('errorText'), f'Navigation failed: {navigation}'
        envelope = self.wait('Practice3D normal initial turn', lambda s: s['phase'] == 'PLAYER_TURN' and bool(s['unit']) and not s['intro_visible'])
        initial = envelope['state']
        assert initial['unit']['id'] == 'lyra', 'Practice3D changed normal initial initiative'
        assert {u['id'] for u in initial['roster'].values() if u['team'] == 'player'} == {'lyra', 'kael', 'mira', 'zane'}, 'Normal party was changed'
        assert_zane_profile(initial)
        assert_idle_selection(initial)
        self.checkpoint('zane-practice-actual-3d-loaded', envelope)
        while envelope['state']['unit']['id'] != 'zane':
            envelope = self.next_player(envelope)
        assert_zane_profile(envelope['state'])
        self.checkpoint('zane-first-normal-turn', envelope)
        envelope = self.move_zane(envelope)
        envelope = self.next_player(envelope)
        while True:
            while envelope['state']['unit']['id'] != 'zane':
                envelope = self.next_player(envelope)
            assert_zane_profile(envelope['state'])
            targeting = self.fire_targeting(envelope)
            assert targeting['state']['unit'] == envelope['state']['unit'], 'Selecting Fire spent resources'
            targets = legal_enemy_targets(targeting['state'], targeting['canvas'])
            if targets:
                break
            self.click_button(targeting, 'cancel')
            envelope = self.wait('unreachable Fire cancelled', lambda s: not s['command'] and not s['ability_id'], after=targeting['state']['frame'])
            assert_idle_selection(envelope['state'])
            envelope = self.move_zane(envelope)
            envelope = self.next_player(envelope)
        before = targeting['state']
        self.checkpoint('zane-fire-legal-enemy-targeting', targeting)
        self.cdp.click(*canvas_point(targets[0]['point'], before['viewport'], targeting['canvas']))
        # Short phases are retained by the read-only observer; polling cannot
        # manufacture/replay a phase to get a screenshot. Loaded/final captures
        # show the real imported 3D battle; live effect capture is opportunistic.
        fired = self.wait('Fire recovery and owned cleanup', lambda s: s['unit'].get('id') == 'zane'
                          and s['unit'].get('acted') and not s['resolving'] and not s['zane']['owners'], after=before['frame'])
        keys = {e['key'] for e in fired['state']['zane']['events'] if e['kind'] == 'cue'
                and e.get('value') == 'fire_charge' and e.get('ability_id') == 'fire'}
        assert len(keys) == 1, 'Expected one admitted Fire action key'
        key = keys.pop()
        self.coverage = assert_fire_result(before, fired['state'], key)
        self.coverage.update(waited_player_turns=self.turns_waited, title_entry='not exercised; QA Practice3D bootstrap')
        self.checkpoint('zane-fire-outcome-and-cleanup', fired)
        settled = self.wait('late Fire cleanup', lambda s: not s['resolving'], after=fired['state']['frame'])
        assert_fire_result(before, settled['state'], key)
        self.cdp.evaluate('true')
        assert not self.cdp.errors, 'Browser errors after Zane showcase'
