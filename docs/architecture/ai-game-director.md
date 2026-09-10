# AI Game Director

## Purpose

ProjectTactic's AI stack can now observe battles, play the real game with deterministic baseline policies, and convert evidence into engineering proposals. The Game Director adds the missing product-design layer: it decides **what gameplay question should be tested next** from evidence and writes the next bounded implementation prompt itself.

This is the intended self-improvement loop for The Appointed:

```text
The Appointed north star
        +
real battle evidence
        +
accepted project lessons
        |
        v
AI Producer: what is failing / unknown?
        |
        v
AI Game Director: which unknown matters most for fun?
        |
        v
next-experiment.json
next-agent-prompt.md
        |
        v
coding / reasoning agent on a new branch
        |
        v
PR + tests + self-play + human acceptance
        |
        +-------------------------------> repeat
```

The AI is therefore allowed to prompt the next AI. It is **not** allowed to certify its own work as fun, silently change production balance, commit directly to main, or merge its own proposal.

## North star model

`ai/goals/appointed-game-director.json` defines a stable game-design target separate from the engineering scorecard.

The weighted pillars are:

- meaningful decisions: 22
- build expression: 18
- tactical mastery: 18
- tension and pacing: 14
- replayability and surprise: 12
- readability and fairness: 10
- frictionless flow: 6

These weights are prioritization guidance, not a literal fun score. The director must never optimize one metric such as win rate, damage, or turn count by itself.

## Why a separate director is necessary

The existing producer answers questions such as:

- Did a check fail?
- Which evaluation dimension lacks evidence?
- What bounded experiment could reduce that uncertainty?

The Game Director adds a different question:

> Of all the things we could learn next, which one is most likely to improve The Appointed as an engaging tactical roguelike?

This distinction matters. A perfectly stable game can still be boring. A high win-rate policy can still be exploiting a shallow system. A large number of buttons can still produce only one meaningful decision.

## Current first self-generated experiment

The first real self-play evidence contains only these player-facing action ids:

- `basic-attack`
- `move`
- `wait`

That means the current evaluator cannot observe the core roguelike expression layer: abilities, elemental play, buffs, control, status effects, MP tradeoffs, or build synergies.

The Game Director therefore ranks `exp-ability-aware-action-surface` above simply adding more maps or more heuristic policies. The generated next branch is:

`feature/ai-ability-action-surface`

The experiment extends the self-play adapter rather than changing production balance. Existing random and greedy policies remain unchanged controls, while a new ability-aware policy gets its own evidence.

## Self-prompting contract

`tools/ai/game_director.py` writes four artifacts:

- `next-experiment.json`: machine-readable experiment contract
- `director-state.json`: evidence summary and ranked opportunities
- `game-director-report.md`: human-readable reasoning summary
- `next-agent-prompt.md`: complete bounded prompt for the next coding/reasoning agent

The generated prompt includes:

- The Appointed north star
- evidence that caused the experiment
- observation and falsifiable hypothesis
- one bounded change
- success metrics
- guardrails
- validation requirements
- rollback plan
- human acceptance questions
- branch name
- explicit instructions to open a PR and not merge
- explicit instruction to feed resulting evidence back into the Producer and Director

That last rule is what closes the loop. Each implementation should generate the evidence that causes the next prompt.

## What "self-improving" means here

The system improves through progressively better evidence, experiments, eval coverage, and accepted lessons. It does not retrain model weights on every run.

A healthy iteration is:

1. AI proposes a hypothesis.
2. A bounded PR implements only enough to test it.
3. Existing regressions and deterministic self-play run again.
4. New gameplay evidence is compared with baseline evidence.
5. Human playtest questions evaluate fun, clarity, surprise, and feel where automation is insufficient.
6. The result is accepted, rejected, or revised.
7. Only validated lessons become persistent project knowledge.
8. The Director chooses the next highest-information experiment.

Later, accepted/rejected experiment history can become a clean preference dataset for a specialized ProjectTactic critic or ranking model. That is the appropriate point to consider fine-tuning.

## Unknown-unknown discovery

The Director should increasingly discover issues the user did not know to prompt for, including:

- a legal action that is almost never strategically credible
- a build that changes numbers but not decisions
- terrain that looks important but has negligible policy value
- a dominant ability that collapses multiple jobs into the same play pattern
- a difficulty spike driven by unavoidable damage rather than tactical error
- long cleanup phases after the outcome is strategically decided
- encounter seeds where the best move is almost always obvious
- random variation that changes outcomes without changing strategy
- AI policies that outperform humans only by exploiting unreadable or tedious mechanics

Each finding must become an experiment, not an unquestioned truth.

## Human acceptance

Fun cannot be fully inferred from self-play. Human acceptance remains mandatory for player-facing conclusions.

The most useful human questions are not just "Was it fun?" They should ask:

- Which turns felt tense?
- Which turns felt clever?
- Which turns felt obvious or automatic?
- Which losses felt earned versus arbitrary?
- Which rewards changed how you played?
- When did you feel a build come online?
- Did the enemy create a problem you wanted to solve, or only more HP to remove?
- Did you understand why a strong tactic worked?

Those answers can later be joined to deterministic scenario/build evidence and used to calibrate the automated proxies.

## Guardrails

Best practice is aggressive experimentation with conservative promotion.

The Director may generate prompts automatically. A future orchestrator may even open bounded experimental PRs automatically. However:

- main remains protected by human approval
- no automatic merges
- no deletion or weakening of failing tests to improve a score
- no broad balance rewrite from one scenario
- no self-play-only declaration that a mechanic is fun
- no accepted memory entry from an unvalidated hypothesis
- no more than one unrelated gameplay system per experiment

## Next evolution

After the ability-aware action surface is validated, the Director should re-rank the remaining opportunities from the new evidence. Likely candidates include a deterministic scenario matrix, terrain-seeking and defensive policies, action-dominance metrics, and then run-level build/boon experiments.

The long-term target is not a single "smart bot." It is a closed development laboratory where The Appointed continuously plays itself, identifies the most valuable unknown, prompts the next bounded experiment, measures the result, learns only from validated outcomes, and keeps humans responsible for whether the game is actually becoming better.
