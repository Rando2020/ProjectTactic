"""Validate and export independently authored illustrated Zane images.

Never cut battle sprites out of a labeled concept collage. Provide a clean
upper-body portrait and four transparent, anatomically consistent full-body
direction images instead. Exports share a foot anchor and a fixed canvas size.

Usage:
 python tools/prepare_illustrated_zane.py --portrait /path/portrait.png \
   --front /path/front.png --right /path/right.png \
   --back /path/back.png --left /path/left.png \
   --out /path/to/asset-staging

The output directory is user-selected. This command never updates gameplay,
merges a PR, or archives existing rigs.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

DIRECTIONS = ("front", "right", "back", "left")
CANVAS = (128, 192)
BOTTOM_MARGIN = 4
PADDING = 5


class ArtValidationError(ValueError):
    pass


def normalize_sprite(source: Image.Image) -> Image.Image:
    source = source.convert("RGBA")
    if source.width < 64 or source.height < 100:
        raise ArtValidationError("Each directional source must be at least 64x100 pixels.")
    alpha = source.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None or alpha.getextrema() == (255, 255):
        raise ArtValidationError("Directional sprite requires genuine transparent pixels.")
    if bounds[2] - bounds[0] < 32 or bounds[3] - bounds[1] < 80:
        raise ArtValidationError("Sprite silhouette is too small or empty.")
    # A border of opaque pixels indicates an incorrectly cut-out source.
    for x in (0, source.width - 1):
        for y in (0, source.height - 1):
            if alpha.getpixel((x, y)) > 16:
                raise ArtValidationError("Corner transparency missing; likely a background box.")
    trimmed = source.crop(bounds)
    factor = min(
        (CANVAS[0] - PADDING * 2) / trimmed.width,
        (CANVAS[1] - PADDING * 2 - BOTTOM_MARGIN) / trimmed.height,
    )
    size = (max(1, round(trimmed.width * factor)), max(1, round(trimmed.height * factor)))
    resized = trimmed.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((CANVAS[0] - size[0]) // 2, CANVAS[1] - BOTTOM_MARGIN - size[1]))
    return canvas


def export_assets(portrait: Path, sprites: dict[str, Path], dest: Path) -> list[Path]:
    if set(sprites) != set(DIRECTIONS):
        raise ArtValidationError("Exactly front, right, back, and left sprites are required.")
    # Validate the full group before writing any outputs.
    with Image.open(portrait) as file:
        if file.width < 256 or file.height < 256:
            raise ArtValidationError("Portrait master must be at least 256x256 pixels.")
        painted = file.convert("RGB")
    normalized: dict[str, Image.Image] = {}
    for direction in DIRECTIONS:
        with Image.open(sprites[direction]) as src:
            normalized[direction] = normalize_sprite(src)
    dest.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    art = dest / "zane-portrait-illustrated.png"
    painted.save(art, "PNG", optimize=True)
    outputs.append(art)
    for direction in DIRECTIONS:
        name = dest / f"zane-{direction}-illustrated.png"
        normalized[direction].save(name, "PNG", optimize=True)
        outputs.append(name)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--portrait", type=Path, required=True)
    for direction in DIRECTIONS:
        parser.add_argument("--" + direction, type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    sprites = {d: getattr(args, d) for d in DIRECTIONS}
    for result in export_assets(args.portrait, sprites, args.out):
        print(result)


if __name__ == "__main__":
    main()
