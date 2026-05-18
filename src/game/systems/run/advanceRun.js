import { getRunNode } from '../../data/runNodes.js'
import { getRewardDraftForNode } from '../../data/runRewards.js'

export function selectRunNode(run, nodeId) {
  const node = getRunNode(nodeId)
  if (!run || !node || !run.availableNodeIds.includes(nodeId)) return run

  return {
    ...run,
    currentNodeId: nodeId,
    activeModifierIds: Array.from(new Set([...(run.activeModifierIds ?? []), ...(node.modifierIds ?? [])])),
  }
}

export function completeRunNode(run, nodeId) {
  const node = getRunNode(nodeId)
  if (!run || !node) return run

  const rewardDraft = getRewardDraftForNode(node)
  const completedNodeIds = Array.from(new Set([...(run.completedNodeIds ?? []), nodeId]))
  const nextNodeIds = node.nextNodeIds ?? []
  const isComplete = nextNodeIds.length === 0

  return {
    ...run,
    status: isComplete ? 'complete' : 'reward',
    completedNodeIds,
    availableNodeIds: isComplete ? [] : nextNodeIds,
    pendingRewardNodeId: nodeId,
    pendingRewardIds: rewardDraft.map((reward) => reward.id),
    endedAt: isComplete ? new Date().toISOString() : run.endedAt,
  }
}

export function skipRunReward(run) {
  if (!run) return run

  return {
    ...run,
    status: run.availableNodeIds?.length ? 'active' : run.status,
    pendingRewardNodeId: null,
    pendingRewardIds: [],
  }
}
