extends Node
class_name GameConfig
# ============================================================
#  THE APPOINTED: AS ABOVE
#  GameConfig.gd  Global constants, tier definitions, palette
# ============================================================

#  This is an autoload singleton.
#  Access anywhere via: GameConfig.PALETTE.HUB_BG

#  TO SET UP:
#  Project  Project Settings  Autoload
#  Add: res://scripts/autoload/GameConfig.gd as "GameConfig"
# ============================================================

#  Game Identity
const GAME_TITLE = "The Appointed"
const GAME_SUBTITLE = "As Above"
const GAME_FULL_TITLE = "The Appointed: As Above"

#  Revelation Tiers
# How much truth has been uncovered. Affects what every system shows.
enum RevelationTier {
	TIER_1 = 1,  # The War
	TIER_2 = 2,  # The Cracks
	TIER_3 = 3,  # The Fallen
	TIER_4 = 4,  # The Pattern
	TIER_5 = 5,  # The Ascent
}

const TIER_LABELS = {
	1: "The War",
	2: "The Cracks",
	3: "The Fallen",
	4: "The Pattern",
	5: "The Ascent",
}

# Total revelation points needed to unlock each tier
const TIER_THRESHOLDS = {
	1: 0,
	2: 150,
	3: 400,
	4: 750,
	5: 1200,
}

#  Clarity Meter (per-run resource)
const CLARITY = {
	"MIN": 0,
	"MAX": 100,
	"START": 30,

	# Gains
	"SOUL_CONVERSATION": 8,
	"BOSS_DIALOGUE_UNLOCKED": 15,
	"HUB_RELATIONSHIP_MOMENT": 10,
	"CRACK_EVENT_TRIGGERED": 20,
	"TRUE_NAME_FRAGMENT": 25,

	# Losses
	"SIN_UNCHECKED": -5,
	"SOUL_ABANDONED": -10,
	"FALLEN_ARGUMENT_FLED": -8,
}

#  Costume Integrity (100  0 reveals true name)
const COSTUME_INTEGRITY = {
	"START": 100,
	"CRACK_EVENT": -15,
	"MIRROR_ENCOUNTER": -20,
	"HISTORICAL_SOUL_MET": -10,
	"TRUE_NAME_FRAGMENT": -12,
	"HUB_DEEP_CONVERSATION": -8,
	"BOSS_SEES_THROUGH": -18,
}

#  Run Milestones
const RUN_MILESTONES = {
	"FIRST_CRACK": 3,
	"FIRST_SOUL": 5,
	"BOSS_FIRST_MEMORY": 7,
	"AZRAEL_OPENS_UP": 10,
	"ENEMY_SPEAKS": 12,
	"ANAMNESIS_AVAILABLE": 15,
	"ADAM_AVAILABLE": 20,
	"FALLEN_REMEMBER_YOU": 25,
}

#  Palette
const PALETTE = {
	# Hub  warm decay, holy ruin
	"HUB_BG": Color("#0a0806"),
	"HUB_WARM": Color("#c8a96e"),
	"HUB_STONE": Color("#3d3530"),
	"HUB_LIGHT": Color("#f0e8d0"),
	"HUB_SHADOW": Color("#1a1410"),

	# Mountain  cold, ascending
	"MOUNTAIN_BG": Color("#070a0f"),
	"MOUNTAIN_MIST": Color("#8fa3b8"),
	"MOUNTAIN_ICE": Color("#c8dde8"),

	# Sin colors  each character has a thematic color
	"PRIDE_GOLD": Color("#d4af37"),
	"ENVY_VERDIGRIS": Color("#4a8c6f"),
	"WRATH_CRIMSON": Color("#9b2335"),
	"SLOTH_DUSK": Color("#6b5b8a"),
	"GREED_AMBER": Color("#b8860b"),
	"GLUTTONY_ASH": Color("#8a9a8a"),
	"LUST_IVORY": Color("#e8d8c8"),

	# Revelation tier colors  shift as truth is uncovered
	"TIER_1": Color("#4a6fa5"),    # cold blue  tactical
	"TIER_2": Color("#7a5c8a"),    # violet  unease
	"TIER_3": Color("#8a3a3a"),    # deep red  fallen
	"TIER_4": Color("#c8a040"),    # gold  understanding
	"TIER_5": Color("#e8e0d0"),    # near-white  transcendence
}

#  Font Paths
const FONTS = {
	"DISPLAY":       "res://assets/fonts/TrajanPro-Regular.ttf",
	"DISPLAY_BOLD":  "res://assets/fonts/TrajanPro-Bold.otf",
	"TITLE":         "res://assets/fonts/CinzelDecorative-Regular.ttf",
	"HEADER":        "res://assets/fonts/Cinzel-Bold.ttf",
	"HEADER_MEDIUM": "res://assets/fonts/Cinzel-Medium.ttf",
	"HEADER_LIGHT":  "res://assets/fonts/Cinzel-Regular.ttf",
	"BODY":          "res://assets/fonts/CrimsonText-Regular.ttf",
	"UI":            "res://assets/fonts/CormorantGaramond-Regular.ttf",
}

#  Sin / Virtue Map
# The core theological engine of the game
const SIN_VIRTUE_MAP = {
	"pride": {
		"sin": "Pride",
		"costume": "Righteousness",
		"virtue": "Dignity",
		"color": PALETTE.PRIDE_GOLD
	},
	"envy": {
		"sin": "Envy",
		"costume": "Righteous Advocacy",
		"virtue": "Justice",
		"color": PALETTE.ENVY_VERDIGRIS
	},
	"wrath": {
		"sin": "Wrath",
		"costume": "Holy Zeal",
		"virtue": "Righteous Anger",
		"color": PALETTE.WRATH_CRIMSON
	},
	"sloth": {
		"sin": "Sloth",
		"costume": "Contemplation",
		"virtue": "Sacred Rest",
		"color": PALETTE.SLOTH_DUSK
	},
	"greed": {
		"sin": "Greed",
		"costume": "Stewardship",
		"virtue": "Provision",
		"color": PALETTE.GREED_AMBER
	},
	"gluttony": {
		"sin": "Gluttony",
		"costume": "Bodily Purity",
		"virtue": "Joy",
		"color": PALETTE.GLUTTONY_ASH
	},
	"lust": {
		"sin": "Lust",
		"costume": "Celibacy",
		"virtue": "Sacred Love",
		"color": PALETTE.LUST_IVORY
	},
}

#  Helper Functions

static func get_tier_label(tier: int) -> String:
	return TIER_LABELS.get(tier, "Unknown")

static func get_tier_color(tier: int) -> Color:
	match tier:
		1: return PALETTE.TIER_1
		2: return PALETTE.TIER_2
		3: return PALETTE.TIER_3
		4: return PALETTE.TIER_4
		5: return PALETTE.TIER_5
		_: return Color.WHITE

static func get_sin_color(sin: String) -> Color:
	var data = SIN_VIRTUE_MAP.get(sin, {})
	return data.get("color", Color.WHITE)

static func calculate_tier_from_points(points: int) -> int:
	var tier = 1
	for t in [5, 4, 3, 2, 1]:
		if points >= TIER_THRESHOLDS[t]:
			tier = t
			break
	return tier
