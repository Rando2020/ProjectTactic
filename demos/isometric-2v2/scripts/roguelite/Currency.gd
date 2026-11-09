class_name Currency
extends RefCounted

const SOUL_SHARDS := "soul-shards"
const OBSIDIAN := "obsidian"
const GLYPHS := "glyphs"
const BOSS_TOKENS := "boss-tokens"
const RUN_AETHER := "run-aether"

static func display_name(currency_id: String) -> String:
	match currency_id:
		SOUL_SHARDS: return "Soul Shards"
		OBSIDIAN: return "Obsidian"
		GLYPHS: return "Glyphs"
		BOSS_TOKENS: return "Boss Tokens"
		RUN_AETHER: return "Aether"
		_:
			if currency_id.ends_with("-sigils"):
				return currency_id.replace("-", " ").capitalize()
			return currency_id.replace("-", " ").capitalize()

static func is_meta_currency(currency_id: String) -> bool:
	return currency_id in [SOUL_SHARDS, OBSIDIAN, GLYPHS, BOSS_TOKENS] or currency_id.ends_with("-sigils")
