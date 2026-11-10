# Command Schools Implementation Plan

> **For agentic workers:** Execute and verify each task in the existing native engineering task.

**Goal:** Add separate Skills and Magic → school → spells in the live courtyard.

**Architecture:** Ability metadata feeds a pure catalog from each active unit's abilities. Courtyard HUD owns navigation only; existing selection and manager retain all combat authority.

**Tech Stack:** Godot 4.6.3, GDScript, current GitHub Pages export workflows.

**Spec:** ../specs/2026-11-10-command-schools-design.md

## Global constraints
- No new heroes, combat balance, save ownership changes, or campaign UI changes.
- School labels remain editable and provisional; several schools can belong to one hero.

## Review focus
- Unknown and alias IDs must not corrupt ownership or duplicate entries.
- Cancelling at each nested level must neither spend an action nor leave stale confirmation.
- Low MP/silence must not hide learned schools or enable illegal casts.
- Repeated menu input, actor changes and action completion must reset stale navigation.
- All five commands and Back remain usable at narrow game widths and large text scales.

## Task 1: Catalog and native menu
- [ ] Add focused failing-first tests in tests/blooming_commands/CommandMenuTest.gd.
- [ ] Add command_category/magic_school to AbilityDB and AbilityCommands.catalog(ids).
- [ ] Add courtyard Magic command, nested school navigation and disabled reasons in BloomingHUD; preserve manager execution methods.
- [ ] Wire parent-aware cancellation and keyboard/gamepad focus; run focused tests green.

## Task 2: Regression and publication
- [ ] Update existing courtyard tests to traverse the actual new menus.
- [ ] Run native supported scene, parser, Python and Web-package checks; add exact-head graphical CI captures.
- [ ] Independently review code and rendered captures, fix identified blockers and rerun affected tests.
- [ ] Publish draft PR, verify exact-head CI, merge under user authorization, verify Pages provenance and hosted browser smoke before claiming live.
