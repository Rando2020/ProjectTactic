# Playable tactical descent

The Godot Web build is the playable entry point. The React design/prototype screens remain available under `?legacy` and `?dev`. This is an original tactical RPG prototype, not a reproduction of copyrighted game content.

The [live public build metadata](https://rando2020.github.io/ProjectTactic/tactics/build-info.json)
identifies the current deployment; see the [dated delivery ledger](../production/delivery-ledger.md)
for release evidence and limits. Prototype 3D is opt-in through Practice → View &
quality settings → Sprites active → Show 3D; it is not the default presentation.

## Player loop

1. Play / Visit the Hearth, then Begin Descent.
2. Choose a route and deploy the four-character party.
3. On each player turn, move and act once in either order. M selects Move, A Attack, S Ability, W Wait. Hover targets for forecasts, then click a highlighted tile to execute. Cancel exits targeting without spending the action.
4. Enemies take their own turns. Victory awards gold, spendable JP and current-job JP.
5. Continue from spoils to the route. Choose battles, boons or story encounters. Job changes and learned abilities remain in the character screen.
6. Continue Descent restores the latest encounter checkpoint. Refresh during combat restarts that encounter; it is not a mid-turn save. Saves are browser-local and origin-specific.

## Local Zane impact showcase candidate

These instructions describe the **local candidate checkout**, not a claim that the public build above contains it. Open `godot/project.godot` with Godot 4.6.3 and run the start screen.

1. Choose **Practice: Zane showcase**. It uses the existing Practice map, four-character party, three enemies, initiative and save sandbox. There is no forced Zane turn; wait for him normally.
2. Try movement, a basic sword attack, or **Fire on separate turns**. Fire remains 12 MP, range 3 and a three-tile fan—not a single-target Fireball. Each recipient's actual hit, immunity, armor loss or HP loss drives its feedback.
3. This entry starts with the existing 3D view enabled. **View & quality settings** retains Show sprites/Show 3D and quality controls. The new Zane variant falls back to original Zane, then the visible sprite if unavailable.
4. **Reduced Zane impact motion** suppresses only the new camera kick, target wobble and flash. Animation timing, targeting, results and sound remain. This preference is session-only, survives Practice retry, and clears on exit; it does not create a global saved setting. Change it during your idle player turn.
5. The new sound uses existing **FX → Game** buses: either Game or FX at zero is silent, while Music remains separately controlled. Retry and exit keep the existing canonical-save sandbox behavior.

Automated contracts are not native/browser art, audio-mix or frame-time acceptance. Final source export, clean-checkout/remote hydration and gameplay acceptance remain separate release gates; live `build-info.json` remains the deployed identity authority.

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

## Clean checkout and validation

Install Git LFS and the official **Godot `4.6.3.stable.official.7d41c59c4`**
(non-.NET) engine; release exports require matching **4.6.3 export templates**.
Start from current `main`, not an earlier delivery hash, unless deliberately
reproducing a historical checkpoint:

```sh
GIT_LFS_SKIP_SMUDGE=1 git clone --branch main https://github.com/Rando2020/ProjectTactic.git
cd ProjectTactic
git lfs install --local
git lfs fetch --include='godot/**' --exclude='' origin HEAD
git lfs checkout 'godot/**'
godot --version  # expected: 4.6.3.stable.official.7d41c59c4
godot --headless --path godot --editor --import --quit
python tools/check_playable_loop.py
```

Hydrate only the current `godot/**` runtime scope; do not use a blanket historical
LFS fetch/checkout to fix unrelated archived pointers. Inspect logs as well as
exit codes: import can exit zero while reporting missing resources or script
errors. The [Pages gate](../../tools/export_pages_web.py) rejects those failures
before publishing. Known shutdown-resource diagnostics are retained, not hidden.

Run `python tools/check_playable_loop.py /path/to/godot` with the same engine. It creates an isolated save directory, launches the normal project with a test scene, rejects runtime script errors and checks manual turn idling, action-before-movement, support effects, progression, two generated-floor victories, reward advancement, spoils routing, boon selection and checkpoint restoration. Automation exercises production commands and resolution; it does not establish human enjoyment or balance.

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

## Historical integration review scope

The original integration built on `97574e8` (PR #70), preserving the then-unmerged
terrain/art/HUD stack for review rather than silently merging it. That checkpoint
was subsequently integrated through PR #72; PR #73 repaired Pages and PR #74
added the later shared-party checkpoint. See the [delivery ledger](../production/delivery-ledger.md)
for exact merged/deployed identities. This historical scope is not a pending merge
blocker, and this document does not authorize future merges.
