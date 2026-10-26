# Act 1 tiles → 3D environment

This is a small integration prototype based on the user's existing Act 1 tile illustrations. Start here for their cream stone, lavender rock faces, ochre soil, olive grass and pink flowers. The older Ashvale chapel packs explore a different, darker palette.

The kit contains six GLB meshes, editable Blender source and generator, reference images, a 25-cell JSON layout, and a standalone Godot preview with an arrow-key test token and grid toggle. These are real meshes with backs and sides; the illustrations are visual references, not perspective images stretched over cubes. Dimensions, unseen backs and stairs are inferred. This is not final Arcane/No Rest for the Wicked fidelity: chipped silhouettes, painted surface detail, varied vegetation and better terrain blending remain art work.

## Run and review

Open this folder's `project.godot` in Godot 4.6, import, and run. Arrow keys move the gold test token; G toggles the overlay; A/D orbit. Red cells are blocked. The token snaps to cell centers; it is not a character controller. There is no combat, physics collision, action-point budget, pathfinding or animated stair traversal in this sandbox. `cover` and `move_cost` are example metadata, not combat implementation.

`source/.gdignore` deliberately prevents Godot from attempting to import the editable Blender file. Runtime imports use `models/*.glb` only. Review images are Blender renders, not screenshots of Godot.

## Integrate with ProjectTactic

1. Review this candidate independently before copying meshes into `godot/assets/3d/act1/`. Preserve the existing OBJ set until the replacement has been checked in the battle mock.
2. Adapt the mesh lookup in `godot/scripts/presentation/PracticeTerrain3D.gd` to instantiate these GLBs as PackedScenes. Map grass/grass_flowers to `grass_flowers`, stone to `stone`, and ruinblock to `ruin_wall`. `flower_clump` is a standalone decorative prop. Do not replace game state with the sandbox JSON.
3. Read terrain, elevation, occupancy and movement permissions from the existing TacticalGrid. Rendered meshes are presentation; neither flowers nor a visible wall should silently create gameplay rules. Route unit actions, targeting and cover through existing authority.
4. Resolve the vertical contract explicitly. This pack has 2 m cells, 1 m elevation, Y-up GLB, walking plane at local Y=0, with terrain thickness below zero. Existing PracticeTerrain3D uses MODEL_HEIGHT_STEP=0.82 and BASE_TILE_TOP_Y=0.26. To preserve that renderer, scale the new meshes vertically by 0.82 and add the base-plane offset 0.26. Keep unit/grid projection on those existing constants. Alternatively migrate all terrain, unit and cursor projection together to the 1 m contract; do not change just the mesh scale.
5. `high_ground` includes its 1 m rise in its geometry. For a cell at height h>=1, place its base at `(h-1)*height_step + base_offset`; flat tiles use `h*height_step + base_offset`. Do not add height to the high-ground mesh twice. `stairs` ascends toward local -Z in Godot and spans a 2 m cell from 0 to 1 m. Rotate it for other directions and provide explicit traversable edges from TacticalGrid.
6. Use the full 3D environment in the existing SubViewport presentation path first. The current Node2D unit sprites can remain layered over that view using consistent cell projection. Shared 3D depth/occlusion requires placing Sprite3D billboards in the same 3D viewport or implementing an explicit depth-compositing strategy; a Sprite2D over the viewport will not automatically disappear behind a wall.
7. Check terrain/units/cursor alignment at every elevation, sprite occlusion, camera readability, browser rendering and performance in the battle mock before making this a default. This pack does not modify production code.

The sandbox reserves whole wall cells as blocked and uses four-neighbor movement. Its stairs allow only north/south entry and require an explicit link to the upper cell. This is a small executable example of separating mesh geometry from navigation permissions, not a replacement movement specification.

## Asset and source contract

`manifest.json` lists mesh IDs, source references, triangle counts and dimensions. Source illustrations were copied from `preview/act1_tile_extraction/` in Rando2020/ProjectTactic. Their ownership/provenance is inherited from that repository; no additional rights are asserted. References are not embedded as GLB textures.

Vertex colors encode the palette in a standard glTF material. UV islands are intentionally stacked because these meshes use vertex colors, not unique baked textures; re-unwrap before baking textures. GLB vertices split at flat normals, UV and color seams. Ground extends below its surface pivot intentionally. Some touching hidden faces remain in the assembled block pieces; acceptable for this prototype, but remove in the optimization pass. Meshes are not collision hulls and have no LODs.

Generator: Blender 4.5.9 LTS, fixed seed 814, `source/build.py`. Automated export checks: `source/verify_exports.py` uses the installed blender-asset-qa skill. Grid checks: `godot --headless --path . --script res://verify.gd --quit-after 120` after editor import. Validation uses Godot 4.6.2 locally; production documentation names 4.6.3, so verify in that version too.
