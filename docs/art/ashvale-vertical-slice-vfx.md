# Ashvale vertical-slice VFX polish

This pass makes the first Ashvale encounter read like a deliberate tactical diorama instead of a debug board. It is presentation-only: combat rules, pathing, AI, saves, rewards, jobs and run progression are unchanged.

## Files

- `godot/scripts/grid/CinematicTacticalGrid.gd`
  - Subclasses `TacticalGrid.gd`.
  - Keeps the existing grid authoritative.
  - Replaces large badge-heavy overlays with restrained color-coded fills and rims.
  - Move = cyan, attack = red, ability = violet, AoE = hot red, target lock = gold.
- `godot/scripts/battle/AshvaleBattlePresentation.gd`
  - Listens to existing BattleManager signals.
  - Adds turn focus pulses, movement traces, enemy-intent connectors, water glints and warm hazard/shrine glows.
  - Activates only on `ashvale_road_01`.
- `godot/scenes/Battle.tscn`
  - Mounts the presentation director.
  - Uses `CinematicTacticalGrid` while preserving the same BattleManager/UI structure.
- `tools/check_ashvale_visual_slice.py`
  - Protects the intended presentation contract in CI.

## Visual hierarchy

The slice follows this order:

1. Environment establishes the battlefield.
2. Unit sprites remain the strongest moving shapes.
3. Tactical state uses translucent color and thin rims rather than opaque debug carpets.
4. Persistent UI frames information at the edges.
5. Momentary VFX spike only when the player moves, commits an ability, or an enemy acts.

## Enemy intent

Enemy intent is represented in two places on purpose:

- the right-side intent cards explain the plan in text;
- the battlefield connector shows the relationship spatially.

The connector is deliberately low-opacity during player planning and becomes stronger when the enemy is actually acting. Lethal/high-danger plans use progressively warmer colors.

## Environment accents

This pass adds only subtle 2D accents above the 3D backdrop:

- shallow water gets quiet glints;
- shrine/burning tiles receive warm ground glow.

These accents do not modify terrain state or damage rules.

## Known placeholders

- Unit sprites remain the current isometric assets.
- The 3D Ashvale kit is still low-poly foundation geometry.
- Spell and physical hit VFX reuse the existing `VFXManager` and `BattleJuiceEffects` systems rather than adding duplicate effect stacks.

## Next evolution

After browser visual acceptance:

1. tune sprite scale/contact shadows against the 3D backdrop;
2. add authored ambient props and local-light cues to the 3D kit;
3. replace temporary portraits with final painted art using the stable asset paths from PR #55;
4. capture a reference screenshot and freeze the Ashvale visual bar before building biome two.
