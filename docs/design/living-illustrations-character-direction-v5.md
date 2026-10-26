# Living Illustrations: ProjectTactic character art direction (V5 evaluation)

Status: proposed visual language; not a replacement for the existing rig or a claim of exact-reference likeness.

## Decision from the Zane studies

The user's Zane look-target triptych has usable painted front/rear three-quarter presentations, but is not an orthographic or animation-ready atlas. The local V4 experiment retained paint likeness on shallow front/rear surfaces but distorted it on the older V3 geometry. A local V5 four-facing comparison repeated that result: the two art-derived directions retained likeness, while side views rendered from the old V3 blockout visibly lost hair, face, cloth and armor identity. These locally generated V5 pictures are evidence of **what not to ship**, not production candidates.

Since the repository already contains the substantially stronger `zane_painterly_v1` actual 16-bone GLB, nine inherited animations and an opt-in duel route, **do not swap it out for flat artwork**.

## Visual identity

A grounded, painterly tactical miniature standing in a truly three-dimensional battlefield:

- Character silhouettes read at the existing 138.24-local-pixel footprint, with restrained metallic gold and rich navy/cream values.
- Painted surface treatment is authored in UV atlas, face/hair shapes and vertex value planes. Avoid screen-facing portrait cards except in close-up dialogue or explicitly bounded sprite fallback.
- Real 3D rig owns north/east/south/west facings and sword/Fire/hit/walk. No left/right mirrored art: sword and spell hands must stay anatomically consistent.
- Terrain is physical, with tile occupancy and elevation from existing combat logic. Presentation must not rewrite movement, damage, action markers, save files, or cast sockets.
- Character-specific "signature" comes from silhouette, material breakup, cloth shape, ink/brush edge treatment and spell feedback. A future optional post-process should be evaluated as a separate bounded experiment; do not enable it globally.

## Existing authoritative baseline

`assets/source/zane-painterly-v1/` and `godot/assets/3d/characters/zane_painterly_v1/` are the production asset and runtime directories. As documented in their current source README, V4 has 9,229 triangles, three materials, six surfaces, a 1024px atlas, 16 unchanged bones, three sockets and nine unchanged impact animations. Frozen candidate GLB digest: `14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20`. Treat that hash as a starting observation, not perpetual truth when a new approved art version is intentionally shipped. Read `docs/qa/painterly-duel-runtime-2026-10-25.md` and `docs/qa/painterly-release-gates.md` before any asset edits.

## Best-practice V6 implementation order

1. Capture the actual current Godot 4.6.3 Zane duel at four facings, Standard/High, plus walk/slash/Fire/hit. Record camera, footprint, model hash and selected renderer.
2. Grade proportion silhouette, face/hair mass, layered scarf, steel pauldron form, split-coat hem, boots and blade continuity at native battle scale. Use the V5 reference painting as an art target, never as rendered-model evidence.
3. In the editable Blender source, reshape highest-impact geometry first. Repaint atlas **on matching 3D topology**, then refine trim/weathering; prevent armor/sword intersections and coat floor penetration in defeat.
4. Export under a new versioned asset identifier with full provenance. Preserve exact rest/binds, 16 bones, 3 sockets, nine inherited clips and project action markers, unless a separately approved rig migration is undertaken.
5. Re-run original asset validation, motion clearance, imported Godot contracts, fallback probes and native/browser duel checks; capture actual final quality before approving art.
6. Open an independent art/runtime PR. Do not merge or publish on the basis of concept or offline illustration alone.

## Risks and non-goals

This document changes **no game behavior** and carries **no tested 4-direction Godot capture**. The V5 external study was generated from older local V3/V4 assets, not the checked-in rig; it is a visual feasibility experiment. It is not a reason to downgrade the current model. No global shaders, render profiles, gameplay values or live demo were changed.
