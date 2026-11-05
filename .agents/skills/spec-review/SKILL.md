---
name: spec-review
description: Review proposed ProjectTactic changes against canonical Godot architecture, game design, and testable acceptance criteria before implementation. Inspired by Google's Elephant Goldfish Model.
---
# ProjectTactic specification review

Use when a change affects combat, status/turn order, sprite pipeline, visual occlusion, save data, player progression, or multiple subsystems. For a narrow bug, use the existing workflow instead.

## Read first
- `CLAUDE.md`, `ARCHITECTURE.md`, `AI_TASK_PACKETS.md`
- Related `docs/design/`, `docs/systems/`, `docs/production/`
- The actual Godot code in `godot/`, not `src/` or archived React as runtime truth

## Outputs, in this order
1. A brief stating intended player experience, scope, non-goals, affected files, and alternatives.
2. A design draft with decisions, dependencies, failure states, UX impacts, rollback, and explicit unknowns.
3. An acceptance matrix with observed baseline, test steps, and verifiable expected results.
4. A findings log distinguishing confirmed source evidence, hypotheses, and unresolved owner decisions.
5. Only after approval: an implementation plan for a scoped feature branch.

## Independent-review rule
If Google's Elephant Goldfish Model plugin is actually installed and fresh isolated subagents are available, use `egm-brainstorm`, `egm-draft`, and `egm-review` per upstream instructions. Provide reviewers with the draft and source references, without the drafting conversation. If fresh independent contexts are unavailable, state **"Independent EGM review not performed"**; do not pretend a self-check is independent. An agent can still conduct a clearly labeled single-context checklist.

## Game-specific gates
- Four-direction isometric sprites retain anatomical hand, identity, camera, foot alignment, and scale.
- Terrain must not make units unfairly invisible: specify transparent/outline/LOS/cover behavior separately.
- Preserve deterministic command, initiative, and save behavior; clarify actual versus forecast damage.
- Compare candidate render to approved painted battlefield references; report mismatch without inventing a similarity percentage.
- Godot is the production target. Do not introduce new React gameplay.
- No secret access, destructive cleanup, merge, deployment, or auto-merge without approval.

## Attribution
Original project-local procedure inspired by the Apache-2.0 licensed https://github.com/google/elephant-goldfish-model . This file does not bundle or install Google's plugin. Review upstream before any installation or update.
