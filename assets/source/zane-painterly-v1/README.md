# Zane painterly v1 — local editable candidate

**Status: stable V4 engineering/art candidate for in-Godot evaluation; not an exact match to the concept or a claim of final visual approval.** Original sculpted geometry and an original deterministic painted atlas on the unchanged impact rig. Target illustrations are art direction, not model-output evidence.

Exported GLB SHA-256: `14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20`.

Measured budget: 9,229 triangles, 3 materials, 6 mesh surfaces, one embedded 1024×1024 atlas. All 16 bones/rests/inverse binds and 3 sockets match impact; every sample of all nine clips is exactly equal. Source 96Hz all-nine-clip floor test passes unchanged `-0.0001` tolerance. Minimum is 0.00093846; neutral stance boot clearance is 0.00799994 world units.

Draft V2 had a defeat floor intersection. V3 fixes that in garment skinning: broad graduated thigh-to-shin weighting lets the long coat fold at the existing knee rather than remain a rigid thigh slab. No bone, bind, socket, clip, timing or runtime change. The lower boot soles are rounded longitudinally so neutral contact is closer without exposing a pointed toe during the unchanged defeat roll.

Neutral offline Blender export renders and actual Godot captures are separate evidence. The actual texture's physical lighting/value response and game-scale readability remain under independent review. No concept image or generated picture is used as model evidence.

## Rebuild

```
python3 assets/source/zane-painterly-v1/paint_atlas.py
blender -b -t 2 --python assets/source/zane-painterly-v1/build_zane.py
python3 assets/source/zane-painterly-v1/validate_export.py --write-metadata
blender -b -t 4 --python assets/source/zane-painterly-v1/render_review.py
```

Source Blend contains the export skin, socket-attached sword, preserved project rig/actions and a hidden `AUTHORING | segmented sculpt and paint` collection with individually named editable construction meshes. Unhide that collection to edit components. Rejoin/export or rerun the deterministic builder to rebuild the export skin; component changes are not automatically linked into the export duplicate.

Atlas artwork is original code-authored broad pigment fields and directional strokes; no generated/concept pixels or external model meshes are included. Shared fabric/organic/metal materials give three opaque Principled materials and six surfaces total. UVs intentionally reuse eight bounded atlas tiles. `COLOR_0` contains broad directional value planes. No Blender-only shader is needed.

All sixteen bone definitions, inverse binds, three sockets and every sample of all nine clips match the immutable impact GLB. `changed_clips` in metadata is inherited terminology relative to original `zane_v2`; `motion_source` explicitly records all nine unchanged impact clips. Gameplay, timings and runtime scripts are outside this lane.

Original `zane-impact-v1` and `zane_v2` source/runtime assets are untouched. No remote writes or deployment.

## Editable preview/export and reproducibility

The saved Blend multiplies the original atlas by `PaintPlanes` exactly once, matching runtime `COLOR_0`. A fresh direct saved-Blend export using the builder's selection/export settings produced **byte-identical** frozen GLB. The source shader is not a paint-over or incompatible alternate setup.

The procedural builder is geometrically deterministic, but Blender 4.3.2 can reorder triangle index rows when joining construction meshes. A fresh complete build produced a different file hash with identical JSON, every vertex/normal/UV/color/weight/animation accessor, image bytes, and oriented triangle sets. `compare_rebuild.py frozen.glb rebuilt.glb` verifies this strict semantic equivalence. Do not claim fresh procedural builds necessarily reproduce the binary hash; use the documented saved Blend for byte-identical re-export, or regenerate metadata for fresh geometrically equivalent builds.

Exact new artifact paths are ordinary Git blobs through narrow `.gitattributes` exceptions; no unavailable legacy LFS object is needed for this handoff. Actual Godot-generated `.glb.import`, extracted atlas and atlas `.import` are included. Embedded and extracted atlas decode to identical pixels; source PNG is embedded verbatim in GLB. Import retains inherited 30fps/no-trim/no-RESET/named-skin settings. Full hashes and original-art provenance are in `provenance.json`.

Run `python3 assets/source/zane-painterly-v1/test_validate_export.py` to check that failed clearance writes explicit failure status and does not publish a new manifest. All original validators remain unchanged.

## V4 fixed-camera blade margin

V4 shortens only the exposed visual blade by 6cm (0.715m to 0.655m), leaving grip/guard, body mesh, materials, rig, motion, sockets, camera and logical gameplay reach unchanged. V3 remains frozen at commit `2872aa6` / GLB `1be0345f…99e57`, with its separate render evidence retained. Exact V4 GLB is `14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20`.

The actual exported V4 mesh has at least **0.06782178 world units / 2.92990090 display pixels** of fixed-camera margin across all nine clips and four cardinal facings at96Hz. `check_motion_clearance.py` pins the unchanged ortho3.2/pitch30/yaw45/target0.95 camera, floor tolerance and a >=0.05 world margin. Forty actual blade triangles show no sampled surface crossing against the deformed skin. These are sampled geometry checks, not continuous-collision or native-render certification.

The builder accepts `--output` and `--source-output` after Blender's `--` separator for safe scratch rebuilds without overwriting frozen delivery.

## Stable atlas import policy

This atlas alone uses explicit Lossless compression, mipmaps on, and automatic 3D compression switching disabled (`compress/mode=0`, `mipmaps/generate=true`, `detect_3d/compress_to=0`). This avoids a first native 3D use rewriting tracked import settings to platform-specific VRAM compression. Pixels, GLB and material graphs are unchanged. See [verified Godot4.6.3 semantics and tradeoff](import_policy.md).

## Actual 3D review evidence

`review/neutral-turnaround.png` shows front, three-quarter and rear. `review/game-camera-motion.png` shows walk/slash/cast/defeat extrema from the fixed gameplay projection. `review/face-detail.png` is the actual face close-up. `review/game-scale-138.png` is a rounded138px proxy for the138.24-local-pixel viewport; viewers may scale it.

`review/turntable.mp4` is a4-second real-model rotation:48rendered frames at12fps,512×512,H264. Stills use192Cycles samples; turntable uses64. Each turntable frame checks the evaluated model bounding boxes remain inside the frame. Decoded video was visually inspected at four quarter-turns; ffprobe verified48frames/4.0seconds. **All are actual offline renders of exactGLB14c74976, not gameplay captures or generated illustrations.** Full image/video hashes and per-frame view metadata are in `review/manifest.json`. No image-generation paint-over or artificial flame lighting was used.

To regenerate the turntable:

```sh
blender -b -t 4 --python assets/source/zane-painterly-v1/render_review.py -- --turntable-only --turntable-frames 48 --samples 64 --revision V4 --output /tmp/zane-turntable
ffmpeg -framerate 12 -i /tmp/zane-turntable/turntable_%03d.png -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart /tmp/zane-turntable.mp4
```
