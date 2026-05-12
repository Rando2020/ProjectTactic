export const DEFAULT_SETTINGS = {
  difficulty: 'normal',
  textSpeed: 'normal',
  reducedMotion: false,
  highContrast: false,
  largeText: false,
  autoSave: true,
  battleSpeed: 'normal',
  showBattleForecast: true,
  confirmEndTurn: true,
  colorblindMode: 'off'
}

export const DIFFICULTY_PRESETS = {
  story: {
    label: 'Story',
    description: 'Lower enemy pressure, forgiving timing windows, designed for narrative flow.',
    enemyDamageMultiplier: 0.75,
    timingWindowMultiplier: 1.3,
    rewardMultiplier: 1
  },
  normal: {
    label: 'Normal',
    description: 'Balanced tactical pressure with the intended timing challenge.',
    enemyDamageMultiplier: 1,
    timingWindowMultiplier: 1,
    rewardMultiplier: 1
  },
  tactical: {
    label: 'Tactical',
    description: 'Stronger enemy pressure, tighter timing, better rewards.',
    enemyDamageMultiplier: 1.18,
    timingWindowMultiplier: 0.88,
    rewardMultiplier: 1.15
  },
  nightmare: {
    label: 'Nightmare',
    description: 'High pressure mode for testing builds, deflects, and turn planning.',
    enemyDamageMultiplier: 1.35,
    timingWindowMultiplier: 0.78,
    rewardMultiplier: 1.25
  }
}

export const COLORBLIND_MODES = [
  { id: 'off', label: 'Off' },
  { id: 'protanopia', label: 'Protanopia support' },
  { id: 'deuteranopia', label: 'Deuteranopia support' },
  { id: 'tritanopia', label: 'Tritanopia support' }
]
