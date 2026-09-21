# Tileset: Forgotten Field v01

- Asset ID: `environment-forgotten-field`
- Intended use: first Godot vertical-slice battlefield theme
- Generation tool: image generator with transparent PNG output
- Generation date: fill at generation time
- Status: prompt-ready
- Output: individual files, not a combined contact sheet

## Prompt

Create a coherent set of original isometric tactical RPG terrain tiles for an abandoned mustering ground called the Forgotten Field. The location is melancholy and reclaimed by nature: desaturated moss grass, dry seed heads, broken civic stone, a worn earth road, shallow iron-blue water, and a restrained memory shrine with hairline pale-gold repair. Painterly pixel-adjacent texture, crisp gameplay edges, soft southwest key light, cool ambient shadows, restrained detail, no recognizable franchise style.

Each asset must have a transparent background and one exact 96 × 48 top diamond. Side faces may extend 16 px below on a 96 × 64 canvas. Preserve identical camera angle, diamond corners, light direction, scale, and contact points across every tile. Produce separate files for grass, flowering grass, brush, road, stone, high ground, shallow water, and shrine. Terrain transitions should feel related without baking neighboring tiles into the canvas.

## File names

`environment-forgotten-field-{terrain}-tile-v01.png`, using the terrain IDs from `godot/data/asset_manifest.json`.

## Exclusions

No units, UI, text, logos, perspective grid, square top-down tiles, opaque backgrounds, extreme bloom, photorealism, chibi styling, or dense grass that obscures a unit's feet.

## Review checklist

- Exact 96 × 48 top footprint
- All four diamond corners align
- Unit silhouette remains readable at 80 px height
- Water and high ground are identifiable without labels
- No visible seams at repeated placement
