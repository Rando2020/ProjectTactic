# Progression speed safety
Base:938cb2e, isolated fix/progression-speed-safety. Scope: fix accidental permanent CT lockout, not class rebalance or silence behavior.

Policy approved by parent: actors configured with positive base speed retain at least1 after accumulated progression and Slow. Explicit nonpositive configured speeds preserve existing behavior. Stun/petrify use action/movement gates, not zero-speed assignment; no production stop status found. Preserve earned job history and all other bonuses; retain normal Haste/Slow rounding and Haste precedence.

Files: BattleScene.gd progression application, Unit.gd effective Slow speed, CharacterScreen.gd displayed progression speed, tests/test_progression_speed.gd/.tscn. Test actual Battle.tscn spawned Kael with mastered Warder800JP and level5Warder520JP, baseline and intermediate class cases; verify real TurnOrder activates/forecasts, Slow expires through owner turn, normal status rates unchanged, explicit0/negative speed unchanged, jobJP/current job unchanged.

RED first; minimal floor at the two boundaries; focused/CT/combat/playable regressions; separate commit and fresh independent review. No integration checkout, GUI or remote changes.


## Results
- Initial actual-spawn/status regression: 59 checks, 8 failures. Minimal runtime fix: 59 checks, 0 failures.
- Parent requested narrow CharacterScreen consistency: displayed speed vs actual spawn initially 64 checks, 1 failure (mastered Warder displayed 0 while actual speed was 1). Same positive-configured-speed floor added to displayed progression speed; 64 checks, 0 failures.
- Final gameplay: 415 checks, 0 failures; CT 130/0, combat formula 209/0, combat execution 53/0, Cancel/Move 17/0. Existing asset/HUD/element/Orren/vow suites and all-script load pass. Existing missing icons and resource shutdown warnings remain unrelated baseline limitations.
- No progression history/stat bonuses removed; no silence changes; no movement/incapacitation rules changed. Effective speed 1 is a safety floor, not a claim that mastered Warder pacing is balanced or visually accepted.
