# Ashvale 3D Next Take

This branch is moving ProjectTactic from debug-board presentation toward a hybrid tactical diorama: modular 3D environments with existing 2D/2.5D unit art and tactical overlays.

## Immediate goals

- Check in each Ashvale modular terrain asset under `godot/assets/3d/ashvale/`.
- Keep the kit small enough to remain ordinary Git on this path despite the repo-wide LFS defaults.
- Author one hand-composed Ashvale battlefield before expanding procedural generation.
- Layer existing isometric character/enemy sprites into the 3D scene.
- Add readable selected, move, and attack markers.
- Validate Godot import and Web export before replacing any production battle renderer.

## Acceptance bar

The authored scene should be strong enough to use as a public development screenshot. Height, traversable surfaces, player/enemy silhouettes, and tactical overlays must be readable without relying on debug labels.

## Scope guardrails

This remains an isolated presentation experiment. It does not change battle rules, grid data, collision semantics, saves, rewards, or encounter balance. Existing 2D terrain remains the fallback until the 3D presentation passes browser visual and performance validation.
