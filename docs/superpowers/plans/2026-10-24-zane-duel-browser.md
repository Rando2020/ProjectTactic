# Zane Duel Browser QA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox syntax for tracking.

**Goal:** Add an optional real-input movement/sword lane for the isolated duel.
**Architecture:** Separate staged bootstrap, observer subclass and terminal sentinel; reuse CDP transport and existing model/movement assertions without changing old scenarios.
**Tech Stack:** Python unittest/CDP, Godot 4.6.3 GDScript, disposable XDG profiles.
**Spec:** docs/superpowers/specs/2026-10-24-zane-duel-browser-design.md

## Global Constraints
- QA-only files; no production combat, native contracts, assets, workflow or browser flags.
- `zane-duel` uses `begin_zane_duel_practice()` and `rig3d=true`; never `zane_showcase`.
- Exactly Zane `(4,5)` and Storm Imp `(6,5)`, normal stats/initiative/AI; browser acts only in the initial Zane turn.
- Browser first sword only; native title/Fire/terminal/replay coverage is not a browser claim.

## Review Focus
- Extra/duplicate actors and runtime enemy IDs must not masquerade as the exact duel.
- Offscreen/unobserved destinations and targets must not become CDP clicks.
- Miss/immune outcome labels must never claim hit damage or extra armor/critical text.
- Terminal transitions retain verified sword evidence; those before sword fail promptly.
- Failed staging/export must restore exact project bytes and leave old scenarios unchanged.

### Task 1: Isolated staging and read-only native observer
**Files:** `tools/export_browser_qa.py`, `tools/test_export_browser_qa.py`; new `tools/browser_qa/ZaneDuel{Bootstrap,BattleQA,Sentinel}.gd/.tscn`, `ObserverDuelContract.gd/.tscn`.
**Interfaces:** consumes frozen production helper; produces schema-2 snapshot with `duel`, per-unit `archetype`, `legal_attack_targets`, retained `completed_sword` and original-owner `sword_cleanup`.
- [x] Add staging and native contracts; run Python RED (unknown zane-duel scenario), native RED without production helper.
- [x] Implement minimal isolated bootstrap/subclass/sentinel and export admission.
- [x] On actual production commit run native observer contracts and QA export; ensure project bytes/stage restored and production PCK clean.

### Implementation ruling
Initial proposal used Wait before sword to keep a pollable action state. Source
inspection showed that normal hero counters during enemy AI could legitimately kill
the Imp. Parent directed same-turn move+sword instead. Actual native RED then showed
that `turn_ended` precedes the 550 ms owned tail cleanup. Retain distinct action and
owner-keyed cleanup observations, rather than force idle or synthesize a snapshot.
Cost if wrong: false QA acceptance; native JSON is therefore passed through the same
Python invariant validator and repeated with untouched RNG.

### Task 2: CDP sword basics and regressions
**Files:** new `tools/browser_zane_duel.py`, `tools/test_browser_zane_duel.py`; update `tools/browser_combat_smoke.py` routing only.
**Interfaces:** consumes schema above; produces bounded evidence/screenshots and explicit coverage report.
- [x] Write snapshot-invariant and synthetic-CDP transport tests, including terminal rejection and failure reporting; observe RED.
- [x] Implement `ZaneDuelSmoke`, roster/move/target/sword assertions and optional scenario routing.
- [x] Run all Python tests, old native observer contracts, full native gameplay suite and package checks on actual frozen source. Actual Chrome/WebGL2 acceptance remains the parent CI gate.
- [x] Record exact commit/tree/evidence/CLI and obtain independent review before handoff.

### Review fix record
- Important queued-owner timing edge: failed native delayed-tail test, then exact
  still-valid owner lookup (including queued nodes), native GREEN with full JSON
  invariant validation. No production changes or relaxed visual assertions.
- Staging test entrypoint moved below all classes; direct/discovery counts agree.
- Chrome/WebGL2 execution remains an external gate, not a local success claim.
