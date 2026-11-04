# Haste application aura candidate

One new painterly **world-space Haste effect layer**, unintegrated and unapproved. This is not another Haste icon, an animation sheet, or new mechanics. No existing effects or game files are replaced.

## Why this asset
The merged production catalog inventories 76 unique historical v11 combat PNGs: shared cast 4; Fire 16; melee 8; Thunderstrike, Void Pulse, Dark Breath and Shadow Mend 12 each. Its existing Haste image is a UI icon study, not a character-ground aura. The inventory is historical evidence, not proof of current-main runtime use.

Fresh main-source inspection confirms `godot/scripts/vfx/VFXManager.gd::play_haste` already implements eight procedural golden Line2D streaks and a flash. `AbilityDB.gd` defines Haste. This candidate fills the missing painted aura layer only. It is not evidence that Haste is currently exposed in every 2v2 loadout. Delay Strike and Heavy Slash expansion are not part of this package.

## Reuse and status
- Keep existing 76 frames: see `evidence/historical-76-frame-inventory.csv`.
- Keep current Haste logic and procedural visual untouched.
- This PNG is one static application-aura candidate. It could be evaluated with scale/fade in a later isolated review, but no timing, loop, pivot, or binding is supplied as validated.
- The ellipse and upward streaks are one image; placing a character inside it requires deciding front/back occlusion. Do not silently put the whole ring over a character.
- 80 px width is a proposed review size, not calibrated geometry. Actual rendered body/ground footprint must guide final scale.

## Evidence
- Current VFX: https://github.com/Rando2020/ProjectTactic/blob/main/godot/scripts/vfx/VFXManager.gd#L495-L514
- Ability definition: https://github.com/Rando2020/ProjectTactic/blob/main/godot/scripts/data/AbilityDB.gd#L202-L211
- Existing catalog: https://github.com/Rando2020/ProjectTactic/tree/3b1958e28e60b4f15593f242e8127a67e46a19b3/assets/source/production-catalog-2026-11-04

## QA and next gate
Original PNG is RGBA with real alpha; numeric results are in `alpha-qa.json`. No pixels were edited. Inspect over both pale and dark terrain at gameplay size, choose footprint/pivot and front/back layering, then test short application timing without covering the unit. No engine integration, animation, browser or human visual acceptance is claimed.

## Provenance
Generated for ProjectTactic with OpenAI built-in image generation on November 4, 2026. Full prompt is included. This records provenance, not a blanket license grant. No external purchased art, font or software is included.
