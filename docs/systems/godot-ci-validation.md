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
