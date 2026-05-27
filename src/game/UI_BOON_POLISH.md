# Boon UI Polish — Hades-Style Enhancement

## Overview

The boon selection experience has been enhanced with Hades-style progression mechanics, better visual presentation, and clearer mechanical explanations. Players now understand **why** boons are offered, what **lanes** are, and what happens when lanes reach capacity.

---

## Components & Structure

### 1. **BoonCard.jsx** (New Component)
A reusable boon card component used in both boon selection and replacement flows.

#### Features:
- **Two Variants**:
  - `variant="full"` — Full card for BoonPickScreen with hover details
  - `variant="compact"` — Minimal card for BoonReplacementModal options

- **Hover Card Display**:
  - Full description and flavour text
  - Lane status visualization (progress bar showing used/total slots)
  - Current lane occupancy with color-coded indicators
  - Smooth fade-in animation

- **Lane Information**:
  - Shows which lane a boon belongs to (e.g., "Movement (1/2)")
  - Visual warning if lane is full
  - Lane slots display as a visual progress bar in hover

- **Selection Context**:
  - Optional `selectionReason` prop to explain why this boon was offered
  - Visual styling for different card states (selected, full, etc.)

### 2. **BoonPickScreen.jsx** (Enhanced)
Main boon selection screen redesigned for clarity and Hades-style feel.

#### New Features:

**Your Blessings Section**:
- Shows all currently active boons in a summary strip
- Each boon displays as a compact item with icon and name
- Visual indicator of progression through the run

**Improved Boon Cards**:
- Lane badge showing lane name and slot usage (e.g., "Movement (1/2)")
- Selection reason displayed below description (e.g., "1 slot left in movement lane")
- Lane full warning if choosing would exceed capacity
- Hover cards showing detailed information

**Better Selection Context**:
- `getSelectionContext()` function generates per-boon explanations:
  - General: "Synergy with your current build"
  - Lane-specific: "2 slots available in movement lane"
  - Full lane: "Movement lane is full"

**Visual Hierarchy**:
- Updated grid spacing and sizing
- Better typography pairing
- Clear separation of current boons from selection options

#### Key Props Passed to BoonCard:
```jsx
<BoonCard
  boon={boon}
  onSelect={onChooseBoon}
  activeBoons={activeBoons}
  selectionReason={getSelectionContext(boon)}
  variant="full"
  showLaneInfo={true}
/>
```

### 3. **BoonReplacementModal.jsx** (Enhanced)
Modal that appears when a lane reaches capacity, clarifying the limitation and choice.

#### New Features:

**Lane Capacity Visualization**:
- Red-bordered modal indicating a critical decision
- Title includes warning emoji: "⚠️ Movement Lane is Full"
- Clear explanation of the lane limit (max 2 movement boons)

**Lane Status Bar**:
- Visual progress bar showing total slots in the lane
- Filled slots displayed in rarity color
- Empty slots in subtle gray
- Shows exact count: "2/2 (FULL)"

**Three-Part Flow**:
1. **Incoming Blessing** — Preview of the new boon using BoonCard
2. **Lane Visualization** — Shows why this decision is necessary
3. **Choose One to Replace** — Radio selection of existing boons

**Enhanced Visual Feedback**:
- Section icons: `+` for incoming, `→` for choices
- Each existing boon shown as a selectable card
- Radio buttons styled with golden accent color (#c9a756)

#### Selection Flow:
```jsx
// User sees:
// 1. Why replacement is needed (lane limit explanation)
// 2. Visual lane status (progress bar)
// 3. What they're adding (incoming boon card)
// 4. What they can replace (existing boon options)
```

---

## Lane System Mechanics

### What are Boon Lanes?
Lanes are categories of boon effects that have per-run limits. Currently implemented:

**Movement Lane**
- Limit: 2 boons per run
- Includes: Movement stat bonuses, tactical movement abilities
- Boons: Windrunner Step, Battle Fury, Reaping Step

### How It Works:
1. **Detection** — `getBoonLane(boon)` identifies a boon's lane
2. **Counting** — `getBoonsInLane(activeBoons, lane)` counts current boons in the lane
3. **Enforcement** — `needsLaneReplacement()` detects when limit would be exceeded

### Lane Limit Structure (boons.js):
```javascript
export const BOON_LANE_LIMITS = {
  'movement': 2,
}
```

**Extending to new lanes**: Simply add a new entry to `BOON_LANE_LIMITS` and tag boons with `lane: 'new_lane_name'` in their definition.

---

## UI/UX Improvements

### Visual Polish:

1. **Hover Cards**
   - Appear on boon interaction (full variant only)
   - Include icon, name, rarity, description, flavour
   - Show lane progress visualization
   - Auto-positioned above card with smooth fade-in

2. **Lane Badges**
   - Compact badge showing lane name + slot usage
   - Appears in card top-right for quick reference
   - Color-coded to rarity if full/unavailable

3. **Color Coding**
   - **Gold (#c9a756)** — Labels, important UI elements
   - **Rarity colors** — Card borders, progress bars
   - **Red (#ef4444)** — Lane full warnings and replacement modal
   - **White/Gray** — Neutral content, disabled states

4. **Typography Hierarchy**
   - Eyebrow: 12px uppercase (section labels)
   - Title: 26px bold (screen title)
   - Card title: 20px bold (boon name)
   - Description: 14px regular
   - Flavour: 12px italic

### Information Density:

**BoonPickScreen**:
- Shows current boons → selection options → detailed hover info
- Sufficient context without overwhelming
- Progressive disclosure through hover interaction

**BoonReplacementModal**:
- Immediate explanation of the problem (lane full)
- Visual lane status bar shows the constraint
- Clear choices presented with preview cards
- Three distinct sections keep flow logical

---

## Code Integration

### In GameShell.jsx (or equivalent):
```jsx
import BoonPickScreen from '../screens/BoonPickScreen'
import BoonReplacementModal from '../screens/BoonReplacementModal'

// When displaying boon selection:
<BoonPickScreen 
  gameState={gameState} 
  onChooseBoon={handleChooseBoon} 
  setScreen={setScreen} 
/>

// When lane capacity reached:
{showReplacementModal && (
  <BoonReplacementModal
    incomingBoon={pendingBoon}
    existingBoons={existingBoonsInLane}
    onConfirm={handleReplacement}
    onCancel={handleCancel}
  />
)}
```

---

## Adding New Boon Lanes

To extend the system with new lanes:

1. **Define the lane in boons.js**:
   ```javascript
   export const BOON_LANE_LIMITS = {
     'movement': 2,
     'elemental': 1,  // NEW: Max 1 elemental boon
   }
   ```

2. **Update getBoonLane() logic** (boons.js):
   ```javascript
   export function getBoonLane(boon) {
     if (boon.lane === 'elemental') return 'elemental'
     // ... rest of logic
   }
   ```

3. **Tag boons with the lane**:
   ```javascript
   { 
     id: 'my_elemental_boon',
     name: 'Fire Mastery',
     // ...
     lane: 'elemental'
   }
   ```

4. **Update getLaneLabel()** in BoonPickScreen and BoonReplacementModal if needed.

---

## Design Philosophy

### Hades-Style Progression
- **Clear feedback**: Players always know why boons are offered
- **Meaningful constraints**: Lane limits create strategic depth
- **Visual hierarchy**: Important info is prominent, details on demand
- **Respectful interactions**: Hover reveals, no spam

### Player Trust
- **Transparency**: Lane limits are explained, not hidden
- **Consistency**: Same boon always shows same lane status
- **Clarity**: Visual indicators reinforce mechanical constraints
- **Respect**: Warnings given before forcing replacement

---

## Testing Checklist

- [ ] Hover cards appear and disappear smoothly
- [ ] Lane badges show correct slot counts
- [ ] Selection reasons are accurate (lane-specific vs. synergy)
- [ ] Replacement modal appears when lane would exceed limit
- [ ] Lane visualization bar is accurate
- [ ] Radio button selection works correctly
- [ ] Incoming boon preview is clear
- [ ] Replacement is confirmed correctly
- [ ] BoonCard compact variant works in both contexts
- [ ] Colors match rarity system
- [ ] Text is readable on all backgrounds
- [ ] Mobile responsiveness (grid adjusts)
- [ ] No layout shifts when hovering

---

## Future Enhancements

1. **More Lanes**: Add restriction lanes as needed (e.g., "Elemental Cap", "Healing Lane")
2. **Synergy Indicators**: Show which boons combo together
3. **Exclusivity**: Mark boons that can't be taken together
4. **Preview Mode**: Show predicted stats with incoming boon
5. **Undo System**: Allow one boon swap per run
