# Zane Painterly v1 Implementation Plan

> **For agentic workers:** Use the supplied native asset-building lane; parent coordinates integration and independent visual review.

**Goal:** Real editable reference-informed Zane model on the unchanged shipping rig.

**Architecture:** Load immutable impact-v1 Blend; replace visual mesh/equipment only; deterministically build sculpted surfaces and authored color atlas; export new GLB. Validate semantic rig/animation/socket identity and render only the exported asset.

**Tech Stack:** Blender 4.3.2 Python, Pillow for original texture artwork, existing GLB validator library, Godot 4.6.3 Compatibility integrator.

**Spec:** `docs/superpowers/specs/2026-10-25-zane-painterly-v1-design.md`.

## Global Constraints
Asset-only work. Original assets unchanged. Sixteen existing joints, nine exact clips and three exact sockets. <=24k triangles, <=8 materials, one 1024px color atlas. No external model/image source or installation. No runtime edits or remote writes.

## Review Focus
- Coat panel clipping during walking/slash/cast: inspect exported animation extrema.
- Rig rest/animation drift: compare every joint transform, bind and channel sample.
- Texture export loss: require embedded image and UVs/vertex colors, inspect imported GLB renders.
- Game scale value separation: render fixed 30-degree ortho camera and reduced footprint.
- Foot floor penetration and sword socket changes: inspect contacts and exact attachment transforms.

## Tasks
- [x] Record design, baseline hashes and output contract before building.
- [x] Build original face/hair/scarf/coat/armor/leather/sword geometry and authored color atlas in `build_zane.py` / `paint_atlas.py`.
- [x] Export `zane_painterly_v1.glb` and editable `zane_painterly_v1.blend` without modifying rig/actions/socket transforms.
- [x] Render exported GLB using `render_review.py`, send first contact sheet for visual critique, iterate important defects.
- [x] Run `validate_export.py`: exact rig/bind/socket/channel comparison; budgets, image/UV/vertex-color presence, finite geometry, weight sums, floor contacts.
- [x] Record provenance/rebuild commands/hashes in README and manifest; preserve all old assets; hand off isolated branch to parent.

## Verified outcome

V4 is a real editable first in-game art candidate, not an exact reference match. Frozen GLB SHA14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20;9,229triangles/3materials/6surfaces/one1024²atlas. Original rig/rest/binds/sockets and all nine clip samples remain exact. New floor/blade-surface/frustum checks pass; all original tests/assets stay unchanged. SavedBlend re-export is byte-exact; freshprocedural builds are geometrically deterministic but Blender may reorder triangle rows, checked bycompare_rebuild.py.

Independent source review concerns (failed-report status, exactguardstrength, sourcepreviewparity) were corrected and verified. A later native atlas auto-import rewrite was addressed with this atlas's explicit lossless+mipmapped/non-autodetect policy; actual native-use persistence belongs to the integration lane. Clean finaloffline stills and48-frame turntable are included separately from native game captures. No push, merge or deployment was performed.
