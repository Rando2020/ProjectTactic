# Consistent hero idle sprites v02

Status: **candidate assets for Godot Web PR review**, not a final animation release.

## Scope

A four-hero, four-direction set of 256×256 RGBA PNGs lives at `godot/assets/characters/iso-v02/`. Each texture uses the same canvas, neutral character lighting, and a nominal foot contact point at (128, 245). The PNGs are derived from the larger per-character isometric sprite sheets, rather than the later, crowded four-hero composite sheets. Production art is original and stylistically adjacent to classic isometric tactics games, not copied from a proprietary game.

| Gameplay ID | Sprite role | Asset stem |
| --- | --- | --- |
| zane | Swordsman | character-swordsman-idle |
| mira | Mage | character-mage-idle |
| lyra | Rogue | character-rogue-idle |
| kael | Dragoon | character-dragoon-idle |

**Important:** Art roles do not change gameplay jobs, equipment, stats, save IDs, or story canon. In particular, Kael's dragoon visual is a **temporary art demonstration** rather than a confirmed role redesign.

## Runtime facing adapter

The existing game uses cardinal facings N/E/S/W rather than diagonal labels. The manifest maps:

| Godot facing | Manifest direction | Source 3/4 view |
| --- | --- | --- |
| S | front | sw |
| E | right | se |
| N | back | ne |
| W | left | nw |

The adapter in `godot/scripts/units/Unit.gd` calls `AssetRegistry.get_character_direction_candidates(unit_data.id, direction)` and retains `unit_data.sprite_sheet` as a final fallback. For Zane, the previously illustrated directional sprite paths remain first fallback candidates. A 3D opt-in display still owns its visual and is not changed by 2D texture switching.

`Unit` anchors sprites with the bottom of their 256px canvas at the tile origin. The authored foot line is y≈245, giving around 3 game-pixel vertical padding at 80px display height. Selection, HP bars, abilities, AI, damage preview, and enemy art are unchanged.

## Quality checks and future improvements

- `tools/test_hero_sprite_v02.py` checks all 16 real PNG files, PNG transparency, canvas dimensions, foot-line consistency, per-hero view distinctness, and manifest references.
- Review at **80px** character height on the 96×48 tile, including high-contrast selection rings and the ruined chapel floor. The files are not yet native Web-play-tested in this PR environment.
- These are single-frame *idle views*, not directional walking, attacks, casts, or skeletal animation frames. No animation may be inferred from their existence.
- Generated view asymmetry is still possible around equipment hands, flowing cloth, and lighting; a human consistency review remains required. Image-based checks cannot prove true anatomy.
- The largest visual ambiguity is the difference between intended character canon (especially Zane, Kael, and Lyra) and provisional class visualizations. Preserve previous assets through the manifest until art direction is signed off.
- Source image sheets and QA contact sheets should stay with the art production archive outside `godot/assets/`. Runtime includes only normalized sprite PNGs.
- If the four-view test fails on an upcoming art revision, revert a named asset path or let `AssetRegistry` load its existing fallback.

## Follow-up

After the PR's Godot import, unit tests, and Web build pass, capture a real 1v1 arena screenshot of each facing and confirm tile-foot alignment with movement. Only then consider animations or enemy replacements.
