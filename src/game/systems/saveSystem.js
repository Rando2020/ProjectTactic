import { STARTING_INVENTORY } from '../data/items.js'
import { STARTING_PARTY_IDS } from '../data/party.js'
import { STARTING_JOB_LEVELS } from '../data/jobs.js'

const SAVE_KEY = 'vaelthar-eidolon-chronicles-save-v1'

export const createNewSave = () => ({
  version: 1,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  playerName: 'Zane',
  currentMode: 'story',
  currentTownId: 'ashvale',
  currentStoryId: 'prologue',
  completedStoryIds: [],
  storyFlags: [],
  unlockedTownIds: ['ashvale'],
  activeQuestIds: ['cracked_bell'],
  completedQuestIds: [],
  completedMissionIds: [],
  partyIds: STARTING_PARTY_IDS,
  jobLevels: STARTING_JOB_LEVELS,
  inventory: STARTING_INVENTORY,
  gold: 120,
  jp: 0,
  restCount: 0,
  playtimeSeconds: 0,
  onboardingComplete: false
})

const normalizeInventory = (inventory) => {
  if (!inventory) return STARTING_INVENTORY
  if (!Array.isArray(inventory)) return inventory

  return inventory.reduce((acc, itemName) => {
    const normalizedId = String(itemName)
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_|_$/g, '')
    acc[normalizedId] = (acc[normalizedId] || 0) + 1
    return acc
  }, {})
}

export const normalizeSave = (save) => {
  if (!save) return null
  return {
    ...createNewSave(),
    ...save,
    partyIds: save.partyIds || STARTING_PARTY_IDS,
    jobLevels: save.jobLevels || STARTING_JOB_LEVELS,
    inventory: normalizeInventory(save.inventory),
    restCount: save.restCount || 0
  }
}

export const loadSave = () => {
  try {
    const raw = window.localStorage.getItem(SAVE_KEY)
    if (!raw) return null
    return normalizeSave(JSON.parse(raw))
  } catch (error) {
    console.warn('Unable to load Vaelthar save.', error)
    return null
  }
}

export const writeSave = (save) => {
  try {
    const nextSave = normalizeSave({ ...save, updatedAt: new Date().toISOString() })
    window.localStorage.setItem(SAVE_KEY, JSON.stringify(nextSave))
    return nextSave
  } catch (error) {
    console.warn('Unable to write Vaelthar save.', error)
    return save
  }
}

export const clearSave = () => {
  try {
    window.localStorage.removeItem(SAVE_KEY)
  } catch (error) {
    console.warn('Unable to clear Vaelthar save.', error)
  }
}
