# AI Task Packets

## Principle
Define rules before code. One deterministic subsystem + one test per session.

## Codex Packet Template
engine_version: 4.6.2 | language: typed GDScript
allowed_files: [list] | forbidden: .tscn, autoloads, project.godot
signature: func name(params: Types) -> ReturnType
rules: [from RULESET_CONTRACTS.md] | done: headless test passes

## Claude Packet Template
- First: interface + invariants + edge cases + test list
- Then: code
- No Node access, no global state, no autoloads, no wall clock

## Best AI Tasks (most reliable first)
GridMath | TurnQueue | ElementalSystem | StatusHooks | LootTableRoller | RoomValidator | SaveMigrator | CombatLogFormatter

## Run Tests
godot --headless --path . -s res://tests/test_element_resolver.gd

## Review Checklist
- [ ] Depends only on explicit inputs
- [ ] Does NOT mutate .tres Resources at runtime
- [ ] No scene-tree calls in hot logic
- [ ] Tests cover edge cases
- [ ] Save files schema-versioned
- [ ] Logs use structured event IDs
