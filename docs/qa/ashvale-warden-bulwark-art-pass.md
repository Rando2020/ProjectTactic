# Ashvale Warden and Hollow Bulwark art pass

Status: implementation candidate  
Branch: `feature/ashvale-warden-bulwark-art-pass`  
Base: `feature/ashvale-arcanist-cantor-art-pass`

## Scope

This batch extends the robust character contracts and adds two individual transparent idle sprites:

| Gameplay ID | Art role | Runtime path | Display target |
|---|---|---|---|
| `kael` | Warden | `res://assets/characters/character-warden-idle-v01.png` | 80 px |
| `null_drake` | Hollow Bulwark | `res://assets/characters/enemy-hollow-bulwark-idle-v01.png` | 95 px |

Both assets use exact 128 × 128 transparent canvases and the shared bottom-center foot anchor.

## Null Drake mapping assessment

The Hollow Bulwark mapping is supported by current combat evidence:

- `MapGenerator.gd` describes Null Drake as “Tanky melee.”
- Its explicit role is `tank`.
- Roguelike values are HP 100, Temper 65, movement 3, speed 5, physical 35, magic 22.
- The hardcoded Ashvale version remains a high-HP, low-mobility physical unit.
- Its stated teaching intent is blocking and positioning.

Those mechanics align directly with Bulwark mass, shield architecture, and defensive stance. The generated art intentionally excludes draconic anatomy. The visible “Null Drake” display name remains a narrative-taxonomy mismatch and should be handled separately from this asset integration.

## Prompt contract improvements

The prompt packs now include:

- Warden shield size, placement, equipment, accent, and stance limits
- Hollow Bulwark shield negative-space, body-mass, and family-language requirements
- Explicit runtime-scale and grayscale acceptance gates
- Role-specific rejection rules for boss scale, shield occlusion, role drift, and draconic anatomy
- Copy-paste-ready Warden and Hollow Bulwark prompts
- Null Drake combat-role evidence embedded in the Bulwark prompt

## Runtime fallback chain

1. Preferred manifest-backed character PNG
2. Existing legacy gameplay sprite
3. Existing procedural team-colored pillar

Missing or invalid preferred files must not prevent battle startup.

## Generation record

- Mode: built-in image generation
- Warden references: accepted Vanguard and Arcanist idle sprites
- Hollow Bulwark references: accepted Hollow Lancer and Hollow Cantor idle sprites
- First Warden candidate: accepted
- First Hollow Bulwark candidate: accepted
- Rejected candidates: none

## Visual review

- Warden is broader than Arcanist and remains within player-unit scale.
- Hollow Bulwark is broader than Cantor and remains below boss scale.
- Shield, head or face plane, torso, weapon hand, and feet remain separable.
- Both retain readable silhouette and luminance separation after 80 px or 95 px grayscale reduction.
- Browser capture must confirm HP-bar clearance, tile anchoring, overlay readability, and contrast in the live Ashvale formation.

## Follow-up

After browser acceptance, the next idle pair should be Wayfarer and Hollow Stray. Storm Imp’s high-mobility profile should be inspected before confirming the Stray mapping. Hollow Lancer remains reserved.
