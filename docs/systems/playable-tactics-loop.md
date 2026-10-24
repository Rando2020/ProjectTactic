# Playable tactical descent

The Godot Web build is the playable entry point. The React design/prototype screens remain available under `?legacy` and `?dev`. This is an original tactical RPG prototype, not a reproduction of copyrighted game content.

## Player loop

1. Play / Visit the Hearth, then Begin Descent.
2. Choose a route and deploy the four-character party.
3. On each player turn, move and act once in either order. M selects Move, A Attack, S Ability, W Wait. Hover targets for forecasts, then click a highlighted tile to execute. Cancel exits targeting without spending the action.
4. Enemies take their own turns. Victory awards gold, spendable JP and current-job JP.
5. Continue from spoils to the route. Choose battles, boons or story encounters. Job changes and learned abilities remain in the character screen.
6. Continue Descent restores the latest encounter checkpoint. Refresh during combat restarts that encounter; it is not a mid-turn save. Saves are browser-local and origin-specific.

## Implementation

- `BattleManager.gd`: human-controlled default, action/movement ordering, targeting validation and single MP deduction for chain abilities. Automated play is an explicit test opt-in.
- `BattleScene.gd`: victory merges resources into character data, awards progression once and saves route advancement before yielding to the spoils UI. Job-level stat bonuses apply when constructing combat units.
- `AbilityDB.gd`: normalizes missing support targets and radius patterns without mutating shared definitions. Buff/heal types use their appropriate resolver.
- `Unit.gd`: only damage-over-time status IDs deal periodic damage. Beneficial magnitude is not a damage percentage.
- `GameState.gd`: canonical browser autosave, backward-compatible optional run payload, formations, inventory, currency, character resources and job history.
- `RunManager.gd`: preserves permanent progression, resets per-run resources, restores its runtime state from the checkpoint at boot.
- `StartScreen.gd`: working Continue, instructions and music toggle; no misleading save-slot placeholder.
- `tools/prepare_playable_web.py` and `web/compressed-wasm-loader.js`: preserve exact exported engine bytes in gzip and split engine/game data into 3 MiB parts; the loader reassembles them on the client, keeping individual static assets below host limits. Requires browser DecompressionStream support in addition to Godot's WebGL2 and secure-context requirements.
- GitHub Pages builds React plus Godot at `dist/tactics`. The Godot validation workflow also uploads the standalone playable export.

## Validation

Run `python tools/check_playable_loop.py /path/to/godot` using Godot 4.6.2. It creates an isolated save directory, launches the normal project with a test scene, rejects runtime script errors and checks manual turn idling, action-before-movement, support effects, progression, two generated-floor victories, reward advancement, spoils routing, boon selection and checkpoint restoration. Automation exercises production commands and resolution; it does not establish human enjoyment or balance.

Build:

```sh
mkdir -p build/web
godot --headless --path godot --import
godot --headless --path godot --export-release Web ../build/web/index.html
python tools/prepare_playable_web.py build/web
```

Serve the output over HTTPS. For GitHub Pages use the deploy workflow after review and merge.

## Limits and next steps

- Desktop-first. Mobile layout, touch interactions and browser persistence need device acceptance.
- This pass enables a coherent existing tactical loop. Advanced ability descriptions still include aspirational mechanics, such as teleport, cover interception and some mastery effects, which need separate implementation/acceptance. Do not advertise the entire job catalog as feature-complete.
- Three-slot `SaveSystem.gd` is legacy and is not the Continue path. Consolidate it later instead of writing parallel saves.
- Save JSON assumes a game-authored checkpoint. Comprehensive malformed-save recovery and atomic cross-file meta/run transactions remain follow-up work.
- Existing asynchronous VFX can leave resource-leak warnings at headless exit. Runtime script errors are test failures.
- Human balance, difficulty, full ten-floor completion, loss/retry presentation and device testing remain acceptance tasks.

## Review scope

This branch builds on `97574e8` (PR #70), preserving the unmerged terrain/art/HUD stack, and targets main for an integrated review. Those inherited commits are included, not silently merged. Review their existing PRs alongside this integration. No commit is made directly to main and no merge is authorized by this document.
