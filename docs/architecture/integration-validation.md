# Browser delivery and persistence integration validation

Historical validation snapshot before the playability follow-up.
For current behavior and preview status, see [browser delivery](browser-delivery.md).

Date: 2026-09-08. Branch: `integration/web-run-persistence`.

Combined without merging either pull request or changing main:

- PR #38: `8af0860f2f5e6e6085f8c99856ee60c2bb26d209`
- PR #39: `3770120f67202e09c64d11c8d25d21c626640445`
- Base main: `21f7673b2feb125660797f7d04c2c25e074b2ae8`
- Combined implementation: `3b3bbecff64812e9ba7c03582a504a11a3206e06`

No implementation conflicts or gameplay persistence defects were reproduced.
This branch adds validation only beyond the two PRs. No fix PR was opened.

## Checks actually run

Godot 4.6.2 native Linux:

- Combined editor import and release Web export passed using `tools/export_godot_web.py`.
- Existing cold-process persistence suite: 35 assertions passed.
- Additional integration callback suite: 19 assertions passed across five separate processes.
- Static stability checks passed with 12 existing warnings.
- Diff whitespace check passed.

The additional suite compares the complete normalized SaveSystem snapshot before
and after cold process startup and the actual StartScreen Continue callback.
That comparison includes party registry/equipment, deployment, selected node and
floor plan, seed/RNG, boons, inventory, campaign progress, and all saved currencies.

| Checkpoint | Native restart + Continue | Browser refresh + Continue |
| --- | --- | --- |
| Before battle | Passed; map, party and full snapshot match | Not tested |
| After victory | Passed; actual BattleScene victory callback awards and advances once | Not tested |
| After boon selection | Passed; actual StageSelect callback adds one boon and advances once | Not tested |
| After abandonment | Passed; actual StageSelect callback clears run; Continue opens hub | Not tested |

Repeated actual victory, boon and abandonment callbacks leave the snapshot
unchanged. Victory is invoked as a test callback, not achieved by playing combat.
The fixture bypasses floor 2 to reach a generated floor-3 boon node. These tests
are integration checks for lifecycle code, not an end-to-end playthrough.
The before/victory process emits an ObjectDB leak warning on shutdown. No script
or engine errors remain after test scene cleanup; the warning is retained as a
limitation rather than suppressed or treated as proof of a gameplay defect.

## Reproduce native checks

After importing the Godot project, run:

```sh
python tools/check_run_persistence.py --godot /path/to/godot
python tools/check_integration_checkpoints.py --godot /path/to/godot
python tools/export_godot_web.py --godot /path/to/godot
node tools/check_godot_stability.mjs --skip-godot
```

Both persistence runners use disposable XDG_DATA_HOME directories on Linux/WSL;
they do not touch a player's real saves. Web export excludes `tests/*`.

## Browser acceptance blocker

The supervised preview failed before serving the game because Vite was missing.
Network dependency installation was cancelled by the approval system. An offline
installation could not find the required React Vite plugin in cache, and the
installed primary runtime did not contain Vite. No alternative browser-control
mechanism, public deployment, or main/PR merge was attempted.

Consequently, IndexedDB durability, refresh timing, browser party rendering,
and a browser-played victory are **unverified**. Native restart and a successful
Web export do not establish those behaviors. Do not mark browser acceptance done.

## Next implementation prompt

Validate `integration/web-run-persistence` in a working browser preview using its
Godot Web export. Refresh and press Continue before battle, on victory spoils,
after boon selection, and after abandonment. Record party/formation, node/floor,
boons and currencies before and after each refresh, and verify rewards cannot be
repeated. Investigate the native victory-process ObjectDB shutdown warning if it
also appears during normal play. Fix only reproduced defects, open a bounded PR
if needed, and do not merge PR #38, PR #39, or the integration branch.
