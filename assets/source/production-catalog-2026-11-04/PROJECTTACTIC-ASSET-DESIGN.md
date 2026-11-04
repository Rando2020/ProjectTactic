# ProjectTactic: meaningful asset production plan

**Version 1.1 • 4 November 2026 • Production design, not a shipped-build claim**

## The outcome

Build one coherent, readable tactical encounter before expanding the roster or producing more disconnected art. The current useful target is the four-combatant chapel/Blooming Ruins slice: Zane and Kael against a Storm Imp and Void Cultist. Give that encounter a consistent environment, complete decision states, legible characters, and effects attached to actual abilities.

The catalog contains **63 asset families**, not 63 completed assets. An asset family can contain several views or states. Every family has a stable ID, purpose, priority, delivery contract, acceptance test, existing-evidence note, and production/runtime status. The JSON and CSV are planning records, **not replacements for the game's asset manifest**.

The priority is to reuse and finish, rather than regenerate everything:

- **P0: 31 families needed by the current slice.** Many can reuse existing art or UI components. This is a dependency list, not a request to generate 31 new packs at once.
- **P1: 25 families that strengthen the same scene or already-supported mechanics.**
- **P2: 7 later-content families.** Do not generate these until a concrete gameplay slot calls for them.

## Verified reusable inventory

The inspected v11 archive contains **76 actual combat-frame PNG files** in the three specified frame directories. This is a file count, not a count of distinct abilities or proof of animation quality:

- **52 modular frames:** 4 shared casting frames plus 12 each for Lightning, Void Pulse, Dark Breath and Shadow Mend.
- **16 Fire frames**, each 512×512.
- **8 melee frames:** 4 slash and 4 impact, each 1024×1024.

`verified-reusable-frames.csv` records their archive-relative paths, dimensions and SHA-256 hashes. All 76 are actual image files, not Git LFS pointer text. The archive includes code-side spell catalog entries. This establishes recoverable art and existing mappings, not a fresh browser gameplay pass or acceptance of every visual.

Existing provisional ally directions and the review-only four-idle Void Cultist candidate still need identity/registration review. Separate Ice candidate material also exists; it is not counted among these 52 archived modular frames. Do not confuse source atlas PNGs, previews, repeated archive copies or shared casting with additional unique runtime frames.

## Newly registered candidates and studies

Revision 1.1 adds an explicit **9-entry candidate/reference register** in JSON and CSV. It records **1 existing approved front reference, 3 generated candidates and 5 exploratory studies**. Reference and candidate PNGs are included beside this catalog. They are source/review files, not runtime exports.

| Item | Current status | What prevents production use |
|---|---|---|
| Zane existing front | Approved identity reference | Does not approve new derived views or prove a complete runtime set |
| Zane rear NE | Generated candidate, not approved | Visible height 983 px versus 1064 px front; feet/scale unregistered; costume and pose discrepancies |
| Zane rear NW | Generated candidate, not approved | Visible height 841 px versus 1064 px front; feet/scale unregistered; costume and pose discrepancies |
| Broken pillar | Generated candidate, not approved | Genuine alpha reported, but footprint, scale, occlusion and camera/rotation tests pending |
| Haste icon | Study only | Edge cleanup, 24/32/48 px review and verified gameplay slot pending |
| Cultist front/rear/opposite | Three studies only | Staff handedness changes; views are not a coherent, registered sprite set |
| Stone material | Study only | Not matched to approved continuous cream-stone palette; seams untested; not a runtime tile |

Across the new Zane rear images, the **pouch, scarf, coat and sword pose vary**. The opposite front **SW view remains missing**. Source-pixel silhouette heights do not establish display scale; each image needs a measured foot pivot, body bounds and an explicit runtime scale. These two rear candidates are still images, not breathing animation. The approved front remains the identity reference while these issues are resolved.

The existing current-demo priority remains unchanged. The studies are now traceable instead of being silently promoted into finished assets. No game source, imported asset, gameplay behavior or published build was changed by this catalog revision.

## What the design must preserve

The user's approved courtyard direction is **cream stone, lavender shadows, ochre soil, and lilac flowers**, with a continuous painterly environment and a tactical grid layered on top. Visible terrain should not look like repeated square tiles. The references point toward painterly lighting and materials with the clean silhouettes and immediate tactical readability of classic isometric RPGs. Use original characters, architecture, ornament and symbols.

Stage rotation and breathing sprites are known goals. A single painted background does not provide a rotating stage, and four unrelated poses do not establish animation. The catalog therefore separates view-independent material/identity masters from the files needed by each renderer.

The older recovered asset bible's dark charcoal/moss palette is useful historical context, not the authority to replace the later approved courtyard palette. Dark ink remains appropriate for interface surfaces, where it keeps cream labels and tactical information readable.

## Visual system

### Environment

- Large, connected cream-stone shapes with selective chipped edges and broad lavender shadow planes.
- Ochre earth crosses cell boundaries naturally. Soil, moss, and flowers use irregular patches rather than a different decorative border on every tile.
- Lilac flowers concentrate along broken masonry and scene margins. The playable center stays quiet enough for feet, paths and target markers.
- One architectural focal point, such as a broken arch, is enough for the small encounter. More detail should not mean more visual competition.
- Paint texture inside materials; preserve crisp silhouettes and contact edges. Avoid glossy plastic, tiny high-contrast cracks everywhere, or inconsistent light direction between pieces.

### Units

Preserve established identities. Team is communicated by a badge/ring and shape, not by repainting every ally blue and every enemy red. A swordsman, heavy defender, small imp and robed caster must remain recognizable in grayscale at gameplay scale.

Costume, weapon hand, eye placement and accessory count must remain consistent across directions. Preserve original sprite and portrait identity references alongside every production sheet. Art-role labels in older documents are not authorization to rename characters or replace a drake with a humanoid.

### Interface

Use a restrained dark ink surface, warm light text, thin aged-brass framing and clear state shapes. Painted material texture belongs in corners and margins, never beneath dense text. Generate decorative assets; render labels, numbers and dynamic state in the engine.

Suggested palette tokens, **production proposals rather than approved samples**:

| Token | Proposed color | Use |
|---|---|---|
| cream-stone | #D8C6A4 | dominant world material |
| lavender-shadow | #7B7394 | cool material shadows |
| ochre-earth | #A8754F | soil and warm transitions |
| lilac-growth | #B4A0D1 | sparse vegetation |
| ink-panel | #202535 | interface surfaces |
| ink-deep | #121722 | modal and text backing |
| warm-text | #F0E8D8 | primary interface text |
| aged-brass | #B9985D | restrained frame decoration |
| focus-gold | #E7CB85 | active/focused state |
| ally-cyan | #60BFC9 | ally badge and move cue |
| hostile-coral | #E28177 | hostile badge and attack cue |

All final combinations need gameplay-scale and contrast checks. Color is always reinforced by shape or text.

### Readability order

1. Acting unit, selected target and confirmation state.
2. Legal movement, affected tiles, hazards and elevation.
3. HP/resources/status and the consequence of the next action.
4. Other units and architectural occlusion.
5. Decoration and surface texture.

An impact may briefly dominate, but it must not cover the state needed to understand its result.

## Two delivery tracks, one art direction

### Current 2D adapter

The inspected recovered Godot source uses a **96×48 top diamond**, **16 px visible slab depth**, and **14 px logical elevation offset**. A standard complete block is therefore 96×64. Top contact center is (48,24). A 4× art master may use a 384×256 canvas with 384×192 top footprint and 64 px slab depth, then produce a carefully checked runtime export.

These are dimensions of the recovered renderer, not a universal engine constraint. The source also has a map-specific painted-tile-size override. Verify the exact destination scene before import.

Keep side-depth and logical elevation separate. Raising the art by 14 px is not the same operation as stacking 16 px slabs. Do not paint a staircase into a flat tile and call it traversable elevation.

### Rotating environment track

Use the same material IDs on modular meshes or another real multi-view representation. Prefer continuous ground surfaces and decals to visible tile trays. Architecture must have valid back and side surfaces. A 2D fallback requires authored orientation views and foreground/occlusion layers, not rotating an illustration flat on screen.

The tactical grid, occupancy, movement cost, target eligibility and height remain gameplay data. Materials and props do not invent new rules. A rendering adapter translates grid positions into presentation coordinates. Existing 3D studies use a different scale, so do not copy the 96 px or 14 px numbers directly into metres.

Quarter-turn camera controls need camera-relative sprite-facing selection and world-facing preservation. Show these controls only when the renderer actually supports them. Camera rotation and end-turn unit facing must be separate concepts in the UI.

## Production contracts

### Terrain and props

- Separate base surface, cross-cell transition/decal, vertical side/occluder, and tactical overlay.
- A block export has a declared top polygon, contact origin, outside extent, and occupied cells. It never contains a unit, grid label, selection ring, or decorative fake shadow beyond its declared extent.
- Use 3 quiet stone variants and 2 crack variants before producing a large biome set. Check a 3×3 arrangement, not just isolated cards.
- Every tall prop declares whether it blocks movement, line of sight, both or neither. The engine data remains authoritative.
- Keep a reference view with grid off and another with movement/target overlays and all four combatants present. An attractive concept image is not proof of these conditions.

### Characters and enemies

Proposed normalized small-unit canvas: **128×128 RGBA, foot pivot (64,112)**. This is a new export target, not a claim that current files already follow it. Large weapons may need a larger declared canvas; visible body scale must remain consistent. All pivots and body bounds belong in metadata.

First deliver four authored idles: NE, SE, SW, NW. Next extend one character through a complete useful action set before multiplying the work across the roster. A proposed full small-unit frame budget is:

- Idle breathing: 4 frames per direction.
- Walk: 6 per direction.
- Attack or cast: 4 per direction for each supported action.
- Hurt: 2 per direction.
- KO: 1 terminal pose per direction, with transition as needed.

These are planning budgets, not a requirement to manufacture unnecessary frames. Use the actual move/cast durations and character needs to decide. Breathing should be subtle torso/cloth motion with stable feet, not whole-character inflation. Reduced-motion mode uses a still.

**Exact prototype scale and anchor correction:** the illustrated Zane branch in the inspected v11 `prototypes/isometric/Unit.gd` uses scale **86/1080**, a front source-pixel anchor **(650,1150)** and a rear anchor **(630,1160)**. Camera-relative N/W selects the rear image; W/S are provisionally mirrored with offset correction. The new NE/NW candidates have different visible heights and unregistered feet, so these old anchors must not be copied blindly.

The same prototype has a **separate compact-skin branch** using **86/600** and anchor **(400,740)**, and a Kael fallback using 80 divided by the texture's maximum dimension. The earlier **80 px ally / 95 px enemy** description belongs to historical base-unit behavior, not the exact illustrated-Zane prototype. The proposed 128×128 export canvas is a future normalization proposal, not an instruction to replace these adapters without testing.

Do not mirror asymmetric equipment as a finished four-direction solution. If mirrored temporary views remain, label them provisional in the catalog and viewer.

### Spells and combat effects

Re-use the existing modular casting vocabulary. Shared casting, formation, action/travel, impact and dissipation are composable modules. Not every spell travels: an electrical pillar should not be mislabeled a projectile or descending bolt.

Each frame records source rectangle, semantic anchor, duration proposal, sequence phase, source hash and element. Existing candidate sheets have variable row geometry, so their explicit rectangles are authoritative. A regular-grid importer is unsafe without normalization.

Separate caster-ground, projectile-origin, target-body, and target-ground anchors. Attach gameplay resolution to a declared event, never an arbitrary animation frame number. Suggested visual timings do not create new charge-time mechanics.

Every effect must finish fully clear, preserve team/target cues, work over light and dark terrain, and have a reduced-flash/motion alternative. Alpha must be genuine transparency, with no baked checkerboard or floor plane. A contact sheet is not playback QA.

### UI art versus UX implementation

A panel texture is an asset. A command confirmation is a behavior. The catalog includes both so that decorative work cannot be mistaken for a fixed interaction.

Use scalable engine layout and live text. Supply button states for default, hover, keyboard focus, pressed, selected, disabled, loading and error. A disabled skill displays a reason such as insufficient MP or Silence, based on the real state. A generated label embedded in artwork is not acceptable.

## Required interaction states

The four known gaps are explicit move/target confirmation, enemy inspection, facing after Wait, and instructions that follow the current state.

| State | What the player sees | Confirm | Cancel/back |
|---|---|---|---|
| Command | Active unit, legal commands, relevant HP/MP/status | Choose command | Close nonessential panel |
| Move preview | Reachable cells, path, destination, cost | Choose destination | Return to Command |
| Move confirmation | Pending destination and path; explicit Move/Cancel controls | Commit movement preview | Return to Move preview |
| Post-move Command | New position, remaining choices, Undo if allowed | Choose next action | Undo movement before action resolution if game permits |
| Target preview | Valid targets, AoE, affected allies, current forecast | Choose target | Return to Command or Skills |
| Action confirmation | Attacker, target, cost, actual consequences and explicit Confirm/Cancel | Commit once | Return to Target preview |
| Facing choice after Wait | Four direction arrows, focused direction, front/back cue | Confirm facing and end turn | Return without spending the turn |
| Resolving | Input locked, effect, outcome; no misleading actionable buttons | No duplicate commit | No cancellation after resolved game event |
| Inspect | Read-only ally/enemy details and status explanations | Close or return | Restore previous selection state |
| Result | Clear victory/defeat, Replay control | Reset encounter | Leave according to scenario flow |

If the rules permit another action after resolution, return to Command; otherwise advance according to the game's established turn lifecycle. This design does not invent extra action points or change combat balance.

Context text comes from this state machine. Examples: “Choose a destination”, “Confirm move”, “Choose a target”, “Confirm Fire”, “Choose facing”, “Enemy acting”. The current command's inputs must agree with the hint. Keyboard focus, mouse hover and selected target are separate states.

On cramped screens, keep the current confirmation and cancellation visible. Collapse secondary details or open an inspector drawer instead of covering the battlefield with several permanent panels. Target sizes and text scale need actual browser/device checks before acceptance.

## First production batches

### Batch A: make the environment and decisions coherent

1. Produce a small cream-stone/ochre material set and transition masks, then validate a continuous 3×3 patch with grid hidden.
2. Produce the move, path, destination, attack, AoE, invalid, active and facing visual language with one geometry contract.
3. Produce one panel/button/icon kit and show it in the move confirmation, action forecast, enemy inspector and facing-choice states.
4. Reuse current four combatant art in the composite to judge scale and contrast. Do not spend the whole batch making a prettier empty environment.

**Exit:** source assets, individual exports, catalog records and one labeled mockup are available. This is an art/UI candidate exit, not gameplay acceptance.

### Batch B: close current characters and combat feedback

1. Fix registration and identity consistency for the existing Void Cultist candidate before generating a second enemy concept.
2. Resolve actual authored versus mirrored Zane/Kael facings. Produce missing unique views, then one complete breathing/action sample for one unit.
3. Verify/reuse the existing Fire and melee packages before new Ice/Lightning art. Add only missing phases or status feedback needed by the demo.
4. Validate all four combatants against the same stage and UI.

**Exit:** unique directional assets, pivots, timing/event metadata and dynamic preview evidence. No engine claim until imported and tested.

### Batch C: integration and acceptance

Use a separate candidate scene/branch, retain fallbacks, fix the four interactions, verify unit scale/anchors, test terrain occlusion and any camera turns, then run the encounter through victory, defeat and replay. The existing working build remains available until the new one passes.

**Exit:** a specified build with engine import, actual browser play evidence and a short known-limits report. Only then use “engine verified” or “shipped”.

## Status and evidence discipline

- **Planned:** a brief exists; a file is not implied.
- **Study only:** exploratory art exists, but it has not qualified as a coherent production candidate.
- **Approved reference:** an existing approved identity or visual reference, not automatic approval of derived work.
- **Generated candidate:** output exists, but art, dimensions or registration may still be wrong.
- **Normalized candidate:** files, dimensions, alpha, pivots and manifest are checked.
- **Engine verified:** imported and inspected in the exact target build.
- **Accepted:** visual and gameplay-scale review passed; approval/evidence is recorded.
- **Shipped:** present and verified in the delivered build.

Store original/reference images, exact prompt, generation tool, date, selected output, rejected versions and a small QA record. Stable asset IDs stay independent of filenames. Do not overwrite originals or discard fallback art while a replacement is under review.

The authoritative delivery manifest should include: ID, version, role, source, files/hashes, dimensions, crop rectangles, pivots, body bounds, views, states, frame durations, event markers, footprint, material/theme tags, fallback and validation evidence. The planning catalog leaves output_files empty for unproduced work. Existing generated candidates are now registered with their repository-relative image paths; an ID in output_files does not mean the candidate is accepted, normalized or installed. Per-candidate status remains authoritative.

## Acceptance checklist

### Technical

- Real PNG/SVG/image data, no LFS pointer masquerading as an image.
- Expected dimensions, genuine alpha, no unwanted clipping or padding-related scale change.
- Stable anchors through animation and facing changes.
- No missing references; fallback behavior remains intact.
- Source art and runtime exports are separated. Atlas sizes and import filtering are tested, not assumed.

### Visual

- Clear at real gameplay scale, using the exact scene's scale and anchors, including the illustrated-Zane prototype's 86/1080 adapter where applicable.
- Four units remain distinguishable in grayscale and over both light and dark surfaces.
- Path, attack, AoE, invalid and facing states work without relying on color alone.
- Continuous terrain when the grid is off; precise selection geometry when it is on.
- No copied franchise characters, logos or symbols; identities match approved references.

### Behavioral

- Selecting an enemy inspects it without consuming a turn or changing the active ally.
- Move and action confirmation commit once; Cancel and Undo preserve allowed reversibility.
- Wait opens facing choice and only the explicit confirmation ends the turn.
- Hints reflect the state after every transition.
- HP/resources/status, forecast and effect outcomes agree with game rules.
- Replay restores the complete encounter and does not preserve stale highlights or prompts.

### Browser/runtime

- Actual import and play in the delivered target, including selection, occlusion, zoom and camera behavior.
- Actual browser input/viewport checks, not only headless parsing or a static screenshot.
- VFX playback, reduced motion, repeat casts, and end-state cleanup.
- Report untested audio, mobile, camera rotation or performance honestly rather than allowing a broad “passed” label to hide them.

## Evidence basis and limits

This design also incorporates the current archive audit (`verified-reusable-frames.csv`) of ProjectTactic-v11-source.tar.gz. It used the user's current asset request and earlier approved courtyard/style/rotation preferences; recovered ProjectTactic source specifications and assets; and local Void Cultist and modular Ice/Lightning candidate manifests/QA. The inspected standalone checkpoint identifies source commit **30323a6d57578571f3838d36cc0bb2234bd0e662** (29 October 2026). It is a historical checkpoint, not proof of current main or the latest recovered integration.

Useful project references: `docs/architecture/asset-bible-v1.md`, `docs/ISOMETRIC_TILE_ART_SPEC.md`, `docs/TACTICAL_GRID_SPEC.md`, `ASSET_PIPELINE.md`, `godot/data/asset_manifest.json`, and the relevant Unit/TacticalGrid source. The later approved courtyard art direction takes precedence where the older palette differs.

The catalog is a grounded production brief. It does not claim that all proposed assets were generated, that review-only assets were approved, that interaction bugs were fixed, or that a new game build was published.
