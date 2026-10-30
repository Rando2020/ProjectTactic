# ProjectTactic: standalone 2v2 isometric demo

Open this folder's `project.godot` in **Godot 4.6.3**, let imports finish, then press **F5**. No source-generation step or LFS download is required for this folder.

Zane and Kael fight a Storm Imp and a Void Cultist on a compact painted chapel battlefield. Move, Attack, Skills and Wait use the existing tactical combat rules. Defeat both enemies to win; Replay Fight restores all four fighters. Saves use the separate `ProjectTactic-IsometricProof` namespace.

## Controls

Click commands and highlighted tiles. Keyboard shortcuts: M Move, A Attack, S Skills, W Wait, Esc Cancel. Zane's Fire costs 12 MP. Each ally acts when its initiative turn arrives.

## Scope and provenance

This self-contained folder preserves the playable source checkpoint `30323a6d57578571f3838d36cc0bb2234bd0e662`, recovered from the verified source archive SHA-256 `6859d7d06a6e05b6c2cb1b40bd72ecc06305d680ab2b9c30a641b631e9e853ba`. Its scene paths are relative to this project's root. The main `godot/` game is not changed.

The demo uses existing ProjectTactic art, not Final Fantasy Tactics or Tactics Ogre assets. Zane has two authored static poses mirrored into interim facings, rather than a complete animation set. Painted stairs and walls are scenery; the playable floor is flat and 5 by 5.

The source checkpoint passed automated combat/HUD/retry tests and a native Godot playthrough through victory and replay on October 29, 2026. Browser/phone visual acceptance and audio acceptance remain pending. This source publication does not deploy or merge the demo into the live game.

## Tests

From the repository root after importing this Godot project:

```sh
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/BootTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/HudTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/SkirmishTest.tscn
godot --headless --path demos/isometric-2v2 --scene res://prototypes/isometric/JuiceTest.tscn
```

Use temporary XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME directories for isolated automated tests. More original implementation detail is in `prototypes/isometric/README.md`; its builder commands describe the earlier development checkout, not a requirement to run this packaged folder. `HISTORICAL_DESIGN_README.md` is retained for provenance only.

Packaging note: both original WAV tracks are split into three binary parts each to fit the upload channel. The demo assembles them automatically in memory with no user setup. The assembled bytes and decoded PCM match the original WAVs exactly. Export presets include the parts. Combat rules are unchanged. `MusicTest.gd` validates both tracks in source and exported Web PCK.
