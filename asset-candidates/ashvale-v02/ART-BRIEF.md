# Ashvale: first mesh asset family

Status: authored candidate pack, not approved production art. User delegated prompt writing and production decisions. Deliver actual editable meshes and portable GLB exports, with an independent preview for NOVA.

## Direction
Arcane-inspired angular planes and deliberate color separation; No Rest for the Wicked-inspired weight, exaggerated silhouettes and worn construction. Original designs, no extracted game assets. Slate shadows, warm grey stone, oxblood cloth, dark steel and aged brass. Broad surfaces and chipped silhouettes take priority over tiny noise. Actual directional light remains dynamic.

## Technical contract
Source: ProjectTactic main `godot/assets/3d/ashvale/README.md`, fetched during this task. Tactical tile = 2 m; elevation = 1 m. Blender sources are Z-up; GLB export converts to Y-up. Grid logic remains authoritative. Modular origins are centered in XY at the nominal ground surface; floor slabs extend below it. Character height is an inferred 1.9 m. Orthographic 40–50 degree review camera.

Local checkouts appear older than remote; this package is separate from NOVA's working files. No current rig integration contract was available. Character bone and clip names are provisional, requiring explicit mapping on integration.

## First batch
Two floor variants; full and broken wall; pillar; 1 m stairs; archway; banner; brazier; rubble; sword; Zane armored rig prototype. A composed courtyard and an independent Godot preview accompany individual models. Character is a stylized armored silhouette prototype, not a final likeness or detailed facial sculpt.

## Authored decisions and inferred dimensions
2 m wall spans, 0.4 m wall thickness, 2.4 m full wall height, 3.2 m arch height. Five 0.2 m stair risers. Character exaggerated shoulder armor and layered ember cloth. Concealed face/helmet for the first rigid-armor rig prototype; this differs from the earlier uncovered-face illustration. All back surfaces are authored interpretations. No quantitative likeness claim is made against the earlier perspective image.

## Production prompts
Environment: Build original modular ruined courtyard meshes at the stated dimensions. Use large bevels, asymmetric chips on outer edges, broad slate paint, sparse aged brass inlays and oxblood cloth. Keep tile tops level, stairs consistent and arch passage open. Export independent assets with UVs and readable pivots.

Character: Build a 1.9 m armored vanguard prototype with broad shoulders, narrow waist, planted boots, layered angular steel, oxblood mantle and segmented garment. Use a named humanoid skeleton and in-place idle, walk and attack clips. Export a skin, not a static posed illustration. Record the limitations of rigid armor weights and the lack of fine face/hand articulation.

Stone texture (built-in ImageGen): Seamless square flat base-color swatch of weathered grey slate; broad painterly blue-grey and warm-grey mineral patches, sparse ochre flecks, low contrast, no masonry grid, perspective, cast shadow, text or directional lighting. Actual generation prompt is represented by this production brief. Edge seamlessness is not assumed; apply UV regions within image edges for this first kit.

Steel texture (built-in ImageGen): Flat dark blue-grey worn steel base-color swatch, broad angular painted marks, midnight slate base, medium blue-grey scumbled strokes, rare warm charcoal. No photographic scratches, baked highlights, lighting gradients, rivets, seams, text or borders. Mapped onto real 3D armor.

## Acceptance
Inspect real mesh renders; check scale, UVs, nonzero geometry, triangle budgets, skeleton, clip names and round-trip import. Godot import/playback verification is separate from Blender checks. Mark unresolved visual, deformation and runtime issues in the handoff. No automatic merge or deployment.
