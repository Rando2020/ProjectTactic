# Shared Character Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Share the reviewed Kael presentation implementation with original Mira, preserving all existing behavior.

**Architecture:** One existing-behavior base, two minimal profiles, a bounded Unit factory extension. Original Kael behavior remains an independent immutable test reference.

**Tech Stack:** Godot 4.6.3, GDScript, original GLB assets.

**Spec:** `docs/superpowers/specs/2026-10-24-shared-character-presentation-design.md`

## Global Constraints
- Isolated branch only; no current/live/public/remote changes or GUI.
- No Mira bytes before builder-authoritative frozen checksum.
- No gameplay callbacks, timer changes, retargeting, render-footprint change, or extra capability.
- Preserve Kael script path, public constants/defaults, original regression suite, other actors, sprite fallback, and save state.

## Review Focus
- Wrong profile/socket routing: a renamed-socket real PackedScene must use only the configured socket.
- Extraction timing drift: compare every phase and bone against byte-frozen original Kael source.
- Variant fallback: missing mandatory clips/socket rejects; optional walk/defeat retains prior fallback.
- Alias and off-toggle: archetype metadata selects Mira only through existing opt-in path; unrecognized actors remain sprite-backed in normal readiness.
- Detached viewport leak: repeated disable/re-enable detaches synchronously and frees next frame.

## Task 1: Shared implementation with unchanged Kael behavior
**Files:** create `godot/scripts/presentation/SharedRigPresentation.gd`; modify `KaelRigPresentation.gd`; create `godot/tests/test_shared_rig_presentation.gd`, `.tscn`, and `godot/tests/fixtures/KaelRigPresentation90cd781.gd`.
**Interfaces:** Existing `play(String)`, `face(Vector2i)`, `hand_world_position()`, `is_available()`, `set_pixel_style(bool)`, `set_high_quality(bool)` remain unchanged. Base has `skin_id`, `asset_path`, `cast_socket_name`; Kael `_init()` supplies old defaults and retains `MODEL_PATH`.
- [x] Freeze exact original adapter bytes/hash into test fixture. Add real-scene configurable socket acceptance/rejection and full original/new phase, pose, render, facing, anchor and origin comparison.
- [x] Run headless shared scene; require expected missing-base failure before implementation.
- [x] Move existing implementation to shared base; replace only character defaults and literal socket lookup; add tiny Kael initializer.
- [x] Run original Kael scene and new shared scene cleanly. Temporarily mutate shared contact time, verify reference comparison fails, restore and rerun.
- [x] Commit only bounded source/tests/docs changes.

## Task 2: Frozen Mira profile and Unit route
**Files:** add frozen original asset/provenance under `godot/assets/3d/characters/mira_v2/`; create `MiraRigPresentation.gd`; modify only Unit factory and supported-archetype list; add `godot/tests/test_mira_presentation.gd` and `.tscn`.
**Interfaces:** Mira `_init()` configures frozen asset and confirmed legacy socket `Kael_v2_cast_socket`; Unit treats both imported profiles as validation-gated replacements.
- [x] Wait for authoritative freeze and verify SHA before copying; no candidate bytes.
- [x] Add failing real-asset tests: sixteen bones, nine authored durations, phase contact/release/recovery, walk/defeat, root anchor, projected socket, frame-immediate updates, render footprint. Add actual Unit/VFX/lifecycle/cancellation, repeated cleanup, malformed imported scene fallback, archetype aliases, unchanged saved state and off-toggle tests.
- [x] Require expected missing-profile/routing failures before adding thin Mira wrapper and bounded factory list.
- [x] Run new and original suites, scene import, all-script validation and relevant combat/cleanup scenes; inspect complete logs for errors, not exit code alone.
- [x] Add source/hash/prototype limitations and exact QA evidence. Exclude import churn and unchanged hydrated LFS assets; commit bounded diff and hand off for parent review.
