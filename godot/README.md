# ProjectTactic — Godot 4

This folder contains the Godot 4 implementation of ProjectTactic.

## Opening the Project

1. Open Godot 4
2. Click **Import** → navigate to this `godot/` folder → select `project.godot`

## Folder Structure

```
godot/
├── project.godot          # Godot project file — open this
├── scripts/
│   ├── battle/            # BattleManager, TurnOrder
│   ├── grid/              # GridSystem, TacticalGrid
│   ├── units/             # Unit
│   ├── data/              # ItemData, MapData, TileData
│   └── systems/           # ElementalSystem, ObjectiveTracker
├── scenes/                # .tscn scene files (add here)
└── assets/                # Godot-specific assets (add here)
```

## Status

The React prototype (`../src/`) is the current source of truth for game logic.
Port systems to Godot in this order (see `../docs/` for specs):

1. GridSystem + TacticalGrid
2. TurnOrder (CT system)
3. BattleManager + Unit
4. ElementalSystem + damageFormula
5. ObjectiveTracker + MapData
