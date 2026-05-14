# Art Direction Guide

## Target

Vaelthar should feel like a modern browser-playable tactical RPG with classic strategy RPG readability and a darker grounded fantasy mood.

The screen should communicate: miniature battlefield, dramatic elevation, readable unit silhouettes, ornate-but-clear menus, and deliberate command pacing.

## Influence boundary

Use classic tactical RPGs as design references only. Do not directly copy protected characters, sprites, UI layouts, logos, names, maps, extracted files, animation frames, audio, fonts, scripts, or proprietary data from any commercial game.

ProjectTactic should learn from genre conventions while building original assets, original data, and original interaction design.

## Influences

Use these as directional references only:

- Classic tactical RPG readability
- Isometric battlefield staging
- Pre-battle deployment and formation tension
- Job progression clarity
- Painterly dark fantasy mood
- Stone, leather, copper, ash, candlelight, violet Ether, and muted gold
- Strong silhouette language for jobs and monsters
- Modern 2026 UI clarity and responsiveness

## Visual Pillars

### Readable Tactical Board

Tiles must make gameplay state readable before they look detailed.

- Movement should be visually obvious.
- Height should be visible without relying only on text labels.
- Blocking terrain should read immediately.
- Hazard and surface reaction tiles should be unmistakable.
- Debug coordinates should be toggleable, not always part of the presentation.

### Pseudo-Isometric Depth

The production battlefield should not look like a spreadsheet or dashboard grid.

- Prefer diamond or staggered tiles.
- Show tile faces or shadows to imply elevation.
- Use a consistent unit anchor point so sprites feel planted on the board.
- Preserve a debug grid view for QA and systems work.

### Dark Fantasy With Warm Highlights

Base world tone should be ash, stone, midnight blue, blackened green, and desaturated brown.

Accent colors:

- Temper: orange or bronze
- Ether: violet or blue-violet
- Holy: soft gold
- Null or Dark: violet-black
- Thunder: pale gold
- Water: deep cyan
- Fire: ember orange

### Tactics UI, Not SaaS UI

The interface should feel like a tactical RPG command layer, not a product dashboard.

- Use dark parchment, stone, brass, and candlelit accents.
- Prefer beveled panels over soft rounded SaaS cards.
- Keep buttons compact and command-like.
- Use ornamentation sparingly so combat readability stays strong.
- Use a clear focus state for keyboard/controller support.

### Original Placeholder Assets

Placeholder assets should be legally safe and original.

Naming convention:

```text
lowercase-kebab-case.png
```

Examples:

```text
warder-idle-placeholder.png
resonant-cast-placeholder.png
stone-road-tile.png
shrine-ether-tile.png
ui-panel-dark-gold.png
```

## Asset Priorities

1. Terrain tiles
2. Player unit sprites
3. Enemy unit sprites
4. Job icons
5. UI panels
6. VFX placeholders
7. Portraits
8. Town scene backdrops
9. Battle result illustrations

## Required presentation systems before mass asset generation

Before generating a large asset batch, define these implementation rules:

- Tile size and projection style
- Sprite anchor point
- Direction count: N, S, E, W first
- Idle frame count
- Cast, hit, and dissipate VFX frame naming
- Terrain registry keys
- UI panel component names

## Current Placeholder Rule

Until the battle loop is complete, prioritize simple readable assets over polished production art.

The next visual milestone is not final art. It is a battlefield and menu layer that already feels like a tactics RPG using original placeholder assets.
