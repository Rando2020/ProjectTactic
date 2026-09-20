# Archived Godot Narrative Prototype

This folder preserves the earlier "seven / true names / sin-virtue" narrative prototype.

It is not production runtime code.

Why it was archived:
- `godot/project.godot` autoloads `res://scripts/systems/GameState.gd`, not the older `scripts/autoload/GameState.gd`.
- The old setup guide instructed contributors to register a second GameState singleton, which would conflict with the production architecture.
- The current canon is the Recurrence narrative under `docs/lore/` and `godot/data/story/`.

Useful material may still be mined for character psychology, visual language, or encounter ideas, but do not restore these files to the production Godot tree without an explicit migration plan.
