# Visual Battle Readability Audit

## Current Implementation Status

### ✅ Already Implemented (Excellent Foundation)

1. **HP Bars** (Unit.gd, lines 123-144)
   - Floating bars above units showing HP
   - Color-coded: Green (>60%), Yellow (30-60%), Red (<30%)
   - Works, but could be more prominent

2. **Facing Indicator** (Unit.gd, lines 301-363)
   - Polygon2D arrow showing cardinal direction (N/E/S/W)
   - Rotates based on unit facing
   - Has shadow and glow for depth
   - Works well!

3. **Unit Selection Highlight** (Unit.gd, line 366-370)
   - Modulate brightening on selected unit
   - Could be stronger/more obvious

4. **Selected Tile Highlight** (TacticalGrid.gd, lines 517-554)
   - Large diamond highlight with GO/HIT/CAST labels
   - Larger scale (1.14x)
   - Yellow color for neutral, color-coded for action type
   - Excellent implementation

5. **Range Highlights** (TacticalGrid.gd, lines 488-520)
   - Move tiles: Cyan (0.0, 0.90, 1.0)
   - Attack tiles: Orange (1.0, 0.40, 0.0)
   - Ability tiles: Purple (0.75, 0.25, 1.0)
   - AOE preview: Red (1.0, 0.22, 0.1)
   - All have rim highlights for definition
   - Works but could be more dynamic

6. **Action Forecast Panel** (BattleUI.gd, lines 379-1080)
   - Comprehensive damage/heal forecast
   - Element icons, affinity display
   - Hit confidence indicators
   - Critical notes highlighted
   - Status/tactical/detail notes organized
   - Excellent information density

7. **Path Preview** (TacticalGrid.gd, lines 493-497)
   - Shows movement path with step numbers
   - Gradient opacity for depth
   - Works well!

8. **Team Color Indicators** (Unit.gd, lines 109-121)
   - Colored dot (blue player, red enemy)
   - Has outline for contrast
   - Works well!

9. **Unit Name Labels** (Unit.gd, lines 147-157)
   - 6-character display name
   - White text with black outline
   - Good contrast

### 🟡 Areas for Enhancement

1. **Unit Selection Outline**
   - Current: Slight modulate brightening (1.2x)
   - Issue: Subtle, hard to see in battle
   - Potential: Add thick glowing outline or border

2. **Range Preview Clarity**
   - Current: Static diamond highlights
   - Issue: Can blend into background
   - Potential: Add pulsing animation or clearer distinction

3. **Status Effect Display**
   - Current: Signals exist but no visual icons shown
   - Issue: Can't see buffs/debuffs at a glance
   - Potential: Add small icons above units

4. **Grid Overlay**
   - Current: None
   - Issue: Tile boundaries not always obvious
   - Potential: Subtle grid lines to define tiles

5. **Floating Damage Numbers**
   - Current: None
   - Issue: Can't see where damage comes from during resolution
   - Potential: Numbers that appear and fade over hit units

6. **AOE Radius Clarity**
   - Current: Red highlight tiles
   - Issue: Hard to estimate radius at glance
   - Potential: Circle radius indicator or animated pulse

## Recommended Implementation Priority

### Phase 1: High Visual Impact (Quick Wins)
1. Enhance unit selection outline (glow ring like active_unit_tile)
2. Animate range preview highlights (pulsing or wave effect)
3. Add status effect icons above units
4. Add subtle grid overlay to tiles

### Phase 2: Medium Effort
5. Floating damage/heal numbers
6. Clearer AOE circle radius
7. Larger/bolder unit sizing for distance visibility

### Phase 3: Polish
8. Camera zoom/pan improvements
9. Additional VFX on ability resolution
10. Turn order indicator enhancement

