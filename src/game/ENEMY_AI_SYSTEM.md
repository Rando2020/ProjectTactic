# Enemy AI & Intent Validation System

## Overview

This document describes the enemy AI decision-making system and how it ensures that enemy intent previews (shown to players) match the actual actions enemies take. **Player trust depends on this accuracy.**

---

## Enemy Variety

### Current Enemy Types (6 total)

#### Tanks/Bruisers
- **Null Drake** - Aggressive bruiser, high Temper, melee attacker
- **Void Golem** - Slow tank, highest armor/HP, defensive

#### Healers
- **Void Vessel** - Defensive healer, MP-focused, supports allies

#### Casters/Disruptors
- **Storm Imp** - Fast ranged disruptor, uses thunder spells
- **Fen Wraith** - Terrain caster, exploits environmental combos
- **Null Mage** - Spell-focused elemental caster, fire element

#### Physical DPS
- **Void Mantis** - Glass cannon, highest physical damage, high jump

### Ability Distribution

Each enemy has 3-4 abilities:
- All have `basic_attack`
- At least 1 special ability (spell or technique)
- Healers have 2-3 healing/support abilities
- Casters have 3-4 different spell types

---

## AI Decision Making

### AI Profiles

Each enemy uses one of 7 AI profiles that define their strategy:

#### 1. **aggressive_bruiser**
- Charges enemies, prefers high-damage abilities
- Target selection: Closest enemy
- Ability preference: `power_slash` (burst damage)
- Examples: Null Drake

#### 2. **ranged_disruptor**
- Stays at range, uses crowd control
- Target selection: Closest enemy (range advantage)
- Ability preference: `spark_chain` (AoE disruption)
- Examples: Storm Imp

#### 3. **terrain_caster**
- Uses environmental effects flexibly
- Target selection: By threat level
- Ability preference: Any available spell (cycled)
- Examples: Fen Wraith

#### 4. **slow_tank**
- Holds position, defensive
- Target selection: Closest enemy
- Ability preference: `sunder_strike` (armor breaking)
- Movement: Only moves if out of attack range
- Examples: Void Golem

#### 5. **defensive_healer**
- Prioritizes ally healing over offense
- Target selection: Wounded ally first, then closest enemy
- Ability preference: Healing spells when ally is wounded
- Special behavior: Uses `protect` when own HP < 50%
- Examples: Void Vessel

#### 6. **aggressive_dps**
- All-in damage, targets weakest enemy
- Target selection: Lowest HP (eliminate fast)
- Ability preference: Burst abilities (`double_strike`, `power_slash`)
- Examples: Void Mantis

#### 7. **spell_focused**
- Prioritizes spell usage over physical
- Target selection: By threat level
- Ability preference: Elemental spells (fire, ice, thunder)
- Examples: Null Mage

---

## Intent Validation (Critical!)

### How It Works

The intent validation system ensures that what the UI promises matches what actually happens:

```javascript
// In aiController.js

// 1. chooseEnemyAction() - Decides what the enemy will DO
export function chooseEnemyAction({ map, grid, units, unit }) {
  // Returns the ACTUAL action to execute
}

// 2. previewEnemyIntent() - Shows what the enemy WILL do
export function previewEnemyIntent({ map, grid, units, unit }) {
  // Calls chooseEnemyAction() and formats the result
  // Must return identical action data
}

// 3. validateEnemyIntent() - VERIFIES they match (development use)
export function validateEnemyIntent({ map, grid, units, unit }) {
  // Compares intent vs actual action
  // Logs warnings if they differ
}
```

### Key Principle

**`previewEnemyIntent()` MUST call `chooseEnemyAction()` internally.** This ensures the preview and actual action are always identical.

```javascript
export function previewEnemyIntent({ map, grid, units, unit }) {
  const action = chooseEnemyAction({ map, grid, units, unit })  // ← Same logic!
  
  // Just format the action for display
  if (action.type === 'ability') {
    return {
      label: `${unit.name} will cast ${ability.name}...`,
      action  // Return the exact same action data
    }
  }
  // ...
}
```

### Validation in Development

Use this to catch mismatches during development:

```javascript
// In BattleScreen.jsx or development tools
const validation = validateEnemyIntent({ map, gridRef.current, units: unitsRef.current, unit })

if (!validation.isValid) {
  console.error('Intent mismatch detected:', validation)
  // This indicates a bug in the AI system
}
```

---

## Strategy Decision Flow

### For Each Enemy Turn:

1. **Select Target**
   - Profile-specific logic (closest, weakest, threat-based, etc.)
   - Healers check for wounded allies first

2. **Check for Special Actions**
   - Healers: Can switch to ally if wounded
   - Tanks: Can choose to stay/move based on range
   - Casters: Can cycle through different spells

3. **Select Ability**
   - Profile preference (e.g., bruiser wants power_slash)
   - Check MP availability
   - Fall back to basic_attack if unable

4. **Check Range**
   - If in range → Use ability on target
   - If out of range → Move closer
   - If can't move → Wait

5. **Return Action**
   - Type: `move`, `ability`, or `wait`
   - All data needed for execution
   - All data shown in intent preview

---

## Enemy Compositions

### Balanced Team Compositions (by difficulty)

**Easy:**
- Single enemy
- Or weak pairing (2 basic types)

**Normal:**
- 2-3 enemies with role diversity
- Examples:
  - Tank + Healer + DPS
  - Caster + Bruiser
  - Healer + Mage + Support

**Hard:**
- 4 enemies with strong synergy
- Examples:
  - Healer + Tank + Caster + DPS
  - Double Mage + Support + Tank

**Extreme:**
- 3-4 enemies all high-damage
- Limited healing, high pressure

### Usage

```javascript
// In mission setup
const difficulty = 'normal'
const enemyIds = generateEnemyComposition(difficulty)
const enemies = enemyIds.map(id => instantiateEnemy(id, { x, y }))
```

---

## Adding New Enemy Types

### Step 1: Define the Enemy

```javascript
// In enemies.js
export const ENEMIES = {
  new_enemy: {
    id: 'new_enemy',
    name: 'New Enemy Name',
    faction: 'void',
    role: 'Description',
    aiProfile: 'aggressive_bruiser',  // Pick a profile
    level: 2,
    stats: { hp: 200, mp: 80, ... },
    affinities: ['element'],
    weaknesses: ['element'],
    abilities: ['basic_attack', 'ability_id_1', 'ability_id_2'],
    sprite: '/path/to/sprite.png',
    drops: { gold: 50, jp: 15, items: [] }
  }
}
```

### Step 2: Create Abilities (if needed)

```javascript
// In abilities.js
export const ABILITIES = {
  new_ability: {
    id: 'new_ability',
    name: 'Ability Name',
    type: 'magic' | 'physical' | 'support' | 'heal',
    element: 'fire' | 'ice' | 'thunder' | 'water' | 'earth' | 'holy' | 'dark' | 'none',
    mpCost: 20,
    power: 100,
    range: { min: 1, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'enemy' | 'ally' | 'enemy_or_tile' | 'objective',
    timingProfile: 'none',
    effects: [{ type: 'damage', amount: 100 }]
  }
}
```

### Step 3: Pick/Create AI Profile (if needed)

Most enemies use existing profiles. If you need a new one:

```javascript
// In aiController.js
const AI_PROFILES = {
  new_profile: {
    selectTarget: (unit, allies, enemies) => { /* logic */ },
    selectAbility: (unit, target, enemies, allies) => { /* logic */ },
    shouldHeal: (unit, allies) => { /* logic */ },
    description: 'Strategy description'
  }
}
```

### Step 4: Add to Compositions

```javascript
// In enemies.js
export function generateEnemyComposition(difficulty = 'normal') {
  const compositions = {
    normal: [
      ['new_enemy', 'null_drake'],  // Add your composition
      // ...
    ]
  }
}
```

---

## Testing & Validation

### Development Checklist

- [ ] Enemy has 3-4 unique abilities (not just basic_attack)
- [ ] AI profile matches the enemy's role
- [ ] Abilities all exist in ABILITIES constant
- [ ] Intent validation passes: `validateEnemyIntent()` returns isValid=true
- [ ] Enemy appears in at least one composition
- [ ] Intent text is clear and accurate
- [ ] Target selection makes strategic sense

### Runtime Validation

During battles, add to BattleScreen:

```javascript
// Optional development check
if (gameState.settings?.debugAI && phase === PHASE.ENEMY_TURN) {
  const validation = validateEnemyIntent({ map: activeMission, grid: gridRef.current, units: unitsRef.current, unit: activeUnit })
  if (!validation.isValid) {
    console.warn(`AI mismatch for ${activeUnit.name}:`, validation)
  }
}
```

---

## Common Issues & Fixes

### Issue: Intent says ability but enemy uses basic_attack

**Cause:** Insufficient MP or ability not in unit.abilities

**Fix:** 
1. Check ability mpCost vs enemy.stats.mp
2. Verify ability name in unit.abilities array
3. Ensure ability exists in ABILITIES

### Issue: Intent shows wrong target

**Cause:** Target selection logic changed but intent preview didn't update

**Fix:**
1. Ensure previewEnemyIntent() calls chooseEnemyAction()
2. Run validateEnemyIntent() to catch the mismatch
3. Align target selection logic in both functions

### Issue: Enemy never heals

**Cause:** AI profile isn't defensive_healer or shouldHeal logic is wrong

**Fix:**
1. Check aiProfile value
2. Verify shouldHeal() returns true when allies < 70% HP
3. Verify healing abilities exist in unit.abilities

---

## Notes for Implementation

- **Trust is Everything**: Players immediately lose trust if the UI lies about intent
- **Deterministic**: chooseEnemyAction must produce same result each time for same state
- **Profiled**: Each enemy type has a distinct playstyle through AI profiles
- **Balanced**: Enemy compositions ensure variety, not pure overwhelming damage
- **Testable**: validateEnemyIntent() catches mismatches during development

Keep the intent validation tight and the strategy profiles clear. This is the foundation of player trust in the battle system.
