# Hosted Godot demo candidate

This candidate stacks on PR #42. PRs #38 through #42 remain unmerged. The browser
build executes the Godot game, with the existing title, deployment, battle, reward,
boon, run-map and save systems. The React prototype is not the hosted entrypoint.

## Reproduced export blocker and fix

A real exported PCK has imported textures instead of source PNG bytes. BattleScene,
BattleUI portraits and TacticalGrid previously read only raw PNG files. A packed
resource check reproduced missing sprites and terrain even though Web export passed.
Seven battle-unit and four prop import files also had `valid=false`, with no usable
imported texture. Their imports were regenerated, retaining their original UIDs;
PNG artwork was not changed. Loaders now use imported textures when source bytes
are absent, retaining the native raw-PNG fallback.

## Reproduce and stage

Use Godot 4.6.2 with its single-thread Web export templates and hydrated Git LFS:

```sh
python3 tools/export_godot_web.py --godot /path/to/godot
python3 tools/check_exported_assets.py --godot /path/to/godot
python3 tools/check_integration_checkpoints.py --godot /path/to/godot --pack build/web/index.pck
python3 tools/prepare_hosted_demo.py build/web /empty/staging-directory
```

The staging helper copies the export without altering it, gzip-compresses the
37,695,054-byte engine to 9,379,523 bytes, verifies an exact decompression round
trip, and writes a SHA-256 manifest. This fits static hosts with smaller per-file
limits. The host MUST honor `_headers`: `/index.wasm` needs
`Content-Encoding: gzip` and `Content-Type: application/wasm`. Do not serve the
compressed staging folder from a plain server that ignores these headers.
Use the uncompressed `build/web` for GitHub Pages or ordinary local testing.
Cloudflare documents `_headers` behavior at
https://developers.cloudflare.com/workers/static-assets/headers/.

CI exports and tests the actual PCK, and uploads both `godot-web` (uncompressed)
and `godot-hosted-demo` (gzip/header-dependent). Nothing publishes to GitHub Pages
from this branch. The existing Pages workflow publishes on main push or explicit
workflow dispatch. The separate Sites publication is an owner-private preview of
this candidate, not a main-branch deployment.

## Validation boundaries

The packed-resource suite checks all seven battle sprites and portraits, all 16
original terrain mappings, and all four props. The 36 native checkpoint assertions
also run against the exported PCK, exercising Continue, victory/reward deduplication,
boon selection, abandonment and cold-process restoration. The existing checkpoint
fixture bypasses floor 2 to reach boon selection. It invokes callbacks and does not
prove combat balance, a complete player-driven combat loop, browser IndexedDB,
real browser refresh, or frame rate.

The supervised preview was reachable, but the cloud browser's Godot compatibility
screen reported missing WebGL2 and Secure Context. This environment cannot validate
start/deployment/combat/rewards/boon/next-encounter/refresh through live browser input.
No compatibility checks were disabled. Native packed checks and publication success
must not be described as full browser gameplay approval.

## Tester acceptance

Open the hosted URL using a WebGL2-capable browser on HTTPS. Saves are local to the
browser and origin. Start a run, deploy, use movement and an ability, finish a battle,
claim rewards once, choose a boon when offered, and enter the following encounter.
Refresh before battle and after rewards/boon selection. Use Continue and verify the
same node, party, equipment, HP/MP, boons and currencies. A refresh during battle
restarts that encounter from its checkpoint; there is no mid-turn resume promise.
Record browser/device, errors, and the first failed step before further rollout.

## Next implementation prompt

Play the hosted Godot candidate in a compatible browser. Validate the complete run
loop and refresh/Continue, record screenshots and console errors, and fix only the
first reproduced blocker on a new branch. Preserve save compatibility and do not
merge.
