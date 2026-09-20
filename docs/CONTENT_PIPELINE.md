# Content Pipeline

## Content philosophy

Combat, story, encounters, jobs, items, maps, and progression should be data-driven wherever practical.

The production target is Godot. JavaScript data under `src/` remains reference material unless a task explicitly targets the reference build.

## Recommended workflow

1. Define design intent in `docs/`.
2. Add or update the production data under `godot/data/` or a focused Godot data script.
3. Add a service/helper under `godot/scripts/` if stateful behavior is required.
4. Persist only the smallest stable state needed in `godot/scripts/systems/GameState.gd` or the owning run/meta service.
5. Validate the data contract.
6. Render it through an existing generic UI or encounter surface.
7. Add bespoke presentation only after the state and content flow work.

## Production ownership

| Content | Preferred location |
| --- | --- |
| Narrative canon | `docs/lore/` |
| Narrative runtime data | `godot/data/story/` |
| Narrative runtime services | `godot/scripts/story/` |
| Battle/map definitions | `godot/scripts/data/` or dedicated `godot/data/` files |
| Job/class definitions | `godot/scripts/data/` and job system services |
| Run progression | `godot/scripts/roguelite/`, `godot/scripts/roguelike/` |
| Persistent state | `godot/scripts/systems/GameState.gd` |
| Save serialization | `godot/scripts/state/SaveSystem.gd` and production GameState save contract |
| Player-facing screens | `godot/scripts/ui/`, `godot/scenes/` |

## Recurrence story example

The current narrative follows this pipeline:

- Design truth: `docs/lore/recurrence-narrative-bible.md`
- Runtime definitions: `godot/data/story/recurrence_manifest.json`
- State/query service: `godot/scripts/story/RecurrenceStory.gd`
- Reactive character delivery: `godot/scripts/story/GuideDialogue.gd`
- Player surfaces: Results, Last Hearth, Codex
- Validation: `tools/check_recurrence_story.py`

This separation lets authors know the whole truth while players receive only what their progress has earned.

## Content naming rules

Use snake_case stable IDs and readable display names.

Examples:

- `ashvale_road_01`
- `mirefen_reaction_trial`
- `recurrence_leaf_love`
- `continuance_revealed`
- `sunder_strike`

## Asset naming rules

Use descriptive lowercase kebab-case file names.

Examples:

- `zane-portrait-placeholder.png`
- `null-drake-idle-placeholder.png`
- `stone-castle-tile.png`
- `guide-memory-fragment-frame.png`

## Acceptance checklist

New content should:

- Have a stable ID.
- Have a clear player-facing purpose.
- Declare unlock or gating requirements when applicable.
- Live in the production path for the system that owns it.
- Have a test, validator, debug path, or reproducible acceptance scenario.
- Preserve existing save compatibility or document migration.
- Use original or legally safe assets.
- Update matching documentation.
- Avoid runtime dependencies on `archive_react/`, `archive_godot/`, or `docs/archive/`.
