# Scout tradeoff verification — 24 October 2026

## Frozen scope

Base: `21f43db37ca4ad0fb9aa8cdfdca2fbf184906ef1`. Isolated branch: `scout-tradeoff-2026-10-24`. No publication, merge, deployment, GUI/browser exercise or changes to other checkouts.

- Quickstep preserves Scout/Lyra access and 5 MP. After moving, it spends the action and reopens one normal movement; it does not restore an attack, grant a speed/stat buff or apply a timed status. Ordinary Move/Wait ends the turn and ordinary next-turn reset restores the normal action economy.
- Reject early, acted, insufficient-MP, unequipped, other-target, enemy and secondary-hop use without spending. Revalidate active actor, turn, equipment and MP at contact. A transient turn serial distinguishes a new turn for the same actor; deleted-actor cleanup stores the actor ID before awaiting.
- Long Shot remains 60 power, 0 MP and 3–5 Manhattan tiles. Canonical fields take precedence over legacy aliases. Unknown IDs remain empty. Player range/preview/input and existing AI candidate/intent legality share normalized bounds; Long Shot primary admission/contact revalidates range.
- Range enforcement is intentionally **not** broadened to other skills or secondary AoE/chain targets. Story, CT rules, save schema, job history, access/costs, other skills, weapons/loot and enemy support planning remain unchanged.
- Button/hover/focus forecast states the MP/action tradeoff. Post-action movement/cancellation copy correctly offers Move/Wait, not a new attack.

## Test-first evidence

New real `Battle.tscn` contract: `godot/tests/test_scout_tradeoff.gd/.tscn`, registered in the existing isolated runner and its expected-contract set.

Observed RED → GREEN:
- Long Shot: 14 failures → canonical range, legal 3/5 versus illegal 1/2/6, real target clicks, AI candidates/intents, forecast/damage and stale contact all pass.
- Quickstep: 34 failures → action tradeoff, MP, eligibility, duplicates and asynchronous rejection pass.
- Extended input found cancellation copy and stale-highlight preview defects; both reproduced then corrected.
- Deleted caster at contact reproduced a freed-object property access; cleanup now uses the captured string ID.
- Visible forecast cost initially omitted MP although structured data included it; real UI-label regression caught it and the note now displays 5 MP.
- The previous playable smoke fixture assumed Quickstep could be used before moving. Its four failures were resolved by performing a real first move, retaining the original action-lock, no-self-damage, remaining-move and battle-continuation assertions. No production rule was relaxed for the test.

## Fresh results

`python tools/check_playable_loop.py`: all 12 contracts pass:
- Combat formula 209; combat execution 56; turn order 130; progression speed 73.
- Cancel/move input 17; Silence 58; **Scout tradeoff 116**.
- Kael presentation 113; terrain cleanup 10 cycles; recovered assets 15 assertions.
- UI readability 2465; playable loop 427.

Additional checks: validation-runner tests 6/6; static stability passes with 19 existing warnings; production scripts 65 loaded; narrative contract; Orren arc 31; HUD layout 30; Mira presentation 115; independent shared-rig comparator 2622.

The existing cancel/move and playable fixtures still print shutdown ObjectDB/audio-resource diagnostics; baseline reproduced these before edits. The new Scout contract exits cleanly with no script errors or resource warnings. Orren's existing script also prints an ObjectDB shutdown warning. No claim of GUI, browser, live deployment or broad encounter-balance acceptance.

Full command logs, RED evidence and execution ledger: `/workspace/shared/scout-choice-evidence/`. All 218 local LFS assets were hydrated only after SHA-256 matched the frozen base pointers; no asset changes are included.

## Independent review

Fresh read-only whole-slice code review found no Critical or Important issues. Reviewer did not rerun the engine. One non-blocking test-hardening suggestion remains: inject duplicate inputs explicitly during the recovery phase; current tests inject during anticipation and again after completion, while code retains the same resolving/action gates through recovery. No gameplay defect was identified.
