export const RUN_NODE_TYPES = {
  BATTLE: 'battle',
  ELITE: 'elite',
  EVENT: 'event',
  SHRINE: 'shrine',
  BOSS: 'boss',
}

export const FIRST_RUN_NODES = [
  {
    id: 'ember_road_01',
    type: RUN_NODE_TYPES.BATTLE,
    name: 'Ember Road Skirmish',
    label: 'Battle',
    missionId: 'ashvale_road_01',
    depth: 1,
    nextNodeIds: ['mirefen_choice_01', 'ash_shrine_01'],
    modifierIds: ['emberlit_skies'],
    description: 'A controlled opening fight where the run starts bending the old road toward fire and ash.',
  },
  {
    id: 'mirefen_choice_01',
    type: RUN_NODE_TYPES.BATTLE,
    name: 'Conductive Marsh Route',
    label: 'Battle',
    missionId: 'mirefen_marsh_01',
    depth: 2,
    nextNodeIds: ['null_knight_elite_01'],
    modifierIds: ['charged_water'],
    description: 'A wet battlefield route that rewards thunder setups and punishes careless clustering.',
  },
  {
    id: 'ash_shrine_01',
    type: RUN_NODE_TYPES.SHRINE,
    name: 'Ashen Guardian Shrine',
    label: 'Shrine',
    depth: 2,
    nextNodeIds: ['null_knight_elite_01'],
    modifierIds: ['guardian_whispers'],
    description: 'A non-combat shrine that grants a stronger draft choice before the elite fight.',
  },
  {
    id: 'null_knight_elite_01',
    type: RUN_NODE_TYPES.ELITE,
    name: 'Null Knight Interdiction',
    label: 'Elite',
    missionId: 'mirefen_marsh_01',
    depth: 3,
    nextNodeIds: ['veilscar_event_01'],
    modifierIds: ['void_pressure'],
    description: 'A harder combat node that tests whether the current build can break armor before the field turns hostile.',
  },
  {
    id: 'veilscar_event_01',
    type: RUN_NODE_TYPES.EVENT,
    name: 'Veilscar Memory',
    label: 'Event',
    depth: 4,
    nextNodeIds: ['guardian_boss_01'],
    modifierIds: ['echoing_past'],
    description: 'A run event that trades safety for power and hints at history repeating itself.',
  },
  {
    id: 'guardian_boss_01',
    type: RUN_NODE_TYPES.BOSS,
    name: 'Guardian Echo: The Burning Bell',
    label: 'Boss',
    missionId: 'mirefen_marsh_01',
    depth: 5,
    nextNodeIds: [],
    modifierIds: ['boss_resonance'],
    description: 'The first run capstone. Survive the resonance spike and end the route.',
  },
]

export const FIRST_RUN_NODE_MAP = Object.fromEntries(FIRST_RUN_NODES.map((node) => [node.id, node]))

export function getRunNode(nodeId) {
  return FIRST_RUN_NODE_MAP[nodeId]
}

export function getStartingRunNodeId() {
  return FIRST_RUN_NODES[0].id
}
