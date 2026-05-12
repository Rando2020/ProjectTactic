# Character Progression, Temper, Ether, and Job Unlocks

This document defines the character-side progression model for **Vaelthar: Eidolon Chronicles**. It is designed to support a tactics RPG structure where character level, job level, armor identity, and ascended class unlocks are all visible from the character screen.

## Design Goals

- Make **Temper** and **Ether** first-class character stats, not hidden combat math.
- Separate **character level** from **job level**, similar to classic tactical RPG progression.
- Let players unlock advanced and ascended jobs through meaningful cross-training.
- Make each ascended class feel like the result of a build path, not a simple rename.
- Make every locked job explain exactly which character level, job level, JP, or story flag is missing.
- Keep the data model usable by React UI, save files, AI balancing tools, and future map-based combat.

---

## Character Sheet Sections

| Section | Fields | Purpose |
|---|---|---|
| Identity | name, portrait, story role | Who the unit is narratively. |
| Progression | level, XP, current job, current job level, current JP, JP to next job level, job levels, job requirements, unlocked jobs, mastered jobs, ascended jobs | Shows character growth and class access. |
| Core Stats | HP, MP, Strength, Mind, Speed, Bravery, Faith | Baseline battle effectiveness. |
| Armor | Temper, max Temper, Ether, max Ether | Physical and magical armor identity. |
| Combat | CT, Limit Gauge, Resonance, known Guardians | Tactical readiness and special resources. |

---

## Temper and Ether

Temper and Ether should appear directly in the character section beside HP and MP.

| Armor | Role | Protects Against | Restored By | Stripped By |
|---|---|---|---|---|
| Temper | Physical armor | Bleed, Knockdown, Slow, Weaken, Berserk | Ironcore Shard, Bulwark, Seraph passive, Warder training | Sunder Strike, Null Breaker passive, heavy physical hits, Earth armor-break effects |
| Ether | Magical armor | Burn, Freeze, Stun, Silence, Curse, Blind | Resonance Phial, Veil, Holy Guardian effects, Etherweaver bonuses | Flare, Dragon fire, Null Echo, Dark drain effects, Shatter reactions |

### Zero Armor Rule

When a target reaches 0 Temper or 0 Ether, attacks against that defense axis gain a **+15% damage bonus** and status effects tied to that defense axis apply at their full base chance.

---

## Character Level System

Character level is based on XP and improves global stats. Job level is separate and based on JP earned while using a class.

| Character Level | XP Required |
|---:|---:|
| 1 | 0 |
| 2 | 100 |
| 3 | 240 |
| 4 | 420 |
| 5 | 650 |
| 6 | 930 |
| 7 | 1260 |
| 8 | 1640 |
| 9 | 2070 |
| 10 | 2550 |
| 15 | 5700 |
| 20 | 10100 |
| 25 | 16150 |
| 30 | 24540 |

Pragmatic balancing note: keep early levels fast so the player unlocks the job system quickly. Slow the curve after level 10 once ascended paths become visible.

---

## Job Leveling Requirements

Job level is based on JP and is tracked **per character per job**. This means Zane can be a Warder Lv. 5 while another character is only Warder Lv. 1.

| Job Level | JP Required | Title | Unlock Meaning |
|---:|---:|---|---|
| 0 | 0 | Untrained | Job can be viewed but has no learned kit. |
| 1 | 30 | Initiate | Job can be equipped. Skill slot 1 becomes available. |
| 2 | 90 | Apprentice | Skill slot 2. First related-job unlocks begin here. |
| 3 | 180 | Adept | Skill slot 3. Hybrid-job requirements begin here. |
| 4 | 320 | Specialist | Skill slot 4. Passive scaling improves. |
| 5 | 520 | Veteran | Main ascended prerequisite tier. |
| 6 | 800 | Master | Mastered job badge. Primal and capstone requirements. |
| 7 | 1200 | Transcendent | Late-game summon and relic scaling. |
| 8 | 1700 | Mythic | Mythic mastery badge and future prestige hooks. |

### JP Award Rules

| Event | Recommended JP |
|---|---:|
| Use an action from the current job | 6 |
| Hit an elemental weakness | 4 |
| Apply a status | 4 |
| Break Temper or Ether | 6 |
| Trigger an elemental combo | 8 |
| Successful Resonance Window | 20 |
| Clear a battle | 18 |
| Clear a boss battle | 35 |

### JP Distribution Rules

| Rule | Value |
|---|---:|
| Active job JP share | 100% |
| Related spillover JP share | 15% |
| Benched unit JP share | 0% for prototype |
| Job mastery level | Lv. 6 |
| Main ascended requirement target | Lv. 5 |
| Capstone ascended requirement target | Lv. 6 |

Best practice: show JP to next level directly on the job panel. The player should never need to guess why a class is locked.

```text
Current Job: Warder Lv. 4, 410 JP
Next: Warder Lv. 5 at 520 JP
Needed: 110 JP
Unlock preview: Null Breaker requires Warder Lv. 5, Skywarden Lv. 2, Oathbound Lv. 2
```

---

## Base Jobs

| Job | Unlock Requirement | Ascends To | Role |
|---|---|---|---|
| Warder | Character Lv. 1 | Null Breaker | Frontline physical defender |
| Arcanist | Character Lv. 1 | Etherweaver | Elemental spell attacker |
| Resonant | Character Lv. 1 | Primal Binder | Guardian binder and summon specialist |
| Luminary | Character Lv. 1 | Seraph | Healer and armor restorer |
| Skywarden | Character Lv. 4, Warder Lv. 2 | Drake Ascendant | Mobile aerial striker |
| Chronist | Character Lv. 4, Arcanist Lv. 2 | Time Sovereign | CT and turn-order manipulator |
| Oathbound | Character Lv. 6, Warder Lv. 2, Luminary Lv. 2 | Aegis Vow | Paladin protector |
| Voidcaller | Character Lv. 6, Arcanist Lv. 3, Resonant Lv. 1 | Abyssal Magister | Dark caster and Ether breaker |
| Null Resonant | Character Lv. 10, Resonant Lv. 3, Voidcaller Lv. 2 | Eclipse Harbinger | Hybrid Resonance and Null class |

---

## Ascended Jobs

| Ascended Job | Base Job | Unlock Requirement | Passive |
|---|---|---|---|
| Null Breaker | Warder | Character Lv. 12, Warder Lv. 5, Skywarden Lv. 2, Oathbound Lv. 2 | Physical hits strip 18 Temper before damage. |
| Etherweaver | Arcanist | Character Lv. 12, Arcanist Lv. 5, Chronist Lv. 3, Voidcaller Lv. 2 | Combo chain window increases from 7 seconds to 10 seconds. |
| Primal Binder | Resonant | Character Lv. 14, Resonant Lv. 6, Luminary Lv. 2, Voidcaller Lv. 2, freed any Primal Guardian | Summons gain +20% power and +10% Resonance success. |
| Seraph | Luminary | Character Lv. 12, Luminary Lv. 5, Resonant Lv. 2, Oathbound Lv. 3 | Healing restores 35 Temper and 35 Ether. |
| Drake Ascendant | Skywarden | Character Lv. 12, Skywarden Lv. 5, Warder Lv. 3, Arcanist Lv. 2 | Jump and dive skills ignore 25% Temper. Fire-aligned dives strip Ether. |
| Time Sovereign | Chronist | Character Lv. 13, Chronist Lv. 5, Arcanist Lv. 3, Resonant Lv. 2 | Excess CT above 100 converts to next-action power. |
| Aegis Vow | Oathbound | Character Lv. 13, Oathbound Lv. 5, Warder Lv. 3, Luminary Lv. 3 | Allies gain bonus starting Temper from this unit. |
| Abyssal Magister | Voidcaller | Character Lv. 14, Voidcaller Lv. 5, Arcanist Lv. 3, Null Resonant Lv. 3 | Dark and Null skills drain Ether and convert part to caster Ether. |
| Eclipse Harbinger | Null Resonant | Character Lv. 18, Null Resonant Lv. 6, Voidcaller Lv. 4, Resonant Lv. 4, freed Vaelthorn | Holy and Dark actions extend combos and increase Limit gain. |

---

## Job Requirement Display Rules

The character UI should show locked jobs with concrete missing requirements.

### Example: Null Breaker Locked

```text
Null Breaker
Status: Locked
Requires:
- Character Lv. 12, current Lv. 10
- Warder Lv. 5, current Lv. 4, 110 JP needed
- Skywarden Lv. 2, current Lv. 1, 48 JP needed
- Oathbound Lv. 2, current Lv. 0, 90 JP needed
```

### Example: Etherweaver Ready

```text
Etherweaver
Status: Ready to unlock
Requirements met:
- Character Lv. 12
- Arcanist Lv. 5
- Chronist Lv. 3
- Voidcaller Lv. 2
```

---

## Unlock Philosophy

### Best Practice

Ascended jobs should require at least one lateral class, not only the base class. This makes the player engage with the job board and creates identity through cross-training.

Example:

```text
Warder Lv. 5 alone should not unlock Null Breaker.
Null Breaker should require Warder Lv. 5 + Skywarden Lv. 2 + Oathbound Lv. 2.
```

### Pragmatic Workaround

For the first playable prototype, allow ascended jobs to unlock with the main job requirement only, but display the full cross-training requirements as coming soon. That avoids blocking gameplay while the JP economy is still being tuned.

---

## Data Implementation

The canonical data lives in:

```text
src/game/data/progression.js
```

Use that file for:

- character sheet rendering
- job unlock checks
- ascended class availability
- armor cap calculations
- save file validation
- future map editor balancing
- JP to next job level calculations
- locked job requirement summaries
- unlock previews from a source job

Key exports:

```text
JOB_LEVEL_TABLE
JOB_LEVELING_REQUIREMENTS
JOB_UNLOCK_REQUIREMENTS
JOB_LEVEL_REQUIREMENT_MATRIX
getJobProgress(character, jobId)
getJobRequirementSummary(character, jobId)
getJobUnlockPreview(character, sourceJobId)
getLockedJobRequirements(character, jobId)
```

---

## Next Integration Target

The next code step should be to wire `progression.js` into the React character UI so every unit displays:

- Character Level
- XP to next level
- current Job
- Job Level
- JP to next job level
- Temper and Ether bars
- locked ascended class requirements
- unlocked ascended class badge
