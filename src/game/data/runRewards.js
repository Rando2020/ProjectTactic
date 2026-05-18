export const RUN_REWARD_TYPES = {
  BOON: 'boon',
  RELIC: 'relic',
  PACT: 'pact',
  RESOURCE: 'resource',
}

export const RUN_REWARDS = {
  emberwake: {
    id: 'emberwake',
    type: RUN_REWARD_TYPES.BOON,
    name: 'Emberwake',
    element: 'fire',
    rarity: 'common',
    summary: 'Fire abilities leave pressure behind.',
    description: 'Your first fire action each battle gains +10% damage. Future work should also leave burning terrain behind the target.',
    effects: [{ type: 'damage_bonus', element: 'fire', amount: 0.1, oncePerBattle: true }],
  },
  stormthread: {
    id: 'stormthread',
    type: RUN_REWARD_TYPES.BOON,
    name: 'Stormthread',
    element: 'thunder',
    rarity: 'common',
    summary: 'Thunder rewards wet terrain setups.',
    description: 'Thunder actions gain +1 action JP. Future work should increase damage against targets standing on wet or electrified tiles.',
    effects: [{ type: 'bonus_action_jp', element: 'thunder', amount: 1 }],
  },
  glassbound_edge: {
    id: 'glassbound_edge',
    type: RUN_REWARD_TYPES.RELIC,
    name: 'Glassbound Edge',
    element: 'physical',
    rarity: 'uncommon',
    summary: 'Armor breaks matter more.',
    description: 'Breaking Temper grants +5 run gold now. Future work should trigger splash damage when Temper is broken.',
    effects: [{ type: 'temper_break_gold', amount: 5 }],
  },
  guardian_oath_first_flame: {
    id: 'guardian_oath_first_flame',
    type: RUN_REWARD_TYPES.PACT,
    name: 'Guardian Oath: First Flame',
    element: 'guardian',
    rarity: 'rare',
    summary: 'SURGE becomes a build engine.',
    description: 'The first successful SURGE each battle grants +2 action JP. Future work should also increase Guardian resonance.',
    effects: [{ type: 'surge_bonus_jp', amount: 2, oncePerBattle: true }],
  },
  echo_shards_cache: {
    id: 'echo_shards_cache',
    type: RUN_REWARD_TYPES.RESOURCE,
    name: 'Echo Shard Cache',
    element: 'meta',
    rarity: 'common',
    summary: 'Meta-progression currency.',
    description: 'Gain +2 Echo Shards at the end of the run.',
    effects: [{ type: 'echo_shards', amount: 2 }],
  },
  void_bargain: {
    id: 'void_bargain',
    type: RUN_REWARD_TYPES.PACT,
    name: 'Void Bargain',
    element: 'void',
    rarity: 'rare',
    summary: 'More reward, more danger.',
    description: 'Gain +4 Echo Shards at run end. Future work should add enemy speed or void pressure during battles.',
    effects: [{ type: 'echo_shards', amount: 4 }, { type: 'future_enemy_speed_bonus', amount: 1 }],
  },
}

export const DEFAULT_REWARD_DRAFT = ['emberwake', 'stormthread', 'glassbound_edge']
export const SHRINE_REWARD_DRAFT = ['guardian_oath_first_flame', 'echo_shards_cache', 'void_bargain']
export const ELITE_REWARD_DRAFT = ['glassbound_edge', 'guardian_oath_first_flame', 'void_bargain']

export function getRunReward(rewardId) {
  return RUN_REWARDS[rewardId]
}

export function getRewardDraftForNode(node) {
  if (node?.type === 'shrine') return SHRINE_REWARD_DRAFT.map(getRunReward)
  if (node?.type === 'elite' || node?.type === 'boss') return ELITE_REWARD_DRAFT.map(getRunReward)
  return DEFAULT_REWARD_DRAFT.map(getRunReward)
}
