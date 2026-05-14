# Godot Tactics Architecture

This branch keeps the current GitHub `main` Godot implementation as the primary playable path.

## Core Runtime

- `godot/scripts/battle/BattleScene.gd` builds maps and spawns the demo units.
- `godot/scripts/battle/BattleManager.gd` owns turn flow, commands, enemy actions, objective checks, and battle logging.
- `godot/scripts/battle/CombatResolver.gd` resolves attacks, heals, spell damage, hit VFX, and defeat handling.
- `godot/scripts/grid/GridSystem.gd` owns map math, movement ranges, pathing, attack ranges, and line of sight.
- `godot/scripts/grid/TacticalGrid.gd` renders tiles, highlights, unit placement, and tile/unit clicks.
- `godot/scripts/units/Unit.gd` owns HP/MP, CT-facing state, movement, statuses, damage, healing, and turn lifecycle.
- `godot/scripts/data/AbilityDB.gd` is the current ability table.
- `godot/scripts/vfx/VFXManager.gd` is the autoloaded VFX singleton named `VFX`.

## Current Demo Target

The default Godot battle is now `Grasslands First Fight` via `BattleScene.map_index = 2`.

The encounter tests:

- five player-side units,
- five enemies,
- attack, spell, heal, support, control, poison, slow, silence, blind, haste, and immobilize,
- movement range with terrain cost, height deltas, occupancy, jump limits, and movement-affecting statuses,
- CT-based turn order,
- victory/defeat objective flow,
- VFX and battle log feedback.

## Clean-Room Direction

Project Tactic can study genre conventions from classic tactical RPGs, but all implementation should stay original:

- original character names and stats,
- original maps,
- original formulas,
- original art and VFX,
- original ability names and data.

Useful inspiration categories:

- height as a tactical advantage,
- readable movement and attack ranges,
- job/ability identity,
- status-driven enemy variety,
- environment-aware movement costs,
- compact battle UI with immediate feedback.

Do not copy proprietary tables, maps, scripts, dialogue, binaries, sprites, audio, or exact formulas.
