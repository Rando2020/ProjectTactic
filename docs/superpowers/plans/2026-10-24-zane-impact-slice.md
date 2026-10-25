# Zane Impact Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship original, readable weight and impact for Zane's movement, basic sword attack and existing Fire in the playable Godot Practice demo.

**Architecture:** Keep combat/grid/lifecycle authoritative. A versioned original rig and audio pack feed one ticket-owned presentation adapter/controller; all other actors, skills and default feedback retain their existing paths. Parallelize asset production with runtime work against the frozen interfaces below, then integrate and verify real gameplay.

**Tech Stack:** Godot 4.6.3/GDScript, Blender 4.3.2, glTF/GLB, Python standard-library synthesis/validation, existing native/Web export pipeline.

**Spec:** `docs/superpowers/specs/2026-10-24-zane-impact-slice-design.md` (read with this plan).

## Global Constraints

- Godot **4.6.3**, existing 16-bone shared rig; original locally authored assets/audio, no paid services or unverified third-party samples.
- Fire remains canonical `fire` (`fireball` is only its existing alias): **12 MP, range 3, power 100, fan width 1 / three tiles, burn duration 2 at magnitude 0.07**.
- No new `Engine.time_scale` changes; at most one existing pause per scoped action: sword **80 ms**, Fire **60 ms**, only on actual HP/armor impact.
- Preserve preparation **0.20 seconds**, Fire travel **0.22 seconds**, recovery **0.22 seconds**; Zane-only movement may last **0.50–1.00 seconds** with no CT/cost/range/occupancy changes.
- Preserve shared rig/rest/sockets, 138.24-pixel footprint, original `zane_v2`, non-Zane parity, 2D fallback, canonical saves, turn ownership and existing terrain/status authority.
- Work only on the scoped feature branch. No automatic merge or unrequested publication. No runtime implementation belongs in React.

## Review Focus

- Mixed Fire hit/miss/immunity, empty fan and lethal recipients must never get inferred damage, per-recipient charge audio, repeated pause, or revived death poses (Task 4).
- Actor/target removal, silence during travel, cancellation followed by a new ticket, retry and scene exit must leave no late cue/contact or stuck pause (Task 4).
- Missing/corrupt variant/manifest, 2D toggles and unrelated Kael/Mira presentation must retain visible fallback and independent frozen regression evidence (Tasks 1, 3).
- Long/elevated moves and easing must drive gait from actual distance, with bounded cue cadence and honest residual slip—not fictitious per-tile footfalls (Tasks 1, 3, 6).
- Game/FX zero, three-target mixes, reduced motion and Web cleanup must remain usable without clipping, hidden controls or save leakage (Tasks 2, 5, 6).

## Ownership and parallel order

- **RigAsset:** Task 1 only: new source/GLB/metadata/provenance and its asset validator/tests. No GDScript adapter edits.
- **AudioAsset:** Task 2 only: new WAV pack/manifest/source generator/provenance and its validator/tests. No `AudioSettings.gd` edits.
- **RuntimePresentation:** Tasks 3–5 in order: all GDScript/UI and runtime tests. Own the shared sampler extraction, new variant selection, grid hook, resolver feedback policy, VFX/controller and entry point.
- **Integration/review:** Task 6 after all lanes; one owner integrates test fixes in touched files. Do not have two agents edit the same runtime file.
- Rig/Audio can start immediately after reading the spec; runtime can write RED tests and adapters against its schema in parallel. Final GREEN requires final exported assets, not placeholder mocks.

---

### Task 1: Author and prove the compatible Zane rig variant

**Files:**
- Create: `assets/source/zane-impact-v1/{build_zane.py,author_actions.py,README.md}` plus necessary copied original source dependencies and generated `.blend` source.
- Create: `godot/assets/3d/characters/zane_impact_v1/{zane_impact_v1.glb,presentation.json,README.md}`.
- Create: `tools/validate_zane_impact_asset.py`, `tools/test_zane_impact_asset.py`.
- Do not modify: old `zane_v2`, `kael_v2`, `mira_v2`, their adapters, or frozen fixture/hash tests.

**Interfaces:** Consumes recovered original source/hashes listed in the spec. Produces the exact `presentation.json` schema and exported GLB (rig/bind transform tolerance 1e-5, names/hierarchy exact); `python3 tools/validate_zane_impact_asset.py` validates checked-in outputs and emits a compatibility report. Only walk/slash/cast keys may change. Runtime reads measured `gait_calibration.step_canvas_px` per facing, not an invented 48 px step.

- [ ] Write `tools/test_zane_impact_asset.py`: missing outputs fail; corrupted baseline hash, bone/rest/skin/socket difference, changed unapproved clip, missing required clip, root motion and inconsistent marker seconds fail; valid variant differs in approved animation keys only.
- [ ] Run `python3 -m unittest tools.test_zane_impact_asset -v`; observe missing-variant RED.
- [ ] Copy/version the original builder and dependencies; author a separate action-edit pass, refine only Zane's silhouette/materials, export nine clips, and populate actual hashes/markers/compatibility and gait calibration. Keep source markers at documented source frames, with runtime load/snap mapping supplied by Task 3. Validate socket trajectory, floor clearance and sword/body separation on the **export**, not only Blender.
- [ ] Run the validator and tests; render four facings plus idle/load/release/recoil/recovery and short/long gait samples at the actual 138.24-pixel footprint. GREEN requires all structural tests and no new conspicuous penetration; note residual slide rather than claiming IK.
- [ ] Commit only owned sources/runtime assets/metadata/validators. Follow existing LFS policy; verify new LFS objects are available to a clean checkout, or use only a reviewed narrow frozen-runtime exception consistent with existing character assets.

### Task 2: Build the original Zane cue pack

**Files:**
- Create: `tools/generate_zane_impact_audio.py`, `tools/test_zane_impact_audio.py`.
- Create: `godot/assets/audio/zane_impact_v1/{manifest.json,README.md,step-a.wav,step-b.wav,sword-load.wav,sword-release.wav,sword-hit.wav,fire-charge.wav,fire-release.wav,fire-hit.wav,fire-miss.wav,fire-immune.wav}`.

**Interfaces:** Produces spec cue IDs/manifest (`step_a`, `step_b`, `sword_load`, `sword_release`, `sword_hit`, `fire_charge`, `fire_release`, `fire_hit`, `fire_miss`, `fire_immune`). Runtime loads streams from the manifest and applies `gain_db` on the existing FX bus. Source generator is deterministic; no runtime library/service required.

- [ ] Write `tools/test_zane_impact_audio.py`: all ten IDs present, files/hash/durations match, mono PCM16/48000 Hz, peak ≤ -3 dBFS, no clipping/DC/click-prone endpoints, maximum durations per spec and total WAV bytes <1 MB; identical generation reproduces hashes.
- [ ] Run `python3 -m unittest tools.test_zane_impact_audio -v`; observe missing-pack RED.
- [ ] Implement layered deterministic synthesis and manifest/provenance; generate files. Make body/attack/air components distinct and leave headroom. No sampling/relabeling existing combat WAVs with unknown provenance.
- [ ] Run tests GREEN and audition individual cues plus a simulated three-recipient mix (one release/one master hit, not three). Decode/listen through the available audio channel and record observations/revisions; mark physical speaker/headphone checks unverified unless actually tested; generator tests are not a listening substitute.
- [ ] Commit only owned pack/source/tests; verify LFS hydration in clean-checkout gate.

### Task 3: Integrate variant sampling and actual-distance locomotion

**Files:**
- Create: `godot/scripts/presentation/ZaneImpactRigPresentation.gd`, `godot/scripts/presentation/ZaneImpactAudio.gd`.
- Modify: `godot/scripts/presentation/SharedRigPresentation.gd` (default-preserving sampler hook only), `godot/scripts/units/Unit.gd`, `godot/scripts/grid/TacticalGrid.gd:811–834`.
- Create: `godot/tests/test_zane_impact_rig.{gd,tscn}`.
- Modify only routing expectations as necessary: `godot/tests/test_zane_presentation.gd`, `godot/tests/test_kael_presentation.gd`, `godot/tests/test_mira_presentation.gd`, `godot/tests/test_playable_loop.gd`; retain old source/hash/pose/fallback assertions through direct original-adapter fixtures.

**Interfaces:**
- Shared `_phase_sample() -> Dictionary` returns `{clip: String, time: float}`; `_sample()` still owns seek/advance/socket update. Original profiles return the exact old values.
- New adapter reads/validates Task 1 metadata, overrides only approved states, and provides `begin_walk(direction: Vector2i, distance_px: float) -> float`, `advance_walk(distance_delta_px: float, elapsed_delta_s: float) -> void`, `end_walk(cancelled: bool = false) -> void`.
- `ZaneImpactAudio.play_cue(cue_id: String, owner: Node) -> AudioStreamPlayer` is static and uses Task 2 manifest and FX bus; null for missing cues. It uses no global RNG, no loops and a cap of three active new voices. Owners can stop/free their own handles. The rig/action owner declares `cue_started(cue_id: String)` and the helper emits it on that owner for test observation.

- [ ] Write `test_zane_impact_rig`: validate load/snap/contact/recoil/recovery samples, current-frame socket origin under transformed parent, irreversible defeat, original fallback then sprite fallback; distance increments (including zero/nonuniform increments) advance gait/plant crossings, while stationary start and stop emit none. A 0.14-second cue minimum and no backlog burst hold; cancelled/dead movement emits no late sound. Assert duration in [0.50,1.00], unchanged grid/HP/MP/CT and no root motion, not zero foot-slip.
- [ ] Run `godot --headless --path godot res://tests/test_zane_impact_rig.tscn`; observe missing-adapter RED.
- [ ] Extract the sampler hook without changing old values. Add variant metadata validation, state mapping and 0.10-second variant-only stop settle. Route existing Show 3D Zane to variant → original Zane → sprite; no new feature toggle. Grid supplies actual prior/current interpolated canvas displacement and wall-clock delta to the new adapter while preserving its existing straight segment, occupancy update and callers. Use measured stride per facing; use the bounded duration formula for this variant only.
- [ ] Run new suite plus `test_shared_rig_presentation`, `test_kael_presentation`, `test_mira_presentation`, `test_zane_presentation`, `test_playable_loop` scenes. Require zero failures and frozen original comparator unchanged. Retain rig toggle detach/free and all contact/cancellation assertions.
- [ ] Commit scoped integration and tests.

### Task 4: Drive honest sword/Fire effects from one lifecycle ticket

**Files:**
- Create: `godot/scripts/presentation/ZaneActionPresentation.gd`, `godot/tests/test_zane_impact_actions.{gd,tscn}`.
- Modify: `godot/scripts/vfx/VFXManager.gd:591+`, `godot/scripts/battle/BattleManager.gd` (primary basic attacks, ability result/AoE paths, lifecycle finish/cancel/exit), `godot/scripts/battle/CombatResolver.gd`, `godot/scripts/battle/BattleScene.gd` (one camera-offset owner).
- Read but do not change mechanics: `ActionLifecycle.gd`, `CombatFormula.gd`, `AbilityDB.gd`.

**Interfaces:** Use context/record/controller/VFX signatures exactly from the spec. Add trailing `feedback_owner: StringName = &""` to `resolve_attack` (after `mods`), `resolve_spell`, and `_execute_ability_with_result` (after `source_status_requires_hit`). `_present_action` adds trailing `ability_id: String = ""`. Default calls retain current behavior. Nonempty owner tags emitted outcomes and suppresses only resolver audiovisual work; no formula/roll/side-effect branch moves. Never suppress `receive_damage`, `Unit.animate_death`, logical defeat/removal, status/counter/elite/curse behavior, `unit_defeated` or `combat_resolved` signals; only resolver-owned decorative KO/death VFX are suppressible. `BattleScene.apply_zane_impact_kick(direction: Vector2, strength: float, duration: float) -> void` composes deterministic impulse through its existing offset updater.

- [ ] Write real-scene action tests using actual resolver/lifecycle: canonical Fire/alias retains literal 12/3/100/fan1/burn2/.07; one MP spend, one result per recipient, unchanged CT/action flags and terrain/status outcomes. Cover three hits, mixed hit/miss/immune, all immune, empty fan, neutral zero, armor loss, overkill, sword hit/miss/critical/counter. Count one charge/release/master impact and one pause; no hurt cue/pose/kick for miss/immunity. Assert other characters/skills still use legacy feedback. Test new cosmetic calls leave global RNG state unchanged.
- [ ] Add interruption fixtures: before release, during travel, actor/target death/removal, post-lead-in silence, repeated click, cancel→new ticket, scene exit/retry. Assert no resource/damage duplication, late cues, stale handle, target resurrection, or stuck pause; eventual owned nodes/voices zero after ≤0.70-second tail plus a frame.
- [ ] Run `godot --headless --path godot res://tests/test_zane_impact_actions.tscn`; observe new behavior RED.
- [ ] Implement action-scoped controller/owned FX and cue handles. Capture canonical ability/context after admission; preserve post-lead-in validations, MP deduction and per-target resolution order. Collect Fire results via `_execute_ability_with_result` once each, preserving normal log/terrain/status behavior; present the aggregate once. Basic attacks present their actual result before existing follow-ups. Suppress both legacy resolver feedback and BattleScene result-shake only for marked scoped outcomes. Use one existing 80/60 ms pause, no competing pause/timescale, and no cosmetic calls to global RNG.
- [ ] Run new suite and `test_combat_execution`, `test_combat_formula`, `test_spell_outcome_feedback`, `test_hit_secondary_status`, `test_silence_contract`, `test_terrain_cleanup`, `test_starter_identity`, `test_cancel_move_input`, `test_tactical_contract_integration` scenes. Require zero failures; investigate real regressions rather than relaxing assertions. Compare on/off new presentation against identical real outcomes with controlled combat RNG, accounting for known legacy cosmetic RNG use.
- [ ] Commit scoped controller/integration/tests.

### Task 5: Make the showcase findable and comfortable

**Files:**
- Modify: `godot/scripts/ui/StartScreen.gd`, `godot/scripts/presentation/PracticeComparison.gd`.
- Create: `godot/tests/test_zane_impact_showcase.{gd,tscn}`.
- Modify: `README.md`, `docs/systems/playable-tactics-loop.md` (accurate local-candidate entry instructions only; no false deployed claim).

**Interfaces:** Existing `_on_rig_practice_pressed()` still uses `GameState.begin_practice()` then `practice_session.rig3d = true`; set session-only `zane_showcase = true`. No new mode or persistent save fields. `practice_session.reduced_zane_motion` controls the new presentation only; context reads it as `reduced_motion`.

- [ ] Write showcase test: exact entry/banner text from spec; old Practice/Continue paths remain; original party/enemies/initiative retained; no forced active Zane. New variant loads from existing 3D toggle, original/sprite fallback is visible. Reduced motion removes only new kick/wobble/flash, not timing/outcomes. Game=0 and FX=0 are silent, Music remains separately controlled; settings and canonical save before/after exit/retry match baseline.
- [ ] Run `godot --headless --path godot res://tests/test_zane_impact_showcase.tscn`; observe missing-entry/setting RED.
- [ ] Rename only existing 3D button to “Practice: Zane showcase”, add exact banner and session-only “Reduced Zane impact motion” control inside existing view/quality UI. Keep idle-turn switching guard and no new global settings system. Update candidate instructions.
- [ ] Run new suite and `test_playable_loop.tscn`; run `godot --headless --path godot --script res://tests/test_ui_readability.gd` and `godot --headless --path godot --script res://tests/test_battle_hud_layout.gd`, then native 1080p/4K UI checks; require no clipped instructions/controls, save leakage or unauthorized turn change.
- [ ] Commit scoped UI/docs/tests.

### Task 6: Fresh build, audiovisual review and delivery evidence

**Files:** Create `docs/qa/zane-impact-slice.md`; amend only owned files when fixing issues. Generated captures/builds stay outside source runtime paths.

**Interfaces:** Consumes merged RigAsset, AudioAsset and RuntimePresentation commits. Produces actual tested commit/hash/build provenance, test results and representative playable captures, not just an asset preview.

- [ ] Run `node tools/check_godot_stability.mjs --skip-godot`, both Python asset/audio suites, `godot --headless --path godot --import`, then `godot --headless --path godot --script res://tests/validate_all_scripts.gd` and all Task 3–5 scenes. Require success markers/zero failures; report any baseline shutdown diagnostic separately, never waive script/import/resource errors.
- [ ] Export fresh empty directory: `python3 tools/export_pages_web.py /tmp/zane-impact-web --godot /usr/local/bin/godot`. Require fresh output/package validation and source commit in `build-info.json`. Verify fresh-clone asset hydration; no LFS pointers in runtime payload.
- [ ] Capture native and supported-browser **actual gameplay** at normal speed: short/long/elevated movement, four facings, sword hit/miss, Fire hits/mixed/immune, reduced motion, sprite fallback, repeat-cast/toggle/retry. Frame storyboard: 0.00 brace, 0.12 compressed ember, 0.20 release, 0.30 flight/recoil, 0.42 contact, 0.64 recovery end (existing hit pause may add wall time). Label separate Blender storyboards as proposed concepts, not native proof.
- [ ] Measure exported rig stride/visible foot drift against baseline, source origin alignment, target/fan readability and actual master mix. Compare warm same-camera actions at standard/high quality; use existing rolling frame intervals honestly (not GPU time). Reject new clipping, conspicuous penetration, wrong fan reach, audio stacks, runaway allocations or material frame-time regressions; calibrate only owned presentation values and rerun affected gates.
- [ ] Perform independent whole-branch review, record verified/unverified evidence, commit QA notes, and hand the reviewed candidate/preview to the parent for authorized delivery/PR. Do not auto-merge or silently publish.

## Handoff

User already approved execution; no extra creative approval gate is required. Parent may dispatch RigAsset, AudioAsset and RuntimePresentation now using the ownership map. Asset/source hashes and gait calibration are generated facts to verify, not placeholders to accept. This plan itself implements no runtime changes.
