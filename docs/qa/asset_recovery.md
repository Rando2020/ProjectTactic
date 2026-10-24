# Exact historical asset recovery — 2026-10-24

Scope: restore the original five PNGs below, without generating replacement art,
changing registry mappings, or changing gameplay/story. SHA-256 values are the
original Git LFS object IDs, checked against the recovered bytes before copying.
Source URLs are pinned to historical commits, not mutable branch heads.

The four run-node LFS pointers already exist at baseline `717d256`; their hydrated
working-tree bytes also matched the historical objects. Their initial runtime
failure was a missing Godot import cache, not different artwork. The hub background
was absent from the baseline tree. Thus only the hub PNG requires a new Git tree
entry; staging the four matching icon pointers correctly produces no icon diff.
The new hub import sidecar follows the repository's existing PNG convention.

## Provenance

All paths are relative to the repository root. Icons are RGBA PNGs, 64 × 64;
the background is 1280 × 720. No pixels were modified.

| Path | Bytes | SHA-256 / LFS OID | Pinned original source |
| --- | ---: | --- | --- |
| `godot/assets/generated/icons/run-node-battle-icon.png` | 459 | `2a489de43fd734ca2e8eada80e713972e40bf98f8a7df59efc1d306149e9bf5a` | [785e1d7def4a6b8c335e2a854e3d993656257c9a](https://media.githubusercontent.com/media/Rando2020/ProjectTactic/785e1d7def4a6b8c335e2a854e3d993656257c9a/godot/assets/generated/icons/run-node-battle-icon.png) |
| `godot/assets/generated/icons/run-node-boss-icon.png` | 497 | `903b848a52ab06263d63a6efa791dafa99706bd4ab6eca9446345ca1e8a96164` | [785e1d7def4a6b8c335e2a854e3d993656257c9a](https://media.githubusercontent.com/media/Rando2020/ProjectTactic/785e1d7def4a6b8c335e2a854e3d993656257c9a/godot/assets/generated/icons/run-node-boss-icon.png) |
| `godot/assets/generated/icons/run-node-elite-icon.png` | 521 | `79bc01a3ca09e76fdaaa4b9de664394495b103ec7e7517d4a2bfd5b954671166` | [785e1d7def4a6b8c335e2a854e3d993656257c9a](https://media.githubusercontent.com/media/Rando2020/ProjectTactic/785e1d7def4a6b8c335e2a854e3d993656257c9a/godot/assets/generated/icons/run-node-elite-icon.png) |
| `godot/assets/generated/icons/run-node-wanderer-icon.png` | 519 | `80a0a8821d16e7b0efbd97d66bad3fcfd3e2d25b369714f6a10191e25618947e` | [785e1d7def4a6b8c335e2a854e3d993656257c9a](https://media.githubusercontent.com/media/Rando2020/ProjectTactic/785e1d7def4a6b8c335e2a854e3d993656257c9a/godot/assets/generated/icons/run-node-wanderer-icon.png) |
| `godot/assets/backgrounds/hub-background-last-hearth.png` | 18807 | `ead7f40504bc2cc0a08abf466adfa38ac1995e0fef5c9ef0054737549460e32b` | [9f02a5f4c845c0e44e92834b03aefd267307610d](https://media.githubusercontent.com/media/Rando2020/ProjectTactic/9f02a5f4c845c0e44e92834b03aefd267307610d/godot/assets/backgrounds/hub-background-last-hearth.png) |

## Verification

Godot 4.6.3. Run from the repository root. The five verified originals are now
raw Git blobs (see the clean-checkout portability follow-up below); the initial
recovery run described here used hydrated LFS objects:

```sh
godot --headless --path godot --import
godot --headless --path godot --script res://tests/test_recovered_assets.gd
```

The focused test checks historical hashes, real `ResourceLoader` texture loads,
and original dimensions. Before recovery/import it exited 1 with five failures:
the four icon imports could not load, and the hub source PNG did not exist.
After copying all five original byte streams and importing, it exited 0:
`Recovered asset contract: OK (5 assets, 15 assertions)`.

Broader baseline checks passed: 61 production scripts, asset manifest (94), HUD
layout (30), element resolver (9), Orren arc (31), vow/sigil (23), faceted mesh,
recurrence data, and first-art-pass validation. The playable loop reported 415
checks / 0 failures, but retained its exit-time object/resource leak diagnostics.
The unrelated combat test failed its temper rounding expectation (45 vs 46) and
reported a `GameState` compile dependency error; standalone terrain cleanup timed
out after 180 seconds. Those systems are unchanged here; this is not a claim that
the entire baseline suite is green.

Only source PNGs/LFS pointers, the new hub import sidecar, this document, and the
focused test/UID belong in this change. Import caches, logs, LFS caches, unrelated
generated UIDs, and pre-existing hydrated-asset worktree changes are not staged.
No remote object upload or push is required or performed.

## Remaining recovery gaps

The registry still references these two unavailable historical overlays:

- `elite_marked`: `res://assets/overlays/elite-overlay-marked.png`
- `elite_champion`: `res://assets/overlays/elite-overlay-champion.png`

No verified original bytes have been recovered for either. They are deliberately
not fabricated, substituted, renamed, or included in the five-asset contract.

## Clean-checkout portability follow-up

The five verified originals above are now stored as raw Git bytes via five
exact-path `.gitattributes` exceptions. Their SHA-256 values and pixels are
unchanged. This bounded exception avoids enabling blanket LFS checkout against
the repository's incomplete historical LFS store. Other assets remain under
their existing storage rules; this does not claim every legacy pointer is
available in a fresh checkout. CI is pinned to the tested Godot 4.6.3 engine.

The historical incomplete-store warning is not a claim that current runtime
objects are unavailable: a separate anonymous **baseline** Godot-scope fetch
verified 178 unique objects (51,971,458 bytes). The integrated candidate has
218 pointer paths / 174 unique OIDs / 51,969,462 unique bytes, all covered by
that verified baseline-object superset. CI now fetches/checks out only current
`godot/**` objects before import; see the integration checkpoint's clean-checkout
commands. No blanket historical LFS fetch is needed.
