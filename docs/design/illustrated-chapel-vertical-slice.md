# Illustrated Chapel: playable 2.5D battle presentation slice

## Creative target

The approved painterly Zane art mock is the visual reference, especially its **bottom-left tactical battle**: raised and cracked masonry, silhouettes of ruined arches, muted slate/ochre stone, legible fighters on a height-aware grid, cool blue player selection, warm red enemy selection, and a compact dark-and-gold command menu.

The painterly portrait/combat-calculation panels remain a separate art integration (draft PR #83). The mockup is **not** treated as a screenshot of current gameplay or an animation atlas.

## Player entry

From the title screen select **Illustrated Chapel / Play 2.5D Battle**. This deliberately starts the existing **one-on-one Zane vs Storm Imp practice rules**, but with `practice_session.illustrated_chapel = true` and `rig3d` unset. The existing Ashvale full-party battle, Zane 3D showcase, and Zane duel are untouched.

No merge or live public deployment is implied by a green PR build. The entry will be available in a branch Web build after acceptance or on the canonical site only after an explicitly approved merge and deployment.

## Rendering and gameplay ownership

- `godot/scripts/battle/BattleScene.gd`: `_create_illustrated_chapel_map`, a distinct 10x8 map using existing real terrain IDs, height steps, line-of-sight blocking, and Zane/Storm Imp spawn coordinates.
- `godot/data/asset_manifest.json`: a `ruined-chapel` environment theme. Tile textures, columns, low walls, an arch and a torch use original standalone SVGs, with preserved tile fallbacks.
- `godot/assets/environments/ruined-chapel/`: 96x64 isometric terrain sprites and freestanding transparent architecture. No copyrighted assets or source-image fragments.
- `godot/scripts/grid/TacticalGrid.gd`: adds only four new valid prop keys. The existing tile-to-screen conversion, selection, height/range/collision, and painterly sprite fallbacks stay authoritative.
- `godot/scripts/battle/BattleUI.gd`: actual existing Move, Attack, Skills and Wait buttons are moved to a compact lower-left dock **only for this mode**. Their real callbacks, active-state disabling, keyboard shortcuts, cancel, and ability list still use the existing BattleManager.
- Fire forecast remains a contained charcoal-and-gold preview **without a full-screen red overlay**. Canonical HP before/after, hit chance, MP, secondary effects and conditional KO are not replaced by hardcoded concept statistics. The existing local 72x72 fire impact flash is not a screen-covering forecast.

## Scale and draw contract

Each walkable tile is still 96x48 screen pixels with 16 pixels of skirt; movement and clicks use the TacticalGrid logical center. Artwork stays behind units, cursor highlights, HP bars, and selection indicators. Ruined low walls are placed on wall-coded impassable cells so the illustration does not promise walkability through masonry. The middle tiles around (4,5) and (6,5) remain open.

## Quality gates

1. Run `python -m unittest discover -s tools -p test_illustrated_chapel_battle.py`; then import with Godot 4.6.3 and run `godot --headless --path godot --script res://tests/test_illustrated_chapel_art.gd`.
2. In a real browser, start the chapel from the title; verify only Zane and Storm Imp spawn, with 2D Zane, visible raised walls and blocked perimeter.
3. Check left-side menu Move, Attack, Skills, Wait; keyboard M/A/S/W, Escape/Q cancellation; enemy AI phase.
4. Inspect Fire forecast: compact dark panel; HP, MP, hit %, range, Burn and knock-out changes still sourced from actual forecast; only local, short-lived fire VFX changes tint.
5. Check 1280x720, 1366x768, 1600x900 and 3840x2160, including 150% text; no permanent field occlusion, clipped command text or damaged sprite readability.
6. Verify defeat/retry, win/result handling and refresh/Continue. Leave practice restores canonical save.

## Constraints and next pass

This first iteration is a playable **hand-authored stylized approximation** of the mockup, not the exact painted texture quality of that concept image. The large illustrated portrait, four consistent directional Zane PNGs and enemy portrait remain separate production-art tasks. The source mock contains false sample stat numbers and cannot be used as a texture atlas. Gradually replace SVGs with independently approved painted originals once browser alignment and interaction are verified.

This PR must remain separate from pending banner PR #82 and painterly Zane PR #83 until conflict/readability review. Do not archive or delete existing GLB models, Godot assets, source hashes, saves or deployments. Do not merge without approval.
