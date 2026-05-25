## HubDialogue.gd
## Four hub characters who react to your run history.
## Hades-style: they remember what happened and say something specific.
##
## Characters:
##   Sera        The Hearth keeper. Warm, observant, practical.
##   Varn        Watch veteran. Blunt, tactical, dry.
##   Volant      Bellkeeper Archivist. Academic, precise, quietly amazed.
##   The Echo    Appears rarely. Cryptic. Possibly Vaelthorn's voice.

class_name HubDialogue
extends RefCounted

const CHARACTERS: Dictionary = {

	"sera": {
		"name":    "Sera",
		"title":   "Keeper of the Last Hearth",
		"portrait":"?",
		"color":   Color(0.98, 0.82, 0.55),
		"lines": {
			"first_run": [
				'"You came back. Good. Some don\'t, the first time."',
				'"The Hearth remembers everyone who\'s passed through. It will remember you."',
				'"Don\'t look at the door like that. You\'re not leaving again until you\'re ready."',
			],
			"floor_1_3": [
				'"That far. Floor {floor}. The first few are always the hardest to read."',
				'"You\'re learning the shape of it. That\'s not nothing."',
				'"The Anchors don\'t care how many times you\'ve tried. But I do."',
				'"I\'ve seen people turn back at floor two and come back to clear all ten. You\'re still here."',
			],
			"floor_4_6": [
				'"Floor {floor}. You\'re past the first wall now. That means something."',
				'"The Void Golems start appearing around there. They know you\'re coming."',
				'"Halfway. The second half is different  the enemies know the terrain better than you do."',
			],
			"floor_7_9": [
				'"Floor {floor}. You almost touched it. I could feel the resonance shift."',
				'"That\'s close. That\'s really close. Whatever you had  it nearly worked."',
				'"The Thornspire knows your name now. That\'s not a comfort, but it\'s true."',
			],
			"run_complete": [
				'"You did it. The Anchor is shattered. The resonance held."',
				'"I wasn\'t sure, at the end. But the Hearth is still standing. So are you."',
				'"Every run I watch people leave through that door. Not many come back having done what you just did."',
			],
			"died_to_elite": [
				'"An elite. {killer}. Those affixes  they compound. Next time, read them before the first move."',
				'"Champion-tier on that floor? That\'s the Null Resonance doing its work."',
				'"Elites are the Void\'s way of saying it noticed you. Take that as a compliment, then dodge next time."',
			],
			"died_to_anchor": [
				'"The Anchor\'s pulse. You got close  so close that it started enraging. That\'s actually progress."',
				'"It pulses harder below half health. You needed a few more holy hits before it shifted phases."',
			],
			"had_curses": [
				'"You carried {curse_count} curse{plural}. That takes nerve. Most people wait until the run is already going well."',
				'"The curses make it harder and stranger. That\'s the point. You\'ll find the combinations that work."',
			],
			"high_heat": [
				'"Heat {heat}. You\'re not making it easy on yourself. Good."',
			],
			"default": [
				'"The Hearth is still lit. That\'s enough for now."',
				'"Rest. There\'s time before the next run."',
				'"You learn more from the floors you didn\'t clear than the ones you did."',
			],
		},
	},

	"varn": {
		"name":    "Varn",
		"title":   "Last of the Ashvale Watch",
		"portrait":"?",
		"color":   Color(0.65, 0.78, 0.95),
		"lines": {
			"first_run": [
				'"First run. You survived. That\'s the bar. You cleared it."',
				'"The Watch used to train recruits for three months before sending them to the Outskirts. You went in blind. Respect."',
				'"Don\'t let floor one fool you. The Null Drakes at floor seven are the same creature with different numbers."',
			],
			"floor_1_3": [
				'"Floor {floor}. The Cultists are the ones to watch  they die fast but they\'ll drain your Ether if you let them cast."',
				'"You\'re reading the terrain wrong. Water plus thunder. That\'s the opening move on every wet-terrain floor."',
				'"Storm Imps move four tiles. Keep your Arcanist out of their range or you\'re spending heals before you need to."',
			],
			"floor_4_6": [
				'"Floor {floor}. The Fen Wraiths start there. Holy\'s the answer. If Mira\'s at full Ether, they\'re not a problem."',
				'"You made it past the first boon pick. Whatever you chose  it\'s shaping the run now."',
				'"The second half demands you stop reacting and start positioning. Wall of Iron, then advance."',
			],
			"floor_7_9": [
				'"Floor {floor}. Void Golems. Slow, but the reach surprises people. Don\'t let them corner Mira."',
				'"Almost. The Watch had a saying: \'The run you almost cleared teaches more than the ten you won.\' I don\'t know if that\'s true, but I believed it for twenty years."',
			],
			"run_complete": [
				'"Anchor\'s down. Good work. Clean execution."',
				'"That\'s the job. Rest, then we figure out what the next one looks like."',
				'"The Watch cleared three Anchors in six months. You just matched the pace. I\'ll note that."',
			],
			"died_to_elite": [
				'"That affix. {killer}. You saw it coming  the Void Sight boon would have shown you the affix before the fight."',
				'"Volatile. Classic. The explosion radius is two tiles. Keep your units spread and it\'s a non-event."',
				'"Champion-tier this early means the Null Resonance curse has been active. Check the curse stack before you commit."',
			],
			"died_to_anchor": [
				'"The pulse hits everything within two tiles. The solution is ranged holy  Mira from three tiles out, Kael holds the Golem."',
				'"Phase two fires twice on adjacent tiles. You need to back off at fifty percent or you lose your tank."',
			],
			"had_curses": [
				'"Storm Debt with Stormglass Timing negates itself. That\'s the kind of combination the Watch used to call a \'calculated loss that isn\'t.\'"',
				'"Curses compound. Two is a build. Three is a run identity. Four is something I\'d want to watch."',
			],
			"default": [
				'"Keep moving. The Anchor doesn\'t wait."',
				'"What went wrong is fixable. What went right  remember that."',
				'"The run that kills you is the one where you stopped adapting. Don\'t stop adapting."',
			],
		},
	},

	"volant": {
		"name":    "Archive Mage Volant",
		"title":   "Bellkeeper Researcher",
		"portrait":"?",
		"color":   Color(0.53, 0.94, 0.67),
		"lines": {
			"first_run": [
				'"Fascinating. Your resonance signature has already shifted from exposure to the Anchor\'s field. I\'ll note that."',
				'"First run. Floor {floor}. I\'ll add it to the record. The Bellkeepers have tracked three hundred and twelve runs against this specific Anchor complex."',
				'"You survived. That puts you in the top forty-two percent of first-run incursions. I\'m not sure if that\'s comforting."',
			],
			"floor_4_6": [
				'"Floor {floor}. The resonance data from that depth is significantly different from the upper floors. The Anchor is actively influencing the terrain."',
				'"You\'re past the first ley confluence. That\'s where three of my previous field researchers didn\'t return. You\'re doing better than them."',
			],
			"floor_7_9": [
				'"Floor {floor}. The record for a first-month incursion is floor nine. You matched it. I\'ll update my projections."',
				'"The Void Golem\'s movement pattern is predictable once you\'ve seen it six times. You\'ve seen it once. That\'s the gap."',
				'"Extraordinary. The elemental reactions at this depth are  I\'m getting ahead of myself. Come back and I\'ll share the data."',
			],
			"run_complete": [
				'"The Anchor is shattered. I\'ve waited twelve years to write that sentence. Thank you."',
				'"I need to update every model I\'ve built. This changes the resonance field entirely. Remarkable."',
			],
			"died_to_elite": [
				'"The {killer} prefix combination  I\'ve documented fourteen encounters with that specific pairing. Eleven of them ended similarly. The counter is elemental disruption before engagement."',
				'"An elite at that floor is statistically within normal parameters. What\'s interesting is the affix interaction. I\'d like to discuss it when you have time."',
			],
			"boon_observation": [
				'"You selected {boon_count} boon{plural} from the Guardian pool. The resonance signature from Ignareth\'s boons is particularly strong this run."',
				'"The curse-boon interaction data from your run is invaluable. Champion\'s Grit against the Null Resonance curse specifically  I\'ve been waiting for that dataset."',
			],
			"died_to_anchor": [
				'"The phase transition at fifty percent HP is documented but the timing varies by three-point-seven seconds based on terrain state. That variance matters at close range."',
				'"Holy resonance disrupts the pulse cycle by approximately one-point-two turns if applied correctly. Mira\'s Consecrate ability would introduce that disruption."',
			],
			"default": [
				'"Every run adds to the record. This one included."',
				'"The data you generate is valuable even when the run ends early."',
				'"Twelve years of documentation. Your contribution to the record is noted."',
			],
		},
	},

	"the_echo": {
		"name":    "The Echo",
		"title":   "Origin Unknown",
		"portrait":"?",
		"color":   Color(0.66, 0.33, 0.97),
		"lines": {
			"first_run": [
				'"You felt it. The pull toward the Vault. That\'s not courage. That\'s recognition."',
				'"The resonance knows you. It has for longer than you realise."',
			],
			"run_complete": [
				'"The Anchor falls. The resonance breathes. Neither of us expected this."',
				'"You shattered it. Now the field is open. Something else will fill it. It always does."',
			],
			"had_curses": [
				'"The curses are not punishments. They are invitations. Some of them, anyway."',
				'"Vaelthorn\'s Hunger. You know what it costs. You took it anyway. That means something."',
			],
			"died_to_anchor": [
				'"The Anchor does not hate you. It simply doesn\'t know you yet."',
				'"Void energy recognises holy energy the way fire recognises water. Point that at it."',
			],
			"floor_7_9": [
				'"Floor {floor}. The resonance at that depth is almost aware. Almost."',
				'"You felt the Anchor\'s attention. That\'s new. That\'s significant."',
			],
			"default": [
				'"..."',
				'"The resonance shifts when you enter. I notice that."',
				'"Come back. The Vault will be different. So will you."',
			],
		},
	},
}


## Select the best dialogue line for a character based on run context.
static func get_line(character_id: String, gs: Node) -> Dictionary:
	var char_data: Dictionary = CHARACTERS.get(character_id, {})
	if char_data.is_empty(): return {}

	var lines: Dictionary = char_data.get("lines", {})
	var death: Dictionary = gs.get("last_run_death") if gs else {}
	var reached_floor: int = int(gs.get("run_floor_reached")) if gs else 0
	var runs: int = int(gs.get("runs_completed")) if gs else 0
	var heat:  int = 0
	var rm: Node = Engine.get_main_loop().root.get_node_or_null("/root/RunManager") if Engine.get_main_loop() else null
	if rm: heat = rm.heat_level
	var story_flags: Array = []
	if gs and gs.get("story_flags") != null:
		story_flags = gs.story_flags
	var met_wanderer := story_flags.has("met_orren")
	var active_curses: Array = []
	var active_boons:  Array = []
	if gs and gs.get("active_run") and gs.active_run:
		active_curses = gs.active_run.active_curses
		active_boons  = gs.active_run.active_boons
	# Check the PREVIOUS run's boons via last_run_death context
	var had_curses: bool = active_curses.size() > 0 or (int(death.get("had_curses", 0)) > 0)
	var was_complete: bool = (reached_floor >= 10 and death.is_empty())
	var died_anchor: bool = death.get("was_anchor", false) == true
	var died_elite: bool = death.get("was_elite", false) == true and not died_anchor

	# Priority selection
	var category := "default"
	if met_wanderer:
		category = "met_wanderer"
	elif runs == 0 and reached_floor == 0:
		category = "first_run"
	elif was_complete:
		category = "run_complete"
	elif died_anchor:
		category = "died_to_anchor"
	elif died_elite:
		category = "died_to_elite"
	elif had_curses:
		category = "had_curses"
	elif heat >= 2:
		category = "high_heat"
	elif reached_floor >= 7:
		category = "floor_7_9"
	elif reached_floor >= 4:
		category = "floor_4_6"
	elif reached_floor >= 1:
		category = "floor_1_3"
	# Fallback chain
	var pool: Array = []
	if category == "met_wanderer":
		match character_id:
			"sera":
				pool = ["\"Orren found you, then. Keep his marks close. The lower stairs move when no one is looking.\""]
			"varn":
				pool = ["\"Orren is reckless, but his routes are good. If he says a door is safe, it is safe enough.\""]
			"volant":
				pool = ["\"You met Orren? Good. His maps are infuriatingly imprecise and usually correct.\""]
			_:
				pool = lines.get("default", [])
	else:
		pool = lines.get(category, lines.get("default", []))
	if pool.is_empty(): return {}

	var raw: String = pool[randi() % pool.size()]

	# Template substitutions
	raw = raw.replace("{floor}", str(reached_floor))
	raw = raw.replace("{heat}", str(heat))
	raw = raw.replace("{killer}", str(death.get("killer_name", "an enemy")))
	var cc: int = int(death.get("had_curses", 0))
	raw = raw.replace("{curse_count}", str(cc))
	raw = raw.replace("{plural}", "s" if cc != 1 else "")
	raw = raw.replace("{boon_count}", str(active_boons.size()))

	return {
		"line":     raw,
		"name":     char_data["name"],
		"title":    char_data["title"],
		"portrait": char_data["portrait"],
		"color":    char_data["color"],
		"category": category,
	}


## Get lines from all four characters for the current run state.
static func get_all_lines(gs: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var reached_floor: int = int(gs.get("run_floor_reached")) if gs else 0
	# runs not needed here
	# Echo only appears on interesting runs
	var last_death: Dictionary = gs.get("last_run_death") if gs else {}
	var show_echo: bool = reached_floor >= 7 or last_death.get("was_anchor", false) == true or \
		(gs and gs.get("active_run") and not gs.active_run.active_curses.is_empty())
	for cid in ["sera","varn","volant"]:
		var line := get_line(cid, gs)
		if not line.is_empty(): result.append(line)
	if show_echo:
		var echo_line := get_line("the_echo", gs)
		if not echo_line.is_empty(): result.append(echo_line)
	return result
