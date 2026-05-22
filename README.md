# The Appointed: As Above
## Project Setup & Integration Guide

---

## The Game

A theological tactical RPG with roguelike elements.

Seven angels, assigned to embody the seven deadly sins,
administer the trials of Purgatory — while being refined by those same trials.

They don't know what they are yet.

The loop isn't punishment. It's the curriculum.

---

## File Structure

```
src/
└── game/
    ├── config/
    │   └── gameConfig.js          # Title, constants, tier definitions, palette
    ├── data/
    │   ├── characters.js          # The Seven — full arcs, dialogue, relationships
    │   ├── hubCharacters.js       # Antechamber inhabitants
    │   ├── historicalSouls.js     # Adam, Eve, Cain, Moses, Elijah, David, Job
    │   ├── bossData.js            # Ancient stuck souls with loop-aware dialogue
    │   └── jobSkills.js           # FFT-style skill database (previous session)
    ├── state/
    │   ├── narrativeState.js      # Initial state + full state shape
    │   ├── narrativeReducer.js    # All narrative state transitions
    │   └── skillReducer.js        # Skill system reducer (previous session)
    └── systems/
        └── skillSystem.js         # Skill logic (previous session)
```

---

## Integration

### 1. Add narrative state to your game state

In `src/game/state/initialGameState.js`:

```js
import { createInitialNarrativeState } from './narrativeState.js';

export const initialGameState = {
  // ... your existing state
  narrative: createInitialNarrativeState(),
};
```

### 2. Wire the narrative reducer

In your main `gameReducer.js` or `progressionReducer.js`:

```js
import { narrativeReducer, NARRATIVE_ACTIONS } from './narrativeReducer.js';

export function gameReducer(state, action) {
  if (Object.values(NARRATIVE_ACTIONS).includes(action.type)) {
    return {
      ...state,
      narrative: narrativeReducer(state.narrative, action),
    };
  }
  // ... existing cases
}
```

### 3. Begin / end runs

```js
import { narrativeActions } from './state/narrativeReducer.js';

// When a run starts:
dispatch(narrativeActions.beginRun());

// When a run ends:
dispatch(narrativeActions.endRun({
  soulsHelped: 3,
  bossesDefeated: ['the_keeper'],
  bossesFled: [],
  clarityAtEnd: gameState.narrative.clarity,
  crackEventsThisRun: ['solan'],
  killingBlows: { the_keeper: 'solan' },
}));
```

### 4. Award clarity and revelation

```js
import { CLARITY } from './config/gameConfig.js';

// After a soul conversation:
dispatch(narrativeActions.gainClarity(CLARITY.SOUL_CONVERSATION, 'soul_met'));
dispatch(narrativeActions.gainRevelation(20, 'soul_adam_early'));

// After a boss talk path completes:
dispatch(narrativeActions.bossTalkPathComplete('the_righteous_one'));
```

### 5. Track character arc progress

```js
// Crack event triggers:
dispatch(narrativeActions.triggerCrackEvent('aeryn'));

// Anamnesis returns a memory fragment:
dispatch(narrativeActions.returnMemoryFragment('solan', 'The secret of God is presence'));

// True name revealed:
dispatch(narrativeActions.revealTrueName('aeryn', 'Luciel'));

// Character reaches resolution:
dispatch(narrativeActions.reachResolution('brennan'));
```

### 6. Boss encounter tracking

```js
// After a fight:
dispatch(narrativeActions.bossFightComplete(
  'the_wrathful', 'brennan', gameState.narrative.totalRuns
));

// Get loop-aware dialogue:
import { getBossLoopDialogue } from './data/bossData.js';
const line = getBossLoopDialogue('the_wrathful', gameState.narrative.totalRuns);

// Check if talk path is available:
import { isTalkPathAvailable } from './data/bossData.js';
const canTalk = isTalkPathAvailable('the_wrathful', gameState.narrative);
```

### 7. Read revelation tier anywhere

```js
import { REVELATION_TIERS } from './config/gameConfig.js';

const tier = gameState.narrative.revelationTier;
// TIER_1 — surface layer, normal tactics game
// TIER_2 — cracks show; enemies behave oddly; Casimir grows uneasy
// TIER_3 — fallen angels appear; bosses reference party history
// TIER_4 — party knows what they are; Anamnesis opens fully
// TIER_5 — endgame; resolution arcs; loop can end
```

### 8. Hub character dialogue

```js
import { getHubDialogue } from './data/hubCharacters.js';

const hubCharState = gameState.narrative.hubCharacters.azrael;
const lines = getHubDialogue('azrael', hubCharState.dialogueTier);
```

### 9. Historical soul availability

```js
import { isSoulAvailable, getSoulEncounter } from './data/historicalSouls.js';

const available = isSoulAvailable('adam', gameState.narrative);
const encounter = getSoulEncounter('adam', gameState.narrative.totalRuns);
if (encounter) {
  // show encounter.dialogue
}
```

---

## The Revelation Tier System

| Tier | Name | Points Required | What Changes |
|------|------|----------------|-------------|
| 1 | The War | 0 | Surface layer. Looks like any tactics game. |
| 2 | The Cracks | 150 | Enemies hesitate. Casimir grows uneasy. Boss dialogue deepens. |
| 3 | The Fallen | 400 | Fallen Angels appear. Bosses remember the party. Anamnesis activates. |
| 4 | The Pattern | 750 | Party knows what they are. Adam/Eve accessible. True names surface. |
| 5 | The Ascent | 1200 | Endgame. Resolution arcs. The loop can end. |

### Revelation Points — Major Sources

| Event | Points |
|-------|--------|
| Soul encounter (first meeting) | 20 |
| Soul encounter (advanced state) | 25 |
| Soul departs | 40 |
| Boss talk path completed | 60 |
| Character reaches resolution | 100 |
| Crack event triggered | 30 |
| True name revealed | 50 |
| Casimir learns the truth | 40 |
| Hub character met | 10 |
| Gift given to hub character | 15 |
| Memory fragment returned by Anamnesis | 30 |

---

## The Seven — Quick Reference

| Human Name | True Name | Sin | Costume | Virtue | Starting Job |
|-----------|-----------|-----|---------|--------|-------------|
| Aeryn | Luciel | Pride | Righteousness | Dignity | Soldier |
| Cael | Zaqiel | Envy | Righteous Advocacy | Justice | Archer |
| Brennan | Camael | Wrath | Holy Zeal | Righteous Anger | Soldier |
| Solan | Raziel | Sloth | Contemplation | Sacred Rest | Mage |
| Mira | Sachiel | Greed | Stewardship | Provision | Vagrant |
| Tobias | Muriel | Gluttony | Bodily Purity | Joy | Cleric |
| Seren | Anael | Lust | Celibacy | Sacred Love | Archer |

---

## Hub Characters — Unlock Conditions

| Character | Tradition | Available | How |
|-----------|-----------|-----------|-----|
| Azrael | Hebrew / Islamic | Run 1 | Always at the dock |
| Ereshkigal | Sumerian | Run 1 | In the courtyard garden |
| Casimir | Original (human) | Run 1 | In the library corner |
| Lilith | Hebrew / Kabbalistic | Run 1 (Tier 3 to approach) | In the dark corners — present but distant |
| Aurora | Roman | Run 1 | Appears briefly after crack events only |
| Somnus | Roman | Run 5 | Found at what passes for night |
| Anamnesis | Greek Theological | Run 1 (Tier 3 to function) | The deep pool — present but silent |
| Osiris | Egyptian | Run 10 | Introduced by Ereshkigal |

---

## Boss Quick Reference

| Boss | True Name | Sin Mirrored | Character Mirror | Talk Path Requirement |
|------|-----------|-------------|-----------------|----------------------|
| The Righteous One | Sabriel | Pride | Aeryn | Aeryn costume ≤ 40, Run 10+ |
| The Keeper | Vashiel | Sloth | Solan | Solan costume ≤ 35, Run 8+ |
| The Devoted | Celestiel | Gluttony | Tobias | Tobias costume ≤ 30, Run 8+ |
| The Wrathful | Arariel | Wrath | Brennan | Brennan costume ≤ 25, Run 12+, Moses met |
| The Mirror | — | Variable | Variable | No talk path — fight only |

---

## The Costume Integrity System

Each character's "costume" — the sanctified version of their sin — has an integrity value (100 → 0).

It starts at 100. It falls through:
- Crack events (-15)
- Mirror encounters (-20)
- Historical soul meetings (-10)
- True name fragments from Anamnesis (-12)
- Deep hub conversations (-8)
- A boss seeing through them (-18)

When costume integrity reaches 0, the true name surfaces.

**The costume is never attacked directly.**
It is mirrored until the character can see it themselves.

---

## Design Principles

**The sin is never attacked directly.**
It is mirrored until the character can finally see it.

**You can only reach people as far as you've gone yourself.**
Boss talk paths require the mirroring character to have done their own work first.

**The loop ends quietly.**
Not with a final boss. With seven characters, one by one, putting something down.

**The costume is not fake.**
The practices are real. The discipline is genuine. The beliefs are sincere.
The game never says: you were wrong to be this way.
The game asks: what were you protecting? Is it still there?

---

## Hub Character Name Reference

These names were chosen deliberately from non-Greek, non-Hades-adjacent traditions:

| Character | Source | Why |
|-----------|--------|-----|
| **Azrael** | Hebrew / Islamic | Angel of accompaniment — fits the game's theology directly |
| **Lilith** | Kabbalistic (apocryphal) | Already in the lore as the third path; predates every system here |
| **Aurora** | Roman | Universal recognition; the name is already a word everyone knows |
| **Ereshkigal** | Sumerian | Oldest queen of the dead in recorded history; more ancient than Greek |
| **Somnus** | Roman | Root of somnambulant, insomnia — players feel they already know him |
| **Osiris** | Egyptian | Judge of the dead who was himself killed, resurrected, and displaced |
| **Anamnesis** | Greek Theological / Catholic Liturgy | Not a god — a sacred concept; the holy remembering used in the Eucharist |

---

*"As it was in the beginning, is now, and ever shall be."*

*The loop isn't the problem. The loop is the point.*

