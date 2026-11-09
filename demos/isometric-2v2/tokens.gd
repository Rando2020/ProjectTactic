# ============================================================
#  THE APPOINTED · DESIGN TOKENS
#  Autoload — register in Project Settings as "Tokens"
#  Mirrors design-system/colors_and_type.css
# ============================================================
extends Node

# ── Hub (warm decay, holy ruin) ─────────────────────────────
const HUB_BG          := Color("#08090d")
const HUB_BG_WARM     := Color("#0a0806")
const HUB_STONE       := Color("#3d3530")
const HUB_STONE_2     := Color("#2a2520")
const HUB_WARM        := Color("#c8a96e")
const HUB_LIGHT       := Color("#f0e8d0")
const HUB_SHADOW      := Color("#1a1410")

# ── Mountain (cold, ascending) ──────────────────────────────
const MOUNTAIN_BG     := Color("#070a0f")
const MOUNTAIN_STONE  := Color("#1a2230")
const MOUNTAIN_MIST   := Color("#8fa3b8")
const MOUNTAIN_ICE    := Color("#c8dde8")

# ── Sacred / danger signals ─────────────────────────────────
const SACRED_GOLD     := Color("#d4af37")
const SACRED_GLOW     := Color("#ffd86b")
const CRIMSON         := Color("#9b2335")
const CRIMSON_DEEP    := Color("#5c1620")
const BONE            := Color("#e8d8c8")
const ASH             := Color("#5a544f")

# ── The Seven (one color per sin / character) ───────────────
const PRIDE_GOLD        := Color("#d4af37")  # Aeryn / Luciel
const ENVY_VERDIGRIS    := Color("#4a8c6f")  # Cael / Zaqiel
const WRATH_CRIMSON     := Color("#9b2335")  # Brennan / Camael
const SLOTH_DUSK        := Color("#6b5b8a")  # Solan / Raziel
const GREED_AMBER       := Color("#b8860b")  # Mira / Sachiel
const GLUTTONY_ASH      := Color("#8a9a8a")  # Tobias / Muriel
const LUST_IVORY        := Color("#e8d8c8")  # Seren / Anael

# ── Revelation Tier ramp (color shift per tier) ─────────────
const TIER_COLORS := [
  Color("#4a6fa5"),  # Tier 1 — The War (cold blue)
  Color("#7a5c8a"),  # Tier 2 — The Cracks (violet)
  Color("#8a3a3a"),  # Tier 3 — The Fallen (deep red)
  Color("#c8a040"),  # Tier 4 — The Pattern (gold)
  Color("#e8e0d0"),  # Tier 5 — The Ascent (near-white)
]
const TIER_NAMES := ["The War", "The Cracks", "The Fallen", "The Pattern", "The Ascent"]

# ── Foreground / neutral scale ──────────────────────────────
const FG_1 := Color("#f0e8d0")  # primary text
const FG_2 := Color("#c8b89a")  # secondary
const FG_3 := Color("#8a7e6a")  # labels
const FG_4 := Color("#5a5247")  # hint / disabled
const LINE      := Color(0.78, 0.66, 0.43, 0.18)  # brass hairline
const LINE_2    := Color(0.94, 0.91, 0.81, 0.08)  # subtle stone
const LINE_HOT  := Color(0.83, 0.69, 0.22, 0.55)  # sacred border

# ── Surfaces ────────────────────────────────────────────────
const SURFACE_0 := Color("#08090d")  # void
const SURFACE_1 := Color("#11100c")  # slab
const SURFACE_2 := Color("#1a1610")  # raised slab
const SURFACE_3 := Color("#25201a")  # iron plate

# ── Parchment (narrative-interlude surface) ─────────────────
const PARCHMENT        := Color("#ede0c2")
const PARCHMENT_LIGHT  := Color("#f5ecd2")
const PARCHMENT_SHADOW := Color("#d4c298")
const PARCHMENT_BURN   := Color("#b8a06a")
const INK              := Color("#2a1d10")
const INK_FADED        := Color("#5c4530")
const INK_RUBRIC       := Color("#8c1f1f")
const BRASS_DEEP       := Color("#6a4a1a")
const BRASS            := Color("#8c6f2a")

# ── Combat semantics (stained-glass pigment) ────────────────
const HP   := Color("#4cd166")  # vital flesh
const TMP  := Color("#f08020")  # temper / physical armor
const ETH  := Color("#a585ff")  # ether / magical armor
const HIT  := Color("#f5c542")
const CRIT := Color("#ffe680")
const HEAL := Color("#62e576")
const MISS := Color("#5a544f")
const STATUS_BUFF   := Color("#efc46b")
const STATUS_DEBUFF := Color("#e0304a")

# ── Spacing (4-pt grid) ─────────────────────────────────────
const SPACE_1 := 4
const SPACE_2 := 8
const SPACE_3 := 12
const SPACE_4 := 16
const SPACE_5 := 24
const SPACE_6 := 32
const SPACE_7 := 48
const SPACE_8 := 64
const SPACE_9 := 96

# ── Type ────────────────────────────────────────────────────
# Fonts live in res://assets/fonts/.
const FONT_DISPLAY_PATH      := "res://assets/fonts/TrajanPro-Regular.ttf"
const FONT_DISPLAY_BOLD_PATH := "res://assets/fonts/TrajanPro-Bold.otf"
const FONT_HEADER_PATH       := "res://assets/fonts/Cinzel-Bold.ttf"
const FONT_HEADER_MED_PATH   := "res://assets/fonts/Cinzel-Medium.ttf"
const FONT_HEADER_REG_PATH   := "res://assets/fonts/Cinzel-Regular.ttf"
const FONT_BODY_PATH         := "res://assets/fonts/IMFellEnglish-Regular.ttf"
const FONT_UI_PATH           := "res://assets/fonts/CormorantGaramond-Regular.ttf"
const FONT_MONO_PATH         := "res://assets/fonts/JetBrainsMono-Regular.ttf"

const SIZE_DISPLAY  := 64   # clamp(48-88) — use Trajan, all caps
const SIZE_H1       := 40   # Trajan, all caps, tracked
const SIZE_H2       := 28   # Trajan, all caps, tracked
const SIZE_H3       := 20
const SIZE_H4       := 16
const SIZE_EYEBROW  := 11
const SIZE_BODY     := 17   # IM Fell English
const SIZE_BODY_SM  := 14
const SIZE_UI       := 13   # Cormorant
const SIZE_LABEL    := 11
const SIZE_NUMERIC  := 14   # JetBrains Mono

# Letter-spacing — apply as Label theme override "constants/character_spacing"
const TRACK_DISPLAY  := 1   # px per glyph at base size
const TRACK_HEADER   := 2   # uppercase / tracked
const TRACK_EYEBROW  := 4   # heavily tracked all-caps eyebrow
