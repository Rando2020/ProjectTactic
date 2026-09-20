# THE APPOINTED: AS ABOVE
## Godot Setup Guide

---

## Files Created

You now have the core narrative system for Godot:

```
scripts/autoload/
├── GameConfig.gd        # Constants, tiers, palette, sin/virtue map
├── GameState.gd         # Main state singleton with signals
├── Characters.gd        # The seven character definitions
└── HubCharacters.gd     # Antechamber NPCs (Azrael, Lilith, etc.)
```

---

## Step 1: Set Up Autoloads

In Godot, go to **Project → Project Settings → Autoload**

Add these four singletons **in this order**:

| Path | Node Name | Enabled |
|------|-----------|---------|
| `res://scripts/autoload/GameConfig.gd` | `GameConfig` | ✓ |
| `res://scripts/autoload/GameState.gd` | `GameState` | ✓ |
| `res://scripts/autoload/Characters.gd` | `Characters` | ✓ |
| `res://scripts/autoload/HubCharacters.gd` | `HubCharacters` | ✓ |

**Important:** GameConfig must load first because the others depend on it.

---

## Step 2: How to Use These in Your Code

### Accessing Constants

```gdscript
# In any script:
var hub_bg_color = GameConfig.PALETTE.HUB_BG
var current_tier_label = GameConfig.get_tier_label(GameState.revelation_tier)
var aeryn_color = GameConfig.get_sin_color("pride")
```

### Accessing Game State

```gdscript
# Get current revelation tier
var tier = GameState.revelation_tier

# Get a character's data
var aeryn_state = GameState.get_character("aeryn")
print(aeryn_state.costume_integrity)  # 0-100

# Check if a crack event has happened
if GameState.get_flag("aeryn_crack_event_complete"):
    print("Aeryn has cracked")
```

### Modifying State (Use the Methods!)

```gdscript
# Start a run
GameState.begin_run()

# Award revelation points
GameState.gain_revelation(20, "soul_adam_met")

# Trigger a character crack event
GameState.trigger_crack_event("aeryn")

# Meet a hub character
GameState.meet_hub_character("azrael")

# Complete a boss fight
GameState.boss_fight_complete("the_righteous_one", "brennan")
```

### Connecting to Signals

```gdscript
# In any script's _ready():
func _ready():
    GameState.revelation_tier_changed.connect(_on_tier_changed)
    GameState.clarity_changed.connect(_on_clarity_changed)
    GameState.character_crack_event.connect(_on_crack_event)

func _on_tier_changed(new_tier: int):
    print("Revelation tier is now: ", GameConfig.TIER_LABELS[new_tier])

func _on_clarity_changed(new_clarity: int):
    $ClarityBar.value = new_clarity

func _on_crack_event(char_id: String):
    print(char_id, " has experienced a crack event!")
```

### Getting Character Data

```gdscript
# Get full character definition
var aeryn_data = Characters.get_character("aeryn")
print(aeryn_data.human_name)  # "Aeryn"
print(aeryn_data.true_name)   # "Luciel"
print(aeryn_data.wound)       # The full wound text

# Get dialogue for current tier
var dialogue_lines = Characters.get_hub_dialogue("aeryn", GameState.revelation_tier)

# Get flavor text
var flavor = Characters.get_flavor_text("aeryn", GameState.revelation_tier)
```

### Getting Hub Character Data

```gdscript
# Get hub character dialogue
var azrael_lines = HubCharacters.get_dialogue("azrael", GameState.revelation_tier)

# Check if available
var osiris_available = HubCharacters.is_available(
    "osiris", 
    GameState.total_runs, 
    GameState.revelation_tier
)

# Get dream reveal (Somnus specific)
var aeryn_dream = HubCharacters.get_dream_reveal("somnus", "aeryn")

# Get memory fragment (Anamnesis specific)
var aeryn_memory = HubCharacters.get_memory_fragment("aeryn")
```

---

## Step 3: Project Structure

Set up your folders like this:

```
godot/
├── scripts/
│   ├── autoload/           # ✓ Created
│   │   ├── GameConfig.gd
│   │   ├── GameState.gd
│   │   ├── Characters.gd
│   │   └── HubCharacters.gd
│   ├── systems/
│   │   └── NarrativeSystem.gd  # Helper functions (optional)
│   └── ui/
│       ├── HubScreen.gd        # Hub UI controller
│       └── CharacterCard.gd    # Reusable components
├── scenes/
│   ├── hub/
│   │   └── HubScreen.tscn      # The Antechamber scene
│   ├── mountain/
│   │   └── RunScreen.tscn
│   └── ui/
│       ├── CharacterCard.tscn
│       └── DialogueBox.tscn
├── resources/
│   └── theme/
│       └── appointed_theme.tres  # UI theme with fonts/colors
└── assets/
    ├── fonts/
    │   ├── Cinzel-Bold.ttf
    │   └── CrimsonText-Regular.ttf
    ├── portraits/
    │   ├── aeryn.png
    │   └── ...
    ├── icons/
    │   └── sin_icons/
    │       ├── pride.png
    │       └── ...
    └── backgrounds/
        └── antechamber.jpg
```

---

## Step 4: Asset Wiring in Godot

### Fonts (in Theme Resource)

1. Create a new Theme resource: `res://resources/theme/appointed_theme.tres`
2. In the Theme editor, add fonts:
   - **Default Font** → `res://assets/fonts/CrimsonText-Regular.ttf`
   - Add **Font Size Overrides** for different text types
3. For custom fonts in specific controls:

```gdscript
# In a script:
var title_font = load("res://assets/fonts/Cinzel-Bold.ttf")
$TitleLabel.add_theme_font_override("font", title_font)
$TitleLabel.add_theme_font_size_override("font_size", 48)
```

### Images (Character Portraits, Backgrounds)

```gdscript
# Static preload (fast, loaded at compile time)
const AERYN_PORTRAIT = preload("res://assets/portraits/aeryn.png")

func _ready():
    $Portrait.texture = AERYN_PORTRAIT

# Dynamic load (slower, loaded at runtime)
func show_character(char_id: String):
    var path = "res://assets/portraits/" + char_id + ".png"
    var portrait = load(path)
    $Portrait.texture = portrait
```

### Asset Maps (Best for Game Data)

Create `res://scripts/data/AssetPaths.gd`:

```gdscript
extends Node

const PORTRAITS = {
    "aeryn": preload("res://assets/portraits/aeryn.png"),
    "cael": preload("res://assets/portraits/cael.png"),
    "brennan": preload("res://assets/portraits/brennan.png"),
    "solan": preload("res://assets/portraits/solan.png"),
    "mira": preload("res://assets/portraits/mira.png"),
    "tobias": preload("res://assets/portraits/tobias.png"),
    "seren": preload("res://assets/portraits/seren.png"),
}

const SIN_ICONS = {
    "pride": preload("res://assets/icons/sin_icons/pride.png"),
    "envy": preload("res://assets/icons/sin_icons/envy.png"),
    "wrath": preload("res://assets/icons/sin_icons/wrath.png"),
    "sloth": preload("res://assets/icons/sin_icons/sloth.png"),
    "greed": preload("res://assets/icons/sin_icons/greed.png"),
    "gluttony": preload("res://assets/icons/sin_icons/gluttony.png"),
    "lust": preload("res://assets/icons/sin_icons/lust.png"),
}

func get_portrait(char_id: String) -> Texture2D:
    return PORTRAITS.get(char_id, null)

func get_sin_icon(sin: String) -> Texture2D:
    return SIN_ICONS.get(sin, null)
```

Then use it:

```gdscript
# In any script:
$Portrait.texture = AssetPaths.get_portrait("aeryn")
$SinIcon.texture = AssetPaths.get_sin_icon("pride")
```

### Background Images

```gdscript
# In a TextureRect or Sprite2D:
const ANTECHAMBER_BG = preload("res://assets/backgrounds/antechamber.jpg")

func _ready():
    $Background.texture = ANTECHAMBER_BG
```

---

## Step 5: Create Your First Scene (Hub Screen)

1. **Scene → New Scene → 2D Scene**
2. Rename root node to `HubScreen`
3. Add children:
   ```
   HubScreen (Control)
   ├── Background (TextureRect)
   ├── CharacterPanel (PanelContainer)
   │   └── CharacterList (VBoxContainer)
   ├── DialogueBox (PanelContainer)
   └── UILayer (CanvasLayer)
   ```

4. Attach script `HubScreen.gd`:

```gdscript
extends Control

func _ready():
    # Connect to signals
    GameState.hub_character_met.connect(_on_hub_character_met)
    
    # Set background
    $Background.texture = load("res://assets/backgrounds/antechamber.jpg")
    
    # Populate character list
    _update_character_list()

func _update_character_list():
    for char_id in Characters.PARTY_ORDER:
        var char_data = Characters.get_character(char_id)
        var char_state = GameState.get_character(char_id)
        
        var card = preload("res://scenes/ui/CharacterCard.tscn").instantiate()
        card.setup(char_id, char_data, char_state)
        $CharacterPanel/CharacterList.add_child(card)

func _on_hub_character_met(hub_char_id: String):
    print("Met: ", hub_char_id)
```

---

## Step 6: Testing the System

Create a test script to verify everything works:

```gdscript
extends Node

func _ready():
    print("=== Testing Narrative System ===")
    
    # Test 1: Constants
    print("Game title: ", GameConfig.GAME_FULL_TITLE)
    print("Tier 1 label: ", GameConfig.TIER_LABELS[1])
    
    # Test 2: Character data
    var aeryn = Characters.get_character("aeryn")
    print("Aeryn's true name: ", aeryn.true_name)
    
    # Test 3: State changes
    GameState.begin_run()
    print("Current run: ", GameState.current_run)
    
    GameState.gain_revelation(200, "test")
    print("Revelation tier: ", GameState.revelation_tier)  # Should be 2
    
    # Test 4: Signals
    GameState.clarity_changed.connect(func(new_clarity):
        print("Clarity changed to: ", new_clarity)
    )
    GameState.gain_clarity(10)
    
    print("=== Tests Complete ===")
```

---

## What to Build Next

Now that the foundation is in place, the next logical builds are:

1. **HubScreen.tscn** — The Antechamber UI where players interact with hub characters
2. **CharacterCard.tscn** — Reusable component for displaying party members
3. **DialogueBox.tscn** — Component for showing hub character dialogue
4. **Asset integration** — Once you know what images you have, wire them up

Which would you like to build first?

---

## Troubleshooting

**"Can't access GameState"**
- Check Project Settings → Autoload to make sure it's registered
- Make sure the path is correct: `res://scripts/autoload/GameState.gd`

**"Invalid get index 'revelation_tier'"**
- GameState might not be initialized yet. Add `await ready` in _ready()

**"Fonts not showing"**
- Check font file paths in Theme resource
- Make sure font files are actually imported (check .import folder)

**"Signals not firing"**
- Make sure you're calling GameState methods, not directly modifying variables
- Use `GameState.gain_revelation()` not `GameState.revelation_points += 20`

---

*The loop isn't the problem. The loop is the point.*
