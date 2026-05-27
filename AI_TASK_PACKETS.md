# AI Task Packets

ProjectTactic is now a **Godot-first tactical RPG / roguelite prototype**.

These packets are written for Codex, Claude Code, or any future coding agent working in this repository.

## Non-Negotiable Direction

Build new runtime features in Godot.

Do not add new React/JavaScript gameplay unless the user explicitly says the task is for the old browser prototype.

Reference-only paths:

```txt
src/
archive_react/
VaeltharChronicles.jsx
```

Primary implementation paths:

```txt
godot/
godot/scenes/
godot/scripts/
```

## Packet 1: Town Node System

Priority: Critical for run depth.

Goal:

Add town nodes to the Godot roguelite run loop so runs have recovery, investment, party pivots, and information choices.

Reference JS:

- `src/game/screens/TownScreen.jsx`
- `src/game/data/towns.js`

Godot target:

- `godot/scripts/roguelike/RunState.gd`
- `godot/scripts/roguelike/MapGenerator.gd`
- `godot/scripts/ui/StageSelect.gd`
- new UI scene/script only if StageSelect becomes too crowded

Initial town types:

- Sanctum: heal/revive/upgrade one boon.
- Armory: spend gold to improve one unit for the run.
- Tavern: swap or recruit a party member.
- Oracle: reveal/reroute upcoming nodes.
- Vault: bank one reward for meta-progression.

Do not:

- Implement this in React.
- Create new JS town screens.

## Packet 2: HP Carryover Between Floors

Priority: Critical for roguelite pressure.

Goal:

Make HP persist between floors so damage matters across the run.

Godot target:

- `godot/scripts/roguelike/RunState.gd`
- `godot/scripts/systems/GameState.gd`
- `godot/scripts/battle/BattleScene.gd`
- `godot/scripts/units/Unit.gd`

Rules:

- Surviving units keep post-battle HP.
- Defeated units remain wounded/disabled until revived by a node/item/effect.
- Give a small automatic post-battle recovery only if balance needs it.
- Start with HP only; do not carry MP/ether unless explicitly requested.

## Packet 3: Party Composition

Priority: Very High.

Goal:

Let the player choose or swap active units so runs differ by party makeup.

Reference JS:

- `src/game/components/PartyScreen.jsx`
- `src/game/data/party.js`
- `src/game/data/roster.js`

Godot target:

- `godot/scripts/ui/DeploymentScreen.gd`
- `godot/scripts/ui/StageSelect.gd`
- `godot/scripts/systems/GameState.gd`

First version:

- Choose active party before starting a run.
- Save chosen formation/loadout.
- Later, Tavern nodes can allow mid-run swaps.

## Packet 4: Wanderer Encounter Screen

Priority: High.

Goal:

Port the richer Wanderer interaction flow to Godot.

Reference JS:

- `src/game/screens/WandererScreen.jsx`
- `src/game/data/wanderers.js`

Existing Godot:

- `godot/scripts/roguelike/WandererData.gd`
- simple encounter handling in `godot/scripts/ui/StageSelect.gd`

Godot target:

- new `godot/scripts/ui/WandererScreen.gd` if warranted
- or a cleaner modal inside `StageSelect.gd`

Needs:

- dialogue
- accept/decline
- pay/challenge/free conditions
- reward preview
- secret skill reward support

## Packet 5: Mystery Events

Priority: High.

Goal:

Port the richer mystery event table and outcomes to Godot.

Reference JS:

- `src/game/data/mysteryEvents.js`

Existing Godot:

- `godot/scripts/roguelike/RunState.gd`
- `godot/scripts/ui/StageSelect.gd`

Events to port:

- Treasure Cache
- Blessed Shrine
- Guardian Gift
- Merchant Caravan
- Abandoned Camp
- Ancient Ruins
- Ambush
- Trap Corridor
- Curse Site
- Mimic Hoard

Do not:

- Add another JS event resolver.

## Packet 6: Options Screen

Priority: Medium.

Goal:

Make the title-screen Options button open real Godot settings.

Godot target:

- `godot/scripts/ui/StartScreen.gd`
- new `godot/scenes/OptionsScreen.tscn` if needed
- `godot/scripts/systems/AudioSettings.gd`

Initial controls:

- music volume
- FX volume
- fullscreen/windowed
- resolution display
- back to title

## Packet 7: Dedicated Loot Claim Screen

Priority: Medium.

Goal:

Move post-battle loot from a simple overlay into a polished Godot claim screen.

Reference JS:

- `src/game/screens/LootScreen.jsx`

Existing Godot:

- `godot/scripts/roguelike/LootSystem.gd`
- `godot/scripts/ui/InventoryScreen.gd`
- loot overlay in `godot/scripts/ui/StageSelect.gd`

First version:

- show gold
- show equipment drops
- show rarity and affixes
- claim and continue to run map

## Packet 8: Terrain Identity Cards

Priority: Medium-High.

Goal:

Make terrain tactically readable through hover/inspect cards.

Godot target:

- `godot/scripts/grid/TacticalGrid.gd`
- `godot/scripts/battle/BattleUI.gd`
- `godot/scripts/data/TileData.gd`

Card should show:

- tile name
- move cost
- elevation
- cover
- line of sight
- elemental/surface state
- special effect

Design notes:

- Battle card should be compact.
- Codex card can be larger and more ornate.
- Tile data should help both player UI and AI valuation.

## Standard Validation

Run after Godot changes:

```cmd
tools\check_godot_stability.cmd --skip-godot
```

If feasible:

```cmd
tools\check_godot_stability.cmd
```

The full command may report the known Godot headless signal 11 crash. That is not a parse failure if the static pass already succeeded.
