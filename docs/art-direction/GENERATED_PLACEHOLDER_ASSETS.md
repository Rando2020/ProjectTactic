# Generated Placeholder Assets

Generation date: 2026-05-18

Generator: `tools/generate_placeholder_assets.py`

Status: placeholder

## Purpose

This pass fills the implementation paths already referenced by the browser and Godot asset registries. The assets are original, deterministic placeholder PNGs intended to unblock UI, battle, and Godot scene integration while final painted production art is still in progress.

## Generated Families

- Browser implementation assets under `src/assets/`.
- Current browser gameplay compatibility assets under `src/game/assets/placeholders/`.
- Godot registry assets under `godot/assets/`.
- Tactical range markers, cursors, and status icons from `docs/art-direction/ASSET_MANIFEST.md`.

## Style Notes

- Classic isometric tactical readability.
- Dark stone, brass, jewel-tone magic accents.
- Allied units bias toward blue and cyan.
- Enemy units bias toward violet and red.
- Status icons use both color and shape cues.

## Exclusions

- No commercial game assets.
- No copied Final Fantasy Tactics, Tactics Ogre, Vagrant Story, or Square Enix-owned silhouettes.
- No AI-generated third-party likenesses.

## Regeneration

Run:

```sh
python tools/generate_placeholder_assets.py
```

If the local shell does not expose `python`, use the bundled Codex Python runtime.
