# Godot CI Validation

## Purpose

ProjectTactic's production game lives under `godot/`, so the repository must validate Godot directly instead of relying only on the React/Vite reference build.

## Workflow

`.github/workflows/godot-validate.yml` runs on pull requests and manual dispatch.

It validates the narrative data contract, then uses Godot 4.6.3 without .NET for engine checks:

1. Runs `tools/check_recurrence_story.py` so malformed Recurrence or Orren story data fails before engine startup.
2. Starts the real project in headless editor mode so project settings, resources, autoloads, scenes, and import-time dependencies are exercised.
3. Runs `godot/tests/validate_all_scripts.gd`, which recursively loads every GDScript under `res://scripts`.
4. Runs targeted Godot story tests when the branch defines them, including the Orren Love / Grief state progression.

A malformed story contract or script that cannot be parsed or loaded causes the workflow to fail.

## Zane impact asset and audio checks

The exported GLB compatibility tests require Python 3.11+ and `numpy==2.3.5`
for matrix/skin sampling; they do **not** run Blender. The audio tests and
generator use only the Python standard library. After hydrating runtime assets:

```bash
python -m pip install numpy==2.3.5
python -m unittest discover -s tools -p test_zane_impact_asset.py
python -m unittest discover -s tools -p test_zane_impact_audio.py
```

CI installs that pinned NumPy prerequisite and runs both suites explicitly.
The 31-contract gameplay runner (28 scenes and three standalone scripts) includes
Zane's rig, action, session-only showcase-controls, isolated duel, hovered-tile
health, and painterly-rig scenes plus the pure `test_zane_outcome_layout.gd` script,
dispatched with `--script`. All seven post-baseline cases fail on script/resource
errors even if Godot prints success and exits zero.
Only pre-Zane cases retain the exact documented shutdown resource-count
allowance, and those diagnostics remain visible.

## Separate Zane browser acceptance

The default eleven-click Quickstep export, package, browser command, profile,
checks, and artifact remain unchanged. CI additionally runs the explicit
`test_browser_zane_showcase.py` and `test_zane_release_workflow.py` Python suites.
The latter executes the real workflow shell blocks with controlled external
processes; it proves failure propagation, output isolation, required evidence,
and process cleanup, not browser rendering.

After the default QA export, CI exports `--scenario zane-showcase` separately to
`build/web-qa-zane/` while the raw production PCK is still available. The exporter
checks that production contains no QA resources before/after staging. CI checks
project restoration and absent staging, then re-exports production separately to
`build/web-production-recheck/` and applies the production-PCK exclusion guard.
Only afterward are the production/default QA PCKs packaged into chunks.

The separate Zane browser step serves `build/web-qa-zane/`, uses a fresh disposable
Chrome profile with the existing browser flags, and runs the bounded actual-input
[Zane scenario](../qa/browser-zane-showcase.md). It requires nonempty actual loaded,
movement, and Fire/cleanup PNGs, `report.json`, and `browser-events.json`. The
`zane-showcase-browser-captures` artifact always uploads the separate capture
folder, including export/re-export/package/smoke logs and server/browser logs.
An absent artifact is an error. Inspect the actual screenshot pixels when
reviewing the artifact; a synthetic transport test is not visual acceptance.

`pipefail` preserves export/package/smoke failures through `tee`; process teardown
runs on success or failure. A failed default Quickstep smoke does not prevent the
Zane run if its own package succeeded, and neither scenario suppresses the other's
failure. Cancellation does not start a new browser. No browser security flags,
workflow triggers, or permissions are added or broadened.

## Third isolated Zane duel browser lane

The optional [one-on-one QA scenario](../qa/zane-duel-browser-2026-10-24.md) is a
third path, not a replacement for Quickstep or full-party Zane Fire. Their existing
export/package/browser/artifact steps are unchanged. Explicit Python CI also runs
`test_browser_zane_duel.py` and `test_zane_duel_release_workflow.py`.

The duel exports with `--scenario zane-duel` to `build/web-qa-duel/` before the
original production PCK is packaged. Its exporter runs both ordinary and slow-tail
native observer contracts. After duel staging is restored, the same existing
production-exclusion helper guards a fresh production re-export to
`build/web-production-duel-recheck/`. This repeats the earlier guard after **all
three** QA scenarios without moving or modifying the existing full-party steps.

A separate browser process serves the duel package with a fresh disposable profile
and exactly the existing Chrome flags. It validates an observed legal move and
sword action, using the scenario's bounded actual-input contract; this is not Fire,
title-entry, complete victory/replay, or audible-audio acceptance. The step requires
nonempty actual loaded/movement/sword-cleanup screenshots, `report.json`, and
`browser-events.json`. The always-uploaded `zane-duel-browser-captures` artifact
retains `docs/qa/browser-zane-duel-captures/`, including export/re-export/package/
smoke/server/browser logs and failure evidence when available.

Export/package/smoke failures propagate through `tee`; browser/server cleanup runs
on failure too. If an earlier browser lane fails, duel still runs when its own
package succeeded; cancellation does not start it. Missing evidence or a missing
artifact fails, rather than silently passing. The shell regressions exercise these
boundaries with controlled external processes and do not claim browser rendering.
No security flags, workflow triggers, permissions, or native-runner policy are
changed by this additional lane.

## Why recursive loading matters

Godot can contain scripts that are not instantiated by the current main scene. A basic smoke launch can therefore miss stale or newly broken files.

The validator treats the entire production script tree as code that must remain loadable.

## Local parsing check

First follow the [clean-checkout / scoped Godot hydration instructions](playable-tactics-loop.md#clean-checkout-and-validation).
From the repository root, with exact Godot `4.6.3.stable.official.7d41c59c4` on PATH:

```bash
godot --headless --path godot --editor --quit-after 2
godot --headless --path godot --script res://tests/validate_all_scripts.gd
```

## Scope

The local parsing check above validates parsing and project loading only. Current
[workflow source](../../.github/workflows/godot-validate.yml) also runs bounded
combat/presentation contracts, exports and [real browser input QA](../qa/browser-combat-smoke.md);
use that source for the complete CI command list and the [delivery ledger](../production/delivery-ledger.md)
for dated outcomes. Parsing alone does not replace:

- deterministic combat tests;
- save/load migration tests;
- browser export validation;
- scene-specific gameplay smoke tests;
- performance profiling.

Existing bounded checks do not certify all save migrations, full gameplay acceptance or performance.

## Failure policy

When this workflow fails:

1. Fix the exact Godot error before adding more gameplay to the affected branch.
2. Keep the repair bounded.
3. Do not bypass the check with `|| true` or equivalent suppression.
4. Preserve useful legacy files in archive paths rather than production runtime paths.
