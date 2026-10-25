# Zane impact slice — design

Date: 2026-10-24. Source: `29cead4dca4e6dbafa123bc002c230d81d66a403` / tree `6c91ee0b0ee0914fcdd3cf77a8adb6098e9ad455`. Branch: `nova/zane-impact-slice`.

## Purpose and approval

The user approved implementation and delegated creative direction: make movement, a sword attack and one spell feel memorable in the playable demo. Deliver one polished **Zane** presentation slice, not a roster expansion or a new combat system. The feel target is **tension → sharp release → resistance → payoff**. Dave the Diver is a feel reference, not a source of copied audiovisual assets or harpoon mechanics. This document is an execution handoff, not another design-approval gate.

## Non-negotiable constraints

- Godot **4.6.3**, existing 16-bone shared rig; original locally authored assets/audio, no paid services or unverified third-party samples.
- Fire remains canonical `fire` (`fireball` is only its existing alias): **12 MP, range 3, power 100, fan width 1 / three tiles, burn duration 2 at magnitude 0.07**. No single-target Fireball, knockback, stagger, collision damage, combo, balance, AI, job or equipment changes.
- `CombatFormula`, `CombatResolver`, `BattleManager`, `ActionLifecycle`, and grid/terrain services retain gameplay authority. Presentation never spends resources, changes HP/status/CT/occupancy, grants contact, or infers damage from animation or nominal power.
- Preserve post-presentation validation, actual recipient hit rolls, existing grass/road ignition policy, existing secondary-status rules, counters and defeat ownership. Miss/immunity still spend accepted actions normally.
- No new `Engine.time_scale` changes. Reuse at most one existing pause per scoped action: sword **80 ms**, Fire **60 ms**, only when an actual HP/armor impact occurred. Suppress the scoped legacy duplicate pause/shake path.
- Preserve the 138.24-pixel footprint, foot anchor, projected sockets, pixel/clean/quality modes, sprite fallback, canonical saves and ordinary non-Practice rendering defaults.

## What changes on screen

**Movement:** grounded forward intent, distance-matched alternating strides, audible weight, restrained cloth/torso lag, then a soft plant. The grid currently interpolates a single straight visual segment, not a traversed tile path. Keep that segment and all logical movement rules. New Zane variant only: duration `clampf(canvas_distance / 180.0, 0.50, 1.00)` seconds; gait phase advances from actual accumulated grid-canvas displacement, using **measured per-facing projected stride from the new exported walk clip**, not from elapsed time or tile count. The 180 px/s duration divisor is an initial pacing calibration, not a fixed-speed guarantee after the cap. Emit crossed plant cues only while moving, minimum 0.14 wall-clock seconds apart, no catch-up burst. A variant-only 0.10-second pose settle fits inside the existing 0.20-second post-move wait. This is gait matching, **not IK foot locking**; captures must measure remaining foot drift. All other actors retain their 0.50-second move.

**Sword:** planted feet and shoulder/hip load for 0.16 seconds, decisive 0.04-second release into existing lifecycle contact, one narrow blade trail, a short metallic/body composite only on real contact, then the existing 0.22-second recovery. Miss gets air-cut and MISS, never a hit spark/thunk or damage recoil. Armor-only contact is distinct from HP loss; critical presentation follows the real critical flag.

**Fire:** Zane braces with sword controlled and free hand gathering a compressed amber ember; the final 0.04 seconds snap the hand forward. One hot-core projectile leaves the synchronously sampled cast socket, with a short tapered ember trail and visible caster recoil during its **0.22-second travel**. At permitted contact, a restrained fan-shaped sweep depicts the existing three-tile footprint. Each real recipient gets its own honest result; one action-level body impact sound and one camera impulse maximum. Empty fan/all misses dissipate, immunity deflects without hurt recoil, zero-loss nonimmune contact is soft and neutral. Mixed outcomes never make immune/missed recipients flinch. Numbers use `applied_hp_damage`, with existing armor and affinity information; lethal results keep death/KO ownership and never restart a hit pose.

Keep preparation **0.20 seconds**, travel **0.22 seconds**, recovery **0.22 seconds**. Improve key distribution and phase mapping, not every actor's timing. No new flash covering the screen; the bright core is local. Standard effect budget: one projectile/trail, up to eight embers, three fan tile accents, and up to three recipient accents. Trails/charge stop on cancellation; completed short audio/ember tails retire within 0.70 seconds.

## Asset contract (RigAsset owns outputs)

Create `godot/assets/3d/characters/zane_impact_v1/zane_impact_v1.glb` and sibling `presentation.json`. Keep frozen `zane_v2` bytes, README, adapter and hash checks intact. New meshes/materials may refine only Zane's established brown-hair/warm-steel/pale-cloth/slate-blue/charcoal silhouette. Do not mix in the obsolete blond fallback design.

The variant retains exact bone names/order/parents/rest transforms, skin inverse binds (numeric equivalence within 1e-5), and all three legacy socket names/transforms: `Kael_v2_cast_socket`, `Kael_v2_weapon_socket`, `Kael_v2_shield_socket`. Exactly the existing nine clip names/durations remain; only **walk/slash/cast** animation keys may differ. Other clips remain semantically identical. Root motion is never consumed; walk root stays zero. No animation method tracks or gameplay callbacks.

`presentation.json` schema 1 has these required fields (seconds unless stated):

```json
{
  "schema_version": 1,
  "profile_id": "zane_impact_v1",
  "model": "res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb",
  "model_sha256": "<actual exported hash>",
  "baseline_sha256": "9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5",
  "authoring_fps": 24,
  "changed_clips": ["walk", "slash", "cast"],
  "unchanged_clips": ["idle", "thrust", "heavy", "hit", "recovery", "defeat"],
  "source_markers": {"slash_load": 0.375, "slash_contact": 0.625, "cast_load": 0.4583333333333333, "cast_release": 0.875, "cast_recoil": 1.125},
  "runtime": {"prepare": 0.20, "snap": 0.04, "travel": 0.22, "recovery": 0.22, "walk_speed_px_s": 180.0, "walk_min": 0.50, "walk_max": 1.00, "walk_settle": 0.10},
  "walk_contacts": [0.0, 0.5],
  "cast_socket": "Kael_v2_cast_socket"
}
```

Also include `marker_frames` (slash load/contact 10/16; cast load/release/recoil 12/22/28), nine exact `clip_durations`, a generated bone/rest/socket compatibility report hash, `forward_axis: "+Z"`, `root_motion: "in_place"`, and `gait_calibration`: measured world stride plus `step_canvas_px` for each N/E/S/W facing at the unchanged camera/display profile. Seconds are `(authoring_frame - 1) / 24`, not frame/24. Walk plant phases 0/0.5 refer to authored frames 1/13; do not emit a footstep merely for beginning a stationary move. The old ±0.14-world foot excursion projects to only about 12 canvas pixels: **48 px is not a shipping assumption**. Reauthor and measure the new stride; record visible sliding at the 1.00-second cap honestly. Runtime consumes these values; they are not a second independent timing source.

Place source/build/provenance under `assets/source/zane-impact-v1/`; derive from recovered `hero_recon/Original-Characters-Prototype-Checkpoint/Zane-v2/zane_v2.blend` (SHA `374b52c41275feeb45b1df49ad240fc2923de3d4be8636a74a054c0c925131af`) and `build_zane.py` (SHA `276696b68912613dc9a4c19f97b4e35372655a40f4d90f9095716f50e31348eb`). Copy sources, never edit the recovered originals. Record exact output hashes and reproducible export command. Do not commit import caches, films, or unrelated archives.

## Sound contract (AudioAsset owns outputs)

Create `godot/assets/audio/zane_impact_v1/manifest.json`, WAVs, README/provenance and `tools/generate_zane_impact_audio.py`. Use original deterministic local synthesis; no existing ambiguous-provenance combat sample or Dave recording. WAV: mono PCM16, 48 kHz, no loop, peak at most -3 dBFS, short click-free endpoints, total pack under 1 MB. Decode and listen through the available audio channel; numerical compliance alone is not acceptance. Record physical speaker/headphone checks as unverified unless actually performed.

Manifest schema: `{"schema_version":1,"profile_id":"zane_impact_v1","cues":{<id>:{"path":<res path>,"gain_db":<float>,"duration_s":<actual>,"sha256":<actual>}}}`. Stable cue IDs and maximum durations:

| ID | Max seconds | Starting gain dB | Character |
|---|---:|---:|---|
| `step_a`, `step_b` | 0.16 | -10 | muted boot/body with fine grit, alternating |
| `sword_load` | 0.18 | -12 | quiet cloth/steel tension |
| `sword_release` | 0.18 | -7 | fast directional air cut |
| `sword_hit` | 0.28 | -5 | weight plus short metal edge |
| `fire_charge` | 0.20 | -10 | compressed rising pressure |
| `fire_release` | 0.26 | -5 | breath/crack launch, not a gunshot |
| `fire_hit` | 0.48 | -5 | low-mid body, crack and short ember tail |
| `fire_miss` | 0.26 | -12 | airy dissipating heat |
| `fire_immune` | 0.28 | -11 | restrained brittle deflection |

All cues route through existing **FX → Game** buses; zero volume really mutes. Charge/release/hit cues are once per action, not once per fan recipient. Only one Fire outcome tail is selected (impact wins if any real damage/armor contact; otherwise immunity if present, otherwise miss/dissipation). Maximum three simultaneous new voices, no pitch variation using global combat RNG.

## Runtime interfaces and authority

RuntimePresentation owns all GDScript changes. `SharedRigPresentation._sample()` may extract a default-preserving `_phase_sample() -> Dictionary` returning `{clip: String, time: float}`; frozen Kael comparison must remain exact. New `ZaneImpactRigPresentation.gd` overrides phase selection only for approved clips, mapping load/snap, travel recoil and recovery via the manifest. Its movement API is `begin_walk(direction: Vector2i, distance_px: float) -> float` (returns duration), `advance_walk(distance_delta_px: float, elapsed_delta_s: float)`, `end_walk(cancelled: bool = false)`; the grid supplies real displacement and stop/cancel events.

The validated variant is the default **existing Show 3D** choice for Zane, without another toggle. Invalid variant falls back to original Zane, then visible sprite if both fail. Other characters/adapters are unchanged.

Extend `VFXManager.present_action(actor, destination, kind, permitted, context: Dictionary = {})`; empty context follows the exact legacy path. A scoped context contains `profile_id`, `action_key` (`manager-instance-id:ticket`), `ticket`, `actor_id`, canonical `ability_id` (empty for basic attack), `kind`, `destination`, `footprint: Array[Vector2i]`, and `reduced_motion`. Predicate: validated Zane variant plus basic `slash`, or canonical `fire`; never all generic casts or all Zane skills.

`ZaneActionPresentation.gd` owns one action's disposable VFX/audio and exposes `present(actor: Unit, context: Dictionary, permitted: Callable) -> void`, `present_outcomes(records: Array[Dictionary]) -> void`, `finish() -> void`, `cancel() -> void`. Each record is `{target_id, target_ref: WeakRef, grid_pos: Vector2i, outcome: Dictionary}` copied at real resolution; never reconstructed from VFX collision. Provide `cue_started(cue_id: String)` and `phase_presented(phase: String)` signals for exactly-once tests. VFX bridges `present_outcomes(context, records)`, `finish_action(action_key)`, `cancel_action(action_key)`, and the pure query `action_lead_in_completed(action_key: String) -> bool`. The query is true only for a surviving, non-cancelled owner that completed its keyed lead-in. BattleManager checks it before granting contact and aborts only that still-anticipating ticket on refusal; visual cancellation after earned contact never refunds results or changes recovery/turn authority.

Resolver methods gain a trailing `feedback_owner: StringName = &""` argument (after `mods` for attacks). Empty preserves all existing feedback/results. Nonempty suppresses only audiovisual side effects, including miss/hit VFX and resolver-spawned decorative KO/death overlays, and tags every returned/emitted result with `feedback_owner`; scoped damaging results also carry `defeated` copied directly from `receive_damage` (not inferred later). Formulas, rolls, damage, secondary effects and signals remain. Never suppress `receive_damage`, `Unit.animate_death`, logical defeat/removal, `unit_defeated`, status/counter/elite/curse side effects, or `combat_resolved` signals. Scoped caller uses `&"zane_impact_v1"`. `BattleScene` ignores those results for its legacy miss/damage shake. The action presenter owns actual-outcome numbers/reactions and **one** existing pause. A small deterministic directional kick (sword 2 px/0.10 s; Fire 3 px/0.12 s) is composed by BattleScene's existing camera-offset owner, not a competing tween.

`BattleManager._present_action(..., ability_id: String = "")` builds context after lifecycle admission. `_execute_ability_with_result(..., feedback_owner: StringName = &"")` forwards policy; Fire AoE gathers each actual result once, presents once after existing resolution, and preserves MP/terrain/status order. Basic attack call sites present their real result before existing follow-ups. Cancellation, invalid admission/revalidation, actor removal, scene exit and retry invalidate the handle; stale callbacks never affect a newer key. Finish permits only bounded already-started tails; cancel removes them immediately. New presentation uses no global RNG.

## Discovery and comfort

Rename only the existing 3D entry to **“Practice: Zane showcase”**. Reuse the existing Practice map, party, enemies, initiative, controls, retry and save sandbox. No forced Zane turn or party filtering. Display: **“Zane showcase: try movement, a sword attack, or Fire on separate turns. Fire targets a three-tile fan.”** If another character starts, wait for Zane normally.

Add one session-only **“Reduced Zane impact motion”** checkbutton to existing Practice view/quality controls: suppress new camera kick, target wobble and bright flash, keeping targeting, animation timing, trail direction, outcomes and sound. Do not invent a global settings system or change audio settings serialization.

## Evidence required to call this polished

Automated real-scene tests cover exact mechanics, mixed outcomes, empty fan, cancellation/death/travel/silence, stale ticket, mute, cleanup and old profiles. Fresh native and browser gameplay captures show movement at short/long distances, sword hit/miss, Fire hit/mixed/immune, four facings/elevation, 2D fallback and reduced motion. Measure foot drift at plant windows rather than claiming foot locking. Audition the actual fan mix, not only each WAV alone. Compare identical warm gameplay/camera/default-quality samples against baseline; report frame-time distributions and visible regressions honestly. Fresh export provenance must match the reviewed commit. No automatic merge or unrequested publication.
