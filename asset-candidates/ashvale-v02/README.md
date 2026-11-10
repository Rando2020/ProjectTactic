# Ashvale v02 asset candidate for NOVA

Start with [NOVA-HANDOFF.md](NOVA-HANDOFF.md). This folder contains 13 GLB meshes, editable Blender source, generated paint textures, actual mesh renders and a standalone Godot preview. The character has idle, walk and attack clips and a sword weighted to its right hand. This is a low-poly candidate, not approved final art.

## Download and run

Install Git LFS, check out this branch, then retrieve this pack:

```sh
git lfs install
git lfs pull --include="asset-candidates/ashvale-v02/**"
godot --path asset-candidates/ashvale-v02 --editor
```

Run the preview with arrow keys for movement and Space for attack. The separate project does not replace the production game. The pack follows a 2 m tile and 1 m elevation contract; the gameplay grid remains authoritative.

The narrow LFS include avoids fetching unrelated legacy assets with known missing LFS objects. Browser downloads of source archives may contain pointers; use Git LFS to retrieve the binaries.

## Validation and next work

See [review/VALIDATION.md](review/VALIDATION.md) for completed Blender/Godot checks and limitations, and [NEXT-PASS.md](NEXT-PASS.md) for the next art pass. Godot was checked at 4.6.2; production integration still needs checking at the project's version. The mesh QA script requires the `blender-asset-qa` skill; set `BLENDER_ASSET_QA_SCRIPTS` to its scripts folder if installed outside the default Codex skills directory.

![Actual character mesh render](review/zane-rig.png)
