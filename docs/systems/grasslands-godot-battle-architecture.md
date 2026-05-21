# Grasslands Godot Battle Architecture

## Purpose

This document resolves and supersedes the older PR #17 branch, which attempted to integrate a Grasslands Godot battle architecture against an earlier version of the repo.

Current `main` has moved substantially since that branch. The safest path is to preserve the useful architecture direction without overwriting newer Godot-first battle, roguelite, enemy intent, reward, and run-loop work.

## Current Main Reality

The current Godot implementation already includes many of the battle architecture goals from PR #17:

- Godot-first production direction.
- Battle scene and battle manager orchestration.
- Tactical grid rendering and tile interaction.
- CT-style turn flow.
- Ability targeting.
- Damage preview and battle UI feedback.
- Enemy intent handling.
- Run/roguelite services.
- Meta progression services.
- Procedural run/floor generation hooks.
- Boon, elite affix, wanderer, secret skill, and job progression service layers.
- Battle rewards flowing into run and meta systems.

## Why PR #17 Should Not Be Merged As-Is

PR #17 was useful, but it was based on an older repo state. A raw merge would risk:

- Reintroducing older assumptions about React/Godot ownership.
- Replacing newer Godot battle manager behavior.
- Reintroducing old battle UI assumptions.
- Conflicting with the current roguelite run-loop services.
- Reintroducing a reviewed bug where a missed physical ability could still apply its status effect.

## Preserved Direction From PR #17

The useful design intent remains valid:

- Add a readable Grasslands battle target.
- Test a larger encounter than the first small demo fight.
- Support terrain cost, height deltas, occupancy, jump limits, statuses, VFX, and objective resolution.
- Keep implementation original and clean-room.
- Use Godot as the production target.

## Grasslands Encounter Target

A future Grasslands implementation should be a mid-size tactical test map.

Recommended target:

```txt
Name: Grasslands First Fight
Map ID: grasslands_first_fight_01
Purpose: Open-field tactics test with ridges, roads, grass, water, and raider pressure
Party size: 4-5 player units
Enemy count: 4-5 enemies
Difficulty: early chapter / route floor 2-3
Objective: Defeat all enemies
```

## Tactical Test Goals

The Grasslands map should test:

- Larger party control.
- Height advantage.
- Open-field movement.
- Ranged pressure.
- Healing and support choices.
- Slow, poison, blind, haste, immobilize, and guard effects.
- Enemy melee pressure plus caster pressure.
- Whether battle UI remains readable with 9-10 units on the field.

## Recommended Implementation Branch

Use a fresh branch from current `main`:

```txt
feature/godot-grasslands-battle-map
```

Do not revive the old PR #17 branch directly.

## Recommended Files To Touch

```txt
godot/scripts/battle/BattleScene.gd
godot/scripts/data/AbilityDB.gd
godot/scripts/systems/GameState.gd
godot/scripts/ui/StageSelect.gd
godot/scripts/units/Unit.gd
```

Optional docs:

```txt
docs/systems/grasslands-godot-battle-architecture.md
```

## Implementation Rules

### BattleScene.gd

Add a third debug/editor map option only if it does not conflict with current procedural run map generation.

Recommended behavior:

```txt
0 = Ashvale
1 = Crypt
2 = Grasslands First Fight
```

Do not make Grasslands override active roguelite generated floors.

### AbilityDB.gd

Add support abilities and field-control abilities only if they align with current ability schema.

Candidate abilities:

- `rally_guard`
- `snare_vine`
- `field_medic`
- `volley_pin`
- `hook_lance`
- `poison_prick`
- `mire_hex`

### Unit.gd

Add effective movement helpers:

```gdscript
func get_effective_move() -> int:
    var base_move: int = unit_data.base_stats.move if unit_data else 4
    if has_status("immobilize") or has_status("petrify"):
        return 0
    if has_status("slow"):
        return max(1, base_move - 1)
    if has_status("haste"):
        return base_move + 1
    return base_move

func get_jump_limit() -> int:
    return unit_data.base_stats.jump if unit_data else 1
```

Then movement callers should use those helpers instead of raw `base_stats.move` and `base_stats.jump`.

### BattleManager.gd

When physical abilities miss, status effects must not apply.

Required rule:

```txt
Physical ability status effects only apply if the attack did not miss.
```

This resolves the Codex review issue from PR #17.

## Codex Prompt For Follow-Up

```txt
Create feature/godot-grasslands-battle-map from main. Add Grasslands First Fight as a third debug/editor Godot battle map without changing active roguelite procedural map behavior. Preserve current main battle manager and run-loop work. Add any needed abilities using the current AbilityDB schema. Add effective movement helpers to Unit.gd and update movement callers to use them. Ensure physical ability status effects only apply when the attack hits. Open a PR into main and do not merge.
```

## Resolution

PR #17 should be closed as superseded by current `main` and this handoff. The follow-up implementation should happen as a clean branch from current `main` to avoid stale merge conflicts.
