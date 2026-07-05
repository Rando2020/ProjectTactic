# JSON data model foundation

ProjectTactic should use JSON as the canonical content and balance layer for the browser prototype. Game systems should remain in JavaScript or TypeScript, while towns, missions, jobs, abilities, party members, maps, assets, rewards, story progress, and save shape should be represented as structured data.

## Why this matters

The current prototype has useful structured data, but much of it is still embedded in JavaScript modules. That is fast for early iteration, but it makes balancing, tool support, Codex edits, Godot experiments, and future save migration harder.

The data model added in this branch is intentionally additive. It does not replace current imports yet. The working prototype should continue to run while the team validates the JSON contracts.

## Current foundation files

| File | Purpose |
| --- | --- |
| `src/game/data/json/missions.json` | Mission metadata, objectives, rewards, unlocks, map references, and formation references. |
| `src/game/data/json/towns.json` | Town metadata, services, NPC references, map position, and mission references. |
| `src/game/data/json/jobs.json` | Job progression data, unlock requirements, growth modifiers, ability references, and ascension links. |
| `src/game/data/json/abilities.json` | Ability metadata, targeting, costs, tags, animation IDs, and audio IDs. |
| `src/game/data/json/party-members.json` | Party member identity, starting stats, portraits, sprites, traits, and story hooks. |
| `src/game/data/json/maps/ashvale-null-drake.map.json` | Initial tactical map contract for isometric grid, tile metadata, deployment zones, camera, and asset references. |
| `src/game/data/json/asset-manifest.json` | Asset lookup table for UI, tilesets, and battle sprite sets. |

## Data ownership rule

Use JSON for content, configuration, and balance values.

Use JavaScript or TypeScript for logic, validation, pathfinding, AI behavior, rendering, and UI state.

Use localStorage JSON only for player save state.

## ID naming rules

Use lowercase snake case for data IDs.

Examples:

- `ashvale_null_drake`
- `mirefen_reaction_trial`
- `stormglass_deflect_trial`
- `sunder_strike`
- `ruined_garden_shrine_tileset`

Use lowercase kebab case for asset filenames.

Examples:

- `zane-front-left.png`
- `main-menu-button-selected.png`
- `ruined-garden-shrine-tileset.png`

## Recommended migration path

### Phase 1: Add JSON beside existing data

Status: started in this branch.

Do not remove current JavaScript modules yet. The JSON files should serve as the content contract for future work.

### Phase 2: Add data loaders

Create small loader modules that import JSON and expose the same helper functions the current JavaScript files expose.

Examples:

- `getMission(missionId)`
- `getTown(townId)`
- `getJob(jobId)`
- `getPartyMember(characterId)`

### Phase 3: Add validation

Add schema validation or lightweight runtime validation before using content in save migration or tactical screens.

Validation should check:

- Missing IDs
- Duplicate IDs
- Missing references
- Invalid unlock requirements
- Invalid map dimensions
- Invalid asset references

### Phase 4: Replace JavaScript data modules

Once loaders and validation are in place, replace the current hand-authored JavaScript data modules with JSON-backed helpers.

### Phase 5: Expand ability data

The next systems pass should convert ability summaries into structured effect blocks once the resolver is ready.

## Best practice

Build toward a data-driven tactical RPG where content designers can add missions, jobs, abilities, maps, and encounter content without editing core systems.

## Pragmatic workaround

Keep the current JavaScript data files running until the JSON loader layer is added. This avoids breaking the playable prototype while improving architecture.

## Risk

The JSON files are not wired into the runtime yet. They are architecture foundation files, not active game behavior.

The map file includes only a partial tile list to establish the format. It must be expanded before replacing tactical map data.

## Next recommended action

Create a follow-up branch that adds JSON loader utilities and imports `missions.json` into the current mission screen without changing gameplay behavior.
