# Zane four-direction art review

Source-only review prototype, 2026-11-04. **Not accepted gameplay art.**

This standalone Godot 4 project compares the approved SE reference with SW, NE, and NW illustrated candidates. It does not change the game, replace the character atlas, or supply animation frames. The original PNG pixels are copied unchanged, not mirrored or programmatically edited.

## Run

Open `project.godot` with Godot 4.6 or run `godot --path .`. The top row shows enlarged art, the middle row shows 85-pixel visible silhouettes, and the bottom preview switches directions every 1.2 seconds. Light/dark backgrounds reveal transparency and edge readability.

Run validation: `godot --headless --path . --script tests/test_registration.gd`.

## Sources and status

- SE: approved original `zane-front.png` from `demos/isometric-2v2/prototypes/isometric/assets/`, SHA-256 recorded in registration.json.
- NE/NW: prior illustrated rear candidates recovered from the 2026-11-04 source catalog. Still unapproved.
- SW: new image-generation candidate using the approved original and the existing pose-guided pilot as references. A second targeted generation rotated torso and hips rather than merely turning the head. Still unapproved.
- All art remains 1254 x 1254 with alpha; SHA-256 source identity is tested.

The display normalization uses alpha >= 128 bounds and a manual horizontal foot-center estimate. The vertical comparison baseline is the lowest opaque pixel, **not a calibrated ground-plane pivot**. It is sufficient for review but must not be copied blindly into gameplay. The candidate acceptance flags remain false.

## Visual review

An independent inspection found the revised SW convincingly opposite-front: torso, hips, boots and head turn together, the large anatomical-left pauldron is nearer the viewer, and the sword stays in the farther anatomical-right hand. Identity is strong. Remaining issues are a slightly more side-on angle than SE, shorter/more horizontal sword projection, and small costume-detail drift.

The four directions are not approved as a consistent animation-ready production set. Exact boot-contact pivots, matched turn angles, silhouette scale, and costume consistency still need final visual acceptance. No animation or battle integration is claimed.

## Verification

- Godot 4.6.3 registration checks passed: four directions, original hashes/dimensions, no mirroring, candidate status gates, anchor and display-height arithmetic.
- Headless import and runtime smoke passed without script errors.
- Graphical Godot capture is blocked in this cloud environment: Xorg cannot create local listening sockets. Headless startup does not establish rendered/native-size visual acceptance. Review the project on a graphical Godot installation before promotion.

## Next acceptance gate

Review the four directions at actual game scale, calibrate both boot contact points and check directional switching, then explicitly approve or request targeted corrections. Only after approval should animation production or gameplay atlas replacement start.
