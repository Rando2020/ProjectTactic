# Ashvale mesh handoff — v02

This is a second authored asset candidate package. It contains actual 3D mesh files, an editable Blender source, image-generated paint textures, production prompts, and an isolated Godot art preview. It is not merged into ProjectTactic and does not replace NOVA's active work.

## Contents

13 GLBs in `models/`: floor-plain, floor-inlaid, wall-full, wall-broken, pillar, stairs-rise-1m, platform-rise-1m, archway, banner, brazier, rubble, vanguard-sword, zane-rig-prototype.

`source/ashvale-master.blend` contains the authored meshes and composed courtyard. `source/build_assets.py` rebuilds the family in Blender 4.5.9 LTS. Two base-color textures are embedded into relevant GLBs and retained in `textures/`. Review images are actual Blender renders, not generated pictures of the finished meshes.

## Open and test

Import `project.godot` into Godot. Run the project; arrow keys move through the clear 3x3 test area, Space plays the attack motion. This is an art/animation preview, not a battle system. The preview is checked with local Godot 4.6.2; production currently documents 4.6.3 and requires its own import and gameplay checks.

Headless checks:
```
godot --headless --path <this-folder> --editor --import
godot --headless --path <this-folder> --script res://godot-preview/verify.gd
```

`source/.gdignore` prevents Godot from trying to import the editable `.blend` file. Copy the GLBs into a new candidate asset directory in Tactic; import those directly. Use Git LFS correctly for binary media, and do not copy `.godot` caches into the repository.

## Contract

One tile is 2x2 m; elevation step is 1 m. GLBs are Y-up. Floors have their walk surface at approximately zero, with thickness below the pivot. Stairs rise 1 m over 2 m. Module placement is centered on the cell; walls span 2 m. The arch has an open central passage.

No physics shapes are embedded. The existing tactical grid owns walkability, height and combat rules. NOVA should assign these visual modules to existing terrain IDs, rather than derive combat state from their visible geometry. Add simple collision proxies only where the 3D integration needs physics queries.

The humanoid export has a skin and 16 bones: root, pelvis, chest, head, plus upper_arm/forearm/hand/thigh/shin/foot on each side. Names are provisional and are not asserted compatible with the existing production skeleton. Three clips: idle (2 s), walk (1 s), attack (1 s). The preview sets idle/walk looping. Attack impact time 0.5 s is only a proposed marker, not a gameplay event emitted by the GLB.

## Known limitations

- Zane is an armored silhouette/rig prototype. He is helmeted and substantially simpler than the earlier concept. No final face, fingers, cloth simulation or deformation-quality approval.
- Rigid armor weighting is intentional; the walk needs foot locking and polish; directional facing is implemented in the preview. Attack is a movement test, not final combat choreography. A sword is included in the character mesh and rigidly weighted to hand.R. The standalone sword is also retained; do not attach a duplicate.
- The palette and painted textures establish a starting direction; they do not yet reproduce the visual sophistication of the reference games. Stone repeats and bright/dark balance need evaluation in the production camera.
- UV overlap is intentional for shared tiling paint, not a unique high-to-low normal bake. Generated texture edges are avoided in UVs; mathematical seamlessness has not been claimed.
- Modular masonry gaps and loose rubble are intentional separate components; ground-plane exceptions apply to floor slabs and blade/prop components.
- Source dimensions and materials are authored choices except the repository's 2 m tile / 1 m elevation contract.

## Next production passes

1. Agree the production skeleton and animation naming with NOVA.
2. Replace the character prototype with a refined original Zane model, proper face/hands and deliberate deformation topology.
3. Refine weapon grip, extreme poses, contact and attack timing. The current attack remains a simple motion study.
4. Integrate a single Ashvale encounter; assess camera-scale readability and frame cost before expanding the family.

## Provenance

Meshes and build scripts authored for this request with Blender. Stone and steel base-color textures generated using built-in ImageGen from original prompts in ART-BRIEF.md. No extracted meshes or textures from Arcane, League of Legends or No Rest for the Wicked are included. Those titles describe visual influences only. Build/runtime checks are recorded under `review/`.

## Changes in v02

Tapered knee plates, layered foot plates, a raised breastplate ridge, asymmetric shoulders, folded rear mantle and split coat panels. Sword follows hand.R in all three clips. Preview turns the character toward movement. Environment modules are carried forward from v01. This is a technical and silhouette iteration, not final reference-quality art.

