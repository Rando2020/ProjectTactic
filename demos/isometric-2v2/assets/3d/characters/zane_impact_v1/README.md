# Zane impact v1 — compatible presentation variant

Original local refinement of the established brown-hair / warm-steel / pale-cloth / slate-blue / charcoal Zane identity. This is one movement / sword / Fire presentation slice, not a new combat rig or a roster redesign.

- GLB SHA-256: `669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90` (960,748 bytes).
- Frozen `zane_v2` baseline: `9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5`. Its files are unchanged.
- Sixteen existing bones, exact names/order/parents/rest; numerically equivalent inverse binds and all three legacy sockets (tolerance1e-5).
- Exactly nine existing clip names/durations. Only `walk`, `slash`, `cast` keys differ; `idle`, `thrust`, `heavy`, `hit`, `recovery`, `defeat` remain semantically identical.
- No root motion, gameplay callbacks, new bones, runtime constraints, or gameplay authority. Facing remains glTF `+Z`.

## Visible changes

The pale torso has stronger chest-to-waist taper; greaves are narrower faceted planes; the sword shoulder and short charcoal mantle have an offset directional silhouette. Broad original palette blocks are refined rather than replaced with a blond fallback or textured noise.

Sword: feet remain planted while hips/shoulders oppose, with an outward-safe lifting arc, a high compressed load, and a decisive forward/downward diagonal cut. Cast: the free hand gathers close to the chest, extends forward across the silhouette, then recoils with the torso while the sword stays controlled to the side. Walk: longer alternating support strokes, raised returns, restrained torso counter-rotation, no translated root. All are presentation-only.

## Measured timing and gait

`presentation.json` is the authoritative machine-readable contract. Source markers are `(frame-1)/24`: slash10/16 and cast12/22/28. Runtime retains preparation0.20s / snap0.04s / travel0.22s / recovery0.22s; authoring does not retime gameplay.

Export-measured foot-origin stance excursion: step0.60845434 world units; full-cycle stride1.21690867. At unchanged camera.size3.2 / pitch30 / yaw45 / **local138.24px** display square:

- N/W: 21.27047610px per step.
- E/S: 20.33279232px per step.

These are not a guessed48px tile stride. Runtime must apply existing parent canvas scale to the local ruler, not change the138.24px asset footprint. Ideal distance-matched exported support-origin drift in64px/0.50s and192px/1.00s samples is1.18–1.33 local canvas pixels. This is **not IK foot locking**. The one-second cap still produces rapid cycling and visible raster/transition drift; native gameplay measurement remains required.

## Verification and provenance

Run `python3 tools/validate_zane_impact_asset.py`; its report checks actual GLB data, immutable baseline bytes, rig/binds/sockets, all nine durations, six frozen motion sets, markers, measured gait, and dense floor/socket sampling. Run `python3 -m unittest tools.test_zane_impact_asset -v` for corruption/rejection tests.

`assets/source/zane-impact-v1/` contains the editable source, original copied source scene and builder provenance, deterministic variant builder, separate action pass, and fresh-export render/clearance utilities. Rebuilding with Blender4.3.2 reproduced this GLB byte-for-byte locally; semantic equivalence is the portability guarantee.

Fresh GLB reimport clearance check: 1277 dense samples, no blade-edge/body-triangle crossings outside intentional right-hand grip, and positive minimum exported floor clearance0.00532244 world units across all nine clips. This does not claim complete self-collision/cloth simulation.

The `.glb.import` is source-controlled import **settings**, not an import cache, and retains the original profiles' default30fps animation import. As in the baseline, Godot resamples24fps source markers; synchronously queried imported sockets—not hard-coded raw-export positions—must launch effects. No `.godot/` cache or film is committed.

This variant GLB and its two editable `.blend` source files are stored as raw Git blobs under narrowly scoped `.gitattributes` exceptions. Their bytes match the reviewed asset hashes. Existing assets and their LFS policies are unchanged. Remote publication and clean-checkout verification remain separate integration gates; a local asset build does not establish either.
