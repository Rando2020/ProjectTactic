from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TILE_OUT_DIR = ROOT / "godot" / "assets" / "tiles"
PROP_OUT_DIR = ROOT / "godot" / "assets" / "props"
TILE_TARGET = (96, 64)
PROP_TARGET = (96, 96)
GEN_DIR = Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2")

TILE_SOURCES = {
    "grass": GEN_DIR / "ig_03f6f72321caa43e016a062dfd31fc819ab8fc90c6bb522215.png",
    "road": GEN_DIR / "ig_03f6f72321caa43e016a062e2b70c0819a9436362010f16051.png",
    "stone": GEN_DIR / "ig_03f6f72321caa43e016a062e631158819a981a368303de97e5.png",
    "shallow_water": GEN_DIR / "ig_03f6f72321caa43e016a062e93d7d0819a90cbf5dd73fe82b8.png",
    "grass_flowers": GEN_DIR / "ig_03f6f72321caa43e016a06afeb5cb4819a91351e9a19b0dd46.png",
    "brush": GEN_DIR / "ig_03f6f72321caa43e016a06b00712cc819aa6d0850d81997afd.png",
    "cliff_grass": GEN_DIR / "ig_03f6f72321caa43e016a06b03cfde0819aae8a0612c83fdcc6.png",
    "burning_grass": GEN_DIR / "ig_03f6f72321caa43e016a0769566278819a8dcb76ac6a31fb45.png",
    "scorched_dirt": GEN_DIR / "ig_03f6f72321caa43e016a07697fdaec819aa8ee15e33563ab5c.png",
    "frozen_water": GEN_DIR / "ig_03f6f72321caa43e016a0769a70a74819aa1d29876fa3f3877.png",
    "cracked_stone": GEN_DIR / "ig_03f6f72321caa43e016a0769c9d798819a9dc4478c6303e8a6.png",
    "holy_shrine": GEN_DIR / "ig_03f6f72321caa43e016a0769ff1be0819ab88a4496ef5d9a04.png",
}

PROP_SOURCES = {
    "mossy_rock": GEN_DIR / "ig_03f6f72321caa43e016a06b0605408819ab349a65d8949fb04.png",
    "leafy_bush": GEN_DIR / "ig_03f6f72321caa43e016a06b0a8fd44819a9dece3038ba1c917.png",
    "tree_stump": GEN_DIR / "ig_03f6f72321caa43e016a06b0eaa6d8819a9bd971d65640c4ac.png",
    "ruin_block": GEN_DIR / "ig_03f6f72321caa43e016a06b12ad7d4819a901440fce77299cc.png",
}


def remove_magenta_key(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if r > 185 and b > 185 and g < 105:
                px[x, y] = (r, g, b, 0)
            elif r > 145 and b > 145 and g < 145:
                px[x, y] = (r, g, b, min(a, 70))
    return rgba


def trim_alpha(img: Image.Image) -> Image.Image:
    alpha = img.getchannel("A")
    bbox = alpha.point(lambda v: 255 if v > 12 else 0).getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def fit_asset(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    trimmed = trim_alpha(remove_magenta_key(img))
    scale = min(target[0] / trimmed.width, target[1] / trimmed.height)
    new_size = (
        max(1, int(round(trimmed.width * scale))),
        max(1, int(round(trimmed.height * scale))),
    )
    resized = trimmed.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", target, (0, 0, 0, 0))
    x = (target[0] - resized.width) // 2
    y = target[1] - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def main() -> None:
    TILE_OUT_DIR.mkdir(parents=True, exist_ok=True)
    PROP_OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, src in TILE_SOURCES.items():
        out = TILE_OUT_DIR / f"{name}.png"
        fit_asset(Image.open(src), TILE_TARGET).save(out)
        print(out)
    for name, src in PROP_SOURCES.items():
        out = PROP_OUT_DIR / f"{name}.png"
        fit_asset(Image.open(src), PROP_TARGET).save(out)
        print(out)


if __name__ == "__main__":
    main()
