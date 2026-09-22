# Ashvale Wayfarer and Hollow Stray art pass

Status: implementation candidate  
Branch: `feature/ashvale-wayfarer-stray-art-pass`  
Base: `feature/ashvale-warden-bulwark-art-pass`

## Scope

This batch extends the character contracts and adds two individual transparent idle sprites:

| Gameplay ID | Art role | Runtime path | Display target |
|---|---|---|---|
| `lyra` | Wayfarer | `res://assets/characters/character-wayfarer-idle-v01.png` | 80 px |
| `storm_imp` | Hollow Stray | `res://assets/characters/enemy-hollow-stray-idle-v01.png` | 95 px |

Both assets use exact 128 × 128 transparent canvases and the shared bottom-center foot anchor.

## Storm Imp mapping assessment

The Hollow Stray mapping is supported by current combat evidence:

- `MapGenerator.gd` describes Storm Imp as a fast flanker.
- Its explicit role is `fast`.
- Roguelike values are HP 75, movement 4, jump 2, speed 10, Magic 42, and Ether 80.
- Thunderstrike is a range-4 chain attack.
- Void Pulse is a range-3 silence attack.
- The 80 percent spawn chance supports an irregular arrival pattern.

Those mechanics align with Stray asymmetry, light equipment, forward-ready posture, and a compact magical conductor. The generated art intentionally excludes horns, tail, wings, hovering, and other legacy imp anatomy. The visible `Storm Imp` name remains a narrative-taxonomy mismatch and should be handled separately from this asset integration.

## Lyra mapping assessment

Lyra is explicitly a Scout with movement 4, jump 2, speed 9, minimum attack range 2, and a progression built around Pin Shot, Long Shot, Quickstep, Rain of Arrows, Smoke Screen, and Shadow Step. Wayfarer communicates those mechanics through a compact bow, lean open silhouette, travel equipment, and alert stance.

## Prompt contract improvements

- Role-specific equipment, stance, accent, and negative-space rules
- Gameplay evidence embedded in both generation prompts
- Color and grayscale acceptance gates at runtime size
- Explicit rejection of active attack effects and legacy imp anatomy
- Copy-paste-ready Wayfarer and Hollow Stray prompts

## Runtime fallback chain

1. Preferred manifest-backed character PNG
2. Existing legacy gameplay sprite
3. Existing procedural team-colored pillar

Missing or invalid preferred files must not prevent battle startup.

## PR 68 review carry-forward

PR 68 identified fixed unit HUD coordinates crossing full-height sprites. This branch positions the unit name, HP bar, and team indicator above the actual scaled sprite canvas while preserving the original procedural-fallback position.

## Generation record

- Mode: built-in image generation
- Wayfarer references: accepted Vanguard, Arcanist, and Warden sprites
- Hollow Stray references: accepted Hollow Lancer, Cantor, and Bulwark sprites
- First Wayfarer candidate: accepted
- First Hollow Stray candidate: accepted
- Rejected candidates: none

## Visual review

- Wayfarer remains readable in color and grayscale at 80 px.
- Hollow Stray remains readable in color and grayscale at 95 px.
- Bow, conductor, hands, face plane, torso, and feet remain separable.
- Browser capture must confirm HUD clearance, tile anchoring, overlays, and contrast in the live Ashvale formation.

## Follow-up

After browser acceptance, resolve whether legacy display names should change or remain intentionally dissonant. Hollow Lancer remains reserved until a compatible reach unit exists.
