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

## Current playability and persistence

The integration includes PR #39's single SaveSystem owner. Continue restores
seed, selected node, party/equipment/vitals, boons, currencies and RNG state.
Victory rewards and node advancement are checkpointed together. See
[the persistence contract](../systems/run-persistence.md).

- Continue is disabled without a valid autosave; an available checkpoint shows
  its floor or hub and gold. It receives initial keyboard focus.
- Enter Hub visits the hub without clearing progress. The New Game label is
  used only when no autosave exists.
- Load Game lists existing autosave/manual slots and disables missing slots.
  Selecting a manual slot promotes it to autosave so the next Continue uses it.
  A failed promotion restores the previous live state and retains the old save.
  Creating manual slots still uses SaveSystem's API; no manual-save picker is added.
- Options opens real Game/Music/FX sliders using the existing AudioSettings
  owner. The settings persist independently of run snapshots.
- The run map has Save & Title. It checkpoints and returns to the title without
  ending the run or paying end rewards. If saving fails, the run stays open.
- Abandon asks for confirmation and explains how to leave without ending a run.
- The Web title omits Exit because closing a browser tab belongs to the browser.

## Development preview

After installing the existing npm dependencies and exporting Godot:

```sh
npm install
npm run dev
```

The default development command now serves `build/web`, with an actionable
error if the export is missing. Re-export after Godot source changes. The
historical React application remains available through `npm run dev:legacy`;
`npm run build` continues to check that reference build.

Use localhost on your own machine or an HTTPS host with WebGL2 support. An
insecure remote preview is not equivalent to HTTPS or trusted localhost.

## Validation and limits

Godot 4.6.2 editor import and release Web export pass. Native persistence tests
cover cold startup and exact state restoration. Native integration checks use
actual Continue, victory, boon, abandonment, audio, and session-exit callbacks.
They also inject failed checkpoint writes. Tests run in disposable Linux user
data directories, not player saves. The integration suite runs in GitHub Actions.

The supervised preview now serves the actual Godot launcher. The available
cloud browser reports missing **WebGL2** and **Secure Context**, before game
startup. Browser gameplay, IndexedDB durability, input, audio and performance
remain unverified. No feature detection was weakened to bypass that limitation.
The shutdown resource-in-use errors were traced to confirmation audio still
playing when tests exit; the harness stops it and allows mixer cleanup. One
ObjectDB leak warning remains in the native victory-process fixture, without
script or engine errors. That warning is not claimed fixed.

The separately known combat formula assertion (45 actual vs 46 expected) is
unchanged and needs investigation, not a silent expected-value adjustment.

## Browser acceptance checklist before inviting testers

1. Open the combined Godot Web export on HTTPS or local trusted localhost, with
   WebGL2 enabled. Confirm the title and fonts appear without console errors.
2. Test Options, then enter the hub, start a run, deploy, move and perform an
   action. Win a battle and confirm its rewards and map advancement.
3. Refresh and Continue before battle, on victory spoils, after boon selection,
   and after abandonment. Compare party/formation, node/floor, boons and every
   currency. Rewards must remain owned exactly once.
4. Test Save & Title, then Continue; cancel Abandon and verify the run remains.
5. Test keyboard/pointer controls and clipping at the default and smaller window
   sizes. Repeat on Chromium and Firefox. Safari/mobile needs separate testing.

Next: obtain browser acceptance on a compatible host before adding more content
or changing combat balance. Do not merge the source PRs automatically.
