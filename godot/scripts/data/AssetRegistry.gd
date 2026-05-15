class_name AssetRegistry
extends RefCounted

# Central Godot asset registry for ProjectTactic.
#
# This file maps stable gameplay IDs to planned asset paths. The paths are
# allowed to point to placeholder files that will be generated later. Keeping
# these IDs stable lets battle, UI, and map systems integrate art without
# repeatedly changing gameplay data.

const TILES := {
        "grass": {
                "id": "grass",
                "label": "Grass",
                "path": "res://assets/tiles/grass-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "dirt": {
                "id": "dirt",
                "label": "Dirt",
                "path": "res://assets/tiles/dirt-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "road": {
                "id": "road",
                "label": "Road",
                "path": "res://assets/tiles/stone-road-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "stone": {
                "id": "stone",
                "label": "Stone",
                "path": "res://assets/tiles/stone-floor-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "wall": {
                "id": "wall",
                "label": "Wall",
                "path": "res://assets/tiles/wall-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "water": {
                "id": "water",
                "label": "Water",
                "path": "res://assets/tiles/water-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "shrine": {
                "id": "shrine",
                "label": "Shrine",
                "path": "res://assets/tiles/shrine-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
        "high_ground": {
                "id": "high-ground",
                "label": "High Ground",
                "path": "res://assets/tiles/high-ground-tile-placeholder.png",
                "prompt_source": "docs/prompts/tilesets-terrain.md",
        },
}

const OVERLAYS := {
        "wet": "res://assets/tiles/wet-overlay-placeholder.png",
        "burning": "res://assets/tiles/burning-overlay-placeholder.png",
        "frozen": "res://assets/tiles/frozen-overlay-placeholder.png",
        "electrified": "res://assets/tiles/electrified-overlay-placeholder.png",
}

const HIGHLIGHTS := {
        "selected": "res://assets/ui/tile-selected-diamond.png",
        "move": "res://assets/ui/tile-move-diamond.png",
        "attack": "res://assets/ui/tile-attack-diamond.png",
        "ability": "res://assets/ui/tile-ability-diamond.png",
        "blocked": "res://assets/ui/tile-blocked-diamond.png",
}

const UNITS := {
        "zane": {
                "id": "zane",
                "display_name": "Zane",
                "role": "Swordsman",
                "idle": "res://assets/characters/zane-idle-placeholder.png",
                "action": "res://assets/characters/zane-action-placeholder.png",
                "portrait": "res://assets/characters/zane-portrait-placeholder.png",
                "prompt_source": "docs/prompts/characters-player-units.md",
        },
        "mira": {
                "id": "mira",
                "display_name": "Mira",
                "role": "Archer",
                "idle": "res://assets/characters/mira-idle-placeholder.png",
                "action": "res://assets/characters/mira-action-placeholder.png",
                "portrait": "res://assets/characters/mira-portrait-placeholder.png",
                "prompt_source": "docs/prompts/characters-player-units.md",
        },
        "kael": {
                "id": "kael",
                "display_name": "Kael",
                "role": "Mage",
                "idle": "res://assets/characters/kael-idle-placeholder.png",
                "action": "res://assets/characters/kael-action-placeholder.png",
                "portrait": "res://assets/characters/kael-portrait-placeholder.png",
                "prompt_source": "docs/prompts/characters-player-units.md",
        },
}

const ENEMIES := {
        "null_drake": {
                "id": "null-drake",
                "display_name": "Null Drake",
                "idle": "res://assets/characters/null-drake-idle-placeholder.png",
                "attack": "res://assets/characters/null-drake-attack-placeholder.png",
                "prompt_source": "docs/prompts/characters-enemies.md",
        },
        "storm_imp": {
                "id": "storm-imp",
                "display_name": "Storm Imp",
                "idle": "res://assets/characters/storm-imp-idle-placeholder.png",
                "attack": "res://assets/characters/storm-imp-attack-placeholder.png",
                "prompt_source": "docs/prompts/characters-enemies.md",
        },
        "fen_wraith": {
                "id": "fen-wraith",
                "display_name": "Fen Wraith",
                "idle": "res://assets/characters/fen-wraith-idle-placeholder.png",
                "attack": "res://assets/characters/fen-wraith-attack-placeholder.png",
                "prompt_source": "docs/prompts/characters-enemies.md",
        },
}

const UI := {
        "panels": {
                "dark_stone": "res://assets/ui/dark-stone-panel.png",
                "command_bar": "res://assets/ui/command-bar-panel.png",
                "turn_order_sidebar": "res://assets/ui/turn-order-sidebar-panel.png",
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
        "damage_numbers": "res://assets/vfx/damage-number-floats.png",
}

const GUARDIANS := {
        "titan": "res://assets/characters/titan-guardian-summon.png",
        "siren": "res://assets/characters/siren-guardian-summon.png",
}

static func get_tile(tile_id: String) -> Dictionary:
        return TILES.get(tile_id, {})

static func get_unit(unit_id: String) -> Dictionary:
        return UNITS.get(unit_id, ENEMIES.get(unit_id, {}))

static func get_highlight(highlight_id: String) -> String:
        return HIGHLIGHTS.get(highlight_id, "")

static func get_job_icon(job_id: String) -> String:
        return JOBS.get(job_id, "")

static func get_vfx(vfx_id: String) -> String:
        return VFX.get(vfx_id, "")
