# Tactics Combat Core Architecture

## Purpose

This document defines the first FFT-inspired tactical combat foundation for ProjectTactic without copying proprietary source, formulas, assets, or UI files from any reference game.

The goal is to make the browser prototype feel like a real tactics RPG before more assets, towns, story, or animation polish are layered on top.

## Scope Added

The combat core now separates tactical rules from React screen rendering.

```text
src/game/systems/battle/
  battleReducer.js
  damagePreview.js
  movementRange.js
  turnOrder.js

src/game/components/
  DamagePreviewPanel.jsx
  TurnTimeline.jsx
```

Updated files:

```text
src/game/screens/BattleScreen.jsx
src/game/components/TacticalGrid.jsx
src/game/styles/gameShell.css
```

## Core Loop

```text
CT charges until a unit reaches action threshold
→ Active unit is selected
→ Player chooses Move, Attack, Ability, Item, or Wait
→ Movement uses Move and Jump stats
→ Attack selects a target and shows preview
→ Confirm resolves damage
→ Turn CT is reduced based on action economy
→ Enemy turns auto-resolve through placeholder AI
→ Objective state is checked
```

## Turn Order

`turnOrder.js` implements the first Charge Time model.

- Units become active at CT 100.
- Speed determines CT gain.
- Waiting preserves more CT than taking a full move-and-act turn.
- The timeline projects upcoming turns for player readability.

This is intentionally simple. It is a foundation for future cast times, delayed actions, haste, slow, reaction abilities, and timeline manipulation jobs.

## Movement Range

`movementRange.js` replaces adjacent-only movement with range-based movement.

Movement considers:

- Unit Move stat
- Unit Jump stat
- Terrain move cost
- Terrain blocking rules
- Occupied tiles
- Map bounds

Known limitation: path rendering exists as data but is not yet displayed as a drawn path.

## Damage Preview

`damagePreview.js` gives the player a tactical confirmation step before resolving attacks.

Preview includes:

- HP damage
- Temper break
- Facing label
- Hit chance placeholder
- Remaining HP
- KO projection

Known limitation: hit chance is currently 100 percent until evasion, reactions, equipment, statuses, and terrain modifiers are implemented.

## Battle Reducer

`battleReducer.js` is now the main tactical state transition layer.

It owns:

- Active unit
- Selected unit
- Active command
- Movement range
- Damage preview
- Target selection
- CT refresh
- Basic enemy turn behavior
- Battle log updates

React screens should call reducer actions rather than directly mutating battle rules.

## Current Placeholders

- Ability still logs a placeholder action.
- Item uses a placeholder heal and does not consume inventory.
- Enemy AI attacks adjacent targets or waits.
- Attacks are melee range only.
- Facing is displayed but not yet selected at end of Wait.
- Damage formula is original placeholder math and should be tuned later.
- No animation queue yet.
- No deployment screen yet.

## Next Evolution

1. Add pre-battle deployment using existing map deployment zones.
2. Add job ability data and ability targeting patterns.
3. Add end-turn facing selection.
4. Add enemy AI intent preview before enemy turns.
5. Add equipment and derived stat pipeline.
6. Add terrain defense and evasion modifiers to preview.
7. Add reaction/passive ability hooks.
8. Add animation queue and event log playback.

## Risk Notes

The combat core is still MVP code. It is intentionally small, but it now has the correct seams for a serious tactics prototype. Avoid adding more broad campaign systems until the Move, Act, Wait, enemy turn, objective, and results loop feels good.
