# ProjectTactic AI Producer Loop

## Goal

ProjectTactic should use AI as a persistent development system, not only as a prompt-response coding assistant.

The target loop is:

1. Observe the repository, tests, build results, deterministic simulations, browser playtests, and human feedback.
2. Convert those observations into structured evidence.
3. Score the build against stable ProjectTactic goals.
4. Compare the current build with prior evidence and accepted lessons.
5. Identify failures, regressions, blind spots, and high-value experiments without waiting for a human to invent a prompt.
6. Produce a bounded task packet for a coding agent.
7. Implement changes only on a dedicated branch and PR.
8. Re-run the same evaluations before recommending acceptance.
9. Promote only validated lessons into long-term memory.

This is the ProjectTactic AI producer loop.

## What "learning" means

The first version does not retrain model weights inside the repository.

It learns through four safer mechanisms:

- **Evidence memory:** builds and playtests produce machine-readable evidence.
- **Accepted lessons:** durable findings are kept in source control so future agents do not repeat known mistakes.
- **Expanding evals:** every meaningful escaped bug should become a regression check when practical.
- **Preference history:** later, accepted and rejected AI proposals can become training data for ranking future proposals.

Weight-level fine-tuning can be considered later, after enough high-quality trajectories and human decisions exist. Training on noisy self-generated output too early risks teaching the system its own mistakes.

## Why this is different from AGENTS.md

`AGENTS.md` and `AI_TASK_PACKETS.md` tell an agent how to work and what known tasks exist. The producer loop answers a different question:

> What should we work on next, based on evidence, even when the user does not know what to ask for?

The producer should be able to surface unknown unknowns such as:

- a dominant boon or ability that makes other choices irrelevant
- a job that is almost never selected
- a map seed with unusually high loss rates
- turns with no meaningful tactical choice
- repeated player backtracking or cancelled actions
- enemy intent that is technically correct but unreadable
- save or browser behavior that passes native tests but fails after refresh
- a recent feature with no regression coverage
- a large architectural hotspot that repeatedly causes unrelated defects
- asset readability or performance regressions that functional tests cannot see

## Architecture

### 1. Evidence producers

Evidence can come from:

- GitHub Actions
- Godot unit and integration tests
- deterministic battle simulations
- future AI self-play
- browser automation
- performance traces
- human playtest notes
- screenshots or visual review summaries

All evidence should be normalized to `ai/schemas/evidence.schema.json`.

### 2. Scorecard

`ai/evals/projecttactic-scorecard.json` defines durable product goals. Initial dimensions are:

- correctness and stability
- tactical depth
- run health and replayability
- readability and UX
- performance and browser delivery
- discovery and coverage

Scores are signals, not truth. A score must never be optimized in isolation when doing so makes the game less fun.

### 3. Memory

`ai/memory/lessons.jsonl` stores accepted lessons. Entries should be short, falsifiable where possible, and linked to evidence.

The producer may generate candidate lessons, but it must not silently promote them to accepted truth. Human approval or strong automated evidence is required.

### 4. Producer

`tools/ai/producer.py` is the deterministic coordinator. It can:

- validate AI configuration and evidence
- summarize failing checks and important observations
- compare evidence coverage against the scorecard
- generate prioritized proposal packets
- generate candidate lessons for review

It deliberately has no GitHub merge permission and no ability to edit gameplay itself.

### 5. Reasoning model

A reasoning model can consume the producer report plus the relevant repository context to create better hypotheses and implementation plans.

The model should be treated as a proposer, not an oracle. It should cite evidence IDs, distinguish observed facts from hypotheses, and define a falsifiable success condition for every change.

### 6. Coding agent

Codex, Claude Code, or another coding agent receives one bounded proposal at a time. It must follow the repository PR workflow and cannot merge without explicit user approval.

## Self-play roadmap

### Phase A: Instrumentation

Add a telemetry/event recorder for deterministic offline runs. Capture at minimum:

- build SHA
- scenario/map ID
- RNG seed
- party and jobs
- enemy composition
- abilities and boons offered/selected
- actions by turn
- damage/healing/status applications
- unit deaths
- battle result
- turn count
- elapsed time
- retries, cancels, and invalid actions where available

Do not collect personal player data for this development harness.

### Phase B: Scripted agents

Create several simple players before using an LLM:

- greedy damage
- defensive survival
- objective rush
- random legal action
- terrain-seeking
- status/control focused

These baselines reveal degenerate strategies and make later learned agents measurable.

### Phase C: Search-based self-play

Add a headless battle interface that exposes legal actions and deterministic state. Monte Carlo search or beam search can explore tactics without requiring a large model for every move.

This is likely the highest-value source of balance evidence for ProjectTactic.

### Phase D: Model-guided critic

Use a reasoning model to review aggregated self-play results and answer questions such as:

- What strategy is over-rewarded?
- Which decisions are fake choices?
- Where does difficulty spike unexpectedly?
- Which abilities are never correct to choose?
- What new test would most reduce uncertainty?

The critic produces proposals, not direct balance edits.

### Phase E: Preference learning

Record whether proposals were accepted, rejected, reverted, or improved after playtesting. Once the dataset is large enough, use it to rank future proposals or fine-tune a small project-specific critic.

## Guardrails

The producer must never:

- commit directly to `main`
- merge a PR
- change multiple unrelated systems in one experiment
- treat a single self-play policy as representative of real players
- optimize only win rate or average turn count
- promote its own hypothesis into accepted memory without evidence
- delete failing tests to improve a score
- hide known failures
- train on secrets, private user data, or credentials

## Experiment contract

Every AI-generated development proposal should contain:

- **Observation:** what evidence triggered the proposal
- **Hypothesis:** what the AI thinks is happening
- **Change:** the smallest intervention that tests it
- **Success metric:** what should improve
- **Guardrail metrics:** what must not regress
- **Validation:** automated and human checks required
- **Rollback:** how to disable or revert the experiment

## Recommended next implementation

After this foundation is merged, build `feature/ai-battle-telemetry`.

That PR should add a deterministic development-only battle telemetry sink and one headless scenario exporter. Do not add an LLM to combat runtime. The goal is to create clean training and evaluation data first.

After telemetry is stable, build `feature/ai-self-play-baselines` with scripted player policies and batch simulation. Only then add a model-guided critic.
