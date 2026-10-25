# Zane painterly v1 design

## Intent and authority
Create a real editable character model close to the user's approved painterly 3D-look target. The user delegated creative control while preserving story/gameplay; this is an asset-only lane. The two actual reference PNGs were visually inspected before modeling and hash-verified: 3D target `c71ac9abfe9e6f338b466b24cdaab1c0ff34cd9af5a6e8cbe237782b01e6b943`; concept `a0462180d4eab98caf1196da06eba692aced3f6b28ef3ccf0ae4975e69225c0d`. They are design targets, not renders of our model.

## Approach
Rebuild the visual mesh over the immutable impact-v1 rig rather than merely recolor the old model, or replace the rig with a film-style sculpt. A new rig would risk movement/sword/Fire timing and is rejected. Recoloring would not deliver the target silhouette and is rejected. Native Blender geometry, an authored painted atlas and broad vertex-color planes give editable, exportable dimensional forms without external mesh dependencies. This is the builder's implementation choice under delegated art direction.

## Visual decisions
Angular clean-shaven face; substantial swept pointed brown hair; thick folded cream scarf; navy fitted long split coat with cream inset and lining; layered bevelled steel pauldrons, bracers and knees; restrained brass edgework; leather crossing straps/belt/boots; straight diamond-section sword. Preserve original Zane palette/identity and existing bone positions. Readable silhouette, face/hair mass, coat layering and game-scale value separation precede ornament.

## Contract
- New source: `assets/source/zane-painterly-v1/`; new runtime: `godot/assets/3d/characters/zane_painterly_v1/`.
- Original assets remain byte-for-byte unchanged.
- Exactly 16 existing joints, same rest and inverse binds; nine animation clips with identical channels, keys and durations; three same socket transforms and ancestry.
- Target <=24,000 triangles, <=8 glTF materials, one 1024px painted color atlas, no custom runtime shader, standard opaque glTF PBR compatible with Godot Compatibility.
- Coats follow existing thigh bones; armor follows relevant rigid limb segments. No new cloth simulation or skeleton changes.
- No runtime/battle/UI edits, no remote writes, deployment, third-party meshes, paid services, credentials or installations.

## Evidence
Deliver builder, editable Blend, textured exported GLB, asset metadata/hashes, rig/clip/socket comparison and geometry budget. Render the exported GLB (not the source scene) front/three-quarter/rear, the actual orthographic gameplay projection, and walk/slash/cast poses. Label render evidence offline 3D, not game capture. Parent integrator handles final game capture and independent critique.
