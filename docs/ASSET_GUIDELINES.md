# Asset Guidelines

## Art direction
Vaelthar should feel like a grounded, darker tactical fantasy RPG with readable battlefield pieces and premium UI restraint.

Target mood:
- Classic tactical RPG readability.
- Dark fantasy materials: stone, copper, glass, shrine ash, marshlight, old banners.
- Original silhouettes and symbols.
- No direct copies of Final Fantasy Tactics, Tactics Ogre, Vagrant Story, or Square Enix-owned assets.

## Placeholder policy
Placeholder assets are allowed when they are:
- Original.
- Generated specifically for this project.
- Licensed CC0 or permissive with attribution tracked.
- Clearly named as placeholders.

## Naming rules
Use lowercase kebab-case.

Examples:
- `zane-idle-placeholder.png`
- `mira-portrait-placeholder.png`
- `null-drake-idle-placeholder.png`
- `shallow-water-tile-placeholder.png`
- `ui-panel-dark-gold-placeholder.png`
- `surge-ring-placeholder.png`

## Folder structure
```txt
src/game/assets/placeholders/
  units/
  portraits/
  tiles/
  icons/
  ui/
  vfx/
  audio/
```

## Tactical readability requirements
- Player units must read as blue/cyan or clearly allied.
- Enemy units must read as red/violet or clearly hostile.
- Movement tiles, attack tiles, danger tiles, and objective tiles must be visually distinct.
- Terrain must be identifiable at small sizes.
- Status icons must be readable without relying only on color.

## Future production asset checklist
- Idle sprite or token.
- Hover/selected state.
- Hit flash or impact state.
- Portrait.
- Small UI icon.
- Accessibility alternate shape/color cue.
