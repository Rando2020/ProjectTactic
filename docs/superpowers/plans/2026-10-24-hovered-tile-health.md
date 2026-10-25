# Hovered-Tile Health Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Keep the last inspected tile's occupant HP truthful after HP and occupancy changes.

**Architecture:** BattleManager caches the inspected cell, formats read-only text, and subscribes to existing Unit events. Refresh never re-enters input or preview logic.

**Tech Stack:** Godot 4 GDScript; existing Python native-contract runner.

**Spec:** `docs/superpowers/specs/2026-10-24-hovered-tile-health-design.md`

## Global Constraints
Preserve all story, combat, action ordering, previews, and ordinary full-party/duel behavior. No GUI, publishing, deployment, config, or broad refactor.

## Review Focus
- Same-cell Fire must update actual BattleUI text without another hover.
- Clearing selection/highlights must not lose the inspected cell.
- Heal/Burn/lethal and removal must not leave a stale occupant.
- Movement into/out of the cell must update occupancy without preview side effects.
- Invalid registry entries must be skipped read-only; no control/resource/RNG mutation.

### Task 1: Repair the display subscription gap
**Files:** `godot/scripts/battle/BattleManager.gd`, new `godot/tests/test_hovered_tile_health.{gd,tscn}`, `tools/check_playable_loop.py`, `tools/test_check_playable_loop.py`.
- [x] Write strict native regression using real BattleScene/BattleUI and one viewport hover before legal Fire; add explicitly labeled edge fixtures and state snapshots.
- [x] Run fixture against unchanged production; expect stale-HP/occupancy assertions, not script errors. Run existing runner tests as baseline.
- [x] Add `_format_tile_info(grid_pos: Vector2i) -> String`, `_refresh_inspected_tile_info() -> void`, dedicated inspected-cell cache, and existing unit-event subscriptions only.
- [x] Register fixture outside LEGACY_CONTRACTS and add existing strict error-path coverage; verify new registration red before adding it.
- [x] Run focused regression, unchanged duel/showcase contracts, Python runner tests, static stability, and diff checks. Root owns aggregate integration to avoid overlapping engine lanes.
- [x] Record exact evidence and freeze local commit/tree for independent integration review.
