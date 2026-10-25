# Zane vs Storm Imp practice — bounded implementation evidence

Base: `2ecb820772a3b2d524e6ec97964fd1ec5d43033f`.

## Result
- New distinct title entry: **Practice: Zane vs Storm Imp**.
- Session-only `zane_duel` mode; Ashvale contains only Zane `(4, 5)` and the existing Storm Imp `(6, 5)`.
- Existing roster/stat/resource paths, real initiative, enemy AI, ordinary counters, sword and Fire rules are reused. No combat-core or asset changes.
- Both victory and defeat expose **Replay Fight** / **Return to Hearth**. Replays retain the original checkpoint and presentation flags; duel rewards and backend training mutation are disabled. Both full-party entries remain unchanged.

## Red → green
Tests were authored before product edits. The native case first failed because the real title lacked the new entry (2 checks / 1 expected failure). Narrow Python runner tests first failed in three cases because the new case was absent and could not enforce script/shutdown strictness.

Final focused verification:
- `godot --headless --path godot res://tests/test_zane_duel_practice.tscn` with isolated XDG data/config/cache: **179 checks, 0 failures**, no script/resource errors or exit leaks.
- Unchanged `test_zane_impact_showcase.tscn`: **84 checks, 0 failures**. Its source was not edited; original 4+3 roster and Lyra-first turn remain asserted.
- `python -m unittest tools.test_check_playable_loop -v`: **11 tests passed**. The new case is outside the legacy shutdown allowance and its script/resource errors fail the runner.
- `node tools/check_godot_stability.mjs --skip-godot`: passed, **19 existing warnings** (same baseline count).
- `git diff --check`: passed.

The new native case exercises the real title callback/scene transition, exact two-actor scene roster, natural fresh-profile Zane-first speed tie, legal move/cancel/adjacent sword, immediate Fire legality/12 MP cost/range/fan definition and single target resolution, in-flight command guards, actual enemy action/resolution, ordinary combat victory, both real results/replay paths, repeated clicks, immutable baseline/checkpoint, saved non-Fire loadout and earned stats, RunManager RNG/runtime restoration, and canonical save/settings bytes. Title and both terminal results buttons fit **1328×861, 1920×1080, and 3840×2160** at all four UI size preferences.

## Deliberate test boundaries and inherited behavior
- The win is obtained through normal commands/real combat. The sword test observes a real enemy response. Loss-results coverage uses a clearly labeled authoritative damage/objective fixture, as the existing full-party lifecycle test does. Passive waiting after a sword can win through normal 25% counters; neither counters nor rolls were modified to manufacture a natural loss.
- Existing practice detaches active_run and starts at normal maximum combat resources. Replay restores that original start; exit restores exact saved in-run HP/MP/armor, earned stats, loadout, story, and runtime state.
- The save-byte profile has already met the Guide. Restoration is also checked before Hearth entry: the ordinary first-ever Hearth visit may legitimately add its pre-existing Guide story flag; this feature does not suppress that story behavior.
- Reload state comparison normalizes JSON numeric representation, while disk bytes are compared exactly. No save-format migration is performed.
- The accelerated native harness explicitly stops its still-playing autoload audio voices at teardown, rather than allow the defeat sting to leak at process exit. No audio product code was changed.
- Headless checks do not certify visual quality, audible sound, browser performance, or native pointer play. Independent native GUI and separate duel-browser checks remain follow-up lanes. The complete legacy native aggregate is deferred to integration, not repeatedly rerun here.

No push, merge, deployment, GUI, credential, or configuration mutation was performed. Local-only freeze commits are authorized; remote publication still requires fresh approval.
