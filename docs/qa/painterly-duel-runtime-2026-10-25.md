# Painterly duel runtime candidate — local only

## Scope

Only the existing **Practice: Zane vs Storm Imp** route selects `zane_painterly_v1`. Full-party showcase and ordinary Practice retain `zane_impact_v1`. No new toggle, lighting/shader change, gameplay rule, action timing, progression or save schema change.

The exact `ZaneImpactRigPresentation.gd` resource remains the action-controller identity; `feedback_owner` stays `zane_impact_v1`. Explicit `configure_profile(String) -> bool` accepts only the approved impact/painterly profiles before first tree entry. Unknown profiles and entered/detached reconfiguration reject without mutation. Candidate metadata preserves the original baseline and changed-clips semantics and requires exact inherited-impact provenance.

Painterly uses the existing clean rendering path: Standard192 / High384, LINEAR, existing High4xMSAA. Footprint138.24, camera3.2/pitch30/yaw45, and exactly one Unit-scale gait ruler are unchanged. Fresh fallback order is painterly → impact → original Zane → visible original sprite. Failed adapters detach before replacement.

## Repeatable checks

After importing the actual asset with Godot4.6.3:

```sh
godot --headless --editor --path godot --import
python tools/check_playable_loop.py godot
python tools/check_zane_painterly_fallbacks.py --output /tmp/painterly-fallback-results
PYTHONPATH=tools python -m unittest discover -s tools -p 'test_*.py'
node tools/check_godot_stability.mjs --skip-godot
```

Run these with isolated `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME`. The aggregate native runner isolates every case itself; the fallback runner copies the imported project and isolates every probe. Neither uses canonical player data.

`test_zane_painterly_rig.tscn` is a strict new aggregate contract, with no legacy shutdown-error exemption. Its default run requires the real asset and checks imported bone/rest identity, all nine imported animation channel targets/times/values, all three sockets, actual albedo textures/vertex colors, quality/facing/projection, duel-only routing, existing UI toggles, one-scale gait, replay/exit and unchanged canonical save bytes. Its metadata probe is explicitly a **synthetic metadata unit fixture**, not visual acceptance.

The separate fallback runner exercises missing/corrupt candidate bytes, wrong profile/provenance, a damaged real imported-scene unit fixture after viewport creation, unavailable impact, and all unavailable models. It repeats toggles and checks visible fallback, correct fresh defaults and no orphan viewport. It never modifies source assets. Every engine/script error fails this runner, even after a success marker.

The browser duel assertion accepts only painterly, binds the observed hash to local metadata **and independently hashed actual local GLB bytes**, and requires an actual visible sixteen-bone instance. Full-party browser identity remains pinned to its original impact hash. Browser unit snapshots/transport tests are synthetic, not browser rendering acceptance; this lane still covers movement+sword, not Fire.

## Frozen V4 evidence and limits

- Runtime base: `63d80906e56332d2ac43f1ed3fb5687ecb11edc7`; implementation checkpoint `9226f4f` (assets separate).
- Final model: `14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20`; metadata `2d76386f858cbdb7474efbb14bbca30d4003ca0606743d7bb4fabe76370b5eeb`. Asset owner's frozen chain: `b0c1a5f`, `e86b9ad`, `2872aa6`, `f184fea`. Source handoff uses real Git blobs, not new LFS dependencies.
- Fresh Godot4.6.3 import exited0. Full31-contract native runner exited0 on actual V4. New candidate contract:289 checks,0 failures plus162 malformed-metadata subprocess checks,0 failures; actual import6 textured surfaces and6 vertex-color surfaces. Actual four-facing projected foot-origin stance excursions agree with metadata.
- Existing impact rig120, impact actions1433, showcase84, duel179 and hovered-health50 checks passed unchanged. No new strict-scene error diagnostics. Four legacy scenes retain the **unchanged pre-existing shutdown-resource allowances**: `test_spell_outcome_feedback`(2 resources), `test_hit_secondary_status`(1), `test_cancel_move_input`(1), `test_scout_outcome_integration`(1). Those diagnostics remain visible; this is not a claim that every legacy engine log is pristine.
- All seven V4 fallback probes passed with zero engine/script errors.
- Native duel observer initially failed its stale impact-only identity assertion, then passed after an exact **duel-only** candidate/path/hash/visible-sixteen-bone assertion update. Normal and slow-tail modes both passed; unchanged full-party showcase observer also passed. Both real native sword observations passed the Python duel identity/outcome assertions with the exact V4 digest, one ticket and zero MP. This is native observation evidence, **not browser transport/render acceptance**.
- Python tool suite138 tests passed. Static checker passed with19 pre-existing warnings. Independent runtime review identified no Critical/Important/Minor findings and independently passed30 Python checks; the later native QA-only identity correction was independently exercised RED→GREEN, not a gameplay change.
- Original `zane_v2` SHA `9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5` and impact SHA `669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90` remain unchanged.
- Logs: `/workspace/scratch/ccbd55cd809f/painterly-zane-evidence/runtime/`, notably `final-v4-native-suite.log`, `final-v4-fallbacks/`, `duel-observer-{green,slow}-v4.log`, `showcase-observer-v4.log`, `final-v4-observed-identity.log`, `final-v4-python-suite.log` and `final-v4-static.log`.
- No GUI/browser capture, hardware-GPU, audio-listening, 4K-quality, performance, publication or final-art-match claim is made by this runtime lane. Separate asset and native-visual reviews own their evidence.

## CI registration boundary

Existing `godot-validate.yml` already invokes the strict aggregate runner (therefore the candidate native scene and162 metadata fixtures), its unit tests, duel Python assertions, and native normal/slow-tail observer contracts via the duel QA export stage. Full-party assertions remain unchanged.

The new fallback runner requires these additional bounded commands after project import; they need no new dependencies or Blender:

```sh
python -m unittest discover -s tools -p test_check_zane_painterly_fallbacks.py
python tools/check_zane_painterly_fallbacks.py --output build/painterly-fallback-evidence
```

These commands are now wired by the coordinated release-gate change, together with isolated portable asset validation. See `docs/qa/painterly-release-gates.md`. This runtime slice itself did not alter workflow files.
