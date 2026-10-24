# Verified integration checkpoint — 2026-10-24

> **Historical checkpoint, not current deployment status.** The source, no-publication
> statements and clean-source limitations below describe this earlier integration
> task. Later PR #72–#75 delivery, scoped runtime hydration, CI and graphical
> evidence are recorded in the [delivery ledger](../production/delivery-ledger.md).
> Read the [live build-info.json](https://rando2020.github.io/ProjectTactic/tactics/build-info.json)
> for the version deployed now; do not treat baseline `717d256` as current or blocked.

This is a bounded Godot checkpoint, **not a completed combat redesign**. The
Recurrence story, existing run structure and gameplay intent were preserved.
No source push, main merge, deployment, or remote CI run was performed by this
integration task. Hosting and graphical acceptance are separate owner tasks.

## Exact build input

- Baseline: `717d2567b5462b8330c41002c7882f7b98db763c`.
- Export source: `0db52e500c96743b2512acc3b4690cb9584b2321`.
- Export source tree: `244a153248cd8f5a20f5a3a61f260cdda9aacdda`.
- Last gameplay change: `30021ad`, the independently reviewed positive-speed
  progression/Slow guard. Later source changes before export were test-only.
- Godot: `4.6.3.stable.official.7d41c59c4`, matching official 4.6.3 release
  Web/no-threads and Windows/x86-64 templates, installed only into isolated
  workspace XDG data. Official template archive SHA-256:
  `3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8`.

Every remaining runtime LFS payload used by the build was hashed against its
source pointer: **218/218 exact OID and byte-size matches**. The five recovered
PNGs are now raw blobs with unchanged historical hashes; Kael's raw GLB is
1,232,656 bytes, SHA-256
`c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117`.

## Approved patch provenance

All source ranges were independently reviewed before integration. `git
range-diff` confirmed identical patches for combat, input, UI and Kael; there
were no manual merge conflicts.

| Area | Original commit(s) | Integration commit(s) |
| --- | --- | --- |
| Exact historical recovery | `6444474` | `6444474` (preserved ancestor) |
| Combat projection, ability power, CT, Defend/forecast refresh | `9e27662`, `7afcd93`, `4053848`, `fd4f2f4` | `a38d561`, `22a6ceb`, `ce4738f`, `dc0c729` |
| Cancel/Move input | `938cb2e` | `4e79204` |
| Responsive readability, scrolling, turn rail, populated loadout | `9d5fbeb`, `ea54d0f`, `8d7b1a4`, `cd557c1` | `ac60d05`, `ad7c318`, `77fe361`, `755b9da` |
| Original Kael presentation and final nine clips | `d888f2b`, `3ef94a6`, `ad0971e`, `4b3f9c4` | `1815ec3`, `2a98e1a`, `5dc6c2d`, `a5d9727` |
| Progression/Slow speed safety | `7e4a9c7` | `30021ad` |

Integration-only reviewed corrections: terrain scene harness `db7ab3a`;
expanded CI runner `8feb304`; partial timeout diagnostics `10e561b`; narrowly
scoped recovered-asset portability and CI engine pin `4b68027`; speed factory
boundaries and runner coverage `0db52e5`.

## Fresh verification on the hydrated export source

All **20 aggregate commands exited 0**, with no `SCRIPT ERROR`. The numerical
contracts total **3,687 checks/assertions**; terrain cycles, mesh, script loads,
and data validators are additional checks, not included in that total.

| Contract | Result |
| --- | --- |
| Combat formula / execution / turn order | 209 / 53 / 130, zero failures |
| Cancel/Move input | 17, zero failures |
| Progression and Slow speed safety | 73, zero failures |
| Real playable loop | 425, zero failures |
| UI readability and geometry | 2,465, zero failures |
| Kael adapter and transitions | 113, zero failures |
| Recovered originals | 5 assets / 15 assertions |
| Asset manifest / HUD layout | 94 / 30 assertions |
| Element / Orren / vow-sigil | 9 / 31 / 23 |
| Terrain cleanup | 10 enable/redraw/disable cycles |
| Faceted mesh / production scripts | passed / 63 loaded |
| Recurrence / first art pass / static checker | passed / passed / passed with 19 warnings |

The existing CI entry point now runs ten isolated contracts with a finite
120-second limit per contract, plus six runner unit tests. This complete runner
also exited 0 on the hydrated build. Tests use temporary data/config/cache paths,
not player settings or saves. Runner negative controls reject nonzero exits,
script errors, missing success markers, and `10 failures` mistaken for zero;
timeout diagnostics are retained.

Terrain's former timeout was a test harness issue: standalone `--script`
compilation could not resolve the GameState autoload. The same ten cycles in a
normal scene passed; both deliberately forced assertion failures now exit 1
promptly. No production terrain code was changed.

### Warnings, not hidden failures

Static checking reports 19 unused/shadowed-name warnings. Some input/playable
runs emit ObjectDB/resource-in-use diagnostics on shutdown; verbose runs named
`ui-confirm.wav`, `attack-impact.wav`, `spell-cast.wav`, `victory-chime.wav`, their
audio playbacks, and an input movement coroutine. Orren's test also emits an
ObjectDB warning. The exact number varies by run. No rig leak was identified,
but neither the underlying cause nor pre-existence relative to baseline is
claimed proven. These diagnostics were not suppressed or presented as pristine
runs.

## Clean-source / CI limitation

Plain `git archive` invoked the local LFS smudge filter, so it was **not** accepted
as clean-source evidence. A second archive with `GIT_LFS_SKIP_SMUDGE=1`, no copied
working assets and no import cache, retained 218 legacy runtime pointers. Its
import returned 0 but emitted 515 `ERROR` lines and five `SCRIPT ERROR`s. The
startup-blocking preloads in `AudioSettings.gd` were:

- `res://assets/audio/sfx/ui-confirm.wav`
- `res://assets/audio/sfx/attack-impact.wav`
- `res://assets/audio/sfx/spell-cast.wav`
- `res://assets/audio/sfx/victory-chime.wav`
- `res://assets/audio/sfx/defeat-sting.wav`

The five recovered PNGs still passed their 15 assertions in that archive, but
shared autoload errors make this **not a clean application test**. The script
loader and formula checks also printed nominal success and exited 0 despite
those parse diagnostics; inspecting logs is essential. The expanded runner
rejects `SCRIPT ERROR` output. No claim is made that current LFS objects are all
unavailable remotely, or that remote CI has passed: an independent anonymous **baseline** Godot-scope fetch verified 178 unique
LFS objects (51,971,458 bytes), with zero missing OIDs/errors. The integrated
candidate has **218 pointer paths / 174 unique OIDs / 51,969,462 unique bytes**;
all are covered by that verified baseline-object superset. These are distinct
counts, and neither is a claim that remote CI has run. The historical missing-object caveat must
not be generalized to the current runtime scope. Blanket LFS conversion or
blanket checkout was not introduced.

### Supported clean-checkout acquisition

Start with a checkout that skipped automatic LFS smudging, then hydrate only
objects referenced by its current Godot tree before import:

```sh
git lfs fetch --include='godot/**' --exclude='' origin HEAD
git lfs checkout 'godot/**'
godot --headless --path godot --editor --import --quit
python tools/check_playable_loop.py
```

CI now performs these exact scoped fetch/checkout commands before importing.
No blanket historical fetch, credential change, new access grant, or raw-byte
conversion of the remaining legacy assets is required. An independent clean
checkout/import verification is tracked separately from this integration's
already-verified hydrated exports.

## Build outputs and limits

Fresh Web and Windows release exports both exited 0 with no export
`ERROR`/`WARNING`. Web packaging validated WASM integrity, PCK magic, assembled
byte lengths, relative subpath loading and normal fetch passthrough. Windows
PE structure and embedded PCK were checked; the executable was **not run on
Linux**. Browser/native acceptance is separate from those structural checks.

Local handoff directory:
`/workspace/shared/tactics-integration-2026-10-24/final-build/`.
`manifest.json` pins every artifact/file hash, the exact source/tree, template
provenance and validation limits. `SHA256SUMS.txt`, Web/Windows ZIPs, and official
Godot license/third-party notices accompany the outputs. Build/test/import logs
are in the parent evidence directory. No old hosted engine or stale build was
mixed into these exports.

## Remaining gameplay work, explicitly deferred

The read-only October tactical audit targeted immutable `938cb2e`; its
positive-speed defect is addressed separately above. Its other gaps are not
claimed fixed here:

- Unresolved starter/job ability IDs, Long Shot's minimum-range mismatch, and
  player/enemy Silence plus hit-gated control asymmetry need a bounded contract
  pass.
- Cover, Iron Wall, barriers, Quickstep, teleport and several other named
  support/special effects do not yet deliver all their described mechanics.
  Heal forecasts/execution and some area-footprint descriptions differ.
- Equipment and weapon profiles are staged, not a completed weapon-by-class
  tradeoff system. Mastery passives and automatic level-based ability grants
  are not validated live features. Enemy roles primarily shape composition and
  stats, not fully distinct tactical planning.
- Two historical elite overlays remain unavailable and were not invented.

The checkpoint improves truthful damage/CT, input, readability, presentation
and progression safety. It does not certify every declared ability, long-run
balance, every mastered-job combination, or a full tactical redesign.
