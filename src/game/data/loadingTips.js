export const LOADING_TIPS = [
  {
    id: 'surge',
    title: 'SURGE timing',
    body: 'Elemental skills have different rhythms. Thunder asks for fast taps. Ice asks for patience.'
  },
  {
    id: 'deflect',
    title: 'DEFLECT windows',
    body: 'Enemy tells are not just flair. Watch the warning pulse and DEFLECT to cut incoming damage.'
  },
  {
    id: 'wet',
    title: 'Wet reactions',
    body: 'Wet enemies are vulnerable to Ice and Thunder reactions. Freeze or Electrify before they can reposition.'
  },
  {
    id: 'armor',
    title: 'Temper and Ether',
    body: 'Temper protects against physical pressure. Ether protects against magical pressure and many status effects.'
  },
  {
    id: 'mission_board',
    title: 'Mission board',
    body: 'Check objectives before battle. Bonus objectives are designed to teach tactics, not just reward perfection.'
  },
  {
    id: 'accessibility',
    title: 'Readable by default',
    body: 'Use Settings to toggle larger text, high contrast, reduced motion, and colorblind support placeholders.'
  },
  {
    id: 'resonance',
    title: 'Do not just kill Guardians',
    body: 'Corrupted Guardians can sometimes be reached through a Resonance Window. Saving them changes rewards and story flags.'
  }
]

export const getRandomLoadingTip = () =>
  LOADING_TIPS[Math.floor(Math.random() * LOADING_TIPS.length)]
