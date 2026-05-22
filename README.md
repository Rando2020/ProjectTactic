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
    │   ├── hubCharacters.js       # Antechamber inhabitants (Greek figures + NPCs)
    │   ├── historicalSouls.js     # Adam, Eve, Cain, Moses, Elijah, David, Job
    │   ├── bossData.js            # Ancient stuck souls with loop-aware dialogue
    │   ├── jobSkills.js           # (from previous session) FFT-style skill DB
    │   └── [other existing data files]
    ├── state/
    │   ├── narrativeState.js      # Initial state + state shape
    │   ├── narrativeReducer.js    # All narrative state transitions
    │   ├── skillReducer.js        # (from previous session)
    │   └── [existing state files]
    └── systems/
        ├── skillSystem.js         # (from previous session)
        └── [existing systems]
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
  // ... your existing cases
}
```

### 3. Begin/end runs

```js
import { narrativeActions } from './state/narrativeReducer.js';

// When a run starts:
dispatch(narrativeActions.beginRun());

// When a run ends:
dispatch(narrativeActions.endRun({
  soulsHelped: 3,
  bossesDefeated: ['the_keeper'],
  bossesFlед: [],
  clarityAtEnd: gameState.narrative.clarity,
  crackEventsThisRun: ['solan'],
  killingBlows: { the_keeper: 'solan' },
}));
```

### 4. Award clarity and revelation

```js
import { CLARITY } from './config/gameConfig.js';

// After a meaningful soul conversation:
dispatch(narrativeActions.gainClarity(CLARITY.SOUL_CONVERSATION, 'soul_met'));
dispatch(narrativeActions.gainRevelation(20, 'soul_adam_early'));

// After a boss talk path:
dispatch(narrativeActions.bossTalkPathComplete('the_righteous_one'));
```

### 5. Track character arc progress

```js
// When a crack event triggers for a character:
dispatch(narrativeActions.triggerCrackEvent('aeryn'));

// When Mnemosyne returns a memory fragment:
dispatch(narrativeActions.returnMemoryFragment('solan', 'The secret of God is presence'));

// When a true name is revealed:
dispatch(narrativeActions.revealTrueName('aeryn', 'Luciel'));

// When a character reaches resolution:
dispatch(narrativeActions.reachResolution('brennan'));
```

### 6. Track boss encounters

```js
// After a boss fight:
dispatch(narrativeActions.bossFightComplete('the_wrathful', 'brennan', gameState.narrative.totalRuns));

// Get loop-aware dialogue for a boss:
import { getBossLoopDialogue } from './data/bossData.js';
const line = getBossLoopDialogue('the_wrathful', gameState.narrative.totalRuns);

// Check if talk path is available:
import { isTalkPathAvailable } from './data/bossData.js';
const canTalk = isTalkPathAvailable('the_wrathful', gameState.narrative);
```

### 7. Check revelation tier

```js
import { REVELATION_TIERS } from './config/gameConfig.js';

// In any component:
const tier = gameState.narrative.revelationTier;

// What to show at each tier:
// TIER_1 — enemies are "demons", no unusual behavior
// TIER_2 — enemies hesitate, partial speech, Archivist starts noticing
// TIER_3 — fallen angels appear, bosses reference the party's history
// TIER_4 — party knows what they are, Mnemosyne opens fully
// TIER_5 — endgame, ascent possible
```

### 8. Character flavor text by tier

```js
import { getCharacter } from './data/characters.js';

const char = getCharacter('aeryn');
const tier = gameState.narrative.revelationTier;
const flavor = char.flavorText[`tier${tier}`];
```

### 9. Hub character dialogue

```js
import { getHubDialogue } from './data/hubCharacters.js';

// Get the current dialogue pool for a hub character:
const hubChar = gameState.narrative.hubCharacters.charon;
const lines = getHubDialogue('charon', hubChar.dialogueTier);
// Pick a line based on conversation count, randomness, or state
```

### 10. Historical soul availability

```js
import { isSoulAvailable, getSoulEncounter } from './data/historicalSouls.js';

// Check if Adam is available to encounter:
const available = isSoulAvailable('adam', gameState.narrative);

// Get the right encounter state for current run count:
const encounter = getSoulEncounter('adam', gameState.narrative.totalRuns);
if (encounter) {
  // show encounter.dialogue
}
```

---

## The Revelation Tier System

| Tier | Name | Points Required | What Changes |
|------|------|----------------|-------------|
| 1 | The War | 0 | Surface layer. Normal tactics game. |
| 2 | The Cracks | 150 | Enemies behave oddly. Archivist uneasy. Boss dialogue deepens. |
| 3 | The Fallen | 400 | Fallen Angels appear. Bosses remember the party. Mnemosyne begins. |
| 4 | The Pattern | 750 | Party knows what they are. Adam/Eve accessible. True names possible. |
| 5 | The Ascent | 1200 | Endgame. Resolution arcs. Loop can end. |

### Revelation Points — Major Sources

| Event | Points |
|-------|--------|
| Soul encounter (first) | 20 |
| Soul encounter (advanced) | 25 |
| Soul departs | 40 |
| Boss talk path complete | 60 |
| Character reaches resolution | 100 |
| Crack event triggered | 30 |
| True name revealed | 50 |
| Archivist learns the truth | 40 |
| Hub character met | 10 |
| Gift given to hub character | 15 |
| Memory fragment returned | 30 |

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

## Hub Character Unlock Conditions

| Character | Available | How |
|-----------|-----------|-----|
| Charon | Run 1 | Always at the dock |
| Persephone | Run 1 | In the courtyard |
| Archivist (Casimir) | Run 1 | In the library corner |
| Nyx | Run 1 | Appears at dusk / low clarity |
| Hemera | Run 1 | Appears after crack events — briefly |
| Hypnos | Run 5 | Found at what passes for night |
| Mnemosyne | Run 1 (Tier 3 to function) | The deep pool — present but silent |
| Hades | Run 10 | Introduced by Persephone |

---

## Boss Quick Reference

| Boss | True Name | Sin Mirror | Character Mirror | Talk Path Character |
|------|-----------|-----------|-----------------|-------------------|
| The Righteous One | Sabriel | Pride | Aeryn | Aeryn (costume ≤40) |
| The Keeper | Vashiel | Sloth | Solan | Solan (costume ≤35) |
| The Devoted | Celestiel | Gluttony | Tobias | Tobias (costume ≤30) |
| The Wrathful | Arariel | Wrath | Brennan | Brennan (costume ≤25) |
| The Mirror | — | Variable | Variable | None — fight only |

---

## Design Principles

**The sin is never attacked directly.**
It is mirrored until the character can see it.

**You can only reach people as far as you've gone yourself.**
Boss talk paths require the mirroring character to have done work on their own arc.

**The loop ends quietly.**
Not with a boss fight. With seven characters putting something down.

**The costume is not fake.**
The practices are real. The discipline is genuine.
The game never says: you were wrong to be this way.
The game asks: what were you protecting? And is it still there?

---

*"As it was in the beginning, is now, and ever shall be."*
*The loop isn't the problem. The loop is the point.*
