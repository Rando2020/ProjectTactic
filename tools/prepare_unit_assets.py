from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "godot" / "assets" / "sprites" / "units"
TARGET = (128, 128)
GEN_DIR = Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2")

SOURCES = {
    "zane": GEN_DIR / "ig_03f6f72321caa43e016a077303fae8819a888d8c9f1737a0a0.png",
    "mira": GEN_DIR / "ig_03f6f72321caa43e016a077341a878819a8c9ac8c3aae0ccf7.png",
    "kael": GEN_DIR / "ig_03f6f72321caa43e016a077384ea9c819abd2c4ad269798999.png",
    "lyra": GEN_DIR / "ig_03f6f72321caa43e016a0773c879cc819ab0726e4968869799.png",
    "null_drake": GEN_DIR / "ig_03f6f72321caa43e016a0774161cec819a8db30ec86b59a426.png",
    "storm_imp": GEN_DIR / "ig_03f6f72321caa43e016a0774785e88819a8963fb6c788405f5.png",
    "void_cultist": GEN_DIR / "ig_03f6f72321caa43e016a0774b6db20819aad84bb85f81a3f7d.png",
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


def fit_unit(img: Image.Image) -> Image.Image:
    trimmed = trim_alpha(remove_magenta_key(img))
    scale = min((TARGET[0] - 10) / trimmed.width, (TARGET[1] - 8) / trimmed.height)
    new_size = (
        max(1, int(round(trimmed.width * scale))),
        max(1, int(round(trimmed.height * scale))),
    )
    resized = trimmed.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", TARGET, (0, 0, 0, 0))
    x = (TARGET[0] - resized.width) // 2
    y = TARGET[1] - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, src in SOURCES.items():
        out = OUT_DIR / f"{name}.png"
        fit_unit(Image.open(src)).save(out)
        print(out)


if __name__ == "__main__":
    main()
