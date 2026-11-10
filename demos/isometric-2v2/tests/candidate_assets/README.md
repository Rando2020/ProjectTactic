# Opt-in candidate asset battle experiment

This is a **review fixture**, not promotion of artwork to the default game. All added code and PNGs are confined to this test folder. The original Unit scene, runtime manifests, default scene, combat rules, source candidates, and Pages deployment are unchanged. `stage.py` copies the standalone project to a **new** directory and switches only that copy's actor script and appends review-only HUD overrides. It also chooses a separate `ProjectTactic-CandidateReview` save namespace.

## Run with Godot 4.6.3

From the repository root:

```sh
python demos/isometric-2v2/tests/candidate_assets/stage.py /tmp/projecttactic-candidate-review
godot --headless --editor --path /tmp/projecttactic-candidate-review --import
godot --headless --path /tmp/projecttactic-candidate-review res://tests/candidate_assets/CandidateTest.tscn
godot --headless --path /tmp/projecttactic-candidate-review res://tests/candidate_assets/HollowDirectionTest.tscn
godot --headless --path /tmp/projecttactic-candidate-review res://tests/candidate_assets/FullMatchTest.tscn
godot --path /tmp/projecttactic-candidate-review res://prototypes/blooming/BloomingBattle.tscn
```

Use fresh XDG data/config/cache directories for automated tests. To make six real engine-rendered **posed diagnostic** captures, run `res://tests/candidate_assets/CaptureTest.tscn` with a graphical renderer. That test refuses headless rendering. These are not screenshots of a manual playthrough. The candidate-review workflow runs staging, all three contracts and graphical captures; its uploaded artifact needs visual inspection before acceptance.

## Art and behavior

- Kael: four independent idle directions from [#117](https://github.com/Rando2020/ProjectTactic/pull/117), with original body-height scales and foot pivots. No mirrored equipment. No candidate walk/melee animation exists, so procedural action presentation remains.
- Zane: four idle directions plus SE windup/release from [#118](https://github.com/Rando2020/ProjectTactic/pull/118). The source pack's lift/extend PNGs are retained, but this first integration maps only the engine's anticipation and release hooks. **It is not the standalone seven-segment 760ms animation.** Existing engine presentation timing remains authoritative.
- Hollow Stray (`storm_imp`): retained SW idle/windup/release from [#114](https://github.com/Rando2020/ProjectTactic/pull/114), plus independently generated NE/SE/NW idle candidates. All four idle directions now use the same identity. New source scales match the retained SW visible height (88.61px); per-view manual pivots keep the visible foot baseline within 0.16px of the origin. Cast poses still exist only for SW. If an optional idle row is absent, original artwork/transforms remain the defensive fallback. See [four-direction review](hollow-directions/README.md).
- Void Cultist stays unchanged. Portrait rail, active-unit and forecast portraits use crops of the actual candidate sources. The appearance setting is disabled and labeled Candidate art (review), because this staging mode does not implement skin switching. Void Cultist portraits remain unchanged.
- Logical N/E/S/W maps to screen NE/SE/SW/NW. Cast hooks are supported only for actual SE Zane or SW Hollow art. Unsupported casts retain idle art and existing generic effects.
- Existing source bytes are unchanged; the three new idle PNGs are added non-destructively. `source-hashes.json` is checked before staging. This fixture does not approve the art, clean edge alpha, fix inter-frame drift, or include proposed Ascended emblems or reconstructed Fire assets.

## Local engine evidence (2026-11-09)

- Focused actor contract: **110 checks, zero failures**, including source texture identity, four-direction mapping, scale/pivot, unsupported-facing restoration, resource invariance, release/recovery and cancellation cleanup.
- Test-first baseline: 3 missing-adapter failures. Cancellation regression: 2 failures before repair. Independent review found a real stale-Hollow-facing defect; rendered texture/transform assertions failed before restoration was implemented.
- Full match: **99 checks, zero failures**, 11 decisions, two Fire casts, both allies moving, real enemy AI actions, both enemies defeated, victory, duplicate Replay press creating one battle, and a fresh confirmed move after replay. Saved campaign progress remains unchanged. Commands drive real selection/review/confirm logic; this is automated engine integration, not physical mouse play.
- A texture observer recorded actual Zane and Hollow candidate windup/release textures during this match, not merely source decoding or standalone animation tests.
- Local graphical capture is **blocked**: Xorg cannot create listening sockets. No local in-engine visual acceptance, browser/mobile/audio/performance acceptance is claimed.
- Existing compact-skin contract fails on the deliberately staged candidate override because it asserts original compact paths, frame sizes and anchors. The normal unmodified project is not switched. Broader regression results are reported in `evidence/`; do not describe the entire suite as green.

## Remaining gates

Inspect graphical artifact captures at gameplay size, review foot placement/occlusion/style and the deliberately incomplete facing/animation coverage, then implement complete compatible assets before any production promotion. No merge or live deployment is part of this experiment. Keep the PR draft.
