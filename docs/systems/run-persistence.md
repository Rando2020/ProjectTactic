# Run checkpoint persistence

## Contract

`SaveSystem.gd` is the sole writer for campaign, run and meta-progression state.
Slot 1 (`user://save_1.json`, schema 3) is the autosave. Slots 2 and 3 use the
same complete-snapshot format. Loading a slot restores its currency balances;
it never adds saved balances to current balances or emits reward signals.
Audio settings remain independently owned by AudioSettings.

Continue loads slot 1 and routes an active run to `StageSelect.tscn`, otherwise
to `HubScene.tscn`. Missing/damaged/unsupported saves produce an on-screen
message. The separate Load Game slot-picker button remains a placeholder.

This is **node-checkpoint saving, not mid-battle saving**. Closing during an
unfinished battle resumes at the selected run-map node with the saved formation.
Entering it restarts that battle. Closing on the victory spoils display resumes
after the completed node, with rewards already owned. It does not replay spoils.

## State ownership and files

| File | Responsibility |
|---|---|
| `godot/scripts/state/SaveSystem.gd` | Validation, migration, snapshot composition, disk writes and Continue destination |
| `godot/scripts/systems/GameState.gd` | Campaign/party values and run-side state; existing save/load calls delegate |
| `godot/scripts/roguelike/RunState.gd` | Seed, floor plan, selected node, formation, boons, conditions, inventory, reward receipts, aether and saved RNG state |
| `godot/scripts/roguelite/RunManager.gd` | Run lifecycle and live mirrors; restoration has no reward/start side effects |
| `godot/scripts/roguelite/MetaProgression.gd` | Currency and upgrade rules; save delegates to the snapshot owner |
| `godot/scripts/battle/BattleScene.gd` | Synchronous victory checkpoint before awaiting spoils dismissal |
| `godot/scripts/ui/StageSelect.gd` | Checkpoints route/deployment and noncombat outcomes |
| `godot/scripts/ui/StartScreen.gd` | Continue callback |
| `godot/scripts/ui/ResultsScreen.gd` | Presentation only for run completion counts, now awarded in RunManager |

The snapshot contains the full unit registry, preserving equipment, jobs,
learned abilities and vitals rather than only JP. New runs clear battle vitals
but keep character progression. Inventory and pending reward/boon screens are
included. Seed and RNG state use decimal strings to preserve 64-bit values
through JSON's floating-point number parsing.

SaveSystem initializes last in the autoload order, after the state owners have
initialized defaults. Restoration rebuilds the registry and constructs a run
even when the previous `active_run` is null. It then synchronizes RunManager's
active flag, seed, stage, heat, boons, aether and RNG without starting a new run.

## Preventing duplicate rewards

Battle victory wraps gold, JP, loot, meta currencies, loadout XP and node
advancement in a synchronous transaction. Nested save requests are suppressed;
the outer commit writes a single snapshot before UI awaits. Run completion also
uses a transaction and is ignored once no active run remains. Node-scoped reward
receipts protect repeated campaign/stage reward calls after reload. Battle
callbacks have a scene-local once guard. Noncombat effects save after advancing.

Victory now merges vitals into the character registry instead of replacing the
registry entry, and no longer increments run JP a second time. Completed-run
counts are owned by RunManager, not by rebuilding the results screen.

Writes go to a temporary file, flush, then rename over the slot. Failed writes
or replacement leave the previous checkpoint available and report a warning.
The transaction batches disk writes; it is not an in-memory rollback mechanism.

## Compatibility

- If slot 1 is absent, legacy version-1 `save.json` and
  `meta-progression.json` are imported into the unified autosave. Legacy files
  are retained unchanged.
- Schema 1/2 slots are adapted on load. Old boolean `story_flags` values are
  repaired to an empty list, and typed campaign lists are rebuilt safely.
- Old slots did not store aether/RNG state/full party state. Missing information
  cannot be recovered; defaults and available legacy campaign/meta values are
  used. The next save uses schema 3.
- An existing invalid autosave is not silently replaced by a legacy import.
  Unsupported versions and invalid structural data are rejected before restore.

## Regression checks

On Linux/WSL with Godot 4.6.2 installed, from the repository root:

```sh
node tools/check_godot_stability.mjs --skip-godot
python3 tools/check_run_persistence.py --godot /path/to/godot
```

The Python runner imports the project, then starts independent Godot processes
with temporary `XDG_DATA_HOME` directories. It does not touch real user saves.
`godot/tests/test_run_persistence.gd` covers cold-process restoration, exact large
seeds and RNG continuation, node completion, party/equipment/JP, boons, inventory,
pending choices, currencies, null-run slot restore, partial-write suppression,
duplicate reward calls after load, repeated run completion, invalid slots,
corrupt/unsupported files, legacy imports and the actual Continue scene change.
`.github/workflows/run-persistence.yml` runs these checks on PRs.

## Remaining limits

- No turn-by-turn battle restoration or slot-picker UI in this PR.
- Tests exercise native headless Godot. Browser IndexedDB durability, refresh
  timing, audio and a full browser battle still require a Web playtest.
- Browser storage eviction/private browsing can remove or restrict saves.
- This does not resolve the existing unrelated combat formula test discrepancy
  (Temper HP damage 45 versus expected 46).
- The browser-delivery PR is separate; this branch is based on current main.

Next: verify checkpoint persistence in the Web build through deployment, victory,
boon choice and abandonment before extending the gameplay loop.
