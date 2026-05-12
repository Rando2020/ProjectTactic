import { getMission } from '../data/missions.js'

const itemNameToId = (itemName) =>
  String(itemName)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')

const addItemsToInventory = (inventory = {}, items = []) => {
  const nextInventory = { ...inventory }
  items.forEach((itemName) => {
    const itemId = itemNameToId(itemName)
    nextInventory[itemId] = (nextInventory[itemId] || 0) + 1
  })
  return nextInventory
}

export const buildMissionResult = (missionId, outcome = {}) => {
  const mission = getMission(missionId)
  if (!mission) {
    return {
      missionId,
      status: 'invalid',
      victory: false,
      title: 'Unknown Mission',
      objective: 'Mission data missing.',
      bonusObjectives: [],
      completedBonusObjectives: [],
      rewards: { jp: 0, gold: 0, items: [] },
      unlocks: { flags: [], townIds: [], questIds: [] },
      summary: 'No mission metadata was found.'
    }
  }

  const victory = outcome.victory !== false
  const completedBonusObjectives = victory
    ? outcome.completedBonusObjectives || mission.bonusObjectives.slice(0, 2)
    : outcome.completedBonusObjectives || []

  const bonusCompletionRate = mission.bonusObjectives.length
    ? completedBonusObjectives.length / mission.bonusObjectives.length
    : 0

  const rewardMultiplier = victory ? 1 + bonusCompletionRate * 0.15 : 0

  const rewards = {
    jp: Math.round((mission.rewards?.jp || 0) * rewardMultiplier),
    gold: Math.round((mission.rewards?.gold || 0) * rewardMultiplier),
    items: victory ? mission.rewards?.items || [] : []
  }

  return {
    missionId: mission.id,
    questId: mission.questId,
    status: victory ? 'victory' : 'defeat',
    victory,
    title: mission.title,
    subtitle: mission.subtitle,
    objective: mission.objective,
    difficulty: mission.difficulty,
    recommendedLevel: mission.recommendedLevel,
    bonusObjectives: mission.bonusObjectives,
    completedBonusObjectives,
    rewards,
    unlocks: victory
      ? {
          flags: mission.unlockFlagsOnComplete || [],
          townIds: mission.unlockTownIdsOnComplete || [],
          questIds: mission.unlockQuestIdsOnComplete || []
        }
      : {
          flags: [],
          townIds: [],
          questIds: []
        },
    summary: victory
      ? 'Mission cleared. Rewards and progression unlocks are ready to apply.'
      : 'Mission failed. No progression unlocks will be applied.'
  }
}

export const applyMissionResult = (save, result) => {
  if (!result?.victory) return save

  return {
    ...save,
    storyFlags: [...new Set([...save.storyFlags, ...result.unlocks.flags])],
    unlockedTownIds: [...new Set([...save.unlockedTownIds, ...result.unlocks.townIds])],
    activeQuestIds: [...new Set([...save.activeQuestIds, ...result.unlocks.questIds])],
    completedQuestIds: result.questId
      ? [...new Set([...save.completedQuestIds, result.questId])]
      : save.completedQuestIds,
    completedMissionIds: [...new Set([...save.completedMissionIds, result.missionId])],
    jp: save.jp + result.rewards.jp,
    gold: save.gold + result.rewards.gold,
    inventory: addItemsToInventory(save.inventory, result.rewards.items)
  }
}
