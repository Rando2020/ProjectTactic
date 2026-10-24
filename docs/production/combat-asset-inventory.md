# Combat slice asset inventory

Audited 2026-10-23. Existing Godot isometric 2D rendering retained. No generated art was needed for this implementation pass. This inventory records integration status, not browser visual approval.

| Group | Status | Source and treatment |
| --- | --- | --- |
| Four party characters | Usable now | `godot/assets/characters/character-{vanguard,arcanist,warden,wayfarer}-idle-v01.png`; existing art, foot-anchored sprites and shadows |
| Hollow enemies | Usable now | Existing lancer, bulwark, stray and cantor idle artwork |
| Terrain and props | Usable now | Existing terrain manifest and Forgotten Field scenery; retain height projection and depth sorting |
| Movement | Needs adjustment | Existing tile-to-tile tween works; sprites still glide, without walk-cycle frames |
| Attack and casting poses | Needs adjustment | Existing idle sprite gains short anticipation, lunge and recovery; dedicated directional poses remain missing |
| Hit and defeat | Usable now | Existing recoil, tint and defeat fade; visual acceptance pending |
| Slashes and projectiles | Usable now | Procedural `VFXManager` lines, polygons and tweens; slash contact at target body, arrow travel before resolution |
| Casting | Usable now | New procedural casting ring and traveling energy orb; generic lead-in, element-specific existing impacts |
| Fire, ice, lightning, wind, holy and dark | Usable now | Existing procedural impact effects reused |
| Heal and protection | Usable now | Existing cure and protect effects; fixed empty healing glyphs; capped healing feedback matches actual restored HP |
| Raster VFX sheets | Unused in this pass | Existing `godot/assets/vfx/*-impact-vfx-sheet.png`; require frame/alpha inspection before replacing functioning procedural effects |
| Audio | Usable now | Existing attack impact, spell cast, battle music and result cues; browser audio acceptance pending |
| Dedicated direction/pose set | Missing | Produce one character's small pose set only after observing this build at gameplay scale |
| Cinematic skill movies | Deliberately unused | Real-time effects stay attached to actual battlefield targets |

## Presentation contract

BattleManager awaits anticipation and projectile travel before calling the authoritative resolver. The resolver applies outcomes synchronously and emits contact feedback. Player input is gated during lead-in and recovery. AoE uses one lead-in, then resolves its existing target set. No additional damage calculation lives in presentation. Sprite movement leaves the unit root, shadow and health bar anchored.

The original VFX sheets and character source art were not edited. New visuals are procedural code in VFXManager, with the same provenance as the implementation.

## Follow-up based on observed constraints

The managed browser cannot run this export because it reports missing WebGL2 and a secure context. Do not generate a large pose batch before a supported-browser playthrough establishes actual silhouette, timing and layering problems. First evaluate a melee strike, ranged shot, fire spell, area spell, Cure and Protect in the deployed build. Then improve one character's attack/cast poses and movement cycle where the result visibly needs it.

Remaining scope: this is the existing descent with a combat presentation pass, not a newly authored two-battle campaign. A direct encounter retry, explicit short-demo finale, comprehensive unsupported-ability filtering, reduced-motion controls and dedicated pose animation are not completed by this pass.

## Next production brief: Kael melee poses

Reference: existing `assets/characters/character-vanguard-idle-v01.png`. Preserve original armor, sword, palette, light direction and three-quarter view. Target approximately 80 pixels on the battlefield. Audit current Unit anchoring before fixing a common transparent canvas and normalized foot anchor; use the same sprite scale across poses, not per-texture bounding-box scaling. Leave margins for the weapon arc.

Produce only anticipation and contact poses first; reuse idle for recovery. Inspect both against the existing idle at gameplay size, reject anatomy/equipment drift, then integrate through the existing action lifecycle with cancellation restoring idle and position. Do not produce a full sprite sheet or roster before this example passes visual review. Record generator, reference, source files, import paths and anchor metadata. Generated poses are not yet produced.

Use reusable real-time slash, impact and reaction effects; no skill movies or renderer replacement. After the melee example, prioritize one caster pose family and an intact/burning/spent terrain kit for mechanics already implemented.

Design reference: https://store.steampowered.com/app/1290750/Crawl_Tactics/ . Its official description emphasizes height, facing and terrain/trap interactions. Borrow the goal of understandable environmental consequences, preserving ProjectTactic's original art and setting. No Crawl Tactics gameplay was playtested during this pass, and its internal asset pipeline is unknown.


## 2026-10-23: Kael integrated melee pose pass

Two built-in image_gen outputs now imported and used by real slash actions:
- `godot/assets/characters/character-vanguard-anticipation-v01.png`
- `godot/assets/characters/character-vanguard-contact-v01.png`
- Provenance/anchors: `godot/assets/characters/kael-melee-poses-v01.json`.

Original idle remains recovery and fallback. Both generated sources use 1280x1280 transparent canvases. Explicit foot offsets and measured body-height calibration map each to 76 local pixels before existing Unit HP scaling. Sword extents do not determine scale. The generator did not honor the initially requested 1024px anticipation canvas, so metadata uses the actual output. No raster processing or replacement of existing artwork was performed.

Anticipation prompt: Create one game sprite pose based faithfully on this reference character Kael. Original 2.5D painted tactical RPG sprite, same brown-haired man, bronze steel layered armor, dark brown cape, long steel sword, three-quarter view facing screen right, light from upper left. Change ONLY the arms and upper torso into a sword attack ANTICIPATION: sword raised back above his right shoulder ready to slash towards screen right. Preserve boots stance, grounded feet, proportions, armor and face. No shield. One isolated full-body character, genuine transparent background, no floor/shadow/VFX/text. Square 1024x1024 canvas. Foot midpoint at (512,896), top of head around y=256, body height 640 pixels; sword stays inside 64px canvas margin. Designed to render with body height about 76 pixels. Restrained detail, crisp readable silhouette, no photorealistic redesign. This is one anticipation pose, not a sprite sheet.

Contact prompt: Create a single CONTACT pose of Kael for a tactical RPG sword attack. Image 1 is the exact character and pose framing to preserve, image 2 original character identity. Change ONLY arms and sword from raised anticipation to a completed downward diagonal slash towards screen right: hands at waist height, steel sword extends right and slightly downward, fully visible within canvas. Keep legs, boots, head height, cape, bronze steel armor, brown hair, scale and lighting identical to image 1. Keep full body visible with margin on all sides. 1280x1280 transparent canvas, midpoint between grounded soles around (656,1155), head top around (660,225). Same painted three-quarter view facing screen right. No shadow, no effects, no text, no background. Intended body on-screen height 76px. Do not add armor or change costume. One pose only, not a sprite sheet.

Observed: original and generated art inspected; static browser preview at intended display size showed readable raised-sword silhouette and comparable head/body height and palette. The poses have a wider stance than idle and do not constitute a seamless animation cycle. No new directional variants or mirroring. Actual battle timing, layering and stance transitions still need browser/player review. Real-scene tests verify that poses run through the existing action path and clean up correctly; they do not establish visual quality.

## Live 3D comparison prototype

`godot/scripts/presentation/Humanoid3D.gd` creates original rigid low-poly mesh parts attached to one 11-joint Skeleton3D definition. Kael: bronze plate, broad shoulders, dark cape. Zane: teal armor, narrower shoulders, pale headband. Both use exactly the same animation sampler and wrist weapon socket. Idle, walking, anticipation, contact, recovery, hit and defeat are driven by real Unit/action events.

This is a geometry/material blockout, not the final painted character style or a production skinned mesh. No image generation, downloaded models, paid assets, or new licenses are involved. BoxMesh parts are rigid bone attachments; there is no smooth skin deformation, IK, cloth simulation or animation retargeting importer. These limitations are deliberate for the reuse experiment.

Each character uses a transparent 192x192 SubViewport, isolated World3D, orthographic Camera3D, matte materials and fixed lighting. Its texture is composited on the existing isometric 2D board at the projected foot origin. Only Kael and Zane in explicitly selected 3D practice sessions use it. Other units, normal practice and ordinary runs keep sprites. Practice retry retains the choice in memory; canonical saves do not gain presentation fields.

Godot API reference: https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html . The prototype uses BoneAttachment3D to bind rigid parts to skeleton bones.

Browser performance and visual quality remain unverified. Two per-character viewports are a bounded prototype, not an approved architecture for a full roster. Do not expand to every unit before measuring render cost and assessing silhouette, foot sliding, direction and overlap in supported-browser gameplay.

## Casting and screenshot-driven presentation pass

Shared 3D cast anticipation, release and recovery now use the free-hand bone. Hand projection traverses Skeleton3D space, camera viewport pixels, output Sprite2D transform and the battle canvas before VFX placement. Existing Void Pulse on Zane is the verified loadout example; existing impact effects and combat formulas are unchanged. Casting travels from the hand instead of translating the whole character. Invalid presentation tickets abort before release; cancellation during travel removes the orb. No generated or replaced raster assets.

User screenshot `image.png` received 2026-10-23 showed a sprite battle titled Mirefen Border: a low/right battlefield, a large grey background, duplicate turn-order panels and a dense sidebar. It establishes those visible issues, not the underlying source revision or 3D rendering quality. Code inspection found fixed camera fit dimensions, automatic movement following and WASD/combat-hotkey overlap. This pass fits the board to viewport/HUD bounds, keeps framing stable during turns and movement, limits keyboard panning to arrows, and makes F refit. Dark slate background, teal/brass command styling, teal HP fill, one timeline and scrollable sidebar improve hierarchy. Loadout strip moves to the bottom edge.

Next visual direction: original miniature-like fantasy characters with distinct job silhouettes, restrained materials, and terrain with readable top surfaces and height edges. The geometric 3D rigs remain blockouts. Choose one terrain family and two contrasting character silhouettes for the next art pass; do not generate a roster or claim this UI correction is a complete asset revamp.

## 2026-10-23: repository-wide terrain and UI audit

Current census: `asset-audit.csv`, reproducible with `python tools/audit_assets.py`. 447 tracked media/font files: 210 have literal runtime/data references, 79 need dynamic-reference review, 42 are preview/reference files, and 116 belong to the legacy web/source kit. 99 SHA-256 duplicate groups were found. A reference does not prove an asset is visible; absence of a literal reference does not prove safe deletion. No blanket deletion performed. The old opening table's “usable now” means technically loadable, not visual approval.

All 80 fetched remote refs were scanned for asset paths. `historical-asset-paths.txt` records 399 historical image paths absent from this branch, including the two root references now archived. This is a path inventory, not visual inspection of every historical asset version. GitHub main remains 0415b6d; open art/HUD PR stack is separate from these local delivery branches.

| Asset family | Disposition | Action / evidence |
| --- | --- | --- |
| Forgotten Field 8 generated floors | Reuse now, gameplay visuals pending | Inspected grass PNG; 96x64 authored diamonds. Default procedural maps previously skipped this family. It is now the preferred fallback for known terrain IDs on maps without a theme. |
| Legacy square UI terrain | Usable fallback after adjustment | Inspected grass square. Now mapped into diamond polygons instead of spilling into square cells. |
| Authored tile skirts and procedural cliff faces | Adjusted | Generated top center is canvas y24, not y32. Shift +8 aligns top to grid; exposed faces now reach neighboring height or board base rather than fixed 16px. |
| Dark-stone panel and command icons | Reused | Nine-patch rail, icon command buttons, active character art, existing display font. No new images. |
| Generated demo preview sheet | Reference only | Excluded from Web export, source retained. |
| Root `_ante.png`, `_roster.png` | Reference only | Moved to `preview/reference-archive/`, no runtime references found. |
| Duplicated generated/legacy/UI files | Retain pending caller migration | Exact duplicates recorded; some are fallback contracts. No filesystem deduplication assumed safe. |
| Historical Ashvale 3D kit | Recovery candidate, not current runtime | 22 OBJ terrain/prop meshes plus MTL/manifest exist on `origin/feature/ashvale-3d-terrain-kit` at `342fbd8dd5157325d1a2257c621b14c692255f21`. |
| Historical Ashvale 3D backdrop | Needs adaptation before use | `origin/feature/ashvale-playable-3d-battle` at `b1c2ff8240fe572e891a997404c719729c2103cc` contains `godot/scripts/battle/Ashvale3DBackdrop.gd`. Uses real meshes rendered once into a SubViewport; restricted to Ashvale, skips headless, lacks terrain-mutation rebuilding. Do not blindly cherry-pick the old branch. |
| Historical sample teapot | Not game art | Architecture sample; exclude from terrain recovery scope. |

User feedback: current demo does not look 3D and UI remains bland. Current board is still isometric 2D; this pass does not claim a live 3D board. Existing Kael/Zane rigs are opt-in only. Next priority is to adapt the recovered 3D terrain kit into one practice encounter with current authoritative map state, mutation refresh, projection and fallback checks. Preserve all existing combat, casting and saves.

## Recovered 3D terrain practice integration

Recovered the existing 22 OBJ files, shared MTL palette, manifest and README from `342fbd8dd5157325d1a2257c621b14c692255f21`; no new art was generated. Adapted historical `Ashvale3DBackdrop.gd` from `b1c2ff8240fe572e891a997404c719729c2103cc` into `godot/scripts/presentation/PracticeTerrain3D.gd`. No historical gameplay code or full branch merge.

Practice offers an independent Terrain 2D/3D toggle, guarded by the existing idle-player-turn rule. The 3D Rig Prototype entry initially enables both terrain and character rigs; later terrain choice persists in the in-memory practice session through retry. Ordinary battles remain 2D. Supported existing terrain IDs map to recovered meshes. Unsupported terrain or unavailable required meshes restores the whole legacy board rather than misleading the player with substituted grass.

One transparent 1536x1024 SubViewport renders on enable or terrain redraw. TacticalGrid remains authoritative. The 30-degree orthographic projection maps 2m tiles to 96x48 pixels. Logical height_step controls vertical mesh scale; actual mesh AABB tops align to the logical surface. Raised columns stretch to the common board base. Tile targeting and units remain existing 2D canvas nodes. This is a mesh-rendered terrain layer, not a new gameplay renderer or orbiting camera. Props do not add collisions.

Terrain redraws rebuild from current grid data, including ignition, and request a viewport update. Legacy tiles, debug height labels and props hide only while the mesh layer is valid; highlights/units remain visible. Disable immediately frees the viewport subtree and restores legacy presentation. Headless builds construct/test this path instead of bypassing it.

Visual acceptance, lighting, prop/unit overlap and browser cost remain pending. Solid-color materials and rigid models are recovered blockout art, not painted final assets. The old kit README's showcase/source-art references describe historical tooling, not scenes restored in this pass.

## High-resolution sampling
Standard/High practice setting reuses all existing meshes and textures. High doubles viewport dimensions and inversely scales output; no raster regeneration or new assets. Rendered world/hand anchors remain unchanged in automated checks. 4K UI layout checks passed; browser visual quality and performance remain pending.

## Encounter art and flow refinement

Original procedural humanoid meshes now use eight-sided beveled prisms with flat outward normals, layered tabard/waist armor, Kael shield and a hooded Hollow caster with focus staff. Kael, Zane and the existing void_cultist archetype share the same skeleton and animation sampler. Enemy instance IDs are resolved through archetype metadata; no new enemy stats or combat abilities. Other units retain existing art. No raster generation or downloaded model assets.

BattleLighting.gd supplies the same warm key, cool fill and ambient parameters to terrain and humanoid viewports. This is shared lighting configuration, not a single shared shadow/occlusion world. Existing melee/casting/contact effects remain authoritative and integrated. Art remains procedural rigid geometry, not smooth-skinned production character models.

Practice settings are collapsed under View & quality settings; command tooltips describe action order and targeting, active units show job names, and entry is named Play 3D Encounter / Practice. Victory offers up to three existing unlocked job paths for Kael and one rematch with that path. Existing prerequisites and canonical set_current_job/serializer are reused. The choice directs future JP growth, does not grant free abilities, and can occur once per practice session. Retry preserves the new checkpoint; exit restores the saved descent and narrative state.

Verification: initial mesh-normal assertion caught inward winding; corrected before final export. Outward front normal and unit AABB checks pass. No visual capture or appearance acceptance was available. Blender and a graphical display were unavailable locally; no claim of hand-modeled or Blender-authored assets. Desktop templates recovered from the existing official template archive permit Windows and Linux x86_64 export.

## Appointed vector UI kit

Six original code-authored SVG assets in assets/ui/appointed: Move chevron/path, Attack blade, Ability resonance diamond, Wait hourglass, geometric crest and brass-inset nine-patch rail. Authored at 64px command icons, 96px crest and 256px frame; used at 24px icons and 42px crest with existing HUD sizing. SVG sources are editable vectors; Godot imports them as textures. No external artwork or image generation. AppointedTheme.gd centralizes ink/ivory/brass/teal surfaces and distinct normal, hover, pressed, focus and disabled states. Applied to battle commands, settings and results buttons. Crest/frame/icons are integrated in actual battle UI. Existing gameplay and narrative unchanged.

First integration exposed PNG-only AssetRegistry loading for SVG paths. New vector assets now use native Godot resource imports. Final integration run: 415 checks passed with existing shutdown warning only; 30 HUD layout assertions passed. Static preview source: preview/appointed-ui-kit.svg. Static rendering unavailable (CairoSVG/rsvg-convert missing); no static image or in-game visual acceptance claimed. Desktop/Web exports succeeded. This is a coherent initial UI kit, not a claim of state-of-the-art visual quality without observation.
