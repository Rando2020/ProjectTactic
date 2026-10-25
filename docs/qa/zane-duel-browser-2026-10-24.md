# Optional Zane duel browser QA — 2026-10-24

## Source boundary

QA-only branch `test/zane-duel-browser` starts at reviewed
`2ecb820772a3b2d524e6ec97964fd1ec5d43033f`. It depends on production duel commit
`c54f34e86c08b1798794c78b24788a1378da90de` (tree
`7cc0c3efb6447cf0884d08b0846f74bf85d5e12c`). Actual-source verification uses a separate
worktree `projecttactic-zane-duel-browser-verify` at that production commit plus this
QA slice. No interface stubs, production file edits, merges, pushes or deployments.

## What the optional lane proves

`--scenario zane-duel` uses the real production helper, existing `rig3d=true`, normal
Ashvale combat and exactly Zane/Storm Imp. CDP only navigates/reads the snapshot and
clicks observed native controls/tiles: one legal step, then sword in the first turn.
It validates the real model identity and records actual-canvas screenshots.

There is no pollable settled action gap after move+sword. The observer therefore
retains actual `turn_ended` costs/outcomes/lifecycle/pose, then separately observes
cleanup of that exact original owner instance/action key, its weak-referenced
FX/audio and owner-marked reaction recipients. Queued-for-deletion owners are still
captured at synchronous handoff, covering slow/backgrounded frames. No action is
replayed, no pose forced, no roll/resource/initiative altered. Primary and ordinary
counter damage use authoritative applied resource fields. A miss is valid and never
counts as hit coverage. Real later AI cannot change the retained sword costs.

The minimal sentinel preserves this evidence through normal Battle removal; a
Results transition before sword completion fails promptly. It does not expose
results controls or claim victory/replay behavior was exercised.

**Not browser-proven here:** actual title entry, Fire, subsequent enemy AI, complete
victory/defeat/replay loops, listening/audio quality, or Chrome/WebGL2 acceptance.
Those gameplay paths remain native-contract coverage; existing full-party Fire QA
is unchanged. Screenshot checkpoints show the actual current canvas, not a claimed
same-frame rendering of a retained historical action snapshot.

## Verification and red/green record

- New scenario staging initially failed with unknown `zane-duel`; new Python module
  was absent. After implementation, staging and transport/invariant tests passed.
- Base native bootstrap failed on the genuinely missing production helper; no stub
  was introduced. It then ran against the frozen actual production source.
- Same-turn handoff and separate tail cleanup each had failing coverage before
  implementation. Early native teardown leaked active enemy-action coroutines;
  fixture teardown now waits for normal AI/Results to settle, without affecting the
  captured evidence or exported bridge.
- Six ordinary native observer runs passed with zero errors/warnings; their actual
  JSON passed the same Python invariant validator. Observed ordinary runs were hits
  without counters; synthetic invariant tests separately cover misses/counters.
- Independent review found a queued-owner slow-frame edge. Native delayed-tail
  regression failed before the fix and passed afterward with
  `queued_at_handoff=true`, zero diagnostics, and complete actual JSON validation.
  Its 600 ms wall-clock stall is **native test-only**, after a real outcome Label is
  observed; it is not part of the browser bootstrap/observer. The optional exporter
  runs both normal and slow-tail contracts. Scenario-routing regression was RED→GREEN.
- All Python tools tests: **125 passed** (13 duel invariants/transport tests; 12 staging/export tests). Direct staging test
  execution includes the duel class; the entrypoint is below all test classes.
- Unchanged native base observer and full-party showcase observer: zero failures.
- Actual-source full gameplay runner: **29 contracts, exit 0**, including native
  duel **179 checks**, showcase **84**, impact actions **1433**, outcome layout
  **60486**. This aggregate preceded the final QA-only queued-owner fix; focused
  observer/Python checks cover that fix. No duplicate aggregate is claimed.
- Existing legacy shutdown diagnostics remained visible in
  `test_spell_outcome_feedback`, `test_hit_secondary_status`, `test_cancel_move_input`,
  `test_scout_outcome_integration`, `test_resource_hud`, and `test_playable_loop`.
  They are the runner's already-allowlisted shutdown resource reports, not new QA
  allowances. New duel observer/regression runs have no such diagnostics.
- QA Web export and packaged-WASM/PCK/manifest/root/subpath checks passed; original
  and post-staging reexported production PCKs passed the no-QA-resource guard.
  Repeated staging import emitted existing cache-recreated `.uid` warnings only;
  project bytes were restored and `godot/tests/browser_qa` removed.

Local diagnostic logs: `/tmp/zane-duel-browser-qa/`. Final source/artifact identities
and exact command results are in the handoff; these paths are not public artifacts.

## Optional CI commands (no workflow/browser-flag edits)

Use the combined production+QA source, Godot 4.6.3 official Web templates, fresh
XDG/browser profiles, and a real WebGL2-capable Chrome already started by the existing
CI harness. The production PCK must be the un-packaged raw export for the guard.

```sh
python -m unittest discover -s tools -p 'test_*.py'
python tools/export_browser_qa.py --scenario zane-duel \
  --production-pck build/web/index.pck --output build/web-qa-duel/index.html
python tools/prepare_playable_web.py build/web-qa-duel
node tools/check_web_package.mjs build/web-qa-duel
# Serve build/web-qa-duel on the existing local CI HTTP server, then:
python tools/browser_combat_smoke.py --scenario zane-duel \
  --url http://127.0.0.1:8000/index.html --port 9222 \
  --timeout 45 --budget 180 --output docs/qa/browser-zane-duel-captures
```

Expected screenshots: `zane-duel-actual-3d-loaded.png`,
`zane-duel-3d-movement-completed.png`, `zane-duel-sword-outcome-and-cleanup.png`, plus
`report.json` and `browser-events.json`. The missing cloud WebGL2 capability is not
bypassed; actual Chrome CI remains the parent's authorization-dependent gate.
