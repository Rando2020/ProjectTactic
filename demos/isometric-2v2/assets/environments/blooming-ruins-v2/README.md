# Blooming Ruins — painted environment kit v2

Generated from the user's approved Blooming Ruins stage reference, with native
Godot UI ornaments and a playable placement preview. This pack targets the
reference's warm ivory stone, lavender shade, ochre ground, olive cypress,
pink flowers and navy/gold accents. It is a visual candidate, not a claim of
finished production art or full integration into the campaign.

## Included

| File | Contents | Intended use |
|---|---|---|
| surfaces.png | Four quadrants: paving, ochre soil, masonry, coping/stairs | Diffuse textures on actual geometry |
| foliage.png | Cypress, pink shrub, pink flowers, hanging ivy, grass, cream-flowered shrub | Six transparent decorative cutouts |
| architecture.png | Full column, broken column, ruined pier, arch | Four transparent fixed-camera architecture pieces |
| props.png | Navy/gold banner, pots, rubble, low wall | Four transparent detail pieces |
| distance.png | Painted valley, aqueducts, clouds and distant ruins | Opaque background; no playable collision |
| move/attack/skill/wait.svg | Original geometric command symbols | Editable UI icons; no rasterized text |
| portrait-frame.svg | Brass ornamental frame with transparent center | UI ornament |
| bloom-theme.tres | Normal, hover/focus, pressed and disabled button styles | Godot-native theme |
| manifest.json | Sizes, hashes, inspected atlas rectangles, pivots and alpha metrics | Sprite slicing and provenance |
| prompts.json | Exact generation prompts, including the unused foliage edit | Reproduction and art-direction record |

There are **19 raster elements across five PNGs**, plus five SVGs and a Theme.
The sheets are source textures, not pre-cut individual files. Generated grids
were uneven: use manifest rectangles rather than automatically slicing equal cells.
ArtStage.gd demonstrates Sprite3D region use without changing the source pixels.

## Run the actual preview

Use the ProjectTactic checkout containing PR #96. Open `godot/project.godot`, then
`res://demos/blooming_ruins/ArtPreview.tscn`, and press F6. Windows users can run
`godot/demos/blooming_ruins/PlayArt.cmd`; set GODOT_EXE if needed. The launcher
isolates saves. The original first-pass demo remains available separately.

This preview inherits the isolated demo encounter and controls. Its 31 checks
cover loading all fourteen scenery regions, background setup and the existing
movement/targeting/combat/enemy-turn contracts. It does not add canonical abilities,
campaign rewards or a new character progression system.

Actual engine capture: `docs/previews/blooming-ruins-art-v2-godot.png`.
The generated stage reference is not the screenshot of this implementation.

## Godot assembly contract

- Fixed elevated isometric view, approximately 30 degrees downward; tile size 2
  world units. Keep the camera fixed in yaw for these pre-painted silhouettes.
- Atlas pivots are bottom-center, except hanging ivy which attaches at top-center.
  Use world-space placement and depth-tested billboards. Keep visible roots supported.
- Sprite alpha cutoff is 0.5; filtering is linear with mipmaps. Import configurations
  enable mipmaps to reduce shimmer. Preview scaling is authored per asset, not one
  universal pixel size. Architecture contains baked perspective, not 3D topology.
- Surface atlas regions are inset inside their quadrants. The preview uses planar
  world UVs, top/side projection and a subtle violet tint on vertical faces.
  Atlas edges are not certified seamless: inspect repetition before large-area use.
- Stairs, floor elevations and retaining walls remain real geometry. Column/arch
  cutouts only supply appearance; they do not define collision or legal movement.
- Keep flowers at borders, already blocked cells and architectural bases. Sparse
  center detail preserves the player's ability to read range and target silhouettes.
- Background is scenery only. The preview uses a large camera-facing quad behind
  the world; it is not a skybox, a 360-degree scene or independent parallax layers.
- UI labels, HP/MP, commands and focus behavior remain live Godot controls. The
  portrait is resolved through the project's existing AssetRegistry with fallbacks.

## Existing art to reuse

Read `godot/data/asset_manifest.json` and AssetRegistry for the approved Zane
portrait/directional sprites and Mira, Kael, Lyra and enemy art. Do not regenerate
their identities from the environment image. The preview retains the old demo's
unit cutouts as a dependency and uses registered portraits; character replacement
and animation belong to the production integration pass.

## Provenance and QA

The five PNGs were produced with built-in image_gen from the user-provided stage
reference. No third-party asset download or extracted commercial game data was
used. SVGs and Theme were authored as editable source. Generation does not itself
establish production suitability; project asset review still applies.

The original foliage result was retained: its alpha checks passed, while the
attempted clean-up edit shifted the palette too brightly. Dark/glowing RGB seen in
some tool previews is largely outside the alpha silhouette; engine inspection is
the acceptance source. The unused edit is not a runtime dependency.

`python tools/inspect_blooming_ruins_art.py` (Pillow required) verifies real clear
alpha and visible silhouettes, measures source bounds and writes the manifest.
It does not edit image pixels. Native Godot 4.6.2 Compatibility rendering was
inspected at 1600×900. Release uses 4.6.3 and still needs browser/device acceptance.
Repository-wide import also reports existing unhydrated LFS audio files; this
silent visual scene runs without them. Its runtime checks are not a clean import
or acceptance claim for all other ProjectTactic assets.

## Remaining work to reach the reference

1. Replace rigid rectangular retaining walls with irregular broken silhouettes,
   beveled stone modules, richer stair landings and foreground masonry framing.
2. Recompose through the production TacticalGrid/PracticeTerrain3D seam described
   in `docs/design/blooming-ruins-integration.md`; keep its authoritative movement,
   ability resolution, enemy intent and Practice lifecycle.
3. Add tested occlusion/cutaway rules so tall columns or foreground foliage cannot
   hide a selectable unit. The art preview does not implement cutaway behavior.
4. Finish directional character animation, foot contact, cast/attack/hit/death
   states, subtle leaf/banner motion, local shadows, particles and sound.
5. Complete portrait initiative UI, responsive HUD checks, native/browser tuning,
   repeat-seam cleanup and human visual acceptance at gameplay scale.

This is the environment build kit and a working proof of placement. The remaining
items are explicitly not represented as generated meshes, animations or shipped
gameplay. No changes to the project's main entry point or deployment are included.
