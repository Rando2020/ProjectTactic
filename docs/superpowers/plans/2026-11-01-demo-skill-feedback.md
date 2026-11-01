# Existing 2v2 Skill Completion Implementation Plan

> **For agentic workers:** Use subagent-driven-development; check each task below against actual demo paths.

**Goal:** Complete readable, contact-synchronous feedback and target/queue context for the existing demo skills.
**Architecture:** Preserve BattleManager/CombatResolver authority and ActionLifecycle tickets. Extend disposable presentation helpers, not game rules. UI consumes read-only forecast recipients and current enemy plans.
**Tech Stack:** Godot 4.6.3, GDScript, existing authored RGBA sheets, procedural sound.
**Spec:** User requests existing skills feel complete, classic tactical impact rhythm, and target portraits/intent/queue links. Parent handoff November 1 2026.

## Global Constraints
- Only standalone demos/isometric-2v2; preserve Fire/basic melee, original assets, exact costs/powers/statuses/initiative.
- No new skills, charge-turn mechanics, turn shifting, paid assets or production/main changes.
- Preview is not execution; enemy plans may change. No fake queue movement.
- Source and exported tests required; no browser/phone/audio claims without actual evidence.

## Review Focus
Cancellation/duplicate input cannot spend twice; chain forecasts match actual ordered recipients; KO/retry clears cosmetics; heal/guard never present damage reactions; camera/skin changes preserve anchors.

- [x] Add failing actual Skirmish tests for missing shared outcome ownership, chain/heal/status/guard and recipient preview contracts.
- [x] Wire existing abilities into admitted presentation and report actual resolver outcomes once; add optional heal feedback ownership.
- [x] Add modular presentation/frame helpers and shared cast; independently inspect and test art.
- [x] Add affected portraits/current intent/actual queue linkage and cancellation cleanup.
- [x] Run all source and packed demo suites, native visual review when available, regress existing Fire/melee.
- [ ] Publish only authorized prototype and same private Site, then verify exact remote and live bytes. Record unavailable acceptance separately.
