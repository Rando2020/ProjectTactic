# Kael Pixel Presentation Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline; parent reviews the branch. Steps use checkbox syntax.

**Goal:** An opt-in Kael-only imported rig presentation that respects existing combat authority and crisp UI.
**Architecture:** A Node2D facade renders the original Kael GLB through an isolated SubViewport. Existing Unit hooks drive phase sampling; no animation callback owns gameplay. The existing practice 3D toggle selects the facade only for Kael, retaining other rigs and sprite fallback.
**Tech Stack:** Godot 4.6.3, GDScript, original GLB.
**Spec:** Parent task and read-only analysis, summarized below.

## Global Constraints
- Baseline 717d2567b5462b8330c41002c7882f7b98db763c; isolated local branch only, no remote changes.
- Only Unit.enable_3d_prototype factory seam may change in shared combat code.
- Do not edit PracticeComparison, AppointedTheme, BattleUI or UISettings.
- Tile positions, stats, save/progression and ActionLifecycle remain unchanged.
- Seven-clip v2 may use explicitly documented idle/fade fallbacks; only replace with v2.1 after builder checksum verification.
- Melee preparation 0.20s; permitted contact then 0.22s recovery. Cast preparation 0.20s, release during 0.22s projectile travel, then 0.22s recovery.
- Low-resolution nearest character rendering is independent of high_quality; UI remains outside viewport.

## Review Focus
- Missing asset/required clips/socket must leave visible sprite fallback.
- Cancellation resets sampled phase without delayed callback restarting it.
- Socket projection must include facing, parent scale and output transform immediately after seek.
- Defeat must not be interrupted by idle reset or hit; absent walk/death remain honestly documented.
- Four tile facings, repeated toggles, quality changes must preserve projected feet.

### Task 1: Adapter contract and phase sampling
**Files:** Create godot/scripts/presentation/KaelRigPresentation.gd; godot/assets/3d/characters/kael_v2/kael_v2.glb; godot/tests/test_kael_presentation.gd.
**Interfaces:** Node2D with skin_id, state, is_available(), play(String), face(Vector2i), hand_world_position()->Vector2, set_high_quality(bool), set_pixel_style(bool). Owns viewport/output/camera/player/skeleton references only, no Unit gameplay reference.
- [x] Write real scene tests for absent adapter/load, clip contact samples, cancellation, immediate socket transforms, four facings and defeat priority; run and record RED.
- [x] Implement validated asset loading and manual phase sampling; run same tests GREEN.
- [x] Add pixel/quality invariance and fallback cases RED then GREEN.
- [x] Commit adapter, asset, tests and documentation.

### Task 2: Minimal Unit factory integration
**Files:** Modify godot/scripts/units/Unit.gd enable_3d_prototype only; extend test_kael_presentation.gd.
**Interfaces:** Existing rig3d practice flag and Unit.enable/disable; Kael chooses imported adapter only if is_available. Others retain Humanoid3D.
- [x] Test actual Unit Kael selection, repeated enable/disable and non-Kael unchanged; observe RED.
- [x] Add minimal factory branch, then GREEN.
- [x] Run available project tests, report baseline/missing-asset failures separately; commit.

### Task 3: Verified v2.1 and graphical handoff
- [x] Await builder's final path/checksum/report; verify checksum and retained seven clips/timings before copying.
- [x] Add walk/defeat tests RED, integrate authored clips GREEN; preserve idle/fade fallback for missing optional clips.
- [ ] Native QA operator captures/reviews final stable commit (parent coordinates; no GUI used here).
- [x] Record exact asset checksum, commits, results and honest visual limitations; parent reviews/cherry-picks.
