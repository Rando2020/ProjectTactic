# Zane vs Storm Imp practice design

## Intent and authority
The user wants one hero and one enemy at a time to test the basics, and delegated creative control while preserving story and gameplay. The choices below are implementation defaults under that delegation, not claims that the user specifically approved the title, enemy, coordinates, or API.

## Small feature
Add the distinct title entry **Practice: Zane vs Storm Imp**. Keep both existing full-party practice entries unchanged. Reuse Ashvale, spawning only Zane at `(4, 5)` and the existing Storm Imp at `(6, 5)`: Fire is immediately in range when equipped, or one legal step enables a sword attack. Keep original stats, saved progression/loadouts, real AI, initiative/tie rules, Fire cost/range/fan, action timing, and all other combat rules. Do not equip omitted skills or grant rewards/training for this duel.

## Approaches and delegated choice
1. **Reuse the practice sandbox with a session-only mode (chosen):** smallest seam, retains the canonical-save baseline/checkpoint, RunManager snapshot/RNG restoration, presentation controls, and real battle/results scenes.
2. Separate battle/manager implementation: isolates the roster but duplicates combat and risks diverging rules; rejected.
3. Shrink existing practice: fewer UI entries, but destroys the preserved full-party demo; rejected.

## Interfaces and flow
- `GameState.begin_zane_duel_practice() -> bool` wraps existing `begin_practice()` and adds `practice_session["mode"] = "zane_duel"`. Existing admission signature/callers stay unchanged.
- `GameState.is_zane_duel_practice() -> bool` reads only that session mode.
- The title callback uses the helper, sets `rig3d = true` (new Zane presentation), and loads the existing battle. It does not set `zane_showcase`; the original showcase contract remains distinct.
- Battle spawning selects only Zane and only Storm Imp before instantiation, then shares the existing player stat/resource setup and enemy setup. Runtime enemy ID may be `Enemy_1`; archetype is `unit_data.id == "storm_imp"`.
- A distinct visible banner explains movement/sword/Fire without promising Fire if a saved loadout omits it.
- Duel victory and defeat both offer **Replay Fight** plus **Return to Hearth**. No JP/gold reward or Kael training UI; the backend also rejects training mutation for the duel.
- Existing `can_retry_practice()` / `retry_practice()` accept either duel terminal state, restoring the original checkpoint without recapturing battle gains. Session presentation flags persist. Duplicate clicks are guarded by current state and existing ResultsScreen transition latch.
- Exit and reload retain existing canonical-state/settings safety. No new persistent save fields or settings. As in existing practice, detaching the active run starts with normal maximum combat resources; replay restores those original duel starting resources, and exit restores the exact saved in-run resources.

## Evidence and boundaries
Add a strict isolated native contract exercising the real title button, exact roster/positions, fresh-profile first turn, legal move/sword/Fire/cancel/input guards/cost, enemy AI, both results/replays, duplicate transitions, saved loadout/progression, baseline/checkpoint identity, RunManager RNG, save/settings bytes, and reload. Register it in the existing runner; preserve existing showcase tests verbatim. Browser duel QA is a separate lane.

No BattleManager, combat formula/resolver, AbilityDB, TurnOrder, asset, CI architecture, GUI, remote Git write, merge, deployment, credential, or configuration changes.
