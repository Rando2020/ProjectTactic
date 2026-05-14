# ProjectTactic Asset Manifest

This manifest organizes the generated visual references from the current asset pass and defines where approved assets should live once exported into implementation-ready files.

## Current Direction

The preferred visual target is now:

```text
80% classic isometric tactical RPG readability
20% darker grounded gothic fantasy mood
```

That means the repo should favor:

- 2.5D / isometric battlefield readability
- clean parchment and beveled UI panels
- readable tactical grids and deployment markers
- jewel-tone status and range colors
- less heavy gothic framing than the earliest pass
- original assets only, no copied commercial game files

## Proposed Folder Structure

```text
src/assets/
  concepts/
  screens/
  tiles/
  props/
  ui/
  ui/cursors/
  ui/status-icons/
  ui/range-markers/
  portraits/

docs/art-direction/
  ASSET_MANIFEST.md
  STYLE_TARGET.md
```

## Generated Reference Assets To Preserve

| Proposed Path | Source / Purpose | Implementation Status |
|---|---|---|
| `docs/art-direction/tileset-cathedral-interior-props-reference.jpg` | Uploaded cathedral/interior props and floor tile concept sheet | Reference only. Needs sliced tile exports. |
| `docs/art-direction/ui-character-status-job-progression-reference.jpg` | Character status, Temper/Ether, job progression, equipment, and learned skills reference | Reference only. Use for character compendium UI. |
| `docs/art-direction/ui-prebattle-deployment-reference.jpg` | Pre-battle deployment screen reference with 2.5D fort map and roster | Reference only. Use for deployment UI and map presentation. |
| `docs/art-direction/ui-ironhold-encampment-reference.jpg` | Town / camp hub screen reference | Reference only. Use for town and story hub implementation. |
| `docs/art-direction/ui-asset-sheet-reference.jpg` | Cursor, tile highlight, range overlay, status icon, button prompt, and divider reference | Reference only. Needs individual SVG/PNG exports. |

## Existing Committed UI Placeholders

| Path | Purpose |
|---|---|
| `src/assets/ui/temper-icon.svg` | Temper armor placeholder icon |
| `src/assets/ui/magic-armor-icon.svg` | Ether / magical armor placeholder icon |
| `src/assets/ui/job-seal.svg` | Base job placeholder seal |
| `src/assets/ui/ascended-seal.svg` | Ascended job placeholder seal |

## Naming Rules

Use lowercase kebab-case names.

Examples:

```text
tileset-cathedral-interior-props.png
ui-character-status-job-progression-reference.jpg
cursor-attack-sword.png
range-marker-move-green.png
status-icon-poison.png
portrait-zane-resonant-vanguard.png
screen-prebattle-deployment-reference.jpg
```

## Asset Classification

### Reference Assets

Use `docs/art-direction/` for generated images that communicate style, layout, or direction but are not sliced into game-ready files.

### Implementation Assets

Use `src/assets/` only when the file is ready to be imported by the app.

### Tiles and Props

Use `src/assets/tiles/` and `src/assets/props/` for implementation-ready extracted sprites. A full concept sheet should stay in `docs/art-direction/` until it is sliced.

## Next Export Pass

The next pass should slice and export:

1. `selected-tile.png`
2. `move-range-tile.png`
3. `attack-range-tile.png`
4. `magic-range-tile.png`
5. `objective-marker.png`
6. `cursor-default.png`
7. `cursor-attack.png`
8. `cursor-magic.png`
9. `status-icon-poison.png`
10. `status-icon-burn.png`
11. `status-icon-freeze.png`
12. `status-icon-stun.png`
13. `status-icon-silence.png`
14. `status-icon-haste.png`
15. `status-icon-slow.png`
16. `status-icon-regen.png`
17. `status-icon-guard-break.png`
18. `status-icon-bleed.png`
19. `status-icon-curse.png`
20. `status-icon-barrier.png`

## Risk

Large generated PNG/JPEG assets should be committed carefully. If GitHub file-size or connector constraints block direct binary upload, use Git LFS or manual upload for production files, and keep this manifest as the source of truth for naming and placement.
