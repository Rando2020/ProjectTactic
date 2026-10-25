# Zane duel practice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A separate one-on-one Zane/Storm Imp practice entry that preserves combat rules and saved progress.

**Architecture:** Extend the existing in-memory practice session with a `zane_duel` mode admitted by a helper. Branch roster selection before instantiation, share stat/resource setup, and reuse original checkpoint replay and ResultsScreen transition guards.

**Tech Stack:** Godot 4 / GDScript; Python unittest runner contracts.

**Spec:** `docs/superpowers/specs/2026-10-24-zane-duel-practice-design.md`

## Global Constraints
- Keep both existing full-party entries, 4+3 rosters, and Lyra-first contracts unchanged.
- Ashvale Zane `(4, 5)` vs Storm Imp `(6, 5)`; original saved stats/loadout; normal practice starting resources; real AI/initiative/combat rules.
- Session-only `mode = zane_duel`; no canonical fields/settings or free skills/rewards/training.
- Both terminal outcomes offer **Replay Fight** and **Return to Hearth**; replay restores original checkpoint and preserves session flags.
- No combat-core/assets/CI architecture edits, GUI, push, merge, deploy, credentials, or configuration changes.

## Review Focus
- An equipped loadout without Fire remains without Fire, including replay.
- Saved progression/resources and active-run runtime/RNG state survive the sandbox and exit.
- Victory does not mutate the original checkpoint or grant hidden Kael training/JP/gold.
- Rapid double admission/replay/exit cannot duplicate transitions or overwrite a baseline.
- Real enemy actions and lethal Fire may transition to results before a harness can reuse battle references.

## Task 1: One-on-one practice lifecycle and contract
**Files:**
- Modify: `godot/scripts/ui/StartScreen.gd`, `godot/scripts/systems/GameState.gd`, `godot/scripts/battle/BattleScene.gd`, `godot/scripts/ui/ResultsScreen.gd`, `godot/scripts/presentation/PracticeComparison.gd`.
- Create: `godot/tests/test_zane_duel_practice.gd`, `godot/tests/test_zane_duel_practice.tscn`.
- Modify: `tools/check_playable_loop.py`, `tools/test_check_playable_loop.py`.

**Interfaces:**
- Consumes existing `begin_practice()`, `_restore_practice_checkpoint()`, `retry_practice()`, `leave_practice()`, real `BattleManager.select_command/select_ability/_on_tile_clicked`, and scene transitions.
- Produces `begin_zane_duel_practice() -> bool`, `is_zane_duel_practice() -> bool`, `practice_session.mode == "zane_duel"`; exact title entry and terminal **Replay Fight** button. Uses `rig3d = true`, not `zane_showcase`.

- [x] Step 1: Write native failing contract and runner registration expectations. Assert real entry exists, old entries stay, exact two actors/archetype/positions and natural first Zane turn; legal cancel/one-step/sword/Fire 12 MP/fan/range/input guard and real AI; victory/defeat replay restore original state and flags without rewards/training; duplicate transitions, custom loadout/progression/resources, RunManager RNG and canonical/settings bytes remain safe.
- [x] Step 2: Run isolated native contract and `python -m unittest tools.test_check_playable_loop -v`; expect missing new entry and unregistered strict case failures before product edits.
- [x] Step 3: Implement only the declared helper/roster/results/banner branches and register the new strict case outside `LEGACY_CONTRACTS`.
- [x] Step 4: Run focused native contract and runner tests until green. Then run unchanged full-party showcase and static stability checks. Defer the complete native contract runner to integration, per parent task direction; do not repeat the legacy aggregate here. Expect zero test failures and no new strict-case diagnostics.
- [x] Step 5: Record red/green evidence and bounded limitations, locally commit the feature for a frozen independent review. No remote writes.
