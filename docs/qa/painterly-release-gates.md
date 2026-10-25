# Painterly release gates

`Godot Validate` runs these additional gates **after the existing Godot import**:

1. Focused fallback-runner, isolated-asset-runner, and CI-shell regression tests.
2. Unchanged `validate_export.py`, `test_validate_export.py`, and
   `check_motion_clearance.py` through a disposable staged-input wrapper.
3. All seven actual imported-asset fallback probes.

The existing strict gameplay/native aggregate, metadata tests, baseline
exemptions, and three browser scenarios are unchanged. These additions do not
register another production runner, rebuild assets, update metadata, or export
a new release.

## Portable asset gate

```sh
python -m unittest discover -s tools -p test_check_zane_painterly_release_gates.py
python -m unittest discover -s tools -p test_zane_painterly_release_workflow.py
python tools/check_zane_painterly_release_gates.py --output build/painterly-release-gates/assets
```

The wrapper copies only the three candidate validator scripts, editable atlas,
existing GLB parser, and original/impact/painterly runtime asset directories into
a temporary matching hierarchy. It does **not** copy the source Blend or old
source reports. Validators run unchanged, with assertions enabled, without
`--write-metadata`, `--structure-only`, Blender, or new dependencies. Existing
NumPy is sufficient. Each child has a 300-second limit (`--timeout` overrides
seconds per child); a timeout fails with exit 124. Each nonzero child exit fails
the wrapper; the first such exit code is preserved (signals normalize to 1).
Independent remaining checks still run so their diagnostics survive.

Outputs must be outside the checkout or inside ignored `build/`:

- `validate_export.log`, `test_validate_export.log`, `check_motion_clearance.log`
- Fresh `validation_report.json` and `motion_clearance_report.json`, when emitted
- `release-gates.json` with each command, status, exit code, and artifact names

A successful report-producing child that emits no fresh report also fails.
Previous output reports are cleared before the run. Source metadata, approved
GLBs, scripts, and checked-in source reports are never the write targets.
Stale/altered metadata fails the original validator; floor, sampled blade/skin
crossing, fixed-camera framing, and minimum blade margin failures retain the
original assertions and tolerances.

## Actual fallback probes

```sh
# Use isolated XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME for this import.
godot --headless --path godot --import
python -m unittest discover -s tools -p test_check_zane_painterly_fallbacks.py
python tools/check_zane_painterly_fallbacks.py --output build/painterly-release-gates/fallbacks
```

This existing runner copies the imported project and isolates every probe's
player-data directories. It checks missing/corrupt candidate, wrong
profile/provenance, damaged actual import, unavailable impact, and unavailable
all-3D fallbacks. It fails on engine/script diagnostics even with exit zero.
Seven `fallback-*.log` files preserve the observations. CI always attempts to
upload `build/painterly-release-gates/`, including artifacts from failing gates.

## Limits

Fixture subprocess tests prove orchestration, failure propagation, and source
preservation, not asset acceptance. Actual exported-mesh clearance samples all
nine clips at 96 Hz and four fixed-camera facings; it is not continuous-collision
or visual certification. Headless fallback probes are not native GUI/browser
rendering, performance, audio-listening, or hardware-GPU acceptance. This gate
neither alters approved geometry nor replaces independent art/native review.
