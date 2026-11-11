# Job Mastery Runtime Implementation Plan

> **For agentic workers:** Execute this bounded continuation in the native engineering task and independently review the branch.

**Goal:** Make the existing earned Squire, Warder and Luminary scalar mastery bonuses work in actual combat.

**Architecture:** JobTreeData projects supported mastery scalars. BattleScene snapshots them on Unit and applies movement once. CombatFormula remains the single calculation source for forecasts and CombatResolver.

**Tech Stack:** Godot 4.6.3, GDScript, existing Python/Node gates and GitHub Actions.

**Spec:** ../specs/2026-11-11-job-mastery-runtime-design.md

## Global constraints
- Preserve saves, ability ownership, action costs, random-roll count and new-character behavior.
- Apply only earned supported effects; explicitly document all omitted mastery promises.
- Mirror the same small deltas into campaign and standalone courtyard sources.

## Review focus
- JP 799 vs 800, unknown jobs and class switches must not award or erase mastery incorrectly.
- Repeated factory calls and preview calls must not accumulate stats or write saves.
- Counter mastery changes the threshold, not eligibility, and never chains counters.
- Warder reduction must match real HP/Temper spending and exclude magical/true damage.
- Luminary healing must handle flat run bonuses, full HP and overheal caps identically in intent/preview/resolution.

## Task 1: Runtime projection and regression
- [ ] Add failing real-factory/mastery combat tests to tests/test_job_mastery.tscn in both projects; verify intended failures.
- [ ] Add supported mastery scalar projection, Unit snapshot and factory/character Move integration.
- [ ] Add shared counter chance, physical reduction and caster-aware heal formulas; wire actual resolver and enemy intent.
- [ ] Run focused contracts green, existing production gameplay suite and supported courtyard contracts.

## Task 2: Publication
- [ ] Register new contract in existing aggregate/release gates.
- [ ] Record supported vs pending class effects and exact verification.
- [ ] Independent review, fix findings, then publish PR under existing GitHub authorization.
- [ ] Verify exact-head CI before merging and check actual Pages provenance before any live claim.
