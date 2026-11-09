# ProjectTactic — standalone 2D isometric 2-vs-2 checkpoint

Local source commit: `30323a6d57578571f3838d36cc0bb2234bd0e662`  
Branch: `prototype/isolated-isometric-20261029`  
Engine: Godot 4.6.3. Date: 2026-10-29.

This is an **interim existing-art checkpoint**, not the requested later FFT-art pass. No proprietary Final Fantasy Tactics or Tactics Ogre assets are included or supplied. It remains separate from the main game; nothing was merged, pushed, deployed or published. The older 1-vs-1 commit `8797df64172abb0823347717ffdc1311acf10d57` and v3/v4 packages are historical, not this 2-vs-2 build.

## Source ZIP

Extract the ZIP and import `ProjectTactic-2v2-source/project.godot` into Godot 4.6.3, let assets import, then press F6 on `prototypes/isometric/Skirmish.tscn` or F5 for the project entry point. This is an already-generated standalone project with hydrated asset bytes, not Git LFS pointers; no repository clone or build script is needed. The original prototype README's repository-level builder commands describe reconstruction from the development repository, not a prerequisite for this ZIP.

Command-line alternative, from the extracted project directory:

```sh
godot --headless --path . --editor --import --quit
godot --path .
```

A genuinely cold import may report pre-existing AudioSettings WAV-loader warnings before import finishes. If so, complete/repeat import before launching. Persistent runtime errors are not expected. Editor/import caches, local settings, Git history and credentials are excluded. The isolated saved-data namespace is `ProjectTactic-IsometricProof`.

## Web ZIP

Extract it, keep all nine exported files together with their original names, and from `ProjectTactic-2v2-web` run:

```sh
python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765/`. Do not open `index.html` as a `file://` URL. Requires WebAssembly and WebGL2. The export is single-threaded, so no COOP/COEP isolation headers or browser-security flags are needed. Audio may require an initial click. This ZIP is a local Web build, not a hosted site or one-click native executable.

## Play

Zane and Kael face a Storm Imp and Void Cultist on the flat 5×5 chapel floor. Initiative chooses the active ally. Click commands/tiles, or use M Move, A Attack, S Skills, W Wait and Esc Cancel. Fire costs 12 MP when available; the cultist can Silence a caster. Defeat both enemies to win. One ally's KO does not end the fight while another lives. Replay Fight resets all four combatants.

## Evidence and acceptance

- Automated source checks: 2 Python builder tests; clean boot and juice regressions; HUD 9 checks; skirmish 73 checks; all 32 existing main-game contracts completed with runner exit 0. Legacy shutdown-resource warnings remain visible in that existing suite.
- Web export: exit 0, no ERROR/WARNING; HTML declared sizes, WASM/PCK signatures and single-thread configuration checked.
- Native visual/action acceptance passed: correct four-fighter chapel scene; Zane Fire spent 12 MP; Wait advanced both enemies; Kael moved and attacked to defeat the Imp without ending the fight; Zane attacked the remaining Cultist; the Cultist took its turn; Kael moved and finished it; Practice Victory appeared; Replay restored all four fighters at full HP and Zane at 90 MP. The included native screenshot shows that replay state.
- Independent checks against the exact exported Web PCK: boot, HUD (9 checks), juice regression and skirmish (73 checks) passed; aggregate exit 0, no ERROR/FAIL.
- Browser rendering/gameplay and phone QA were unavailable; audible output was not accepted (native used dummy audio). No browser, phone or audible-audio acceptance claim is made.

## Remaining limits

Two still Zane poses are mirrored for four interim facings; asymmetric details reverse. They are not four bespoke directions or a walk/sword animation set. Kael and both enemies reuse existing art. Painted stairs and upper architecture are scenery, not a multi-height playable map. Forced lethal-damage defeat fixtures test the loss/retry lifecycle, not natural-loss balance. The FFT-assets-first follow-on is pending the user's own-copy/asset-source clarification; no such assets have been acquired.

## Compact class-skin comparison (2026-10-31)

The isolated demo now defaults to the selected compact **class appearance studies**:
swordsman on Kael's melee role and mage on Zane's caster role. Names, lore, stats,
skills and enemy art are unchanged; the mage appearance is not a canonical Zane
redesign. The **Skins** button restores the original presentation at any time
outside action resolution. Queue and active portraits follow the selected skin.
Rogue and dragoon remain import-ready studies, not new combatants.

Both complete original sets are preserved byte-for-byte under
`prototypes/isometric/assets/character-sets/{compact,painterly}/originals/` with
source hashes and deterministic extraction. Raw sheets stay in GitHub but are
excluded from runtime exports to avoid unnecessary download size.

These are static directional cutouts with existing procedural movement, recoil,
lunge and spell effects—not newly drawn walk or attack frame sequences. Compact
melee uses that procedural fallback rather than briefly swapping to an unrelated
legacy attack pose. Front-left directions (and rogue rear-right) are documented
mirrors; handedness/asymmetric costume details reverse. See the asset README for
anchors, mapping, provenance and limitations. Original assets are retained.
