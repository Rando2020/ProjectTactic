# Build UI Polish — Boon System Enhancement Summary

## What Was Changed

### Files Created:
1. **`src/game/components/BoonCard.jsx`** — Reusable boon card component with hover details
2. **`src/game/UI_BOON_POLISH.md`** — Detailed design documentation

### Files Modified:
1. **`src/game/screens/BoonPickScreen.jsx`** — Enhanced with lane info and selection context
2. **`src/game/screens/BoonReplacementModal.jsx`** — Clearer lane limit explanations

---

## Key Features Implemented

### 1. Hover Cards (BoonCard.jsx)
- **Full variant**: Detailed hover cards showing description, flavour, lane status
- **Compact variant**: Minimal hover tooltips for modal use
- **Lane visualization**: Visual progress bar showing current/max slot usage
- **Smooth animations**: Fade-in effect with CSS keyframes

### 2. Lane Information Display
**BoonPickScreen**:
- Lane badge on each card showing "Movement (1/2)"
- Selection reason explaining why boon was offered
- Lane full warning if choosing would exceed limit
- "Your Blessings" summary showing current boons

**BoonReplacementModal**:
- Lane visualization bar showing full/empty slots
- Clear explanation of lane limits
- Red-bordered alert style for constraint warning
- Three-part flow: Why → Incoming → Choose

### 3. Selection Context
- **Lane-aware explanations**: "2 slots available in movement lane"
- **Synergy fallback**: "Synergy with your current build" for non-lane boons
- **Full lane alert**: "Movement lane is full" when capacity reached

### 4. Visual Polish
- **Color coding**: Gold labels, rarity-colored borders, red warnings
- **Typography**: Clear hierarchy with uppercase labels
- **Layout**: Improved spacing and card grid sizing
- **Feedback**: Lane full warnings and selection reasons

---

## How It Works: The Lane System

### Lane Detection
```javascript
// In BoonCard.jsx and BoonPickScreen.jsx
const lane = getBoonLane(boon)  // Returns: 'movement' | '' | etc.
```

### Lane Counting
```javascript
// Get boons in a specific lane
const laneBoonsCount = getBoonsInLane(activeBoons, 'movement').length
// Result: 1 (out of limit of 2)
```

### Capacity Checking
```javascript
// Check if adding would exceed limit
const laneIsFull = laneBoonsCount >= BOON_LANE_LIMITS[lane]
// If true: show "Choose & Replace" button, trigger modal on click
```

### Replacement Flow
```
User clicks boon in full lane
  ↓
Modal displays:
  - Current lane status (visual bar)
  - Incoming boon preview
  - Existing boons (radio options)
  ↓
User selects one to replace
  ↓
onConfirm(newBoon, replacedBoonId)
```

---

## Component Hierarchy

```
GameShell / BattleScreen
  ├── BoonPickScreen
  │   ├── Header
  │   ├── Your Blessings (if activeBoons.length > 0)
  │   └── Boon Grid
  │       └── BoonCard[variant="full"]
  │           ├── Card Content
  │           └── Hover Card (on mouse enter)
  │
  └── BoonReplacementModal (conditional render)
      ├── Lane Visualization
      ├── Incoming Blessing
      │   └── BoonCard[variant="compact"]
      ├── Choose One to Replace
      │   └── BoonCard[variant="compact"] × N (radio selectable)
      └── Action Buttons
```

---

## Component Props Reference

### BoonCard.jsx
```jsx
<BoonCard
  boon={boonObject}                    // Required: the boon to display
  onSelect={handleSelect}              // Optional: callback on selection
  isSelected={boolean}                 // Optional: highlight state
  activeBoons={[...]}                  // Optional: for lane counting
  selectionReason={string}             // Optional: explain why offered
  variant={'full'|'compact'}           // Optional: default 'full'
  showLaneInfo={boolean}               // Optional: show lane badge, default true
/>
```

### BoonPickScreen.jsx Props
```jsx
<BoonPickScreen
  gameState={gameState}                // Required: has activeRun.boons
  onChooseBoon={handleBoonSelection}   // Required: called when boon picked
  setScreen={setScreen}                // Required: for "Back to Map" button
/>
```

### BoonReplacementModal.jsx Props
```jsx
<BoonReplacementModal
  incomingBoon={boonObject}            // Required: the boon being chosen
  existingBoons={[...]}                // Required: current boons in lane
  onConfirm={handleReplacement}        // Required: (newBoon, replacedId) => {}
  onCancel={handleCancel}              // Required: dismiss modal
/>
```

---

## Visual Design Details

### Colors Used:
- **Gold (#c9a756)**: Section labels, important UI, accents
- **Rarity Colors**: Borders, progress indicators, hover states
  - Common: #94a3b8
  - Rare: #fbbf24
  - Legendary: #a855f7
  - Unique: #ef4444
- **Red (#ef4444)**: Lane full warnings, replacement alerts
- **Background**: Transparent dark (10,14,24), overlay at 84-98% opacity

### Typography:
- **Eyebrow**: 12px uppercase, gold, letter-spaced
- **Title**: 26px bold
- **Section Title**: 12px uppercase, gold
- **Card Title**: 20px bold
- **Body**: 14px regular
- **Meta**: 12-11px, reduced opacity

### Spacing:
- **Panel padding**: 24px
- **Section margins**: 24px
- **Card gaps**: 14px in grid
- **Internal card gaps**: 10px
- **Modal max-width**: 620px

---

## Testing the Implementation

### Quick Test Flow:
1. **BoonPickScreen**
   - [ ] Shows "Your Blessings" section with current boons
   - [ ] Cards display lane badges (e.g., "Movement (1/2)")
   - [ ] Selection reasons appear below descriptions
   - [ ] Hover shows detailed card with flavour and lane progress bar
   - [ ] "Choose & Replace" button appears if lane is full

2. **BoonReplacementModal**
   - [ ] Triggers when clicking a boon in a full lane
   - [ ] Shows red alert with lane full message
   - [ ] Displays lane visualization bar with filled slots
   - [ ] Shows incoming boon in compact format
   - [ ] Lists existing boons as radio options
   - [ ] Selecting and confirming works

3. **Visual Quality**
   - [ ] Colors are consistent with rarity system
   - [ ] Text is readable on all backgrounds
   - [ ] No layout shifts or jank
   - [ ] Animations are smooth
   - [ ] Mobile responsive (3→2→1 column as width decreases)

---

## Integration Notes

### With Existing Game State:
The system assumes:
- `gameState.activeRun.boons` contains array of currently selected boons
- Each boon has `id`, `icon`, `rarity`, `name`, `description`, `flavour`, `effect`
- `getCurrentNode(run)` returns current floor node with `.options` (boon choices)

### With Lane System:
- `getBoonLane()` correctly identifies movement boons
- `BOON_LANE_LIMITS` defines the cap (currently 2 for movement)
- New lanes can be added by extending both

### With Rarity System:
- `BOON_RARITIES` provides color, border, glow for each rarity
- Cards properly inherit rarity styling
- Hover cards use rarity colors for progress indicators

---

## Future Extensions

### Additional Lanes:
To add an "Elemental" lane with cap of 1:

1. Update `boons.js`:
   ```javascript
   export const BOON_LANE_LIMITS = {
     'movement': 2,
     'elemental': 1,  // NEW
   }
   ```

2. Update `getBoonLane()` to detect elemental boons:
   ```javascript
   // Detect boons with fire/ice/thunder/holy affinity
   if (boon.element && ['fire','ice','thunder','holy'].includes(boon.element)) {
     return 'elemental'
   }
   ```

3. Tag boons explicitly if needed:
   ```javascript
   {
     id: 'fire_mastery',
     element: 'fire',
     lane: 'elemental',  // EXPLICIT OVERRIDE
     // ...
   }
   ```

### UI Enhancements:
- Show boon synergies (which boons work well together)
- Preview stats with incoming boon applied
- Exclude incompatible boons from selection
- Undo system for one replacement per run

---

## Implementation Status

✅ **Completed**:
- BoonCard component with hover details
- BoonPickScreen enhancements
- BoonReplacementModal improvements
- Lane information display
- Selection context generation
- Visual polish and styling
- Documentation

⏳ **Ready for**:
- Integration testing with game state
- Visual QA (color, spacing, animation)
- Mobile/responsive testing
- Player feedback iteration

---

## Files Summary

| File | Status | Purpose |
|------|--------|---------|
| `src/game/components/BoonCard.jsx` | ✨ NEW | Reusable card with variants |
| `src/game/screens/BoonPickScreen.jsx` | 🔄 UPDATED | Selection with lane info |
| `src/game/screens/BoonReplacementModal.jsx` | 🔄 UPDATED | Clearer replacement flow |
| `src/game/UI_BOON_POLISH.md` | ✨ NEW | Design documentation |
| `src/game/data/boons.js` | ✓ NO CHANGE | Lane system already in place |

---

## Questions / Notes

- **Lane visualization**: Are the progress bar colors (using rarity color) clear enough?
- **Modal frequency**: Will players encounter lane full situations regularly enough for the modal to feel intentional?
- **Hover positioning**: Should hover cards appear differently on mobile (since hover doesn't exist)?
- **Lane names**: Should "Movement" lane have a different label for clarity?
