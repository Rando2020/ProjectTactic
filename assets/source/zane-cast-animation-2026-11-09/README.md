# Zane southeast cast animation candidate

Updated November 9, 2026. **Usable for local animation review, not accepted production art.**

## What changed from the first pack

Two additional authored in-between PNGs bridge idle → windup and windup → release. There are now five distinct SE poses: idle, lift, windup, extend and release. The recovery traverses the three intermediate poses in reverse. This is a deliberately stepped sprite animation, not interpolated smooth motion.

New deliverables:
- `animation/Zane-SE-Cast-Preview.mp4`: six-second review video, three repetitions, enlarged character plus an approximately 85-pixel-height reference. Clearly labeled as an animation export, not an engine capture.
- `animation/Zane-SE-Cast-Transparent.apng`: two-second looping animation, original 1254 × 1254 RGBA pixels, with idle pauses around the 760 ms cast.
- `zane-se-spriteframes.tres`: importable Godot SpriteFrames resource, with `idle-se` and non-looping `cast-se` animations.
- Updated Godot timing controller, eight-image standalone review project, local HTML playback page, reproducible animation builder and validation tests.

The four recovered facing images remain byte-identical to their source archive. All four newly generated cast PNGs are also unchanged from image-tool output. No source PNG is trimmed, mirrored, alpha-repaired, recolored, warped or otherwise edited. APNG export changes the container, not decoded pixels. The MP4 uses scaled display copies on a dark background for viewing only.

## Watch and run

Play `animation/Zane-SE-Cast-Preview.mp4` in a video player, or open `review.html` beside its bundled folders. The page contains native MP4 controls and transparent APNG playback. No external network service is needed.

Open `project.godot` in Godot 4.6, or run `godot --path .`.
- 1 / 2 / 3 / 4: SE / SW / NE / NW.
- Space: cast in SE.
- Escape: cancel.

Only SE has a cast animation. SW, NE and NW cast requests are deliberately rejected rather than using mismatched or mirrored art. Their sprites are static directional candidates, not idle animations.

## Exact cast timing

| Segment | Start | Duration |
|---|---:|---:|
| Lift | 0 ms | 80 ms |
| Windup | 80 ms | 120 ms |
| Extend | 200 ms | 80 ms |
| Release | 280 ms | 240 ms |
| Recovery extend | 520 ms | 80 ms |
| Recovery windup | 600 ms | 80 ms |
| Recovery lift | 680 ms | 80 ms |
| Idle resumes | 760 ms | Until next action |

The release presentation event occurs exactly once when time crosses 280 ms. It does not apply combat damage. The test clip holds idle for 600 ms before casting and 640 ms after casting, making each playback loop two seconds. The event therefore occurs at 880 ms within that loop.

The cast controller ignores repeated starts while active and locks facing until complete or cancelled. A negative delta does not advance time. A large delta still emits only one release event and finishes cleanly. Cancellation after the event does not retract an event already emitted.

## Godot integration

The included SpriteFrames resource uses a 50 fps timing grid and relative frame durations `[4,6,4,12,4,4,4]`, giving 760 ms total. Attach it to an AnimatedSprite2D in the standalone project to use it directly. It references `res://images/`; when moving into the game, move/remap those resource paths together.

Use a centered sprite with provisional offset `Vector2(-39, -491)` and uniform scale `0.079887218` for the SE reference's 85-pixel visible height. All SE cast frames use that SAME transform. The offset corresponds to the provisional boot midpoint `(666,1118)` in the original 1254-pixel source canvas.

For presentation synchronization, the release pose is frame index 3. Prefer the supplied CastState timing event if large frame deltas must be handled deterministically. Connect presentation to the game's existing authoritative action system; do not create a second damage application path.

No game scene, gameplay atlas, main branch or pending publication was modified by this pack.

## Honest QA status

Passed:
- Eight genuine 1254 × 1254 RGBA assets with unclipped visible alpha bounds.
- Four recovered source hashes matched; generated source copies unchanged.
- 60 Godot 4.6.3 checks: 22 action/state checks, 18 sequence/boundary checks, and 20 SpriteFrames/resource checks.
- Godot import without script errors and standalone scene smoke with all eight textures, one release and return to idle.
- APNG: 100/100 decoded RGBA frames exactly equal the intended source images, two seconds total, real transparency.
- MP4: 300 frames, six seconds, 1280 × 720; four encoded action phases extracted and visually inspected at enlarged and small scale.

Not established:
- Browser or graphical Godot playback inspection. Local display/browser socket restrictions remain unresolved and were not bypassed.
- Full battle integration, gameplay/FX synchronization, user visual acceptance or production readiness.
- Continuous smooth motion. Five distinct poses are held for deliberate timing; no optical-flow interpolation or crossfades disguise the frame count.

The generated in-betweens maintain coherent hand ownership, weapon position, face identity and planted stance. Read-only alpha matching in the boot region found one source pixel vertical drift for lift/windup/release and `(1,2)` pixels for extend, at most about 0.18 pixels combined at native game scale. Hair silhouette and small scarf/armor details vary slightly; these changes can produce visible shimmer at enlarged scale and need an actual playback decision. Numeric alignment checks are not aesthetic approval.

The source family for SW/NE/NW still has costume/angle differences. Additional facings, walking, melee, hit and defeat animations remain separate unfinished work.

## Reproduce checks and exports

Dependencies: Godot 4.6, Python with Pillow and NumPy; FFmpeg for animation exports.

```
python validate_assets.py
godot --headless --path . --editor --import
godot --headless --path . --script tests/test_cast.gd
godot --headless --path . --script tests/test_sequence.gd
godot --headless --path . --script tests/test_spriteframes.gd
godot --headless --path . -- --smoke
python build_animation.py
python tests/validate_animation.py
```

The animation builder uses direct source-file links for each timed frame, then FFmpeg encodes the sequence. Temporary sequence links are not required to view the supplied files.

## Provenance

Recovered sources: `Rando2020/ProjectTactic`, branch `assets/zane-ne-idle-correction-20261107`, folder `assets/source/zane-ne-idle-correction-2026-11-07`. PR #100 merged the earlier directional source archive without approving it as production art.

All four new cast poses were generated with the built-in image tool using the approved SE identity/stance and adjacent cast poses as references. Exact prompts are in `prompts/`. No third-party stock or new licensed material was added.
