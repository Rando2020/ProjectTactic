#!/usr/bin/env python3
"""Validate the manifest-backed Forgotten Field first art batch."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
MANIFEST = GODOT / "data" / "asset_manifest.json"
TERRAINS = ("grass", "grass_flowers", "brush", "road", "stone", "high_ground", "shallow_water", "shrine")
PROPS = ("leafy_bush", "mossy_rock", "tree_stump", "ruin_block")
OVERLAYS = ("selected", "move", "attack", "ability", "blocked")
INDICATORS = ("player", "enemy")
CHARACTERS = ("zane", "void_cultist")


def local_path(resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        raise AssertionError(f"Not a Godot resource path: {resource_path}")
    return GODOT / resource_path.removeprefix("res://")


def inspect_png(path: Path, expected_size: tuple[int, int]) -> Image.Image:
    if not path.is_file():
        raise AssertionError(f"Missing asset: {path.relative_to(ROOT)}")
    image = Image.open(path).convert("RGBA")
    if image.size != expected_size:
        raise AssertionError(f"{path.name}: expected {expected_size}, got {image.size}")
    alpha = image.getchannel("A")
    extrema = alpha.getextrema()
    if extrema[0] != 0 or extrema[1] == 0:
        raise AssertionError(f"{path.name}: expected useful transparent and visible pixels")
    return image


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    footprint = manifest["tile_footprint"]
    if (footprint["width"], footprint["height"]) != (96, 48):
        raise AssertionError("Manifest tile footprint must remain 96 x 48")

    theme = manifest["environments"]["forgotten-field"]
    for asset_id in TERRAINS:
        inspect_png(local_path(theme["terrain"][asset_id]["path"]), (96, 64))

    for asset_id in PROPS:
        image = inspect_png(local_path(theme["props"][asset_id]["path"]), (96, 96))
        bounds = image.getchannel("A").getbbox()
        if bounds is None or bounds[2] - bounds[0] > 82 or bounds[3] - bounds[1] > 80:
            raise AssertionError(f"{asset_id} prop exceeds the compact gameplay silhouette")

    overlay_theme = manifest["tactical_overlays"]["forgotten-field"]
    for asset_id in OVERLAYS:
        image = inspect_png(local_path(overlay_theme[asset_id]["path"]), (96, 48))
        center_alpha = image.getpixel((48, 24))[3]
        if center_alpha > 96:
            raise AssertionError(f"{asset_id} overlay obscures the tile center at alpha {center_alpha}")

    reduced: dict[str, Image.Image] = {}
    for asset_id in INDICATORS:
        image = inspect_png(local_path(manifest["unit_indicators"][asset_id]["path"]), (64, 64))
        reduced[asset_id] = image.resize((18, 18), Image.Resampling.LANCZOS)
        visible = sum(1 for value in reduced[asset_id].getchannel("A").get_flattened_data() if value >= 64)
        if visible < 24:
            raise AssertionError(f"{asset_id} indicator loses its silhouette at 18 px")

    difference = ImageStat.Stat(ImageChops.difference(reduced["player"], reduced["enemy"])).sum
    if sum(difference) < 2500:
        raise AssertionError("Player and enemy indicators are too similar at 18 px")

    for unit_id in CHARACTERS:
        entry = manifest["characters"][unit_id]["idle"]
        image = inspect_png(local_path(entry["path"]), (128, 128))
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise AssertionError(f"{unit_id} character has no visible silhouette")
        if bounds[1] > 10 or bounds[3] < 118:
            raise AssertionError(f"{unit_id} character does not use the shared vertical canvas")
        if not 54 <= (bounds[0] + bounds[2]) / 2 <= 74:
            raise AssertionError(f"{unit_id} character is not centered on the foot anchor")

    print("Forgotten Field art: OK (8 terrain, 4 props, 5 overlays, 2 indicators, 2 characters; 96 x 48 footprint)")


if __name__ == "__main__":
    main()
