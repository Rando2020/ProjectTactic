# Blooming Ruins — isolated local integration

Launch with Godot 4.6.3:

```sh
godot --path demos/isometric-2v2 res://prototypes/blooming/BloomingBattle.tscn
```

This is an opt-in 2v2 scene, not the default title scene or a live release. It reuses the v11 combat, abilities, damage, costs, turn queue, player commands, save-isolated practice lifecycle and audio. The PR96 independent Encounter/3v3 logic is not imported.

## Presentation
- Fixed orthographic textured 3D terrain rendered into the existing 2D tactical canvas, with separately depth-sorted painted cutouts and existing Sprite2D actors.
- Art source: ProjectTactic PR96 head `8d5284e239f7573715bd507de21bf45f5896bc20`. All five source PNG hashes verified against manifest; original art preserved.
- Twelve by eleven logical cells; four-height landing; two two-cell-wide stair lanes. Each logical stair tile has three physical decorative treads, nine per flight. Cell centers match the actual center tread height; picking and highlights follow all physical top surfaces.
- New native HUD preserves actual Skills/forecasts and has a collapsible tester/intent rail. Q/E reports the fixed-view boundary rather than rotating this scene.
- Allied compact sprites have four authored views. Enemies preserve the inherited static art and logical facing; no new enemy direction sheets or walk animation are claimed.
- Known-unit readability conservatively fades painted cutouts when their rectangle overlaps a unit head. It is not pixel-perfect occlusion or fog-of-war.

## Scoped navigation correction
A Blooming-only BattleManager subclass ranks advancing moves by legal terrain path cost, avoiding the base AI's Manhattan local minimum above the retaining wall. It retains the existing move budget, occupancy, jump/height costs and retreat behavior. The original BattleManager is unchanged.

## Integration seams
Only two existing files change: BattleUI gains an overridable selection-controller factory; ResultsScreen chooses this scene for replay only when `practice_session.blooming_ruins` is true. All other production changes are new files/assets in this opt-in integration.

## Evidence and boundaries
Tests include geometry/projection/picking, real move/Fire once, both enemy AI turns, win/loss replay, save isolation, skin changes, fixed-view input, HUD layout and compiled-pack loading. Actual desktop engine capture shows selection, movement, Skills, forecast, cast/travel/impact/decay and enemy response. MovieMaker records actual engine PCM; no post-dub. Physical phone/browser and human listening are not verified. Existing v11 audio is deliberately retained; the separate recorded Fireball V4 candidate is not enabled.

Run individual test scenes under `tests/blooming`, `tests/blooming_hud`, and `tests/blooming_capture`. Capture scene uses normal simulation timing and actual combat/UI methods; `-- --capture-dir=/absolute/path` saves PNGs and evidence JSON. Use a real display for images (headless is only diagnostics).

This local work does not merge PR96, modify main, publish a Site, replace the current live demo, or add Haste/idle animation mechanics.
