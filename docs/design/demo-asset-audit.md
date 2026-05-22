# Demo Asset Audit

ProjectTactic needs a focused vertical-slice asset pack, not a full production art library yet. This audit defines the minimum assets needed to make the Godot demo feel intentional while keeping scope small enough to generate, review, and replace systematically.

## Art direction lock

Use this direction for all demo assets:

- Reimagined diorama emberlit HD-2D.
- Watercolor softness over clean tactical readability.
- Dark fantasy war mood.
- Modern prestige tactical RPG UI polish.
- Isometric billboard characters.
- Original designs only. Do not copy copyrighted characters, maps, UI, icons, or effects.

## Production rules

- Use lowercase kebab-case file names.
- Keep gameplay IDs stable even if art is replaced later.
- Put Godot runtime assets under `godot/assets/`.
- Put generated source notes and prompts under `docs/prompts/`.
- Do not add new runtime assets to React. `src/` is read-only reference.
- Prefer cohesive batches over one-off images.

## Demo asset batches

### Batch 1: Demo board pack

Purpose: make the tactical battlefield readable.

Required files:

```txt
godot/assets/tiles/grass-tile.png
godot/assets/tiles/dirt-tile.png
godot/assets/tiles/road-tile.png
godot/assets/tiles/stone-tile.png
godot/assets/tiles/wall-tile.png
godot/assets/tiles/shallow-water-tile.png
godot/assets/tiles/shrine-tile.png
godot/assets/tiles/high-ground-tile.png
godot/assets/tiles/height-edge-grass.png
godot/assets/tiles/height-edge-stone.png
godot/assets/tiles/burning-tile.png
godot/assets/tiles/frozen-tile.png
godot/assets/tiles/void-corruption-tile.png
godot/assets/tiles/elite-spawn-tile.png
godot/assets/tiles/boss-arena-tile.png
```

Nice-to-have props:

```txt
godot/assets/props/leafy-bush.png
godot/assets/props/ruin-block.png
godot/assets/props/mossy-rock.png
godot/assets/props/tree-stump.png
godot/assets/props/broken-banner.png
godot/assets/props/ash-pillar.png
```

### Batch 2: Demo unit pack

Purpose: make combat feel character-driven.

Required files:

```txt
godot/assets/sprites/units/zane-idle-isometric.png
godot/assets/sprites/units/mira-idle-isometric.png
godot/assets/sprites/units/kael-idle-isometric.png
godot/assets/sprites/units/lyra-idle-isometric.png
godot/assets/sprites/units/null-drake-idle-isometric.png
godot/assets/sprites/units/storm-imp-idle-isometric.png
godot/assets/sprites/units/void-cultist-idle-isometric.png
godot/assets/sprites/units/fen-wraith-idle-isometric.png
godot/assets/sprites/units/boss-null-knight-idle-isometric.png
```

Not required for this pass:

- Full walk cycles.
- Full attack/cast/hurt/down sheets.
- Eight-direction facing.

### Batch 3: Combat feedback pack

Purpose: make actions feel responsive.

Required files:

```txt
godot/assets/vfx/fire-impact-vfx-sheet.png
godot/assets/vfx/ice-impact-vfx-sheet.png
godot/assets/vfx/lightning-impact-vfx-sheet.png
godot/assets/vfx/earth-impact-vfx-sheet.png
godot/assets/vfx/wind-impact-vfx-sheet.png
godot/assets/vfx/dark-impact-vfx-sheet.png
godot/assets/vfx/holy-impact-vfx-sheet.png
godot/assets/vfx/heal-vfx-sheet.png
godot/assets/vfx/buff-vfx-sheet.png
godot/assets/vfx/damage-number-floats.png
```

### Batch 4: Roguelite UI pack

Purpose: support hub, rewards, boons, currencies, and run nodes.

Required currency files:

```txt
godot/assets/icons/currency-soul-shards-icon.png
godot/assets/icons/currency-obsidian-icon.png
godot/assets/icons/currency-glyphs-icon.png
godot/assets/icons/currency-boss-tokens-icon.png
godot/assets/icons/currency-phoenix-sigils-icon.png
godot/assets/icons/currency-titan-sigils-icon.png
```

Required run-node files:

```txt
godot/assets/icons/run-node-battle-icon.png
godot/assets/icons/run-node-elite-icon.png
godot/assets/icons/run-node-boon-icon.png
godot/assets/icons/run-node-wanderer-icon.png
godot/assets/icons/run-node-boss-icon.png
godot/assets/icons/run-node-shop-icon.png
```

Required boon files:

```txt
godot/assets/icons/boon-phoenix-heart-icon.png
godot/assets/icons/boon-ember-reprisal-icon.png
godot/assets/icons/boon-titan-bulwark-icon.png
godot/assets/icons/boon-stone-oath-icon.png
godot/assets/icons/boon-storm-quickening-icon.png
godot/assets/icons/boon-void-bargain-icon.png
```

### Batch 5: Status and elite-affix pack

Purpose: make roguelite modifiers legible.

Required files:

```txt
godot/assets/icons/status-burn-icon.png
godot/assets/icons/status-freeze-icon.png
godot/assets/icons/status-slow-icon.png
godot/assets/icons/status-curse-icon.png
godot/assets/icons/status-bleed-icon.png
godot/assets/icons/status-shield-icon.png
godot/assets/icons/affix-volatile-icon.png
godot/assets/icons/affix-fortified-icon.png
godot/assets/icons/affix-vampiric-icon.png
godot/assets/icons/affix-of-frost-icon.png
godot/assets/icons/affix-of-flames-icon.png
godot/assets/icons/affix-of-void-icon.png
```

### Batch 6: Hub identity pack

Purpose: make the meta-progression layer feel like a real place.

Required files:

```txt
godot/assets/backgrounds/hub-background-last-hearth.png
godot/assets/ui/hub-panel-dark-gold.png
godot/assets/ui/guardian-shrine-panel.png
godot/assets/ui/job-reliquary-panel.png
godot/assets/ui/heat-altar-panel.png
godot/assets/ui/reward-card-panel.png
```

## Demo acceptance standard

The demo asset pass is successful when:

- Every visible gameplay object has a stable asset path.
- The hub, battle, results, and run-node screens share the same visual language.
- The four heroes and core enemies feel like they belong to the same world.
- Elemental VFX communicate fire, ice, lightning, dark, holy, earth, wind, healing, and buffs.
- Boons, currencies, elite affixes, and statuses are readable at small UI sizes.

## Follow-up implementation tasks

1. Add or update `AssetRegistry.gd` IDs for all missing demo assets.
2. Generate placeholder assets batch by batch.
3. Import generated assets into Godot and verify `.import` files are created.
4. Update scenes to reference registry IDs instead of direct hardcoded paths where feasible.
5. Replace placeholders with higher-fidelity assets only after the demo loop is stable.
