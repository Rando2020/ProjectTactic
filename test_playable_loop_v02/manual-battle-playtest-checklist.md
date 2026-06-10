# The Appointed Playable Loop v0.2 Manual Battle Check

Use this after one Godot editor playthrough to decide whether the battle UI and telemetry targets need tuning.

## BattleUI Right Sidebar

- Enemy Intent: visible when enemies are planning, not crowding the active unit panel.
- Tile Info: readable on hover, not visually louder than commands or intent.
- Battle Readout: should fit as three compact lines:
  - `T / D / Taken / H`
  - `Boon / Terr / Haz`
  - `Close / Trig / Top`
- Forecast panel: appears at the bottom without covering command buttons.

## Results Screen

- Battle Readout should show all metrics without pushing Calling Progress/Revelation off the useful first screen.
- Top Boons should be readable at a glance.
- Tuning Notes should feel like designer feedback, not player-facing flavor.
- v0.2 Targets line should be small enough to read but not dominate the rewards.

## v0.2 First-Pass Targets

- Ideal battle length: 14 total turns or less.
- Slow battle: more than 18 total turns, or more than 9 player turns.
- Ideal player turns: 7 or less.
- Damage pressure: damage taken should usually stay below 70% of damage dealt, with a floor of 60.
- Boon triggers: 2 or more per fight should be the minimum for the build to feel alive.
- Terrain impact: 20 or more terrain damage, or 2 or more hazard triggers, means terrain mattered.

## After The Battle

Find the latest telemetry export at:

`C:\Users\jojo3\Coding\ProjectTactic\test_playable_loop_v02\last_battle_telemetry_report.txt`

Record:

- total turns:
- player turns:
- damage dealt:
- damage taken:
- healing used:
- boon triggers:
- top boon:
- terrain damage:
- hazard triggers:
- tuning notes:
- right sidebar crowded? yes/no:
- Results screen crowded? yes/no:
