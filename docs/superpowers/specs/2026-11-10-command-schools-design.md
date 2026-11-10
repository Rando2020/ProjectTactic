# Courtyard command schools

Intent: separate Magic and Skills, then group a hero's available spells by school. The user explicitly wants heroes to eventually use multiple types of magic. The current learned/equipped battle ability list remains the source of ownership; no hero is assigned a single school.

Use the existing Godot courtyard controls and authoritative combat manager. Add per-ability catalog metadata, a pure grouping projection, and courtyard-only menu state. Magic opens schools, a school opens its spells, and Skills opens physical techniques. Keep Move, Attack, Wait, confirmation, targeting, effects, costs, and saves intact.

Initial editable assignments: Fire/Thunderstrike/Void Pulse in Black Magic, Haste in Time Magic, existing healing/protection definitions in White Magic. These are provisional organizing labels, not final lore or class restrictions. Empty schools are omitted. Empty Magic or Skills categories stay visible but disabled with an explanation. Known abilities that cannot currently be used stay visible with a reason. Unknown saved IDs are neither erased nor exposed as broken buttons.

Back from review returns to targeting, then the same spell list, then school list, then commands. Self reviews return to their list. Preserve selection/focus where practical, scroll long lists, use native GUI-safe keyboard/mouse/touch controls and gamepad navigation. No new heroes, spells, art or save migration.

Approaches considered: fixed school per hero would block the requested future; school inferred only from damage type conflates magical weapon skills and support; explicit per-ability metadata supports multiple schools and later taxonomy changes without ownership edits. The last approach is the implementation choice.
