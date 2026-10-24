# Ashvale Arcanist and Hollow Cantor art pass

Status: implementation candidate  
Branch: `feature/ashvale-arcanist-cantor-art-pass`  
Base: `feature/ashvale-first-character-art-pass`

## Scope

This batch strengthens the reusable character prompt contract and adds two individual transparent idle sprites:

| Gameplay ID | Art role | Runtime path | Display target |
|---|---|---|---|
| `mira` | Arcanist | `res://assets/characters/character-arcanist-idle-v01.png` | 80 px |
| `void_cultist` | Hollow Cantor | `res://assets/characters/enemy-hollow-cantor-idle-v01.png` | 95 px |

Both assets use exact 128 × 128 transparent canvases and the shared bottom-center foot anchor.

## Prompt contract improvements

The hero and enemy prompt packs now specify:

- Fixed three-quarter isometric camera and team-facing direction
- Runtime display dimensions and 96 × 48 tile context
- Exact visible-pixel, baseline, center, and edge-clearance targets
- Accepted Vanguard and Hollow Lancer reference responsibilities
- Role-specific equipment and silhouette constraints
- Grayscale, alpha, and small-size review gates
- Automatic rejection conditions for floors, shadows, contact sheets, edge crops, and role drift
- Copy-paste-ready prompts for Arcanist and Hollow Cantor

## Mapping decision

- Mira maps naturally to Arcanist because the existing gameplay role is Mage.
- Void Cultist maps naturally to Hollow Cantor because both are mid-range ritual casters.
- Hollow Lancer is removed from the Void Cultist mapping and remains reserved.
- Null Drake and Storm Imp retain their existing fallbacks. Neither is a defensible lancer match.

This decision changes art-role presentation only. Gameplay IDs, display names, stats, abilities, AI, and encounters remain unchanged.

## Runtime fallback chain

1. Preferred manifest-backed character PNG
2. Existing legacy gameplay sprite
3. Existing procedural team-colored pillar

Missing or invalid preferred files must not prevent battle startup.

## Generation record

- Mode: built-in image generation
- Arcanist style reference: `character-vanguard-idle-v01.png`
- Hollow Cantor style reference: `enemy-hollow-lancer-idle-v01.png`
- Source prompts:
  - `prompts/assets/characters/hero-squad-vanguard-arcanist-warden-wayfarer-v01.md`
  - `prompts/assets/characters/enemy-pack-hollows-and-elites-v01.md`
- First Arcanist candidate: accepted
- First Hollow Cantor candidate: accepted
- Rejected candidates: none

## Visual review

- Arcanist remains distinct from Vanguard through a narrower silhouette and compact focus device.
- Hollow Cantor retains the Hollow family language without reading as a spear user.
- Both remain identifiable after runtime-size reduction and grayscale conversion.
- Browser capture must confirm HP-bar clearance, foot placement, team contrast, and overlay readability.

## Follow-up

After browser acceptance, generate Warden and Hollow Bulwark as the next broad-silhouette pair. Keep Hollow Lancer reserved until gameplay introduces a compatible reach unit or explicitly approves a taxonomy migration.
