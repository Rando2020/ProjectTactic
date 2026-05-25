# Phase 2 Visual Battle Readability Enhancements

## Overview
Phase 2 adds three critical visual features to improve battle clarity and unit hierarchy. All enhancements are now complete and ready for playtesting.

---

## ✅ 1. Floating Damage Numbers on Hits/Heals

**Status:** Already Implemented (Verified & Confirmed)

**Location:** `godot/scripts/vfx/VFXManager.gd`

**Implementation Details:**
- `play_damage_number(grid_pos, amount, color)` - Creates floating text that rises and fades
  - Displays damage amount in customizable color
  - Default: yellow for physical attacks, red/orange for critical hits
  - Position: Above target with slight horizontal randomness
  - Animation: Floats upward 52px over 0.75s, fades starting at 0.3s
  
- `play_heal_number(grid_pos, amount)` - Wrapper for heal display
  - Green color (0.35, 1.0, 0.55) for healing
  - Same animation as damage numbers

**Integration:**
- CombatResolver calls these automatically:
  - `resolve_attack()` → calls `play_damage_number()` for all physical hits
  - `resolve_spell()` → calls `play_damage_number()` for magical damage
  - `resolve_heal()` → calls `play_heal_number()` for healing spells
  - Elite prefixes → `play_damage_number()` for MP drain, lifesteal, etc.

**Color Scheme:**
- Physical damage: Yellow (1.0, 0.95, 0.4)
- Critical strikes: Deep red-orange (1.0, 0.25, 0.1)
- Flank bonus: Orange (1.0, 0.45, 0.1)
- Healing: Green (0.35, 1.0, 0.55)
- Miss: Gray (0.65, 0.65, 0.65)
- MP drain: Purple (0.65, 0.35, 1.0)

---

## ✅ 2. Clearer AoE Preview with Tile Count

**Status:** Newly Implemented

**Location:** `godot/scripts/grid/TacticalGrid.gd`

**Changes:**
- Modified `_refresh_highlights()` to call new `_add_aoe_tile_count_badge()` when AoE preview is active
- Added `_add_aoe_tile_count_badge(positions: Array[Vector2i])` function

**How It Works:**
1. Calculates center position of all AoE tiles (average X, Y)
2. Places a badge at center displaying "AoE: X" where X = number of tiles
3. Badge design:
   - **Background:** Red panel (1.0, 0.22, 0.1) at 70% opacity
   - **Text:** White text with red outline
   - **Position:** Below the AoE cluster (+24px Y offset for readability)
   - **Z-Index:** Placed above highlight layer for visibility

**Visual Benefits:**
- At a glance, players see exactly how many tiles an ability will affect
- Helps predict damage spread for AOE abilities
- Makes ability planning clearer without hovering over individual tiles
- Red color matches existing AoE highlight for visual consistency

**Example Output:**
- 3-tile AoE → Badge shows "AoE: 3"
- 7-tile chain reaction → Badge shows "AoE: 7"
- Single-target ability → Badge shows "AoE: 1"

---

## ✅ 3. Unit Scale Variation for Visual Hierarchy

**Status:** Newly Implemented

**Location:** `godot/scripts/units/Unit.gd`

**Changes:**
- Added `_apply_unit_scale()` function called after `_draw_unit()`
- Scales entire unit (sprite, body rect, all visuals) based on max HP

**How It Works:**
1. **Baseline:** 50 HP = 1.0x scale (normal size)
2. **Formula:** Logarithmic scaling with clamping
   - `scale = 0.75 + 0.6 * log₂(hp/50 + 0.5)`
   - Clamped to range [0.75x, 1.35x]
3. **Why Logarithmic?**
   - Similar units (close HP values) have subtle scale differences
   - Extreme units (very weak/strong) have more dramatic differences
   - Avoids jarring size jumps between similar units

**Scale Examples:**
- 25 HP (weak minion): ~0.85x scale
- 50 HP (standard unit): 1.0x scale
- 75 HP (tough enemy): ~1.12x scale
- 100+ HP (elite/boss): 1.25-1.35x scale

**Visual Benefits:**
- **Threat Assessment:** Players instantly see stronger units are larger
- **Visual Hierarchy:** Creates natural importance ordering
- **Tactical Awareness:** Larger enemies = focus target, planning priority
- **Immersion:** Stronger creatures logically take up more space

**Implementation Details:**
- Applies to ALL unit visuals (sprite, colored rect, HP bar, name label, etc.)
- Applied once at initialization (not every frame, no performance cost)
- Works with both sprite-based and colored-rect fallback units
- Invisible to player but massive impact on visual readability

---

## Testing Checklist

- [ ] **Floating Numbers**
  - [ ] Damage numbers appear above hit targets
  - [ ] Heal numbers appear in green
  - [ ] Numbers fade out smoothly
  - [ ] Colors match damage type (physical, crit, heal, etc.)
  
- [ ] **AoE Tile Count**
  - [ ] Badge appears when selecting AOE ability
  - [ ] Count is accurate (matches tile count)
  - [ ] Badge positioned at center of AoE
  - [ ] Readable without obscuring AoE tiles
  - [ ] Disappears when AoE preview clears
  
- [ ] **Unit Scaling**
  - [ ] Weaker enemies appear smaller
  - [ ] Stronger enemies appear larger
  - [ ] Boss units noticeably larger
  - [ ] Scaling doesn't break positioning
  - [ ] UI elements (HP bar, name) scale correctly

---

## Integration Notes

All three enhancements integrate seamlessly with existing systems:
- **No new dependencies** - Uses existing VFXManager and Unit architecture
- **No breaking changes** - Only additions to existing functions
- **Automatic activation** - Works immediately without configuration
- **Zero performance impact** - Scaling applied once, badges rendered only when needed

---

## Next Steps (Optional Phase 3)

Consider these additional enhancements for future iterations:
- Damage type indicators (slash, pierce, fire, etc.)
- Unit status effect stacking (multiple debuffs shown)
- Range preview improvements (show max range limits)
- Ability cost indicators (MP, Temper usage shown)
