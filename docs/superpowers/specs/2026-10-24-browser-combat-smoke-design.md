# Exported-browser combat smoke

## Intent and scope

Prove three bounded interactions through real browser input in the exported Godot
runtime: cancel the ability menu, cancel a selected ability target, then move to
one legal tile. Native signal-emission tests and screenshots alone do not prove
that exported input reaches the gameplay controls.

Success means state assertions, screenshot checkpoints, and browser error capture
pass together. Cancellation must preserve the active unit, position, HP/MP, and
move/action flags. Movement must change position to the clicked legal tile, spend
only movement, and leave MP and action availability unchanged.

## Approaches

1. Screenshot/OCR plus fixed-coordinate clicking: no instrumentation, but brittle
   under HUD resizing and unable to verify resource/action invariants. Rejected.
2. A permanently resident QA observer under `godot/tests`: small, but the current
   `all_resources` export would package it in production. Rejected.
3. **Recommended:** keep a QA wrapper/observer under `tools/browser_qa`, stage it
   temporarily under `godot/tests/browser_qa` only for QA export, then restore the
   project and remove staging in `finally`. The ordinary export remains unchanged.

## Design

- The QA scene inherits unchanged `Battle.tscn` and adds an observer child,
  preserving the production BattleScene root/type and absolute VFX paths. It observes normal state.
  It exposes JSON snapshots to JavaScript containing only non-sensitive gameplay
  state, UI rectangles, viewport dimensions, and projected legal tile centers.
- The bridge has no callable action API, signals, gameplay setters, fixture cheats,
  or production autoload. All actions originate as CDP mouse input.
- Python reuses installed `websocket-client` and the existing DevTools target
  discovery. It subscribes before navigation so startup exceptions are captured.
- Poll state transitions with deadlines instead of assuming fixed animation times.
  Map Godot viewport coordinates through the real canvas DOM rectangle; reject
  hidden/disabled/zero-size/off-canvas controls and invalid destinations.
- Preserve existing normal/compact visual evidence and add menu-open, menu-cancel,
  targeting, target-cancel, movement-range, and completed-move checkpoints.
- Write JSON state/checkpoint/input evidence and console/exception diagnostics even
  after failure. Browser errors fail the smoke, rather than silently disappearing.
- CI uses its existing installed browser and disposable profile, and uploads
  evidence on failure as well as success. No new dependency or permission changes.

## Constraints and non-goals

Frozen baseline: `90cd78195eb000d8a0fa71a631d276c1753f7e15`. Local isolated branch
only; no source publication, workflow dispatch, merge, deployment, Site access,
credentials, paid services, browser installation, or production gameplay change.
No claim about balance, art quality, full combat, or cross-browser/mobile coverage.
Known cloud-browser/retained-shell namespace isolation is not retried or bypassed.
Local headless/unit/export validation is distinct from actual browser execution;
the latter may require separately approved CI publication.

## Verification

Unit tests cover input-coordinate conversion, stale/invalid observations, state
invariants, CDP asynchronous error handling, and staging restoration on export
failure. A headless scene test validates the observer against real unchanged
Godot nodes without claiming browser input coverage. Production files and export
configuration are byte-identical before/after staging. Full relevant existing
checks run before handoff. Parent review owns approval and any later publication.
