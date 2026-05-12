export const ITEMS = {
  vitae_draught: {
    id: 'vitae_draught',
    name: 'Vitae Draught',
    type: 'consumable',
    rarity: 'common',
    description: 'Restores 200 HP to one ally.',
    combatUse: 'Single-target recovery',
    value: 60
  },
  resonance_phial: {
    id: 'resonance_phial',
    name: 'Resonance Phial',
    type: 'consumable',
    rarity: 'uncommon',
    description: 'Restores 90 Ether to one ally.',
    combatUse: 'Magic armor recovery',
    value: 90
  },
  ironcore_shard: {
    id: 'ironcore_shard',
    name: 'Ironcore Shard',
    type: 'consumable',
    rarity: 'uncommon',
    description: 'Restores 90 Temper to one ally.',
    combatUse: 'Physical armor recovery',
    value: 90
  },
  soul_ember: {
    id: 'soul_ember',
    name: 'Soul Ember',
    type: 'consumable',
    rarity: 'rare',
    description: 'Revives a KO’d ally at 60% HP.',
    combatUse: 'Emergency revival',
    value: 220
  },
  null_bane: {
    id: 'null_bane',
    name: 'Null Bane',
    type: 'consumable',
    rarity: 'rare',
    description: 'Cleanses all negative status effects from one ally.',
    combatUse: 'Status cleanse',
    value: 180
  }
}

export const STARTING_INVENTORY = {
  vitae_draught: 3,
  resonance_phial: 1,
  ironcore_shard: 1
}

export const getInventoryEntries = (inventory = STARTING_INVENTORY) =>
  Object.entries(inventory)
    .map(([itemId, quantity]) => ({ item: ITEMS[itemId], quantity }))
    .filter((entry) => entry.item && entry.quantity > 0)
