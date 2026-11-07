# Ashvale v03 chapel approach — NOVA handoff

Six new reusable GLBs plus one assembled scene. This environment art candidate supplements v02; it does not replace the character or production scenes.

| Asset | Use |
|---|---|
| AR_chapel_gate_4m | Focal gate spanning multiple tactical cells |
| AR_battered_buttress | Sloping support / vertical framing |
| EN_flagstone_2m | 2 m ground module |
| EN_twisted_ash_tree | Static dead tree with connected branch geometry |
| PR_crooked_lantern | Static post and emissive amber lamp |
| PR_splitwood_barricade | Timber cover visual |
| SC_chapel_approach | Assembled art-review scene |

Open this folder's project.godot and run. A/D orbit, W/S zoom. Preview is for visual inspection, without combat, movement, collision, navigation or destructibility. Source master and build script are in source/. Imported GLBs are Y-up, meters. Use your tactical grid for cover, heights and movement. Lantern point lights live in the preview, separately from the GLB's emissive material.

For Git checkout, use `git lfs pull --include="asset-candidates/ashvale-v03/**"` to retrieve this pack's binaries without unrelated legacy LFS files.

## Rebuild and verify

Use Blender 4.5.9 or verify API compatibility on another version:

```sh
blender --background --factory-startup --python source/build_chapel.py
blender --background --factory-startup --python source/verify_exports.py
blender --background --factory-startup --python source/review_roundtrip.py
godot --headless --path . --editor --import
godot --headless --path . --script res://godot-preview/verify.gd
```

Mesh QA requires the blender-asset-qa skill scripts. Set BLENDER_ASSET_QA_SCRIPTS if they are outside the default ~/.codex/skills/blender-asset-qa/scripts location. Review/ contains actual mesh renders, automated reports and limitations. Blender source has packed images. Build output is deterministic from the seed.

## Integration limits

Candidate silhouettes and materials still need art approval at the actual production camera. No LODs or collision proxies yet; scene performance is unprofiled. UVs deliberately reuse material space; a future unique normal bake requires a new UV layout. Vertex colors must be retained by the engine importer. Godot preview uses Compatibility rendering and was tested locally at 4.6.2; production-version validation remains required.

![Actual exported mesh review](review/roundtrip-materials.png)
