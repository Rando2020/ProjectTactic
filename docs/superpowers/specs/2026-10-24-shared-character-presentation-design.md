# Shared original-character presentation

## Intent and boundary
Reuse Kael's reviewed presentation-only rig adapter for original Mira without duplicating behavior. Work is isolated from final integration `90cd78195eb000d8a0fa71a631d276c1753f7e15`; live/current/public PR72 stay untouched. Mira binary inclusion is gated on an authoritative builder freeze and SHA-256.

## Approaches
- **A — approved:** extract the existing implementation to `SharedRigPresentation.gd`; retain `KaelRigPresentation.gd` as a thin compatibility wrapper and add `MiraRigPresentation.gd` as a second thin profile. This preserves Kael's entry point and public constants/defaults.
- B — replace the Kael adapter path with a parameterized class. Fewer files, but breaks the reviewed facade/class-path contract for no needed benefit.

## Design
The shared base owns exactly the current phase sampling, node discovery, viewport construction, rendering controls, facing, and projected socket facade. Its only character-specific configuration is model asset path, skin id, and cast socket name. Kael wrapper retains `MODEL_PATH` and initializes the original defaults. Mira wrapper supplies the final frozen path and confirmed socket. Shared timing/constants remain public through inheritance; no configurable phase timings or new behavior.

After asset freeze, Unit's existing factory selects the imported wrapper for Kael or Mira and retains Humanoid3D for zane/void_cultist. Its supported-archetype list adds Mira; existing practice flag, render settings, archetype alias behavior, sprite fallback, attach/detach ownership, and saved state remain unchanged.

## Invariants / anti-goals
No animation callbacks into gameplay. Unit, TacticalGrid, VFX and ActionLifecycle remain contact/resource/movement/cleanup authority. Keep exact 0.20/0.22/0.24/0.50/0.65-second sampling, 15/24 contact and 21/24 cast release; optional walk/defeat fallback; 138.24 canvas footprint; 160/192/384 render profiles and fixed feet anchor. No unrelated refactor, blend system, retargeting, new graphics capability, gameplay/stat/story change, GUI access, remote write, or deployment.

## Verification
Run original Kael real-scene suite unchanged. In a separate real-scene regression test load an immutable copy of the original adapter from the base commit and compare it against the new Kael wrapper for every facade phase, all bone poses, clip time, facing, projected feet/socket, and render profile. This independently catches extraction mistakes rather than comparing two wrappers of the same new implementation. New tests must fail before the implementation exists. After freeze, validate exact Mira source hash and sixteen bones/nine clips, real Unit routing, transitions, synchronous socket/VFX behavior, cancellation, optional/malformed scenes, sprite fallback, unchanged gameplay state, and repeated disable/free cleanup. Headless tests do not replace the separate native visual review.
