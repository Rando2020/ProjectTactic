from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

battle_scene = (ROOT / "godot/scenes/Battle.tscn").read_text(encoding="utf-8")
cinematic_grid = (ROOT / "godot/scripts/grid/CinematicTacticalGrid.gd").read_text(encoding="utf-8")
presentation = (ROOT / "godot/scripts/battle/AshvaleBattlePresentation.gd").read_text(encoding="utf-8")
polished_ui = (ROOT / "godot/scripts/battle/PolishedCinematicBattleUI.gd").read_text(encoding="utf-8")

checks = {
    "battle scene uses cinematic grid": "CinematicTacticalGrid.gd" in battle_scene,
    "battle scene mounts Ashvale presentation director": "AshvaleBattlePresentation.gd" in battle_scene,
    "battle scene keeps polished cinematic UI": "PolishedCinematicBattleUI.gd" in battle_scene,
    "battle scene keeps 3D Ashvale backdrop": "Ashvale3DBackdrop.gd" in battle_scene,
    "move highlight uses restrained cyan palette": "MOVE_COLOR" in cinematic_grid and "0.42" in cinematic_grid,
    "attack highlight is distinct from movement": "ATTACK_COLOR" in cinematic_grid,
    "ability highlight is distinct from attack": "ABILITY_COLOR" in cinematic_grid,
    "cinematic grid removes text badge dependency": "_add_tile_badge" not in cinematic_grid,
    "presentation listens to enemy intent": "enemy_intent_changed.connect" in presentation,
    "presentation listens to movement": "unit_moved.connect" in presentation,
    "presentation listens to ability mode": "ability_mode_started.connect" in presentation,
    "intent telegraph uses actor and target ids": '"actor_id"' in presentation and '"target_id"' in presentation,
    "environment accents include water": "_add_water_glint" in presentation,
    "environment accents include warm ground glow": "_add_warm_ground_glow" in presentation,
    "Ashvale presentation removes duplicate unit labels": "_declutter_units" in presentation and "child is Label" in presentation,
    "Ashvale presentation preserves enemy HP readability": 'unit.team == "player"' in presentation and "rect.position.y <= -60.0" in presentation,
    "polished UI remains presentation-only subclass": 'extends "res://scripts/battle/CinematicBattleUI.gd"' in polished_ui,
}

failed = [name for name, passed in checks.items() if not passed]
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

if failed:
    raise SystemExit("Ashvale visual-slice contract failed: " + ", ".join(failed))

print("Ashvale visual-slice contract passed")
