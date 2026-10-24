# Exported combat input smoke

This test drives the actual exported Godot runtime with Chrome DevTools Protocol
mouse movement/press/release events. It does not emit Godot button signals, call
combat commands, mutate game state, or substitute a JavaScript game simulation.

## Coverage

1. Open Ability, press Cancel, and verify the menu/selection/highlights clear.
2. Reopen Ability, select the normal first ability (Lyra's Long Shot), verify CAST
   highlights, press Cancel, and verify all targeting state/highlights clear.
3. Select Move, choose an unoccupied legal tile supplied by the real grid, click
   its projected center, wait for movement resolution, and verify the destination.
4. Reopen Ability and click the actual Quickstep label: 5 MP once, action spent,
   Move reopened, Attack/Ability disabled, same HP/position before turn handoff.
5. Click Move and another legal tile; wait for a subsequent player turn, then
   verify original Lyra by instance identity, final position and retained MP.
   Later enemy/terrain HP changes are not attributed to Quickstep.

Both cancellations preserve active-unit identity, HP, MP, position, and move/action
flags. Movement spends only the move flag; HP/MP/action and active unit stay the
same. Late frames are checked after movement. Exceptions, console errors/asserts,
and browser log errors fail the test. Every transition has a finite timeout;
controls and tiles use observed geometry, not fixed pixel coordinates. Compact
and restored captures also wait for the actual canvas rectangle, not just frame
advancement. Timed-out Godot subprocesses retain partial stdout/stderr before
staging cleanup and re-raising the timeout.

## Isolation

`tools/browser_qa` is outside the Godot project (`res://`). The QA export helper
refuses a preexisting `godot/tests/browser_qa`, temporarily stages the fixtures and
selects their scene, and restores the exact project bytes/removes staging in
`finally`, including when import, validation, or export fails. The QA scene
inherits unchanged Battle.tscn and adds only an observer child: the original
BattleScene root, script, node paths, input handlers, and gameplay are preserved.

The observer publishes data-only schema-v2 `window.__projectTacticQA` snapshots.
Rendered labels identify Quickstep; a roster keyed by stringified Godot instance
IDs and the existing player-turn serial preserve actor identity across handoff. It has no
JavaScript callbacks or action API. Browser unit tests do not need websocket-client;
actual browser execution uses the same dependency already installed by this CI.
Game saves for headless observer validation use a disposable XDG directory; CI
browser input uses a disposable Chrome profile.

Production is exported first. The helper checks that the unencrypted production
PCK has no QA resource paths or bridge symbol before and after staging. QA runs
before `prepare_playable_web.py`, which replaces the raw PCK with exact-byte parts.
Neither QA export nor smoke is a deployment or production artifact upload.

## Commands and artifacts

After the normal Godot import and production Web export:

```sh
python -m unittest discover -s tools -p test_export_browser_qa.py
python -m unittest discover -s tools -p test_browser_combat_smoke.py
python tools/export_browser_qa.py --production-pck build/web/index.pck --output build/web-qa/index.html
```

The workflow starts its existing browser at `about:blank`, enables Runtime/Page/Log
observation, and only then navigates to the local QA export. The script is:

```sh
python tools/browser_combat_smoke.py --output docs/qa/browser-captures
```

Use only an authorized browser and reachable environment. Do not retry the known
cloud-browser/retained-shell localhost namespace mismatch or alter access controls.

The `forgotten-field-browser-captures` CI artifact is retained even on smoke failure:

- Existing loaded, settled, and compact 1366×768 captures.
- Ability-menu open/cancelled, Long Shot targeting/cancelled, legal movement range,
  and completed movement captures.
- Quickstep menu, action-spent/movement-reopened, second-movement range, and
  second-movement/turn-handoff captures.
- `report.json`: pass/fail, failure detail, checkpoints/snapshots, actual input
  coordinates, browser version, latest observation, and errors.
- `browser-events.json`: complete collected console/exception/browser-log events.
- `chrome.log` and `server.log`; a failure screenshot when capture remains possible.

## Released PR #75 CI evidence (2026-10-24)

[Godot Validate 40095725695](https://github.com/Rando2020/ProjectTactic/actions/runs/40095725695)
on final head `1f00ccae4ba72605a1991949440ee41a951027be` passed **11 real clicks
plus hover / 14 checkpoints**, including Quickstep, the actual **MP: 65** HUD
label, second movement and original Lyra identity after handoff. It reported no
captured browser errors. The source tree `ed32741c360c27f3d5eb2c1cb4f47367b1bc6bec`
was merged as `f900b54a`. The post-mouseMoved gate requires two newer frames and
unchanged row/canvas geometry before pressing the original coordinate; it never
chases a reflowed button. This exported-CI check is not full-encounter acceptance
or acceptance of the separate pending starter-identity candidate.

## Earlier PR #74 CI evidence (2026-10-24; historical)

[Godot Validate run 40086250617](https://github.com/Rando2020/ProjectTactic/actions/runs/40086250617)
on final PR #74 head `ed417b755f7186589b97962f8f6bba7624c5c644` succeeded,
including actual Chrome mouse input: **seven clicks and nine checkpoints** for
menu Cancel, target Cancel and legal movement. The reviewed source tree is
`a5667343e47548eaca8f51e36acb9f70ecc96e28`, also the tree merged as `c80a0259`.
The run retains `report.json`, captures and browser diagnostics in the
`forgotten-field-browser-captures` artifact. No captured JavaScript/browser-console
errors were reported; known native shutdown and browser-environment warnings are
not recast as a warning-free result.

At that PR #74 checkpoint, the seven-click evidence did **not** cover Quickstep.
The later PR #75 trial above closes that bounded eleven-click input gate.

This closes the earlier pending CI-input check below, **not** full-encounter,
deployed spell/encounter, mobile or final-art acceptance. For public/private
release provenance and current limitations, use the [delivery ledger](../production/delivery-ledger.md)
and [live public build-info.json](https://rando2020.github.io/ProjectTactic/tactics/build-info.json).

## Earlier local evidence (2026-10-24; preserved checkpoint)

Baseline: `90cd78195eb000d8a0fa71a631d276c1753f7e15`. Isolated branch only.
All 28 Python tests passed (22 new harness/staging tests); the real-scene
observer contract passed with zero failures.
Production and QA Web exports succeeded using existing Godot 4.6.3/templates.
Production PCKs exported before staging and after cleanup were byte-identical:
16,410,648 bytes, SHA-256
`4d2b27303c38db9c6164b607780b9a94078456a5182d2990110c3d675d169996`.
Neither contained the bridge; the QA PCK did. Normal project/config bytes remained
unchanged. Existing native gameplay/presentation/UI contracts, script parsing,
responsive HUD, narrative, art, static stability, and Web packaging checks passed.
The native Cancel/move test retains its known shutdown ObjectDB/one-resource
warning; the Orren contract also retains an ObjectDB shutdown warning. Static
stability reported its existing 19 warnings; no new runtime script errors were observed.

**Actual browser input assertions and new screenshots have not run locally.** No
browser was launched, shared GUI used, unreachable localhost retried, source
published, workflow dispatched, Site changed, or branch merged. A later authorized
CI run is required to establish exported-input acceptance. Unit/headless/export
results do not prove that acceptance, art quality, full combat, or mobile support.

See [the Scout extension evidence](browser-quickstep-smoke.md) for the later
Quickstep-only change, historical isolation proof, and later released CI evidence.
