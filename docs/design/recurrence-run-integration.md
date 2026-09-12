# Recurrence Run Integration

## Goal

Translate the Recurrence narrative into playable structure so the player experiences the themes through tactical decisions, repeated runs, companion relationships, and progression rather than through exposition alone.

This document is intentionally implementation-facing.

## Core player experience

The game should train the player to value certainty.

The player learns:

- reliable builds
- damage ranges
- enemy intent
- route safety
- resource conservation
- strong job combinations
- encounter patterns
- known rewards

The story then gradually asks whether certainty is always worth what must be removed to obtain it.

The final narrative choice should feel connected to how the player has spent the whole game playing.

## Narrative loop

A run should broadly contain:

1. **Hub / Guide conversation**
2. **Route choice**
3. **Human-scale story encounter**
4. **Tactical battle**
5. **Companion or faction consequence**
6. **Boon / job / resource reward**
7. **Occasional Codex or fragment beat**
8. **Guide reaction based on restoration state**
9. **Boss or threshold event**
10. **Return, death, or progression into the next cycle layer**

The narrative system should avoid forcing lore after every battle. Silence and repetition are part of the pacing.

## Reveal cadence

### Runs 1-3: Establish attachment

Player belief:

The Guide is an unusual but benevolent run companion.

Player-facing content:

- Guide knows slightly too much
- Guide recognizes patterns from failed runs
- Guide uses the phrase "There you are"
- first references to a damaged Gigas Codex
- repeated ancient symbols appear in otherwise unrelated regions
- no direct explanation of Recurrence

Important rule:

Do not make the Guide suspicious yet. Make the Guide useful and emotionally safe.

### Runs 4-7: First fragment, first preference

Recommended first restored half: Love.

Unlock condition:

Complete a companion-centered route where the player chooses to protect a relationship at meaningful tactical cost.

Fragment effect on Guide:

The Guide rediscovers preference and affection.

Mechanical reward:

Unlock a modest persistent relationship-oriented benefit, such as improved rescue/revive support, bond gain, or a new camp interaction.

Guide behavior change:

The Guide asks about why the player chose a person over an optimized reward.

Example:

> "The northern cache contained more value."
>
> "I know why you went back for them. I do not understand why that answer feels different now."

### Runs 8-12: Grief completes the first pair

Unlock condition:

A companion consequence must be irreversible for that run. Avoid cheap mandatory death if possible. Loss can include departure, permanent wound, broken relationship, abandoned town, or chosen sacrifice.

Fragment effect on Guide:

The Guide becomes capable of absence.

Mechanical reward:

A powerful but limited remembrance mechanic, such as carrying one bond-linked passive from a lost companion into a future run.

Narrative danger:

Do not imply that the mechanic literally resurrects the person.

Guide beat:

> "I have their memories."
>
> "Why is that not enough?"

This is the first moment the player should feel that restoration may have consequences.

## Five pair arcs

Each bifurcation needs four layers:

1. a human relationship story
2. a tactical expression
3. a Guide transformation
4. a later cosmological reinterpretation

### Pair One: Love / Grief

Human story:

A companion forms an attachment they know may cost them strategically.

Tactical expression:

Protect, extract, or return for a vulnerable unit when retreat is objectively safer.

Guide transformation:

Preference, affection, then grief.

Later reinterpretation:

The Collective retained every memory of the people it "saved" and still discovered it could miss them.

### Pair Two: Choice / Regret

Human story:

The player must choose between two defensible outcomes. Neither can be preserved through perfect play.

Tactical expression:

Mutually exclusive objectives on the same battlefield.

Example:

- hold the bridge to protect civilians
- pursue the commander to prevent a future attack

The player cannot fully achieve both.

Guide transformation:

The Guide initially calculates which outcome was statistically superior, then later asks whether the player wishes they had chosen differently.

Mechanical integration:

Do not immediately reveal which route produces greater long-term value.

Later reinterpretation:

The Guide remembers its first intervention in Recurrence and discovers that explanation does not erase regret.

### Pair Three: Trust / Betrayal

Human story:

A companion or faction requests access, power, or strategic discretion the player cannot fully verify.

Tactical expression:

Give an AI-controlled ally autonomy, share a scarce resource, reveal a position, or accept an unknown deployment effect.

Important:

The trusted party must be capable of keeping or breaking trust for understandable reasons.

Guide transformation:

The Guide discovers that trust only exists where certainty ends.

Mechanical integration:

Introduce a system where some ally intents are deliberately hidden after the trust arc, not because the UI is worse, but because the player has chosen autonomy for that character.

Later reinterpretation:

The Appointed has always been the Guide's first genuine trust relationship.

### Pair Four: Hope / Fear

Human story:

The party pursues an outcome that cannot be guaranteed by current knowledge.

Tactical expression:

A mission with incomplete forecast information, shifting objectives, or a route whose reward cannot be previewed.

Use sparingly. Do not sabotage the game's normal readability.

Guide transformation:

The Guide experiences real fear for the Appointed.

Key question:

> "Would you want to know whether this ends well?"

Mechanical integration:

Offer the player optional prediction tools that reduce uncertainty at a cost. The strongest narrative path may require occasionally declining perfect information.

Later reinterpretation:

The ancient civilization progressively removed uncertainty until hope became expectation.

### Pair Five: Self / Loneliness

Human story:

The player is confronted with identity boundaries rather than simple affiliation.

Possible companion arc:

A character is offered perfect integration into a powerful group, faith, magical order, or ancestral network that would eliminate isolation but dissolve a meaningful part of their independent self.

Tactical expression:

A battle involving linked units that share damage, status, resources, or turns. Mechanically demonstrate both the strength and cost of total linkage.

Guide transformation:

The Guide recognizes that it is not simply humanity-at-scale. It is something new.

Later reinterpretation:

Humanity solved loneliness by removing the condition of being separate.

## Fragment acquisition model

Fragments should not be random drops.

Recommended structure:

- 2 fragments from companion arcs
- 2 fragments from major faction decisions
- 2 fragments from recurring boss/Continuance thresholds
- 2 fragments from Codex reconstruction milestones
- 1 fragment from a high-level optional challenge demonstrating mastery
- 1 fragment created by the player's final unforecastable choice

This prevents completion from becoming hidden-object busywork.

## The tenth fragment

The final fragment, Choice, should not exist as a collectible before the finale.

The player creates it through a decision no system can evaluate in advance.

Recommended UI behavior:

Normal late-game decisions show some combination of:

- projected consequences
- faction response
- tactical preview
- reward impact

The final choice deliberately does not.

Do not show percentage success, morality color, "true ending" iconography, or meta-achievement hints before commitment.

The absence of preview is itself the final mechanic.

## The Guide question system

Guide conversations should use a lightweight memory of player behavior.

Track narrative tags such as:

- prioritized_companion_over_reward
- abandoned_optional_rescue
- repeated_same_job_build
- accepted_unknown_route
- rejected_unknown_route
- trusted_faction
- betrayed_faction
- lost_companion
- spared_enemy
- chose_high_certainty_option
- chose_high_uncertainty_option

The Guide should ask about actual play rather than generic philosophy whenever possible.

Example:

If the player repeatedly chooses safe routes:

> "You prefer outcomes you can see."
>
> "I do not mean that as criticism. I think I preferred them too."

If the player changes from a reliable build to an unknown job:

> "You knew the old form would work. Why leave it?"

If the player reloads or repeats a route in a supported diegetic context:

> "You wanted a different answer badly enough to become someone who knew more. Is that still the same choice?"

Avoid shaming players for optimization. The game should implicate, not scold.

## Guide presentation changes

Narrative restoration should be visible without requiring exposition.

### 0-20%

- still posture
- concise speech
- minimal interruption
- neutral musical motif
- environment around Guide visually subdued

### 20-40%

- small preferences appear in hub decoration
- Guide interrupts itself occasionally
- humor becomes more specific
- individual instrument joins motif

### 40-60%

- Guide references individual memories
- more pauses and corrections
- emotional reactions before explanations
- environmental warmth and contrast increase

### 60-80%

- Guide may avoid certain Codex areas
- some conversations become unavailable immediately after fragment restoration
- music gains dissonant counter-lines rather than simply becoming darker
- Guide begins disagreeing with its own earlier statements

### 80-100%

- Guide asks player not to continue
- Continuance interference becomes overt
- Guide's speech becomes less authoritative and more personal
- Guide increasingly says "I" instead of "we"

Important:

The visual arc should read as increased specificity, not corruption.

## Continuance encounter language

The Continuance should be taught mechanically before being named.

### Early encounters

Enemies reset altered tiles.

Defensive formations reconstruct themselves.

A boss restores its original stance when moved.

The player experiences continuity as an annoying but understandable mechanic.

### Midgame

The same pattern appears across unrelated enemy cultures.

The player assumes reused ancient technology, divine law, or a hidden faction.

### Late game

The player learns these systems share a preservation mandate.

The Continuance can speak through inherited institutions, constructs, or preserved voices without needing one permanent humanoid avatar.

### Final encounter

The Guide may actively assist the Appointed while the Continuance resists.

Boss phases should represent preservation principles:

1. **Restore State**: battlefield reverts toward initial configuration
2. **Preserve Lineage**: defeated units return through successor units or inherited buffs
3. **Reject Novelty**: repeated player actions become increasingly resisted
4. **Fix Outcome**: Continuance attempts to lock future turn order or route state
5. **Finality**: player must commit to irreversible tactical sacrifices to break the system

The battle should make the player physically fight a system that refuses to allow irreversible change.

## Codex delivery

Do not use the Codex as a wall of lore text.

Each recovered portion should contain:

- one human marginal note
- one institutional statement
- one missing or damaged paired phrase
- one visual clue
- at most one explicit cosmological fact

Example early page:

Institutional text:

> Integration reduced bereavement instability by 63 percent across the northern districts.

Marginal note:

> Mara says this means I won't have to lose her. I haven't told her that I am more frightened of never missing her.

The marginal notes disappear from post-Convergence pages.

That absence should become meaningful before anyone explains it.

## Companion requirements

At least five major companions or recurring NPC arcs should embody the bifurcations without knowing the cosmology.

Do not make them simple theme mascots.

Each should contradict their assigned theme in some way.

Examples:

- Love / Grief character loves intensely but avoids commitment to prevent loss
- Choice / Regret character appears decisive but cannot forgive one past choice
- Trust / Betrayal character is honest but controlling because they cannot tolerate uncertainty
- Hope / Fear character is publicly optimistic but privately obsessed with prediction
- Self / Loneliness character is fiercely independent and secretly desperate to disappear into belonging

The cosmological reveal should make the player realize the entire world has been living smaller versions of the same problem.

## Boss storytelling rule

Major bosses should not explain the thesis before battle.

Their mechanics should embody their worldview first.

Dialogue after or during phase transitions may then name what the player has already experienced.

Example:

A preservationist boss repeatedly restores fallen allies.

Only after the player has experienced the frustration does the boss say:

> "You keep calling death a consequence. I call it a failure of maintenance."

This is stronger than opening with a monologue about mortality.

## Ending unlock logic

### Return availability

Available before all fragments are restored.

The player can choose it while still believing restoration is the intended goal.

### Recurrence availability

Available once the player understands the basic cycle and refuses Return.

### Severance availability

Requires nine recovered Leaves plus the final Choice event.

### Release availability

Provisional. Only include if the game provides enough mechanical groundwork for transformation rather than simply presenting it as a superior hidden answer.

If implemented, it should require evidence that the player repeatedly accepted bounded uncertainty rather than merely completing collectibles.

## Save/load and run persistence requirements

Narrative state should eventually persist at the account/save level rather than only within a run.

Recommended future fields:

```json
{
  "guide_restoration": {
    "love": false,
    "grief": false,
    "choice": false,
    "regret": false,
    "trust": false,
    "betrayal": false,
    "hope": false,
    "fear": false,
    "self": false,
    "loneliness": false
  },
  "guide_stage": 0,
  "codex_entries": [],
  "narrative_tags": [],
  "continuance_awareness": 0,
  "ending_flags": {
    "return_available": false,
    "recurrence_available": false,
    "severance_available": false,
    "release_available": false
  }
}
```

This is a design sketch, not a mandated final schema.

## Demo integration recommendation

Do not attempt the full mythology in the first playable demo.

Add only three narrative signals:

1. The Guide says "There you are" after a reset or return.
2. One optional Codex fragment contains an unexplained paired concept such as Love / [missing].
3. One battle mechanic associated with Continuance restores or resets a tactical state.

That is enough to establish narrative DNA without blocking the core combat loop.

## Acceptance criteria for future narrative implementation

A story feature is ready when:

- it works even for players who skip Codex text
- it changes or is expressed through play, not only dialogue
- it does not reveal later cosmology prematurely
- the Guide remains emotionally coherent at the current restoration stage
- the choice has a defensible opposing position
- the player can articulate what happened emotionally without needing to understand the full metaphysics
- existing combat remains readable and fair

## Recommended next implementation slice

Prototype **Love / Grief** only.

Minimum slice:

1. add one companion relationship beat
2. add one tactical objective that competes with optimal resource play
3. add one recovered Love fragment
4. change Guide dialogue after restoration
5. later in the same slice, add a loss or absence event that unlocks Grief
6. add a small persistent remembrance reward
7. add one Codex entry whose meaning changes after Grief

If this arc feels emotionally meaningful in play, the remaining bifurcations can scale from the same architecture.
