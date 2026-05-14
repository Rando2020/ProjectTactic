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

The Godot battle scene is now the primary playable tactics prototype.

Current default battle:

- `Grasslands First Fight`
- five player units
- five enemies
- CT turn order
- movement, attacks, abilities, healing, support, status effects, VFX, and objective resolution

The React prototype remains useful for fast UI/gameplay experimentation, but Godot is where the battle loop should be hardened.
