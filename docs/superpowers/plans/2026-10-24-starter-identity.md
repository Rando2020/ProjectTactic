# Starter identity first-slice implementation plan

> **For agentic workers:** Use executing-plans for this narrow approved implementation; TDD followed by independent whole-branch review.

**Goal:** Give the existing Fire definition one identity, preserve raw ownership, and make the current-job JP shop truthful.
**Architecture:** Pure canonical/known/equipped/catalog/quote projections; user-initiated learn/equip writes only. CharacterScreen consumes those contracts. No save migration.
**Tech Stack:** Godot 4.6.3, GDScript, headless scene tests.
**Spec:** [Bounded starter-identity contract](../../production/starter-identity-first-slice.md). Only this first slice is approved; broader loadout migration remains excluded.

## Global constraints
- Base: `c80a025930a7e27c6fc2def169b82b1e23d1e3f5`, tree `a5667343e47548eaca8f51e36acb9f70ecc96e28`.
- Only `fireball -> fire`; existing Fire definition and prices unchanged. This alias is an approved repair inference, not historical mechanics evidence.
- Preserve raw base/learned/equipped records, JP, history, story and save fields on reads/restore. No load-time write or version bump.
- Explicit setter counts unique valid canonical abilities before four-slot cap. Legacy empty equipment still means all-known and remains uncapped. Do NOT claim a global four-slot repair.
- No new abilities/prices/refunds/grants/teacher mechanics, combat healing/status/Quickstep changes, GUI use, publication, merge or deploy.
- SaveSystem slot serialization and empty-loadout revision migration remain omitted known gaps.

## Review focus
- Alias and canonical IDs mixed in base/learned/equipped arrays; unresolved ownership stays queryable.
- Empty or wholly unowned equipped arrays retain the legacy all-known fallback; unresolved-but-owned selections do not silently broaden access.
- Missing/negative/fractional/string prices never charge; true integer zero stays free; owned unpriced definitions stay equippable.
- UI click after job/JP/ownership changes revalidates; displayed price and charge share one quote.
- Read projections and restore do not rewrite disk or normalize raw legacy arrays; practice still persists the baseline.

### Task 1: Pure contracts and character shop
**Files:** AbilityDB.gd, GameState.gd, CharacterScreen.gd; test_starter_identity.gd/.tscn.
**Interfaces:** AbilityDB.canonical_id(id), canonical_ids(ids), get_ability(id); GameState.get_known_abilities(uid), get_equipped_abilities(uid), get_learnable_abilities(uid), get_ability_purchase_quote(uid,id), existing knows/learn/setter APIs.
- [x] Write failing tests for alias/ownership/projections, explicit setter unique cap, unknown and unpriced rejection, exact 100/80/0 costs, duplicate/stale clicks, UI price/reasons, and fresh/restore/job consistency.
- [x] Run headless test scene, inspect intended failures.
- [x] Add pure projections, retain all raw entitlement arrays, derive catalog from existing jobs, share quote with UI and revalidate on purchase.
- [x] Run tests green and existing progression/playable/Silence/outcome suites.

### Task 2: Persistence and review evidence
**Files:** same test scene; production handoff document.
- [x] Test raw unknown base/learned/equipped restore, two primary roundtrips, read-only hash, JP/history/story and practice retry/leave baseline.
- [x] Restore saved base ownership from existing unit_resources when present (no new save schema); no mutation on queries.
- [x] Run project static checker, story check, all runnable Godot tests with isolated HOME/XDG and record any baseline failures.
- [x] Commit exact frozen branch and request independent review; no publication.

## Execution rulings / evidence
- Preserve raw legacy catalog metadata too, rather than updating it on restore/job switch; all actual purchase/UI consumers use the pure current-job projection. This avoids serializing read-time cleanup and costs a deprecated, non-authoritative field remaining in old saves.
- Keep ownership-before-availability fallback semantics: nonempty owned unresolved-only equipment produces no usable skills, not an accidental all-known grant. Empty and wholly unowned selections retain old all-known behavior. No strict four-slot migration is claimed.
- Primary persisted-value roundtrip assertions normalize Godot JSON numeric Variant types; pure in-memory queries assert strict equality and disk hashes. Practice intentionally clears death-presentation context in its checkpoint as before; the saved baseline and exit restore preserve it.
- Initial LFS pointer import failure was environmental, not an accepted baseline warning. Hydrated 364 SHA-256-verified local objects, restored only generated import sidecars, then cold-imported cleanly. Corrected-environment RED reproduces 23 checks / 12 intentional failures; GREEN has 109 checks / 0 failures.
