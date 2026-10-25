# Ashvale v04 — weathered chapel / NOVA handoff

This pack refines v03 and adds a torn banner, fallen masonry and alternate paving. Nine reusable static GLBs plus the assembled chapel scene. Import this version as a candidate; do not automatically substitute it into production scenes.

## What changed

- Painted limestone replaces pale, flat trim. Selected capstones have real cut-away edge damage.
- Timber and bark use a dedicated painted grain texture with grain-aligned UVs. Flat end faces use planar UVs.
- An alternate 2 m paving bond breaks the square pattern.
- Thick, folded oxblood banner has a torn hem and original diamond emblem. Cloth is static, with no simulated wind.
- Fallen stone clusters sit on a dark earth footprint for scenery placement.
- Gate shaft bases and shoulder bottoms overlap internally to avoid visible coplanar faces.

## Files

`models/` contains AR_chapel_gate_4m, AR_battered_buttress, EN_flagstone_2m, EN_flagstone_bond_2m, EN_twisted_ash_tree, EN_fallen_masonry, PR_crooked_lantern, PR_splitwood_barricade and PR_torn_ashvale_banner. SC_chapel_approach is the assembled review scene. Exact bounds and triangle counts are in asset-manifest.json.

`source/chapel-master.blend` is editable and contains packed images. `source/build_chapel.py` rebuilds the meshes and review scene. `textures/` retains generated slate, limestone and timber albedo. `review/` contains actual mesh renders, clean-reimport checks and validation notes.

## Retrieve and preview

```sh
git lfs pull --include="asset-candidates/ashvale-v04/**"
godot --path asset-candidates/ashvale-v04 --editor
```

Run this standalone project. A/D orbit; W/S zoom. Preview has lighting but no battle simulation, navigation, collisions or character control. The authoritative tactical grid remains responsible for movement and cover.

GLBs use meters and Y-up. Floors remain 2 m modules with thickness below the ground pivot. The gate spans approximately 4.2 m; it is multi-cell scenery, not a 2 m wall replacement. Lantern point lights belong to the preview scene; the GLB includes emissive panels only. Keep vertex colors enabled on import.

## Rebuild

Blender 4.5.9 was used. Run `blender --background --factory-startup --python source/build_chapel.py`, then source/verify_exports.py and source/review_roundtrip.py in the same way. Verification needs the blender-asset-qa skill; set BLENDER_ASSET_QA_SCRIPTS to its scripts directory if not installed under ~/.codex/skills. Godot checks: `godot --headless --path . --editor --import`, then `godot --headless --path . --script res://godot-preview/verify.gd`.

This remains a stylized art candidate. Repeated architecture, uniform broad wear, static cloth, missing LODs and unprofiled runtime cost remain production work. Inspect at the actual game's camera before approval; no claim of final Arcane / No Rest for the Wicked fidelity.

![Actual exported meshes](review/roundtrip-materials.png)
