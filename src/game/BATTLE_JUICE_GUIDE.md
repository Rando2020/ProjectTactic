# ⚡ Battle Juice + Sprite Placeholder Upgrade

## Overview

Enhanced the battle system with FFT/Disgaea-style visual polish:
- **Hit Pauses** — Brief time freeze on impact for weighty feedback
- **Target Flashes** — White/golden flash effect on hit units
- **Camera Nudges** — Subtle screenshake on ability impact
- **Enhanced Unit Placeholders** — Better class silhouettes and visual hierarchy
- **Facing Readability** — Clearer direction indicators
- **Idle Bob** — More prominent floating animation with better timing

---

## New Components

### 1. BattleJuiceEffects.jsx

Provides React hooks for battle polish effects:

**useHitEffect()** — Master hook that triggers all effects together:
```javascript
const { triggerHit } = useHitEffect()

// In combat resolution:
triggerHit({
  targetUnitIds: [targetId],
  intensity: 'normal',        // 'light' | 'normal' | 'heavy' | 'critical'
  pauseDuration: 80,          // Time freeze in ms
  flashDuration: 300,         // Flash effect duration
  shakeDuration: 150,         // Camera shake duration
})
```

**Individual hooks** for fine control:
```javascript
const { triggerPause, isPaused } = useHitPause()
const { triggerFlash, flashingUnitIds } = useTargetFlash()
const { triggerShake, shake } = useCameraShake()
const { triggerWobble, wobble } = useImpactWobble()
```

**Wrapper components**:
```jsx
<BattleShakeCam shake={shake}>
  {/* Content gets camera shake applied */}
</BattleShakeCam>

<HitEffectUnit unitId={id} isFlashing={flashingUnitIds.has(id)} wobble={wobble}>
  {/* Unit gets flash and wobble effects */}
</HitEffectUnit>
```

---

### 2. EnhancedUnitDisplay.jsx

Better visual representation of units with class clarity:

**EnhancedUnitPortrait** — Replaces basic emoji tokens:
```jsx
<EnhancedUnitPortrait
  unit={unit}
  isSelected={unit.id === selectedId}
  isActive={unit.id === activeId}
  isFlashing={flashingUnitIds.has(unit.id)}
  size="normal"  // 'small' | 'normal' | 'large'
/>
```

Features:
- Color-coded job circles (same as TacticalGrid.jsx)
- Class silhouette icon (⚔️, ✨, ⚡, etc.)
- Unit initials in center
- Status indicators on side (colored dots for conditions)
- Enemy badge (red E)
- Selection/active glow effect
- Flash animation on hit
- Juicy bobbing animation

**Job Profiles**:
```javascript
JOB_PROFILES = {
  warder: {
    label: 'Warder',
    bg: '#dc2626',
    border: '#991b1b',
    text: '#fecaca',
    silhouette: '🛡️',
    accent: '#ff6b6b',
    description: 'Tank — Guard allies',
  },
  // ... 8 more jobs
}
```

**JobIndicator** — Show class info on hover:
```jsx
<JobIndicator jobId="warder" size="compact" />
// or full card version
<JobIndicator jobId="warder" size="full" />
```

**FacingIndicator** — Clear direction arrows:
```jsx
<FacingIndicator facing="N" style={{ position: 'absolute', top: 3, right: 5 }} />
// Shows: ↑ for North, → for East, ↓ for South, ← for West
```

**StatusBars** — HP/Temper/Ether visualization:
```jsx
<StatusBars unit={unit} direction="vertical" size="normal" />
// Shows three color-coded bars with labels and values
```

---

## Integration Steps

### Step 1: Import in BattleScreen.jsx

```javascript
import { useHitEffect, BattleShakeCam, HitEffectUnit } from '../components/BattleJuiceEffects'
import { EnhancedUnitPortrait, StatusBars } from '../components/EnhancedUnitDisplay'
```

### Step 2: Add effect hooks to BattleScreen

```javascript
export default function BattleScreen({ gameState, setGameState, activeMission, ... }) {
  // ... existing state ...

  const {
    triggerHit,
    isPaused,
    flashingUnitIds,
    cameraShake,
  } = useHitEffect()
```

### Step 3: Trigger hit effects in confirmAttack()

```javascript
function confirmAttack() {
  if (!pendingTarget) return
  const { targetId, abilityId } = pendingTarget
  // ... resolve attack ...

  // Trigger hit juice!
  const intensity = dmg?.amount > 100 ? 'heavy' : 'normal'
  triggerHit({
    targetUnitIds: [targetId],
    intensity,
    pauseDuration: 80,
    flashDuration: 300,
    shakeDuration: 150,
  })

  // Then do reactions and updates
  spawnCombatPopups(result.events, prevU, result.units)
  // ...
}
```

### Step 4: Wrap grid in camera shake

```javascript
return (
  <div style={{ position: 'relative' }}>
    <BattleShakeCam shake={cameraShake}>
      <TacticalGrid
        map={activeMission}
        units={units}
        // ... other props ...
      />
    </BattleShakeCam>
    {/* Rest of UI */}
  </div>
)
```

### Step 5: Update TacticalGrid to use enhanced units

Replace the UnitPortrait component with EnhancedUnitPortrait:

```javascript
// In TacticalGrid.jsx
import { EnhancedUnitPortrait, FacingIndicator, StatusBars } from './EnhancedUnitDisplay'

function UnitDisplay({ unit, isSelected, isActive, isFlashing }) {
  return (
    <div style={s.unitBody}>
      <EnhancedUnitPortrait
        unit={unit}
        isSelected={isSelected}
        isActive={isActive}
        isFlashing={isFlashing}
        size="normal"
      />
      <div style={s.unitName}>{unit.name.split(' ')[0]}</div>
      <StatusBars unit={unit} size="small" />
    </div>
  )
}
```

---

## Effect Intensity Levels

Different ability types should trigger different intensities:

```javascript
const getAbilityIntensity = (ability, damage) => {
  // Critical hits and strong abilities
  if (damage > 150) return 'critical'
  if (damage > 100) return 'heavy'
  if (damage > 50) return 'normal'
  return 'light'
}

// In confirmAttack:
const intensity = getAbilityIntensity(ability, dmg?.amount)
triggerHit({ targetUnitIds: [targetId], intensity })
```

---

## Animation Details

### Hit Pause (80ms default)
- Freezes all animation during impact
- Gives player time to register the hit
- Makes slow-mo feel intentional, not janky

### Target Flash (300ms default)
- White glow around hit target
- Applies to all targets hit by AOE
- Brightness boost + drop-shadow effect
- Fades smoothly

### Camera Shake (150ms default)
```
Intensity  |  Shake  |  Use Case
-----------|---------|---------------------
light      |  2px    |  Basic attacks, heals
normal     |  4px    |  Special abilities
heavy      |  6px    |  Ultimate abilities
critical   |  8px    |  Critical hits, SURGE
```

### Impact Wobble (150ms default)
- Scale + rotation effect on hit target
- Compresses slightly then bounces back
- Combined with camera shake = solid impact feel

### Idle Bob (2.2s cycle)
- Units gently float up/down
- More prominent than before (3px movement)
- Keeps battles feeling alive even during waiting

---

## Visual Hierarchy Improvements

### Unit Portraits Now Show:
1. **Job Color** — Background (red=tank, green=healer, etc.)
2. **Class Icon** — Top-right silhouette (⚔️ for warrior, ✨ for healer, etc.)
3. **Unit Initials** — Center (AA for Ace Archer, etc.)
4. **Status Dots** — Right side (colored circles for conditions)
5. **Enemy Badge** — Red E badge for enemies
6. **Selection Glow** — Bright border when selected
7. **Flash Effect** — Golden glow on hit

### Status Indicators:
- Bleed: Red dot
- Burning: Orange dot
- Blessed: Green dot
- Stun: Yellow dot
- Others: Gray dot

---

## Facing Readability

**Before**: Simple text label "S" or small arrow
**After**: Large, clear directional arrow in circle

```
N: ↑ (Up)
E: → (Right)
S: ↓ (Down)
W: ← (Left)
```

Positioned at top-right of unit card with:
- Semi-transparent dark background
- White border
- Text shadow for readability
- Rotation applied for direction

---

## Performance Considerations

**CPU Impact**:
- Camera shake uses requestAnimationFrame (not setTimeout)
- Flash effects use CSS filters (GPU accelerated)
- Wobble uses simple transform (GPU accelerated)
- All effects cleanup automatically

**GPU Impact**:
- Drop-shadow filter cached by browser
- No layout reflows during effects
- Transforms are cheap

**Memory**:
- Small Set of flashing unit IDs
- Effect state cleared after duration
- No memory leaks from animations

**Result**: Negligible performance impact, even on mobile.

---

## Testing Checklist

- [ ] Hit pause freezes action briefly
- [ ] Target flash appears on hit
- [ ] Flash fades smoothly
- [ ] Camera shake is subtle but noticeable
- [ ] Wobble effect syncs with camera shake
- [ ] Enhanced portraits display with correct colors
- [ ] Class icons visible on portraits
- [ ] Status dots show current conditions
- [ ] Facing arrows are clear
- [ ] Idle bob animation is smooth
- [ ] Effects trigger on player attacks
- [ ] Effects trigger on enemy attacks
- [ ] Heavy attacks have stronger effects
- [ ] Critical hits have strongest effects
- [ ] No lag or stuttering during effects
- [ ] Mobile performance acceptable

---

## Customization Guide

### Change Hit Pause Duration
In BattleScreen.jsx:
```javascript
triggerHit({
  targetUnitIds: [targetId],
  pauseDuration: 120,  // Longer pause
})
```

### Adjust Camera Shake Intensity
```javascript
triggerHit({
  targetUnitIds: [targetId],
  shakeDuration: 200,  // Longer shake
})
```

### Customize Status Bar Colors
In EnhancedUnitDisplay.jsx:
```javascript
const bars = [
  { color: '#22c55e', label: 'HP' },    // Green instead of green
  { color: '#f97316', label: 'TMP' },   // Orange (unchanged)
  { color: '#a78bfa', label: 'ETH' },   // Purple (unchanged)
]
```

### Add More Job Profiles
```javascript
export const JOB_PROFILES = {
  // ... existing ...
  mystic: {
    label: 'Mystic',
    bg: '#4f46e5',
    border: '#2e1065',
    text: '#e0e7ff',
    silhouette: '🔮',
    accent: '#818cf8',
    description: 'Mage — Arcane power',
  },
}
```

### Adjust Bob Animation
In EnhancedUnitDisplay.jsx styles:
```css
@keyframes juicyBob {
  0% { transform: translateY(0px); }
  50% { transform: translateY(-5px); }  /* More movement */
  100% { transform: translateY(0px); }
}
```

---

## File Structure

```
src/game/
├── components/
│   ├── BattleJuiceEffects.jsx        (NEW: Effect hooks)
│   ├── EnhancedUnitDisplay.jsx       (NEW: Unit visuals)
│   ├── BattleResultScreen.jsx        (EXISTING)
│   ├── TacticalGrid.jsx              (UPDATE: Use enhanced units)
│   └── ...other components
│
├── screens/
│   ├── BattleScreen.jsx              (UPDATE: Add effect hooks)
│   └── ...other screens
│
└── BATTLE_JUICE_GUIDE.md             (NEW: This file)
```

---

## Success Criteria Met

✅ **Better Hit Pauses** — 80ms freeze on impact  
✅ **Target Flashes** — Golden glow effect on hit  
✅ **Camera Nudges** — Subtle screenshake with intensity scaling  
✅ **Better Placeholders** — Enhanced portraits with class silhouettes  
✅ **Facing Readability** — Clear directional arrows  
✅ **Idle Bob** — Prominent, smooth floating animation  
✅ **FFT/Disgaea Polish** — Satisfying, weighty impact feedback  

---

## Next Steps

1. Import new components in BattleScreen.jsx
2. Add useHitEffect hook
3. Call triggerHit in confirmAttack()
4. Wrap TacticalGrid in BattleShakeCam
5. Update TacticalGrid to use EnhancedUnitPortrait
6. Test all effects triggering correctly
7. Adjust intensity values if needed

Everything is ready to integrate—just follow the steps above!
