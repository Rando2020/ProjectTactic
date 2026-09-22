# Asset Bible v1: Vertical Slice Foundation

Status: runtime foundation  
Scope: browser-playable Godot vertical slice  
Canonical manifest: `godot/data/asset_manifest.json`

## Visual thesis

The Appointed should feel like a half-remembered illuminated manuscript reconstructed as a tactical battlefield. Materials are weathered, silhouettes remain clean, and supernatural color is reserved for decisions, danger, and memory. The world may be melancholy, but the combat state must never be ambiguous.

## Non-negotiable runtime contract

- Godot is the runtime source of truth. React art remains reference-only.
- Battlefield tile language uses a 96 × 48 isometric top diamond.
- Side depth may extend the canvas to 64 px high, with 16 px reserved for visible side faces.
- Transparent PNG is the default for tiles, units, props, overlays, indicators, and VFX.
- Asset IDs are stable and lowercase. File names are lowercase kebab-case and end in `-v01`.
- Gameplay data chooses a theme ID. The manifest translates IDs to file paths.
- Every runtime asset may be absent. The game must fall back to legacy art or procedural drawing.
- Do not add generator contact sheets, layered source files, or giant raw exports to the runtime folders.

## Style language

| Dimension | Direction |
|---|---|
| Shape | Readable silhouettes, tapered medieval forms, restrained ornament |
| Surface | Worn stone, dry grass, oxidized metal, faded cloth, hairline gold repair |
| Palette | Charcoal, desaturated moss, parchment, iron blue, ember rust |
| Light | Soft southwest key, cool ambient shadow, no baked spotlight |
| Memory magic | Pale gold and violet used sparingly as a high-salience accent |
| Rendering | Painterly pixel-adjacent texture with crisp gameplay edges |
| Avoid | Photorealism, glossy mobile-game plastic, chibi proportions, noisy microdetail |

## Readability hierarchy

1. Units and target states
2. Walkability, hazards, and height
3. Tactical overlays
4. Props and environmental storytelling
5. Decorative texture

At normal browser zoom, a player must identify team, active unit, legal movement, attack range, and terrain edge without reading text.

## Asset families and naming

| Family | Pattern | Example |
|---|---|---|
| Environment tile | `environment-{theme}-{terrain}-tile-vNN.png` | `environment-forgotten-field-grass-tile-v01.png` |
| Environment prop | `environment-{theme}-{object}-prop-vNN.png` | `environment-forgotten-field-mossy-rock-prop-v01.png` |
| Character | `character-{id}-{pose}-vNN.png` | `character-vanguard-idle-v01.png` |
| Enemy | `enemy-{id}-{pose}-vNN.png` | `enemy-hollow-lancer-idle-v01.png` |
| Tactical overlay | `ui-tactical-overlay-{state}-vNN.png` | `ui-tactical-overlay-move-v01.png` |
| Unit indicator | `ui-unit-indicator-{team}-vNN.png` | `ui-unit-indicator-player-v01.png` |
| UI frame | `ui-{surface}-{role}-vNN.png` | `ui-battle-command-frame-v01.png` |
| VFX | `vfx-{effect}-{variant}-vNN.png` | `vfx-impact-fire-core-v01.png` |

Use the stable gameplay ID inside JSON and code. Increment a filename version only when the output contract changes. Art revisions that keep the same crop, dimensions, and intent may replace the current candidate during review.

## Forgotten Field environment

`forgotten-field` is the first manifest-backed theme. It depicts an abandoned mustering ground where grass has reclaimed old roads and fragments of civic stone imply a civilization erased without spectacle.

Required terrain IDs for the first playable map are `grass`, `grass_flowers`, `brush`, `road`, `stone`, `high_ground`, `shallow_water`, and `shrine`. Required prop IDs are `leafy_bush`, `mossy_rock`, `tree_stump`, and `ruin_block`.

The initial Ashvale battle sets `MapData.environment_theme_id` to `forgotten-field`. Until final files exist, each manifest entry falls back to the current playable tile or prop.

## Tactical overlay contract

Overlay canvases are transparent 96 × 48 diamonds. The manifest defines `selected`, `move`, `attack`, `ability`, and `blocked`. The runtime scales an overlay to the configured tile footprint and retains procedural outlines for contrast. Missing or invalid PNGs fall back first to the existing generated diamond, then to a procedural polygon.

Overlays must remain legible for common color-vision differences. Shape and edge treatment should distinguish states, not hue alone.

## Character and enemy contract

- Idle frame target: 128 × 128 transparent canvas.
- Feet align to bottom-center with consistent padding.
- Three-quarter isometric view matches the battlefield camera.
- Player silhouettes should remain distinguishable at 80 px display height.
- Enemy rank is communicated through silhouette and mass before color.
- Avoid weapons or effects touching the canvas boundary.

The hero prompt pack uses the stable roles Vanguard, Arcanist, Warden, and Wayfarer. These are art-production labels and do not rename current gameplay IDs until a separate data migration is approved.

The manifest `characters` section is the adapter between those art-production roles and current gameplay IDs. Each unit pose lists a preferred versioned asset and a legacy fallback. The accepted mappings are Zane to Vanguard, Mira to Arcanist, and Void Cultist to Hollow Cantor without changing combat IDs, display names, or balance data. Hollow Lancer remains a reserved art role until a compatible gameplay unit exists.

## VFX contract

- Transparent sprite sheets, consistent frame dimensions and origin.
- No camera background, floor plane, typography, or interface frame.
- The anticipation frame is quiet, the impact frame is dominant, and decay clears quickly.
- Keep combat-critical silhouettes visible through the effect.
- Browser target: prefer compact sheets and avoid unnecessary 4K exports.

## Folder map

```text
prompts/assets/{environments,ui,characters,vfx}/
godot/data/asset_manifest.json
godot/assets/characters/
godot/assets/environments/forgotten-field/{tiles,props}/
godot/assets/ui/{tactical-overlays,unit-indicators}/
godot/assets/vfx/
```

## Replacing placeholders

1. Generate one family using its versioned prompt file.
2. Select candidates by silhouette and tactical readability, not illustration polish alone.
3. Normalize canvas, transparency, footprint, and file name.
4. Put the file at the manifest `path`. Do not edit battle code.
5. Import the Godot project, then test normal zoom, selection states, unit contrast, and Web export.
6. Keep the `fallback_path` through review. Remove it only after the new asset is accepted and the browser build is validated.

## Validation gates

- JSON parses and uses schema version 1.
- File names are lowercase kebab-case.
- Tiles match the 96 × 48 top footprint.
- Missing preferred assets produce no crash and preserve the playable loop.
- Player and enemy indicators remain visible with optional files removed.
- The Ashvale battle visibly uses the `forgotten-field` data path.
- Headless Godot parsing and the existing stability check pass.

## Risks and TODOs

- Existing art spans multiple historical folders and naming styles. This foundation does not migrate them all.
- Runtime PNG loading is intentional so missing or Git LFS pointer files can fall back safely. Revisit preload strategy after the art set stabilizes.
- Generator outputs frequently contain inconsistent light direction and diamond geometry. Approve a small terrain batch before scaling production.
- Unit indicators currently have no art fallback file by design. Their procedural fallback is the compatibility contract.
- Add an automated manifest schema and preferred-asset dimension validator when the first real batch lands.
- Perform a color-blindness and small-screen readability pass before declaring assets final.
