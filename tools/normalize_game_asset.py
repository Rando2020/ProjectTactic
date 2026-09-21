#!/usr/bin/env python3
"""Normalize a generated transparent PNG into an exact runtime canvas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--padding", type=int, default=1)
    parser.add_argument("--alpha-threshold", type=int, default=4)
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGBA")
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > args.alpha_threshold else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise SystemExit(f"No visible pixels found in {args.source}")

    cropped = image.crop(bounds)
    available_width = args.width - (args.padding * 2)
    available_height = args.height - (args.padding * 2)
    scale = min(
        available_width / cropped.width,
        available_height / cropped.height,
    )
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )

    canvas = Image.new("RGBA", (args.width, args.height), (0, 0, 0, 0))
    offset = (
        (args.width - resized.width) // 2,
        (args.height - resized.height) // 2,
    )
    canvas.alpha_composite(resized, offset)
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(args.destination, optimize=True)


if __name__ == "__main__":
    main()
