from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "godot" / "assets" / "tiles"
TARGET = (96, 64)

SOURCES = {
    "grass": Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2\ig_03f6f72321caa43e016a062dfd31fc819ab8fc90c6bb522215.png"),
    "road": Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2\ig_03f6f72321caa43e016a062e2b70c0819a9436362010f16051.png"),
    "stone": Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2\ig_03f6f72321caa43e016a062e631158819a981a368303de97e5.png"),
    "shallow_water": Path(r"C:\Users\jojo3\.codex\generated_images\019e2307-96a4-7473-abc9-bb7e2e62d2c2\ig_03f6f72321caa43e016a062e93d7d0819a90cbf5dd73fe82b8.png"),
}


def remove_magenta_key(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            # Remove generated chroma-key magenta and near-edge antialiasing.
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


def fit_tile(img: Image.Image) -> Image.Image:
    trimmed = trim_alpha(remove_magenta_key(img))
    scale = min(TARGET[0] / trimmed.width, TARGET[1] / trimmed.height)
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
        fit_tile(Image.open(src)).save(out)
        print(out)


if __name__ == "__main__":
    main()
