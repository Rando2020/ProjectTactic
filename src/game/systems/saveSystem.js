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
  inventory: ['Vitae Draught'],
  gold: 120,
  jp: 0,
  playtimeSeconds: 0,
  onboardingComplete: false
})

export const loadSave = () => {
  try {
    const raw = window.localStorage.getItem(SAVE_KEY)
    if (!raw) return null
    return JSON.parse(raw)
  } catch (error) {
    console.warn('Unable to load Vaelthar save.', error)
    return null
  }
}

export const writeSave = (save) => {
  try {
    const nextSave = { ...save, updatedAt: new Date().toISOString() }
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
