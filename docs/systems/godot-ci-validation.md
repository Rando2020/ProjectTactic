# Godot CI Validation

## Purpose

ProjectTactic's production game lives under `godot/`, so the repository must validate Godot directly instead of relying only on the React/Vite reference build.

## Workflow

`.github/workflows/godot-validate.yml` runs on pull requests and manual dispatch.

It uses Godot 4.6.2 without .NET and performs two checks:

1. Starts the real project in headless editor mode so project settings, resources, autoloads, scenes, and import-time dependencies are exercised.
2. Runs `godot/tests/validate_all_scripts.gd`, which recursively loads every GDScript under `res://scripts`.

A script that cannot be parsed or loaded causes the workflow to fail.

## Why recursive loading matters

Godot can contain scripts that are not instantiated by the current main scene. A basic smoke launch can therefore miss stale or newly broken files.

The validator treats the entire production script tree as code that must remain loadable.

## Local equivalent

From the repository root, with Godot 4.6.2 on PATH:

```bash
godot --headless --path godot --editor --quit-after 2
godot --headless --path godot --script res://tests/validate_all_scripts.gd
```

## Scope

This validates parsing and project loading. It does not replace:

- deterministic combat tests;
- save/load migration tests;
- browser export validation;
- scene-specific gameplay smoke tests;
- performance profiling.

Those should be added as bounded checks as the vertical slice hardens.

## Failure policy

When this workflow fails:

1. Fix the exact Godot error before adding more gameplay to the affected branch.
2. Keep the repair bounded.
3. Do not bypass the check with `|| true` or equivalent suppression.
4. Preserve useful legacy files in archive paths rather than production runtime paths.
