#!/usr/bin/env python3
"""Run bounded, isolated gameplay/presentation contracts without touching player data."""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# Scene harnesses initialize autoloads before compiling their dependent scripts.
CONTRACTS = [
    ('test_combat_formula.tscn', '0 fail'),
    ('test_combat_execution.tscn', '0 failures'),
    ('test_spell_outcome_feedback.tscn', '0 failures'),
    ('test_healing_contract.tscn', '0 failures'),
    ('test_hit_secondary_status.tscn', '0 failures'),
    ('test_turn_order.tscn', '0 failures'),
    ('test_progression_speed.tscn', '0 failures'),
    ('test_cancel_move_input.tscn', '0 failures'),
    ('test_silence_contract.tscn', '0 failures'),
    ('test_scout_tradeoff.tscn', '0 failures'),
    ('test_scout_outcome_integration.tscn', '0 failures'),
    ('test_tactical_contract_integration.tscn', '0 failures'),
    ('test_kael_presentation.tscn', '0 failures'),
    ('test_mira_presentation.tscn', '0 failures'),
    ('test_zane_presentation.tscn', '0 failures'),
    ('test_shared_rig_presentation.tscn', '0 failures'),
    ('test_terrain_cleanup.tscn', 'Terrain cleanup: 10 enable/redraw/disable cycles passed'),
    ('test_recovered_assets.gd', 'Recovered asset contract: OK'),
    ('test_ui_readability.gd', '0 failures'),
    ('test_playable_loop.tscn', '0 failures'),
]


def main() -> int:
    executable = sys.argv[1] if len(sys.argv) > 1 else 'godot'
    failed = False
    for fixture, success_marker in CONTRACTS:
        with tempfile.TemporaryDirectory(prefix='tactics-test-') as data:
            arguments = ['--script'] if fixture.endswith('.gd') else []
            command = [executable, '--headless', '--path', 'godot',
                       *arguments, 'res://tests/' + fixture]
            print('\n=== ' + fixture + ' ===', flush=True)
            try:
                result = subprocess.run(
                    command, cwd=Path(__file__).resolve().parents[1],
                    env={**os.environ, 'XDG_DATA_HOME': data,
                         'XDG_CONFIG_HOME': data, 'XDG_CACHE_HOME': data},
                    capture_output=True, text=True, timeout=120,
                )
            except subprocess.TimeoutExpired as error:
                for partial in (error.stdout, error.stderr):
                    if partial:
                        print(partial.decode(errors="replace") if isinstance(partial, bytes) else partial, flush=True)
                print('FAIL: contract exceeded the 120-second limit', flush=True)
                failed = True
                continue
            output = result.stdout + result.stderr
            print(output, flush=True)
            # Shutdown resource warnings remain visible, not silently suppressed.
            if result.returncode or 'SCRIPT ERROR:' in output or not re.search(r'(?<!\d)' + re.escape(success_marker), output):
                failed = True
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
