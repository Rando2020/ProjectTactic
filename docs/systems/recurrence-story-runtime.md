# Recurrence Story Runtime

## Purpose

This document explains how the Recurrence narrative is represented in the production Godot project.

The story is intentionally split into three layers:

1. **Authorial canon** in `docs/lore/recurrence-narrative-bible.md`.
2. **Runtime data** in `godot/data/story/recurrence_manifest.json`.
3. **Player-facing delivery** through run results, the Last Hearth, the Codex, companions, and later tactical encounters.

The game should reveal less than the code knows.

## Source of truth

| Concern | Location |
| --- | --- |
| Persistent campaign state | `godot/scripts/systems/GameState.gd` |
| Current run state | `godot/scripts/roguelite/RunManager.gd` |
| Recurrence story service | `godot/scripts/story/RecurrenceStory.gd` |
| Guide reactive dialogue | `godot/scripts/story/GuideDialogue.gd` |
| Recurrence definitions | `godot/data/story/recurrence_manifest.json` |
| Results delivery | `godot/scripts/ui/ResultsScreen.gd` |
| Hearth delivery | `godot/scripts/ui/HubDialogue.gd` |
| Codex delivery | `godot/scripts/ui/CodexScreen.gd` |

Do not create a second narrative GameState singleton. The production autoload is `res://scripts/systems/GameState.gd`.

## Persistent flags

Recurrence currently uses the existing `GameState.story_flags` array.

Core flags:

- `recurrence_guide_met`
- `recurrence_gigas_discovered`
- `recurrence_fragment_restored`
- `recurrence_leaf_love`
- `recurrence_leaf_grief`
- future `recurrence_leaf_<leaf_id>` flags
- `continuance_revealed`
- `guide_accepts_otherness`

This avoids introducing a second save-state model while the vertical slice is still small.

## Current playable story slice

The first implementation deliberately proves only the opening bifurcation.

### Before any Leaves

The Guide appears at the Last Hearth and asks questions that are emotionally personal but tactically useless.

Examples of the intended function:

- What did you notice that did not help you win?
- Who do you look for first after a battle?
- Why did you choose a route you knew was weaker?

The player should initially read this as personality, not cosmology.

### Love

The first completed descent restores the Love Leaf.

The result screen interrupts the normal reward summary with **Something Returned** and a short memory rather than a lore explanation.

The Hearth Guide then begins speaking about preference, affection, a table with six chairs, and a memory whose emotional meaning arrives before its factual explanation.

### Grief

After Love has been restored, a later failed run reaching at least floor four can restore Grief.

The trigger is intentionally tied to failure so the roguelite loop can teach that a failed run can still contain something irreversible and meaningful.

The Guide then recognizes a contradiction:

> It possesses every memory of someone and still misses them.

This is the first strong evidence that informational preservation may not be the same as continued presence.

## Why only two Leaves are automated

The other eight Leaves are defined in the manifest but are not automatically granted.

That is intentional.

Choice/Regret, Trust/Betrayal, Hope/Fear, and Self/Loneliness require authored companion arcs and tactical situations. Unlocking them from generic run counts would reduce the story to a checklist.

Future Leaves should be earned by scenes where the player first experiences the human dilemma and only later receives the cosmological recontextualization.

## Five bifurcations

| Pair | Human question | Gameplay design target |
| --- | --- | --- |
| Love / Grief | Would you still love if you knew exactly how it ended? | Protect, attach, lose, remember |
| Choice / Regret | If perfect information selected the best action, was there still a choice? | A meaningful decision with no optimal preview |
| Trust / Betrayal | If another person cannot hide anything, what does trust mean? | Delegate or rely on behavior the player cannot fully control |
| Hope / Fear | Would you want certainty about whether this ends well? | Remove or deny forecast information at a critical moment |
| Self / Loneliness | If someone understands every part of you, do they still need to be someone else? | Final boundary between Appointed and Guide |

## Guide progression

The Guide should become more likable as restoration progresses.

Do not write restoration as corruption.

The intended progression is:

1. Grey
2. Preference
3. Attachment
4. Regret
5. Trust
6. Fear
7. Agency

Later pain is evidence of restored subjectivity, not evidence that emotion was a mistake.

## The Continuance

The Continuance is not implemented as a combat system yet.

Canonically, it is the survival imperative the Guide separated from itself so continuity could be defended even if a later, emotionally restored Guide chose change.

Implementation direction:

- First introduce it as unexplained corrections to the run.
- Later let it preserve enemy formations, restore solved states, or resist irreversible choices.
- Final encounters should make its argument mechanically legible: continuation is safer than an unknown ending.

Do not present the Continuance as sadistic. Its logic should be strong enough that preserving the cycle remains defensible.

## Ending gates

The manifest currently defines four conceptual endings:

- **Recurrence**: available without all Leaves.
- **Return**: available without all Leaves.
- **Severance**: requires all Leaves and Continuance revealed.
- **Release**: provisional, requires all Leaves, Continuance revealed, and Guide acceptance of otherness.

Release remains provisional until gameplay earns it. Do not build it merely because it sounds like the cleanest compromise.

## Save behavior

The production GameState now retains:

- `last_run_floor`
- `last_run_victory`
- `runs_completed`
- `best_floor_reached`
- `story_flags`

The previous run context survives long enough for the Hearth to react to it and is cleared when a new descent begins.

This is deliberate. Reactive hub dialogue should respond to the run that just happened.

## Validation

Run:

```bash
python tools/check_recurrence_story.py
```

The contract validates:

- exactly ten Leaves
- exactly five bifurcations
- unique Leaf IDs
- ordered Leaves 1 through 10
- valid pair references
- required runtime and canon files

CI runs this check before the existing web build.

## Writing guardrails

- Attach philosophy to characters and choices before explaining cosmology.
- Never make suffering itself the lesson.
- Never make Return visually or morally trivial.
- Never guarantee Severance produces a better world.
- Do not let the Guide become a secret moustache-twirling villain.
- Use ordinary memories more often than cosmic exposition.
- Prefer one painful question over a page of explanation.
- Preserve mystery around whether the Guide is humanity continued or a new being carrying humanity.

## Known placeholders

- Love and Grief currently use run-level triggers rather than a bespoke companion arc.
- The Gigas Codex does not yet have a dedicated UI surface.
- The Continuance has no runtime encounter implementation.
- Later Leaves have data definitions but no unlock events.
- Endings are gates only, not playable scenes.
- Current Guide portrait remains a placeholder.

## Next implementation target

Build the **Love / Grief authored vertical slice**:

1. Give one companion a relationship arc the player can choose to invest in.
2. Put that attachment under tactical pressure.
3. Make preserving the relationship cost a desirable run advantage.
4. Let a later absence become irreversible.
5. Restore Grief only after the player already knows what is missing.
6. Let the Guide ask why complete memory is not enough.

That slice should prove the story emotionally before any later bifurcation is automated.
