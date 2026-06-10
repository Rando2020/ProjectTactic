# Live Cleanup Targets

These are the recommended live code changes after the test folder is accepted.

## 1. Short Test Run

File:

- `godot/scripts/roguelike/RunState.gd`

Change:

- Make the first playable test run 10 floors.
- Keep later 20-25 floor design as a future balance target.

Reason:

- Tactics battles take longer than card fights. A shorter run makes tuning faster and keeps the reward loop visible.

## 2. Fix Run Floor Label

File:

- `godot/scripts/ui/StageSelect.gd`

Change:

- Replace hardcoded `Floor %d / 10` with `Floor %d / %d` using `RunState.TOTAL_FLOORS`.

Reason:

- The current code can drift when run length changes.

## 3. Manual Play Default

File:

- `godot/scripts/battle/BattleManager.gd`

Change:

- Set auto-battle test mode false by default.
- Keep speed/auto mode as a debug toggle later.

Reason:

- We need human decision data to tune fun.

## 4. Add Battle Telemetry

Files:

- `godot/scripts/battle/BattleManager.gd`
- `godot/scripts/battle/BattleScene.gd`
- `godot/scripts/ui/ResultsScreen.gd`

Track:

- turns taken,
- damage dealt,
- damage taken,
- healing done,
- allies downed,
- terrain hazard triggers,
- boon triggers,
- close-call count.

Reason:

- This gives us the math backbone to tune addictiveness and reward pacing.

## 5. Registry Naming Cleanup

File:

- `godot/scripts/data/AssetRegistry.gd`

Change:

- Add explicit paths for the missing manifest items.
- Prefer generated placeholder names that match `static-ui-placeholder-manifest.csv`.

Reason:

- Replacement art can drop in without code changes.

## 6. UI Scene Pass

Files:

- `godot/scripts/battle/BattleUI.gd`
- `godot/scripts/ui/StageSelect.gd`
- `godot/scripts/ui/ResultsScreen.gd`

Change:

- Use named assets from the registry.
- Keep text dynamic in Godot, not baked into images.

Reason:

- Static art stays reusable; gameplay data stays editable.
