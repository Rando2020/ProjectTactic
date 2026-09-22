# Ashvale battle HUD clearance pass

Status: implementation candidate  
Branch: `feature/ashvale-battle-hud-clearance`  
Base: `feature/ashvale-wayfarer-stray-art-pass`

## Problem

The persistent battle controls used fixed coordinates near the horizontal center of a 1920 × 1080 viewport. Normal-zoom browser captures showed the control panel covering the central formation and preventing reliable character-art review.

PR 69 also moved unit names, HP bars, and indicators above full-height sprites, but status icons retained a fixed vertical position and could overlap enemy art.

## Changes

- Anchor the persistent command panel to a computed right rail.
- Use a 360 px rail at widths of 1600 px and above.
- Use a 320 px rail below 1600 px.
- Keep the rail within the rightmost 30 percent at supported QA sizes.
- Recalculate the rail when the viewport changes.
- Share command-row width equally so all four actions remain inside the rail.
- Position status icons from the same unit HUD baseline as names and HP bars.
- Capture CI screenshots at 1600 × 900 and 1366 × 768, both at device scale factor 1.

## Preserved behavior

- Combat commands and keyboard shortcuts are unchanged.
- Turn order, enemy intent, active-unit statistics, battle log, loadout strip, action preview, and settings remain available.
- Character manifest, legacy sprite, and procedural fallback layers are unchanged.
- React is untouched.

## Acceptance gates

- Persistent controls do not cover the central Ashvale formation at 1600 × 900.
- The compact rail remains inside a 1366 × 768 viewport.
- Move, Attack, Wait, and Ability remain visible in both rail sizes.
- Unit names, HP bars, team indicators, and status icons clear full-height sprites.
- Tactical overlays and selected tiles remain readable.
- Godot headless validation and Web export pass.
