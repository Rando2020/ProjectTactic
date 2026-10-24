# Shared original-character presentation verification

## Scope and isolation

Base: integration `90cd78195eb000d8a0fa71a631d276c1753f7e15`. Runtime change is restricted to one shared presentation implementation, thin character profiles and the existing Unit opt-in factory. Live/current/public PR72 are not modified. Native visual review belongs to the separate operator; headless tests make no visual-polish claim.

## Independent Kael extraction proof

- Original `test_kael_presentation.tscn` is unchanged: **113 checks, 0 failures**, no log errors/warnings.
- `test_shared_rig_presentation.tscn`: **2,622 checks, 0 failures**, real frozen Kael asset and actual renamed-socket PackedScene, no log errors/warnings.
- Test fixture is byte-identical to original adapter from base commit, SHA-256 `f039d9e7bc3d2fb0306fc335e26a60b590cd9131989219588f4244fc08cfd4f6`; never regenerated from the extracted implementation.
- Comparator covers all eleven facade/fallback phases, nonnegative time clamping, each of sixteen bone poses, authored clip/sample time, immediate projected socket and 3D socket transforms, defeat interruption lock, cardinal facing, parent translation/nonuniform scale/rotation, render-resolution/quality combinations, footprint/foot origin.
- Deliberate contact mutation `15/24 → 16/24` produced **143 failures**; restoring original value returns **2,622/2,622**. This proves the independent reference detects shared phase bugs.
- Mechanical comparison verifies original implementation differs only in model/skin/socket configuration; timing/render/phase logic is unchanged.

## Baseline dependencies and broader regressions

Local clone initially contained LFS pointers. Before clean verification, hydrated 218 unchanged original assets from the integration checkout only when SHA-256 matched the Git pointer; no replacement art/audio or remote fetch. Local LFS clean filtering confirms no asset changes are staged.

- Combat execution: **53 checks, 0 failures**, clean log.
- Terrain cleanup: **10 enable/redraw/disable cycles**, clean log.
- Static stability check: passes with **19 pre-existing warnings** in untouched files.
- Playable loop: **425 checks, 0 failures**, but intermittent exit-time audio leak diagnostics. Verbose original-adapter and extracted-adapter runs both identify the same `attack-impact.wav`, `spell-cast.wav`, and `victory-chime.wav` playback resources, not rig/viewport resources. This broad suite is **not claimed log-clean**; unrelated audio teardown remains unchanged.

## Frozen Mira verification

Parent-authoritative asset copied only after source and destination SHA-256 both matched `980724d38ae5f9ad2e1e616ab58158c093d73f8c13673693a8bfe5e35ad12ddd`. No mutable builder source was copied. Provenance/identity reference and known prototype limits are recorded in `godot/assets/3d/characters/mira_v2/README.md`; narrow raw-GLB Git attributes mirror Kael.

- Fresh real asset import: exit 0, no error/warning lines.
- Missing profile RED: 1 check / 1 intended failure.
- After adding frozen profile, actual Mira import/phase/variant checks pass while Unit routing RED fails exactly once: 81 checks / 1 failure.
- After bounded factory/support-list extension: **115 checks, 0 failures**, clean log.
- Coverage: frozen hash, sixteen bones/nine exact durations, render profiles/footprint, cardinal facing/feet, contact and cast/recovery samples, synchronous scaled-parent socket, actual authored walk/defeat, no root motion, missing asset and real malformed variants, optional seven-clip fallback, actual Unit/VFX/lifecycle authority and cancellation, five repeated synchronous detach/deferred-free cycles, opt-out sprites, archetype aliases, unchanged actor id/HP/MP/grid/position/saved state, both legacy procedural actors and unsupported sprite actors.
- Final complete targeted run after Mira integration: Kael **113/113**, independent shared comparator **2,622/2,622**, Mira **115/115**, combat **53/53**, terrain **10 cycles**; all clean logs.
- All-script validation: **65 scripts loaded**, clean log.

## Reproduce

Use an isolated XDG data/cache/config location; never run save-changing integration suites against player data. Hydrate tracked LFS originals by pointer hash before first import.

```sh
export XDG_DATA_HOME=/tmp/projecttactic-rig-qa/data
export XDG_CACHE_HOME=/tmp/projecttactic-rig-qa/cache
export XDG_CONFIG_HOME=/tmp/projecttactic-rig-qa/config
godot --headless --path godot --editor --import --quit
for scene in test_kael_presentation test_shared_rig_presentation test_mira_presentation test_combat_execution test_terrain_cleanup; do
  godot --headless --path godot --scene res://tests/$scene.tscn
done
godot --headless --path godot --script res://tests/validate_all_scripts.gd
```

Inspect complete stdout/stderr as well as exit codes. The broad playable-loop audio-teardown qualification above remains explicit; native GUI visual acceptance is still separate.

## Independent final review

A fresh read-only reviewer approved `90cd781..8c520e0` with **no Critical, Important, or Minor findings**. The reviewer independently verified the mechanical extraction, frozen asset hash and transform-only/no-external-URI GLB animation structure, unchanged Kael tests, and reran Kael **113**, comparator **2,622**, Mira **115**, combat **53**, terrain **10 cycles**, and script validation **65** with clean logs (`/tmp/shared-rig-review-*.log`).

The author's final post-Mira playable-loop run also passed **425/425 with a clean log**; the intermittent baseline audio teardown caveat remains documented above. Final static checks retain exactly **19 existing warnings**.

Technical review is not native visual acceptance or deployment authorization. Native appearance/GPU performance remain separate; upstream identity-reference rights/rebuild guarantees are not newly established. Arbitrary malformed-import hardening and unsupported direct factory calls retain the pre-existing API contract rather than broadening this scoped refactor. No review fixes or deferred minors were needed.
