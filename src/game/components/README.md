# Game Components

This folder is for React UI components extracted from the prototype.

Recommended modules:

- `BattleScreen.jsx` - primary battle layout.
- `PartyPanel.jsx` - party unit cards and gauges.
- `EnemyPanel.jsx` - enemy cards, bosses, armor bars.
- `SkillMenu.jsx` - actions, skills, item buttons.
- `TimingPrompt.jsx` - SURGE and DEFLECT inputs.
- `CombatLog.jsx` - battle text feed.
- `StatusBadges.jsx` - status icons and tooltips.
- `WaveBanner.jsx` - wave start and victory messaging.

Rule: components should render state. Gameplay math belongs in `systems/`.
