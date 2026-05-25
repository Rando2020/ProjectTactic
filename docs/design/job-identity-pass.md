# Job Identity Pass

## Overview

This document establishes the core identity, stat priorities, ability roles, and growth curves for every job in ProjectTactic. Each job has a distinct **core mechanical niche** that makes it irreplaceable in combat.

The design principle: **If two jobs do the same thing, one of them fails.**

---

## Part 1: Base Jobs (Tier 1)

Base jobs are available from game start. Each serves a distinct mechanical role that defines team composition decisions.

---

### WARDER: Frontline Defender & Temper Stripper

**Core Identity:**
- **Role**: Anchors the frontline, builds Temper faster than other jobs, uses Temper as both defensive and offensive tool
- **Niche**: The only job that meaningfully interacts with Temper as a primary mechanic
- **Combat Pacing**: Each attack builds team Temper; each defensive action converts Temper to protection

**Base Stats** (Level 1):
- **HP**: 28 (high for survivability)
- **MP**: 6 (minimal casting ability)
- **Move**: 4 (standard)
- **Jump**: 2 (ground-locked)
- **Speed**: 7 (standard)
- **Physical**: 50 (strong physical attacks)
- **Magic**: 20 (poor spellcasting)
- **Physical Resistance**: 0
- **Magic Resistance**: -15 (takes extra magic damage - balances tankiness)
- **Max Temper**: 100 (highest in game)
- **Max Ether**: 40 (low)
- **Attack Range**: 1 (melee)

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Power Slash** (Offensive) - High physical damage attack
   - Generates Temper on hit
   - Scales with Physical stat
   
2. **Sunder Strike** (Tactical) - Reduces target Temper on hit
   - Primary defensive tool against enemy Temper
   - Enables teammate survival
   
3. **Cover** (Protective) - Redirect damage to self using Temper
   - Costs Temper instead of HP
   - Enables positioning freedom for allies
   
4. **Lancer Dive** (Mobility) - High-damage jump attack
   - Scales with Jump; rewards elevation
   - Manages range in elongated fights

**Reaction Ability**: Deflect Guard
- Triggers when allies nearby take damage
- Reduces incoming damage by spending own Temper
- Enables reactive playstyle

**Passive**: Temper Stance
- All damage to allies within 2 tiles generates Warder Temper
- Teammates taking damage → Warder's Temper rises
- Creates feedback loop: protect allies → build Temper → spend it to protect more

**Growth Curve**:
- **HP**: Gains +2 per level (total: 28 → 48 at Lv11)
- **MP**: Gains +0.3 per level (stays minimal)
- **Physical**: Gains +1.2 per level (scales offense into mid-game)
- **Magic**: Gains +0.2 per level (irrelevant)
- **Max Temper**: Gains +1.5 per level (primary scaling)
- **Resistances**: No scaling; stays weak to magic

**Design Coherence**: Warder is the only job where Temper is a primary resource, not a secondary. No other job should build Temper as effectively or use it as defensively. This makes Warder essential for any team that wants to leverage Temper-based defense and offense.

---

### ARCANIST: Elemental Combo Engine

**Core Identity:**
- **Role**: Builds multi-turn elemental chains; rewards planned play
- **Niche**: Only job with native elemental combo generation
- **Combat Pacing**: Early turn 1-2 casts setup; turns 3+ explode with chained reactions

**Base Stats** (Level 1):
- **HP**: 14 (frail; must avoid damage)
- **MP**: 80 (highest in game; fuel for casting)
- **Move**: 3 (reduced movement, encourages backline positioning)
- **Jump**: 2 (ground-locked)
- **Speed**: 6 (slightly slower than standard)
- **Physical**: 15 (weak; not a melee job)
- **Magic**: 60 (highest in game; primary stat)
- **Physical Resistance**: -10 (vulnerable to physical)
- **Magic Resistance**: 15 (resists elemental)
- **Max Temper**: 20 (irrelevant for Arcanist)
- **Max Ether**: 80 (high; fuels elemental spells)
- **Attack Range**: 3 (ranged)

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Firaga** (Offensive Combo) - Fire element spell
   - Applies Fire surface on ground
   - Scales with Magic stat
   - Sets up Blizzaga/Thundaga reactions
   
2. **Blizzaga** (Offensive Combo) - Ice element spell
   - Reacts with Fire surface for increased damage
   - Creates Steam surface for next Thundaga
   
3. **Thundaga** (Offensive Combo) - Thunder element spell
   - Reacts with Steam surface for increased damage
   - Chains multiple hits
   
4. **Flare** (Finisher) - High-damage non-elemental spell
   - Ignores resistances
   - Costs extra Ether
   - Closes elemental chains

**Reaction Ability**: Ether Guard
- Triggers when hit by elemental damage
- Reduces damage and restores Ether
- Enables survival through offense (restores fuel for counterattack)

**Passive**: Combo Memory
- Each elemental spell cast increases the next spell's damage by 15%
- Stacks up to 5 times
- Reward for sequential casting (planning matters)

**Growth Curve**:
- **HP**: Gains +0.5 per level (stays frail)
- **MP**: Gains +2 per level (scales casting volume)
- **Magic**: Gains +1.5 per level (primary scaling; offense grows reliably)
- **Ether**: Gains +1.5 per level (maintains casting fuel)
- **Speed**: No scaling (built in at 6)

**Design Coherence**: Arcanist is the only job with native combo generation. All other elemental damage comes from abilities, status effects, or spells borrowed from ascended jobs. No other job should generate elemental surfaces or reactions as core identity.

---

### RESONANT: Guardian Caller & Window Enabler

**Core Identity:**
- **Role**: Summons Guardians (powerful ally units) during Resonance Windows
- **Niche**: Only job that directly summons external units; enables a second team phase
- **Combat Pacing**: Early game: builds toward summoning; when Resonance triggers: massive tempo swing

**Base Stats** (Level 1):
- **HP**: 22 (medium; not front-loaded like Warder)
- **MP**: 70 (high to fuel summons)
- **Move**: 4 (standard)
- **Jump**: 2 (ground-locked)
- **Speed**: 7 (standard)
- **Physical**: 25 (weak but better than Arcanist)
- **Magic**: 50 (strong but secondary to summoning triggers)
- **Physical Resistance**: 0
- **Magic Resistance**: 0
- **Max Temper**: 60 (medium)
- **Max Ether**: 100 (highest in game; summons cost Ether)
- **Attack Range**: 2 (ranged)

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Summon** (Core Mechanic) - Calls a freed Guardian ally
   - High Ether cost
   - Guardian stats scale with Resonant's Magic
   - Guardian acts immediately when summoned (tempo advantage)
   
2. **Aura** (Buff) - Grants temporary stat boost to nearby allies
   - Enables Resonant to support without summoning
   - Setup for Guardian teamwork
   
3. **Mana Flow** (Resource) - Converts Temper to Ether
   - Only job that does this conversion
   - Enables summoning even when Ether depleted
   
4. **Null Echo** (Disruption) - Echoes a Guardian ability
   - Resonant casts a Guardian's ability as if they're still present
   - Allows multi-turn Guardian presence

**Reaction Ability**: Resonance Pulse
- When a Guardian is summoned, nearby units gain temporary attack boost
- Reinforces summon-focused playstyle

**Passive**: Guardian Attunement
- Resonant and active Guardian share damage reduction if adjacent
- Encourages tactical positioning of Guardian + Resonant
- If Guardian takes damage, Resonant takes 50% of overflow
- Creates shared fate mechanic

**Growth Curve**:
- **HP**: Gains +1 per level (medium growth)
- **MP**: Gains +1.5 per level (fuels summoning upgrades)
- **Magic**: Gains +1 per level (moderate scaling)
- **Max Ether**: Gains +2 per level (scales summoning ability)
- **Speed**: No scaling (standard at 7)

**Design Coherence**: Resonant is the only job that summons units. This is irreplaceable because Guardians are unique entities with their own stat pools. No other job should be able to call external allied units; this makes Resonant essential for specific team compositions and late-game endurance (sustain damage through Guardian rotation).

---

### LUMINARY: Healer & Cleanser

**Core Identity:**
- **Role**: Restores HP, Temper, Ether; removes status effects; enables team persistence
- **Niche**: Only job with core healing abilities; only job with status cleansing as main tool
- **Combat Pacing**: Early: setup for big heals; mid/late: reactive healing + cleanse pressure

**Base Stats** (Level 1):
- **HP**: 20 (low; vulnerable)
- **MP**: 80 (high; fuels healing)
- **Move**: 4 (standard, but often positioned in back)
- **Jump**: 2 (ground-locked)
- **Speed**: 8 (higher than average; healing faster is better)
- **Physical**: 20 (weak; not a fighter)
- **Magic**: 55 (strong; heals scale from this)
- **Physical Resistance**: -10 (takes extra physical)
- **Magic Resistance**: 10 (resists magic slightly)
- **Max Temper**: 40 (low; not a Temper job)
- **Max Ether**: 90 (high; cleansing costs Ether)
- **Attack Range**: 3 (ranged)

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Curaga** (Healing) - Large single-target heal
   - Scales from Magic stat
   - Heals target up to max HP
   - Highest single-target healing in game
   
2. **Bulwark** (Protection) - Reduces incoming damage for target
   - Like temporary resistance boost
   - Preventative healing (stops damage instead of fixing it)
   
3. **Veil** (Cleansing) - Removes one status effect from target
   - Primary defense against status pressure
   - Enables teammates to stay effective
   
4. **Raise** (Resurrection) - Revives defeated ally with partial HP
   - Uses Ether, not MP (balances against spamming)
   - Limits team size damage (player has resources to recover)

**Reaction Ability**: Blessed Recovery
- When nearby allies take damage, restore small amount of their HP
- Enables passive team healing even when Luminary doesn't act
- Encourages Luminary to stay near frontline

**Passive**: Kindled Light
- Each heal cast increases next heal's potency by 20%
- Stacks up to 3 times
- Rewards sequential healing (fits healing pacing)

**Growth Curve**:
- **HP**: Gains +0.8 per level (stays vulnerable)
- **MP**: Gains +2 per level (scales healing capacity)
- **Magic**: Gains +1.3 per level (primary scaling for heal potency)
- **Speed**: Gains +0.2 per level (maintains 8+)
- **Max Ether**: Gains +1.5 per level (scales resurrection availability)

**Design Coherence**: Luminary is the only job with native healing and cleansing. No other job should have core healing abilities; this makes Luminary essential for team survival and status defense.

---

## Part 2: Advanced Job (Tier 2)

Advanced jobs unlock after base job progression. They add depth to existing roles without fully replacing them.

---

### SKYWARDEN: Jump Attacker & Backline Diver

**Core Identity:**
- **Role**: Punishes backline enemies; leverages elevation for bonus damage
- **Niche**: Only job with innate jump range for combat (not just terrain traversal)
- **Combat Pacing**: Position into elevation → dive with Dragon Jump → escape with Aerial Shift

**Unlock**: Warder Lv. 3 (progression builds from defending to diving)

**Base Stats** (Level 1, scales from Warder base):
- **HP**: 30 (higher than Warder; trading tankiness for mobility)
- **MP**: 8 (minimal)
- **Move**: 5 (increased from Warder's 4; aggressive positioning)
- **Jump**: 4 (doubled from Warder's 2; core mechanic)
- **Speed**: 8 (faster than Warder; rewards decisive action)
- **Physical**: 52 (similar to Warder but builds faster)
- **Magic**: 22 (weak; not a caster)
- **Physical Resistance**: -5 (less vulnerable than Warder)
- **Magic Resistance**: -15 (stays weak to magic; balances aerial advantage)
- **Max Temper**: 70 (reduced from Warder; trades defensiveness for offense)
- **Max Ether**: 50 (medium)
- **Attack Range**: 1 (melee, but delivered from air)

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Dragon Jump** (Primary) - Jump to target; deal damage on landing
   - Damage scales with Jump stat
   - Can jump to elevations (+1 damage per height difference)
   - Position matters (elevation advantage = stronger attacks)
   
2. **Lancet** (Quick Strike) - Fast melee attack while airborne
   - Lower damage than Dragon Jump
   - Enables chain diving
   
3. **Dragon Fang** (Finisher) - Powerful ground slam after jump
   - Deals AOE damage around landing zone
   - Can hit backline groups
   
4. (Fourth ability: TBD - possibly an escape or setup tool)

**Reaction Ability**: Aerial Shift
- When taking damage, jump away from attacker
- Reduces damage taken and repositions Skywarden
- Enables aggressive play without penalty (can disengage)

**Passive**: High Ground Hunter
- Gain +15% damage when attacking from higher elevation than target
- +10% if on same height
- -5% if attacking from lower elevation
- Rewards tactical elevation planning

**Growth Curve**:
- **HP**: Gains +1.5 per level
- **Jump**: Gains +0.4 per level (scales the core mechanic)
- **Physical**: Gains +1.2 per level (scales dive damage)
- **Speed**: Gains +0.2 per level (aggressive pacing)

**Design Coherence**: Skywarden is the only job where Jump stat directly increases combat damage (not just terrain traversal). This makes elevation gameplay a core mechanic, not a side benefit.

---

## Part 3: Ascended Jobs (Tier 3)

Ascended jobs represent pinnacle specialization. Each takes a base job's core mechanic and amplifies it to extreme potency.

---

### NULL BREAKER: Armor Destroyer & Anchor Specialist

**Core Identity**:
- **Role**: Breaks enemy defenses; exploits exposed targets for massive damage
- **Niche**: Only job that directly reduces enemy resistances and Temper
- **Combat Pacing**: Sunder enemy → teammates deal +50% damage → NULL BREAKER finishes

**Unlock**: Warder Lv. 5 + completed_stormglass_trial

**Base Stats** (Level 1, scales from Warder):
- **HP**: 35 (tankiest job in game)
- **MP**: 8 (minimal)
- **Move**: 4 (standard)
- **Jump**: 3 (modest improvement)
- **Speed**: 7 (standard)
- **Physical**: 58 (stronger than Warder)
- **Magic**: 22 (irrelevant)
- **Physical Resistance**: 10 (gains resistance to offset tankiness risk)
- **Magic Resistance**: -15 (still weak to magic)
- **Max Temper**: 120 (even higher than Warder)
- **Max Ether**: 60
- **Attack Range**: 1

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Null Sunder** (Primary) - Massive attack that reduces target's Physical Resistance
   - Effect lasts 3 turns
   - Scales with Physical stat + Temper spent
   - Unlocks massive team damage window
   
2. **Anchor Break** (Tactical) - Shatters enemy Temper, leaving them exposed
   - Drains target's Temper
   - Prevents them from using defensive Temper abilities
   - Only job that disables Temper as resource
   
3. **Guardian Guard** (Protection) - Uses Temper to protect an ally
   - Absorbs damage as Temper (share mechanic)
   - Converts NULL BREAKER's role into team tank
   
4. **Rift Cleave** (AOE) - Large area attack against exposed enemies
   - Bonus damage to enemies with reduced defenses
   - Punishes Sunder setup

**Reaction Ability**: Anchor Counter
- When nearby ally is hit, retaliate with reduced-cost Anchor Break
- Enables reactive team defense

**Passive**: Null Break
- All attacks reduce enemy Temper and resistances
- Basic attacks contribute to breakdown setup
- Turns every action into team setup

**Growth Curve**:
- **HP**: Gains +2.5 per level (extreme tankiness)
- **Physical**: Gains +1.5 per level (highest scaling)
- **Max Temper**: Gains +2.5 per level (becomes resource monster)
- **Max Ether**: Gains +1.2 per level

**Design Coherence**: NULL BREAKER amplifies Warder's Temper identity to max. It's the only job that can permanently disable Temper as opponent resource, making it essential for late-game defensive pressure.

---

### ETHERWEAVER: Combo Extender & Chain Master

**Core Identity**:
- **Role**: Extends elemental combo chains indefinitely; turns reactions into planned windows
- **Niche**: Only job that can chain elemental reactions beyond normal limits
- **Combat Pacing**: Setup first Arcanist spell → ETHERWEAVER chains 3-4 more → massive reaction explosion

**Unlock**: Arcanist Lv. 5 + Resonant Lv. 3

**Base Stats** (Level 1, scales from Arcanist):
- **HP**: 14 (frail like Arcanist)
- **MP**: 100 (highest in game; fuel for chains)
- **Move**: 3 (backline positioning)
- **Jump**: 2 (ground-locked)
- **Speed**: 6 (standard for casters)
- **Physical**: 15 (irrelevant)
- **Magic**: 75 (strongest magic in game)
- **Physical Resistance**: -10
- **Magic Resistance**: 25 (resists magic better; balances damage)
- **Max Temper**: 20 (irrelevant)
- **Max Ether**: 120 (resource for chaining)
- **Attack Range**: 3

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Tri-Weave** (Combo Chain) - Cast three elemental spells in sequence
   - Each spell triggers reactions automatically
   - Scales damage based on combo count
   - Only job that can chain 3+ spells per turn
   
2. **Ether Bloom** (Resource) - Explodes target elemental surface
   - Creates chained reaction (Fire→Steam→Lightning cascade)
   - Consumes Ether to amplify
   - Extends existing combo chains
   
3. **Reaction Lock** (Control) - Locks next elemental reaction into bonus damage
   - Setup for guaranteed high-damage reaction
   - Makes combo planning reliable
   
4. **Nova Thread** (Finisher) - Chain spell that hits all enemies connected by surfaces
   - Damage increases per surface on field
   - Payoff for multi-turn setup

**Reaction Ability**: Spell Slip
- When hit, automatically cast a free elemental spell
- Enables offense even while taking damage

**Passive**: Extended Chain
- Elemental reactions last +2 turns longer
- Enables multi-turn combo chains
- Only job that stretches combo window

**Growth Curve**:
- **HP**: Gains +0.5 per level (stays frail)
- **MP**: Gains +3 per level (scales casting volume massively)
- **Magic**: Gains +2 per level (strongest scaling)
- **Max Ether**: Gains +2.5 per level (scales chain fuel)

**Design Coherence**: ETHERWEAVER amplifies Arcanist's combo identity. No other job should be able to extend reaction chains or cast multiple elemental spells in one turn. This makes it essential for damage bursts in late game.

---

### PRIMAL BINDER: Summon Master & Guardian Specialist

**Core Identity**:
- **Role**: Commands multiple Guardians; buffs summoned units; enables endurance through rotation
- **Niche**: Only job that can have 2+ Guardians active simultaneously
- **Combat Pacing**: Summon → buff → summon again → manage Guardian health pools for sustained pressure

**Unlock**: Resonant Lv. 6 + 2 freed Guardians

**Base Stats** (Level 1, scales from Resonant):
- **HP**: 26 (medium)
- **MP**: 75 (high; fuels multiple summons)
- **Move**: 4 (standard)
- **Jump**: 3 (modest improvement)
- **Speed**: 7 (standard)
- **Physical**: 28 (weak)
- **Magic**: 65 (strong; boosts Guardian stats)
- **Physical Resistance**: 0
- **Magic Resistance**: 0
- **Max Temper**: 60 (medium)
- **Max Ether**: 130 (highest in game; multiple summons cost resources)
- **Attack Range**: 2

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Primal Call** (Summoning) - Summon two Guardians simultaneously
   - Massive Ether cost but double tempo advantage
   - Guardian stats scale from Primal Binder's Magic
   - Only job that summons 2+ units per ability
   
2. **Anchor Sever** (Crowd Control) - Disrupt enemy positioned Guardian
   - Removes active Guardian from field (resets it)
   - Enables tactical removal of threats
   
3. **Guardian Chorus** (Buff) - All active Guardians gain massive temp stat boost
   - Amplifies multiple Guardians
   - Setup for double-Guardian damage window
   
4. **Grand Resonance** (Finisher) - All Guardians attack simultaneously
   - Massive burst damage from multiple units
   - Payoff for summoning setup

**Reaction Ability**: Guardian Intercept
- When nearby ally hit, a Guardian automatically redirects damage
- Protects team through Guardian sacrifice
- Enables Guardian to absorb lethal hits

**Passive**: Bound Primal
- When two Guardians active, both gain +30% damage
- Mutual defense: if one Guardian takes damage, other gets temp shield
- Rewards Guardian density

**Growth Curve**:
- **HP**: Gains +1.5 per level
- **Magic**: Gains +1.5 per level (scales Guardian potency)
- **Max Ether**: Gains +3 per level (scales summoning ability massively)
- **Speed**: No scaling

**Design Coherence**: PRIMAL BINDER amplifies Resonant's summoning identity. No other job should be able to manage 2+ Guardians or buff summoned units. This makes it essential for endurance-based team compositions.

---

### SERAPH: Healer Protector & Recovery Converter

**Core Identity**:
- **Role**: Turns healing into team-wide protection; converts recovery into offense
- **Niche**: Only job with healing-to-defense conversion; only job with resurrection cooldown reduction
- **Combat Pacing**: Heal → team gets temporary shields → heal again → shields stack for fortress mode

**Unlock**: Luminary Lv. 5 + completed_mirefen_trial

**Base Stats** (Level 1, scales from Luminary):
- **HP**: 24 (vulnerable but better than Luminary)
- **MP**: 100 (highest for healing capacity)
- **Move**: 4 (standard)
- **Jump**: 2 (ground-locked)
- **Speed**: 9 (faster than Luminary; healing faster is better)
- **Physical**: 22 (weak)
- **Magic**: 70 (strong; heals scale from this)
- **Physical Resistance**: -5 (reduced vulnerability)
- **Magic Resistance**: 20 (resists magic better)
- **Max Temper**: 50 (medium; can use some Temper)
- **Max Ether**: 110 (high; cleansing costs scale up)
- **Attack Range**: 3

**Ability Roles** (4 core + 1 reaction + 1 passive):
1. **Seraphic Mend** (Healing) - Large heal + grants team shield
   - Heals primary target
   - All nearby allies gain damage shield
   - Only job that heals and shields in one action
   
2. **Radiant Wall** (Protection) - Creates team-wide damage barrier
   - Prevents damage up to shield amount
   - Lasts until broken
   - Setup for tank phase
   
3. **Cleanse Field** (Area Cleanse) - Removes status from all nearby allies
   - Single ability clears entire team of status
   - Only job with team-wide cleanse
   
4. **Revival Hymn** (Resurrection) - Revive all defeated allies in area
   - Costs massive Ether
   - Only job with AOE resurrection
   - Game-changing ability for clutch saves

**Reaction Ability**: Radiant Reprieve
- When nearby ally nearly dies, automatically grant them massive shield
- Prevents lethal hits reactively

**Passive**: Mercy Engine
- Each heal cast reduces Revival Hymn's cooldown by 1 turn
- Each ally healed extends team shield duration by 1 turn
- Rewards consistent healing (healing patterns enable game-changing revives)

**Growth Curve**:
- **HP**: Gains +1 per level (stays vulnerable)
- **MP**: Gains +2.5 per level (scales healing massively)
- **Magic**: Gains +1.5 per level (heals grow reliably)
- **Speed**: Gains +0.3 per level (stays fastest for healing response)
- **Max Ether**: Gains +2 per level (scales resurrection availability)

**Design Coherence**: SERAPH amplifies Luminary's healing identity. No other job should have team-wide healing, team-wide cleansing, or AOE resurrection. This makes it essential for late-game persistence and clutch survival.

---

## Part 4: Stat Budget & Scaling Framework

### Level Progression Math

**Stat Growth Formula**: `Base_Value + (Growth_per_Level × (Current_Level - 1))`

For example, Warder at Lv. 7:
- HP: 28 + (2 × 6) = 40 HP
- Max Temper: 100 + (1.5 × 6) = 109 Temper

### Job Stat Budgets (Total stat points)

The total stat budget per job must remain roughly equal to ensure no job is mathematically superior.

**Base Job Budget** (allocated across all stats at Lv. 1):
- Warder: 395 points (high HP/Temper emphasis)
- Arcanist: 380 points (high MP/Magic emphasis)
- Resonant: 390 points (balanced, high Ether emphasis)
- Luminary: 380 points (high MP/Magic, low HP)

**Scaling Budget** (points per level):
- Each job gains ~15-16 total stat points per level
- Warder: +15.3 per level
- Arcanist: +14.7 per level
- Resonant: +15.5 per level
- Luminary: +15.2 per level

**Design Principle**: All base jobs should reach approximately 500 total stats at Lv. 11 (endgame).

### Stat Importance Hierarchy

1. **HP / MP / Ether** (Resource pools)
   - Define how many actions a character can take
   - Job identity: WHO can cast what?
   
2. **Physical / Magic** (Damage scalers)
   - Define how much damage a job does
   - Job identity: HOW much impact do their abilities have?
   
3. **Speed** (Turn order)
   - Affects action pacing and reaction timing
   - Lesser stat; most jobs within 1-2 points of each other
   
4. **Movement / Jump** (Positioning)
   - Define tactical flexibility
   - Not primary balance; more about playstyle flavor
   
5. **Resistances** (Defensive tuning)
   - Fine-tuning for balance
   - Never core identity; always secondary

---

## Part 5: Ability Assignment & Growth Curves

### Ability Types & Distribution

**Every job has 4 core abilities + 1 reaction + 1 passive**.

Core abilities should be:
- 1-2 signature abilities (core job mechanic)
- 1-2 utility abilities (positioning, resource management)

**Signature Abilities**:
- Define what only this job can do
- Examples: Temper Stance (Warder), Combo Memory (Arcanist), Summon (Resonant)

**Utility Abilities**:
- Enable the signature abilities to function
- Examples: Mana Flow (convert Temper to Ether), Aura (buff before summoning)

### Ability Cost Scaling

**Cost per ability type**:
- Basic attacks: 0 cost (standard)
- Healing/Support spells: Scale from 10-30 MP (Luminary has range 10-20, Seraph 15-25)
- Offensive spells: Scale from 15-40 MP (Arcanist 15-30, Etherweaver 20-40)
- Summoning: Scale from 20-50 Ether (Resonant 20-30, Primal Binder 30-50)

**Mana cost growth**: Abilities cost more at higher job levels to balance damage growth

---

## Part 6: Balance Checkpoints

### Question 1: Is every job irreplaceable?

For each job, ask: "Can another job do this better?"

- **Warder**: Only job with Temper conversion mechanics. ✅ Irreplaceable.
- **Arcanist**: Only job with combo generation. ✅ Irreplaceable.
- **Resonant**: Only job that summons. ✅ Irreplaceable.
- **Luminary**: Only job with healing + cleansing. ✅ Irreplaceable.
- **Skywarden**: Only job with jump-based offense. ✅ Irreplaceable.
- **Null Breaker**: Only job with defense-breaking. ✅ Irreplaceable.
- **Etherweaver**: Only job that extends combos. ✅ Irreplaceable.
- **Primal Binder**: Only job with multi-Guardian management. ✅ Irreplaceable.
- **Seraph**: Only job with healing→defense conversion + team cleanse. ✅ Irreplaceable.

### Question 2: Does each job have a power curve?

All jobs should be weakest at Lv. 1 and strongest when fully leveled.

- Early game (Lv. 1-3): Base jobs balanced; advanced jobs unavailable
- Mid game (Lv. 4-7): Advanced jobs unlock; new niches open
- Late game (Lv. 8-11): Ascended jobs define endgame (each specialized to extreme)

### Question 3: Do resistances balance damage?

Jobs with weak resistances should either:
- Have higher raw damage output (payoff for risk)
- Have positioning advantage (escape opportunities)
- Have resource advantages (cast more often)

**Examples**:
- Arcanist: Low resistances but high damage + range
- Warder: Low magic resistance but high HP to absorb
- Luminary: Low resistances but highest speed (heals before being hit)

---

## Part 7: Design Coherence Checklist

For each job, verify:

- [ ] **Core identity is clear**: Can you explain the job in one sentence?
- [ ] **Stats support the identity**: Do the growth curves emphasize the main mechanic?
- [ ] **Abilities reinforce identity**: Do all 4 abilities relate to the core role?
- [ ] **Reaction ability fits**: Does the reaction trigger naturally during the job's playstyle?
- [ ] **Passive amplifies identity**: Does the passive make the core mechanic feel stronger?
- [ ] **It's irreplaceable**: Is this the only job that does this?

---

## Summary: Job Identity Matrix

| Job | Core Mechanic | Resource | Key Stat | Unlock | Replaces? |
|-----|---|---|---|---|---|
| **Warder** | Temper defender | Temper | Physical | Base | Nothing (unique) |
| **Arcanist** | Combo generator | Ether | Magic | Base | Nothing (unique) |
| **Resonant** | Guardian summoner | Ether | Magic | Base | Nothing (unique) |
| **Luminary** | Healer/Cleanser | MP/Ether | Magic | Base | Nothing (unique) |
| **Skywarden** | Jump diver | Physical | Jump | Warder Lv.3 | Extends Warder |
| **Null Breaker** | Defense breaker | Temper | Physical | Warder Lv.5 | Replaces Warder (late) |
| **Etherweaver** | Combo extender | Ether | Magic | Arcanist Lv.5 | Extends Arcanist (late) |
| **Primal Binder** | Multi-summoner | Ether | Magic | Resonant Lv.6 | Replaces Resonant (late) |
| **Seraph** | Heal-to-shield | MP/Ether | Magic | Luminary Lv.5 | Replaces Luminary (late) |

---

## Implementation Notes

This document serves as the **single source of truth** for all balance decisions going forward.

When adjusting stats, abilities, or growth curves, check:
1. Does this change violate the job's core identity?
2. Does this make another job less unique?
3. Does this create a dominant strategy where one job is always better?

If the answer to any is "yes," the change should be reconsidered.

This is not final; it's the foundation for iterative balance based on playtesting.
