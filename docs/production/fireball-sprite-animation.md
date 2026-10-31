# Fireball sprite animation

The user-approved original 16-frame pixel-art sheet lives at
`godot/assets/vfx/fireball-sequence-v1.png`. This is the actual RGBA PNG,
kept directly in Git so a clean checkout does not require LFS to load it.
It was generated with the built-in image tool for this project, not extracted
from Final Fantasy Tactics or another game.

`godot/scripts/vfx/FireballSprite.gd` maps its four columns and four rows to
clipped atlas regions. The source is 1443 by 1090, so integer edge coordinates
explicitly handle the uneven final column and alternating row sizes.
Nearest filtering preserves the pixel treatment. Flight pivots at the hot core;
charge and explosion pivot at the base. The effect never moves a unit.

## Playback

- ZaneActionPresentation: frames 0–3 charge at the live cast socket during the
  existing 0.20-second lead-in; frames 4–7 fly during the existing 0.22 seconds.
  The projectile rotates from its authored northeast direction toward the target.
- Successful damaging recipients: frames 8–15 play over 0.50 seconds at each
  affected recipient tile, within the existing maximum three-tile fan.
- VFXManager.play_fire uses the same impact sequence for unscoped Fire effects.
- Existing action owners still remove charge/projectile nodes on cancellation,
  and own the impact tail. The sprite also retires a completed impact itself.

Fire's MP, range, damage, fan, Burn rules, authoritative outcomes, audio, socket
tracking and reduced camera-motion preference remain controlled by existing code.
Misses and immune recipients do not receive a successful-hit explosion through
the scoped Zane presentation path. No full-screen color overlay is added.

## Remaining review

The source has some fine ember noise and approximate cell alignment. It is a
first integrated art pass, not a claim of final browser visual acceptance.
Check all four flight directions, multi-target readability and smoke fade in
the browser before merging. Character casting poses are existing animations,
not newly generated character sprites. The live demo changes only after the
normal merge and release workflow.
