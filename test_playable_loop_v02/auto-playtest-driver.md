# Auto Playtest Driver

Purpose: let Godot finish a battle without manual player input while still using the normal battle commands, enemy AI, combat resolver, and telemetry report.

Toggle options:
- BattleScene inspector: enable `auto_playtest_battle` and set `auto_playtest_speed`.
- Project setting: set `project_tactic/playtest/auto_battle=true`.
- Command line: launch the battle with `--auto-battle-playtest`; optionally add `--auto-battle-speed=3.0`.

Expected output:
- Battle log shows `Auto playtest driver: enabled`.
- `test_playable_loop_v02/last_battle_telemetry_report.txt` includes `Driver: auto playtest`.

Scope notes:
- This does not touch character directional art.
- The driver uses the existing player command flow: attack if useful, move toward a target, attack again if possible, otherwise wait.
