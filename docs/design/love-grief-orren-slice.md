# Love / Grief Vertical Slice: Orren of the Lower Stair

## Purpose

This slice proves the first Recurrence bifurcation through play before the game explains it through cosmology.

The player should not receive Love because a run counter reached a threshold. The player should first learn to expect a particular person.

The player should not receive Grief because a character is killed in a cutscene. The game should first create a routine, then interrupt it.

## Character choice

Orren is already part of the production run map as a recurring Wanderer.

That makes him ideal for the slice:

- he already appears between tactical encounters;
- repeated runs naturally make recurrence visible;
- he can be useful before he becomes important;
- helping him can cost run efficiency without requiring a bespoke battle map;
- his disappearance does not remove a core party role or damage combat balance.

Love here is attachment, not romance.

## Emotional sequence

### 1. A Lantern at the Lower Stair

The player first experiences Orren as a useful system.

He offers either gold through a safer marked route or JP through training.

Design purpose:

- establish a familiar green lantern;
- establish the silver map case;
- establish that Orren remembers choices;
- give the player a reason to select Wanderer nodes.

No Leaf is restored.

### 2. Someone Else's Weight

Orren is found carrying a wounded stranger.

He can carry the stranger or his map case, not both.

The player can take the useful route and receive gold, or stay and help.

If the player stays:

- no immediate reward is granted;
- the entire party receives MOVE -1 for the rest of the current descent;
- the relationship advances.

This consequence is shown before confirmation.

The point is not to reward altruism secretly. The point is for the player to knowingly choose a worse tactical state because a person has started to matter.

If the player declines, the relationship does not fail permanently. Orren can ask again on a later encounter.

### 3. One Minute

After the player has paid a real cost, the next scene contains no emergency.

Orren makes bad tea.

He talks about a sea he barely remembers and admits that he keeps drawing coastlines into maps that do not need them.

There is no listed reward.

The only option is to sit until the lantern gutters.

This restores **Leaf I: Love**.

The design test is simple: the player should understand why they clicked the button without needing currency, XP, or an unlock attached to it.

### 4. The Door That Opens Backward

The next meeting is intentionally ordinary.

Orren corrects a mark, complains about tea, and promises:

> "Next time, I will show you the door that opens backward."

The player tells him they will look for the lantern.

Nothing bad happens.

This scene exists because Grief requires expectation. If the game removes Orren immediately after Love, the structure feels authored instead of lived.

### 5. The Empty Stair

A later Wanderer node contains the stair but not Orren.

There is:

- no green lantern;
- no body;
- no blood;
- no departure mark;
- a silver map case;
- a route line that stops halfway through a mark.

The game does not confirm death.

The player takes the map case.

This restores **Leaf II: Grief**.

The crucial fact is not that Orren is dead. The crucial fact is that the player knew where he was supposed to be.

### 6. Someone Else's Mark

Future Wanderer nodes do not replay the grief scene.

Another traveler may copy one of Orren's marks incorrectly. The route can still work.

This lets the game state the distinction mechanically:

A useful pattern can survive a person.

That does not make the pattern the person.

## Guide response

Before Love, the Guide notices that the player accepted a tactical penalty to carry someone else's weight.

After Love, the Guide notices that the player looks for Orren's lantern before reading the route.

After Grief, the Guide can remember every detail of Orren and still confront the fact that memory does not answer where he is now.

The Guide's development should remain sympathetic. It is learning a capacity it did not possess, not being infected by emotion.

## Hearth response

Sera, Varn, and Volant also react to the arc.

This is important because the loss should not exist only between the player and a metaphysical narrator.

After the empty stair:

- Sera leaves out a fourth cup.
- Varn refuses to call absence a conclusion, while refusing to pretend the stair looked normal.
- Volant is disturbed by a record that ends mid-sentence.

## Tactical implementation

The authored sacrifice uses RunState.story_move_penalty.

This is separate from generic curses so the cost cannot silently become inactive if curse aggregation changes.

BattleScene applies the penalty directly to player unit move for the rest of that descent.

The field is serialized in RunState.to_dict() and RunState.from_dict().

## State flags

- met_orren
- orrens_waited
- orrens_expected
- orrens_last_seen
- orrens_absent
- orrens_declined_wait
- recurrence_leaf_love
- recurrence_leaf_grief

## Source files

- godot/data/story/orren_arc.json
- godot/scripts/story/OrrenArc.gd
- godot/scripts/ui/StageSelect.gd
- godot/scripts/story/GuideDialogue.gd
- godot/scripts/ui/HubDialogue.gd
- godot/scripts/ui/CodexScreen.gd
- godot/scripts/battle/BattleScene.gd
- godot/scripts/roguelike/RunState.gd
- godot/tests/test_orren_arc.gd

## Acceptance criteria

The slice is complete when:

1. The first Orren meeting remains practically useful.
2. The second relationship gate clearly offers a valuable route versus a MOVE -1 sacrifice.
3. Choosing the sacrifice changes actual player movement in battle.
4. Declining the sacrifice does not permanently lock the story.
5. Love cannot restore before the player has paid the relationship cost.
6. Grief cannot restore before Love and the final ordinary meeting.
7. The empty stair contains no confirmed death.
8. Future Wanderer nodes do not replay the empty-stair reveal.
9. Guide and Hearth dialogue reflect the arc.
10. The Godot headless test proves the state sequence deterministically.

## Pacing rule

Orren can advance at most **one authored relationship beat per descent**.

After an authored Orren scene resolves, any additional Orren/Wanderer node in that same run becomes a non-advancing interlude. Interludes can still grant a practical reward, but they cannot move the relationship forward or restore another Leaf.

The pacing lock is serialized in RunState so saving and continuing a run cannot bypass it.

This means the earliest possible sequence spans multiple descents:

1. first useful meeting;
2. sacrifice decision;
3. attachment / Love;
4. ordinary promise;
5. Empty Stair / Grief.

Declining the sacrifice still consumes that run's authored beat, but the same decision can return on a later descent.

## Remaining risk

The emotional pacing now has a hard minimum, but the player may still miss Orren for several runs depending on route choices. That variability is useful to a point because anticipation grows through absence, but playtesting should confirm it does not become frustration.
