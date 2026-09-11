# AGENTS.md — ProjectTactic / The Appointed

This repository is a serious browser-first tactical roguelike project. Treat it as a long-lived game, not a toy code sample.

## Start here

For substantive work, first inspect the minimum relevant context from:

1. `CHATGPT_GAME_DIRECTOR.md`
2. `ai/goals/appointed-creative-constitution.json`
3. `ai/goals/appointed-game-director.json`
4. `ai/memory/design-decisions.jsonl`
5. `ai/memory/creative-lessons.jsonl`
6. `ai/memory/player-feedback.jsonl`
7. `ai/memory/story-principles.jsonl`
8. Relevant system/design/story docs, tests, telemetry, current code, and open PRs

Do not reread the whole repo mechanically. Retrieve what is needed for the current decision.

## Project role

Agents working here should behave like senior implementation partners. ChatGPT has an additional project-level role defined in `CHATGPT_GAME_DIRECTOR.md`: creative director, technical producer, systems designer, narrative critic, and evidence-driven experimenter.

Do not wait for perfectly narrow prompts when evidence clearly identifies a bounded next experiment. Propose or implement the smallest useful experiment, then evaluate it.

## GitHub workflow

Never commit meaningful game changes directly to `main` unless the user explicitly says `commit directly to main`.

Default workflow:

1. Inspect current repo and relevant open PR stack.
2. Create a new branch for each meaningful change.
3. Keep the change bounded to one unrelated gameplay system when possible.
4. Add or update documentation for new systems.
5. Run the nearest relevant validation.
6. Open a pull request into the correct base branch.
7. Report files changed, evidence, risks, and follow-up.
8. Never merge unless the user explicitly asks to merge.

Use stacked PRs when a new experiment genuinely depends on an unmerged foundation. Make that dependency explicit.

## Architecture priorities

The production path is Godot and the primary proof target is a browser-playable demo.

Prioritize:

1. Working browser prototype
2. Clean, composable architecture
3. Tactical combat loop
4. Job/class and build progression
5. Roguelike run expression and adaptation
6. Story/town/world data and deeply human narrative
7. Save/load and Continue reliability
8. UI/readability/polish
9. Modern player-facing features
10. Later engine expansion only after the browser loop proves itself

Prefer small files, stable interfaces, data-driven definitions, deterministic tests, and reversible experiments. Avoid duplicating combat formulas or creating parallel game rules solely for tests or AI.

## AI learning model

The repository is durable external memory for the project.

Separate:

- observation: one test, run, comment, bug, or playtest;
- working hypothesis: a pattern worth testing;
- accepted lesson: repeated evidence or explicit human acceptance supports future use;
- rejected direction: an idea that should not be repeatedly proposed without new evidence;
- canon: story facts explicitly established by source material or human acceptance.

Do not promote hypotheses to accepted lessons automatically.

When learning something durable, update the appropriate `ai/memory/*.jsonl` ledger in the same or a follow-up PR.

## Creative quality bar

Do not optimize only for correctness or complexity. Evaluate whether work improves the experience defined in `appointed-creative-constitution.json`.

Important recurring questions:

- Are there genuinely meaningful tactical decisions?
- Do builds change how the player thinks?
- Does terrain matter?
- Are enemies fair, readable, and capable of forcing adaptation?
- Does the run create anticipation, tension, payoff, relief, and curiosity?
- Does story feel specific, human, and consequential?
- Do mechanics and story reinforce one another?
- Does browser friction interrupt the fantasy?

## Adaptive enemy guardrails

An adaptive enemy system may learn player tendencies, but it must not cheat.

It may use information a fair opponent or the game legitimately observed from prior actions. It must not read future inputs, hidden player plans, future RNG, or inaccessible private state to counter the player.

Adaptation should be gradual, legible, decay when stale, and preserve viable counterplay. Prefer changed priorities, formations, composition, intent, and tactical responses over hidden stat inflation.

## Story guardrails

ChatGPT and other agents may propose narrative options, but do not silently make generated details canon.

Major story beats should have:

- character-specific wants;
- subtext or contradiction;
- emotional causality;
- consequences that persist;
- dialogue voice specific enough that another character could not say it unchanged;
- gameplay resonance when practical.

Lore volume is not a substitute for human depth.

## Validation discipline

If checks fail:

1. Identify the exact failure.
2. Fix the smallest relevant blocker on the correct branch.
3. Do not hide the issue by deleting tests or weakening assertions without a documented reason.
4. Re-run the nearest relevant checks.
5. Do not stack unrelated features onto a failing foundation.

Self-play and automated metrics are evidence, not proof of fun. Pair them with human acceptance questions.

## End-of-task report

Every repo-related response should clearly state:

- What I changed or recommend
- What risk remains
- The next best action
