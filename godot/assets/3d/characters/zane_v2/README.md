# Original Zane v2 presentation prototype

**Frozen original prototype, not final production art or bespoke sword choreography.** Parent-approved source: `prototype-zane-v2/zane_v2.glb`.

- GLB SHA-256: `9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5` (960,764 bytes).
- Source reference: `prototype-zane-v2/zane_v2.blend`, SHA-256 `374b52c41275feeb45b1df49ad240fc2923de3d4be8636a74a054c0c925131af`.
- Construction reference: `prototype-zane-v2/build_zane.py`, SHA-256 `276696b68912613dc9a4c19f97b4e35372655a40f4d90f9095716f50e31348eb`.
- Original shared motion: `prototype-animation-v2.1/kael_v2_1.blend`, SHA-256 `54858ef68e181d95b10812504f5095d0446d9544eecebc02c258f2a893fa0243`; companion frozen Kael GLB `c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117`.
- Sixteen bones, one sixteen-bind skin, nine clips: idle/slash/thrust/heavy/cast/hit/recovery/walk/defeat. Original hierarchy/rest transforms/action keys/contact conventions remain unchanged.
- Legacy `Kael_v2_cast_socket`, `Kael_v2_weapon_socket`, `Kael_v2_shield_socket` names intentionally preserve shared-rig interoperability, not Kael's character identity. Straight sword is rigid equipment; free-hand casting remains available.
- 5,408 triangles, twelve mesh nodes, 29 material surfaces; no image textures. These counts are not GPU/draw-call measurements.

Only frozen GLB bytes are included here. Builder sources are references, not copied mutable dependencies. Semantic rebuild equivalence does not promise byte-identical serialization; the frozen hash is authoritative. A directory-local `.gitattributes` exception stores only this reviewed GLB as an ordinary Git blob.

## Existing identity reference

`godot/data/asset_manifest.json` maps Zane to the current `character-vanguard-idle-v01.png` visual; `docs/qa/ashvale-first-character-art-pass.md` records that art-role mapping without changing gameplay identity. Its brown swept hair/stubble, warm steel, pale layered cloth, slate-blue panels, charcoal mantle and straight sword are the visual authority. The conflicting old blond/blue fallback was not mixed in.

Builder `prototype-zane-v2/SOURCE_MANIFEST.md` and `reports/source_hashes.json` record the unchanged project references:
- Idle SHA-256 `2c0eff6638025117cc30e02519bfbe959d94cbec32bf18ed8619afb14f4dc214`.
- Anticipation SHA-256 `97c207deab1cd270475ac696ec23003fc07cba6e40c6857cd9cf5bcb597bcb54`.
- Contact SHA-256 `5933e6c1f0e98bbc79a980019fe39ac9915d121d7c836f91eb8064544fd4a368`.

Geometry/materials are original procedural construction, not a Kael/Mira mesh recolor. No third-party art was acquired. Existing reference rights remain the project's responsibility; this document does not establish new licensing clearance. No class, ability, story, balance or actor-id change is introduced.

## Unchanged runtime contract

`ZaneRigPresentation.gd` supplies only path/skin/socket defaults to the already-reviewed `SharedRigPresentation.gd`. The existing opt-in practice3D flag selects it; missing/invalid imports preserve the sprite. All phase sampling, contact authority, timers, projection, render settings, cleanup and saved-state behavior remain unchanged.

Preparation0.20s → slash contact15/24s; cast release21/24s; recovery0.22s; hit0.24s. Authored1.0s walk is explicitly modulo-sampled into existing0.50s grid movement with no root motion. Authored2.0s defeat reaches its endpoint in0.65s and stays clamped; Unit owns fade/removal. Character-only160px nearest and clean192/384 profiles preserve138.24 canvas footprint and the same foot anchor.

The independent builder lab reports1,277 dense clip samples,81 ordered transition probes and97 gait-phase starts with positive sampled floor clearance. **Its0.12s blend probes are asset-level evidence, not the runtime policy:** this unchanged presentation facade manually samples phases without adding a blend system. Shared actions remain generic compatibility proxies, not bespoke fencing or coordinated two-handed attacks. No cloth/IK/self-collision system, arbitrary-speed foot locking, shimmer-free rendering or native visual acceptance is claimed.

Runtime integration evidence: `docs/qa/zane-presentation-profile.md`. Builder evidence: `prototype-zane-v2/godot-validation-lab/README.md` and `reports/SUMMARY.json`.
