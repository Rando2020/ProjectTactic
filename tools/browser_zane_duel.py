"""Optional first-sword duel lane. Real CDP input; read-only observations only."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import time

from browser_combat_smoke import assert_active_mp_display, assert_idle_selection, assert_moved, canvas_point
from browser_zane_showcase import ZaneShowcaseSmoke

MODEL = 'res://assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb'
ASSET_DIRECTORY = Path(__file__).resolve().parents[1] / 'godot/assets/3d/characters/zane_painterly_v1'


def candidate_model_sha() -> str:
    """Bind browser observation to the actual local candidate, not its self-report."""
    metadata = json.loads((ASSET_DIRECTORY / 'presentation.json').read_text())
    assert metadata['profile_id'] == 'zane_painterly_v1' and metadata['model'] == MODEL, 'Wrong local candidate metadata identity'
    digest = hashlib.sha256((ASSET_DIRECTORY / 'zane_painterly_v1.glb').read_bytes()).hexdigest()
    assert metadata['model_sha256'] == digest, 'Local candidate GLB does not match its frozen metadata'
    return digest


def assert_zane_profile(state: dict) -> None:
    """Duel only; full-party showcase keeps its separate original-impact assertion."""
    profile = state['zane']['profile']
    assert profile['available'] and profile['output_visible'], 'Zane imported 3D profile/output is unavailable'
    assert profile['profile_id'] == 'zane_painterly_v1' and profile['asset_path'] == MODEL, 'Wrong duel painterly presentation/model'
    assert profile['model_sha256'] == candidate_model_sha(), 'Wrong painterly model metadata identity'
    assert profile['model_instance_id'] and profile['skeleton_bones'] == 16, 'No actual instantiated sixteen-bone painterly rig'


COVERAGE = ['exact Zane/Storm Imp duel roster', 'actual imported Zane 3D model screenshot',
            'legal one-step movement', 'one sword action/zero MP', 'authoritative damage and counter resource deltas',
            'truthful complete outcome label/cues', 'owned-effect cleanup',
            'enemy AI/title/Fire/terminal/replay remain native coverage, not this browser lane']


def assert_duel_roster(state: dict, *, initial=False) -> None:
    assert state['duel'] == {'mode': 'zane_duel', 'rig3d': True, 'zane_showcase': False}, 'Wrong duel admission/presentation flags'
    roster = list(state['roster'].values())
    players = [unit for unit in roster if unit['team'] == 'player']
    enemies = [unit for unit in roster if unit['team'] == 'enemy']
    assert len(roster) == 2 and len(players) == len(enemies) == 1, 'Duel requires exactly two actors and no extra party members'
    assert players[0]['id'] == players[0]['archetype'] == 'zane', 'Duel player must be Zane'
    assert enemies[0]['archetype'] == 'storm_imp', 'Duel enemy must be actual Storm Imp archetype'
    assert all(unit['hp'] >= 0 and unit['instance_id'] for unit in roster), 'Invalid observed original duel actors'
    assert state['unit']['id'] == 'zane' and state['unit']['instance_id'] == players[0]['instance_id'], 'Expected normal Zane player turn'
    if initial:
        assert players[0]['position'] == state['unit']['position'] == [4, 5] and enemies[0]['position'] == [6, 5], 'Wrong fresh duel positions'
        assert not state['unit']['moved'] and not state['unit']['acted'], 'Duel is not fresh'
        assert all(unit['hp'] > 0 for unit in roster), 'Fresh duel actor is already defeated'


def choose_duel_destination(state: dict, canvas: dict) -> dict:
    candidates = [move for move in state['legal_moves'] if move['position'] == [5, 5]]
    assert len(candidates) == 1, 'No unique observed legal duel one-step destination'
    canvas_point(candidates[0]['point'], state['viewport'], canvas)
    return candidates[0]


def duel_sword_target(state: dict, canvas: dict) -> dict:
    targets = [unit for unit in state['legal_attack_targets']
               if unit['team'] == 'enemy' and unit['hp'] > 0 and unit['archetype'] == 'storm_imp']
    assert len(targets) == 1, 'Expected one observed legal living Storm Imp sword target'
    target = targets[0]
    assert target['instance_id'] in state['roster'], 'Attack target is not the original duel actor'
    for field in ('id', 'archetype', 'team', 'hp', 'position'):
        assert target[field] == state['roster'][target['instance_id']][field], 'Attack target differs from actual roster'
    canvas_point(target['point'], state['viewport'], canvas)
    return target


def _assert_damage(before: dict, after: dict, result: dict) -> None:
    for resource, field in [('hp', 'applied_hp_damage'), ('temper', 'temper_damage'), ('ether', 'ether_damage')]:
        loss = result.get(field, 0)
        assert isinstance(loss, (int, float)) and loss >= 0, 'Invalid authoritative resource loss'
        assert after[resource] == before[resource] - loss, f'{resource} delta disagrees with authoritative applied damage'


def _outcome_label(result: dict) -> str:
    if result.get('missed'): return 'MISS'
    if result.get('affinity', 1) == 0: return 'IMMUNE'
    hp = int(result.get('applied_hp_damage', 0))
    label = f'-{hp} HP' if hp > 0 else '0 HP'
    armor = 0
    for field, name in [('temper_damage', 'Temper'), ('ether_damage', 'Ether')]:
        loss = int(result.get(field, 0)); armor += loss
        if loss > 0: label += f'\n-{loss} {name}'
    if result.get('critical') and hp + armor > 0: label += '\nCRIT'
    affinity = float(result.get('affinity', 1))
    if affinity > 1: label += ' [WEAK]'
    elif affinity < 1: label += ' [RESIST]'
    return label


def assert_sword_result(before: dict, after: dict, key: str, cleanup: dict) -> dict:
    assert_duel_roster(after)
    assert_zane_profile(after)
    actor, prior = after['unit'], before['unit']
    assert actor['instance_id'] == prior['instance_id'] and set(after['roster']) == set(before['roster']), 'Sword replaced an original duel actor'
    assert after['player_turn_serial'] == before['player_turn_serial'] + 1, 'Completed move+sword must record exactly one turn handoff'
    assert prior['moved'] and not prior['acted'], 'Sword must follow the first legal movement'
    assert actor['position'] == prior['position'] and actor['moved'] == prior['moved'], 'Sword spent movement'
    assert actor['mp'] == prior['mp'], 'Basic sword must cost zero MP'
    assert not prior['acted'] and actor['acted'], 'Sword must spend exactly one action'
    assert_active_mp_display(before, after)
    assert_idle_selection(after)
    evidence = after['zane']
    assert not evidence['overflow'], 'Observer evidence bound exceeded'
    assert evidence['lifecycle'] == {'ticket': before['zane']['lifecycle']['ticket'] + 1, 'phase': 'idle'}, 'Sword must finish exactly one lifecycle ticket'
    assert evidence['cleanup']['rig_state'] == 'idle', 'Sword lifecycle did not restore its own pose at handoff'
    owner = after['sword_owner']
    assert owner['key'] == key and cleanup['key'] == key and cleanup['owner_instance_id'] == owner['instance_id'], 'Cleanup is not tied to the admitted sword owner'
    assert cleanup['frame'] >= after['frame'], 'Cleanup observation predates action completion'
    assert not cleanup['owner_alive'] and cleanup['live_effects'] == cleanup['playing_voices'] == cleanup['reaction_marks'] == 0, 'Original sword owner/effects/audio/reactions not cleaned up'
    assert cleanup['camera_kick_remaining'] == 0 or (cleanup['battle_removed'] and cleanup['camera_kick_remaining'] is None), 'Original sword camera cleanup incomplete'

    events = [event for event in evidence['events'] if event['key'] == key]
    cues = [event['value'] for event in events if event['kind'] == 'cue']
    phases = [event['value'] for event in events if event['kind'] == 'phase']
    assert cues.count('sword_load') == cues.count('sword_release') == 1, 'Expected exactly one sword load/release cue'
    assert phases.count('charge') == phases.count('release') == 1 and phases.index('charge') < phases.index('release'), 'Sword preparation/release order or count wrong'
    results = [event['result'] for event in events if event['kind'] == 'outcome']
    primary = [result for result in results if result.get('feedback_owner') == 'zane_impact_v1']
    counters = [result for result in results if not result.get('feedback_owner')]
    assert len(primary) == 1 and len(results) == 1 + len(counters), 'Expected one authoritative primary sword result'
    result = primary[0]
    assert len(counters) == int(bool(result.get('counter'))), 'Counter evidence disagrees with authoritative sword result'
    target_key = next(identity for identity, unit in before['roster'].items() if unit['team'] == 'enemy')
    _assert_damage(before['roster'][target_key], after['roster'][target_key], result)
    assert (after['roster'][target_key]['hp'] == 0) == bool(result.get('defeated')), 'Target defeat disagrees with authoritative result'
    _assert_damage(prior, actor, counters[0] if counters else {})
    assert after['roster'][target_key]['mp'] == before['roster'][target_key]['mp'], 'Sword/counter unexpectedly changed enemy MP'
    for field in ('hp', 'mp', 'temper', 'ether', 'position'):
        assert after['roster'][actor['instance_id']][field] == actor[field], 'Active actor and original roster disagree'
    category = 'miss' if result.get('missed') else 'immune' if result.get('affinity', 1) == 0 else 'hit'
    impact = category == 'hit' and sum(result.get(field, 0) for field in ('applied_hp_damage', 'temper_damage', 'ether_damage')) > 0
    assert cues.count('sword_hit') == int(impact), 'Sword impact cue contradicts applied outcome'
    assert not any(cue.startswith('fire_') for cue in cues), 'Sword wrongly emitted Fire cues'
    if impact:
        assert phases.count('impact') == 1, 'Sword impact phase missing or duplicated'
    else:
        assert not any(phase in ('impact', 'critical', 'armor', 'kick', 'pause') or phase.startswith('hurt:') for phase in phases), 'Miss/immune falsely presented a hit'
    labels = [sample['text'] for sample in evidence['samples'] if sample['key'] == key and sample['role'] == 'outcome']
    assert labels == [_outcome_label(result)], 'Rendered primary outcome Label disagrees with authoritative complete result'
    return {'outcome': category, 'impact_observed': impact, 'counter_observed': bool(counters),
            'mp_spent': 0, 'action_tickets': 1, 'audio_scope': 'cue-start signals only; no listening claim'}


class ZaneDuelSmoke(ZaneShowcaseSmoke):
    def wait(self, label, predicate, after=-2, **kwargs):
        def checked(state):
            assert state.get('phase') != 'RESULTS' or state.get('completed_sword'), ('Unexpected duel terminal transition: '
                f'{state.get("terminal")}; Fire/terminal/replay remain native contract coverage')
            return predicate(state)
        return super().wait(label, checked, after, **kwargs)

    def run(self, url):
        self.deadline = time.monotonic() + self.budget
        for domain in ('Page', 'Runtime', 'Log'): self.cdp.command(f'{domain}.enable')
        navigation = self.cdp.command('Page.navigate', {'url': url})
        assert not navigation.get('errorText'), f'Navigation failed: {navigation}'
        envelope = self.wait('duel initial Zane turn', lambda s: s['phase'] == 'PLAYER_TURN' and bool(s['unit']) and not s['intro_visible'])
        initial = envelope['state']
        assert_duel_roster(initial, initial=True)
        assert_zane_profile(initial)
        assert_idle_selection(initial)
        self.checkpoint('zane-duel-actual-3d-loaded', envelope)
        self.click_button(envelope, 'move')
        moving = self.wait('duel legal one-step movement', lambda s: s['command'] == 'move' and bool(s['legal_moves']), after=initial['frame'])
        assert moving['state']['unit'] == initial['unit'], 'Move selection changed actor resources'
        destination = choose_duel_destination(moving['state'], moving['canvas'])
        self.cdp.click(*canvas_point(destination['point'], moving['state']['viewport'], moving['canvas']))
        moved = self.wait('duel movement settled', lambda s: s['unit'].get('moved') and not s['resolving'], after=moving['state']['frame'])
        assert_moved(initial, moved['state'], destination['position'])
        assert_duel_roster(moved['state'])
        self.checkpoint('zane-duel-3d-movement-completed', moved)
        self.click_button(moved, 'attack')
        targeting = self.wait('duel legal sword targeting', lambda s: s['command'] == 'attack', after=moved['state']['frame'])
        before = targeting['state']
        assert before['unit'] == moved['state']['unit'], 'Attack selection changed actor resources'
        target = duel_sword_target(before, targeting['canvas'])
        self.cdp.click(*canvas_point(target['point'], before['viewport'], targeting['canvas']))
        # Move+action ends the turn in the same coroutine as recovery. The
        # observer retains the actual synchronous turn_ended snapshot before
        # normal AI or Results can replace the active unit or scene.
        attacked = self.wait('duel completed sword observation', lambda s: bool(s.get('completed_sword')) and bool(s.get('sword_cleanup')), after=before['frame'])
        completed = attacked['state']['completed_sword']
        assert before['frame'] <= completed['frame'] <= attacked['state']['frame'], 'Completed sword evidence has impossible frame chronology'
        keys = {event['key'] for event in completed['zane']['events'] if event['kind'] == 'cue'
                and event.get('value') == 'sword_load' and event.get('actor_id') == 'zane'}
        assert len(keys) == 1, 'Expected one admitted Zane sword action key'
        self.coverage = assert_sword_result(before, completed, keys.pop(), attacked['state']['sword_cleanup'])
        self.coverage.update(title_entry='not exercised; production-helper QA bootstrap',
                             terminal_fire_replay='enemy AI/Fire/terminal/replay are native contract coverage, not this browser lane',
                             completion='read-only turn_ended costs/outcomes plus later original-owner cleanup; screenshot is subsequent live canvas')
        self.checkpoint('zane-duel-sword-outcome-and-cleanup', attacked)
        self.cdp.evaluate('true')
        assert not self.cdp.errors, 'Browser errors after duel sword exercise'
