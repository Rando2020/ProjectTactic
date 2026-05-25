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

Protection states reduce incoming before armor projection.

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

Spells default to no crit unless an ability or boon explicitly opts in.

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