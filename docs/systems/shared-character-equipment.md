# Shared character stats and equipment

## Contract
CharacterStats.BASE owns party base statistics. GameState.get_character_stats combines those bases, accumulated job-stat bonuses, permanent upgrades, and valid owned equipment. CharacterScreen and the battle party factory consume that calculation. MP and Ether remain separate resources. Temporary battle statuses, run boons, and story burdens apply afterward and are not presented as permanent roster stats.

EquipmentRules owns the supported slots (weapon/main_hand, accessory, charm), starter inventory, and flat-stat affix mapping. Four shared starter pieces allow the equipment flow to work before the first loot drop. Ownership is per item ID; a piece can be assigned to only one unit. Switching equipment clamps saved resources downward without healing. Comparison text previews the replacement delta, not the candidate's raw bonus.

GameState owns equip/unequip validation and persistence. InventoryScreen shows the same owned inventory and links to character management. The equipment tab is the editing surface. Existing generated run loot is available while owned in run_inventory. Run loot remains run-scoped; starter stores persist in gear_inventory. A stale assignment grants no bonus when its item is no longer owned.

## Save compatibility
The version-1 save gains an optional gear_inventory array. Saves without it receive the starter stores. Legacy equipment display strings and old slot keys remain preserved in saved dictionaries but grant no stats and are not presented as equipped owned items. No destructive migration occurs. Empty supported slots can be filled normally.

## Presentation
The company screen uses warm parchment, dark ink, brass borders, restrained resource colors, existing portraits, and existing original unit art. Jobs show emblems, current/locked/mastered states, prerequisite progress, and JP progress. Containers wrap and scroll with keyboard focus; no full-screen generated image replaces controls.

## Files
- godot/scripts/systems/CharacterStats.gd: pure stat composition.
- godot/scripts/systems/EquipmentRules.gd: inventory/slot contract.
- godot/scripts/systems/GameState.gd: ownership, mutations, saves.
- godot/scripts/battle/BattleScene.gd: shared spawn stats and job identity.
- godot/scripts/ui/CharacterScreen.gd and InventoryScreen.gd: presentation and equipment actions.
- godot/tests/test_character_equipment.tscn: ownership, slots, save round trip, factory parity, resource clamp.

## Boundaries and next steps
Only Physical, Magic, HP, Temper, and Speed loot affixes are implemented. Items containing other affixes are visibly unavailable for equipping; future work must implement their combat hooks before enabling them. No sell/discard system, armor-slot economy, per-job costume production, or new art generation is included. Base levels remain authored demo values. The original four sprite-sheet integration still needs its source PNGs.

Use isolated user data for tests. Run test_character_equipment, test_character_screen_layout, test_progression_speed, and test_playable_loop; also run validate_all_scripts. Rendering must be reviewed separately from headless checks. Web export requires matching Godot 4.6.2 templates. This PR does not deploy or merge.
