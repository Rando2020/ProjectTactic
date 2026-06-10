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
	"selected": "res://assets/generated/ui/tile-selected-diamond.png",
	"move": "res://assets/generated/ui/tile-move-diamond.png",
	"attack": "res://assets/generated/ui/tile-attack-diamond.png",
	"ability": "res://assets/generated/ui/tile-ability-diamond.png",
	"blocked": "res://assets/generated/ui/tile-blocked-diamond.png",
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
		"dark_stone": "res://assets/generated/ui/dark-stone-panel.png",
		"command_bar": "res://assets/generated/ui/command-bar-panel.png",
		"turn_order_sidebar": "res://assets/generated/ui/turn-order-sidebar-panel.png",
		"hub_dark_gold": "res://assets/generated/ui/hub-panel-dark-gold.png",
		"guardian_shrine": "res://assets/generated/ui/guardian-shrine-panel.png",
		"job_reliquary": "res://assets/generated/ui/job-reliquary-panel.png",
		"heat_altar": "res://assets/generated/ui/heat-altar-panel.png",
		"reward_card": "res://assets/generated/ui/reward-card-panel.png",
	},
	"backgrounds": {
		"hub_last_hearth": "res://assets/backgrounds/hub-background-last-hearth.png",
	},
	"command_icons": {
		"move": "res://assets/generated/icons/command-move-icon.png",
		"attack": "res://assets/generated/icons/command-attack-icon.png",
		"ability": "res://assets/generated/icons/command-ability-icon.png",
		"item": "res://assets/generated/icons/command-item-icon.png",
		"wait": "res://assets/generated/icons/command-wait-icon.png",
	},
	"bars": {
		"hp": "res://assets/generated/ui/hp-bar-frame.png",
		"temper": "res://assets/generated/ui/temper-bar-frame.png",
		"ether": "res://assets/generated/ui/ether-bar-frame.png",
	},
	# Bell icons  use in audio settings panel (mute/unmute toggle)
	"icons": {
		"bell":      "res://assets/ui/icons/bell.svg",
		"bell_mute": "res://assets/ui/icons/bell_mute.svg",
	},
	# Parchment  use as background/corner for dialogue boxes and narrative interludes
	"parchment": {
		"bg":     "res://assets/ui/parchment/parchment_bg.png",
		"corner": "res://assets/ui/parchment/parchment_corner.svg",
	},
}

const CURRENCIES := {
	"soul_shards": "res://assets/generated/icons/currency-soul-shards-icon.png",
	"obsidian": "res://assets/generated/icons/currency-obsidian-icon.png",
	"glyphs": "res://assets/generated/icons/currency-glyphs-icon.png",
	"boss_tokens": "res://assets/generated/icons/currency-boss-tokens-icon.png",
	"phoenix_sigils": "res://assets/generated/icons/currency-phoenix-sigils-icon.png",
	"titan_sigils": "res://assets/generated/icons/currency-titan-sigils-icon.png",
}

const RUN_NODES := {
	"battle": "res://assets/generated/icons/run-node-battle-icon.png",
	"elite": "res://assets/generated/icons/run-node-elite-icon.png",
	"boon": "res://assets/generated/icons/run-node-boon-icon.png",
	"wanderer": "res://assets/generated/icons/run-node-wanderer-icon.png",
	"boss": "res://assets/generated/icons/run-node-boss-icon.png",
	"shop": "res://assets/generated/icons/run-node-shop-icon.png",
	"town_1": "res://assets/generated/icons/run-node-shop-icon.png",
	"town_2": "res://assets/generated/icons/run-node-shop-icon.png",
	"town_3": "res://assets/generated/icons/run-node-shop-icon.png",
}

const BOONS := {
	"phoenix_heart": "res://assets/generated/icons/boon-phoenix-heart-icon.png",
	"ember_reprisal": "res://assets/generated/icons/boon-ember-reprisal-icon.png",
	"titan_bulwark": "res://assets/generated/icons/boon-titan-bulwark-icon.png",
	"stone_oath": "res://assets/generated/icons/boon-stone-oath-icon.png",
	"storm_quickening": "res://assets/generated/icons/boon-storm-quickening-icon.png",
	"void_bargain": "res://assets/generated/icons/boon-void-bargain-icon.png",
}

const STATUS_ICONS := {
	"burn": "res://assets/generated/icons/status-burn-icon.png",
	"freeze": "res://assets/generated/icons/status-freeze-icon.png",
	"slow": "res://assets/generated/icons/status-slow-icon.png",
	"curse": "res://assets/generated/icons/status-curse-icon.png",
	"bleed": "res://assets/generated/icons/status-bleed-icon.png",
	"shield": "res://assets/generated/icons/status-shield-icon.png",
}

const AFFIX_ICONS := {
	"volatile": "res://assets/generated/icons/affix-volatile-icon.png",
	"fortified": "res://assets/generated/icons/affix-fortified-icon.png",
	"vampiric": "res://assets/generated/icons/affix-vampiric-icon.png",
	"of_frost": "res://assets/generated/icons/affix-of-frost-icon.png",
	"of_flames": "res://assets/generated/icons/affix-of-flames-icon.png",
	"of_void": "res://assets/generated/icons/affix-of-void-icon.png",
}

const JOBS := {
	"knight": "res://assets/generated/icons/job-knight-icon.png",
	"mage": "res://assets/generated/icons/job-mage-icon.png",
	"cleric": "res://assets/generated/icons/job-cleric-icon.png",
	"rogue": "res://assets/generated/icons/job-rogue-icon.png",
	"archer": "res://assets/generated/icons/job-archer-icon.png",
	"guardian": "res://assets/generated/icons/job-guardian-icon.png",
}

const VFX := {
	"fire_impact": "res://assets/generated/vfx/fire-impact-vfx-sheet.png",
	"ice_impact": "res://assets/generated/vfx/ice-impact-vfx-sheet.png",
	"lightning_impact": "res://assets/generated/vfx/lightning-impact-vfx-sheet.png",
	"earth_impact": "res://assets/generated/vfx/earth-impact-vfx-sheet.png",
	"wind_impact": "res://assets/generated/vfx/wind-impact-vfx-sheet.png",
	"dark_impact": "res://assets/generated/vfx/dark-impact-vfx-sheet.png",
	"holy_impact": "res://assets/generated/vfx/holy-impact-vfx-sheet.png",
	"heal": "res://assets/generated/vfx/heal-vfx-sheet.png",
	"buff": "res://assets/generated/vfx/buff-vfx-sheet.png",
	"damage_numbers": "res://assets/generated/vfx/damage-number-floats.png",
}

const GUARDIANS := {
	"phoenix": "res://assets/generated/icons/guardian-phoenix-sigil.png",
	"titan": "res://assets/generated/icons/guardian-titan-sigil.png",
	"storm": "res://assets/generated/icons/guardian-storm-sigil.png",
	"void": "res://assets/generated/icons/guardian-void-sigil.png",
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

static func get_parchment(part: String) -> String:
	return UI.get("parchment", {}).get(part, "")
