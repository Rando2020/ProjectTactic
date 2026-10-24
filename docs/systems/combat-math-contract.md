# Combat Math Contract

This project uses original formulas inspired by classic tactics readability and modern elemental RPG clarity. The design goal is that the forecast and the resolver always agree.

## Shared Rule

All direct combat should go through `CombatFormula.gd` first. Forecasts read the returned dictionary. Resolvers apply the returned incoming damage and report the actual HP/armor results.

## Physical Damage

```text
raw = Physical * 1.20
modified = raw * attacker_damage_mods
resisted = max(modified - PhysicalResistance, 0)
incoming = round(resisted * HeightMultiplier * FacingMultiplier)
```

Physical damage then projects through Temper:

```text
temper_damage = min(current_temper, round(incoming * 0.35))
hp_damage = max(1, incoming - round(temper_damage * 0.25))
```

Protect reduces physical incoming to 70%; Defend reduces physical and magical incoming to 50%. Both round before armor projection and stack for physical damage. True damage and DoT bypass these defenses. Zero incoming stays zero HP/armor loss. Unit.receive_damage consumes these same projections, including rounding.

## Magical Damage

```text
raw = Magic * (BasePower / 100)
modified = raw * elemental_or_boon_mods
resisted = max(modified - MagicResistance, 0)
incoming = round(resisted * ElementalAffinity)
```

Magical damage projects through Ether using the same armor shape:

```text
ether_damage = min(current_ether, round(incoming * 0.35))
hp_damage = max(1, incoming - round(ether_damage * 0.25))
```

## Height

Height changes physical damage and hit chance.

```text
higher attacker: +10% damage per height step, capped at +30%
lower attacker: -8% damage per height step, capped at -24%
```

## Facing

Facing is based on where the attacker stands relative to the target.

```text
front: x1.00 damage
side:  x1.15 damage
back:  x1.30 damage
```

Side and back attacks also improve accuracy and crit chance.

## Accuracy

```text
physical base hit: 88%
magical base hit: 100%
side attack: +5%
back attack: +12%
high ground: +3%
low ground: -5%
blind: -35%
invisible target: -25%
```

Final hit chance is clamped from 20% to 100%.

## Crit

```text
base physical crit: 5%
side attack: +4%
back attack: +10%
high ground: +3%
crit damage: x1.50 incoming damage before armor projection
```

Spells do not roll crits in the current resolver; forecasts therefore show 0% crit, including from the side/back. Physical critical forecasts multiply incoming before projecting armor, just like resolution.

## Elemental Affinity

Elemental affinity is a multiplier on resisted magical damage.

```text
0.0 = immune
0.5 = resistant
1.0 = neutral
1.5 = weak
2.0 = very weak
```

`ice` is normalized to `blizzard` so ability data can use either naming style.

## Current Integration

- `CombatFormula.gd` owns physical, magical, heal, height, facing, accuracy, crit, and armor projection math.
- `ForecastCalculator.gd` reads formula output for UI forecasts.
- `CombatResolver.gd` applies formula output for real attacks and spells.
- `BattleManager.gd` enemy prediction now uses the same formula path.
- `test_combat_formula.gd` covers first-pass physical, armor, height/facing, and elemental cases.
## Physical ability power and initiative

Physical abilities use `Physical * (BasePower / 100)` in the existing formula,
including resistance, height, facing and armor. Basic attacks/counters retain
`Physical * 1.20`. ForecastCalculator, enemy prediction and real ability
resolution all pass the same declared `base_power`; this is not a new balance
multiplier layered over the basic attack.

TurnOrder live activation and prediction share integer CT ticks. Already-ready
units act before time advances. Ready units are ordered by effective speed,
then stable roster order. Each activation subtracts 100 CT, preserving overflow.
Prediction copies CT and effective speed and does not mutate units; it assumes
no future actions, deaths, status expiration or speed changes. A status change
requires a fresh projection, not a promise about unknown future decisions.

Displayed damage ranges contain exact normal and critical outcomes (hit chance
is separate), not invented random variance. Noncritical magical hits show one
exact value. Haste/Slow application, removal and expiration refresh the visible
timeline immediately without advancing CT. Defending expires at the unit's next
begin_turn, allowing a fresh Defend choice on consecutive turns.

## Resolved feedback vs projected potency

`Unit.receive_damage` and both direct-damage resolver paths expose
`applied_hp_damage`: HP actually removed by this hit, capped at the target's HP
at the damage-application boundary, before signals, defeat callbacks or other
on-hit effects. Misses return zero. `temper_damage` / `ether_damage` already
report the corresponding armor loss.

The existing `hp_damage` / `damage` fields keep their projected, potentially
overkill values. Existing boon, lifesteal, hit-intensity and floating-number
consumers are not rebalanced by this reporting change.

Single-target spell logs and individual chain-hop logs consume the resolver
outcome, not `base_power`. Feedback distinguishes MISS, damage immunity, actual
HP lost and armor lost. Immunity to damage does not claim status immunity.
An executed miss or immune hit still costs the same action and MP; rejected
casts have no resolved outcome. `_execute_ability` retains its boolean admission
contract while `_execute_ability_with_result` also returns that direct outcome.
