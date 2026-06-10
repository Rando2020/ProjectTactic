class_name AssetRegistry
extends RefCounted

# Central Godot asset registry for ProjectTactic.

# This file maps stable gameplay IDs to planned asset paths. The paths are
# allowed to point to placeholder files that will be generated later. Keeping
# these IDs stable lets battle, UI, hub, run-node, and map systems integrate art
# without repeatedly changing gameplay data.

const PROMPT_SOURCE := "docs/prompts/demo-asset-generation.md"

const TILES := {
	"grass": {
		"id": "grass",
		"label": "Grass",
		"path": "res://assets/tiles/grass-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"dirt": {
		"id": "dirt",
		"label": "Dirt",
		"path": "res://assets/tiles/dirt-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"road": {
		"id": "road",
		"label": "Road",
		"path": "res://assets/tiles/road-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"stone": {
		"id": "stone",
		"label": "Stone",
		"path": "res://assets/tiles/stone-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"wall": {
		"id": "wall",
		"label": "Wall",
		"path": "res://assets/tiles/wall-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"water": {
		"id": "water",
		"label": "Water",
		"path": "res://assets/tiles/shallow-water-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"shrine": {
		"id": "shrine",
		"label": "Shrine",
		"path": "res://assets/tiles/shrine-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"high_ground": {
		"id": "high-ground",
		"label": "High Ground",
		"path": "res://assets/tiles/high-ground-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"brush": {
		"id": "brush",
		"label": "Brush",
		"path": "res://assets/tiles/brush-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"grass_flowers": {
		"id": "grass-flowers",
		"label": "Flowering Grass",
		"path": "res://assets/tiles/grass-flowers-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"burning": {
		"id": "burning",
		"label": "Burning Ground",
		"path": "res://assets/tiles/burning-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"ice": {
		"id": "ice",
		"label": "Frozen Ground",
		"path": "res://assets/tiles/frozen-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"cracked_stone": {
		"id": "cracked-stone",
		"label": "Cracked Stone",
		"path": "res://assets/tiles/cracked-stone-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"height_edge_grass": {
		"id": "height-edge-grass",
		"label": "Grass Height Edge",
		"path": "res://assets/tiles/height-edge-grass.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"height_edge_stone": {
		"id": "height-edge-stone",
		"label": "Stone Height Edge",
		"path": "res://assets/tiles/height-edge-stone.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"void_corruption": {
		"id": "void-corruption",
		"label": "Void Corruption",
		"path": "res://assets/tiles/void-corruption-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"elite_spawn": {
		"id": "elite-spawn",
		"label": "Elite Spawn Tile",
		"path": "res://assets/tiles/elite-spawn-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"boss_arena": {
		"id": "boss-arena",
		"label": "Boss Arena Tile",
		"path": "res://assets/tiles/boss-arena-tile.png",
		"prompt_source": PROMPT_SOURCE,
	},
}

const PROPS := {
	"leafy_bush": "res://assets/props/leafy-bush.png",
	"ruin_block": "res://assets/props/ruin-block.png",
	"mossy_rock": "res://assets/props/mossy-rock.png",
	"tree_stump": "res://assets/props/tree-stump.png",
	"broken_banner": "res://assets/props/broken-banner.png",
	"ash_pillar": "res://assets/props/ash-pillar.png",
}

const OVERLAYS := {
	"wet": "res://assets/tiles/wet-overlay.png",
	"burning": "res://assets/tiles/burning-tile.png",
	"frozen": "res://assets/tiles/frozen-tile.png",
	"electrified": "res://assets/tiles/electrified-overlay.png",
	"elite_marked": "res://assets/overlays/elite-overlay-marked.png",
	"elite_champion": "res://assets/overlays/elite-overlay-champion.png",
}

const HIGHLIGHTS := {
	"selected": "res://assets/ui/tile-selected-diamond.png",
	"move": "res://assets/ui/tile-move-diamond.png",
	"attack": "res://assets/ui/tile-attack-diamond.png",
	"ability": "res://assets/ui/tile-ability-diamond.png",
	"blocked": "res://assets/ui/tile-blocked-diamond.png",
	"objective": "res://assets/ui/objective-marker-diamond.png",
}

const UNITS := {
	"zane": {
		"id": "zane",
		"display_name": "Zane",
		"role": "Swordsman",
		"idle": "res://assets/sprites/units/zane-idle-isometric.png",
		"action": "res://assets/sprites/units/zane-idle-isometric.png",
		"portrait": "res://assets/sprites/units/zane-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"mira": {
		"id": "mira",
		"display_name": "Mira",
		"role": "Mage",
		"idle": "res://assets/sprites/units/mira-idle-isometric.png",
		"action": "res://assets/sprites/units/mira-idle-isometric.png",
		"portrait": "res://assets/sprites/units/mira-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"kael": {
		"id": "kael",
		"display_name": "Kael",
		"role": "Guardian",
		"idle": "res://assets/sprites/units/kael-idle-isometric.png",
		"action": "res://assets/sprites/units/kael-idle-isometric.png",
		"portrait": "res://assets/sprites/units/kael-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"lyra": {
		"id": "lyra",
		"display_name": "Lyra",
		"role": "Archer",
		"idle": "res://assets/sprites/units/lyra-idle-isometric.png",
		"action": "res://assets/sprites/units/lyra-idle-isometric.png",
		"portrait": "res://assets/sprites/units/lyra-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"aeryn": {
		"id": "aeryn",
		"display_name": "Aeryn",
		"role": "Soldier",
		"idle": "res://assets/sprites/units/aeryn.png",
		"action": "res://assets/sprites/units/aeryn.png",
		"portrait": "res://assets/sprites/units/aeryn.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"cael": {
		"id": "cael",
		"display_name": "Cael",
		"role": "Archer",
		"idle": "res://assets/sprites/units/cael.png",
		"action": "res://assets/sprites/units/cael.png",
		"portrait": "res://assets/sprites/units/cael.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"brennan": {
		"id": "brennan",
		"display_name": "Brennan",
		"role": "Soldier",
		"idle": "res://assets/sprites/units/brennan.png",
		"action": "res://assets/sprites/units/brennan.png",
		"portrait": "res://assets/sprites/units/brennan.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"solan": {
		"id": "solan",
		"display_name": "Solan",
		"role": "Mage",
		"idle": "res://assets/sprites/units/solan.png",
		"action": "res://assets/sprites/units/solan.png",
		"portrait": "res://assets/sprites/units/solan.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"tobias": {
		"id": "tobias",
		"display_name": "Tobias",
		"role": "Cleric",
		"idle": "res://assets/sprites/units/tobias.png",
		"action": "res://assets/sprites/units/tobias.png",
		"portrait": "res://assets/sprites/units/tobias.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"seren": {
		"id": "seren",
		"display_name": "Seren",
		"role": "Archer",
		"idle": "res://assets/sprites/units/seren.png",
		"action": "res://assets/sprites/units/seren.png",
		"portrait": "res://assets/sprites/units/seren.png",
		"prompt_source": PROMPT_SOURCE,
	},
}

const ENEMIES := {
	"null_drake": {
		"id": "null-drake",
		"display_name": "Null Drake",
		"idle": "res://assets/sprites/units/null-drake-idle-isometric.png",
		"attack": "res://assets/sprites/units/null-drake-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"storm_imp": {
		"id": "storm-imp",
		"display_name": "Storm Imp",
		"idle": "res://assets/sprites/units/storm-imp-idle-isometric.png",
		"attack": "res://assets/sprites/units/storm-imp-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"fen_wraith": {
		"id": "fen-wraith",
		"display_name": "Fen Wraith",
		"idle": "res://assets/sprites/units/fen-wraith-idle-isometric.png",
		"attack": "res://assets/sprites/units/fen-wraith-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"void_cultist": {
		"id": "void-cultist",
		"display_name": "Void Cultist",
		"idle": "res://assets/sprites/units/void-cultist-idle-isometric.png",
		"attack": "res://assets/sprites/units/void-cultist-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"ashen_soldier": {
		"id": "ashen-soldier",
		"display_name": "Ashen Soldier",
		"idle": "res://assets/sprites/units/ashen-soldier-idle-isometric.png",
		"attack": "res://assets/sprites/units/ashen-soldier-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"bone_archer": {
		"id": "bone-archer",
		"display_name": "Bone Archer",
		"idle": "res://assets/sprites/units/bone-archer-idle-isometric.png",
		"attack": "res://assets/sprites/units/bone-archer-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"cult_mage": {
		"id": "cult-mage",
		"display_name": "Cult Mage",
		"idle": "res://assets/sprites/units/cult-mage-idle-isometric.png",
		"attack": "res://assets/sprites/units/cult-mage-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
	"boss_null_knight": {
		"id": "boss-null-knight",
		"display_name": "Null Knight",
		"idle": "res://assets/sprites/units/boss-null-knight-idle-isometric.png",
		"attack": "res://assets/sprites/units/boss-null-knight-idle-isometric.png",
		"prompt_source": PROMPT_SOURCE,
	},
}

const UI := {
	"panels": {
		"dark_stone": "res://assets/ui/dark-stone-panel.png",
		"command_bar": "res://assets/ui/command-bar-panel.png",
		"turn_order_sidebar": "res://assets/ui/turn-order-sidebar-panel.png",
		"forecast": "res://assets/ui/forecast-panel-frame.png",
		"enemy_intent": "res://assets/ui/enemy-intent-panel-frame.png",
		"tile_info": "res://assets/ui/tile-info-panel-frame.png",
		"battle_telemetry": "res://assets/ui/battle-telemetry-panel-frame.png",
		"hub_dark_gold": "res://assets/ui/hub-panel-dark-gold.png",
		"guardian_shrine": "res://assets/ui/guardian-shrine-panel.png",
		"job_reliquary": "res://assets/ui/job-reliquary-panel.png",
		"heat_altar": "res://assets/ui/heat-altar-panel.png",
		"reward_card": "res://assets/ui/reward-card-panel.png",
		"reward_boon_upgrade": "res://assets/ui/reward-boon-upgrade-frame.png",
		"reward_item_common": "res://assets/ui/reward-item-frame-common.png",
		"reward_item_rare": "res://assets/ui/reward-item-frame-rare.png",
		"run_route_connector": "res://assets/ui/run-route-connector-line.png",
	},
	"backgrounds": {
		"hub_last_hearth": "res://assets/backgrounds/hub-background-last-hearth.png",
		"antechamber": "res://assets/backgrounds/antechamber-background.png",
		"run_map_parchment": "res://assets/ui/run-map-parchment-background.png",
	},
	"command_icons": {
		"move": "res://assets/icons/command-move-icon.png",
		"attack": "res://assets/icons/command-attack-icon.png",
		"ability": "res://assets/icons/command-ability-icon.png",
		"item": "res://assets/icons/command-item-icon.png",
		"wait": "res://assets/icons/command-wait-icon.png",
	},
	"bars": {
		"hp": "res://assets/ui/hp-bar-frame.png",
		"temper": "res://assets/ui/temper-bar-frame.png",
		"ether": "res://assets/ui/ether-bar-frame.png",
	},
	# Bell icons  use in audio settings panel (mute/unmute toggle)
	"icons": {
		"bell":      "res://assets/ui/icons/bell.svg",
		"bell_mute": "res://assets/ui/icons/bell_mute.svg",
		"settings_speed": "res://assets/icons/settings-speed-icon.png",
		"settings_grid": "res://assets/icons/settings-grid-icon.png",
		"settings_reduced_motion": "res://assets/icons/settings-reduced-motion-icon.png",
	},
	# Parchment  use as background/corner for dialogue boxes and narrative interludes
	"parchment": {
		"bg":     "res://assets/ui/parchment/parchment_bg.png",
		"corner": "res://assets/ui/parchment/parchment_corner.svg",
	},
}

const CURRENCIES := {
	"soul_shards": "res://assets/icons/currency-soul-shards-icon.png",
	"obsidian": "res://assets/icons/currency-obsidian-icon.png",
	"glyphs": "res://assets/icons/currency-glyphs-icon.png",
	"jp": "res://assets/icons/spoils-jp-icon.png",
	"gold": "res://assets/icons/currency-glyphs-icon.png",
	"boss_tokens": "res://assets/icons/currency-boss-tokens-icon.png",
	"phoenix_sigils": "res://assets/icons/currency-phoenix-sigils-icon.png",
	"titan_sigils": "res://assets/icons/currency-titan-sigils-icon.png",
}

const RUN_NODES := {
	"battle": "res://assets/icons/run-node-battle-icon.png",
	"elite": "res://assets/icons/run-node-elite-icon.png",
	"boon": "res://assets/icons/run-node-boon-icon.png",
	"boon_pick": "res://assets/icons/run-node-boon-icon.png",
	"wanderer": "res://assets/icons/run-node-wanderer-icon.png",
	"boss": "res://assets/icons/run-node-boss-icon.png",
	"shop": "res://assets/icons/run-node-shop-icon.png",
	"mystery": "res://assets/icons/run-node-mystery-icon.png",
	"town_1": "res://assets/icons/run-node-town-sanctum-icon.png",
	"town_2": "res://assets/icons/run-node-town-armory-icon.png",
	"town_3": "res://assets/icons/run-node-town-oracle-icon.png",
	"town_sanctum": "res://assets/icons/run-node-town-sanctum-icon.png",
	"town_armory": "res://assets/icons/run-node-town-armory-icon.png",
	"town_oracle": "res://assets/icons/run-node-town-oracle-icon.png",
}

const BOONS := {
	"phoenix_heart": "res://assets/icons/boon-phoenix-heart-icon.png",
	"ember_reprisal": "res://assets/icons/boon-ember-reprisal-icon.png",
	"titan_bulwark": "res://assets/icons/boon-titan-bulwark-icon.png",
	"stone_oath": "res://assets/icons/boon-stone-oath-icon.png",
	"storm_quickening": "res://assets/icons/boon-storm-quickening-icon.png",
	"void_bargain": "res://assets/icons/boon-void-bargain-icon.png",
}

const STATUS_ICONS := {
	"burn": "res://assets/icons/status-burn-icon.png",
	"freeze": "res://assets/icons/status-freeze-icon.png",
	"slow": "res://assets/icons/status-slow-icon.png",
	"curse": "res://assets/icons/status-curse-icon.png",
	"bleed": "res://assets/icons/status-bleed-icon.png",
	"shield": "res://assets/icons/status-shield-icon.png",
	"protect": "res://assets/icons/status-shield-icon.png",
	"wounded": "res://assets/icons/status-wounded-icon.png",
	"downed": "res://assets/icons/status-downed-icon.png",
}

const AFFIX_ICONS := {
	"volatile": "res://assets/icons/affix-volatile-icon.png",
	"fortified": "res://assets/icons/affix-fortified-icon.png",
	"vampiric": "res://assets/icons/affix-vampiric-icon.png",
	"of_frost": "res://assets/icons/affix-of-frost-icon.png",
	"of_flames": "res://assets/icons/affix-of-flames-icon.png",
	"of_void": "res://assets/icons/affix-of-void-icon.png",
}

const JOBS := {
	"knight": "res://assets/icons/job-knight-icon.png",
	"mage": "res://assets/icons/job-mage-icon.png",
	"cleric": "res://assets/icons/job-cleric-icon.png",
	"rogue": "res://assets/icons/job-rogue-icon.png",
	"archer": "res://assets/icons/job-archer-icon.png",
	"guardian": "res://assets/icons/job-guardian-icon.png",
}

const VFX := {
	"fire_impact": "res://assets/vfx/fire-impact-vfx-sheet.png",
	"ice_impact": "res://assets/vfx/ice-impact-vfx-sheet.png",
	"lightning_impact": "res://assets/vfx/lightning-impact-vfx-sheet.png",
	"earth_impact": "res://assets/vfx/earth-impact-vfx-sheet.png",
	"wind_impact": "res://assets/vfx/wind-impact-vfx-sheet.png",
	"dark_impact": "res://assets/vfx/dark-impact-vfx-sheet.png",
	"holy_impact": "res://assets/vfx/holy-impact-vfx-sheet.png",
	"heal": "res://assets/vfx/heal-vfx-sheet.png",
	"buff": "res://assets/vfx/buff-vfx-sheet.png",
	"damage_numbers": "res://assets/vfx/damage-number-floats.png",
}

const GUARDIANS := {
	"phoenix": "res://assets/icons/guardian-phoenix-sigil.png",
	"titan": "res://assets/icons/guardian-titan-sigil.png",
	"storm": "res://assets/icons/guardian-storm-sigil.png",
	"void": "res://assets/icons/guardian-void-sigil.png",
}

# Job class insignias  full-detail SVG badges for job tree, character sheet,
# and any screen that needs the heraldic class mark rather than a small icon.
# Mapping aligns with job IDs used elsewhere; monk/soldier/templar/vagrant are
# additional classes available for future expansion.
const INSIGNIAS := {
	"archer":  "res://assets/ui/insignias/archer.svg",
	"cleric":  "res://assets/ui/insignias/cleric.svg",
	"knight":  "res://assets/ui/insignias/knight.svg",
	"mage":    "res://assets/ui/insignias/mage.svg",
	"monk":    "res://assets/ui/insignias/monk.svg",
	"soldier": "res://assets/ui/insignias/soldier.svg",
	"templar": "res://assets/ui/insignias/templar.svg",
	"vagrant": "res://assets/ui/insignias/vagrant.svg",
}

# Run-node sigils  SVG source art for map node icons.
# These parallel RUN_NODES (which point to generated PNGs); use SIGILS
# when you need vector quality (large display, tooltips, loading screens).
const SIGILS := {
	"battle":   "res://assets/ui/sigils/battle.svg",
	"boon":     "res://assets/ui/sigils/boon.svg",
	"boss":     "res://assets/ui/sigils/boss.svg",
	"elite":    "res://assets/ui/sigils/elite.svg",
	"mystery":  "res://assets/ui/sigils/mystery.svg",
	"wanderer": "res://assets/ui/sigils/wanderer.svg",
}

static func get_tile(tile_id: String) -> Dictionary:
	return TILES.get(tile_id, {})

static func get_prop(prop_id: String) -> String:
	return PROPS.get(prop_id, "")

static func get_unit(unit_id: String) -> Dictionary:
	return UNITS.get(unit_id, ENEMIES.get(unit_id, {}))

static func get_highlight(highlight_id: String) -> String:
	return HIGHLIGHTS.get(highlight_id, "")

static func get_job_icon(job_id: String) -> String:
	return JOBS.get(job_id, "")

static func get_vfx(vfx_id: String) -> String:
	return VFX.get(vfx_id, "")

static func get_currency_icon(currency_id: String) -> String:
	return CURRENCIES.get(currency_id.replace("-", "_"), "")

static func get_run_node_icon(node_type: String) -> String:
	return RUN_NODES.get(node_type.replace("-", "_"), "")

static func get_boon_icon(boon_id: String) -> String:
	return BOONS.get(boon_id.replace("-", "_"), "")

static func get_status_icon(status_id: String) -> String:
	return STATUS_ICONS.get(status_id.replace("-", "_"), "")

static func get_affix_icon(affix_id: String) -> String:
	return AFFIX_ICONS.get(affix_id.replace("-", "_"), "")

static func get_guardian_icon(guardian_id: String) -> String:
	return GUARDIANS.get(guardian_id.replace("-", "_"), "")

static func get_insignia(job_id: String) -> String:
	return INSIGNIAS.get(job_id.replace("-", "_"), "")

static func get_sigil(node_type: String) -> String:
	return SIGILS.get(node_type.replace("-", "_"), "")

static func get_ui_icon(icon_id: String) -> String:
	return UI.get("icons", {}).get(icon_id, "")

static func get_ui_panel(panel_id: String) -> String:
	return UI.get("panels", {}).get(panel_id.replace("-", "_"), "")

static func get_ui_background(background_id: String) -> String:
	return UI.get("backgrounds", {}).get(background_id.replace("-", "_"), "")

static func get_parchment(part: String) -> String:
	return UI.get("parchment", {}).get(part, "")
