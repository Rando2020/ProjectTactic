# Job Abilities Reference

This document defines all job abilities, their mechanics, costs, and scaling. Use this as the spec for ability implementation.

## Ability Framework

**Ability Types**:
- **Offensive**: Deal damage or apply negative effects
- **Support**: Heal, buff, or enable teamwork
- **Tactical**: Reposition, control, or disrupt
- **Finisher**: High-impact abilities with high cost/cooldown

**Cost Types**:
- **MP Cost**: Standard resource for spells
- **Ether Cost**: Alternate resource for elemental/spiritual abilities
- **Temper Cost**: Warder-specific resource
- **No cost**: Basic attacks or triggered abilities

**Scaling**:
- **Physical Scaling** (S): (Ability_Base × Job_Physical / 100)
- **Magic Scaling** (M): (Ability_Base × Job_Magic / 100)
- **Hybrid (P+M)**: Average of both scalings
- **Flat**: No scaling

---

## Base Jobs: Core Abilities

### WARDER

#### 1. Power Slash
- **Type**: Offensive
- **Cost**: 0 MP (basic attack enhanced)
- **Range**: 1 (melee)
- **Targeting**: Single enemy
- **Damage**: Base 40 × (Physical / 100)
- **Scaling**: Physical (S)
- **Effect**: Generates 15 Temper for Warder on hit
- **Hit%**: 100%
- **Cooldown**: None (usable every turn)

**Design Note**: Primary damage ability. Every hit advances Temper buildup, enabling defensive abilities. Reliable, straightforward offense.

---

#### 2. Sunder Strike
- **Type**: Tactical
- **Cost**: 15 MP
- **Range**: 1 (melee)
- **Targeting**: Single enemy
- **Damage**: Base 25 × (Physical / 100)
- **Scaling**: Physical (S)
- **Effect**: Reduces target Temper by 30 (removes their defensive resource)
- **Hit%**: 95%
- **Cooldown**: 1 turn (can use every other turn)

**Design Note**: Defensive tool that disables enemy Temper. Forces opponents to rebuild their defensive stance. Critical for controlling dangerous enemies.

---

#### 3. Cover
- **Type**: Support
- **Cost**: Varies (20-40 Temper, converted from Warder's pool)
- **Range**: Self + 2 adjacent allies
- **Targeting**: One ally within range
- **Effect**: Redirect next hit to Warder; absorbs damage using Temper
- **Absorption**: 50% of damage absorbed (rest taken as HP)
- **Duration**: Until hit or 3 turns
- **Cooldown**: None (once per turn, different target each use)

**Design Note**: Active team defense. Warder converts their massive Temper pool into protection. Enables aggressive teammate positioning.

---

#### 4. Lancer Dive
- **Type**: Offensive (Jump-based)
- **Cost**: 20 MP
- **Range**: 2-4 tiles away (can attack distant targets)
- **Targeting**: One enemy in range
- **Damage**: Base 50 × (Physical / 100) + Jump_bonus
- **Scaling**: Physical (S) + Jump stat bonus (+5 per Jump level above 2)
- **Effect**: Damage increases if Warder is higher elevation than target
  - Same height: base damage
  - +1 height: +20% damage
  - +2+ height: +40% damage
- **Hit%**: 90%
- **Cooldown**: 2 turns (long cooldown, high payoff)

**Design Note**: Reward for elevation strategy. Enables Warder to punish distant targets if positioned higher. Scales with Jump stat, encouraging skill distribution.

---

#### WARDER: Reaction Ability

**Deflect Guard** (Passive/Reaction)
- **Trigger**: Ally within 2 tiles takes damage
- **Effect**: Automatically reduce damage by 20% + spend Warder's Temper
  - Cost: 10 Temper per use
  - Can trigger multiple times per turn (up to 3 times)
  - Only triggers if Warder has 10+ Temper
- **Cooldown**: None (reactive, not action-consuming)

**Design Note**: Reactive ability that uses Warder's Temper as team defense tool. Encourages team formations with Warder near allies. Automatic triggers reward good positioning.

---

#### WARDER: Passive Ability

**Temper Stance**
- **Effect**: Any damage taken by allies within 2 tiles generates Temper for Warder
  - 1 Temper generated per 10 damage taken by allies
  - Triggers independently of Deflect Guard
  - Does not reduce damage (pure generation)
- **Synergy**: Enables feedback loop:
  - Allies take damage near Warder
  - Warder builds Temper
  - Warder spends Temper to protect allies
  - Cycle continues

**Design Note**: Core identity reinforcement. The more allies are threatened, the stronger Warder becomes. Creates natural gameplay where Warder positions centrally and tanks/redirects pressure.

---

### ARCANIST

#### 1. Firaga
- **Type**: Offensive (Elemental)
- **Cost**: 18 MP
- **Range**: 2 (ranged spell)
- **Targeting**: Single enemy or tile
- **Damage**: Base 50 × (Magic / 100)
- **Scaling**: Magic (M)
- **Element**: Fire
- **Effect**: Applies Fire surface on target tile
  - Fire persists for 2 turns
  - Next Blizzaga on this tile triggers combo (+30% damage)
  - Can stack with other surfaces
- **Hit%**: 100%
- **Cooldown**: None

**Design Note**: First spell in combo chain. Applies environmental effect that enables reactions. Base damage reasonable, but real payoff is in chaining.

---

#### 2. Blizzaga
- **Type**: Offensive (Elemental)
- **Cost**: 18 MP
- **Range**: 2 (ranged spell)
- **Targeting**: Single enemy or tile
- **Damage**: Base 50 × (Magic / 100)
- **Scaling**: Magic (M)
- **Element**: Ice
- **Effect**:
  - If target has Fire surface: +30% damage bonus (reaction)
  - Applies Steam surface on tile (new element)
  - Steam enables Thundaga reactions (+30% damage)
- **Hit%**: 100%
- **Cooldown**: None

**Design Note**: Second spell in chain. Reacts with Fire to deal bonus damage, then creates new surface for next step. Rewards sequential casting.

---

#### 3. Thundaga
- **Type**: Offensive (Elemental)
- **Cost**: 18 MP
- **Range**: 2 (ranged spell)
- **Targeting**: Single enemy or tile
- **Damage**: Base 50 × (Magic / 100)
- **Scaling**: Magic (M)
- **Element**: Thunder
- **Effect**:
  - If target has Steam surface: +30% damage bonus (reaction)
  - Creates Lightning surface (final element)
  - Clears all surfaces after reaction
- **Hit%**: 100%
- **Cooldown**: None

**Design Note**: Third spell in chain. Reacts with Steam, then clears surfaces for finisher. Completes combo setup.

---

#### 4. Flare
- **Type**: Finisher (Non-elemental)
- **Cost**: 30 MP
- **Range**: 2 (ranged spell)
- **Targeting**: Single enemy or tile
- **Damage**: Base 80 × (Magic / 100)
- **Scaling**: Magic (M)
- **Element**: Physical/Non-elemental (ignores resistances)
- **Effect**:
  - Ignores target's Magic resistance
  - Damage bonus if elemental surfaces exist (+15% per surface)
  - Consumes all surfaces (ends combo chain)
- **Hit%**: 100%
- **Cooldown**: 1 turn (after each cast)

**Design Note**: Finisher spell that ignores resistances and scales with surfaces. High MP cost reflects high power. Closes combo chain with payoff damage.

---

#### ARCANIST: Reaction Ability

**Ether Guard** (Passive/Reaction)
- **Trigger**: Takes elemental damage
- **Effect**:
  - Reduce incoming elemental damage by 15%
  - Restore Ether equal to 30% of damage prevented
  - Triggers automatically, not action-consuming
  - Cooldown: None
- **Synergy**: Damage taken → fuel restored; enables counterattack

**Design Note**: Defensive reaction that generates offense fuel. Arcanist takes elemental hit but gets resources back to cast revenge spell. Encourages aggressive play despite low HP.

---

#### ARCANIST: Passive Ability

**Combo Memory**
- **Effect**:
  - Each elemental spell cast increases next spell's damage by 15%
  - Stacks up to 5 times (75% bonus at max)
  - Stack resets if non-elemental spell is cast
  - Bonus applies to Flare and other spells
- **Synergy**: Rewards sequential casting (Fire → Ice → Thunder → Flare = 60% bonus on Flare)

**Design Note**: Rewards planning and commitment to spell chains. Incentivizes pre-planning combo sequences rather than reactive casting.

---

### RESONANT

#### 1. Summon
- **Type**: Support (Summoning)
- **Cost**: 25-35 Ether (varies by Guardian)
- **Range**: Self
- **Targeting**: N/A (summons freed Guardian unit)
- **Effect**:
  - Brings freed Guardian onto field
  - Guardian appears adjacent to Resonant
  - Guardian acts immediately (tempo advantage)
  - Guardian inherits Resonant's Magic stat (+% bonus to Guardian's spells)
  - Guardian lasts until defeated or Resonant is defeated
- **Hit%**: N/A
- **Cooldown**: 1 turn (summon once per turn)

**Design Note**: Core mechanic. Adds powerful ally to field. Ether cost scales with Guardian power. Immediate action on summon is tempo advantage.

---

#### 2. Aura
- **Type**: Support (Buff)
- **Cost**: 15 MP
- **Range**: 3 (nearby allies)
- **Targeting**: All allies in range
- **Effect**:
  - Grant +20% Physical and Magic for 2 turns
  - Stacks with other buffs
  - Can be cast multiple times (different allies)
- **Hit%**: N/A (buff, not attack)
- **Cooldown**: None

**Design Note**: Setup ability that prepares team for damage window. Works independently of summons, enabling diverse tactical options.

---

#### 3. Mana Flow
- **Type**: Resource (Conversion)
- **Cost**: 30-60 Temper (converted to Ether)
- **Range**: Self
- **Targeting**: Self only
- **Effect**:
  - Convert Resonant's Temper to Ether 1:1 ratio
  - Spend X Temper, gain X Ether
  - Enables summoning even when Ether is depleted
  - Only Resonant has this conversion
- **Hit%**: N/A
- **Cooldown**: None (action to use)

**Design Note**: Unique resource management tool. Temper-to-Ether conversion creates interesting positioning decisions (can summon if nearby Temper-building allies exist).

---

#### 4. Null Echo
- **Type**: Tactical (Echo)
- **Cost**: 20 Ether
- **Range**: 3 (range of Guardian's ability)
- **Targeting**: One Guardian's ability
- **Effect**:
  - Cast one active Guardian's ability as if Resonant is the caster
  - Uses Resonant's Magic for scaling (Guardian's ability formulae)
  - Guardian's ability doesn't get cast by Guardian (no cooldown spent on Guardian)
  - Creates multi-turn Guardian presence
- **Hit%**: Depends on Guardian's ability
- **Cooldown**: 2 turns

**Design Note**: Extends Guardian duration through echoed abilities. Rewards summoning multiple Guardians with overlapping ability windows.

---

#### RESONANT: Reaction Ability

**Resonance Pulse** (Passive/Reaction)
- **Trigger**: Guardian is summoned while nearby allies exist
- **Effect**:
  - All nearby allies within 3 tiles gain +15% attack damage for 2 turns
  - Triggers automatically when Guardian appears
  - Cooldown: None
- **Synergy**: Summon creates team damage window; Resonant initiates power spike

**Design Note**: Encourages team positioning around Resonant. Summon creates tempo advantage that extends to allies. Rewards coordinated play.

---

#### RESONANT: Passive Ability

**Guardian Attunement**
- **Effect**:
  - Resonant and active Guardian share 50% damage reduction if adjacent
  - Damage overflow (damage > Guardian's current HP) transfers to Resonant
  - Creates shared fate mechanic
  - Both benefit from proximity
- **Synergy**: Encourages Guardian to stay near Resonant; punishes Guardian isolation

**Design Note**: Core identity reinforcement. Guardian isn't a separate unit—it's an extension of Resonant. Positioning matters.

---

### LUMINARY

#### 1. Curaga
- **Type**: Support (Healing)
- **Cost**: 20 MP
- **Range**: 3 (ranged healing)
- **Targeting**: Single ally
- **Healing**: Base 80 × (Magic / 100)
- **Scaling**: Magic (M)
- **Effect**:
  - Restore HP to target
  - Can overheal up to 15% above max (buffer pool)
- **Hit%**: N/A (always succeeds)
- **Cooldown**: None

**Design Note**: Primary healing spell. Scales with Magic. No cooldown enables spam healing if needed. Overheal buffer prevents wasted healing.

---

#### 2. Bulwark
- **Type**: Support (Protection)
- **Cost**: 15 MP
- **Range**: 3 (ranged)
- **Targeting**: Single ally
- **Effect**:
  - Grant temporary damage reduction (30%) to target
  - Effect lasts 2 turns or until expires
  - Can stack with other buffs
  - Preventative: reduces incoming damage instead of fixing HP loss
- **Hit%**: N/A
- **Cooldown**: None

**Design Note**: Preventative healing. Stops damage before it happens. Enables positioning freedom for teammates.

---

#### 3. Veil
- **Type**: Support (Cleansing)
- **Cost**: 12 MP per status effect
- **Range**: 3 (ranged)
- **Targeting**: Single ally with status
- **Effect**:
  - Remove one status effect from target
  - Can remove multiple status effects in sequence (costs increase)
  - Only job with dedicated cleanse ability
  - Removes: poison, burn, stun, petrify, slow, etc.
- **Hit%**: 100% (always succeeds if status present)
- **Cooldown**: None

**Design Note**: Defense against status pressure. Veil is the only job with dedicated cleansing. Makes Luminary essential for long battles with status enemies.

---

#### 4. Raise
- **Type**: Support (Resurrection)
- **Cost**: 40 Ether (high cost, limited availability)
- **Range**: 2 (ranged resurrection)
- **Targeting**: Defeated ally
- **Effect**:
  - Revive defeated ally with 30% max HP
  - Revived ally can act same turn (if turn hasn't arrived yet)
  - Limited resurrections per battle (Ether cost gates frequency)
- **Hit%**: N/A (always succeeds if target defeated)
- **Cooldown**: 1 turn (revive once per turn max)

**Design Note**: Game-changer ability. Ether cost (not MP) makes it strategic resource. Enables team to recover from defeats without full team wipe. Critical for endurance battles.

---

#### LUMINARY: Reaction Ability

**Blessed Recovery** (Passive/Reaction)
- **Trigger**: Nearby ally within 2 tiles takes damage
- **Effect**:
  - Automatically restore 15% of their max HP
  - Doesn't consume action
  - Triggers per ally hit (multiple triggers per turn possible)
  - Cooldown: None per ally, but Luminary can only trigger up to 3x per turn
- **Synergy**: Passive team healing; encourages Luminary centrally positioned

**Design Note**: Enables passive team healing without Luminary consuming actions. Encourages aggressive teammate positioning knowing they'll be healed.

---

#### LUMINARY: Passive Ability

**Kindled Light**
- **Effect**:
  - Each heal cast increases next heal's potency by 20%
  - Stacks up to 3 times (60% bonus at max)
  - Bonus applies to Curaga and Raise
  - Stack resets if other abilities used
- **Synergy**: Rewards consecutive healing (Curaga → Curaga → Curaga = 60% bonus on 3rd)

**Design Note**: Incentivizes focused healing rotations. Healing gets stronger the more you focus on it. Rewards commitment to healing phase.

---

## Advanced & Ascended: Core Abilities

### SKYWARDEN

#### 1. Dragon Jump
- **Type**: Offensive (Jump-based)
- **Cost**: 15 MP
- **Range**: 2-5 (based on Jump stat; can reach distant targets)
- **Targeting**: One enemy in range
- **Damage**: Base 60 × (Physical / 100) + Jump_bonus
- **Scaling**: Physical (S) + Jump stat (+8 per Jump level above 2)
- **Effect**:
  - Damage increases with elevation advantage
  - Can jump to reach distant targets
  - Positions Skywarden near target (useful for follow-ups)
  - Height bonus: +5% per 1 height difference
- **Hit%**: 95%
- **Cooldown**: None

**Design Note**: Primary damage. Rewards elevation. Jump stat is core scaling factor.

---

#### 2. Lancet
- **Type**: Offensive (Quick)
- **Cost**: 8 MP
- **Range**: 1 (adjacent only)
- **Targeting**: One adjacent enemy
- **Damage**: Base 30 × (Physical / 100)
- **Scaling**: Physical (S)
- **Effect**:
  - Low damage but can chain with Dragon Jump
  - Enables positioning adjustment mid-combo
- **Hit%**: 100%
- **Cooldown**: None

**Design Note**: Quick strike for repositioning or cleanup. Low cost enables tactical sequences.

---

#### 3. Dragon Fang
- **Type**: Offensive (AOE Finisher)
- **Cost**: 25 MP
- **Range**: 1-2 (around landing zone)
- **Targeting**: AOE around Skywarden
- **Damage**: Base 70 × (Physical / 100)
- **Scaling**: Physical (S)
- **Effect**:
  - Damage in AOE around Skywarden's position
  - Hits all enemies in 2-tile radius
  - Can hit backline groups with positioning
- **Hit%**: 90%
- **Cooldown**: 1 turn

**Design Note**: AOE payoff ability. Rewards successful positioning on backline.

---

#### 4. (TBD: Fourth ability)

Recommended: **Aerial Evasion** (Escape/Mobility)
- **Type**: Tactical (Escape)
- **Cost**: 10 MP
- **Range**: Self
- **Targeting**: Self
- **Effect**:
  - Jump away from current tile (2-3 tiles)
  - Avoid incoming attack (triggers when attacked)
  - Enables hit-and-run tactics
- **Hit%**: N/A
- **Cooldown**: None

---

### NULL BREAKER

#### 1. Null Sunder
- **Type**: Offensive (Setup)
- **Cost**: 30 Temper + 15 MP
- **Range**: 1 (melee)
- **Targeting**: Single enemy
- **Damage**: Base 70 × (Physical / 100)
- **Scaling**: Physical (S)
- **Effect**:
  - Reduce target's Physical Resistance by 50% for 3 turns
  - Unlocks massive team damage window
  - Only job that disables resistances
- **Hit%**: 85%
- **Cooldown**: 1 turn

**Design Note**: Synergy ability. Sets up team for burst. Temper cost gates frequency.

---

#### 2. Anchor Break
- **Type**: Tactical (Defensive)
- **Cost**: 20 Temper
- **Range**: 1 (melee)
- **Targeting**: Single enemy
- **Effect**:
  - Drain target's entire Temper pool to 0
  - Prevents target from using Temper-based abilities
  - Lasts indefinitely until target rebuilds Temper
  - Only job that disables Temper as resource
- **Hit%**: 90%
- **Cooldown**: 1 turn

**Design Note**: Disables defensive resource. Forces enemy to rebuild. Breaks enemy team cohesion.

---

#### 3. Guardian Guard
- **Type**: Support (Protection)
- **Cost**: 40-60 Temper (varies by target distance)
- **Range**: 2 (nearby allies)
- **Targeting**: One ally
- **Effect**:
  - Redirect next hit to NULL BREAKER
  - Damage absorbed using NULL BREAKER's Temper
  - Similar to Warder's Cover but with Temper cost
- **Hit%**: N/A
- **Cooldown**: None

**Design Note**: Team defense. Enables protect ally playstyle. High Temper pool supports frequent use.

---

#### 4. Rift Cleave
- **Type**: Offensive (AOE)
- **Cost**: 25 MP
- **Range**: 1-2 (melee AOE)
- **Targeting**: AOE around NULL BREAKER
- **Damage**: Base 80 × (Physical / 100) + bonus vs exposed targets
- **Scaling**: Physical (S)
- **Effect**:
  - Bonus damage (+40%) to enemies with reduced resistances
  - Hits all enemies in 2-tile radius
  - Payoff for Sunder setup
- **Hit%**: 90%
- **Cooldown**: 1 turn

**Design Note**: Finisher ability. Scales with Sunder setup. Rewards coordinated team breakdown.

---

## Reaction & Passive Abilities: Complete List

| Job | Reaction | Trigger/Effect | Passive | Effect |
|-----|----------|---|---|---|
| **Warder** | Deflect Guard | Ally hit → -20% dmg (10 Temper cost) | Temper Stance | Allies' dmg → Warder Temper (+1/10 dmg) |
| **Arcanist** | Ether Guard | Elemental hit → -15% dmg + Ether restore | Combo Memory | Spell cast → +15% next spell (max 5 stacks) |
| **Resonant** | Resonance Pulse | Guardian summoned → +15% ally damage (2 turns) | Guardian Attunement | Resonant + Guardian adjacent → shared 50% reduction |
| **Luminary** | Blessed Recovery | Ally hit → +15% max HP restore | Kindled Light | Heal cast → +20% next heal (max 3 stacks) |
| **Skywarden** | Aerial Shift | Damage taken → jump away, -damage | High Ground Hunter | Atk from higher → +15% dmg, same → +10%, lower → -5% |
| **Null Breaker** | Anchor Counter | Ally hit → free Anchor Break (25 Temper) | Null Break | Attacks reduce target Temper + resistances |
| **Etherweaver** | Spell Slip | Hit by elemental → free elemental spell | Extended Chain | Elemental reactions last +2 turns |
| **Primal Binder** | Guardian Intercept | Ally hit → Guardian redirects damage | Bound Primal | 2 Guardians active → +30% damage each |
| **Seraph** | Radiant Reprieve | Ally near death → grant massive shield | Mercy Engine | Heal → Raise cooldown -1, shield duration +1 |

---

## Cost Summary

**MP Costs by Job**:
- Warder: 15-20 MP abilities (minimal caster)
- Arcanist: 18-30 MP abilities (caster focused)
- Resonant: 15-20 MP support (minimal spell costs)
- Luminary: 12-40 MP healing (varied costs)
- Skywarden: 8-25 MP (low caster, physical focused)
- Null Breaker: 15-25 MP (secondary to Temper)
- Etherweaver: 20-40 MP (heavy caster)
- Primal Binder: 15-25 MP support
- Seraph: 20-40 MP healing (higher costs)

**Ether Costs**:
- Only for: Resonant (summons), Luminary (Raise), Seraph (Raise)
- Ranges: 20-50 Ether for summoning, 40 Ether for resurrection

**Temper Costs**:
- Only for: Warder, Skywarden, Null Breaker
- Ranges: 10-60 Temper for defensive/offensive abilities

---

## Version History

- **v1.0** (Job Identity Pass Release): All base jobs, advanced, and ascended abilities defined
