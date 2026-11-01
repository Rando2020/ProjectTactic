# Combat Juice: Punchy Hits and Staged Spells

Presentation only. Nothing here changes damage, hit chance, turn order or grid
position. All numbers come from the authoritative resolved outcome.

## Where it lives

| Piece | File | Role |
|---|---|---|
| Recipes | `godot/scripts/vfx/ImpactJuice.gd` | Pure logic (RefCounted). Turns an outcome into tiers, timings, layouts. Headless-tested. |
| Hit executor | `godot/scripts/vfx/BattleJuiceEffects.gd` | White flash, sound, knockback, hitstop on live units. |
| Visuals | `godot/scripts/vfx/VFXManager.gd` | Directional sparks, spike path, finale cluster, cracks, shatter, linger. |
| Camera | `godot/scripts/battle/BattleScene.gd` | Shake and directional kick from `CombatResolver.impact_presented`. |
| Audio | `godot/assets/audio/battle_juice_v1/` | Authored by `tools/generate_battle_juice_audio.py` (stdlib, deterministic). |
| Tests | `godot/tests/test_impact_juice.tscn` | Recipe contract plus live resolver/VFX integration. |

## Punchy hit (5 beats)

1. **Flash**: target turns pure white for 2 to 5 frames (shader mix, not a tint).
2. **Sound**: `hit-whack` (melee), `hit-thwip` (arrows), element cue for spells. Pitch drops as tier rises, with small jitter so repeats don't sound copy-pasted. Crits layer a crack.
3. **Particles**: sparks and streaks blast out the far side of the target, in the hit direction.
4. **Knockback**: the sprite (never the grid position) shoves along the hit direction and springs back.
5. **Shake + freeze**: hitstop freezes the tree on the impact frame, then the camera shakes. Crits and KOs add a directional camera kick.

Tier comes from applied HP damage as a fraction of the target's max HP
(light / normal / heavy / critical), crits bump one tier, and any KO is the
**finisher**. Hitstop is capped at 140 ms so turns never drag.

## Staged spell (8 beats)

Lead-in (fits the existing 0.20 s anticipation + 0.22 s travel lifecycle):

1. **Charge**: motes gather into the casting hand.
2. **Spikes**: a line of spikes erupts from caster to target instead of one projectile.
3. **Grow**: each spike is bigger than the last, building toward the target.
4. **Fan out**: smaller side spikes tilt outward.

Finale at contact:

5. **Crack the floor**: jagged cracks radiate from the target, plus a seam back toward the caster.
6. **Big finish**: ground flash ring, then a large cluster encasing the target.
7. **Shatter**: every spike breaks into falling shards.
8. **Linger**: element atmosphere (snow, embers, static, motes, smoke) plus mist.

Every element shares one spike generator. Skins in `ImpactJuice.SPELL_SKINS`
set colour, width, edge jaggedness and linger type, so ice reads as crystal,
fire as flame tongues, thunder as jagged bolts, dark as thorns.

## Rules this code keeps

- **Global RNG is combat's.** Cosmetics use a private `RandomNumberGenerator` and fixed-seed particles. Tests assert the combat roll stream is unchanged.
- **Mechanical results stay clean.** The impact recipe is emitted on `impact_presented`, not added to the result dictionary, so scoped and unscoped outcomes stay identical.
- **Reduced motion** (`practice_session.reduced_zane_motion`) removes shake and knockback and halves hitstop. The flash stays.
- The Zane impact profile path (`feedback_owner`) is untouched and keeps owning its own presentation.

## Tuning knobs

- `ImpactJuice.HIT_TIERS`: flash frames, hitstop, shake, knockback, spark count/speed, pitch per tier.
- `ImpactJuice.TIER_HP_FRACTIONS`: where light/normal/heavy/critical begin.
- `ImpactJuice.SPELL_SKINS`: per-element look.
- `path_layout` / `cluster_layout` / `crack_layout`: spike sizes, counts and spacing.
