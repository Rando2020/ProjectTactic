# ProjectTactic

**The Appointed** is a Godot-first tactical roguelite RPG built around grid combat, job progression, repeated descents, and a story about what humanity preserves when it tries to remove uncertainty and suffering.

The playable production target is the Godot project under `godot/`. React and JavaScript code remain in the repository as reference material and should not be treated as the runtime source of truth.

## Current production architecture

| Area | Source of truth |
| --- | --- |
| Godot project | `godot/` |
| Runtime game state | `godot/scripts/systems/GameState.gd` |
| Run state | `godot/scripts/roguelite/RunManager.gd` |
| Save/load | `godot/scripts/state/SaveSystem.gd` |
| Story runtime | `godot/scripts/story/` |
| Story data | `godot/data/story/` |
| Narrative canon | `docs/lore/` |
| Game/system design | `docs/design/`, `docs/systems/` |
| React reference | `src/`, `archive_react/` |
| Retired Godot prototypes | `archive_godot/` |

## Narrative direction

The current narrative spine is **Recurrence**.

Humanity did not fail to solve itself. It progressively learned to eliminate the painful half of human experience until the boundary between individual selves disappeared. The resulting Collective became the being now known as **the Guide**.

The Appointed remain separate from the Guide. Their separation makes them unpredictable, capable of genuine choice, and uniquely precious to a consciousness that otherwise contains everything capable of fully understanding it.

The ten sealed Leaves of the fictional Gigas Codex form five bifurcated human experiences:

1. Love / Grief
2. Choice / Regret
3. Trust / Betrayal
4. Hope / Fear
5. Self / Loneliness

The story does **not** argue that suffering is good. Its central tension is that eliminating vulnerability, uncertainty, loss, and separateness completely may also eliminate the conditions required for bounded human experience.

Start here:

- `docs/lore/recurrence-narrative-bible.md`
- `docs/design/recurrence-run-integration.md`
- `docs/systems/recurrence-story-runtime.md`
- `godot/data/story/recurrence_manifest.json`

## Development rule

New gameplay, UI, run, combat, progression, and narrative integration belongs in Godot unless a task explicitly targets a reference prototype.

Before implementation, read:

- `CLAUDE.md`
- `ARCHITECTURE.md`
- `AI_TASK_PACKETS.md`
- `docs/systems/js-to-godot-migration-backlog.md`

Meaningful changes should use a feature or fix branch and a pull request into `main`. Do not merge automatically.

## Repository organization

```text
godot/
  data/
    story/              # Runtime narrative data
  scripts/
    battle/
    data/
    roguelike/
    roguelite/
    state/
    story/              # Narrative state helpers and reactive dialogue
    systems/
    ui/

docs/
  architecture/
  characters/
  design/
  lore/
  production/
  systems/
  archive/              # Historical documentation only

archive_react/           # Retired/reference React state and data
archive_godot/           # Retired Godot prototypes, never runtime source
src/                     # React reference build
tools/                   # Validation and development checks
```

## Validation

Narrative contract:

```bash
python tools/check_recurrence_story.py
```

Reference web build:

```bash
npm install
npm run build
```

For production changes, Godot import/export checks should also remain green in the relevant CI workflow or local Godot environment.

## Archive policy

Archive files when they still contain useful historical design context but would mislead future contributors if left in a production path.

Delete redundant copies only when an identical canonical copy already exists elsewhere.

Do not use archived files as runtime dependencies.
