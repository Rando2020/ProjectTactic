# History Cycle Cast Guide

> **Canon status: Act I surface layer.** The Concord, First Breach, Guardian pain, and regional history-cycle conflicts remain active story material. They are the human-scale political interpretation of Recurrence, not the final cosmological explanation. Characters should be allowed to believe these local explanations for a long time.

## Narrative North Star

Vaelthar is not telling a simple save-the-kingdom story. The stronger spine is:

> The ancient war did not end. It was buried inside the rules of civilization, and now every region is unknowingly reenacting it.

The core conflict is not only Guardian corruption or Void Anchors. Those are the visible symptoms. The deeper wound is the Concord: a survival treaty that preserved the world by erasing the people, Guardians, and records that made the survival possible.

## Act I Central Question

When a truth threatens the structures keeping people alive, what are people willing to preserve, expose, or destroy?

This question should work before the player knows anything about the Guide or the Ten Leaves. Later revelations should deepen these conflicts rather than invalidate them.

## Character Design Rule

Every major character should represent one response to repeated history.

| Character | Cycle Role | What They Believe | Why They Are Dangerous |
|---|---|---|---|
| Zane Vale | The Listener | Pain should be heard before it is judged. | He can become a martyr by confusing empathy with obligation. |
| Mira Vey | The Witness | Proof matters because power edits grief into rumor. | She can wait for proof until intervention is too late. |
| Captain Rusk | The Preserver | Order keeps civilians alive when truth starts fires. | He can defend rotten systems because collapse is terrifying. |
| Elian Crowe | The Destroyer | Anything built on erasure deserves to fall. | He can punish people for being born inside the lie. |
| Serra Valecourt | The Inheritor | A corrupt inheritance can be redeemed through duty. | She can seek redemption without surrendering the power she inherited. |
| Caldus Veyr | The Weaponmaker | Suffering becomes acceptable when converted into infrastructure. | He can make cruelty look practical, stable, and necessary. |

## Why This Works For A Tactical RPG

The story theme should show up in systems, not just dialogue.

| Theme | Tactical Expression |
|---|---|
| Listening versus killing | Resonance Windows where saving a Guardian changes rewards and future encounters. |
| Witnessing versus erasure | Objectives to rescue civilians, preserve ledgers, protect defeated enemies, or recover archive fragments. |
| Order versus truth | Defense missions where following orders is safer but morally compromised. |
| Destruction versus liberation | Sabotage missions that weaken institutions but may reduce local trust or cause collateral loss. |
| Privilege versus restitution | Noble access opens shortcuts, restricted archives, and elite deployment options, but costs reputation or forces public sacrifice. |
| Weaponized pain | Void Anchor encounters where the enemy is stronger because someone optimized suffering into a combat system. |

## Recommended First Act Character Flow

### 1. Ashvale Crossing

Primary characters: Zane, Mira, Rusk, Soren, Elian.

Story function:
- Establish Guardian pain as real.
- Establish that the shrine bell is not only broken, but finally honest.
- Introduce Elian as a destabilizing truth-teller who is not safe, polite, or fully wrong.

Player feeling:
- The world is older than the town admits.
- The first victory should feel like opening a wound, not solving a crisis.

### 2. Mirefen Reach

Primary characters: Mira, Drowned Scholar, Reed Child.

Story function:
- Shift from hearing pain to preserving testimony.
- Make water, reflections, and delayed images reinforce memory distortion.
- Give Mira evidence that the Concord erased witnesses, not only monsters.

Player feeling:
- The world remembers what institutions buried.
- Proof can be sacred without being religious.

### 3. Stormglass Bastion

Primary characters: Rusk, Serra, Marshal Kael, Glasswright Theo.

Story function:
- Show how the old war became discipline, academy doctrine, and command hierarchy.
- Introduce Serra as useful and uncomfortable.
- Make the player benefit from systems that may be morally compromised.

Player feeling:
- The enemy is not just outside the walls.
- Some walls are made from old victories stolen from unnamed people.

## Long-Term Cast Tensions

### Zane and Elian

Zane believes hearing pain creates obligation. Elian believes pain that has waited centuries has already earned the right to burn things down.

Best conflict:
- Elian accuses Zane of turning every wound into a conversation.
- Zane accuses Elian of turning every witness into fuel.

### Mira and Caldus

Both are practical. Both distrust vague prophecy. That is why they should frighten each other.

Best conflict:
- Mira heals people one body at a time.
- Caldus stabilizes populations by converting bodies into data, anchors, and repeatable systems.

### Rusk and Serra

Both understand duty. Both were trained to preserve structure.

Best conflict:
- Rusk protects people because he has seen what panic does.
- Serra protects institutions because she has been told institutions are people at scale.

## Best Practice

Keep the ancient lore discoverable through battlefield consequences:
- Post-battle records.
- Codex unlocks.
- Town NPC line changes.
- Mission bonus objectives.
- Recruitable character arguments.
- Archive fragments tied to tactical choices.

## Pragmatic Workaround

Until full branching exists, use static data fields and codex entries to simulate story depth:
- `src/game/data/characterArcs.js`
- `src/game/data/party.js`
- `src/game/data/towns.js`
- `src/game/data/codex.js`

This gives the prototype a stronger narrative identity without requiring a dialogue tree, relationship system, or branching quest engine yet.

## Risks

1. The theme can become too abstract if every line says “cycle” or “history.” Let characters talk about bodies, bells, roads, orders, ledgers, and doors instead.
2. Elian can become cartoonish if he only wants destruction. He needs moments where his methods save people the polite characters would have abandoned.
3. Serra can become too sympathetic too quickly. Her privilege should remain mechanically useful and morally uncomfortable.
4. Caldus should not be evil for evil’s sake. He is scarier if his logic works in the short term.

## Relationship To The Deeper Recurrence Story

The Concord is not secretly irrelevant because a larger cosmology exists. It is evidence of the same human tendency at a scale the player can feel: known structures remain attractive because the alternative is uncertain.

Use these characters to keep the late mythology grounded:

- Rusk embodies the defensibility of preservation.
- Elian embodies the danger and necessity of rupture.
- Mira forces memory to remain accountable to evidence.
- Zane tests whether empathy becomes obligation or control.
- Serra asks whether inheritance can be transformed without pretending it never caused harm.
- Caldus demonstrates how compassionate goals become horrifying when optimization stops asking what a person is.

Do not let any of them become a mouthpiece for the final answer.

## Next Recommended Action

Build the first recruitable-character beat:

- Add an Ashvale side mission where Elian appears as an allied NPC sabotaging a Concord archive wagon.
- Objective split:
  - Protect civilians.
  - Stop the archive burning.
  - Defeat Null-touched escorts.
- Outcome:
  - Elian does not join immediately.
  - The player unlocks the Ashen Companies codex entry.
  - Zane and Mira disagree over whether Elian is a threat or a necessary witness.
