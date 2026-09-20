# Recurrence Story Runtime

## Purpose

This document explains how the Recurrence narrative is represented in the production Godot project.

The story is split into three layers:

1. **Authorial canon** in docs/lore/recurrence-narrative-bible.md.
2. **Runtime data** in godot/data/story/.
3. **Player-facing delivery** through the run map, Last Hearth, Codex, companions, results, and later tactical encounters.

The game should reveal less than the code knows.

## Source of truth

| Concern | Location |
| --- | --- |
| Persistent campaign state | godot/scripts/systems/GameState.gd |
| Current run state | godot/scripts/roguelike/RunState.gd |
| Run lifecycle | godot/scripts/roguelite/RunManager.gd |
| Recurrence story service | godot/scripts/story/RecurrenceStory.gd |
| Orren relationship service | godot/scripts/story/OrrenArc.gd |
| Guide reactive dialogue | godot/scripts/story/GuideDialogue.gd |
| Recurrence definitions | godot/data/story/recurrence_manifest.json |
| Orren authored content | godot/data/story/orren_arc.json |
| Run-map delivery | godot/scripts/ui/StageSelect.gd |
| Hearth delivery | godot/scripts/ui/HubDialogue.gd |
| Codex delivery | godot/scripts/ui/CodexScreen.gd |
| Run result delivery | godot/scripts/ui/ResultsScreen.gd |

Do not create a second narrative GameState singleton. The production autoload is res://scripts/systems/GameState.gd.

## Persistent flags

Recurrence uses the existing GameState.story_flags array.

Core Recurrence flags include:

- recurrence_guide_met
- recurrence_gigas_discovered
- recurrence_fragment_restored
- recurrence_leaf_love
- recurrence_leaf_grief
- future recurrence_leaf_<leaf_id> flags
- continuance_revealed
- guide_accepts_otherness

The opening authored companion slice additionally uses:

- met_orren
- orrens_waited
- orrens_expected
- orrens_last_seen
- orrens_absent
- orrens_declined_wait

This keeps the vertical slice inside the existing save model instead of introducing a parallel narrative store.

## Current playable story slice

The opening bifurcation is now earned through Orren of the Lower Stair rather than generic run completion.

### Before any Leaves

The Guide appears at the Last Hearth and asks questions that are emotionally personal but tactically useless.

Examples of the intended function:

- What did you notice that did not help you win?
- Who do you look for first after a battle?
- Why did you choose a route you knew was weaker?

The player should initially read this as personality, not cosmology.

### Orren stage 1: usefulness

The first Orren encounter is transactional.

He offers:

- gold through a marked route; or
- JP through training.

The player learns the green lantern and silver map case before being asked to care about the person carrying them.

### Orren stage 2: cost

On a later encounter, Orren is carrying a wounded stranger.

The player may take the useful route and receive gold or stay to help.

Staying gives:

- no immediate reward;
- party MOVE -1 for the rest of the descent;
- relationship progression.

The movement cost is explicit before selection.

The penalty is stored as RunState.story_move_penalty and applied directly by BattleScene to real unit movement. It is intentionally separate from generic curses.

Declining the sacrifice does not permanently fail the relationship. The same gate can appear on a future Orren encounter.

### Orren stage 3: attachment

After the player has paid the tactical cost, the next meeting contains no emergency and no listed reward.

Orren makes bad tea, talks about a sea he barely remembers, and admits that he draws coastlines into maps that do not need them.

The player can choose to sit with him.

That restores **Leaf I: Love**.

Love therefore means the creation of expectation and attachment, not romance and not a run milestone.

### Orren stage 4: expectation

The next meeting is deliberately ordinary.

Orren is already waiting. He corrects a map, complains about tea, and promises to show the player "the door that opens backward" next time.

The player tells him they will look for the lantern.

No tragedy occurs.

This scene exists because Grief requires a future the player has begun to assume.

### Orren stage 5: absence

A later Wanderer node contains the same stair but not Orren.

The player finds:

- no green lantern;
- no body;
- no blood;
- no departure mark;
- the silver map case;
- a route line that stops halfway through a mark.

The player takes the map case.

That restores **Leaf II: Grief**.

The story does not confirm Orren's death.

The important event is that the player knew where he was supposed to be.

### Orren stage 6: continuation without replacement

Future Wanderer nodes do not replay the empty-stair scene.

Someone else may copy an Orren route mark incorrectly. The route still works.

This lets the game demonstrate a central distinction:

A useful pattern can survive a person.

That does not make the pattern the person.

## Guide progression through the slice

Before Love, the Guide notices that the player accepted tactical inefficiency to carry someone else's weight.

After Love, the Guide notices that the player looks for Orren's lantern before reading the route.

After Grief, the Guide remembers every detail of Orren and still cannot answer where he is now.

The Guide becomes more sympathetic as restoration progresses.

Do not write restored emotion as corruption.

## Hearth progression through the slice

Sera, Varn, and Volant also react to Orren.

This keeps the relationship grounded in the social world.

After the empty stair:

- Sera leaves out a fourth cup.
- Varn refuses to treat absence as proof, while refusing to call the scene normal.
- Volant is disturbed by an archive record that ends mid-sentence.

## Why the Leaves are not run-count unlocks

RecurrenceStory.record_run_outcome no longer restores Love or Grief automatically.

That is deliberate.

A Leaf should return only after the player has experienced its human problem in play.

Choice / Regret, Trust / Betrayal, Hope / Fear, and Self / Loneliness should follow the same rule.

Do not turn the Ten Leaves into a checklist.

## Five bifurcations

| Pair | Human question | Gameplay design target |
| --- | --- | --- |
| Love / Grief | Would you still love if you knew exactly how it ended? | Attach, expect, lose access, remember |
| Choice / Regret | If perfect information selected the best action, was there still a choice? | A meaningful decision with no optimal preview |
| Trust / Betrayal | If another person cannot hide anything, what does trust mean? | Delegate or rely on behavior the player cannot fully control |
| Hope / Fear | Would you want certainty about whether this ends well? | Remove or deny forecast information at a critical moment |
| Self / Loneliness | If someone understands every part of you, do they still need to be someone else? | Final boundary between Appointed and Guide |

## The Continuance

The Continuance is not implemented as a combat system yet.

Canonically, it is the survival imperative the Guide separated from itself so continuity could be defended even if a later, emotionally restored Guide chose change.

Implementation direction:

- first introduce it as unexplained corrections to the run;
- later let it preserve enemy formations, restore solved states, or resist irreversible choices;
- final encounters should make its argument mechanically legible: continuation is safer than an unknown ending.

Do not present the Continuance as sadistic. Its logic should be strong enough that preserving the cycle remains defensible.

## Ending gates

The manifest currently defines four conceptual endings:

- **Recurrence**: available without all Leaves.
- **Return**: available without all Leaves.
- **Severance**: requires all Leaves and Continuance revealed.
- **Release**: provisional, requires all Leaves, Continuance revealed, and Guide acceptance of otherness.

Release remains provisional until gameplay earns it.

## Save behavior

The production GameState retains:

- last_run_floor
- last_run_victory
- last_run_death
- runs_completed
- best_floor_reached
- story_flags

The active RunState includes:

- story_move_penalty

The previous run context survives long enough for the Hearth to react to it and is cleared when a new descent begins.

The Orren movement burden exists only for the current descent and resets with a new RunState.

## Validation

Run the data contract:

```bash
python tools/check_recurrence_story.py
```

Run the Godot story test:

```bash
godot --headless --path godot --script res://tests/test_orren_arc.gd
```

The full Godot validation workflow also:

- imports the project with Godot 4.6.2;
- loads every production GDScript;
- runs the Orren state progression test.

## Writing guardrails

- Attach philosophy to characters and choices before explaining cosmology.
- Never make suffering itself the lesson.
- Never make Return visually or morally trivial.
- Never guarantee Severance produces a better world.
- Do not turn the Guide into a secret villain.
- Use ordinary memories more often than cosmic exposition.
- Prefer one painful question over a page of explanation.
- Preserve uncertainty around whether the Guide is humanity continued or a new being carrying humanity.
- Do not confirm Orren's death merely to make Grief easier to explain.

## Known placeholders

- Orren currently uses text-only presentation and no portrait.
- The current route generator can surface multiple Orren stages within one descent, which may compress pacing.
- The Gigas Codex does not yet have a dedicated presentation surface.
- The Continuance has no runtime encounter implementation.
- Later Leaves have definitions but no authored unlock arcs.
- Endings are gates only, not playable scenes.
- The Guide portrait remains a placeholder.

## Next implementation target

Playtest the Love / Grief slice for pacing.

The key question is not whether the flags work. The key question is whether players begin looking for the green lantern before the game removes it.

If progression is too fast, add a minimum run-separation rule between:

- orrens_expected;
- orrens_last_seen;
- orrens_absent.

Only after that emotional pacing is convincing should the game begin implementing Choice / Regret.
