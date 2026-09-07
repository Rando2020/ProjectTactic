# Godot browser delivery

The game implementation stays in `godot/`; browser-first describes how testers
access it. The React/Vite build remains a historical reference. This delivery
change does not port gameplay back to JavaScript or modify desktop rendering.

## Build and deployment

- `godot/export_presets.cfg`: tracked, unencrypted `Web` preset using the standard
  single-threaded template, no extensions and no service worker. Exports all
  resources because scenes and assets are also loaded dynamically. JSON files
  are included; test resources are excluded.
- `godot/project.godot`: explicitly selects Compatibility rendering on Web only.
- `tools/export_godot_web.py`: checks for unresolved Git LFS pointers, imports
  with Godot, exports release files, rejects engine errors even with exit code 0,
  and verifies the HTML/JS/WASM/PCK output. Logs live in `build/godot-logs/`.
- `.github/workflows/godot-web.yml`: PR/manual/reusable export job with Godot
  4.6.2 and matching export templates. Checks out LFS assets and runs the existing
  static checker. Uploads `godot-web` and engine-log artifacts.
- `.github/workflows/deploy.yml`: after a merge to main, calls that same export
  job and publishes its artifact to GitHub Pages. Manual dispatch also exists.
  A failed export prevents deployment. PRs build artifacts without publishing.
- `.github/workflows/build.yml`: retained Vite reference-build check. Its success
  alone is not evidence that Godot works.

No Pages settings or published files are changed merely by opening this PR.
The existing Pages site switches to Godot when this change is merged and its
deployment succeeds. Rollback is a revert of the delivery PR and redeployment.

## Local reproduction

Install Godot **4.6.2 standard** and its matching export templates. Fetch Git LFS
assets before importing. From the repository root:

```sh
git lfs pull
node tools/check_godot_stability.mjs --skip-godot
python3 tools/export_godot_web.py --godot /path/to/godot
python3 -m http.server 8000 --directory build/web
```

On Windows use `python` and pass the path to the Godot console executable.
Open `http://localhost:8000` in a browser with WebAssembly and WebGL 2 support.
For a PR artifact, download and extract `godot-web`, then serve that extracted
directory with an HTTP server. Do not open `index.html` as a `file://` URL or
rename individual export files. The production Pages host already supplies HTTPS.

Single-threaded export avoids requiring COOP/COEP response headers on Pages.
See [Godot Web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
Browser audio may require a click first. Browser storage policies can restrict
`user://` persistence. This export is not proof of save/resume correctness.

## Inspection against current code

Baseline inspected: `21f7673b2feb125660797f7d04c2c25e074b2ae8`.

| Area | Observed implementation | Follow-up |
|---|---|---|
| Entry point | `StartScreen.tscn`; New Game routes to the hub | Browser playtest through hub, deployment, battle |
| Run creation | `RunManager.start_new_run()` creates `GameState.active_run` | Verify lifecycle and reward ownership |
| Routes | `RunState.create()` already creates branching routes across ten floors | Older architecture statements that branching is future work are stale |
| Boons | `BoonPickScreen.gd` already exists | Older architecture requests to create a boon screen are stale; verify integration |
| Main autosave | `GameState.save()` saves character/campaign progression, not `active_run` | Choose one authoritative save contract |
| Slot save | `SaveSystem` serializes a run, but restore is guarded on the existing `active_run` being non-null | Reproduce cold-start restoration; reconcile `RunManager` fields |
| Continue / Load | `StartScreen.gd` displays placeholder messages | Wire UI only after the save contract works |
| Run attrition | `RunState` has deployment data but no explicit carried unit HP field | Complete HP carryover and recovery in a later gameplay PR |

## Validation for this change

Locally verified with Godot `4.6.2.stable.official.71f334935`:

- Existing static checker: passes with 12 pre-existing warnings.
- Real editor import: passes without engine errors.
- Release Web export: passes; HTML, JS, WASM and PCK are present, approximately
  51 MiB total before HTTP compression (approximately 36 MiB WASM / 14 MiB PCK).
- Headless main-scene startup: no engine errors during a 120-frame smoke run.
- Existing combat formula test: **9 pass, 1 fail**. Temper HP projection returns
  45 where the assertion expects 46. Combat code and this test are unchanged by
  this PR; investigate separately, do not silently adjust the assertion.

The available cloud browser could not access the local preview. Browser visual
and input verification, audio, a full battle, and reload persistence remain
unverified. Headless startup and successful export do not establish these.

## Browser acceptance checklist before inviting testers

1. Serve the PR build and confirm title art, fonts, and menu appear without
   missing resource or script errors in the browser console.
2. Click New Game, enter the hub, start a run, select its first battle, deploy,
   move a unit and resolve an action. Confirm rewards return to the run map.
3. Check the default viewport and a smaller window for clipped controls; verify
   pointer/keyboard input and audio after the first user interaction.
4. Repeat on Chromium and Firefox. Safari/mobile performance is a separate
   compatibility check, not an assumed result.
5. Treat Continue/Load as unfinished. Do not promise that refreshing resumes a
   run until the follow-up save lifecycle PR is implemented and tested.

## Next bounded task

Unify run persistence and wire Continue: reproduce cold-start restoration,
preserve seed/node/party/boons/currencies, synchronize the run manager, prevent
duplicate rewards, and test save/load round trips before adding more content.
