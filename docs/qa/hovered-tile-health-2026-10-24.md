# Hovered-tile health repair — focused verification

## Scope and source effects
- Base: `347925b2823f069ef6cc3241802e0ca1280d4989` (tree `7cc0c3efb6447cf0884d08b0846f74bf85d5e12c`).
- Only runtime file changed: `godot/scripts/battle/BattleManager.gd`.
- Added a dedicated last-inspected cell, reset on battle start and populated only by real tile hover.
- Extracted the existing tile readout formatting into a display-only helper. Its validity/liveness/tree-membership checks never call registry-cleaning `_living_unit`/`_unit_at_pos`.
- Subscribed to existing unit HP, movement, and tree-exit events; a second defeat callback reads final HP after existing survival boons. The only refresh output is `tile_info_changed`.
- No polling, synthetic hover, selection change, preview/path/AoE/target-lock refresh, combat calculation, resource mutation, action ordering, RNG, story, asset, save/config, or gameplay-rule change.
- Added a new strict native contract and registered it outside the legacy shutdown exceptions; extended the existing Python runner's registration and diagnostic rejection cases. Original duel/showcase fixtures remain unchanged.

## Red → green evidence
1. Existing Python runner baseline: **11 tests passed**.
2. New runner expectation before registration: failed specifically for missing `test_hovered_tile_health.tscn`; registration then passed.
3. New native fixture against unchanged production: **45 checks, 10 failures**, all stale readout/occupancy assertions. The real legal Fire left the actual BattleUI label at `Storm Imp 90/90 HP` after exactly one real mouse-motion hover. State-isolation checks passed.
4. Display repair: **45 checks, 0 failures**.
5. Added existing-Phoenix edge test with post-defeat refresh absent: **50 checks, 1 failure** (empty occupant despite final HP = 1); restored the display callback: **50 checks, 0 failures**.

An initial test-harness attempt used the headless window's default physical size with scaled viewport coordinates and did not hover a tile. The fixture now explicitly uses 1920×1080 and feeds a real Input mouse-motion event. The final RED run above had valid initial labels, target lock/fan, and exactly one hover; there were no script or engine diagnostics. This was test setup correction, not product-input modification.

## Final focused verification
Godot `4.6.3.stable.official.7d41c59c4`, fresh isolated XDG data/config/cache per process:
- `godot --headless --path godot res://tests/test_hovered_tile_health.tscn`: **50 checks, 0 failures**, exit 0.
- Unchanged `test_zane_duel_practice.tscn`: **179 checks, 0 failures**, exit 0.
- Unchanged `test_zane_impact_showcase.tscn`: **84 checks, 0 failures**, exit 0.
- All three outputs contain **zero warnings/errors**, including shutdown diagnostics.
- `python -m unittest tools.test_check_playable_loop -v`: **11 tests passed**, including new fixture registration, script-error rejection, and non-legacy shutdown-resource-error rejection.
- `node tools/check_godot_stability.mjs --skip-godot`: passed with **19 inherited warnings**.
- `git diff --check`: passed.

Full logs: `/workspace/shared/zane-hover-health-evidence/`. The parent owns the combined aggregate, independent review, and native/browser integration; no broad aggregate was run in this isolated lane.

## Evidence boundaries
The real-Fire test uses the original duel spawns, normal equipped Fire and cost, actual action execution, live resulting HP/max HP (no hardcoded damage roll), and the actual BattleUI Label. Separate explicitly labeled Unit damage/heal/Burn, movement, lethal/removal/freed-registry, and Phoenix fixtures are deterministic contract probes, **not natural-play victories, earned-boon demonstrations, or visual/pointer QA screenshots**. Control snapshots cover command/ability, phase, lifecycle/ticket, actor actions/resources, selection/target/path/AoE/ranges, preview/hover emissions, and RunManager RNG; a real heal additionally proves no global RNG consumption.

No GUI, push, merge, deployment, credential, or configuration operation was performed. No permission denial or unresolved blocker occurred.
