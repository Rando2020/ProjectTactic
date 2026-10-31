# Zane — standalone isometric proof

An isolated **2D** presentation experiment, not a main-game replacement. It reuses
`BattleScene`, `BattleManager`, the tactical grid, combat resolver, UI, save sandbox
and results logic. No character/terrain 3D rig is created in this mode.

## Run independently

From the repository root, with current `godot/**` LFS assets hydrated:

```sh
python tools/build_isometric_proof.py /absolute/new/path/zane-isometric-proof
godot --headless --path /absolute/new/path/zane-isometric-proof --editor --import --quit
godot --path /absolute/new/path/zane-isometric-proof
```

Godot **4.6.3** is the tested engine. Import the generated `project.godot` into the
Godot project manager as an alternative. The builder refuses existing destinations
and never edits the original game. The copy uses GL Compatibility and the separate
`ProjectTactic-IsometricProof` saved-data namespace. First launch enters the 2-vs-2 skirmish;
leaving the results returns to the standalone title, not the production campaign.

**Controls:** click/tap a unit or arrows + Enter to select. The active ally opens a contextual command menu; other units are inspect-only. Up/Down + Enter navigate commands; arrows + Enter select a target. Esc/right-click/Back cancels, then closes. M/A/S/W shortcuts require selecting the active ally.
Zane and Kael fight a Storm Imp and a Void Cultist on the same 5×5 floor.
Each ally activates through normal initiative; commands affect the active ally.
Move toward an enemy for a sword attack. Fire is equipped in a fresh
profile, costs 12 MP and uses the existing range-three fan. The cultist can
legitimately Silence a caster; no combat rules are bypassed for the demo. Click a highlighted
target to commit; cancel leaves resources intact. Defeat both enemies to win; losing one ally is not defeat while the other lives.
Results offer Replay Fight, resetting all four fighters.

## Test / package

```sh
python -m unittest discover -s tests -p test_isometric_build.py
# Use temporary XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME for tests.
python tools/check_isometric_proof.py /absolute/new/path/zane-isometric-proof
python tools/check_playable_loop.py
# PCK export needs no export template; running it requires the Godot engine.
godot --headless --path /absolute/new/path/zane-isometric-proof --export-pack Linux /absolute/path/zane-isometric-proof.pck
godot --main-pack /absolute/path/zane-isometric-proof.pck
```

The source tests preserve main-game entry routes; the proof integration test must
run in the generated copy because its result routes intentionally point back into
this prototype. Automated contracts are not human visual/audio acceptance.

## Art and bounded limitations

- Chapel plate and detailed portrait are existing ProjectTactic imagery.
- `assets/zane-front.png`: user-approved original transparent candidate, Library
  `libfile_6c56fd563b688191b2e0d0a9c1d61f3b`; SHA256
  `d299d45c28f164620beee1d88871edea780ce4ad3c4873f1bea86735b64ab236`.
- `assets/zane-back.png`: newly generated matching rear three-quarter pose,
  based on the approved candidate; SHA256
  `88092f9f958fb4779cd7dcf30d3ae749490f26f6c7ae232313210052e2de3e94`.
  No Final Fantasy/Tactics Ogre game assets.
- Two authored still poses are mirrored for four interim facings. This reverses
  asymmetric sword/shoulder details; these are **not four bespoke directions**.
- Existing movement/attack VFX animate the still sprites; no bespoke walk/sword
  frame animation is claimed. Painted stairs/upper architecture remain scenery;
  the playable area is the calibrated flat 5×5 floor.
- Existing Kael, Storm Imp and Void Cultist art is reused; this is not a final art pass for every actor.
- The loss test uses the real death/objective/results route with forced lethal
  damage. It proves loss/retry lifecycle, not natural defeat balance.
- Browser acceptance and one-click OS executables are separate delivery gates.

## Verification evidence (2026-10-29)

- Separate-builder tests: 2 passed (including rejecting Godot's zero-exit script errors).
- Direct initial scene: passes on both fresh and existing isolated save.
- Compact HUD: 9 checks; 2-vs-2 command/save flow: 73 checks; no failures.
  These include Kael name/portrait and actual movement, both enemy AI actions,
  single-Fire MP cost, real combat victory and four-unit retry, plus explicit
  partial-KO nonterminal and full-party defeat fixtures.
- Native-reference flash/wobble regression: original grid API errors reproduced,
  repaired in proof-only autoload adapter, clean after repair and actor disposal.
- Existing main-game aggregate: all 32 contracts completed, runner exit 0. Existing
  legacy shutdown-resource warnings remain visible under that runner's allowance.
- A genuinely cold import may log the existing AudioSettings WAV loader errors
  before Godot finishes importing. A second import is clean; runtime checks reject
  script/resource errors. The proof adapter avoids adding early UI/font imports.

Desktop-native visual and action evidence is recorded separately by the parent
QA session. Headless tests alone are not a native/browser acceptance claim.

The earlier reviewed 1-vs-1 proof is preserved at local commit
`8797df64172abb0823347717ffdc1311acf10d57`. `Battle.tscn` remains its reusable
base; `Skirmish.tscn` supplies only the two additional existing combatants.
The legacy practice-mode flag is retained internally for no-reward safe retry;
it does not constrain the standalone skirmish roster.

## Popup bounds repair
Skills now measure their own height and stay above the separate Back control, instead of inheriting the bottom-aligned Back position. Long lists scroll and follow keyboard focus. Command menus also scroll on short landscape viewports so Wait/Close remain reachable. `SkillBoundsTest.tscn` covers four viewport sizes, painted/rotatable modes and all camera angles. This does not change abilities, costs, initiative or combat rules.
