# ProjectTactic Visual Style Target

## Current Target

ProjectTactic should use an original tactical RPG presentation style that is:

```text
80% classic isometric tactical RPG readability
20% darker grounded gothic fantasy mood
```

This is the direction from the latest generated asset pass. It keeps the tactical clarity, parchment UI, readable class/job systems, and 2.5D battlefield feel while retaining just enough darker medieval atmosphere to make the game distinct.

## What This Means

### Use More Of

- 2.5D isometric battlefields
- readable tile grids
- clean blue ally deployment tiles
- red enemy threat tiles
- parchment panels with thin gold trim
- class/job icons with jewel-tone coding
- readable serif fantasy UI text
- clear party roster panels
- turn-order badges
- status effect icons with consistent colors
- tactical menu clarity over heavy visual ornamentation

### Use Less Of

- overly dark gothic panels
- dense filigree everywhere
- low-contrast text
- UI frames that overpower gameplay
- realism-heavy screens that feel less tactical
- unsliced concept art inside implementation folders

## Screen Direction

### Character / Status Screen

The character screen should communicate:

- party roster on the left
- selected character in the center
- Temper and Ether bars visible near HP/MP
- current job and job level
- JP to next job level
- equipment slots around the character
- job progression tree on the right
- learned skills below the job tree

### Pre-Battle Deployment

The deployment screen should communicate:

- roster and deployment count on the left
- 2.5D battlefield preview in the center
- clear blue deployment tiles
- red enemy markers and danger areas
- objective and enemy preview on the right
- turn-order preview along the bottom
- large Start Battle button

### Town / Camp Hub

The camp hub should communicate:

- 2.5D town or encampment scene
- clickable service nodes
- party roster summary
- current chapter/date/resources
- active events and effects
- bottom navigation for journal, roster, world map, camp, and depart

### UI Asset Sheet

The UI asset kit should include:

- cursors
- tile highlights
- selected-unit rings
- range overlays
- objective marker
- turn-order badges
- Temper and Ether icons
- status-effect icons
- checkbox/radio states
- button prompt frames
- divider ornaments

## Legal Boundary

Do not use or import commercial game assets, ripped sprites, extracted UI, proprietary maps, or copyrighted source files. The repo should learn from genre patterns and implement original assets.

## Implementation Recommendation

Keep generated reference images in `docs/art-direction/` until they are sliced or recreated as implementation-ready files. Only place final importable assets in `src/assets/`.
