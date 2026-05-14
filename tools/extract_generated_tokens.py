from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "resources" / "OpenTacticaPrototype" / "data" / "generated_assets"
ATLAS = ASSET_DIR / "prototype_tactics_atlas.png"
OUT_DIR = ASSET_DIR / "tokens"
TILE_DIR = ASSET_DIR / "tiles"

CROPS = {
    "unit_knight": (54, 610, 140, 708),
    "unit_scout": (245, 610, 330, 708),
    "unit_arcanist": (505, 610, 590, 708),
    "unit_healer": (705, 610, 790, 708),
    "enemy_lancer": (900, 610, 985, 708),
    "enemy_rogue": (1095, 610, 1185, 708),
    "enemy_shadow": (1130, 713, 1215, 812),
}

TILE_CROPS = {
    "terrain_grass": (20, 14, 270, 160),
    "terrain_dirt": (300, 16, 535, 160),
    "terrain_stone": (570, 16, 815, 160),
    "terrain_bridge": (855, 14, 1090, 165),
    "terrain_water": (30, 190, 270, 345),
    "terrain_crystal": (300, 175, 545, 345),
    "terrain_cliff": (575, 178, 815, 345),
    "terrain_stairs": (575, 340, 815, 500),
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TILE_DIR.mkdir(parents=True, exist_ok=True)
    atlas = Image.open(ATLAS).convert("RGBA")
    for name, box in CROPS.items():
        crop = atlas.crop(box)
        canvas = Image.new("RGBA", (96, 112), (0, 0, 0, 0))
        crop.thumbnail((88, 104), Image.Resampling.LANCZOS)
        canvas.alpha_composite(crop, ((96 - crop.width) // 2, 112 - crop.height))
        canvas.save(OUT_DIR / f"{name}.png")

    for name, box in TILE_CROPS.items():
        crop = atlas.crop(box)
        canvas = Image.new("RGBA", (160, 112), (0, 0, 0, 0))
        crop.thumbnail((152, 104), Image.Resampling.LANCZOS)
        canvas.alpha_composite(crop, ((160 - crop.width) // 2, 112 - crop.height))
        canvas.save(TILE_DIR / f"{name}.png")

    print(f"Wrote {len(CROPS)} generated tokens to {OUT_DIR}")
    print(f"Wrote {len(TILE_CROPS)} generated tiles to {TILE_DIR}")


if __name__ == "__main__":
    main()
