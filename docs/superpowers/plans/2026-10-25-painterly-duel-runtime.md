# Painterly Duel Runtime Implementation Plan

> **For agentic workers:** Execute inline with superpowers:executing-plans; use TDD and a final independent review.

**Goal:** Route only the existing Zane duel to the approved painterly model without changing combat or the full-party comparison.

**Architecture:** Keep the exact impact adapter script identity and add an allowlisted, pre-tree profile configuration. Unit selects the candidate only in duel practice and disposes failed adapters before trying fresh impact, original Zane, then visible sprite. Native tests exercise the real imported asset; browser assertions remain separately pinned per route.

**Tech Stack:** Godot 4.6.3/GDScript, Python unittest.

**Spec:** `/workspace/scratch/ccbd55cd809f/painterly-zane-evidence/integration-contract.md`.

## Global Constraints
- Base `63d80906e56332d2ac43f1ed3fb5687ecb11edc7`; isolated runtime branch only; no publication/GUI/install.
- Candidate `zane_painterly_v1`, existing `zane_impact_v1`; exact approved res paths only.
- Candidate LINEAR at 192 Standard / 384 High with existing MSAA; impact remains pixel160/NEAREST.
- Same 138.24 local canvas footprint, 3.2 camera / 30 pitch / 45 yaw; apply Unit scale once.
- No gameplay, timings, CT, RNG, status, death, cost, lighting, shader or global settings changes.
- Preserve feedback owner `zane_impact_v1`, all existing metadata rejection, original baseline SHA and changed-clips semantics; candidate inherits all nine impact animations.
- Asset author owns GLB/Blend/atlas/metadata hashes. Never commit placeholder GLBs or call synthetic fixture results visual acceptance.

## Review Focus
- Unknown or mutable self-declared profile must not bypass configured identity.
- Reconfiguration after first tree entry (even detached) must reject without mutation.
- Candidate failures must leave a fresh pixel-style fallback, never orphan/blank the actor.
- Malformed nested provenance must reject without GDScript errors.
- Imported textures and vertex colors must survive the actual Godot importer.

## Task 1: Adapter profile and routing
Files: `godot/scripts/presentation/ZaneImpactRigPresentation.gd`, `godot/scripts/units/Unit.gd`, `godot/tests/test_zane_painterly_rig.{gd,tscn}`.
Interface: `configure_profile(profile: String) -> bool`, accepting only impact/painterly; default impact unchanged.
- [x] Write native configuration/identity/provenance tests, observe failure from missing API.
- [x] Add narrow profile configuration and strict configured identity/provenance validation.
- [x] Write candidate-only Unit routing/fallback expectations; observe failure before routing change.
- [x] Select candidate before add_child only in duel; discard each failed adapter before replacement.
- [x] Verify baseline rig/actions/showcase and candidate configurations. Actual asset checks wait for freeze.

## Task 2: QA identities and strict registration
Files: `tools/browser_zane_duel.py`, `tools/test_browser_zane_duel.py`, `tools/check_playable_loop.py`, `tools/test_check_playable_loop.py`.
- [x] Write duel-specific identity tests rejecting old impact/mismatched hash/absent actual rig; observe failure.
- [x] Pin duel to candidate final model SHA; leave full-party assertion unchanged.
- [x] Add candidate native scene to strict runner, preserving all previous strict diagnostics behavior.
- [x] Run Python unit suite and static checker.

## Task 3: Actual freeze verification
Files: candidate native tests, local evidence logs; asset files supplied by asset author only.
- [x] Integrate actual frozen asset into runtime validation worktree without editing it.
- [x] Verify skeleton/clips/sockets, imported atlas and vertex-color materials, all-facing gait/scaled footprint, synchronous cast projection, quality and sprite toggles.
- [x] Verify missing/corrupt candidate and multi-stage fallbacks using isolated temporary project copies, never production test hooks.
- [x] Run full combined native suite including duel replay/exit/save/action contracts and Python suite.
- [x] Request independent review; resolve blocking findings with regression tests; commit only owned runtime/tests/docs. Report exact frozen hashes, checks and limits.
