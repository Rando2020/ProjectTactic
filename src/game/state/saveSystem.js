const SAVE_PREFIX = 'vaelthar:eidolon-chronicles'
const ACTIVE_SLOT_KEY = `${SAVE_PREFIX}:activeSlot`

export const DEFAULT_SAVE_SLOT = 'slot-1'

export function getSaveKey(slotId = DEFAULT_SAVE_SLOT) {
  return `${SAVE_PREFIX}:${slotId}`
}

export function hasSave(slotId = DEFAULT_SAVE_SLOT) {
  try {
    return Boolean(window.localStorage.getItem(getSaveKey(slotId)))
  } catch {
    return false
  }
}

export function saveGame(state, slotId = DEFAULT_SAVE_SLOT) {
  if (typeof window === 'undefined') return false

  const payload = {
    version: 1,
    savedAt: new Date().toISOString(),
    state,
  }

  window.localStorage.setItem(getSaveKey(slotId), JSON.stringify(payload))
  window.localStorage.setItem(ACTIVE_SLOT_KEY, slotId)
  return true
}

export function loadGame(slotId = DEFAULT_SAVE_SLOT) {
  if (typeof window === 'undefined') return null

  const raw = window.localStorage.getItem(getSaveKey(slotId))
  if (!raw) return null

  try {
    const payload = JSON.parse(raw)
    return payload?.state ?? null
  } catch (error) {
    console.warn('Unable to parse save data', error)
    return null
  }
}

export function deleteSave(slotId = DEFAULT_SAVE_SLOT) {
  if (typeof window === 'undefined') return false
  window.localStorage.removeItem(getSaveKey(slotId))
  return true
}

export function getActiveSaveSlot() {
  if (typeof window === 'undefined') return DEFAULT_SAVE_SLOT
  return window.localStorage.getItem(ACTIVE_SLOT_KEY) || DEFAULT_SAVE_SLOT
}
