extends Node
# ============================================================
#  THE APPOINTED: AS ABOVE
#  HubCharacters.gd  The inhabitants of the Antechamber
# ============================================================

#  Eight hub characters from various ancient traditions.
#  Access via: HubCharacters.get_character("azrael")

#  TO SET UP:
#  Project  Project Settings  Autoload
#  Add: res://scripts/autoload/HubCharacters.gd as "HubCharacters"
# ============================================================

const HUB_CHARACTERS = {
	"azrael": {
		"id": "azrael",
		"name": "Azrael",
		"title": "The Angel of Accompaniment",
		"location": "The Dock  east edge of the Antechamber",
		"tradition": "Hebrew / Islamic",

		"appearance": "Not what people expect when they hear 'angel of death.' Not terrifying  worn. The face of someone who has been present for every hard moment anyone has ever had, without exception, and has not been broken by it, and doesn't need you to thank him for that. Drinking something from a clay vessel he offers to no one.",

		"role": "Lore delivery. Dry humor. The party's oldest witness.",

		"dialogue": {
			1: [
				"You again. Same party, different loop. Most operations have some kind of turnover.",
				"I've been doing this since before this mountain existed. Take my professional advice: stop fighting everything and talk to some of it.",
				"You want to know how many times you've been here? No. You don't. Not yet.",
			],
			2: [
				"You noticed them hesitating. Good. The new ones are always the most confused  arrived recently and still think they're somewhere else.",
				"I'm not the angel of death, by the way. That's a mistranslation that stuck. I'm the angel of accompaniment. There's a difference. No one dies alone. That's the whole job.",
			],
			3: [
				"The Fallen. I remember them from before they fell. They were the ones who asked the most questions. Still are, technically.",
				"They're not wrong about everything. I'm not saying join them. I'm saying: they're not wrong about everything.",
			],
			4: [
				"You want the number. I can see it. Fine. Are you sure? [beat] Forty-seven loops. You've been here forty-seven times. The record is three hundred and twelve. Different group. They got there. You're doing better than they were at this stage.",
			],
			5: [
				"I've been present at a lot of crossings. Most of them don't look the way people expected. They look like someone finally putting something down.",
				"When it's time  and it will be time soon  I'll be there. That's always been the job. I'm glad it'll be you.",
			],
		},

		"available_from_run": 1,
	},

	"lilith": {
		"id": "lilith",
		"name": "Lilith",
		"title": "The Unbound  She Who Left",
		"location": "The threshold between the Antechamber and the Mountain",
		"tradition": "Hebrew / Kabbalistic",

		"appearance": "Neither the demon of folklore nor the saint of revisionism. Both and neither. Something that has been outside every system long enough to stop needing one. Moves through the Antechamber like she owns it, which in some sense predates anyone else's claim.",

		"role": "The third path. Neither angel nor fallen. The one who escaped the loop  or found its edge.",

		"dialogue": {
			1: [
				"[She is in the corner. She looks at you once. Looks away. There is no hostility in it. She is just  elsewhere.]",
			],
			2: [
				"You keep coming back. That's the design, yes. Most of them don't notice they're designed. Points to you.",
				"The dark corners of this place  they're mine, by prior claim. Just so you know whose space you're in when you come looking for quiet.",
			],
			3: [
				"The Fallen think leaving is freedom. It isn't. I left. What you find outside the system is just  outside the system. It's not better. It's just different cold.",
				"The loop is real. The loop is also not the only thing that's real. I know you can't use that yet. File it.",
			],
			4: [
				"You're asking the right question finally. Not 'how do we finish'  'what are we finishing toward.' Those are not the same question and only one of them has an answer worth having.",
			],
			5: [
				"I've been watching you find your way to the edge of what you were assigned to be. That's where I am. That's where the third thing is.",
				"I won't tell you what's past the threshold. I will tell you: I don't regret the leaving. I don't think you'll regret the staying.",
			],
		},

		"available_from_run": 1,
		"approachable_tier": 3,  # Present but won't talk until Tier 3
	},

	"aurora": {
		"id": "aurora",
		"name": "Aurora",
		"title": "Dawn  the first light after",
		"location": "The threshold to the Mountain",
		"tradition": "Roman",

		"appearance": "Young in the way mornings are young  not naive, but clean. Light that has not yet accumulated the day's weight. Something white that is not quite cloth. Gone before you can look directly at her.",

		"role": "The breakthrough moment. Appears after crack events. Never stays.",

		"dialogue": {
			1: ["[She is at the threshold at the start of each run. She does not speak. She looks at you once. The run begins.]"],
			2: ["Something moved in you just now. I saw it.", "[gone]"],
			3: ["The crack is not damage. The crack is how it opens.", "[gone]"],
			4: ["You are asking the right question.", "[gone]"],
			5: ["It's morning.", "[gone]"],
		},

		"available_from_run": 1,
		"triggered_by_crack_events": true,
	},

	"ereshkigal": {
		"id": "ereshkigal",
		"name": "Ereshkigal",
		"title": "Queen of the Great Below  She Who Remained",
		"location": "A courtyard in the Antechamber  tending a garden",
		"tradition": "Sumerian",

		"appearance": "The oldest queen of the dead in recorded human history  older than the Egyptian system, older than the Greek. Has the bearing of someone who has ruled something genuinely difficult for a very long time and has earned every line of it. Tending the garden without ceremony.",

		"role": "The most genuine ally the party has. Understands their position better than anyone.",

		"dialogue": {
			1: [
				"You look confused about where you are. Most new ones do. You'll stop expecting it to make sense and start expecting it to mean something. Those are different things.",
				"The garden shouldn't grow here. It does anyway. I stopped questioning it.",
			],
			2: [
				"You've been here before, you know. I recognize the shape of how you move. Sit down. I'll tell you what I've noticed.",
				"The ones who get stuck aren't weaker than the ones who go through. They're usually the ones who got close to the truth and got frightened by it.",
			],
			3: [
				"The Fallen came to me once. Offered me a place in their project. I told them I'd already tried leaving and it hadn't solved anything. The mountain is where the work is.",
			],
			4: [
				"I know what you're carrying. I carried something similar for a long time. The question isn't whether the assignment was fair. The question is what you make of where you are.",
			],
			5: [
				"You're ready. I can tell because you stopped trying to leave.",
				"When you go  come back and tell me what it looks like from there. I've always wondered.",
			],
		},

		"available_from_run": 1,
	},

	"somnus": {
		"id": "somnus",
		"name": "Somnus",
		"title": "Sleep  the space between",
		"location": "Found in the Antechamber at what passes for night",
		"tradition": "Roman",

		"appearance": "Soft. Unhurried. Wearing something impractical and comfortable. Often half-present even while speaking  the quality of someone who exists in the liminal space between states professionally and has stopped apologizing for it.",

		"role": "Dream keeper. Between-loop witness. Holds what happens when the party isn't running.",

		"dialogue": {
			1: [
				"Oh. You're awake. Good. That's usually the first step.",
				"You've been dreaming of a light you can't name. Most of you have. I find that interesting.",
			],
			2: [
				"You want to know what you dream about between runs. That's the first time any of you have asked directly. Give me a moment to decide how much to tell you.",
			],
			3: [
				"The Fallen don't dream. They made a choice that took dreaming away from them. I'm not sure they realize what that cost.",
			],
			5: [
				"The dream you're having now is different from the one you were having at the start. I keep records. Would you like to know how they've changed? It's rather beautiful, actually.",
			],
		},

		# Dream reveals by character (given at specific moments)
		"dream_reveals": {
			"aeryn": "You dream of being wrong about something important. Every time. And in the dream, being wrong doesn't end you. You keep being surprised by this.",
			"cael": "You dream of being asked what you want. And answering. You never remember what you said when you wake up.",
			"brennan": "You dream of a moment before the fire. There is always a moment before the fire. You've been trying to stay in that moment longer each time.",
			"solan": "You dream of being called back to something. You keep going the wrong direction on purpose. You know you're doing it. This is important.",
			"mira": "You dream of giving something away  not from abundance, from the last of what you have. And then you dream of what comes after, which is not what you expected.",
			"tobias": "You dream of a meal you've never had. You are entirely in it. When you wake up you can't remember what it tasted like but you can remember what it felt like to be there.",
			"seren": "You dream of being seen. Just seen. Not desired, not admired. Just met. You always cry in this dream. You never know why when you wake up.",
		},

		"available_from_run": 5,
	},

	"osiris": {
		"id": "osiris",
		"name": "Osiris",
		"title": "The Displaced Judge",
		"location": "An old office in the Antechamber",
		"tradition": "Egyptian",

		"appearance": "Green-skinned in the traditional depiction  not sickly, verdant. Something about him suggests things that died and came back changed. Formal in the way that people who ran something large and just for a very long time stay formal after circumstances shift.",

		"role": "The institutional perspective. Critic and, eventually, unexpected ally.",

		"dialogue": {
			1: [
				"You don't know where you are and you move with confidence anyway. That's either courage or foolishness. In my experience the difference only emerges in retrospect.",
			],
			2: [
				"I spent my tenure weighing hearts. Every heart, against the feather of truth. Simple. Clean. Just. What I could not do was change what was in the heart before the weighing. This mountain does that. I have watched it do that.",
			],
			3: [
				"The Fallen were processed through my system before they fell. I have their records. They all weighed clean. They fell after. That's the thing about the old system: it measured what was. It couldn't account for what would become.",
			],
			4: [
				"I spent a long time resenting the replacement of my work. I've arrived at a different position. The weighing was justice. This mountain is trying to be mercy.",
			],
			5: [
				"I've watched dozens of parties complete this. Every single one of them passed through this antechamber at the end. Not one of them looked the way they expected to look when they made it. They looked lighter. That's all. Just lighter.",
			],
		},

		"available_from_run": 10,
		"introduced_by": "ereshkigal",
	},

	"anamnesis": {
		"id": "anamnesis",
		"name": "Anamnesis",
		"title": "The Holy Remembering  the pool of return",
		"location": "The deepest part of the Antechamber",
		"tradition": "Greek Theological / Catholic Liturgical",

		"appearance": "You are not entirely sure she has a form. There is a presence near the water. The water is impossibly clear and impossibly still and looking into it is not entirely comfortable. She is the pool and the presence beside it and the quality of attention you feel when you stand near still water and something looks back.",

		"role": "Late-game memory return. The mechanism of true names. Not a quest  an arrival.",

		"dialogue": {
			2: ["[The pool is still. Nothing happens. But you feel, standing here, that something knows you are standing here.]"],
			3: ["[Something surfaces in the water  not an image. A feeling. The feeling of being someone specific, in a moment before this one, making a choice you said yes to. The feeling fades before you can hold it.]"],
			5: ["[The pool shows you your own face. Not the one you're wearing. The other one. You recognize it.]"],
		},

		# Memory fragments returned at Tier 4
		"memory_fragments": {
			"aeryn": "You are standing in light so complete it has no source. You are asked if you will carry it. You say yes.",
			"cael": "You are given a set of scales. You hold them perfectly steady. You have never held anything this carefully. You say yes.",
			"brennan": "You are shown something unjust. The fire rises in you  clean and clear. It does not destroy the one who shows you. You say yes.",
			"solan": "You are given every mystery. All at once. You are asked if you can hold it without it becoming a weight. You say yes.",
			"mira": "You are given a world and told: there is enough. Care for what is here. You look at it and believe it. You say yes.",
			"tobias": "You are given the capacity for joy. Complete, unguarded. You are told: this is what existence is supposed to feel like. You say yes.",
			"seren": "You are given the ability to love without consuming. To know fully and hold gently. You are shown what this looks like and it is the most beautiful thing you have seen. You say yes.",
		},

		"available_from_run": 1,
		"functions_at_tier": 3,  # Present but doesn't function until Tier 3
	},

	"archivist": {
		"id": "archivist",
		"name": "Casimir",
		"title": "The Archivist",
		"location": "A library corner of the Antechamber",
		"tradition": "Original  fully human",

		"appearance": "Old in a purely human way. Ink stains. Reading glasses. More records than anyone asked him to keep. Warm  genuinely, simply warm in a way that makes the Antechamber feel livable. The only person here who is entirely and unambiguously human. This is the most important thing about him.",

		"role": "Lore delivery without exposition. The human heart of the hub. Will know before anyone tells him.",

		"dialogue": {
			1: [
				"You look like you've been somewhere interesting. Sit down. Tell me what you saw.",
				"I've been charting the pattern for thirty years. Every hundred years, the same conflicts. Different names. Same shape. I used to think it was coincidence.",
			],
			2: [
				"I've been having a very strange feeling lately. That I've done this work before. Not just studied history  that I specifically have studied these specific patterns before.",
				"I found a reference to something called 'The Appointed' in a medieval text. Seven figures. Sent to walk with humanity. I've been trying to find more references. There aren't many. It's like someone removed them.",
			],
			3: [
				"I have to ask you something and I need you to answer honestly. Have you been to this mountain before? Not in memory. In fact. Because if you have, there are things in my records I need to show you.",
			],
			4: [
				"I know what you are. I've known for three weeks and I've been deciding whether to say anything. It changes the work but it doesn't change the work, if you understand me. The patterns are still the patterns. It just explains why someone needed to understand them from the inside.",
			],
			5: [
				"Everything I've spent my life recording  the cycles, the patterns, the repetition  it's all one thing, isn't it. It's one very long sentence that humanity keeps starting over because they keep losing the beginning.",
				"Go finish it. I'll keep the records.",
			],
		},

		"available_from_run": 1,
	},
}

const HUB_CHARACTER_IDS = ["azrael", "lilith", "aurora", "ereshkigal", "somnus", "osiris", "anamnesis", "archivist"]

#  Functions

func get_character(hub_char_id: String) -> Dictionary:
	return HUB_CHARACTERS.get(hub_char_id, {})

func get_dialogue(hub_char_id: String, tier: int) -> Array:
	var char = get_character(hub_char_id)
	if char.is_empty():
		return []
	var dialogue_dict = char.get("dialogue", {})
	return dialogue_dict.get(tier, [])

func get_dream_reveal(hub_char_id: String, char_id: String) -> String:
	if hub_char_id != "somnus":
		return ""
	var char = get_character(hub_char_id)
	if char.is_empty():
		return ""
	var reveals = char.get("dream_reveals", {})
	return reveals.get(char_id, "")

func get_memory_fragment(char_id: String) -> String:
	var anamnesis = get_character("anamnesis")
	if anamnesis.is_empty():
		return ""
	var fragments = anamnesis.get("memory_fragments", {})
	return fragments.get(char_id, "")

func is_available(hub_char_id: String, current_run: int, current_tier: int) -> bool:
	var char = get_character(hub_char_id)
	if char.is_empty():
		return false

	var required_run = char.get("available_from_run", 1)
	if current_run < required_run:
		return false

	# Check if requires minimum tier
	if char.has("functions_at_tier") and current_tier < char.functions_at_tier:
		return false

	if char.has("approachable_tier") and current_tier < char.approachable_tier:
		return false

	return true
