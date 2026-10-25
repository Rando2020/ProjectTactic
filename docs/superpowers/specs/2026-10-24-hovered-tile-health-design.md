# Hovered-tile health readout repair

## Intent and scope
The actual duel showed Storm Imp's authoritative HP and bar falling while the tile readout stayed at 90/90 until another tile was hovered. Preserve all story, combat, action ordering, previews, and ordinary full-party/duel behavior; repair only this display subscription gap.

## Approaches and delegated choice
- **Chosen:** remember the last genuinely inspected tile separately from selection/highlight state; format its text through a read-only helper and refresh on existing unit HP/movement/removal events. This closes the observed gap without replaying input.
- Re-emitting hover or invoking its handler would alter forecasts/path/AoE/target lock; rejected.
- Per-frame polling or a combat-specific patch duplicates authority and does needless work; rejected.

## Design
BattleManager owns the cached cell and display formatter. Formatting skips dead, removed, or invalid units without erasing registry entries. Existing Unit.hp_changed covers receive_damage, heal, and Burn. Existing Unit.moved covers ordinary moves/knockback. Unit.tree_exited clears removed occupants. Refresh again after the existing defeat handler so existing survival boons' final HP is represented, without modifying those boons. The only output of refresh is tile_info_changed; the normal hover handler retains all its other logic. Never use selected_tile as the cache because clear_highlights clears it.

## Evidence boundary
A new strict isolated native fixture uses real viewport hover, actual BattleUI text, and legal Fire. Explicit test-only damage/heal/Burn/movement/lethal/removal fixtures exercise edge cases, control/preview/resource/RNG isolation, and full-party coverage; these are not claims of natural-play victories. Existing duel/showcase contracts remain unchanged. No GUI, publishing, deployment, config, or broad refactor.
