# Exported-browser combat smoke Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for this bounded delegated implementation. Parent owns fresh whole-branch review.

**Goal:** Test ability-menu Cancel, target Cancel and legal movement using real exported browser input.
**Architecture:** QA-only staged read-only Godot observer plus Python CDP input/assertions and always-retained diagnostics. Production export remains observer-free.
**Tech Stack:** Godot 4.6.3, Python stdlib, existing websocket-client and CI Chromium.
**Spec:** docs/superpowers/specs/2026-10-24-browser-combat-smoke-design.md

## Global Constraints
- Frozen baseline 90cd78195eb000d8a0fa71a631d276c1753f7e15; isolated local branch only.
- No production gameplay edits, publication, Site access, workflow dispatch, browser installs, shared GUI, or localhost namespace retries.
- Bridge sources outside res://; stage only during QA; no action APIs.

## Review Focus
- Failure during staging/export must restore configuration and not destroy preexisting files.
- Production PCK must not contain bridge assets.
- Browser exception/console events interleaved with CDP replies must survive and fail smoke.
- UI scaling, missing/disabled controls and illegal tile candidates must not result in guessed clicks.
- Cancellation and movement must preserve resources and avoid stale highlights.

## Task 1: Isolated QA export
Files: tools/export_browser_qa.py, tools/test_export_browser_qa.py, tools/browser_qa/*.
- [x] Write/run failing tests for staging success, exporter failure, existing-stage refusal, main-scene mismatch and PCK bridge exclusion.
- [x] Implement context-managed staging and PCK resource-name inspection; tests pass.
- [x] Add read-only Godot snapshot wrapper and headless observer contract; parse/run it using staging, with isolated save data.

## Task 2: Browser input smoke
Files: tools/browser_combat_smoke.py, tools/test_browser_combat_smoke.py.
- [x] Write/run failing tests for coordinate conversion, invalid controls/destinations, cancel/move invariants and event-aware CDP replies.
- [x] Implement finite state waits, actual mouse events, before/after checkpoints, screenshots, console/page-error reporting, and failure artifacts.
- [x] Run tests and focused headless contracts; no browser execution in this task.

## Task 3: CI wiring and evidence
Files: .github/workflows/godot-validate.yml, docs/qa/browser-combat-smoke.md.
- [x] Keep production export first; verify production PCK excludes bridge; stage/export QA with helper.
- [x] Subscribe before navigation, run smoke on current installed CI browser, retain old normal/compact screenshot coverage and upload all diagnostics with always().
- [x] Run Python unit suites, Godot import/parse/observer and existing relevant aggregate checks; export production/QA with existing local templates if available.
- [x] Review final diff and report exact validation and unexecuted-browser boundary to parent. Commit locally if useful for review; never push.

## Ledger
- Parent approved staged-fixture design at 2026-10-24 09:03 UTC.
- Hydrated 218 Godot LFS assets by SHA-256-verifying bytes read from frozen integration checkout; no source checkout mutation/network download.

- Final verification: 26/26 Python tests (20 new QA tests), headless observer 0 failures, production GDScript63, HUD30, Orren31, manifest94; narrative/art/static/package checks passed. Existing native aggregate: formula209, execution53, CT130, progression73, Cancel/move17, Kael113, recovered15, readability2465, playable425, terrain10 cycles, no script errors. Known native shutdown warnings remain visible.
- Production → staged QA → cleaned production export rerun passed. Production PCKs byte-identical (16,410,648 bytes; SHA-256 4d2b27303c38db9c6164b607780b9a94078456a5182d2990110c3d675d169996); QA absent from production and present in QA pack. Exact project bytes restored, stage absent.
- Ruling: QA scene inherits Battle.tscn with an observer child rather than nesting Battle under a wrapper — production VFX uses absolute /root/BattleScene paths. Structure contract observed RED (1 failure) then GREEN (0 failures); no production code change.
- Ruling: QA guard/export precedes production packaging — prepare_playable_web.py deletes raw PCK after splitting exact bytes into parts. Production is still exported before staging.
- Browser execution remains NEVER RUN here, by scope. No screenshots or exported-input acceptance claimed; later separately authorized CI is required. No source publication/dispatch/merge/deployment. Parent owns independent review of frozen local commit.

## Review corrections (2026-10-24)
- Parent requested two bounded minor corrections after independent review: actual canvas geometry gates for compact/restored captures, and preserving partial subprocess output on timeout.
- RED: geometry regression captured 1600×900 as compact; timeout text/bytes/None-output variants each lost diagnostics (4 assertion failures total). GREEN: all22 QA tests, all28 Python tests pass. Geometry test includes delayed size changes and wrong restored origin; timeout test verifies original exception identity and restored project/no staging.
- Revalidated headless observer (0 failures), QA export and clean production export. Production remains byte-identical to the before-QA pack with the same 4d2b2730… hash; bridge remains QA-only.
- No browser launched or screenshots captured; exported-input acceptance still awaits separately authorized CI. No workflow/publication/deployment changes in this correction.
