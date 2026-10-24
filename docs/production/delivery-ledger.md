# Current delivery ledger

## 2026-10-24: Appointed UI kit (current)

Reconciled 4ecffd5 and private hosted source 550605e869ea314495be6f240a8a07f6c2d18d7a. User authorized original on-brand UI creation and integration independently of pending gameplay observations. Source branch feature/appointed-ui-kit; implementation 5d489e0be26da215a651516d7a9842207c1faceb. Unrelated files preserved; no public push, PR or merge needed.

Six new original SVG assets: four command glyphs, crest and nine-patch rail. Shared AppointedTheme centralizes interaction states, surfaces, borders, text and health styling. Integrated into real battle command rail, practice settings and results buttons. Story, combat, saves, progression and character art unchanged. See inventory for provenance and source dimensions.

Checks: 415 real-scene integration checks and 30 HUD layout assertions passed; Web export/package validation passed; Windows/Linux exports succeeded and packages refreshed in build/desktop. First run exposed PNG-only asset loading, corrected to native Godot SVG imports. Existing ObjectDB/two resources warning persists. No new browser/native graphical observation, performance measurement or human acceptance. Static SVG raster preview also blocked by unavailable local rendering dependencies. Preview source retained; do not present it as a gameplay capture.

Private deployment succeeded:
- Game commit: 5d489e0be26da215a651516d7a9842207c1faceb
- Hosted source: b7fc0fdbbc209d03546fe9899c46606dd6d38e09
- Export: build/ui
- Site: appgprj_6adba102db888191a91592bf85f1a728
- Version: appgprj_6adba102db888191a91592bf85f1a728~appgver_98413226b160819188fa77ce26e649bf
- Deployment: appgdep_6adc4333ff688191b410d621c665141c
- URL: https://appointed-tactics.zzziah.chatgpt.site/

Next bounded milestone: assess this kit in actual gameplay at 1366x768 and 4K, including command discovery, keyboard focus, disabled states and training-choice clarity. Repair the highest-impact observed usability issue. Do not label the initial kit visually accepted or add more ornamental assets without seeing how these work. If graphical evidence stays unavailable, perform independent focused interaction/focus checks without inventing visual findings.

## 2026-10-23: encounter art, training choice and desktop packages (prior)

Reconciled local f1f94de and hosted 408e66a4fdb46cb1067b8f4f0f52d7b283bacdc6. Owner-private access confirmed. User authorizes necessary reviewed merges, while new public source publication remains restricted. No merge was needed for this local implementation; no public push or PR. Unrelated files preserved.

Player-visible changes:
- Kael/Zane shared rigs use original faceted armor, layered equipment and Kael shield. Existing Hollow caster uses hood, focus staff and archetype-based appearance despite unique enemy instance IDs. Other enemies/party members retain sprites.
- Terrain and humanoids use shared warm/cool/ambient lighting configuration, still in separate viewports. No single-world occlusion migration or new combat calculations.
- View/quality tools collapse behind a settings button. Active-unit UI shows job; commands have action-order/targeting guidance. Entry renamed Play 3D Encounter / Practice.
- Practice victory offers up to three unlocked Kael job paths, then rematch at restored resources. This uses canonical job prerequisites/state machinery and directs future JP growth; no free abilities. One choice per practice session; retries preserve it; exit restores original narrative/descent. Existing attack/cast sequences and impacts remain integrated.

Implementation: feature/encounter-art-and-flow, 1b87a30dedc2213ea8f98bb451d1972551161650.

Verification:
- Final real-scene suite: 415 checks, zero failures. Includes enemy archetype mapping, invalid/duplicate training choice, retry preservation, one-choice limit and baseline restoration, plus existing combat/casting/save tests.
- Focused procedural mesh test caught inward triangle winding; repaired and verified outward front normal and bounds before final export.
- 30 HUD layout assertions passed, including 3840x2160. Web export/package checks passed.
- Windows and Linux x86_64 exports succeeded with embedded packs. ZIP CRC checks passed. Linux binary headless startup passed; Windows runtime not tested. Both unsigned development builds, no installer or macOS build.
- Headless integration reports ObjectDB/two resource warnings; Linux startup reports one resource. Previous audio diagnosis remains open.
- No actual browser/native graphical observations, gameplay capture, measured performance or human acceptance. Blender/graphical display unavailable locally; existing managed-browser limitation not retried. Do not label this visually finished based on automated checks.

Private Web publication succeeded:
- Export: build/encounter
- Game commit: 1b87a30dedc2213ea8f98bb451d1972551161650
- Hosted source: 550605e869ea314495be6f240a8a07f6c2d18d7a
- Site: appgprj_6adba102db888191a91592bf85f1a728
- Version: appgprj_6adba102db888191a91592bf85f1a728~appgver_97c790b00dd081919090f0fd058bd88d
- Deployment: appgdep_6adc2560910c8191a09f76998858b84b
- URL: https://appointed-tactics.zzziah.chatgpt.site/

Desktop artifacts from the same implementation: build/desktop/Appointed-Windows.zip (SHA256 404c6f2e8d2f5ce65c6ddd94fa66b8ba7b2e5dfd22e559b56dac943e125304c7), Appointed-Linux.zip (SHA256 c7b23c9bfcafcfe6c874a2e15015bece8a325d42da2a9867cd8a503fd2583501). Each includes build-info.json and controls/readme.

Next milestone: native or supported-browser acceptance of this complete practice loop. Inspect silhouettes, ground contrast, command discoverability, melee/cast readability and whether the training/rematch choice is understandable. Repair the highest-impact reproduced issue before expanding more character art. Native packages now provide an alternative to the managed-browser blocker. If observation is unavailable, pursue an independent bounded audio-shutdown investigation, not speculative visual changes. Preserve original story and combat rules.

## 2026-10-23: selectable high-resolution practice (prior)

Source branch feature/high-resolution-presentation; implementation 969691f0958ab0e51da3634bfd1a1cb08b56be71, based on f0e81af. Added Standard/High button to practice with existing idle-turn guard. Standard stays default. High doubles terrain viewport dimensions to 3072x2048 and character dimensions to 384x384. Inverse sprite scaling preserves footprint and hand projection. No new viewports on quality changes. Preference is in practice_session, reused on terrain/character recreation and retry; canonical saves unchanged. Four times viewport pixel count in High; no measured browser cost claimed.

Verification: 407 integration checks passed; 30 HUD assertions including 3840x2160 passed; Web export, package integrity and whitespace checks passed. First test attempt caught an inferred-type parse error, corrected before successful run. Two resources-in-use/ObjectDB warning remains, with prior audio diagnosis unchanged. No browser observations or 4K visual acceptance; known blocked browser not retried.

GitHub connector listed open PR stack. Local origin/feature/ashvale-battle-hud-clearance is already an ancestor of this build. No merge required for implementation. User requested necessary merges but also retained explicit no-merge/public-source prohibition in same message. No public push, PR or merge performed pending clarification; unrelated files preserved.

Private deployment succeeded:
- Game: 969691f0958ab0e51da3634bfd1a1cb08b56be71
- Export: build/high
- Hosted source: 408e66a4fdb46cb1067b8f4f0f52d7b283bacdc6
- Site: appgprj_6adba102db888191a91592bf85f1a728
- Version: appgprj_6adba102db888191a91592bf85f1a728~appgver_9ce170e851888191a29c1cf62bcdb682
- Deployment: appgdep_6adc1f5c5eb88191927eefc8e58ca4a9
- URL: https://appointed-tactics.zzziah.chatgpt.site/

Try 3D Rig Prototype / Practice, then Quality: Standard → High on an idle player turn. Compare the same camera/action and switch back if slow. Next milestone: verify High in supported-browser gameplay at 4K, including legibility, spell attachment alignment, toggling/retry and measured frame intervals. Keep story and reward rules intact. If observation remains unavailable, complete independent tests for High preference through explicit retry/recreation and investigate audio shutdown separately; do not manufacture visual defects.

## 2026-10-23: terrain cleanup isolation and 4K scope (prior)

Reconciled local HEAD da50025 and implementation f5b59dc. No new visual observations or changed managed-browser capabilities; browser not retried. No deployed-state revalidation this pass. User prioritizes preserving story, quality of life, satisfying feedback and meaningful reward loops, and requests 4K presentation.

Added tests/test_terrain_cleanup.gd: ten real terrain enable/redraw/disable cycles, immediate disposal assertions and scene teardown. Godot 4.6.2 headless verbose run passed without resource warnings. Full existing integration suite rerun with verbose diagnostics: 383 checks passed; shutdown identified AudioStreamWAV/AudioStreamPlaybackWAV instances and attack-impact.wav/victory-chime.wav. This isolates the observed resources to audio in this run, not terrain; root cause and gameplay impact remain unproven. No speculative production fix.

Branch diagnostics/terrain-cleanup-and-4k. Test/documentation-only changes; no export or new deployment because production inputs are unchanged. Last recorded private deployment remains appgdep_6adbf6a8a72081918a8abf79c785f6ce from hosted source e3f24e77e57a894e2dba7d54dd1fa12eaf93fac9. Public push restriction respected; no PR or merge. Existing untracked files preserved.

4K inspection: canvas_items stretch uses a 1920x1080 logical baseline. Terrain viewport is fixed 1536x1024; character viewports are 192x192. Increasing window resolution alone does not increase these render textures. Next milestone: explicit Standard/High render-quality choice with resolution-aware viewport sampling, inverse output scaling and stable world projection, plus 3840x2160 UI layout checks. Preserve a lower-cost default until browser performance is measured. Do not upscale all raster assets or modify reward rates under the label of visual polish. Reward-loop improvements should emphasize clear goals, brisk feedback, meaningful build choices and transparent progress.

## 2026-10-23: recovered mesh terrain in practice (prior)

Reconciled game HEAD 425439f, historical kit 342fbd8dd5157325d1a2257c621b14c692255f21, backdrop b1c2ff8240fe572e891a997404c719729c2103cc and hosted source b03e91cc269047fa3f09cac0611d47caf7cdee27. Existing untracked files preserved. No full historical branch merge or combat code replacement.

Player outcome: 3D Rig Prototype / Practice now initially enables recovered mesh terrain as well as the two existing character rigs. Practice has an independent Terrain 2D/3D toggle, available only on idle player turns. Terrain preference survives practice retry in memory. Ordinary battles retain 2D terrain. Existing sprite/character comparison stays independent.

Implementation: recovered 22 OBJ meshes and shared materials, adapted historical backdrop to PracticeTerrain3D.gd. One transparent 1536x1024 viewport updates on enable and terrain redraw. Actual mesh tops align to logical surfaces; raised columns extend to board base. Grid coordinates, highlights, picking, units, pathfinding, combat, casting and saves remain authoritative in existing systems. Unsupported terrain or missing required mesh restores the full 2D board. Disable frees the viewport immediately. Headless structural tests exercise the same construction path. This remains a composite presentation, not a freely rotating 3D gameplay world; unit/prop occlusion and lighting require visual review.

Source: feature/recovered-3d-terrain, implementation f5b59dc350cb55054ed6a36934a5f18262bb4bf0. No public push, PR, main commit or merge.

Verification:
- Final real-scene integration: 383 checks, zero failures. Includes all tile-center projections, actual raised mesh top projection, ignition rebuild, missing mesh lookup, unsupported-terrain fallback, repeated toggles, retry and existing combat/save/casting regressions.
- Asset manifest: 94 assertions passed. HUD layout: 24 assertions passed.
- Release Web export and package integrity passed (WASM, PCK, lengths, subpath/native fetch). Diff whitespace check passed.
- Final headless shutdown: ObjectDB warning and one resource still in use. Earlier run had two. Historical resource issue remains unresolved; no leak fix claimed.
- Browser observations, performance measurements and human playtest: none for this build. Prior managed browser not retried without changed-capability evidence. No capture or visual acceptance claimed.

Private publication succeeded with unchanged owner-private audience:
- Game commit: f5b59dc350cb55054ed6a36934a5f18262bb4bf0.
- Export: build/terrain3d.
- Hosted source: e3f24e77e57a894e2dba7d54dd1fa12eaf93fac9.
- Site: appgprj_6adba102db888191a91592bf85f1a728.
- Version: appgprj_6adba102db888191a91592bf85f1a728~appgver_d837a68230ec819196b84d9052450d60.
- Deployment: appgdep_6adbf6a8a72081918a8abf79c785f6ce, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site/

Next bounded milestone: assess the newly integrated terrain in supported-browser gameplay before expanding art. Compare 2D/3D terrain on the same idle turn, raised-tile footsteps/targeting, spell mutation, retry, lighting and prop/unit overlap. Repair one observed defect. If visual observation remains unavailable, independently isolate the persistent shutdown resource warning with a focused scene enable/disable harness; do not invent visual defects or rerun a known-blocked browser. Keep the ledger as the single current plan.

## 2026-10-23: terrain depth, asset audit and UI reuse

User feedback: demo does not look 3D, ground does not read as 3D, and UI is bland. This is human feedback, not a measured browser capture. Current rendering remains an isometric 2D board with opt-in 3D characters. This pass does not claim a live 3D ground renderer.

Reconciled starting game HEAD ead27ce and private hosted source d9104b615b40f3812ac96d631be12c9788f90bb2. Git fetch succeeded; 80 remote refs inventoried; main remains 0415b6d. Existing open art/HUD PRs were inspected, not merged. Owner-private access confirmed (owner, custom, one allowed user). Initial hosted checkout opening failed after workspace maintenance removed the directory; recovered it using the supported helper in an empty directory. No publication rejection bypass.

Implemented:
- Default maps now reuse generated Forgotten Field terrain rather than only square legacy textures. Square fallbacks are diamond-clipped.
- Authored 96x64 top diamond aligns to the logical grid with +8px center correction. Cliff faces extend to neighbor elevation or board datum instead of a fixed 16px.
- Reused dark-stone nine-patch rail, command icons, active-unit art and display typography. Sidebar scrolling retained.
- Repository asset census: 447 media/font files, 99 duplicate groups. Classification and reference evidence in asset-audit.csv; generator in tools/audit_assets.py. Unresolved dynamic references retained. Two root reference images archived; preview sheet excluded from Web export. Validator regenerated loose previews locally, left untracked.
- Full remote-ref scan located 399 historical image paths and 23 model paths (22 Ashvale models plus unrelated sample teapot). Actual 3D kit and backdrop survive in historical branches, absent from current implementation. See inventory for exact provenance and limitations.

Implementation branch: `feature/terrain-depth-and-asset-audit`.
Game commit: `a12e9ae46fbec52fd0a9f9d49fb1caf1fa1a92ef`.
No public GitHub push, new PR, main commit or merge. Unrelated untracked files retained.

Verification:
- 198 integration checks passed, zero failures. New coverage: default-map art selection, tile alignment/clipping, cliff depth, unchanged logical terrain and picking.
- 94 asset-manifest assertions, 24 HUD layout assertions and Forgotten Field art validator passed.
- Release Web export, package integrity (WASM/PCK/byte lengths/subpath/native fetch), and diff whitespace checks passed.
- ObjectDB/two resources-in-use shutdown warning present; unresolved, not a new leak fix.
- Browser gameplay/visual acceptance/performance: not measured. Managed browser not retried without changed capability evidence. No gameplay capture. Automated checks do not establish art quality.

Private publication succeeded:
- Export: `build/terrain`.
- Hosted source: `b03e91cc269047fa3f09cac0611d47caf7cdee27`.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_2f0bc8582c188191a241d7112d30b599`.
- Deployment: `appgdep_6adbeae1320c8191964289e9474a424a`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site

Try Practice Battle, inspect raised tiles and target outlines, select commands and scroll the rail. Use 3D Rig Prototype / Practice for Kael/Zane; ground remains 2.5D in both modes. Arrows pan, F refits.

Next bounded milestone: adapt recovered Ashvale mesh kit and Ashvale3DBackdrop to one opt-in practice encounter. Inspect historical source b1c2ff8240fe572e891a997404c719729c2103cc and kit 342fbd8dd5157325d1a2257c621b14c692255f21. Keep TacticalGrid authoritative. Fix historical limitations (Ashvale-only activation, headless bypass for structural tests, missing mutation rebuild) before enabling. Verify projection against real logical centers and height steps, fallback and scene cleanup. No full old-branch merge, combat rewrite, roster expansion or invented visual acceptance.

## 2026-10-23: shared casting and battlefield framing

Player outcome: rig users share casting anticipation, release and recovery. Zane's existing Void Pulse emits the existing orb from the projected free-hand attachment. Combat and MP remain authoritative; cancellation checks suppress stale contact. Sprite fallback, melee, practice isolation and saves remain intact.

Supplied screenshot evidence: a sprite battle has a large grey backdrop, board low/right, dense right sidebar, duplicate turn order and a floating loadout panel. Screenshot revision is unknown and it does not show the 3D prototype. Code inspection found fixed-size framing, movement camera follow and WASD/combat shortcut collisions. This pass fits the board to viewport/HUD space, removes movement auto-follow and duplicate timeline construction, moves loadout to the bottom margin, adds a scrollable themed sidebar, and changes the backdrop to dark slate. Arrows pan, F refits; A/S/W retain combat controls. No new raster art or roster expansion.

Source branch: `feature/casting-and-battle-framing`. Implementation: `610398f6479379b06f91391f740296590f9bd280`, based on `aaa6536`. Source remains local; no public GitHub push, PR, main commit or merge. Unrelated untracked files preserved.

Evidence:
- Automatically tested: 188 real-scene integration checks, zero failures; 24 HUD layout assertions passed. Covers existing Void Pulse gameplay, hand projection after translation, MP spending, recovery, cancellation during travel and camera-fit geometry at 1366x768 and 1920x1080. Existing combat/practice/save checks remain green. `git diff --check` passed.
- Final run had no runtime errors or shutdown resource warnings. Earlier runs retained ObjectDB/two-resource warnings; no general leak fix is claimed.
- Release Web export and package integrity passed: WASM validity, PCK header, reconstructed byte lengths, subpath and native fetch.
- Browser observed: supplied screenshot only, before this update and without exact revision. New layout, motion, layering and visual quality remain unverified. No changed capability evidence justified repeating the blocked managed browser.
- Human playtest and actual browser performance: not measured. No gameplay capture.

Private publication succeeded; owner-private audience unchanged:
- Game commit: `610398f6479379b06f91391f740296590f9bd280`.
- Export: `build/casting`; hosted `dist/build-info.json` identifies game source.
- Hosted source: `d9104b615b40f3812ac96d631be12c9788f90bb2`.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Saved version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_b9457fdc56148191bb8bb57e156343e4`.
- Deployment: `appgdep_6adbe18ed120819181c956324fac4611`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site

Try 3D Rig Prototype / Practice, select Zane on his turn, select Void Pulse and a legal target; compare sprite mode during an idle player turn. Check repeat casts, cancel/next command, camera framing and practice retry. Visual review is pending, not a claim of acceptance.

Next bounded milestone: one coherent terrain family in the existing practice battlefield. Audit top-surface textures, cliff edges, tile clipping and target overlay contrast first; reuse usable assets. Improve terrain surface/height readability with restrained palette and detail, preserving walkability/elevation rules and new HUD framing. Prove one integrated family before variants. Character models remain rigid geometric blockouts. Continue independent implementation without making screenshots mandatory; keep actual gameplay acceptance separate.

## 2026-10-23: in-battle sprite/3D comparison

User clarified that independent building should continue without screenshots. The earlier screenshot dependency still limits visual acceptance, but no longer blocks bounded implementation work.

Player outcome: both practice modes now have a comparison panel. During an idle player turn, switch Kael and Zane between sprites and live 3D without changing HP, resources, tiles or saves. Inactive rigs/viewports detach and free. Re-enabling 3D retains unit facing. Switching is blocked during action resolution and enemy turns. Current in-memory mode survives practice retry; ordinary runs do not show the panel.

Timing: rolling last 180 wall-clock frame intervals, mean and worst, with manual reset. One-second warmup after switch/reset/focus changes. Slow frames retained; these are frame cadence readings, not GPU timing or controlled benchmark results. No performance numbers from a browser are claimed.

Source: `feature/practice-visual-comparison`, implementation `eb11c50e4f756e03fc80b572c69cb6319246ba98`, based on `2de5f13`. No public GitHub push, PR or merge. Existing rejection respected. Unrelated untracked files retained.

Verification: 178 real-scene checks, zero failures, no runtime script errors; repeated mode switching, exact state preservation, facing restoration, active-action exclusion, bounded timing window and reset, plus existing combat/practice/save regressions. Two resources-in-use/ObjectDB warnings remain at headless shutdown. Release Web export and package checks passed. Browser rendering/UI layout, visual quality and performance remain unverified; no new evidence justified repeating the blocked managed browser. No new character art.

Hosting checkout was absent after workspace maintenance. Recovered the existing private Site source through the supported helper before editing. Publication succeeded with unchanged owner-private audience:
- Game commit: `eb11c50e4f756e03fc80b572c69cb6319246ba98`.
- Export: `build/comparison`.
- Hosted source: `336558290cc657c6cff37003f82a51960ff3a9b5`.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_564b1740c0f48191b9fe06583e5a97ff`.
- Deployment: `appgdep_6adbded27e288191a309a0ae93c0dbb2`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site

Next bounded build milestone: add a shared casting anticipation/release/recovery sequence for the existing rig users and connect an existing implemented spell's visual origin to a hand attachment. Current non-slash presentation still moves the entire visual and emits an orb from a generic body origin. Reuse existing spell outcomes and effects; no new rules or roster. Verify cancellation, MP/outcome exactly-once semantics, and sprite fallback. Visual acceptance remains a separate pending task, not a mandatory screenshot gate for independent implementation.

## Prior milestones

## 2026-10-23: 3D visual acceptance reconciliation

Reconciled local HEAD `5a31df6`, implementation `164b4a1163099e36ffa89d64048d98d25013b568`, and hosted checkout `32c7f069ed8883740a290ea4cc2d5c0ff924b3ab`. Sites get_site_version confirmed version 6, matching hosted source and deployment `appgdep_6adbc9365ab48191b5be6269cd6d63a1`. Read existing test log: 157 checks, zero failures, two shutdown resources-in-use warnings. Results were not rerun or represented as new verification.

No supported-browser gameplay evidence or human observations were supplied. No evidence of changed WebGL2/Secure Context conditions justified retrying the previously blocked managed environment. No rendering defect reproduced, no performance measurement, no screenshots/capture, no visual repair or new deployment in this pass. Unrelated untracked files preserved. Documentation-only branch: `docs/3d-acceptance-evidence`.

Dependency to unblock acceptance: a supported-browser playthrough or player recording of both practice modes. Record browser/version, viewport size, whether both characters appear, one move and melee action per character, any disappearance/foot sliding/wrong-facing/overlap issue, and retry outcome. A recording can establish visual findings but does not by itself measure engine frame time. Actual browser performance measurement remains separate.

Decision: do not refine painted materials or expand the roster until rendering and motion are observed. Reproduce the first reported defect, then make a bounded repair on a new feature branch. If no defect is observed, use measured performance and player feedback to decide whether to refine one model. Do not keep issuing speculative implementation passes around this dependency.

## 2026-10-23: shared live 3D humanoid comparison

Player entry: Start screen **3D Rig Prototype / Practice**. Kael and Zane use separate appearances on one procedural Skeleton3D and shared motion sampler. Normal Practice Battle and ordinary runs retain sprites. Prototype retry retains its in-memory selection; returning to Hearth restores the saved descent. No canonical save fields added.

Implementation: `164b4a1163099e36ffa89d64048d98d25013b568`, branch `prototype/shared-3d-humanoids`, based on `9c85819`. No main commit, public GitHub push, PR or merge. Prior public source approval rejection respected; unrelated untracked files preserved.

Implemented:
- Original rigid 3D armor/body parts, two palettes and shoulder/headwear variants, shared 11-joint skeleton and wrist weapon attachment.
- Idle, walk, slash anticipation/contact/recovery, hit and defeat states through existing movement and combat events.
- Contact remains behind ActionLifecycle permission; recovery/cancel returns idle. No new damage calculation.
- Two transparent 192x192 SubViewports and orthographic cameras composite onto existing 2D tiles using projected foot origins. Existing shadows, depth sorting and HUD retained.
- This is an opt-in geometric blockout. No painted textures, smooth skin weights, IK, cloth simulation, retargeting importer, or full-roster migration. See combat-asset-inventory.md for provenance and architecture limits.

Verification:
- First integration caught absolute scene-tree access before units entered tree; moved opt-in initialization to Unit._ready and reran.
- Final real-scene suite: 157 checks, 0 failures, no runtime script errors. Covers identical sampled bone motion across skins, real lifecycle contact/recovery/cancel, walk/hit/death state and cleanup, practice retry instantiation and existing save/reward/combat regressions.
- Headless shutdown still reports ObjectDB leaks and 2 resources in use. No general resource-leak fix claimed.
- Release Web export and package checks passed: WASM validity, PCK header, reconstructed byte lengths, subpath and native fetch.
- Browser observed: none for this prototype. Prior WebGL2/Secure Context blocker has no verified change, so game was not retried in that environment. Headless tests do not verify actual 3D rendering, lighting, clipping or performance.
- Human playtest/capture: pending. Foot sliding, view direction, geometric style and two-viewport cost require review before adoption.

Private publication succeeded:
- Game implementation: `164b4a1163099e36ffa89d64048d98d25013b568`.
- Export: `build/rig3d`.
- Hosted source: `32c7f069ed8883740a290ea4cc2d5c0ff924b3ab`.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_5fb30911a43481919f9f739f514344ad`.
- Deployment: `appgdep_6adbc9365ab48191b5be6269cd6d63a1`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site . Owner-private retained.

Next milestone: supported-browser comparison of 3D Rig Prototype / Practice against normal sprite Practice Battle. Verify that both models render, foot anchoring and direction make sense, contact aligns with feedback and input recovers. Measure actual browser frame time before adding more viewports. Repair one observed blocker, then choose whether to refine one model with painted materials or revise rendering integration. No speculative full-roster migration.

## Prior milestone

## 2026-10-23: Kael melee poses

Player outcome: Kael slash actions now use generated anticipation and contact poses, with fixed foot origin and original idle recovery. Other characters retain existing choreography. Contact pose is selected only after authoritative lifecycle contact permission; no combat calculation changed. Lifecycle finish/cancel restores exact original sprite texture, scale, offset and position. Generated pose animations do not change tint, camera, grid position or save data.

Source branch: `feature/kael-melee-poses`. Implementation: `1fa2e371b9aafc1dd934db9ba1563ccd091cdb02`. Based on practice retry documentation `462d9b3`. GitHub main remains `0415b6debfb3b0cb398eddff98ac3c8516553930`; new branch is local only. No public push, PR or merge; prior automatic publication rejection respected. Unrelated untracked files preserved.

Assets: two 1280px transparent PNGs, Godot imports and anchor/provenance manifest under godot/assets/characters. Existing idle unchanged. Full generation prompts and static inspection findings in combat-asset-inventory.md. Body calibration is independent of sword bounds; existing HP-based Unit scale remains. Missing/unsupported pose requests retain usable artwork.

Evidence:
- Implemented: real slash commands use both poses and restore idle through lifecycle finish/cancel.
- Automatically tested: 130 real-scene checks, zero failures, no runtime script errors. Added repeated pose/recovery, unknown pose fallback, exact transform restoration, cancellation and deleted melee target coverage. Prior combat and practice/save checks remain green. No shutdown leak/resource warning appeared in this run; this observation does not establish a general leak fix.
- Release Web export passed; package checks passed WASM validity, PCK header, byte lengths, subpath loading and native fetch passthrough.
- Browser observed: static HTML asset calibration at intended body size, showing comparable head/body height and palette and readable raised-sword silhouette. This is not game rendering.
- Browser gameplay: not reattempted because no evidence that prior WebGL2/Secure Context constraints changed. No gameplay capture, FPS or in-game layering acceptance claimed.
- Human playtested: pending. Wider attack stance vs original idle, directional consistency and timing need review. Fixed right-facing art only; no new mirroring/directional set.

Private publication succeeded:
- Game implementation: `1fa2e371b9aafc1dd934db9ba1563ccd091cdb02`.
- Export: `build/poses`.
- Hosted source: `091e6b5b40a10f36e12f3253b9d274263062ac99`.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_27be0e332f508191a2a51dcc508a9a8e`.
- Deployment: `appgdep_6adbc085413081919f5931a621365c60`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site . Owner-private retained.

Next bounded milestone: visually review Kael melee in supported-browser gameplay, focusing on stance transition, target direction, impact timing, foreground overlap and readability. Reproduce and fix the highest-impact observed issue before generating another character family. If browser access remains blocked, record that dependency and seek player observations rather than claiming visual acceptance or generating speculative variants.

## Prior milestone

## 2026-10-23: practice encounter retry

Player outcome: Start screen Practice Battle opens repeatable Ashvale combat. Defeat offers Retry Encounter and Return to Hearth. Practice rewards are temporary, explicitly labeled; leaving or refreshing restores the saved descent. Normal roguelike defeat is unchanged.

Implementation: `feature/practice-encounter-retry`, `d67cff42d787adc9122a0efec9e4730cb9d13682`. Canonical GameState serialization/restoration supplies an in-memory encounter checkpoint and persistent baseline; no new save format. Practice has fixed seed/formation and resets resources. State guards prevent duplicate retry transitions and victory rewards. Missing checkpoints show a disabled retry with Hearth fallback.

Verification: 104 real-scene checks passed, zero failures and no runtime script errors. Covers repeated actual defeat/retry, duplicate clicks, win after retry, reward admission once, baseline restoration, missing checkpoint, refresh/load and normal defeat. Release Web export and package WASM/PCK/byte-length/subpath/native-fetch checks passed. Headless shutdown reports ObjectDB leaks and 3 resources still in use (previous run reported 2); this remains unresolved and is not a gameplay-performance claim.

Browser observed: no new browser gameplay observation. Previously missing WebGL2 and Secure Context remain an unverified environment blocker; no evidence of changed conditions justified a repeat. Human playtest, animation quality, FPS and capture remain pending. No new art was generated. Asset inventory now contains a bounded Kael melee pose production brief and Crawl Tactics design reference.

Publication provenance:
- Game source: `d67cff42d787adc9122a0efec9e4730cb9d13682`.
- Export: `build/practice`; generated package integrity passed.
- Hosted source: `2215ca21f0b71f807ae04837f7de7d4a6c3e5f72`; dist/build-info.json records source/checks.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_d1d2baff3dc4819190a424dd3abed42f`.
- Deployment: `appgdep_6adbbe945f5c819193acbf54f9d0ab4b`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site . Owner-private audience retained.
- Local feature commit only; no public GitHub push/PR/merge. Prior automatic review rejected public source publication; no bypass attempted. Unrelated untracked files preserved.

Next bounded milestone: integrate Kael anticipation/contact poses into an actual melee action, prove fixed foot anchoring and recovery/cancellation, then seek supported-browser visual feedback before expanding the art family. Read the production brief in combat-asset-inventory.md. Existing art, Godot, action lifecycle and practice checkpoint behavior must survive.

## Earlier milestone

## 2026-10-23: guarded combat lifecycle

Milestone: primary attacks and abilities retain exclusive action ownership from anticipation through contact and recovery, abort safely when participants disappear, and do not spend MP on an aborted targeted spell.

Game source branch: `refactor/action-lifecycle`.
Game implementation commit: `b3a0de7b242dc894d7ca79718655c3353f5d4f7d`.
Inherited baseline: `748401d`, with choreography implementation `e2dc7f8`.
GitHub main observed at `0415b6debfb3b0cb398eddff98ac3c8516553930`; neither this branch nor `feature/combat-choreography` exists on the remote. No new PR opened and nothing merged. The previous automatic approval rejection for public source publication was not retried or bypassed.

### Implemented

- Added `ActionLifecycle.gd`: exclusive admission, monotonically increasing action tickets, weak actor/target references, one contact permit, recovery, cancellation and rejection of stale completions.
- Main player/enemy attacks and single/area abilities share the lifecycle. Invalidated targeted spells return failure before MP deduction. Input remains locked through recovery; cancellation input cannot disrupt an admitted action.
- Scene exit cancels its lifecycle. Actor removal no longer leaves presentation awaiting a destroyed actor-owned tween; bounded SceneTree timers permit continuation and target revalidation.
- Counters and status application execute inside contact rather than detached delayed callbacks. Counter timing is now immediate contact feedback; it does not have a separate anticipation animation.
- Removed unreferenced `_run_enemy_ai` and `_try_enemy_spell` alternate execution paths after checking GDScript references.
- No save-format, art, renderer, ability-formula or sharing changes.

### Verification

- Real-scene suite: 64 checks, zero failures, no runtime script errors.
- New cases: duplicate admission, duplicate contact, recovery exclusion, stale completion, cancellation, deleted target, deleted actor, aborted-spell MP preservation and cancellation during presentation.
- Existing checks still cover manual input, buff safety, spell result consistency, rewards, two procedural victories and checkpoint restore.
- Release Web export passed. Package checks passed WASM validity, PCK header, reconstructed byte lengths, subpath loading and native fetch passthrough.
- Two existing resources-in-use warnings remain at headless process shutdown.
- Browser gameplay remains unverified. Previous actual export observation reported missing WebGL2 and Secure Context in the managed browser. No evidence of environment repair justified repeating that attempt. No FPS, screenshot or human enjoyment claim is made.

### Architectural boundary

This is the shared lifecycle extraction, not a complete rewrite of combat rules. BattleManager still owns targeting, AI, boons and ability dispatch. CombatResolver still applies outcomes and emits VFX. Secondary boon hits and counters resolve as effects of the admitted action; terrain and anchor pulses remain separate turn effects. Do not advertise every combat subsystem as migrated into an immutable command/event architecture.

### Next bounded milestone

Direct defeat/retry is still absent: BattleScene ends the run and ResultsScreen offers return to the Hearth. Implement retry from an explicit encounter-start checkpoint without duplicating rewards, losses, narrative advancement or permanent progression. Preserve the ordinary roguelike end-run path and existing saves. Inspect GameState, RunManager, DeploymentScreen, BattleScene, ResultsScreen and RecurrenceStory before choosing the checkpoint boundary. Do not add a new save system or silently change normal-run loss rules.

Also pending: supported-browser visual acceptance, directional character poses/walk cycles, a short-demo finale, and broader unsupported-ability filtering. These are not completed by the lifecycle work.

### Publication provenance

- Game implementation: `b3a0de7b242dc894d7ca79718655c3353f5d4f7d`.
- Export: `build/lifecycle`, packaged with `tools/prepare_playable_web.py`.
- Hosted source: `a058a1011b9b86133b55d323a80d80b5afce7780`; `dist/build-info.json` records the game implementation commit.
- Site: `appgprj_6adba102db888191a91592bf85f1a728`.
- Saved version: `appgprj_6adba102db888191a91592bf85f1a728~appgver_dbf18d4d7ae881919c24aa4bf4fb93c5`.
- Deployment: `appgdep_6adbbcf72408819195a0fc6abb37026f`, succeeded.
- URL: https://appointed-tactics.zzziah.chatgpt.site
- Owner-private audience retained. Deployment success is separate from browser gameplay acceptance.
