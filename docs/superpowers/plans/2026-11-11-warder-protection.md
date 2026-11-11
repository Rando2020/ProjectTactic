# Warder Protection Implementation Plan

**Goal:** Activate existing Cover and Iron Wall with consistent targeting, outcomes, turn duration and feedback.

**Architecture:** Unit owns battle-local weak Cover links and owner-turn lifecycle. CombatFormula and CombatResolver share a one-hop recipient query; manager consumers follow authoritative recipient outcome references. Iron Wall uses existing armor projections and explicit action gates.

**Tech Stack:** Godot 4.6.3 GDScript; native scene tests; existing Python/Node release gates.

**Spec:** docs/superpowers/specs/2026-11-11-warder-protection-design.md

## Global Constraints
- Mirror shared behavior under godot and demos/isometric-2v2; preserve their intentional presentation differences.
- No save/ownership/unlock order changes. No new artwork or legacy React runtime work.
- Cover: 0 MP, base range 1/mastery 2, one link, protector next begin_turn.
- Iron Wall: 10 MP, 0.6 multiplier, two future owner turns, Move/Wait allowed.

## Review Focus
- Stale targets after an awaited presentation must not spend resources or misapply effects.
- Interceptor death must not leave the protected ally receiving its statuses/kill feedback.
- Area/follow-up calls that reuse single-target resolution must not accidentally intercept.
- Forecasts are read-only and do not consume RNG, links, MP or statuses.
- Action locking must not disable ordinary spent-action counterattacks on other units.

### Task 1: Iron Wall runtime
Files: mirrored Unit.gd, CombatFormula.gd, CombatResolver.gd, BattleManager.gd, ActionLifecycle.gd, ForecastCalculator.gd; tests/test_warder_protection.gd and .tscn.
Interfaces: existing calls remain compatible; receive_damage adds an optional Iron Wall mitigation flag so terrain retains its previous Defend/Ether handling.
- [x] Write real-manager failing assertions for 10 MP once, 40% reduction, normal/magical/true damage, multiplicative stacking, two future owner turns, movement and counter/action blocking.
- [x] Run both scene tests and confirm behavioral failures before product edits.
- [x] Implement mitigation, explanation and action/admission/contact gates without using has_acted to forbid ordinary reactions.
- [x] Run focused tests green and existing mastery/healing/action lifecycle suites.
- [x] Commit scoped implementation and tests.

### Task 2: Cover links and authoritative recipients
Files: mirrored Unit.gd, AbilityDB.gd, JobTreeData.gd, CombatFormula.gd, CombatResolver.gd, ForecastCalculator.gd, BattleManager.gd; extend native protection tests.
Interfaces: AbilityDB.get_range(ability, caster=null); Unit.get_damage_recipient(attacker, allow_cover=true); Unit.can_cover_ally(target); Unit.cover_ally(target); outcomes include recipient_id/recipient_ref and protected_id only when redirected.
- [x] Write failing assertions for actual Cover cast, 1/2 range, threshold, linked owner expiry, duplicate rejection, no self/enemy/dead target, dynamic range and disabled protector.
- [x] Write failing direct-hit forecast/resolution and literal damage checks, plus misses, crits, one-hop links, KO/freed references and explicit area exclusions.
- [x] Implement weak links, one-hop query, effective range and current recipient defenses while preserving aimed tile context.
- [x] Follow outcome recipient through statuses, counters, CT, kill effects, logs and feedback; keep ground effects on aimed tile.
- [x] Run tests green, add manager/presentation regressions for interruption and read-only forecasts, commit.

### Task 3: Practice feedback and release
Files: demo practice loadout/selection adapter as necessary; demo protection UI tests; workflow and aggregate test registry; docs.
- [x] Add failing practice tests for real skill menu/review/cancel/confirm, action lock, no saved ownership changes, and recipient-specific feedback.
- [x] Enable existing protection skills in battle-local Kael practice options and truthful generic aura/text feedback.
- [ ] Run native/rendered tests and inspect captured frames, then full aggregate/static/script/Python/Node gates.
- [ ] Obtain fresh independent review and fix verified findings.
- [ ] Publish draft, verify remote tree and all exact-head CI, merge only when green.
- [ ] Verify automatic deployment, exact live source_commit and Hosted Pages smoke; report delivered scope and remaining class gaps.

## Review follow-up
The first independent review identified integration gaps outside the direct resolver fixtures. Added real basic-attack Echo tests, terrain with and without Defend/Ether, and enemy Finish text. These initially failed and now pass in both runtimes (89 protection checks each). Courtyard sword versus area-weapon handling is covered through the real encounter adapter and practice suite, not a substituted resolver. Final rendered, hosted and CI verification remains a separate release requirement.
