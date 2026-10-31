# ProjectTactic: standalone 2v2 isometric demo

Open this folder's `project.godot` in **Godot 4.6.3**, let imports finish, then press **F5**. No source-generation step or LFS download is required for this folder.

Zane and Kael fight a Storm Imp and a Void Cultist on a compact painted chapel battlefield. Move, Attack, Skills and Wait use the existing tactical combat rules. Defeat both enemies to win; Replay Fight restores all four fighters. Saves use the separate `ProjectTactic-IsometricProof` namespace.

## Controls

Click/tap a unit or move the visible cursor with arrow keys and press Enter. Selecting the active ally opens Move, Attack, Skills and Wait beside that unit. Other allies and enemies can be inspected but cannot act out of turn. In the menu, use Up/Down and Enter, or click/tap a command. During targeting, arrows move the cursor and Enter or click/tap commits a legal tile. Esc, right-click or Back cancels targeting and returns to the menu; another Back closes selection. M/A/S/W shortcuts work only after selecting the active ally. Touch uses Godot's mouse emulation through the same GUI-safe input path. Zane's Fire costs 12 MP. Each ally acts when its initiative turn arrives.

Cursor: cream corner brackets. Selected unit: gold diamond. Active turn: blue/red glow. Targeting controls move out of the battlefield so the menu cannot cover destination tiles.

## Scope and provenance

This self-contained folder preserves the playable source checkpoint `30323a6d57578571f3838d36cc0bb2234bd0e662`, recovered from the verified source archive SHA-256 `6859d7d06a6e05b6c2cb1b40bd72ecc06305d680ab2b9c30a641b631e9e853ba`. Its scene paths are relative to this project's root. The main `godot/` game is not changed.

The demo uses existing ProjectTactic art, not Final Fantasy Tactics or Tactics Ogre assets. Zane has two authored static poses mirrored into interim facings, rather than a complete animation set. Painted stairs and walls are scenery; the playable floor is flat and 5 by 5.

The source checkpoint passed automated combat/HUD/retry tests and a native Godot playthrough through victory and replay on October 29, 2026. Browser/phone visual acceptance and audio acceptance remain pending. This source publication does not deploy or merge the demo into the live game.

## Tests

From the repository root after importing this Godot project:

```sh
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/SelectionTest.tscn
godot --headless --path demos/isometric-2v2 --script res://prototypes/isometric/SelectionGuiTest.gd
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/BootTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/HudTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/SkirmishTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/JuiceTest.tscn
```

Use temporary XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME directories for isolated automated tests. More original implementation detail is in `prototypes/isometric/README.md`; its builder commands describe the earlier development checkout, not a requirement to run this packaged folder. `HISTORICAL_DESIGN_README.md` is retained for provenance only.

Packaging note: both original WAV tracks are split into three binary parts each to fit the upload channel. The demo assembles them automatically in memory with no user setup. The assembled bytes and decoded PCM match the original WAVs exactly. Export presets include the parts. Combat rules are unchanged. `MusicTest.gd` validates both tracks in source and exported Web PCK.

Selection update (2026-10-31): 37 selection-state checks and independent GUI-event tests pass. Native Godot tested battlefield click selection, contextual menu, keyboard selection/movement, attack preview and cancellation. Full battle/retry regression remains green. Browser/mobile graphical and physical-touch acceptance remain separate gates.

## Portrait turn order
The right rail begins with the active unit marked **NOW**, followed by four projected turns marked **NEXT 1–4**, with existing portrait/idle art, names, and ALLY/ENEMY labels. Repeated portraits mean that unit's later turn, not another copy of the unit. Projection uses the same CT scheduler as actual turns and updates for speed statuses, defeats and replay. Selecting another unit never changes the current actor. Run `PortraitTurnTest.tscn` for 106 focused checks including victory/replay restoration. Native mouse/keyboard turn advance and layout checked; physical-phone and browser graphical acceptance remain separate.

## Rotatable stage comparison

Choose **Try rotatable stage** above the board, then **Q / E** or the two rotation buttons to turn the camera in 90-degree steps through four views. **Return to painted stage** restores the accepted painted presentation without resetting the battle. Painted remains the initial default. Replay retains the selected presentation and resets the camera to view 1.

The comparison uses an orthographic 3D stone floor/plinth with billboard sprite actors, not rigged 3D characters. Terrain, actors and range highlights share a camera; tile picking uses its ground ray. Arrow cursor movement follows the screen after rotation. Logical facing, unit positions, HP/MP, initiative and targeting remain the same across views. Rotation/presentation switching is temporarily locked while an action resolves.

This is deliberately a flat 5×5 combat floor: perimeter ruins are decorative, not walkable stairs or an elevation ruleset. The procedural stone comparison is a functional depth prototype, not a pixel-identical recreation of the painted chapel. Zane's front/back-and-mirrored facings remain provisional. Browser WebGL2 and physical-phone graphics/touch acceptance remain separate from native Godot validation.

Run `res://prototypes/isometric/RotationTest.tscn` for projection, actor picking, screen-relative cursor, selection preservation, per-angle movement/attack/spell, defeat and replay checks.

### Readability polish
Battlefield names are full, high-contrast screen-space labels with ally/enemy edge colors. Labels follow movement and camera rotation, avoid one another, and do not intercept selection. The timeline frames existing Kael/enemy artwork as upper-body portraits without changing source images or combat rules.

Regression: `godot --headless --path demos/isometric-2v2 res://prototypes/isometric/ReadabilityTest.tscn` checks both stage modes, all four angles, phone/desktop viewport geometry, clustered units, KO/retry lifecycle and portrait crops.

### Authored Fire readability pass (2026-10-31)

The supplied Fire sheet is unchanged. Its four charge frames now occupy 0.36 s,
travel 0.36 s, impact 0.40 s and smoke 0.40 s at normal presentation speed.
Charge/travel/impact scales are 0.32/0.27/0.38 (previously 0.24/0.19/0.28).
Authored playback suppresses the competing procedural trail, fan marks, recipient
accent and embers; original-game procedural fallback remains available.
A scaled, bounded visual clock preserves poses on slow frames and completes the
whole tail through hit-pause instead of retiring it at a 550 ms wall deadline.
This is visual windup, not charge-turn, haste or initiative-delay gameplay.

All 15 active demo suites pass against the exported PCK, including 123 new actual
Skirmish readability/lifecycle checks (all 16 poses at 30 FPS, quarter time-scale,
and 8 FPS; one MP12/damage application; cancellation/retry/KO cleanup).
Native Sky screenshots inspected painted/all four rotations and original skins;
an uninterrupted 24-screenshot sequence sampled normal time-scale playback.
These samples are not a continuous video or a physical-phone/WebGL2 performance
claim. Original detached halo/spark ambiguity remains documented in the asset
manifest; no source pixels were repainted or reassigned. Already validated authored
melee slash/impact integration is retained without combat-rule changes.
