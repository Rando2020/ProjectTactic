# ProjectTactic AI skill workflow

This folder contains **original starter skills** tailored from the AI Development Skill Pack. They are not official Anthropic, Karpathy, Matt Pocock, or UI UX Pro Max distributions.

## Routing
- Godot UI/HUD and art: `taste-review`, `ui-ux-quality`, `rigorous-review`.
- GDScript gameplay or bug fix: `pragmatic-engineering`, `first-principles`, `rigorous-review`.
- Agent automation: `agent-orchestration` plus `rigorous-review`.
- Web/TypeScript modules only: `typescript-reliability`.
- Knowledge graph experiments only when justified: `graph-memory`.

Select 1 to 3 skills per task, read the applicable SKILL.md files, and use the task packet. Do not apply TypeScript conventions to GDScript. These instructions are passive repository files; automatic loading depends on the coding agent.

## Project safeguards
1. Start from verified source, branch and acceptance criteria.
2. Keep asset references, scenes, Godot project settings and playable encounter behavior intact.
3. Check gameplay logic with relevant tests; check visual work in rendered Godot screenshots or human review.
4. Report automated tests separately from visual acceptance. The previously reported 415 integration checks and 30 HUD assertions are historical evidence, not proof of this branch.
5. Never commit credentials, generated caches or exported builds.
6. Open a draft PR for review. No merge or live-demo deployment without a separate explicit decision.

## Task template
```markdown
### Objective
### Base commit / relevant scenes
### Skills selected (1 to 3)
### Constraints and non-goals
### Acceptance criteria
### Implementation and tests
### Visual evidence
### Regressions / blockers / not-run
### Rollback and delivery
```
