# Chapel combat integration, 2026-10-31

## Scope and PR stack inspected

Main at `5941987` already contains the illustrated and painted chapel entries, real Zane/Storm Imp duel, canonical movement, initiative, damage forecasts, spell outcomes, save isolation, results and portrait banners. These are retained, not reimplemented.

- #89, `f189044`: open, unmerged. Build passed, Godot Validate failed in `test_assets_have_stable_fallbacks` on absent `zane-front-illustrated.png`; downstream missing capture artifacts were consequences.
- #90, `43ce95f`: open, unmerged, targets #89. Godot Validate passed. This branch inherits its fallback correction.
- #88, `19c69f6`: open Fire atlas work, cherry-picked here. Includes actual atlas, animation helper and regression test. No PR was merged.
- #81/#82 portrait banner and #83 illustrated adapter overlap code already integrated on main; no second banner or parallel resolver was added.
- #87 is source-model intake, outside this 2D runtime scope. Older environment, 3D and broader gameplay branches are not folded in.

## Artwork review and identity boundary

The 16 v02 PNGs are available as **provisional review art**, not approved canonical replacements. Inspecting all directions against the checked-in approved Zane portrait revealed red rather than cream scarf, differing armor/coat proportions, inconsistent weapon placement, stray fragments near canvas edges and similar frontal silhouettes that do not establish anatomically consistent rotations. Mage, Rogue and Dragoon also remain unapproved identity assignments. Distinct file hashes do not prove genuine turnarounds.

`characters.*.direction_status` prevents provisional directional entries becoming defaults. `Chapel / Provisional Sprite Review` opts in for that session, with a visible provisional label. Normal encounters keep their established idle textures and portrait. Jobs, stats, names and saves are unchanged. No asset is deleted, recolored or horizontally mirrored.

The review sprites use their supplied 256x256 canvas and common (128,245) anchor. Runtime `Sprite2D.offset` places that point at the Unit origin. Texture changes rebind scale. Pixel opacity and human anatomy are different acceptance gates.

## Runtime implementation

- `SpriteCombatPose.gd`: foot-pivot breathing, anticipation/contact/recovery and casting offsets for chapel 2D Zane. Cosmetic only; reduced motion removes pose deformation. This is subtle sprite deformation, **not authored limb animation**.
- `Unit.gd`: facing changes for 2D action targets, stable candidate foot origin, no mirroring; keeps original 3D adapters.
- `BattleManager.gd`: enables the existing ticket-owned Zane action presenter for chapel sprites. Its authoritative resolver and action guards are retained. Fire atlas, hit reactions, bounded pause, compact damage and camera feedback use the same existing presenter.
- `TacticalGrid.gd`: chapel props and units share a ground-depth space instead of placing all units on top of props. Depth updates during movement. Other environments preserve their existing layers.
- `UnitStatusPanel.gd` and `BattleUI.gd`: read-only portrait/status inspection from the compact chapel commands, dismissed on phase changes.
- `AssetRegistry.gd`, manifest, title screen: explicit provisional review entry and safe default resolution.

## Validation

Local Godot 4.6.3 import and Web export succeeded. The new sprite test passed 39 checks after reproducing 10 baseline failures and a separate depth failure. The real chapel combat flow passed 13 checks: legal Fire, double-click guard, one MP charge, one outcome, idle reset, enemy response, zero-MP sword and victory/results.

The Python tooling suite passed 168 tests. The initial 32-fixture playable-loop run passed 31 fixtures and caught three legacy Kael offset assertions in `test_playable_loop`. Origin normalization was narrowed to chapel Zane and provisional sprites so legacy presentation retains its exact transform. The affected fixture passed all 427 checks after correction; documented legacy shutdown resource diagnostics remain visible in logs. Native script checks and Web packaging checks are recorded in the PR.

Local Chromium could not launch: the executor rejects the process-singleton socket (`Operation not permitted`). This is not a browser pass. The isolated `chapel-browser` CI job exports a read-only observer, performs real browser input, and uploads actual screenshots/state/errors to `chapel-browser-evidence`. Production main_scene is restored after export. No observer is installed in production.

## Remaining acceptance gates

Browser evidence must be reviewed for all four provisional facings, foot contact, wall occlusion, 1080p/1440p/4K text and battle visibility, forecast readability, sword/Fire timing, victory and console errors. Successful automated assertions do not certify generated anatomy or visual quality. Default Zane still lacks an approved true four-view set. The existing right rail remains; this change adds contextual Status rather than replacing all HUD layout.

No live deployment, approved artwork replacement, full production-quality acceptance, or merge is claimed. Next: approve identity-correct turnarounds; review the browser captures; refine compact HUD and authored action poses against those captures.

## Actual browser findings and fix follow-up

PR #92 (`fix/chapel-browser-acceptance`) supersedes #91 and contains the full integration. The first browser run exposed Status inheriting a disabled default; a failing button-state regression was added and the command now follows player-turn availability. The second run captured all four facings, 1080p/1440p/4K, Status and a real sword attack with no console errors. It then exposed a QA observer error: Unit.has_acted is not the BattleManager action-spent flag used by the UI. The observer now reports that authoritative flag so the driver waits before choosing Fire. No gameplay rule was changed to satisfy the harness.

A separate native regression caught a one-frame pose deformation under reduced motion. The preference is now passed into the initial pose call, not only its next process tick.

The 2D sword contact pose is held for 80 ms when the resolver immediately requests recovery, keeping a visible contact beat without delaying damage or changing action timing. Regression coverage checks the hold and return to recovery.

The browser driver separates the sword and Fire exercises into fresh production-admitted bouts. With the unchanged 90-HP enemy, a critical sword/counter sequence can legitimately win before Fire becomes selectable. Reloading the practice scene for spell coverage avoids changing HP, RNG or damage to force a longer encounter. The native flow separately covers Fire then sword within one duel.
