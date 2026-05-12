export const EQUIPMENT = {
  ashvale_training_sword: {
    id: 'ashvale_training_sword',
    name: 'Ashvale Training Sword',
    slot: 'weapon',
    weaponType: 'sword',
    description: 'A balanced blade used by the Ashvale town watch.',
    stats: { physical: 8 },
    tags: ['starter', 'sword']
  },
  bellkeeper_staff: {
    id: 'bellkeeper_staff',
    name: 'Bellkeeper Staff',
    slot: 'weapon',
    weaponType: 'staff',
    description: 'A shrine staff that hums near fractured Ether.',
    stats: { magic: 8, ether: 12 },
    tags: ['starter', 'staff', 'resonant']
  },
  ironhide_buckler: {
    id: 'ironhide_buckler',
    name: 'Ironhide Buckler',
    slot: 'offhand',
    description: 'A small shield designed for quick guard timing.',
    stats: { temper: 18 },
    tags: ['shield']
  },
  pilgrim_coat: {
    id: 'pilgrim_coat',
    name: 'Pilgrim Coat',
    slot: 'armor',
    description: 'Travel gear reinforced with stitched charm-thread.',
    stats: { hp: 20, ether: 8 },
    tags: ['light_armor']
  },
  stormglass_charm: {
    id: 'stormglass_charm',
    name: 'Stormglass Charm',
    slot: 'accessory',
    description: 'A copper charm that helps the wearer sense the beat before impact.',
    stats: { speed: 1 },
    tags: ['thunder', 'timing']
  }
}

export const STARTING_EQUIPMENT = {
  zane: {
    weapon: 'bellkeeper_staff',
    armor: 'pilgrim_coat',
    accessory: 'stormglass_charm'
  },
  mira: {
    weapon: 'bellkeeper_staff',
    armor: 'pilgrim_coat'
  },
  kael: {
    weapon: 'ashvale_training_sword',
    offhand: 'ironhide_buckler',
    armor: 'pilgrim_coat'
  }
}

export const getEquipment = (equipmentId) => EQUIPMENT[equipmentId]
