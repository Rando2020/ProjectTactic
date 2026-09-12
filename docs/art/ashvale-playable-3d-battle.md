# Ashvale Playable 3D Battle Integration

This branch connects the modular Ashvale 3D environment kit to one real playable encounter without replacing ProjectTactic's working tactical systems.

## Scope

The integration is intentionally limited to the authored debug encounter with map id `ashvale_road_01`.

`Battle.tscn` mounts `Ashvale3DBackdrop.gd` as a presentation layer. The renderer waits until `BattleScene` has initialized the real `MapData` and `TacticalGrid`, then builds the 3D terrain only when:

- the backdrop node is enabled,
- the current map id is `ashvale_road_01`, and
- the game is not running through the headless test path.

All other battles continue using the existing presentation unchanged.

## Rendering architecture

The existing tactical grid remains authoritative for:

- tile coordinates,
- terrain semantics,
- logical height,
- movement and pathfinding,
- mouse input,
- targeting,
- move / attack / ability highlights,
- unit placement and animation,
- combat resolution,
- saves and rewards.

The 3D layer is presentation only.

The renderer creates a transparent 3D `SubViewport`, composes the Ashvale OBJ kit from the initialized map data, and exposes that viewport through a `Sprite2D` at z-index 500. Existing procedural terrain renders below it, while the tactical highlight and unit layers remain above it.

Because the rendered 3D board is represented as a normal 2D sprite after the one-time render, the existing `Camera2D` automatically pans and zooms terrain, units, and tactical overlays together. No second gameplay coordinate system is introduced.

## Isometric alignment

The 3D camera uses a 45-degree horizontal orientation and a 30-degree elevation. With the 2m tile contract, this produces the same 2:1 projection as the existing 96 x 48 tactical grid.

The terrain renderer derives its pixels-per-world scale from the live `TacticalGrid.tile_size` and compresses the kit's vertical dimension so one modeled elevation step projects to the grid's current `height_step` value.

This keeps raised terrain visually aligned with the existing targeting and unit coordinates while preserving the 3D kit's source scale for Blender work.

## Fallback

The `Ashvale3DBackdrop` node exposes an `enabled` flag in `Battle.tscn`. Setting it to `false` returns the encounter to the existing renderer without touching combat or map data.

The original 2D terrain is also still rendered underneath the transparent 3D texture. That gives the experiment a safe visual fallback if a mesh fails to import or a transparent region is exposed.

## Known limitations

- This first integration is static terrain. Runtime terrain mutation does not yet rebuild the 3D texture.
- Existing 2D height/debug labels may still be visible where the transparent 3D image does not cover them.
- Props are mapped conservatively from existing map prop data; they do not affect collision.
- The feature currently targets only Ashvale. Generated run floors and Crypt remain on the established renderer.
- The one-time 1024 x 768 3D render should be browser-friendly, but final acceptance still requires a real browser visual/performance pass.

## Next quality pass

After import, integration, and Web-export checks are green, the next visual pass should stay on this one encounter and improve screenshot quality rather than expanding scope. Priorities are:

1. tune projection and texture placement against real unit feet and tile highlights,
2. improve cliff / road / water transitions,
3. add stronger authored ruin and vegetation composition,
4. improve shadow softness and sprite-to-environment contrast,
5. remove visible legacy debug labels in 3D presentation mode,
6. validate move, attack, ability, and enemy-intent readability in browser play.
