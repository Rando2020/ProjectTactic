# Game Systems

This folder is for pure gameplay logic extracted from the prototype.

Recommended modules:

- `combatEngine.js` - damage calculation, healing, armor stripping, KO logic.
- `timingSystem.js` - SURGE, DEFLECT, elemental rhythm windows.
- `statusSystem.js` - status application, ticking, resistance, expiration.
- `comboSystem.js` - combo chain tracking and reaction resolution.
- `progressionSystem.js` - XP, JP, job levels, ascended unlocks.
- `summonSystem.js` - Guardian unlocks, summon resolution, resonance windows.
- `enemyAiSystem.js` - enemy target selection and action selection.

Rule: systems should be testable without rendering React.
