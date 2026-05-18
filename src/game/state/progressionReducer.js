import {
  getLevelFromXp,
  getUnlockedJobs,
  getAscendedJobs,
  getJobLevelFromJp,
} from '../data/progression.js'

export function applyMissionRewards(state, mission) {
  const rewards = mission?.rewards ?? {}
  const jpReward = rewards.jp ?? 0
  const xpReward = rewards.xp ?? Math.max(50, jpReward * 2)
  const battleJp = rewards.battleJp ?? {}
  const clearBonus = rewards.clearBonus ?? 0

  const roster = Object.fromEntries(
    Object.entries(state.roster).map(([characterId, character]) => {
      const currentJobId = character.currentJobId
      const earnedBattleJp = battleJp[characterId] ?? 0
      const totalJobJpAward = jpReward + earnedBattleJp + clearBonus
      const nextXp = (character.xp ?? 0) + xpReward
      const nextJobJp = {
        ...(character.jobJp ?? {}),
        [currentJobId]: (character.jobJp?.[currentJobId] ?? 0) + totalJobJpAward,
      }
      const nextCharacter = {
        ...character,
        xp: nextXp,
        level: getLevelFromXp(nextXp),
        jobJp: nextJobJp,
        progressionFlags: Array.from(new Set([
          ...(character.progressionFlags ?? []),
          ...(rewards.flags ?? []),
        ])),
      }

      return [characterId, {
        ...nextCharacter,
        unlockedJobs: getUnlockedJobs(nextCharacter),
        ascendedJobs: getAscendedJobs(nextCharacter),
        masteredJobs: Object.entries(nextJobJp)
          .filter(([, jp]) => getJobLevelFromJp(jp) >= 6)
          .map(([jobId]) => jobId),
      }]
    })
  )

  const inventory = { ...state.inventory }
  ;(rewards.items ?? []).forEach((itemId) => {
    inventory[itemId] = (inventory[itemId] ?? 0) + 1
  })

  return {
    ...state,
    roster,
    inventory,
    gold: (state.gold ?? 0) + (rewards.gold ?? 0),
    completedMissions: Array.from(new Set([...state.completedMissions, mission.id])),
    storyFlags: Array.from(new Set([...state.storyFlags, ...(rewards.flags ?? [])])),
    lastResult: {
      missionId: mission.id,
      missionName: mission.name,
      rewards: {
        xp: xpReward,
        jp: jpReward,
        battleJp,
        clearBonus,
        totalJpByCharacter: Object.fromEntries(
          Object.keys(state.roster).map((characterId) => [
            characterId,
            jpReward + (battleJp[characterId] ?? 0) + clearBonus,
          ])
        ),
        gold: rewards.gold ?? 0,
        items: rewards.items ?? [],
        flags: rewards.flags ?? [],
      },
    },
    currentScreen: 'results',
  }
}

export function changeCharacterJob(state, characterId, jobId) {
  const character = state.roster?.[characterId]
  if (!character || !(character.unlockedJobs ?? []).includes(jobId)) return state

  return {
    ...state,
    roster: {
      ...state.roster,
      [characterId]: {
        ...character,
        currentJobId: jobId,
      },
    },
  }
}
