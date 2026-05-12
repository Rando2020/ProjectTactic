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
