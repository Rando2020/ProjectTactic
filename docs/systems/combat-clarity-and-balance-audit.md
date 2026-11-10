# Combat clarity and balance audit — 2026-11-01

Baseline inspected: `5941987ff4e295a8037e8d36e25b2938fa0f0966` (main).
User authorized independent implementation of math and UI/UX improvements.
This is an incremental battle-clarity pass, not a claim that the whole game is balanced.

## What the game needs to support

ProjectTactic combines positional battles, jobs/abilities, elemental defenses,
CT initiative, and a persistent roguelite loop. Players need to understand:

1. What this action costs and whether movement/action remain available.
2. What happens on a normal hit, on a critical hit, or on a miss.
3. Why terrain, facing, resistance, and defenses change the result.
4. Which enemies can respond and when the next turns occur.
5. How combat losses and rewards affect the next encounter and their build.

Existing CombatFormula, ForecastCalculator, CombatResolver, TurnOrder and
RunBonuses are the appropriate authorities. Keep new gameplay in Godot; no
parallel browser implementation. Existing forecast signals and scrollable rail
are retained. The asset branch is untouched.

## Implemented first pass

- CombatOutcome derives a three-outcome probability distribution from the
  existing direct-hit forecast. It never rolls RNG or mutates a unit.
- The forecast separates normal damage from critical damage and labels critical
  chance as conditional on hitting. Hit chance remains visible alongside affinity.
- Target HP and the new projected HP bar explicitly describe the normal-hit
  outcome. Critical target HP is a separate line.
- KO probability accounts for both hit and critical chance. It concerns this
  direct hit only, excluding counters, subsequent chain hops, proc attacks and DoT.
- MP cost is visible in the action header. Fake forecast JP rewards were removed
  from the outcome headline; actual reward feedback remains unchanged.
- Area selection without a unit reports area effect/heal/buff and MP cost, with
  no invented +/-10% damage range, accuracy, or uncapped healing amount.
- Positive affinity below 1 means resistance. It does not imply absorption.
- Removed a forecast-only Brand multiplier on magical damage against burning
  targets. Direct spell execution did not apply it. This does not activate or
  rebalance the broader Brand boon implementation.

## Probability contract

Let h = hit probability, c = critical probability conditional on hit, H = current
target HP, N = normal HP damage, C = critical HP damage.

```
P(miss) = 1 - h
P(normal) = h * (1 - c)
P(critical) = h * c
P(KO) = P(normal) * [N >= H] + P(critical) * [C >= H]
Expected HP loss = P(normal) * min(H, N) + P(critical) * min(H, C)
```

Example: H=50, N=40, C=60, hit=88%, critical=5%.
KO chance is 4.4%, not 5% or 88%. Expected actual HP loss is 35.64.
These are decision statistics, not additional randomness or a damage rebalance.
Expected damage is available to future analysis, not shown as guaranteed damage.

## Balance observations — unchanged by this pass

### Armor has a modest HP benefit

With sufficient armor, 35% of incoming damage is removed from Temper/Ether,
but only 25% of that armor loss reduces HP damage. Approximate HP mitigation is
0.35 * 0.25 = 8.75%, with discrete rounding and a minimum positive HP hit.

| Incoming | Armor available | Armor lost | HP lost |
| --- | --- | --- | --- |
| 100 | 100 | 35 | 91 |
| 100 | 20 | 20 | 95 |
| 100 | 0 | 0 | 100 |

Do not describe these pools as absorbing 35% of HP damage. Before changing their
strength, measure their other roles (break/status mechanics, recovery economy),
and encounters to defeat with and without armor. That audit is still needed.

### Positioning can dominate damage output

Maximum high ground (1.30) and rear attack (1.30) multiply to 1.69 damage before
armor, not +60%. Hit rises from 88% to 100%, critical chance from 5% to 18%.
Ignoring rounding, armor, overkill, and follow-up effects, expected output is
about 2.04 times an even-ground frontal attack against the same resistance.
This may be desirable for a positional game. Playtest whether it crowds out
class and equipment choices before altering it.

### Flat resistance creates thresholds

Resistance subtracts before positional/elemental multipliers. Weak attacks can
reach zero while stronger attacks remain effective. Measure damage at low,
middle and high progression tiers before increasing enemy resistance.

## Known follow-up work

1. Counter eligibility currently differs between forecast and resolver: forecast
   uses team/range while execution also depends on VFX attack mode, target survival,
   and its 25% roll. Share that eligibility policy before publishing exact counter
   risk. Current UI continues to say only 'Counter possible'.
2. Audit all boon paths end-to-end. In particular, Brand's declared physical
   behavior and the resolver's physical-only branch need a separate contract
   decision; removing magical preview inflation is only the confirmed mismatch.
3. Area-wide outcomes should enumerate the actual resolver footprint, team
   filters, chain ordering/falloff and secondary effects. Until then, the UI
   deliberately avoids pretending the selected unit represents every recipient.
4. Present dense modifier notes in an expandable, keyboard-accessible details
   section, preserving the outcome and cost above it.
5. Add terrain inspect cards using real movement costs, elevation, LOS and surface
   rules. Never advertise cover bonuses unless execution implements them.
6. Audit reward, healing and shop costs across a full run: resource loss per
   encounter, recovery opportunities, purchase affordability, boon synergies.
7. Add explicit role comparisons for jobs/equipment and a results screen that
   explains earned rewards and recovery. Route all amounts through existing services.

## Next balance harness

Use deterministic encounter fixtures and the real resolver, with isolated saves.
Record action counts, survival, MP expenditure, overkill, damage prevented,
healing wasted, and encounter outcome across seed batches. Compare confidence
intervals and distributions; do not declare a build balanced from one seed or
from a spreadsheet reimplementation of combat. Tune only after capturing a baseline.

## Validation expectations

Run test_combat_clarity.tscn for probability boundary cases, real forecast-to-UI
integration, empty-tile area routing, resistance labels, Brand preview parity,
healing caps, hover cancellation, and horizontal layout at 720p/1080p/4K.
Also run combat formula, healing, turn-order and UI readability regression tests
and the repository static checker. Visual review and manual interaction remain
separate from headless assertions; report precisely which were exercised.

Validation performed with the available Godot 4.6.2 binary:

- New combat clarity suite: 59 checks passed, including a real resolver parity check.
- Existing combat formula suite: 209 passed.
- Existing healing contract suite: 1,556 passed.
- Existing turn-order suite: 130 passed.
- Existing UI readability suite: 2,505 passed.
- Static stability checker passed with 21 existing warnings.
- Native OpenGL preview fixture rendered at 1280x720 and visually inspected;
  horizontal bounds also asserted at 1920x1080 and 3840x2160.

The native capture is an isolated HUD fixture, not a completed gameplay session.
No gamepad hardware or full-run balance playtest was performed. Existing LFS
assets were restored as needed; unrelated import/cache changes are excluded.
The release pipeline uses 4.6.3; rerun its normal checks before merging.
