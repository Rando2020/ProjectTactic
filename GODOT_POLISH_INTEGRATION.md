# Godot Polish Systems - Integration Guide

## Overview

Three GDScript systems have been created to bring FFT/Disgaea-style polish to ProjectTactic:

1. **BattleJuiceEffects.gd** - Visual feedback for combat
2. **EnhancedUnitDisplay.gd** - Job-colored unit portraits with silhouettes
3. **BoonPickScreen.gd** - Hades-style boon selection UI

All systems are located in `/godot/scripts/` and ready for integration.

---

## 1. BattleJuiceEffects Integration

### Location
`/godot/scripts/vfx/BattleJuiceEffects.gd`

### Setup
The system auto-initializes in `_ready()` by finding:
- `/root/BattleScene/Camera2D` - For camera shake
- `/root/BattleScene/BattleManager/TacticalGrid` - For unit references

### Usage

Register the effects system as an autoload in `project.godot`:
```
[autoload]
BattleJuiceEffects="*res://godot/scripts/vfx/BattleJuiceEffects.gd"
```

Then call from **CombatResolver.gd** or **BattleManager.gd**:

```gdscript
# When a hit lands, trigger effects
var damage = calculate_damage(attacker, target, ability)
var intensity = "normal"
if damage > 100:
    intensity = "heavy"
elif damage > 150:
    intensity = "critical"

BattleJuiceEffects.trigger_hit(
    target_unit_ids=[target.id],
    intensity=intensity,
    pause_duration=80,
    flash_duration=300,
    shake_duration=150
)
```

### Intensity Presets

```
"light":    2px shake, 0.1 wobble, 60ms pause
"normal":   4px shake, 0.15 wobble, 80ms pause
"heavy":    6px shake, 0.2 wobble, 100ms pause
"critical": 8px shake, 0.25 wobble, 120ms pause
```

### Customization

Edit constants at top of BattleJuiceEffects.gd:
```gdscript
const INTENSITY_PRESETS = {
    "light": {"shake": 2, "wobble": 0.1, "pause": 60},
    # ...adjust values here
}
```

---

## 2. EnhancedUnitDisplay Integration

### Location
`/godot/scripts/ui/EnhancedUnitDisplay.gd`

### Job Profiles

Pre-configured for 9 jobs (plus default):
- **Red** - Warder, Null Breaker (tanks)
- **Green** - Luminary (healer)
- **Cyan** - Seraph (holy support)
- **Purple** - Arcanist, Etherweaver (casters)
- **Orange** - Resonant, Primal Binder (summoners)
- **Light Blue** - Skywarden (jumper)

Profiles include: color, border, silhouette icon, label

### Integration in TacticalGrid.gd

In your TacticalGrid unit creation code:

```gdscript
# Instead of simple emoji tokens:
var portrait = EnhancedUnitDisplay.new()
portrait.unit = unit_data
portrait.setup()
tile.add_child(portrait)

# For flashing on hit:
portrait.set_flashing(true)
await get_tree().create_timer(0.3).timeout
portrait.set_flashing(false)

# For selection:
portrait.set_selected(true)
portrait.set_active(true)
```

### Customizing Job Colors

Edit `JOB_PROFILES` in EnhancedUnitDisplay.gd:

```gdscript
const JOB_PROFILES = {
    "warder": {
        "color": Color("#dc2626"),     # Main color
        "border": Color("#991b1b"),    # Border color
        "icon": "⚔️",                   # Job icon
        "label": "Warder"
    },
    # ...add more jobs here
}
```

### Status Indicators

Automatically shows colored dots for conditions:
- Red (Bleed), Orange (Burning), Green (Blessed), Yellow (Stun), Gray (Other)

---

## 3. BoonPickScreen Integration

### Location
`/godot/scripts/ui/BoonPickScreen.gd`

### Integration in StageSelect.gd

When a boon pick node is encountered:

```gdscript
func _show_boon_pick(options: Array) -> void:
    var boon_screen = BoonPickScreen.new()
    add_child(boon_screen)
    
    boon_screen.setup(_gs.active_run.active_boons, options)
    
    # Handle selection
    boon_screen.boon_selected.connect(func(boon: Dictionary, replaced_id: String) -> void:
        if not replaced_id.is_empty():
            # Remove old boon
            _gs.active_run.active_boons = _gs.active_run.active_boons.filter(
                func(b): return str(b.get("id", "")) != replaced_id
            )
        
        # Add new boon
        _gs.active_run.active_boons.append(boon)
        
        # Continue game flow
        boon_screen.queue_free()
        _rebuild_ui()
    )
```

### Lane System

Automatically enforces lane limits:
- **Movement Lane**: Max 2 boons per run
- Add new lanes by:
  1. Updating `BOON_LANE_LIMITS` in BoonSystem.gd
  2. Updating `boon_lane()` detection in BoonSystem.gd
  3. (Optional) Add lane color constant in BoonPickScreen.gd

### Customization

**Change movement lane limit to 3:**
```gdscript
# In BoonSystem.gd
const BOON_LANE_LIMITS: Dictionary = {
    "movement": 3,  # Changed from 2
}
```

---

## Integration Checklist

### BattleJuiceEffects
- [ ] Register as autoload in project.godot
- [ ] Call `trigger_hit()` in combat resolution
- [ ] Test hit pause (brief freeze)
- [ ] Test target flash (golden glow)
- [ ] Test camera shake (screenshake)
- [ ] Test impact wobble (unit bounce)
- [ ] Tune intensity values if needed

### EnhancedUnitDisplay
- [ ] Create instances in TacticalGrid for each unit
- [ ] Verify job colors match unit's currentJobId
- [ ] Test selection glow (highlighted unit)
- [ ] Test active glow (current unit's turn)
- [ ] Test flash effect (on hit)
- [ ] Test idle bob (smooth floating)
- [ ] Verify status dots show correctly
- [ ] Check enemy badges (red E) appear for enemies

### BoonPickScreen
- [ ] Connect to StageSelect._show_boon_pick()
- [ ] Test lane visualization (progress bar)
- [ ] Test lane full modal (replacement selection)
- [ ] Test boon addition to active_run.active_boons
- [ ] Test boon replacement (full lane scenario)
- [ ] Verify boons appear in loadout strip after selection
- [ ] Test with multiple lanes if added

---

## Performance Notes

All three systems are optimized:
- **BattleJuiceEffects**: Uses Godot Tween system (GPU accelerated)
- **EnhancedUnitDisplay**: Simple Control nodes, idle bob via Tween
- **BoonPickScreen**: Standard UI containers, no complex rendering

Expected impact: Negligible on frame rate, CPU usage minimal.

---

## Testing Plan

### Unit Test
1. Start a battle
2. Perform an attack
3. Verify hit pause occurs (brief freeze)
4. Verify target flashes (golden glow)
5. Verify camera shakes slightly
6. Verify unit wobbles (scale bounce)

### UI Test
1. Enter boon pick node
2. Verify current boons shown at top
3. Hover over boon card
4. Verify lane badge shown (e.g., "Movement (1/2)")
5. Click a boon in full lane
6. Verify replacement modal appears
7. Select a boon to replace
8. Verify boon replaces correctly

### Visual Test
1. In battle, check unit portraits have colors
2. Verify silhouette icons show job type
3. Verify selection glow appears when selected
4. Verify idle bob animation (units float gently)
5. Verify status condition dots appear
6. Verify enemy units have red E badge

---

## Known Limitations

- **BattleJuiceEffects**: Camera shake requires valid Camera2D node
- **EnhancedUnitDisplay**: Job profiles must match unit's currentJobId key
- **BoonPickScreen**: Requires BoonSystem singleton to be initialized

---

## Future Enhancements

- [ ] Add more job profiles as they're designed
- [ ] Add sound effects to BattleJuiceEffects
- [ ] Add lane color system separate from rarity
- [ ] Add boon synergy indicators
- [ ] Add ability preview on boon hover
- [ ] Implement boon undo system (1 per run)

---

## Support

If integration fails:

1. Check that file paths match exactly
2. Verify autoload names in project.godot
3. Check node paths in _ready() methods
4. Look for console errors (F12 in debug)
5. Test individual systems in isolation first

---

**Status**: ✅ All systems ready for integration
**Last Updated**: 2026-05-25
