# Optional Zane Practice3D browser acceptance

`--scenario zane-showcase` is a separate, bounded actual-input scenario. The
existing default eleven-click Quickstep scenario and its assertions are unchanged.
Neither scenario is a production build, deployment, or substitute game simulation.

## Setup and input boundary

The QA-only bootstrap calls the existing `GameState.begin_practice()` and sets the
existing `rig3d` flag **before** loading the inherited production battle. It keeps
`/root/BattleScene`, the normal four-member party, map, resources and initiative.
It does not force Zane's turn, reposition units, edit HP/MP, control hit rolls,
change time scale, or add JavaScript action callbacks. The scenario does not
exercise the new title-screen entry; native/title-entry evidence is separate.

The driver uses only CDP mouse move/press/release on observed real controls/cells:

1. Confirm initial Lyra initiative, normal party, available imported Zane adapter,
   `zane_impact_v1` identity, actual model/skeleton and visible output. Save an
   **actual browser screenshot** of the 3D battle, not just a boolean observation.
2. Press normal Wait for other players until Zane. Select Move and choose only an
   unoccupied, visible legal cell from the real grid (prefer `[4,5]` when legal).
3. Wait normally for Zane's next turn. Open Ability → actual Fire label. Click an
   observed legal living enemy. If no legal enemy is available, Cancel, make a
   legal approach move and wait another turn. Never infer target legality solely
   from distance. Total budget: 180 seconds and at most 20 player Wait handoffs.
4. Verify exactly 12 MP, one spent action, one admitted/finished lifecycle ticket,
   one charge and release cue/phase, matching actual MP HUD, charge at imported hand, projectile launch
   near that hand, actual resolver outcomes and matching rendered outcome Labels.
5. Wait for owner/effect/audio cleanup, idle rig, retired camera kick/reaction marks, cleared selection/highlights and a later
   idle frame. Browser console/assert/exception/log errors fail the run.

A miss or immune result **passes only with truthful corresponding feedback**.
A hit is not required: legacy cosmetics consume global RNG, so presentation frame
cadence can change the actual roll. `observed_coverage` lists actual outcomes and
whether impact was observed. A miss never establishes hit/hurt/impact coverage.
Audio evidence is emitted cue-start signals, **not audible listening**.

## Additive read-only observer

Schema remains v2. Additions: Wait geometry, legal ability target cells, unit team/
armor, and `zane` profile/lifecycle/live-owner/retained signal and visual samples.
The model SHA comes from the adapter's validated metadata; model instance and
skeleton prove an imported model is instantiated, while the screenshot supplies
visual evidence. Native/headless availability alone does not prove WebGL drawing.

The observer subscribes to disposable owner signals on `VFX.child_entered_tree`,
before synchronous charge begins. It records authoritative `combat_resolved`
signals while the admitted action context exists. Per-frame read-only samples
retain actual charge/projectile positions and actual outcome Label text, so short
phases aren't silently lost to browser polling. It never calls the hand helper
that forces transform updates; it reads existing socket/camera transforms.
Evidence is bounded (512 events and samples; at most eight position samples per
visual instance). Overflow fails acceptance instead of silently dropping proof.

All fixtures remain outside `res://` until temporary QA staging. Existing exact
project-byte restoration, refusal of preexisting staging, production PCK bridge/
resource exclusion before and after staging, and production re-export proof remain
mandatory. No production script or CI workflow is changed by this slice.

## Commands for the release-checks worker

Run default export/smoke unchanged in its existing output/profile. Then export a
**separate** optional build; do not replace the default QA artifact:

```sh
python -m unittest discover -s tools -p test_browser_zane_showcase.py
python tools/export_browser_qa.py --scenario zane-showcase \
  --production-pck build/web/index.pck --output build/web-qa-zane/index.html
python tools/prepare_playable_web.py build/web-qa-zane
node tools/check_web_package.mjs build/web-qa-zane
```

Serve `build/web-qa-zane` using the existing authorized CI server/browser route and
a fresh disposable Chrome profile (or a separate local URL/subdirectory). Reuse
existing browser/software-WebGL settings; this task adds no flags or bypasses.
With that server/browser ready:

```sh
python tools/browser_combat_smoke.py --scenario zane-showcase \
  --url http://127.0.0.1:8000/index.html --port 9222 \
  --timeout 45 --budget 180 --max-player-turns 20 \
  --output docs/qa/browser-zane-captures
# Mandatory screenshot evidence; inspect its actual pixels in the CI artifact.
test -s docs/qa/browser-zane-captures/zane-practice-actual-3d-loaded.png
test -s docs/qa/browser-zane-captures/zane-3d-movement-completed.png
test -s docs/qa/browser-zane-captures/zane-fire-outcome-and-cleanup.png
test -s docs/qa/browser-zane-captures/report.json
```

The output includes screenshots/checkpoints, actual CDP coordinates, browser
version, latest observation on failure, retained authoritative/visual evidence,
console diagnostics and a failure screenshot when possible. This local cloud
browser lacks WebGL2: do not improvise browser/security workarounds. Actual 3D
browser acceptance and visual inspection must run through the authorized existing
GitHub CI Chrome/software-WebGL route. Python transport and native observer tests
are explicitly not that acceptance.
