# Combat System Specification

## Combat model
Vaelthar should use a CT-style tactical timeline instead of pure ATB for the tactics mode. Each unit accumulates charge based on speed. When charge reaches the threshold, the unit receives a turn.

## Core loop
1. Start battle.
2. Calculate turn order.
3. Active unit selects move, action, and facing.
4. Preview damage, range, hit chance, statuses, and terrain reactions.
5. Confirm action.
6. Resolve timing events if applicable.
7. Apply damage, armor stripping, statuses, terrain effects, reactions, and rewards.
8. Advance timeline.
9. Check objective completion.

## Damage preview
Before confirmation, show:
- Expected HP damage.
- Temper damage.
- Ether damage.
- Hit chance.
- Crit chance.
- Status chance.
- Terrain reaction chance.
- Back/side attack modifier.

## Temper and Ether
- Temper protects against physical pressure, knockdown, bleed, and direct body trauma.
- Ether protects against magic, silence, stun, curse, freeze, and Guardian corruption.
- Armor can be stripped separately from HP.
- Targets with depleted armor become vulnerable to bonus damage and higher status chance.

## SURGE timing
SURGE should become an optional action mastery prompt. Good timing improves output but should not make tactical planning irrelevant.

Recommended result tiers:
- Missed: base damage.
- Good: +15% damage or +10 armor strip.
- Perfect: +35% damage, +status chance, or combo extension.

## DEFLECT timing
DEFLECT is a reaction prompt for targeted units.

Recommended result tiers:
- Missed: full damage.
- Guard: reduce damage by 25%.
- Perfect: reduce damage by 50%, gain small CT refund, or counter with job-specific reaction.

## Resonance objectives
Guardian fights should include a tactical objective:
- Expose Void Anchor.
- Reach anchor tile.
- Protect Resonant unit while channeling.
- Use Resonance action before the boss enters Berserk.

## AI principles
Enemy AI should be readable and thematic, not omniscient.
- Bruisers pursue vulnerable targets.
- Casters prefer AoE and terrain combos.
- Guardians manipulate terrain.
- Void enemies pressure Ether and force positioning mistakes.
