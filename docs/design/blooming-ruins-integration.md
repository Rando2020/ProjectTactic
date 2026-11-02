# Blooming Ruins: integrate the art with ProjectTactic

## Review baseline

GitHub main was compared with local baseline
`5941987ff4e295a8037e8d36e25b2938fa0f0966` during this review and was identical.
The playable Blooming Ruins experiment is in draft #96, stacked on draft #94.
This document records inspected code and the next implementation scope; it does
not claim that the isolated demo is already wired into campaign battles.

## What we already have

| Existing source | Verified capability | Reuse in the next slice |
|---|---|---|
| `godot/scripts/presentation/PracticeTerrain3D.gd` | SubViewport renders 3D terrain; projected tile centers align with the authoritative TacticalGrid; redraws on terrain changes; missing meshes fall back | Apply the painted terrain treatment through this presentation seam |
| `godot/scripts/grid/TacticalGrid.gd` | Existing cell interaction, highlights and optional terrain presentation | Keep one cell-to-screen contract for art, feet, picking and targeting |
| `godot/scripts/battle/BattleManager.gd` | Commands, cancellation, movement budget/jump, ability resolution, enemy intent, action-state and forecast signals | Own the encounter; do not expand the demo's parallel resolver |
| `godot/scripts/battle/BattleUI.gd` | Production command UI; illustrated-chapel presentation variant | Keep real commands and their availability; retain forecast work from #94 when integrated |
| `godot/scripts/data/MapData.gd` | Heights, terrain, props, spawns, deployment, objectives and reward configuration | Author Blooming Ruins as data instead of embedding the board in Stage.gd |
| `godot/scripts/data/AssetRegistry.gd`, `godot/data/asset_manifest.json` | Registered art and fallbacks, including Zane's illustrated portrait and four directions | Reuse approved character identities and art before generating replacements |
| `godot/scripts/systems/GameState.gd`, `godot/scripts/battle/BattleScene.gd` | Character defaults, Practice session lifecycle and battle integration | Use an opt-in Practice entry with retry/exit and save isolation |

The existing Painted Chapel is a different experiment: one background image and
a flat 5×5 playable lower floor. Its drawn stairs are scenery. It demonstrates
integration with combat, but cannot itself supply traversable upper terraces.

## Important differences in the new demo

The isolated demo reuses CombatFormula and TurnOrder, but owns its own movement,
attack execution, enemy decisions, controls and terminal conditions. Its stats,
6-MP Light and 8-MP Heal are prototype rules, not canonical ability definitions.

Production defaults make Zane an Arcanist with Fire/Thunder/Void abilities; Mira
an Arcanist on a Luminary path with Cure/Holy support; Kael a Squire with a
defensive progression path; Lyra a Scout. Restore those loadouts through the
existing character/unit construction path. The three-character demo is not the
full established four-person party. Avoid presenting Zane as a sword-only class.

The asset manifest already has directional illustrated Zane artwork and separate
Mira, Kael, Lyra and enemy art. The generated six-cell demo atlas proves the
cutout technique; it should not silently replace those registered identities.

## Recommended next playable increment

Build **Blooming Ruins Practice** in the production battle scene:

1. Represent the board, heights, blocked masonry and spawns as MapData. Start with
   the supported defeat-all objective. The demo's defeat-plus-reach-gate rule
   requires an explicit objective implementation and tests; a new objective_type
   string alone does not implement it.
2. Extend the existing opt-in terrain presenter with painted stone/soil materials
   and simple stair geometry. Keep TacticalGrid authoritative. Verify projection
   at every height, not just the flat board corners. Visual stairs must match
   legal movement/jump rules; the demo's special stair-only adjacency is separate.
3. Spawn the established party and registered sprites through BattleScene. Preserve
   directional facing, feet anchors and production abilities. Use decorative
   flower/tree cutouts only where they do not obscure legal targets.
4. Drive the existing BattleUI from BattleManager signals. Keep movement/ability
   cancellation, real MP costs, enemy intent and action availability. Expose
   Temper/Ether alongside HP where they explain damage absorption.
5. Enter through Practice and reuse its result/retry/exit lifecycle. Connect to
   route rewards only after Practice acceptance, using the existing progression
   path rather than a second currency/save implementation.

This retains the actual game while changing how its battlefield is presented.
The SubViewport approach is a fixed-camera fit, not automatic free-camera 3D.
Foreground architecture may need a separate occluder layer or cutaway treatment
to overlap 2D units correctly; a flattened terrain render does not provide that
depth interaction for free.

## Design ideas that fit the repository

The design pillars prioritize tactical clarity, job identity, interactive terrain
and one complete playable loop. For this small encounter, emphasize two viable
routes, one readable elevation advantage and clearly telegraphed enemy pressure.
Reuse an existing terrain reaction only after confirming its resolver and preview
agree. Do not expand the job catalog or run length to make this demo feel richer.

The cast guide frames Mira as a witness and Zane as a listener. A later objective
could involve preserving a record or protecting a witness in Ashvale. That is a
proposal requiring narrative/objective work, not an implemented mission or new canon.
Older browser-first wording and migration wish lists must be read alongside the
current Godot-first CLAUDE.md and actual runtime; a design document is not proof
that every described mechanic exists.

## Integration acceptance

- Cell picking, highlights and unit feet agree on both terraces and stair lanes.
- Blocked walls cannot be traversed; terrain costs and jumps use production rules.
- A production ability previews and resolves the same recipients, MP, armor and HP.
- Enemy intent agrees with the action; cancel/retry/exit do not spend extra resources.
- Practice leaves the canonical save unchanged; rewards cannot be awarded twice.
- HUD remains legible at 720p and 1080p; foreground decor does not hide targets.
- Native capture and WebGL2 browser playtest use the actual integrated scene.

Run the repository stability check and targeted scene contracts after code changes.
The isolated demo's 29 checks do not establish these production integration gates.
The release target remains Godot 4.6.3; the demo's local 4.6.2 test is not a release
export or deployment claim.
