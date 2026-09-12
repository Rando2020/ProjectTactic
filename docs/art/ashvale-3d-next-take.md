# Ashvale 3D Next Take

ProjectTactic is moving from debug-board presentation toward a hybrid tactical diorama: modular 3D environments with existing 2D/2.5D unit art and tactical overlays.

## Implemented in this branch

- A 22-piece Ashvale modular runtime kit under `godot/assets/3d/ashvale/`.
- Text OBJ runtime meshes with a shared muted tactical-diorama material palette.
- Canonical Blender procedural source at `source-art/blender/generate_ashvale_kit.py`.
- Fixed scale contract: one tactical tile is `2m x 2m`; one elevation step is `1m`.
- Authored `Ashvale3DBattleMock` with broken road, water crossing, bridge, raised enemy perch, ruins, props, warm/cool lighting, existing isometric unit sprites, and tactical markers.
- `Ashvale3DShowcase.tscn` now opens the authored battle mock instead of an asset gallery.
- Existing 2D production battle remains unchanged and available as fallback.

## Validation evidence

The first binary preview approach exposed a Git LFS mismatch and was removed rather than worked around. The runtime kit now uses text OBJ assets.

On the authored OBJ-based implementation:

- Terrain-art regression passed.
- Existing native integration checkpoints passed.
- Godot imported the project successfully.
- The actual game exported successfully for Web.
- A playable Web artifact was produced by GitHub Actions.

## Acceptance bar for the next branch

The next branch should connect this presentation to exactly one real playable Ashvale encounter behind an explicit feature flag. It must preserve the existing combat/grid/save lifecycle while replacing only presentation.

The playable scene should be strong enough to use as a public development screenshot. Height, traversable surfaces, player/enemy silhouettes, selected tiles, move range, attack range, and enemy intent must remain readable without debug labels.

## Scope guardrails

- Do not expand into full 3D character production.
- Do not change combat math, map semantics, saves, rewards, or encounter balance as part of the visual migration.
- Do not derive authoritative movement/collision from decorative mesh geometry.
- Preserve a one-switch fallback to the existing 2D battlefield until browser visual/performance acceptance passes.
