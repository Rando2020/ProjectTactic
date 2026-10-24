# Scout Tradeoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make Quickstep exchange the action for one second move and enforce Long Shot's existing dead zone.
**Architecture:** AbilityDB owns canonical range normalization. BattleManager owns action admission/contact and action economy; existing UI and forecast expose the same costs. Headless Battle.tscn tests exercise real input signals.
**Tech Stack:** Existing Godot 4.6.3/GDScript and Python contract runner; no new dependencies.
**Spec:** `docs/superpowers/specs/2026-10-24-scout-tradeoff-design.md`

## Global Constraints
- Base 21f43db; isolated checkout only; no publication/merge/deploy/GUI.
- Quickstep 5 MP, existing access, one movement after moving, consumes action, no stat buff.
- Long Shot 3–5 tiles, power 60, MP 0; no other balance or system expansion.
- Preserve story, CT, saves, job history, other skills and support AI.

## Review Focus
- Repeated UI callbacks during anticipation/recovery must not double-spend or restore action.
- MP/access/actor state changing at contact must reject without gameplay effects.
- Stale Long Shot targets entering the 1–2 tile dead zone must not be hit.
- Movement after action must forecast turn end, including Wait and next-turn reset.
- Default and self ability ranges, including area secondaries, must not regress.

## Task 1: Canonical Long Shot range
**Files:** AbilityDB.gd, BattleManager.gd, `godot/tests/test_scout_tradeoff.gd/.tscn`.
**Interfaces:** `AbilityDB.get_ability(id)` returns canonical min_range/range; `_ability_target_in_range(unit,target,ability)` consumes normalized bounds.
- [x] Add real-scene regression for player highlight/preview/input and enemy candidate/intent legality at distances 1, 2, 3, 5 and 6; assert 3 and 5 accepted, others rejected.
- [x] Run regression and observe player dead-zone failures.
- [x] Normalize existing aliases with canonical-field precedence; use shared bounds in selection/validation; revalidate Long Shot contact without constraining secondary AoE targets.
- [x] Verify fresh candidate passes and forecast matches realized normal/critical damage in guaranteed-hit fixture.

## Task 2: Quickstep action tradeoff
**Files:** BattleManager.gd, AbilityDB.gd, ForecastCalculator.gd, BattleUI.gd, same scene regression.
**Interfaces:** Scoped Quickstep eligibility + execution use existing manager turn flags and action lifecycle. No new persistent state or resource.
- [x] Add early/acted/MP/repeated rejection, real first-move → Quickstep → second-move lifecycle, 5 MP once, no HP/stat/status change, no attack and normal next-turn reset tests.
- [x] Add asynchronous contact invalidation and double button-click cases; assert movement and MP unchanged on rejection.
- [x] Run and observe failures before implementation.
- [x] Dispatch Quickstep before generic buffs, validate before/after presentation, consume action/reopen movement only after successful contact.
- [x] Expose action cost in ability menu/forecast and truthful post-action movement preview; preserve immediate self-cast.
- [x] Run regression then full existing gameplay runner; register this contract in the runner.

## Task 3: Verification and handoff
- [x] Run static stability, headless production parse, story, gameplay, presentation and HUD contracts; report any baseline failures/warnings.
- [x] Review exact diff against approved scope and obtain independent review.
- [x] Commit only scoped source/tests/docs; record hash, test counts and evidence paths. Do not publish.
