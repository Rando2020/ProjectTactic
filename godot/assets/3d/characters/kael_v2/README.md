# Original Kael v2.1 presentation prototype

Original in-house stylized geometry and animations, not third-party character art. Frozen builder source: `prototype-animation-v2.1/kael_v2_1.glb`. The runtime filename remains `kael_v2.glb` to preserve the facade path.

- **SHA-256:** `c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117`
- Godot 4.6.3: one 16-bone skeleton, one 16-bind skin, nine clips.
- Clips: idle/slash/thrust/heavy/cast/hit/recovery/walk/defeat.
- Sockets: Kael_v2_weapon_socket / Kael_v2_cast_socket / Kael_v2_shield_socket.
- Model front is +Z after import; feet/rest origin Y=0; skin height approximately 1.867m.
- Builder verified original seven action control keys/interpolation/timing unchanged. New walk is1.0s in-place; defeat is2.0s non-looping. Lower garment weights were corrected for crouching.

## Runtime contract

`KaelRigPresentation.gd` maps existing gameplay phases to authored samples. Animation never applies damage, spends resources or advances combat. The grid remains movement authority; no root motion is consumed. Casting projects the actual animated socket immediately after release sampling, including Unit parent scale.

- Preparation0.20s → authored slash contact0.625s (held just before impact until permitted).
- Recovery0.22s → remainder of attack. Cast release0.875s is held during existing projectile travel.
- Walk1.0s source cycle → existing0.50s visual move; modulo sampling explicitly loops, independently of import flags.
- Defeat2.0s source →0.65s collapse; clamp exact final frame indefinitely. Unit still owns its existing fade/removal (~0.83s). Never queue idle when defeated.
- Older seven-clip variants safely retain idle movement/fade-only death, but are not represented as authored locomotion.

The independent engine import observed ~0.000356m maximum bone translation settling between defeat1.75s and2.0s, despite the exact held Blender keys (~0.015 baseline canvas pixels). Runtime endpoint clamping is explicitly tested and does not rely on importer hold interpolation.

## Visual scope and limitations

This is an evaluated motion/art-direction replacement, not final production art. Rigid per-bone weighting, joint/cloth intersections, hand grips and transition polish remain. Gait playback follows the existing fixed-duration move, not distance-based stride matching: long moves can slide. No locomotion blending, foot IK, cloth simulation or arbitrary retargeting is claimed.

The default **character-only** pixel profile uses a160×160 transparent viewport with nearest output. Clean mode uses192×192 (384 high quality). Both preserve the prior138.24 canvas footprint. High quality changes MSAA without changing the pixel grid. This is NOT a whole-world pixel renderer: terrain, UI and VFX retain their existing rendering. Fractional Unit scale and camera zoom can still produce pixel crawl; no shimmer-free or integer-screen-grid claim. Godot lighting may not exactly match Blender review renders.

The GLB is an ordinary Git blob via directory-local `.gitattributes`, so this original prototype does not depend on missing legacy LFS objects or a remote upload.
