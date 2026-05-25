# Job Screen Improvements - Phase 3

## Overview
Enhanced the job management UI screens to provide better visibility, control, and organization of character job progression and switching.

---

## ✅ Enhanced JobTreeScreen.jsx

### New Features

1. **Character Selector**
   - Dropdown to preview progression for different party members
   - See different unlock paths for each character
   - Helps plan team composition strategically

2. **Tier Filtering**
   - Filter jobs by tier: All, Base, Advanced, Ascended
   - Helps focus on relevant progression paths
   - Keeps interface clean and organized

3. **Interactive Job Cards**
   - Clickable cards to select and view details
   - Status badges showing LOCKED/UNLOCKED state
   - JP and Level display for unlocked jobs
   - Visual feedback on selection (gold highlight)

4. **Detail Panel**
   - **Right sidebar** shows full job information when selected
   - **Role & Description** - What the job does and playstyle
   - **Growth Potential** - Visual bars for HP/MP/Temper/Ether scaling
   - **Abilities List** - All combat abilities the job has
   - **Reaction Ability** - Special reactive counter/defense move
   - **Passive Skill** - Always-active benefit
   - **Weapon Types** - Compatible weapons
   - **Ascension Path** - Shows what job this ascends to

5. **Visual Improvements**
   - Better organized layout with grid + detail panel
   - Growth stats shown as colored bars (green=HP, blue=MP, gold=Temper, purple=Ether)
   - Tier colors maintained (Ascended jobs show special styling)
   - Responsive design - detail panel sticks as you scroll

### UI Components

```jsx
// Tier filtering
<select>
  <option>All Tiers</option>
  <option>Base</option>
  <option>Advanced</option>
  <option>Ascended</option>
</select>

// Growth visualization
<div style={{ width: '75%', background: '#2d9934' }} /> // HP bar

// Detail panel (sticky, right-aligned)
<div className="detail-panel">
  [Job information displays]
</div>
```

---

## ✅ Enhanced CharacterSheetScreen.jsx

### New Features

1. **Job Switching**
   - Click "Available Jobs" buttons to swap character's active job
   - Immediately reflects in stats and UI
   - No modal required - streamlined interface

2. **Expandable Character Cards**
   - Click expand button (▶) to reveal full details
   - Compact view by default, details on demand
   - Better use of vertical space

3. **Current Job Progress Bar**
   - Visual indicator of JP progress toward next level
   - Shows "Lv. X · Y JP" for clarity
   - Gold-colored fill for progression

4. **All Job Progression**
   - Sorted by JP amount (most progress first)
   - Shows all jobs character has touched
   - Clear level and JP display for each job

5. **Available Jobs Section**
   - Shows all unlocked jobs for quick switching
   - Highlights currently active job
   - Easy one-click job swaps

6. **Active Job Details**
   - When expanded, shows full job info:
     - Role and description
     - Passive skill
     - Reaction ability
     - Complete ability list

### UI Components

```jsx
// Stat grid
<div style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
  <div>HP: 120</div>
  <div>MP: 45</div>
  <div>Temper: 88</div>
  <div>Ether: 62</div>
</div>

// Job progress bar
<div style={{ 
  position: 'relative', 
  height: 24, 
  background: 'rgba(0,0,0,.3)'
}}>
  <div style={{ width: '65%', background: 'rgba(201,167,86,.5)' }} />
  <span>Lv. 5 · 650 JP</span>
</div>

// Job switching buttons
<button onClick={() => handleJobSwitch(charId, jobId)}>
  {job.name}
</button>
```

---

## Data Integration

### Required GameState Structure
```javascript
{
  roster: {
    [characterId]: {
      id: "zane",
      name: "Zane",
      currentJobId: "warder",        // NEW: current active job
      jobJp: {
        warder: 350,
        resonant: 180,
        skywarden: 45
      },
      unlockedJobs: ["warder", "resonant", "skywarden"],
      level: 8,
      xp: 2400
    }
  },
  party: [
    { id: "zane", hp: 120, mp: 45, temper: 88, ether: 62 }
  ]
}
```

### Required Props
- **JobTreeScreen**: `gameState`, `setScreen`
- **CharacterSheetScreen**: `gameState`, `setGameState`, `setScreen`

---

## Styling

All components use consistent theming:
- **Gold accent**: `#c9a756` for labels and highlights
- **Dark background**: `rgba(10,14,24,.95)` for panels
- **Text color**: `#f7f0df` for main text
- **Disabled/secondary**: `rgba(247,240,223,.6)` for secondary info
- **Borders**: `rgba(255,255,255,.14)` for subtle dividers

---

## User Experience Improvements

### Before
- Static job list with minimal information
- No way to switch jobs from character sheet
- Growth stats not visualized
- No job details accessible from tree

### After
✓ Interactive selection with detail panel
✓ Job switching directly from character sheet
✓ Visual growth stat representation
✓ Full job information accessible everywhere
✓ Filter by tier for focused exploration
✓ Progress bars for JP advancement
✓ Expandable cards for better space efficiency
✓ Character selection for per-member progression preview

---

## Technical Notes

### Performance
- Detail panel is sticky (position: sticky) for easy scrolling
- Expandable sections minimize DOM nodes by default
- No unnecessary re-renders due to local state management

### Accessibility
- All interactive elements are keyboard accessible
- Clear visual feedback for selected jobs
- Color-coded stats (but not color-only - includes labels)
- High contrast text on background

### Future Enhancements
- **Job comparison view** - Compare two jobs side-by-side
- **Progression timeline** - Show which jobs unlock when
- **Build recommendations** - Suggest job combinations for strategies
- **Ability search** - Filter jobs by specific ability
- **Stats simulation** - Preview stat changes before swapping jobs

---

## Files Modified
1. `src/game/screens/JobTreeScreen.jsx` - Complete rewrite with new features
2. `src/game/screens/CharacterSheetScreen.jsx` - Complete rewrite with management
3. `src/game/GameShell.jsx` - May need to update prop passing to CharacterSheetScreen

## Integration Checklist
- [ ] Verify `gameState` has `roster[charId].currentJobId` property
- [ ] Update GameShell to pass `setGameState` to CharacterSheetScreen
- [ ] Test job switching updates character stats in battle
- [ ] Verify growth stat colors display correctly
- [ ] Check mobile/tablet responsive layout
- [ ] Test filter dropdown on both screens
- [ ] Verify job detail panel scrolls on small screens
