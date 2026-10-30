# Save Schema — user://save_slot_N.json

{"schema_version":1,"engine_version":"4.6.2","ruleset_version":1,
 "seed":73499241,"rng_state":182773621,"floor_index":0,"elapsed_turns":12,
 "party":[{"unit_id":1,"archetype_id":"zane","hp":280,"mp":75,"temper":65,"ether":95,
           "tile":[2,6],"facing":"N","statuses":[],"cooldowns":{}}],
 "meta_unlocks":["job_resonant"],"story_flags":["new_game_started"],
 "inventory":{"vitae_draught":2},"gold":250,
 "command_log":[{"actor_id":1,"type":"move","to":[2,5]}]}

## Rules
1. Always store engine_version + ruleset_version (replay determinism)
2. Store seed AND rng_state (seed alone insufficient for mid-run saves)
3. command_log enables deterministic replay validation
4. Never store Node references — primitives only
5. schema_version < current → run SaveMigrator.gd before use

## Settings: user://settings.cfg (use Godot ConfigFile)
[display] fullscreen=false | [audio] master_volume=0.8 | [gameplay] battle_speed=1
