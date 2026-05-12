import { getBattleMap } from '../data/maps.js'
import { instantiatePlayerUnit } from '../data/units.js'
import { getLevelFromXp, getUnlockedJobs } from '../data/progression.js'

const STARTING_MISSION_ID = 'ashvale_road_01'

function createCharacterProgression(unit) {
  const character = {
    id: unit.id,
    name: unit.name,
    level: unit.level ?? getLevelFromXp(0),
    xp: 0,
    currentJobId: unit.baseJobId,
    jobJp: {
      [unit.baseJobId]: 30,
    },
    progressionFlags: [],
  }

  return {
    ...character,
    unlockedJobs: getUnlockedJobs(character),
    masteredJobs: [],
    ascendedJobs: [],
  }
}

export function createInitialGameState() {
  const startingMap = getBattleMap(STARTING_MISSION_ID)
  const party = startingMap.playerSpawns
    .map((spawn) => instantiatePlayerUnit(spawn.unitId, spawn))
    .filter(Boolean)

  return {
    version: 1,
    mode: 'world',
    currentScreen: 'worldMap',
    activeMissionId: STARTING_MISSION_ID,
    storyFlags: ['new_game_started'],
    completedMissions: [],
    unlockedMissions: [STARTING_MISSION_ID, 'mirefen_marsh_01'],
    unlockedTowns: ['ashvale_crossing'],
    party,
    roster: party.reduce((characters, unit) => {
      characters[unit.id] = createCharacterProgression(unit)
      return characters
    }, {}),
    inventory: {
      vitae_draught: 2,
      resonance_phial: 1,
      ironcore_shard: 1,
    },
    gold: 250,
    settings: {
      showTileCoordinates: true,
      combatSpeed: 'normal',
      tutorialsEnabled: true,
    },
    lastResult: null,
  }
}

export const INITIAL_GAME_STATE = createInitialGameState()
