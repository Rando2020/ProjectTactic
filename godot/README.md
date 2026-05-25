# The Appointed · Godot Design Export

This folder packages the design system from the **HTML/CSS playground** into Godot-ready resources. Drop it whole into your project at `res://design/`.

> **Source of truth.** The HTML/CSS design system (`colors_and_type.css`, `ui_kits/the-appointed/`, the `preview/` cards) remains the canonical reference. When you want to change a color or revise a screen layout, do it there first — then re-export to this folder. The HTML version iterates ~10× faster than touching Godot scenes directly.

## What's in here

```
godot/
├── tokens.gd                          # Autoload — all color/spacing/type constants
├── sfx.gd                             # Autoload — typed wrapper around AudioStreamPlayer pool
├── tile_spec.gd                       # Static data — movement cost, hazard, tags, spawn weight per tile
├── theme.tres                         # Starter Theme: Button, Label, Panel, LineEdit, ProgressBar
└── assets/
    ├── ui/
    │   ├── sigils/                    # 6 run-node medallions (battle/elite/mystery/boon/wanderer/boss)
    │   ├── tiles/                     # 13 base tiles + 4 status overlays — 96×96, seamless
    │   ├── parchment/                 # Aged-paper background + brass corner ornament
    │   └── icons/                     # Bell on/off (mute toggle)
    └── audio/                         # 8 synthesized SFX (.wav)
```

## Tile system

Thirteen base tiles (`grass`, `dirt`, `road`, `stone`, `shrine`, `shallow_water`, `deep_water`, `ice`, `burning`, `electrified_water`, `wall`, `high_ground`, `void_anchor`) plus four status overlays (`ice_overlay`, `burning_overlay`, `electrified_overlay`, `void_overlay`) that composite on top of any base.

Every tile is **96×96 PNG, seamless** — they can tile in any direction without visible seams. Use them with Godot's `TileSet` resource:

```gdscript
# Build a TileSet from the spec — usually done once at editor time
var tileset := TileSet.new()
for id in TileSpec.TILES.keys():
  var texture := load(TileSpec.texture_of(id)) as Texture2D
  var src := TileSetAtlasSource.new()
  src.texture = texture
  src.texture_region_size = Vector2i(96, 96)
  src.create_tile(Vector2i(0, 0))
  tileset.add_source(src)
```

Or sample for procedural generation:

```gdscript
# Pick a tile from the spawn pool weighted by spawn_weight
func random_tile(rng: RandomNumberGenerator) -> String:
  var pool := TileSpec.spawn_pool()
  var total := 0
  for entry in pool: total += entry[1]
  var roll := rng.randi() % total
  for entry in pool:
	roll -= entry[1]
	if roll < 0: return entry[0]
  return "grass"

# Then apply movement / hazard / height when querying:
var cost := TileSpec.cost_of(tile_id)
var blocked := TileSpec.is_impassable(tile_id)
var h := TileSpec.height_of(tile_id)
var hazard := TileSpec.hazard_of(tile_id)
```

Overlays are drawn as a second `TileMapLayer` (Godot 4.3+) or a child `TextureRect` per cell with `mix_blend_mode = MIX_BLEND_MODE_NORMAL` — they expect to sit on top of an already-rendered base.

## Setup

### 1. Drop the folder in

Copy this whole `godot/` folder into your project at `res://design/`:

```
your-godot-project/
└── design/
	├── tokens.gd
	├── sfx.gd
	├── theme.tres
	└── assets/...
```

### 2. Register the autoloads

Project Settings → Autoload → add:

| Path | Name |
|---|---|
| `res://design/tokens.gd` | **Tokens** |
| `res://design/sfx.gd` | **Sfx** |

### 3. Drop the fonts in

Download these from Google Fonts (or use any local copies) and place them at:

- `res://design/fonts/TrajanPro-Regular.ttf` *(if you have the proprietary face — otherwise substitute Cinzel)*
- `res://design/fonts/IMFellEnglish-Regular.ttf`
- `res://design/fonts/CormorantGaramond-Regular.ttf`
- `res://design/fonts/JetBrainsMono-Regular.ttf` *(numerics, optional)*

The `theme.tres` resource references these paths directly.

### 4. Use the theme

Either set the theme globally:

> Project Settings → Gui → Theme → **Custom** → `res://design/theme.tres`

…or assign it per scene-root by setting the Control node's `theme` property.

## Usage examples

### Reading a color

```gdscript
$Background.modulate = Tokens.HUB_BG_WARM
$HpBar.modulate = Tokens.HP
$Label.add_theme_color_override("font_color", Tokens.TIER_COLORS[current_tier - 1])
```

### Playing a sound

```gdscript
Sfx.play("confirm")     # sacred-CTA swell
Sfx.play("crack")       # tier shift
Sfx.play("sacred")      # parchment unfurls
```

### A sigil tinted by node modulate

```gdscript
@onready var sigil := $NodeIcon as TextureRect
sigil.texture = preload("res://design/assets/ui/sigils/boss.svg")
sigil.modulate = Color(1.0, 0.4, 0.5)   # crimson tint — sigils use currentColor
```

### A parchment panel

```gdscript
@onready var parchment := $ChapterCard as TextureRect
parchment.texture = preload("res://design/assets/ui/parchment/parchment_bg.png")
parchment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
# Optionally wrap in a NinePatchRect if you need stretchy edges; the source
# image bleeds 60px from each edge so the centre 1928×1160 region is safe.
```

### Tier-driven theming

```gdscript
func apply_tier(tier: int) -> void:
    var tint := Tokens.TIER_COLORS[tier - 1]
    $TierLabel.add_theme_color_override("font_color", tint)
    $TierName.text = Tokens.TIER_NAMES[tier - 1]
    if tier >= 4:
        $RevelationGlow.show()
    else:
        $RevelationGlow.hide()
```

## What's *not* exported

These are layout/interaction concerns that need to be rebuilt as Godot scenes (`.tscn`) using the HTML kit as a reference:

- **The Antechamber three-column layout** — recreate with `HBoxContainer` → `VBoxContainer × 3`
- **The Pathway floor list** — `VBoxContainer` of `HBoxContainer` rows; sigils as `TextureButton`
- **The parchment-unfurl animation** — Godot `AnimationPlayer` with a `scale_y` keyframe, ~680ms, `Tween.TRANS_CUBIC` `Tween.EASE_IN_OUT`
- **The tier-ember drift** — `CPUParticles2D` with `gravity = Vector2(0, -30)`, modulated `Tokens.SACRED_GLOW`, only enabled at tier 5

Open the HTML UI kit (`ui_kits/the-appointed/index.html`) alongside Godot and use it as the visual spec for each scene.

## Keeping things in sync

The HTML and Godot exports will drift if hand-edited separately. The recommended workflow:

1. Iterate visually in the HTML kit (faster, easier to share).
2. When the design is stable, run the export scripts to refresh `tokens.gd`, sigils, parchment, and WAVs.
3. Re-import this folder into Godot. The autoloads + theme paths stay stable, so existing scenes pick up changes automatically.

The export currently has to be re-run by hand (the script that generated everything in this folder lives in the design-system project's history). If this becomes painful, a small Node script + `pyaudio` could automate it end-to-end against `colors_and_type.css` as input.
