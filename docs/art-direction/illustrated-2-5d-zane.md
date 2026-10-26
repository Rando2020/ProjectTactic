# ProjectTactic painterly 2.5D: Zane first-character slice

## Approved visual target and scope

Use the approved **Zane hybrid 2D / illustration** presentation mock as the art direction: warm painterly faces, swept brown hair, cream scarf, long navy/slate-blue coat, worn leather, muted bronze/gold accents, legible isometric miniatures, illustrated action-forecast portraits, and compact HUD that does not obscure the arena.

**Do not treat the concept collage as a sprite atlas.** Its tiny figures were illustrative mockups, not validated production animation frames, and the pasted mock's sample HP/hit/damage numbers are not gameplay facts. The current game's authoritative combat, forecast and saves remain unchanged.

## Runtime asset contract

- `godot/data/asset_manifest.json -> characters.zane.portrait`: production-painted **portrait** for battle preview, active unit and CharacterScreen; fallback: existing `character-vanguard-idle-v01.png`
- `characters.zane.directions.front/right/back/left`: independent **transparent, foot-aligned** in-battle sprites. The four Godot facings are S/E/N/W respectively.
- `AssetRegistry.get_character_portrait_candidates(id)` and `get_character_direction_candidates(id, facing)`: optional art resolution; all paths are checked before use, never a runtime HTTP dependency.
- `Unit._character_direction_texture` and `_refresh_directional_sprite`: Zane alone uses the directional images in 2D; other units, melee timing, 3D opt-in, shadow, HP bars, input, and grid coordinates remain unchanged.
- `CharacterScreen._unit_texture`, `BattleUI._on_turn_started`, and `BattleManager._portrait_path`: painterly portraits are resolved independently of sprites. Forecast uses actual on-disk path to support the existing PNG-byte reader.

The new preferred PNG paths are placeholders until actual approved isolated source images are committed. **This code pass wires the fallbacks, not the final visual asset quality.** Existing `zane_v2`, `zane_impact_v1`, and `zane_painterly_v1` remain preserved in their current paths.

## Required source files / acceptance before promotion

| File | Native content | Acceptance |
| --- | --- | --- |
| `godot/assets/characters/portraits/zane-portrait-illustrated.png` | Clean illustrated upper-body portrait, no UI/text/background other than authored backdrop | Must match approved face, expressive identity, costume; 4K UI legibility |
| `godot/assets/sprites/units/zane-front-illustrated.png` | 1 full-body transparent sprite facing camera | Correct feet, silhouette, coat, scarf, neutral idle |
| `godot/assets/sprites/units/zane-right-illustrated.png` | 1 full-body transparent sprite facing screen right | Correct anatomical sides |
| `godot/assets/sprites/units/zane-back-illustrated.png` | 1 full-body transparent sprite facing away | Scarf drape and back straps consistent |
| `godot/assets/sprites/units/zane-left-illustrated.png` | 1 full-body transparent sprite facing screen left | No unintended mirror of asymmetrical armor |

1. Generate or hand-separate the source artwork into standalone originals. Verify alpha, four real directions, identical feet baseline, no typography, color and volume agreement, and licensing/provenance.
2. Validate in **real** Godot headless + browser (movement facing, cursor/selection alignment, attacking, Zane Fire AoE, secondary effects, 37→0 forecast, status screen, 1280/1366/1600/3840 resolutions). Test 150% UI text scale.
3. Confirm unchanged combat numbers, turn order, input, cancel, enemy intent, result/boon and refresh/Continue.
4. Only after browser acceptance may old **candidate models** move to a documented archive in a distinct PR. **Do not delete or relocate active `.glb` assets, their rigs, importer files, or documented reference hashes here.** Optional 3D prototype comparisons remain available until then.

## Known risks / tech debt

- Current concept-sheet poses are not compatible frame-perfect sprite animations. First pass is static directional art; movement animation requires controlled 2D puppet/keyframes or verified rendered takes.
- The status screen currently scales its broader UI aggressively; portrait source resolution should be rechecked at 4K instead of merely upscaling a small concept crop.
- PR #82 separately improves compact attacker/defender action banners; integrating it later may require a bounded rebase and visual review. This PR only uses existing targeting preview and does not silently import its pending changes.
- Directional sprite proportions need pixel-perfect screen-space verification with the feet anchor and HP-label offsets, especially when importing non-square PNGs.
- New preferred asset paths may be absent. Such assets must never render LFS pointers or empty texture placeholders in place of existing working sprite/portrait fallbacks.

## Recommended next action

Deliver and QA the **five clean individual production PNGs** on a new art-only PR, then perform browser acceptance of one Zane versus Storm Imp encounter before any 3D archiving or merge.
