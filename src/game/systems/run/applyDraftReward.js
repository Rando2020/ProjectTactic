import { getRunReward } from '../../data/runRewards.js'

function sumEchoShardEffects(reward) {
  return (reward?.effects ?? [])
    .filter((effect) => effect.type === 'echo_shards')
    .reduce((total, effect) => total + (effect.amount ?? 0), 0)
}

export function applyDraftReward(run, rewardId) {
  const reward = getRunReward(rewardId)
  if (!run || !reward || !run.pendingRewardIds?.includes(rewardId)) return run

  const echoShards = sumEchoShardEffects(reward)

  return {
    ...run,
    status: run.availableNodeIds?.length ? 'active' : run.status,
    selectedRewardIds: Array.from(new Set([...(run.selectedRewardIds ?? []), rewardId])),
    pendingRewardNodeId: null,
    pendingRewardIds: [],
    echoShardsEarned: (run.echoShardsEarned ?? 0) + echoShards,
  }
}
