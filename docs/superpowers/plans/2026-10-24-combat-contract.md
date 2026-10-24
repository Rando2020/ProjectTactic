# Trustworthy combat choices implementation plan

**Goal:** Make current damage forecasts, physical skill power and turn-order forecasts agree with real outcomes without replacing October presentation, story or practice persistence.
**Architecture:** Retain CombatFormula as the pure damage owner and make Unit consume its armor projection. Pass existing ability power through forecast/AI/resolver. Simulate the same integer CT scheduler for prediction and live turns.
**Tech:** Godot 4.6.3, existing GDScript tests; no new packages.
**Spec:** docs/production/demo-delivery-contract.md and delegated 2026-10-24 combat audit reconciliation.
**Baseline:** 717d2567b5462b8330c41002c7882f7b98db763c; tree 72350868335e897b996beaf798bf0f62e642814e. Local branch only; no push/merge/deployment.

## Reconciliation before edits
- Current chain hops already use skip_setup=true, so September double-MP claim is obsolete.
- Current tick_statuses limits damage to burn/poison/bleed; generic positive status damage claim is obsolete.
- Current Unit.receive_damage still duplicates/truncates formula and ignores Defending. Physical ability execution still discards base_power. CT forecast still uses fractional time unlike live integer ticks.
- Clone contains LFS pointers pending retrieval. Asset validator identifies three missing Godot fallback assets (elite marked/champion overlays and Last Hearth background) and three React reference placeholders. No assumption that ZIP-only files are present.

## Task 1: direct damage contract
Files: Unit.gd, CombatFormula.gd, tests/test_combat_formula.gd, combat-math-contract.md.
- [ ] Add matrix asserting real receive_damage equals formula HP/armor for incoming 0/1/66, armor 0/65, physical/magical, Protect/Defending combinations; explicit Protect physical-only and Defending both direct damage kinds; critical projection uses multiplied incoming, spells have no crit.
- [ ] Run and capture red output before production edits.
- [ ] Route receive_damage through projections; preserve true damage and defeat lifecycle. Fix critical forecast projection and no-spell-crit contract.
- [ ] Run formula tests and full real-scene suite; commit.
Ruling: Protect remains physical-only (receiver and historic skill semantics); Defend's advertised 50% damage reduction applies to physical and magical direct hits. True damage/DoT bypass defenses. No armor balance redesign.

## Task 2: physical ability power
Files: BattleManager.gd, CombatResolver.gd, ForecastCalculator.gd, tests/test_playable_loop.gd.
- [ ] Reproduce basic vs Mighty Strike/Pin Shot/Aimed Shot using real forecast and resolver, cost once.
- [ ] Pass existing base_power through all physical-ability paths, leave ordinary attack/counter default unchanged.
- [ ] Run red/green focused and integration checks; commit.

## Task 3: matching turn forecast
Files: TurnOrder.gd, tests/test_turn_order.gd.
- [ ] Forecast next 30 activations equals repeated live scheduling across ties, existing-ready CT, mixed speeds, haste/slow, dead units, and zero-speed survivors; projection must not mutate CT.
- [ ] Share integer scheduler, consume ready backlog before ticking, deterministic speed/input-order ties.
- [ ] Red/green tests plus all current suites; commit.

## Review focus and boundaries
Immunity/zero damage; critical armor rounding; self-buff duration; AoE one-cost; CT tie/backlog. Existing tests plus new regressions pin these. Parent owns independent review and UI/art. No visual acceptance claims from headless checks. Missing assets and existing shutdown warnings remain explicit evidence, not silently fabricated replacements.

## Evidence ledger
- Task 1: RED 144 pass / 65 fail; GREEN 209 pass / 0 fail. Full real-scene 415 checks / 0 failures. Baseline/current missing run-node icon errors and shutdown warnings retained, not green asset acceptance.
- Ruling: Corrected stale formula test expected46 to45: incoming50, round(50*.35)=18 armor, round(18*.25)=5 reduction, HP45. Formula computed45 before production edits; no math changed to satisfy this assertion.
- Task 2: RED real-scene 26 checks /12 failures, all physical power forecast/AI/application. Cost-once, support status safety and chain cost already pass.
- Task 3: RED 130 checks /51 failures across current live/predicted CT paths.
- Harness correction: legacy `--script` combat test prints results despite a pre-existing autoload compile error (Humanoid3D GameState reference). Converted formula/CT tests to real Node scenes so autoloads initialize. Re-ran original production files in isolated /tmp snapshot: clean RED formula145/64, CT130/51; current clean GREEN209/0 and130/0. Do not count error-bearing first runs as clean acceptance.
- Task 2 GREEN real scene26/0; Task3 GREEN130/0. Full suite pending below. Parent owns fresh review.
- Final gameplay regression:415 checks/0 failures. Other current suites: asset manifest94, HUD30, element9, Orren31, Vow/Sigil23 all pass. Terrain cleanup legacy --script runner encounters pre-existing GameState/autoload compile failure; no production terrain change. Faceted mesh pending. Missing run-node icon errors persist; integration exit0 is not clean asset validation.

## Independent review, round 1
- Fixed displayed damage ranges: old fabricated variance hid correct crit projection. Real-scene RED39checks/12fail → combined GREEN53/0. Normal min and projected critical max now reach BattleUI; magical hits have no fictional variance.
- Fixed timeline invalidation after Haste/Slow application/removal/expiration: RED47/4fail → GREEN53/0. Scheduler listens to speed-status signals; projection refresh never advances CT.
- Fixed consecutive Defend: RED53/3fail → GREEN53/0. Narrow ruling: defending clears on begin_turn (existing until-next-turn promise); reselecting Defend establishes a fresh waiting interval. Other buff durations unchanged.
- Final regression:415 gameplay checks/0fail, formula209/0, CT130/0, execution53/0. Asset94/HUD30/element9/Orren31/Vow23 pass; all-script load61 pass. Known missing icon/shutdown warnings remain separate.
- Deferred minor: stronger independent expected CT sequence/length/overflow fixtures (reviewer suggestion); existing tests compare 30-action projection/live scheduling plus explicit ready tie/backlog assertions.
- Explicit deferred: healing preview/raw execution mismatch and unsupported ability semantics. This pass does not claim all previews or all skills repaired.
