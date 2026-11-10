# Hero Test Weapons Implementation Plan

**Goal:** Give the existing courtyard heroes two selectable test weapons without adding heroes or changing campaign equipment/saves.

**Architecture:** A courtyard-only BattleManager subclass shares a pure cardinal footprint function between targeting, previews and committed damage. A HUD subclass adds two explicit loadout buttons and preserves the existing target-review-confirm lifecycle. Existing damage formulas, status skills and enemy AI stay authoritative.

**Tech Stack:** Godot 4.6.3, GDScript, existing native test and Web CI lanes.

## Provisional test design
- Kael: Sword (default), Greatsword. Zane: Sword (default), Spear.
- Sword hits the adjacent cardinal cell. Spear hits the first two cells on one cardinal line. Greatsword hits a three-cell row centered one cell ahead, perpendicular to the aim direction.
- Aim determines attack facing. Diagonal aiming is invalid. Spear may also aim at the second cell. Greatsword may aim at an empty center if an enemy occupies its footprint.
- Board edges and walls clip areas; a wall stops spear penetration. Allies are skipped, including allies between spear and enemy. No friendly fire.
- Use existing per-target physical damage, hit, crit and counter rules. No final balance claim. No weapon-stat bonuses.
- Swaps are free before the action, including after movement, but unavailable during resolution, after acting, or on another unit's turn. A swap invalidates pending review. Replay starts both heroes with Sword.
- Text explicitly labels these provisional test loadouts and enemy-only rules. Character artwork does not change with equipment.

## Review focus
Stale confirmation after swap; invalid diagonal or wall aim; actual collateral matches preview; replay/save isolation; readable controls at supported UI scales.

## Tasks
- [x] Write a native failing test for missing weapon controls, geometry and actual selection/confirmation behavior.
- [x] Implement pure footprints and courtyard-only manager/HUD adapters. Preserve skill/AI paths.
- [x] Verify cardinal directions, edges/walls, ally/KO filtering, actual multi-hit resolution, cancel/duplicate confirm, equipment/turn locks and save/replay reset.
- [ ] Run current native scenes, parser, Python and Web suites; inspect actual renderer captures via CI if local display is unavailable.
- [ ] Independent scoped review, publish draft PR, verify exact-head CI, then coordinate safe merge/deployment with parent.
