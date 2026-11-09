# Original Mira Vey v2 presentation prototype

**Frozen original prototype, not final production art.** Exact parent-approved builder asset: `prototype-mira-v2/mira_v2.glb`.

- GLB SHA-256: `980724d38ae5f9ad2e1e616ab58158c093d73f8c13673693a8bfe5e35ad12ddd` (926,200 bytes).
- Builder source reference: `prototype-mira-v2/mira_v2.blend`, SHA-256 `b424dde5f493a5e72023c5b8c561a68b970083b3b04ce264fff64b67d943f85a`.
- Construction source reference: `prototype-mira-v2/build_mira.py`, SHA-256 `1f7e54042e435b68a3e611c9765c5ead825737529a47d12799384c8e787de5df`.
- Shared original rig/action source: `prototype-animation-v2.1/kael_v2_1.blend`, SHA-256 `54858ef68e181d95b10812504f5095d0446d9544eecebc02c258f2a893fa0243`; frozen companion Kael GLB `c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117`.
- One sixteen-bone skeleton, one sixteen-bind skin, nine clips: idle/slash/thrust/heavy/cast/hit/recovery/walk/defeat. Original action keys, durations and bone names retained.
- Legacy socket names are intentional shared-rig contract names: `Kael_v2_cast_socket` on hand.L, `Kael_v2_weapon_socket` on hand.R (closed grimoire), empty `Kael_v2_shield_socket` retained. They do not change Mira's character identity.
- Two mesh nodes, 7,224 triangles, 22 material surfaces. No embedded/referenced image textures. This is not a two-draw-call claim.

Only the exact frozen GLB is included here, not mutable builder sources. Rebuilding is semantically equivalent but not guaranteed byte-identical; the frozen hash above is authoritative. Directory-local `.gitattributes` scopes raw Git storage to this one reviewed original prototype.

## Identity and provenance

Builder's `prototype-mira-v2/SOURCE_MANIFEST.md` records the unchanged project identity reference `refs/mira-idle.png` (SHA-256 `78ac6e9d29b92a3d16d64996a45754c97654d1d9157509748a2e49f8f0a2d75b`), recovered from art branch `art/hd2d-character-identity` at `4ac7282171b3b0584a0f54c82b7f452b248af693`, path `godot/assets/sprites/units/mira-hd2d-v01/mira-idle-01.png`. Dark high bun, navy/violet cowl, long split coat, ivory center, dark fitted armor/gold trim and carried book preserve the existing identity; no lore, story, job or stat changes are introduced.

Mira mesh/materials are new original procedural construction, not a recolor/extraction of Kael. No third-party model/texture/animation pack was acquired. The upstream project identity-reference authorship/licensing was not independently established; this documentation does not invent clearance for it.

## Runtime contract and limits

`MiraRigPresentation.gd` is a thin profile of `SharedRigPresentation.gd`, the same implementation used by the preserved Kael facade. Existing practice3D opt-in controls selection; missing/invalid imports retain the original sprite. All existing gameplay contact, movement, resources, save state and teardown authority remain outside the presentation.

- Preparation 0.20s → slash contact 15/24s, held before impact until authoritative contact.
- Cast release 21/24s is sampled immediately and held during existing projectile travel; actual hand.L socket is projected to canvas-global origin.
- Recovery 0.22s, hit reaction 0.24s, authored 1.0s walk modulo-sampled into existing 0.50s movement, no root motion.
- Authored 2.0s defeat sampled into 0.65s collapse then endpoint-clamped forever; Unit still owns fade/removal. Import loop flags are not relied on.
- Character-only 160px nearest profile; clean 192px/384px quality profiles; unchanged 138.24 canvas footprint and Unit foot anchor. UI/world/VFX are not downsampled here.

Builder's independent Godot lab (`prototype-mira-v2/godot-validation-lab/README.md`, `reports/SUMMARY.json`) verifies 1,277 samples at 96Hz, exact source bone traces and positive sampled floor clearance. Integration tests separately verify real import, phases, socket/VFX, cancellation, malformed-asset fallback and cleanup; see `docs/qa/shared-character-presentation.md`.

Known prototype limits: shared melee motions are compatibility proxies rather than bespoke Mira spell choreography; book stays closed. No cloth/self-collision/IK/blending/retargeting system. Existing fixed-duration grid movement can slide; no guaranteed screen-pixel locking or shimmer-free claim. Numerical/headless checks do not establish native visual acceptance; that review is separate.
