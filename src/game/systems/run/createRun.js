import { getStartingRunNodeId } from '../../data/runNodes.js'

function createRunId() {
  return `run_${Date.now().toString(36)}`
}

export function createRun(seed = 'first-route') {
  const startingNodeId = getStartingRunNodeId()

  return {
    id: createRunId(),
    seed,
    status: 'active',
    currentNodeId: startingNodeId,
    completedNodeIds: [],
    availableNodeIds: [startingNodeId],
    selectedRewardIds: [],
    pendingRewardNodeId: null,
    pendingRewardIds: [],
    activeModifierIds: [],
    echoShardsEarned: 0,
    startedAt: new Date().toISOString(),
    endedAt: null,
  }
}
