# Independent Skill Completion QA

Base: prototype 83954997; working changes under active implementation.
Godot: 4.6.3, headless source tests. No browser, phone, listening or native visual acceptance claim from this worker.

## Added tests
`prototypes/isometric/SkillCompletionLifecycleTest.gd/.tscn` exercises real Skirmish units (not legacy rig fixtures), player direct execution and validated AI dispatch for Thunderstrike, Void Pulse, Dark Breath, Shadow Mend, plus Mighty Strike and Defend. It checks exact MP, unchanged CT, one presentation owner, actual outcome count, capped healing, non-damaging guard, applied status labels/durations, recovery, all camera rotations, skin switching, and owner retirement. Interruption cases cover cancellation, duplicate input, actor KO, Silence and target removal; recoverable cases immediately retry and verify one spend/contact.

## Findings
- MISS/IMMUNE tail progress rewind reported to presentation worker; fixed using monotonic non-hit decay progress.
- Defend correctly presents GUARD / Until next turn, not implementation duration2; test aligned to semantic expiry.
- Empty-center Fire fan forecast lacked affected recipients; coordinator delegated fix to UI worker.
- HudTest compact forecast shrink assertion failed during first aggregate run; UI worker investigating. Do not call aggregate green until revalidated.

## Verified results so far
- FireReadabilityTest:123 passed.
- MeleeSheetTest:565 passed.
- Independent lifecycle:177 passed before final exact-duration assertions added; final aggregate rerun pending.
- CompactSkinTest:1009 passed.
- FireballSheetTest:589 passed.
- PortraitTurnTest:106 passed.
- ReadabilityTest:2452 passed.
- Legacy action clash:198 passed; combat execution56; combat formula209; Silence58; spell outcome184.
- Legacy spell outcome emits resource-leak cleanup warnings despite exit0; not a clean warning-free result.

Per-suite raw logs and independent-summary.tsv are beside this report. Final exported PCK verification belongs to coordinator after art/preview integration.

## Aggregate source result (03:49 UTC)
All 15 pre-existing active demo suites passed. HudTest's initial9-check run had1failure, then independent post-fix rerun passed9/9 with fixture unchanged. Remaining aggregate passes: Rotation382, Selection37, SkillBounds256, Skirmish73; Boot/Juice/SelectionGui/Music identity checks exit0. Fire/Melee tests are from the same implementation pass before final dark art (unchanged Fire/melee source).

New lifecycle test passed182/182 including exact status durations, target removal and immediate retry. Final integrated-dark-art rerun pending below. Mighty Strike fixture now explicitly uses existing guaranteed back-hit geometry to prevent random miss flakiness.

Six relevant legacy source suites passed: action clash198, combat execution56, combat formula209, Silence58, spell outcome184, Zane impact actions1452. The spell outcome suite reported cleanup resource leaks despite successful assertions; other sampled logs clean.

UI worker fixed the forecast sizing bug via hidden empty-content collapse and child-minimum-size relayout, without relaxing HudTest. Empty-area/Defend preview integration now owned and tested by UI worker.

Final integrated-art source lifecycle rerun: **182 checks, 0 failures, exit0**, clean log `independent-lifecycle-final.log` (03:49 UTC).

## Exact final2 packed regression
PCK SHA256 `be705b01cc63a4a9864b644d1e9cecbb94e173e626bc48094a75cb3be10474ee` stable before/after. All20 gameplay/frame/presentation suites plus exclusion check exit0. New SkillFeedback10, SkillPreview56, SkillCompletion182; existing15 all green. SkillPreview emits1resource cleanup warning despite assertions passing. Original-art directories and SkillVisualQA harness excluded. This pack is now superseded by a planned final3 cosmetic cancellation fix; final3 will be independently tested before delivery claims.

## Final3 exact exported-pack acceptance (04:01 UTC)
**21 suites + exclusions check:22/22 exit0**, executed with three independent Godot processes and one isolated XDG namespace per suite. PCK SHA256 `c7c058f6b9df7dfc1c5e617d9873e6d664508eda037cb3221df7c342096caafb` matches before/after.

- Existing15 demo suites all pass.
- SkillFeedback10, SkillPreview56, SkillCompletionLifecycle182 pass.
- ModularFrames, ModularPresentation105, ModularSyncCancel9 pass.
- Original art source directories and SkillVisualQA source/scene/remaps absent from exported pack.
- SkillPreview retains1-resource cleanup warning despite passing56 assertions. ModularSyncCancel also emits resource cleanup warnings despite9 assertions passing; lifecycle and main modular-presentation logs are clean.

All exact-pack logs/hash/exit summary: `skill-feedback-qa/final3-packed/`. Runner: `run-parallel-pack.py`. This is headless native execution of exported PCK, not browser/WebGL2/phone/audio listening evidence.
