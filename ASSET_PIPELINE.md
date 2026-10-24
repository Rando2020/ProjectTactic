# Asset Pipeline

This repo supports AI-assisted placeholder generation, but assets still need naming discipline.

## Asset lifecycle

```txt
Idea
→ prompt draft in /prompts
→ generated candidate
→ placeholder asset in /assets/placeholders
→ reviewed asset
→ production asset in /assets/{characters,environments,ui,audio,music}
→ referenced by game data or components
```

## Naming convention

Use kebab-case and include the asset type.

```txt
character-zane-portrait-v01.png
guardian-ignareth-boss-sprite-v01.png
tileset-ruined-temple-v01.png
ui-status-burning-icon-v01.png
music-battle-standard-loop-v01.ogg
```

## Metadata checklist

Every generated asset should have a prompt file that records:

- asset id
- intended game use
- prompt text
- generation tool
- generation date
- style notes
- exclusions
- status: placeholder, candidate-final, final, rejected

## Folder placement

| Asset type | Folder |
|---|---|
| concept art | `assets/concept/` |
| temporary generated art | `assets/placeholders/` |
| character sprites/portraits | `assets/characters/` |
| maps, tiles, environments | `assets/environments/` |
| icons, buttons, HUD | `assets/ui/` |
| sound effects | `assets/audio/` |
| music loops/stingers | `assets/music/` |

## Git LFS

Large media files are tracked through `.gitattributes`. Do not commit huge raw exports outside the asset folders.

## Godot vertical-slice runtime

The Godot runtime contract is documented in `docs/architecture/asset-bible-v1.md`. Runtime-facing mappings live in `godot/data/asset_manifest.json`; scenes and scripts should select stable theme or asset IDs rather than hard-code new file paths.

The first theme is `forgotten-field`. Its preferred files live under `godot/assets/environments/forgotten-field/`, while tactical overlays and optional unit indicators live under `godot/assets/ui/`. Preferred files may be missing during production. The registry tries each manifest fallback before the grid uses its procedural rendering.

To replace a placeholder, normalize the generated image, give it the exact manifest filename, place it at the manifest `path`, and validate the Godot Web build. Keep fallback entries until the replacement passes tactical readability review.
