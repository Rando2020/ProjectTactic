# JS to Godot Migration Backlog

The React/Vite code is now a historical prototype and design reference. This backlog tracks which ideas still need a proper Godot implementation.

## Migration Policy

Build in Godot first.

Use JavaScript files only to understand:

- old UI flow
- data shapes
- naming
- prototype behavior
- design intent

Do not add new runtime features to `src/game/` unless explicitly requested.

## Status Summary

| Feature Area | React Source | Godot Status | Priority |
|---|---|---|---|
| Battle grid/combat | `BattleScreen.jsx`, battle components | Mostly ported through `BattleScene.gd`, `BattleManager.gd`, `CombatFormula.gd`, `TacticalGrid.gd` | Maintain |
| Combat forecast | `BattleForecastHud.jsx`, `DamageForecast.jsx` | Mostly ported through `ForecastCalculator.gd`, `BattleUI.gd` | Maintain |
| Deployment | `DeploymentScreen.jsx`, `deployment.js` | Ported through `DeploymentScreen.gd` and formation flow | Maintain |
| Run map | `RunMapScreen.jsx`, `floorGenerator.js` | Ported through `StageSelect.gd`, `RunState.gd`, `MapGenerator.gd`; still needs polish | High |
| Towns | `TownScreen.jsx`, `towns.js` | Not fully ported; needs town-node system | Critical |
| Party composition | `PartyScreen.jsx`, `party.js`, `roster.js` | Not fully ported; deployment uses fixed roster/formation | Very High |
| Wanderers | `WandererScreen.jsx`, `wanderers.js` | Data/simple encounter exists; richer screen not ported | High |
| Mystery events | `mysteryEvents.js` | Simple mystery resolution exists; full event table not ported | High |
| Loot claim | `LootScreen.jsx`, `lootSystem.js` | Loot generation exists; polished claim screen not ported | Medium |
| Character sheet/job tree | `CharacterSheetScreen.jsx`, `JobTreeScreen.jsx` | Godot character screen exists; some UI detail still missing | Medium |
| Options/settings | `SettingsPanel.jsx`, `settings.js` | Audio settings exist; title Options screen not implemented | Medium |
| Story/quest/archive | `StoryScene.jsx`, `QuestLog.jsx`, `SummonArchive.jsx`, story data | Codex/dialogue partial; full systems not ported | Later |

## Highest-Value Godot Ports

### 1. Town Node System

Reason:

Runs need meaningful non-combat choices before increasing run length.

Godot implementation target:

- Add town node types to run generation.
- Build or reuse a Godot UI for town choices.
- Start with Sanctum and Armory.
- Add Tavern after party composition exists.

### 2. HP Carryover

Reason:

Healing and defensive decisions do not matter enough if every floor resets the party.

Godot implementation target:

- Persist unit HP in run state.
- Apply carried HP when spawning units.
- Save wounded/defeated state after battle.
- Add recovery through Sanctum/Infirmary/town effects.

### 3. Party Composition

Reason:

Fixed party makes runs feel similar. Even "choose 3 of 4" creates meaningful variation.

Godot implementation target:

- Choose active party before starting a run.
- Save active party into run state.
- Deployment uses the selected party.
- Tavern can later swap units mid-run.

### 4. Wanderer Encounter Screen

Reason:

Wanderers are a strong identity system but currently only lightly represented in Godot.

Godot implementation target:

- Dedicated encounter UI or StageSelect modal.
- Condition preview.
- Payment/challenge/free reward outcomes.
- Secret skill support.

### 5. Mystery Events

Reason:

Mystery nodes currently have less variety than the React prototype.

Godot implementation target:

- Port event table from `mysteryEvents.js`.
- Resolve rewards, penalties, ambushes, shops, and shrines.
- Keep outcomes readable in run map UI.

### 6. Options Screen

Reason:

The new title screen has an Options button, but no screen behind it yet.

Godot implementation target:

- Add settings UI using `AudioSettings.gd`.
- Support music and FX volume.
- Add fullscreen/windowed toggle.
- Return to title.

## Reference-Only JS Files

These are useful to read, but should not receive new runtime work:

```txt
src/game/screens/TownScreen.jsx
src/game/screens/RunMapScreen.jsx
src/game/screens/WandererScreen.jsx
src/game/screens/LootScreen.jsx
src/game/screens/CharacterSheetScreen.jsx
src/game/screens/JobTreeScreen.jsx
src/game/components/PartyScreen.jsx
src/game/components/SettingsPanel.jsx
src/game/data/mysteryEvents.js
src/game/data/towns.js
src/game/data/wanderers.js
src/game/data/progression.js
```

## Agent Checklist

Before implementing a feature:

1. Identify the matching Godot script/scene target.
2. Read the React file only as reference.
3. Implement in GDScript/Godot.
4. Run `tools\check_godot_stability.cmd --skip-godot`.
5. Do not create new React runtime code.
