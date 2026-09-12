# Ashvale 3D Terrain Kit v1

This kit is the first production-oriented 3D environment set for **The Appointed: As Above**.

## Direction

The battlefield should read like a hand-painted tactical diorama rather than a realistic 3D world. Geometry is intentionally chunky, low-poly, readable from an orthographic/isometric camera, and cheap enough for Godot Web.

## Scale contract

- Tactical tile: **2m x 2m**
- Elevation step: **1m**
- Character feet sit on tile top surface
- All pivots remain centered unless a prop needs a natural base pivot
- Godot imports use meters without compensating scale

Never change this scale ad hoc. Map generation, click projection, height rules, movement range, and sprite placement should depend on one shared conversion layer.

## Assets

The first kit contains 22 pieces: five surface types, raised/cliff/stair pieces, roads, bridge, two ruined wall forms, arch/pillar ruins, and six props.

## Source and export

 `source-art/blender/generate_ashvale_kit.py` is the editable procedural source. Run it in Blender with:

```bash
blender --background --python source-art/blender/generate_ashvale_kit.py
```

It exports individual `.glb` assets into `godot/assets/3d/ashvale/`.

The initial checked-in GLBs were generated headlessly from the same geometry contract because Blender is not available in the current automation environment. They are intentionally simple reference meshes and should be opened in Blender for the next art pass rather than treated as final sculpture.

## Godot integration strategy

Do **not** replace the working 2D battle renderer immediately. First use `godot/scenes/dev/Ashvale3DShowcase.tscn` to validate:

1. orthographic readability;
2. sprite contrast against 3D terrain;
3. elevation comprehension;
4. pointer-to-grid projection;
5. collision/navigation scale;
6. web frame time and draw calls;
7. lighting/material mood.

After approval, build a shared battlefield projection layer and move one playable Ashvale encounter to the hybrid 3D environment behind a feature flag.

## Style pass still needed

The generated meshes establish scale, silhouettes, modularity and performance. The next Blender art pass should add:

- irregular stone silhouettes and chipped corners;
- selective bevels and weighted normals;
- restrained hand-painted texture variation;
- moss/ash decals;
- stronger cliff side language;
- prop asymmetry;
- wind/burn variations;
- a small atlas instead of one material per primitive if web draw calls become excessive.

## Risks / guardrails

- Do not build fully rigged 3D characters as part of this terrain milestone.
- Do not make realistic PBR materials the target. The intended look is stylized and sprite-compatible.
- Do not let decorative meshes change tactical collision without matching map data.
- Do not make every tile unique. Reuse is a feature for procedural generation and memory footprint.
