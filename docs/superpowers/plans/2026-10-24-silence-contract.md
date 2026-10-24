# Symmetric Silence action contract
Base90cd78195eb000d8a0fa71a631d276c1753f7e15; isolated fix/silence-action-contract. Existing enemy planning/validation/execution ignores Silence; player blanket-blocks all abilities including physical. Preserve physical actions for both sides using one predicate keyed to existing spell_type == physical, not MP cost or type == buff/heal.

Files: BattleManager.gd validation/planning/selection/dispatch; tests/test_silence_contract.gd/.tscn; tools/check_playable_loop.py contract case list if appropriate.
- RED actual enemy Void Pulse intent/execution while silenced; stale intent after Silence; deterministic mid-presentation interruption before contact; healing and AoE rejection; no MP/HP/status/action consumption for rejected cast.
- RED player menu/selection retains physical Mighty Strike/Defend but rejects magical cast; enemy physical skills/basic attacks remain legal.
- GREEN shared Silence predicate used by player selection, enemy heal/lethal/best candidates and intent validation, single/area execution pre-admission and pre-MP contact. Preserve current valid-intent replanning: a rejected stale magical plan may become a separately announced legal physical/move action, never the forbidden cast. Propagate execution success to enemy action-used flag.
- Run focused, existing combat/CT/progression/input and full playable contracts. No duration, status expiry, anchor pulse special behavior, balance, support implementation, GUI or publication changes. Fresh parent review before integration.

## Explicit rules correction and evidence
Parent confirmed: Silence blocks ordinary magical abilities, including magical healing/buffs, not physical techniques/basic attacks/Defend, symmetrically. This intentionally corrects the prior player's blanket ability lock; it does not claim that old player semantics were unchanged. Classification uses normalized spell_type. An empty lookup is rejected; missing/unknown classification is never treated as a physical exception under Silence. No new per-ability balance exceptions were inferred. The special encounter Anchor pulse remains outside ordinary casting.

Existing stale-intent replanning is retained: a magical plan invalidated before execution may visibly replan into a legal physical or movement action. A cast invalidated during presentation returns false before MP/effects; enemy action-used state now reflects that false result. Existing turn driver/recovery/status expiry remain unchanged.

RED: 51 checks / 29 failures across real enemy planning, stale intent, single/chain/heal contact interruption, magical buff, missing/unknown classification and player physical eligibility. Strengthened final suite adds missing classification and real player physical/Defend execution: GREEN 58 / 0. Runner coverage RED 6 tests / 1 failure until new Silence scene added; GREEN 6 / 0.

Final aggregate runner exits 0 across 11 contracts: combat formula209, execution53, CT130, progression73, input17, Silence58, Kael113, terrain10 cycles, recovered assets15 assertions, UI2465, gameplay425 all pass. Other current asset/HUD/element/Orren/vow/script-load suites and Python tests pass. Known resource shutdown warnings remain reported; no new graphical acceptance or release claim.
