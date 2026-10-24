# Ashvale first character art pass

Status: implementation candidate  
Branch: `feature/ashvale-first-character-art-pass`  
Base: `feature/forgotten-field-second-art-pass`

## Scope

This pilot adds one player silhouette and one enemy silhouette before expanding the roster. It validates 128 × 128 transparency, shared foot anchoring, browser-scale readability, manifest mapping, legacy fallback behavior, and Web export size.

## Accepted assets

| Gameplay ID | Art role | Pose | Runtime path |
|---|---|---|---|
| `zane` | Vanguard | idle | `res://assets/characters/character-vanguard-idle-v01.png` |
| `void_cultist` | Hollow Lancer | idle | `res://assets/characters/enemy-hollow-lancer-idle-v01.png` |

The art-role mapping is intentionally separate from gameplay names. No character IDs, display names, stats, abilities, or encounter data changed.

## Generation source

- `prompts/assets/characters/hero-squad-vanguard-arcanist-warden-wayfarer-v01.md`
- `prompts/assets/characters/enemy-pack-hollows-and-elites-v01.md`
- Built-in image generation mode, one transparent asset per call

The final prompts preserved the source packs and added implementation constraints: one character, three-quarter isometric view, bottom-center feet, weapon fully inside frame, transparent background, no floor or shadow, and readability at the runtime display height.

## Runtime wiring

- `godot/data/asset_manifest.json` maps current unit IDs to preferred art-role poses and legacy PNG fallbacks.
- `AssetRegistry.get_character_candidates()` resolves that data without hard-coding art roles into battle logic.
- `BattleScene` asks the registry for a preferred sprite, appends its existing legacy path when needed, and uses the shared fallback-safe texture loader.
- Unmapped units continue through the existing legacy sprite path and procedural colored-pillar fallback.

## Review gates

- Both assets are exact 128 × 128 transparent PNGs.
- Visible bounds stay inside the canvas and share the same vertical extent.
- The player and enemy silhouettes differ by stance, weapon, mass, palette, and face treatment.
- Missing preferred files must resolve to the legacy sprite without breaking battle startup.
- Normal-zoom browser capture must show both assets planted on their tiles with readable team indicators and HP bars.

## Risks and follow-up

- Fine armor and face detail will compress at battlefield scale. Silhouette and team markers must carry primary readability.
- Hollow Lancer is an art-production role temporarily mapped to the current Void Cultist gameplay ID. A later narrative/data migration should decide whether gameplay names adopt the Hollow taxonomy.
- Action frames remain deferred until idle placement, scale, and combat-preview behavior are accepted.
- The next character batch should add Arcanist and Hollow Cantor, then recheck overlap in dense formations before producing Warden, Wayfarer, and elites.
