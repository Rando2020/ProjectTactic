# Cancel → Move input-flow regression
Baseline approved combat fd4f2f4. Native UI-only candidate9d5fbeb observed Lyra Long Shot→grey Cancel→Move retains purple CAST tiles. Diagnose with real Battle scene, actual UI callback readiness and legal move targets before changing production.

Files: BattleManager.gd command transitions, BattleUI.gd cancel readiness; tests/test_cancel_move_input.gd/.tscn. No battle math, range, movement cost or timing changes.
1. RED: choose Ability/Long Shot via actual UI; Cancel must be enabled, callback clears selection/highlights without MP/action/movement loss. Switching targeting directly to Move must clear old ability range and selection. Selected legal move must execute via grid signal, while illegal native(2,4) stays rejected if outside move range.
2. GREEN: publish command state after selection, derive Cancel eligibility independently of nonexistent confirm-pending flow; clear obsolete highlights/selection when switching commands.
3. Run focused and415 gameplay regressions, commit separately and ask parent for fresh review/native replay. Preserve approved math base. No visual acceptance inferred from headless assertions.

Evidence: native(2,4) is not a legal initial Lyra move. Lyra(0,7) legal range is(0,6),(0,5),(0,4),(1,5),(1,4),(2,5); real legal input moved correctly even before fix. Actual defects were Cancel disabled by stale confirmation-state gating and persistent purple highlights on direct command switch.
RED14checks/5fail; additional ability-menu cancellation RED17/1; GREEN17/0. Final gameplay415/0, combatexecution53/0, formula209/0, CT130/0; existing asset94/HUD30/element9/Orren31/Vow23 andscriptload61 pass. Known baseline missing assets/audio shutdown warnings unchanged. No changes to movement costs, legal destinations, action timing, or approved combat rules. Native graphical replay and fresh code review remain separate parent gates.
