# Asset Prompt Library

This folder contains the source prompts for ProjectTactic placeholder and production-direction assets.

The goal is not to copy any existing tactical RPG asset set. The goal is to create legally safe, original assets that fit the game direction: browser-first tactical RPG, darker grounded fantasy mood, readable isometric combat, and scalable asset organization.

## Current prompt files

- `tilesets-terrain.md` covers terrain tiles, elevation pieces, water, shrine tiles, and surface state overlays.
- `characters-player-units.md` covers Zane, Mira, and Kael with idle poses, action poses, and UI portraits.
- `characters-enemies.md` covers Null Drake, Storm Imp, and Fen Wraith with idle and attack poses.
- `ui-panels-hud.md` covers HUD chrome, command UI, turn order sidebar, tile highlights, and resource bars.
- `ui-job-icons-vfx.md` covers job icons, elemental VFX, damage floats, and Guardian summon illustrations.

## Recommended output locations

Generated assets should use lowercase kebab-case names and should land in the appropriate asset folders.

```txt
src/assets/tiles/
src/assets/characters/
src/assets/ui/
src/assets/vfx/
src/assets/icons/
godot/assets/tiles/
godot/assets/characters/
godot/assets/ui/
godot/assets/vfx/
godot/assets/icons/
```

## Naming rules

Use descriptive lowercase kebab-case filenames.

Examples:

```txt
grass-tile-placeholder.png
stone-road-tile-placeholder.png
zane-idle-placeholder.png
mira-attack-placeholder.png
null-drake-idle-placeholder.png
ui-command-attack-icon.png
fire-impact-vfx-sheet.png
```

## Production rule

Every generated asset should be tracked against three things:

1. Source prompt file
2. Intended in-game use
3. Final file path

This keeps the browser prototype and Godot demo aligned as the project grows.
