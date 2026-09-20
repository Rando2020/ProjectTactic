extends Node
# ============================================================
#  THE APPOINTED: AS ABOVE
#  Characters.gd  The Seven character definitions
# ============================================================

#  Complete data for all seven main characters.
#  Access via: Characters.get_character("aeryn")

#  TO SET UP:
#  Project  Project Settings  Autoload
#  Add: res://scripts/autoload/Characters.gd as "Characters"
# ============================================================

const CHARACTERS = {
	"aeryn": {
		"id": "aeryn",
		"human_name": "Aeryn",
		"true_name": "Luciel",
		"true_name_meaning": "Bearer of the First Light",
		"sin": "pride",
		"sin_label": "Pride",
		"costume": "Righteousness",
		"virtue": "Dignity",

		"costume_description": "Aeryn doesn't experience pride as vanity. They experience it as clarity. The world has a right and a wrong and Aeryn can see which is which. This certainty has saved the party many times. It has also cost them things they haven't finished counting.",

		"surface_personality": "The leader. Magnetic, decisive, genuinely moral. The one people naturally defer to because Aeryn is usually right. Calm in crisis. Absolute in judgment. Has a quality of stillness that reads as strength  and sometimes is.",

		"wound": "Aeryn is terrified of being wrong  not for practical reasons but because their entire architecture of self is built on being right. Every decision made with certainty is a load-bearing wall in a structure they cannot allow to be inspected. If they are wrong about this, they might be wrong about everything. And if they're wrong about everything, what are they?",

		"crack_event": "Aeryn meets a soul on the mountain who did exactly what they did  same certainty, same mandate, same peace in the doing of it  for a cause that history has judged catastrophically wrong. From the outside the two are indistinguishable. Aeryn has to sit with one question: how do I know the difference between my certainty and theirs?",

		"resolution": "Dignity without the armor of certainty. The capacity to act without God guaranteeing the outcome in advance. Conviction that can hold uncertainty rather than being destroyed by it. Aeryn becomes the leader who says 'I might be wrong' and leads anyway  and discovers this is harder and more powerful than certainty ever was.",

		"historical_soul": "nebuchadnezzar",
		"job_arc": ["knight", "templar", "devoted"],
		"starting_job": "soldier",

		# Stat lean
		"stats": {"str": 8, "def": 7, "mag": 4, "spd": 5, "fth": 9},

		# Hub dialogue by tier (array of possible lines)
		"hub_dialogue": {
			1: [
				"The objective is clear. I don't understand why the others hesitate.",
				"Every decision has a right answer. Finding it takes discipline.",
				"We've been given a purpose. I won't apologize for pursuing it completely.",
			],
			2: [
				"There was a moment in the last battle... one of them stopped. Just stopped. And looked at me. I don't know what I saw in its face.",
				"I keep making the right calls. I know I keep making the right calls. So why does it feel like something is accumulating?",
			],
			3: [
				"The one who called itself Veriel  it knew my name. Not this name. Something older. I told it that was impossible.",
				"It said: 'You've been here before. Every loop, the same certainty, the same cost. Do you ever ask yourself who taught you to be this sure?' I didn't have an answer. I've been writing one ever since.",
			],
			4: [
				"I met a man today who had been certain about everything. Completely, peacefully certain. He was wrong about all of it. He didn't know. How would he have known? How do I know?",
			],
			5: [
				"It was never about whether I was right enough. I understand that now.",
				"Luciel. Someone said that name to me and I  I felt it land somewhere very deep and old, and I didn't correct them.",
			],
		},

		# Flavor text that shifts by revelation tier
		"flavor_text": {
			1: "Carries conviction like a weapon and has never considered that weapons cut both directions.",
			2: "Something in the certainty has a small cold room inside it that Aeryn does not open.",
			3: "The light that bears them is the same light that makes shadows.",
			4: "Learning to hold what they know and what they don't in the same hand without either falling.",
			5: "The first light, returned to itself.",
		},
	},

	#  CAEL (ENVY)
	"cael": {
		"id": "cael",
		"human_name": "Cael",
		"true_name": "Zaqiel",
		"true_name_meaning": "Purity of God  the keeper of divine justice",
		"sin": "envy",
		"sin_label": "Envy",
		"costume": "Righteous Advocacy",
		"virtue": "Justice",

		"costume_description": "Cael doesn't envy. Cael fights for fairness. For others. Always for others. The work is real, the causes are right, the injustice being fought is genuine. What has never been examined is what fuels it  the personal argument with the universe's distribution that runs underneath every righteous cause like a river under ice.",

		"wound": "To want something for yourself feels like selfishness. To acknowledge the gap between what you have and what you want feels like envy  which Cael knows is ugly. So desire gets laundered through causes. The hunger is real. The direction it travels is a disguise. Cael has been advocating for everyone's right to want things while quietly suffocating their own.",

		"crack_event": "Someone asks Cael what they want. Not for the world. Not for others. For themselves. Right now. One thing. The silence that follows is the longest moment in the game. Cael opens their mouth twice. Nothing comes.",

		"resolution": "The justice that was always there, freed from the personal. Cael who can name what they want without shame  and discovers that wanting things for yourself doesn't make the work for others less real. It makes it sustainable. Justice that includes the self.",

		"historical_soul": "cain",
		"job_arc": ["rogue", "shadow", "chronicler"],
		"starting_job": "archer",
		"stats": {"str": 5, "def": 5, "mag": 7, "spd": 8, "fth": 6},

		"hub_dialogue": {
			1: [
				"The distribution of resources in this camp is irrational. I've adjusted it.",
				"I fight for the ones who can't fight for themselves. That's all this is.",
				"I don't need recognition. The work is the point.",
			],
			2: [
				"I watched one of the enemies hesitate today. Just  hesitate. And I thought: I know that feeling. The moment before you decide.",
				"Why does everyone assume I'm angry? I'm not angry. I'm paying attention.",
			],
			3: [
				"The one called Sidriel said something I can't stop turning over. It said: 'You fight for everyone's worth except your own. Do you know why that is?' I told it it was wrong. I've been arguing with it in my head for three days.",
			],
			4: [
				"Someone asked me today what I want. Just  for myself. I've been trying to answer that question for what feels like a very long time.",
			],
			5: [
				"I wanted to be seen. That's what it was. Under all of it.",
				"Justice that forgets the self isn't justice. It's just a better-dressed hunger.",
			],
		},

		"flavor_text": {
			1: "Carries the world's ledger in their head and checks it constantly, for everyone but themselves.",
			2: "The advocacy is real. The wound that drives it has been patient.",
			3: "Zaqiel, whose virtue was the hunger for what is right  hasn't yet learned that they are included in 'what is right.'",
			4: "Something quiet moving toward something real.",
			5: "Justice, including the self. At last.",
		},
	},

	#  BRENNAN (WRATH)
	"brennan": {
		"id": "brennan",
		"human_name": "Brennan",
		"true_name": "Camael",
		"true_name_meaning": "Burning of God  Strength and divine force",
		"sin": "wrath",
		"sin_label": "Wrath",
		"costume": "Holy Zeal",
		"virtue": "Righteous Anger",

		"wound": "Something was done to Brennan that they have never named. The anger makes complete sense as a response to that original thing. But the original thing is buried under years of righteous causes, and excavating down to it means admitting the anger is about them  which feels like making it small. Making it personal. Which feels like weakness.",

		"crack_event": "They win. The cause is resolved. The injustice is corrected. And within days the anger has found a new home. Brennan is standing in front of a new target with the same fire and the same certainty, and something in them goes very quiet and asks: was this ever about the cause?",

		"resolution": "Righteous anger that knows what it's for. Fire that has a direction and a limit  not because the limit is imposed from outside, but because Brennan finally knows where the fire comes from and has stopped needing it to prove something.",

		"historical_soul": "moses",
		"job_arc": ["soldier", "knight", "fated"],
		"starting_job": "soldier",
		"stats": {"str": 10, "def": 8, "mag": 3, "spd": 6, "fth": 5},

		"hub_dialogue": {
			1: [
				"There's nothing complicated about this. Wrong things get corrected. That's all.",
				"The others think too much. Sometimes you just have to act.",
			],
			3: [
				"The fallen one  Arariel  it said I've been angry since before I can remember. It said: 'You arrived here burning. What did you carry in from before?' I told it to go to hell. Which, technically.",
			],
			4: [
				"I won. The whole thing. Everything we were fighting for, resolved. I thought I'd feel something other than this.",
			],
			5: [
				"The fire is still there. It's just mine now. Not something that happened to me.",
			],
		},

		"flavor_text": {
			1: "The fire arrived before the causes. The causes came to explain it.",
			5: "Burning of God  now burning clean.",
		},
	},

	# Additional characters would continue here...
	# For brevity, I'll add simplified versions of the remaining four

	#  SOLAN (SLOTH)
	"solan": {
		"id": "solan",
		"human_name": "Solan",
		"true_name": "Raziel",
		"sin": "sloth",
		"costume": "Contemplation",
		"virtue": "Sacred Rest",
		"historical_soul": "qoheleth",
		"job_arc": ["mage", "conjurer", "oracle"],
		"starting_job": "mage",
		"stats": {"str": 3, "def": 5, "mag": 10, "spd": 4, "fth": 9},
	},

	#  MIRA (GREED)
	"mira": {
		"id": "mira",
		"human_name": "Mira",
		"true_name": "Sachiel",
		"sin": "greed",
		"costume": "Stewardship",
		"virtue": "Provision",
		"historical_soul": "judas",
		"job_arc": ["vagrant", "rogue", "heretic"],
		"starting_job": "vagrant",
		"stats": {"str": 6, "def": 7, "mag": 5, "spd": 7, "fth": 5},
	},

	#  TOBIAS (GLUTTONY)
	"tobias": {
		"id": "tobias",
		"human_name": "Tobias",
		"true_name": "Muriel",
		"sin": "gluttony",
		"costume": "Bodily Purity",
		"virtue": "Joy",
		"historical_soul": "elijah",
		"job_arc": ["cleric", "summoner", "wanderer"],
		"starting_job": "cleric",
		"stats": {"str": 5, "def": 6, "mag": 7, "spd": 5, "fth": 8},
	},

	#  SEREN (LUST)
	"seren": {
		"id": "seren",
		"human_name": "Seren",
		"true_name": "Anael",
		"sin": "lust",
		"costume": "Celibacy",
		"virtue": "Sacred Love",
		"historical_soul": "david",
		"job_arc": ["archer", "seer", "unbound"],
		"starting_job": "archer",
		"stats": {"str": 5, "def": 4, "mag": 8, "spd": 9, "fth": 7},
	},
}

const PARTY_ORDER = ["aeryn", "cael", "brennan", "solan", "mira", "tobias", "seren"]

#  Functions

func get_character(char_id: String) -> Dictionary:
	return CHARACTERS.get(char_id, {})

func get_all_characters() -> Array:
	var chars = []
	for char_id in PARTY_ORDER:
		chars.append(CHARACTERS[char_id])
	return chars

func get_character_name(char_id: String, use_true_name: bool = false) -> String:
	var char = get_character(char_id)
	if char.is_empty():
		return ""
	if use_true_name and char.get("true_name"):
		return char.true_name
	return char.get("human_name", "")

func get_sin_color(char_id: String) -> Color:
	var char = get_character(char_id)
	if char.is_empty():
		return Color.WHITE
	var sin = char.get("sin", "")
	return GameConfig.get_sin_color(sin)

func get_hub_dialogue(char_id: String, tier: int) -> Array:
	var char = get_character(char_id)
	if char.is_empty():
		return []
	var dialogue_dict = char.get("hub_dialogue", {})
	return dialogue_dict.get(tier, [])

func get_flavor_text(char_id: String, tier: int) -> String:
	var char = get_character(char_id)
	if char.is_empty():
		return ""
	var flavor_dict = char.get("flavor_text", {})
	return flavor_dict.get(tier, "")
