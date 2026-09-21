#!/usr/bin/env python3
"""Validate the manifest-backed Forgotten Field first art batch."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
MANIFEST = GODOT / "data" / "asset_manifest.json"
TERRAINS = ("grass", "grass_flowers", "road", "stone", "high_ground", "shallow_water")
OVERLAYS = ("selected", "move", "attack", "ability")
INDICATORS = ("player", "enemy")


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

    print("First art pass: OK (6 terrain, 4 overlays, 2 indicators; 96 x 48 footprint)")


if __name__ == "__main__":
    main()
