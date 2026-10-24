# Playable demo delivery contract

## Target

Deliver a desktop-browser vertical slice that a new player can open, understand and finish in roughly 10 to 15 minutes. Use the existing Godot implementation and original art. This is an acceptance target, not a claim that the current build passes it.

The loop is title, short instructions, deployment, tactical battle, rewards, one meaningful progression choice, second battle, clear ending, and replay. Continue must restore the documented encounter checkpoint. Defeat must offer a working retry.

## Bounded feature set

- Four complementary party roles: durable melee, ranged damage, offensive magic and support. Select existing implemented jobs after checking their abilities.
- Move and act in either order, visible legal targets, damage/healing forecasts, enemy turns and explicit wait/cancel controls.
- Two encounters that test different positioning decisions. Prefer reproducible existing encounters before authoring more content.
- One understandable job or ability upgrade with an observable combat effect.
- Existing terrain, character sprites, UI, music and effects. Fill missing functional assets only after auditing what exists. Each asset must communicate team, role, terrain, action or feedback consistently.
- Victory, defeat, retry, checkpoint persistence, mute and readable instructions.

Defer full campaign content, multiplayer, crafting, expanded job catalogs, mobile polish and advanced mechanics that do not support this slice. Hide or clearly mark incomplete abilities so the demo does not promise unsupported behavior.

## Working prompt

You are delivering the ProjectTactic playable demo. Inspect the current branch, repository instructions, this contract and the latest QA evidence before editing. Reuse completed work.

Select the highest-impact unmet acceptance item. Prioritize startup and hosting failures, crashes, progression blockers, misleading controls, tactical readability, balance, then cosmetic polish. State the player-visible outcome and the evidence that will prove it works. Implement the smallest complete change that achieves that outcome.

Use the existing engine and assets. Make routine reversible decisions independently. Batch independent inspections. Run focused checks after each change and the relevant integration suite at milestones; do not repeat unchanged checks without a reason. Do not build additional systems to avoid repairing existing ones.

After each milestone, record the commit, exact checks, observed failures, remaining blockers and next action. Distinguish implemented, automatically verified, browser verified and player accepted. Never substitute automated victories for a human playthrough or a successful export for a working deployment.

Continue until the acceptance checklist passes or an actual environment, authorization or user-design decision blocks dependent work. If blocked, finish independent work and report the precise blocker. Follow existing authorization boundaries. Use feature branches, do not commit to main, and do not merge without explicit authorization. Do not retry a rejected source-publication action through another transport.

## Acceptance checklist

- [ ] Hosted HTTPS URL loads the full game and assets in a supported desktop browser.
- [ ] Fresh browser storage can start the demo without developer tools or explanation from its author.
- [ ] Instructions and target previews make the first legal move and action discoverable.
- [ ] All four roles have at least one verified useful tactical action.
- [ ] A manual playthrough completes both encounters and the progression choice without a soft lock.
- [ ] Rewards are granted once; refresh and Continue preserve the checkpoint and progression.
- [ ] Defeat and retry work; a finished demo has an explicit replay path.
- [ ] At 1366 by 768, critical controls, unit identity, health and target highlights are readable.
- [ ] Music can be muted; missing assets and runtime script errors are absent.
- [ ] Deliver URL, concise controls, known limits and reviewable source changes.

## Current evidence and immediate queue

Read `delivery-ledger.md` for current source/build/deployment identifiers and verification results. Earlier startup/publication blockers were superseded by successful owner-private deployments. Practice retry and Kael melee poses are implemented; browser gameplay acceptance remains pending because the previous managed browser lacked WebGL2 and Secure Context. Automated tests and static asset inspection do not satisfy the manual acceptance checklist above.

Recovered mesh terrain is now integrated in opt-in practice. Next: assess gameplay rendering and repair one observed defect; when observation is unavailable, isolate the persistent shutdown resource warning as described in the ledger. Supported-browser/player comparison remains pending alongside independent implementation; do not expand the roster. Preserve the owner-private audience and respect the prior public GitHub publication rejection. No merge is authorized.


User direction on 2026-10-23: continue bounded independent implementation without screenshots. In-game practice comparison controls now support later feedback. Preserve the distinction between implementation/test evidence and pending visual acceptance; do not require screenshots for every next build milestone. Current priority and provenance live in delivery-ledger.md.

Current encounter art/flow pass adds one temporary training-path choice after practice victory and Windows/Linux packages. See the delivery ledger for exact provenance and pending graphical acceptance. Do not interpret export or headless checks as satisfying the manual-playthrough checklist.
