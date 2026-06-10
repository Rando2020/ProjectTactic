# The Appointed Playable Loop v0.2 Telemetry Tuning

This is the current tuning target sheet for the playable-loop battle test.

## Current Targets

- Ideal battle length: 14 total turns or less.
- Slow battle warning: more than 18 total turns.
- Ideal player turns: 7 or less.
- Slow player-turn warning: more than 9 player turns.
- Damage pressure: damage taken should usually stay below 70% of damage dealt, with a floor of 60.
- Boon trigger floor: 2 or more boon triggers after 7 player turns or 120 damage dealt.
- Terrain impact: 20 or more terrain damage, or 2 or more hazard triggers.
- Close-call pressure: 2 or more close calls means the fight may be too punishing.

## Readout Files

After reloading Godot scripts and starting a battle, BattleManager should write:

- `C:\Users\jojo3\Coding\ProjectTactic\test_playable_loop_v02\last_battle_telemetry_report.txt`

The text report is the playtest artifact. The actual tuning logic lives in Godot code.

## First Tuning Rule

Do not tune thresholds from a missing export. Tune only after a completed battle produces turns, damage, boon, and terrain values.

## Next Pass Questions

- Did the fight end in 14 turns or less?
- Did the player take more than 70% of dealt damage?
- Did at least 2 boons trigger after the fight had enough sample time?
- Did terrain create at least 20 damage or 2 hazard triggers?
- Did the right sidebar feel crowded during combat?
- Did the Results screen feel crowded after battle?
