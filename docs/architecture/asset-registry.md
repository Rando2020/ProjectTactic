# Asset Registry Architecture

The asset registry gives ProjectTactic one stable place to map gameplay IDs to generated art paths.

This is intentionally lightweight. The first goal is to prevent scattered image imports and root-level asset dumping while the browser prototype and Godot demo evolve in parallel.

## Files

```txt
src/assets/assetRegistry.js
godot/scripts/data/AssetRegistry.gd
```

## What the registry does

The registry maps gameplay concepts to planned asset paths:

- terrain tiles
- surface overlays
- tile highlights
- playable units
- enemies
- UI panels
- command icons
- job icons
- VFX sheets
- Guardian summon illustrations

## What the registry does not do yet

The registry does not load images by itself.

It also does not require every referenced asset file to exist today. The current registry acts as a stable contract for future generated assets.

## Browser usage

Use `src/assets/assetRegistry.js` when React components need stable asset references.

Example:

```js
import { assetRegistry } from '../assets/assetRegistry'

const moveHighlight = assetRegistry.highlights.move
const zanePortrait = assetRegistry.units.zane.portrait
```

## Godot usage

Use `AssetRegistry.gd` when Godot scenes or battle scripts need stable asset paths.

Example:

```gdscript
var zane = AssetRegistry.get_unit("zane")
var portrait_path = zane.get("portrait", "")
```

## Recommended integration order

1. Use tile highlight assets in grid overlays.
2. Use portrait assets in turn order UI.
3. Use idle sprites for player and enemy units.
4. Use command icons in battle command UI.
5. Use elemental VFX sheets in combat resolution.
6. Use Guardian illustrations in ability and summon presentation.

## Naming standard

All generated files should use lowercase kebab-case names.

Examples:

```txt
zane-idle-placeholder.png
null-drake-attack-placeholder.png
tile-move-diamond.png
fire-impact-vfx-sheet.png
```

## Risk

The main risk is adding attractive generated images that do not match tile scale, sprite scale, or UI contrast. Validate assets in the tactical grid before generating a large batch.

## Future evolution

Once assets exist, the registry can evolve to include:

- frame dimensions
- animation frame counts
- atlas coordinates
- load priority
- browser preload hints
- Godot resource metadata
- fallback placeholder colors
