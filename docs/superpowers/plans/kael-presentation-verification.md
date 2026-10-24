# Kael presentation verification (final nine-clip integration)

Baseline: `717d2567b5462b8330c41002c7882f7b98db763c`. Godot 4.6.3. Local-only branch; isolated XDG data/config/cache. All materialized legacy LFS assets copied from local baseline only after SHA-256 verification (222 files); no remote fetch.

## Provenance correction

The authoring source changed between initial inspection and copy. Final checksum gate caught SHA `2cbbef4d…` instead of approved `2d76f40e…`. Added a failing immutable checksum assertion, then replaced from the independently verified frozen animation-lab copy. Seven-clip tests pinned that SHA. The final builder-frozen v2.1 subsequently replaces it with `c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117`; tests pin that final SHA. Earlier intermediate commits are not the handoff asset.

## RED → GREEN
- Missing adapter assertion failed before implementation; core 30 assertions passed after.
- Independent pixel/quality method assertion failed; expanded render/fallback suite passed 40.
- Existing practice flag choosing imported Kael assertion failed before Unit factory seam; passed after.
- Final real-scene suite: **113 checks, 0 failures**, no script errors or exit leaks. Covers exact clip samples, no self-granted contact, cancellation, immediate socket evaluation, parent scale, four tile facings, projected feet, quality/style invariance, absent/invalid scene, Unit toggles/fallback, gameplay serialization unchanged, actual VFX origin and mid-projectile cancel/cleanup; nine exact clip durations; authored walk movement/root isolation/loop and all16bones reset to idle; authored collapse endpoint retained after10s despite idle/hit requests; missing optional clips safe fallback and required clip/socket rejection.

Run with isolated writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`:
`godot --headless --path godot res://tests/test_kael_presentation.tscn`

## Project tests
- `python tools/check_playable_loop.py /usr/local/bin/godot`: **425 checks, 0 failures** on final nine-clip code/asset. This full integration run emits ObjectDB/resource exit-leak diagnostics, unlike the clean standalone adapter suite. A second verbose425-check run identifies only AudioStreamWAV/playback instances and three existing SFX resources: attack-impact.wav, spell-cast.wav, victory-chime.wav. No rig/viewport/animation resource leaks were reported. Some earlier full runs were clean. Do not represent this as a diagnostic-free full suite; parent integrated regression must track audio cleanup.
- Asset manifest 94; HUD layout 30; elemental resolver 9; vow/sigil 23; Orren arc 31; faceted mesh; script validation 62: pass. Orren emits baseline ObjectDB exit warning.
- `test_combat_formula.gd`: baseline failure `temper projects expected hp damage (got=45 exp=46)`; direct `--script` also cannot resolve existing Humanoid3D's GameState singleton during compile. Not repaired by visual branch.
- `test_terrain_cleanup.gd` direct `--script`: existing PracticeTerrain3D GameState compile dependency leads to nil terrain and timeout. Real-scene terrain/toggle assertions pass in playable loop. Not repaired by visual branch.

Only presentation assertions changed in existing playable-loop tests: actual imported Kael + both legacy characters; 16/11 bones and 160/192 source profiles respectively; authoritative contact/cancel/anchor/death retained; old hardcoded script identity replaced with observed authored windup and legacy shared motion; +Z facing and quality-invariant Kael pixel source.

## Final nine-clip gate
- Builder froze `c8213805…6117`; bytes were checksum-verified before copy. Separate isolated Godot4.6.3 import confirms nine clips,16bones,1skin,3sockets, finite sampled poses, preserved original durations and walk-loop endpoint equality (~2e-7 transform metric).
- A strict imported defeat1.75→2s equality probe observed subpixel settling (max translation0.000356m), documented rather than suppressed. Adapter clamps exact2s and holds; regression proves this.
- Behavior tests failed before integration (missing authored walk/defeat selection, leg motion and collapse); passed after phase mapping. No speculative bone reset was added: actual walk→idle resets all16bones naturally and is tested.
- Fixed-duration gait mapping may slide on long moves; no IK or blend-tree claim.

## Pending
- Native visual review at gameplay scale (sole designated graphical operator).
- Integrated current-branch full regression after parent combines combat/UI work.
