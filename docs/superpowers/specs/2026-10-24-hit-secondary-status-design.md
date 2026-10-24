# Hit-based damaging secondary statuses

Base: c80a025930a7e27c6fc2def169b82b1e23d1e3f5 (tree a5667343e47548eaca8f51e36acb9f70ecc96e28). Later isolated correction, not a released checkpoint change.

## Intent and scope
A damaging ability's authored secondary status applies only if that recipient's actual CombatResolver outcome is not a miss. Misses still consume normal action and MP. A hit dealing zero damage (including elemental immunity) is still a hit. Preserve all damage/crit/armor/healing values, costs, timings, status duration/expiry, Silence admission, terrain/surface and boon behavior, and applied-outcome logs. Do not fix Quickstep or healing forecasts here.

## Source and approach
BattleManager's physical and magical branches currently apply statuses without inspecting their returned resolver outcome. Chain and area dispatch already funnel through these branches. Gate only the authored secondary application, using the existing outcome, with one shared AbilityDB predicate also used for ForecastCalculator's concise “On hit” wording. A second accuracy roll is rejected because it could disagree with damage; gating on positive damage is rejected because immunity is not a miss. Do not change the resolver or broad UI.

## Authored exceptions and decision
No explicit guaranteed-on-miss damaging debuff flag or description was found in AbilityDB. Buffs, heals and base-power-zero status actions remain outside this correction. Blaze Counter and Arc Counter have positive power but explicitly describe passive counters and carry `blaze_counter_ready` and `arc_counter_ready`. Parent approved preserving these two specific readiness effects, narrowly matched, not a suffix-based exemption. This does not claim passive counters work: no consumer of these ready statuses was found. Smoke Screen retains its existing resolver miss plus applied Blind behavior; that separate status-only outcome/log inconsistency is not corrected here.

## Verification
RED real player action flows for Pin Shot/Eagle Eye, Void Pulse, Blizzard mixed recipients and generic chain fixture. Assert actual outcomes, normal MP/action cost, no false status logs, support preservation, hit-with-zero-damage status and duration, and unchanged Fire ground ignition. Explicitly replace the two legacy status-on-miss assertions in the 184-check feedback suite, retaining all other feedback/cost checks. Run full existing aggregate, static validation, remaining script contracts and Python tests. No GUI, other-checkout source edits, publication, merge or deployment.
