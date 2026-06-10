"""
slice_sprites.py
Slices the 7-character × 4-direction sprite sheet into individual PNGs,
removes the near-black background, auto-trims to content, and saves to
godot/assets/sprites/units/ with the correct naming convention.

Usage:
    python tools/slice_sprites.py
"""

from pathlib import Path
from PIL import Image
import numpy as np

# ── paths ─────────────────────────────────────────────────────────────────────
SHEET_PATH = Path(r"C:\Users\jojo3\Downloads\ChatGPT Image May 29, 2026, 12_25_17 AM.png")
OUT_DIR    = Path(__file__).parent.parent / "godot" / "assets" / "sprites" / "units"

# ── grid layout (measured from header label centres) ─────────────────────────
# Column dividers  (Front-Left | Front-Right | Back-Left | Back-Right)
COL_EDGES = [155, 377, 597, 825, 1086]   # 5 edges = 4 columns

# Row dividers — derived from bright-content band starts/ends
# [row_top, row_bottom) for each of the 7 characters
ROW_EDGES = [43, 245, 436, 623, 829, 1012, 1205, 1448]  # 8 edges = 7 rows

CHARACTERS = ["aeryn", "cael", "brennan", "solan", "mira", "tobias", "seren"]
DIRECTIONS = ["front-left", "front-right", "back-left", "back-right"]

# Background colour (the near-black surround in the concept sheet)
BG_RGB       = (14, 14, 18)
BG_TOLERANCE = 28    # pixels within this distance of the bg colour are removed
EDGE_FEATHER = 6     # pixels at crop edge always removed (avoids label bleed)

# ── helpers ───────────────────────────────────────────────────────────────────

def remove_background(img: Image.Image) -> Image.Image:
    """
    Converts the dark near-black background to transparent.
    Uses a per-pixel Euclidean distance from BG_RGB and a small
    edge fade to blend away anti-aliasing fringing.
    """
    rgb  = img.convert("RGB")
    arr  = np.array(rgb, dtype=np.float32)
    out  = np.zeros((arr.shape[0], arr.shape[1], 4), dtype=np.uint8)

    bg   = np.array(BG_RGB, dtype=np.float32)
    dist = np.linalg.norm(arr - bg, axis=2)          # distance from bg colour

    alpha = np.clip((dist - BG_TOLERANCE) / 20.0, 0, 1)  # 0→transparent, 1→opaque

    # Hard-remove the outermost EDGE_FEATHER pixels (catches label bleed)
    if EDGE_FEATHER > 0:
        alpha[:EDGE_FEATHER, :]  = 0
        alpha[-EDGE_FEATHER:, :] = 0
        alpha[:, :EDGE_FEATHER]  = 0
        alpha[:, -EDGE_FEATHER:] = 0

    out[:, :, :3] = arr.astype(np.uint8)
    out[:, :,  3] = (alpha * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def auto_trim(img: Image.Image, padding: int = 4) -> Image.Image:
    """Crop to the bounding box of non-transparent pixels, plus a small pad."""
    arr  = np.array(img)
    mask = arr[:, :, 3] > 10
    if not mask.any():
        return img
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    y0, y1 = np.where(rows)[0][[0, -1]]
    x0, x1 = np.where(cols)[0][[0, -1]]
    h, w   = arr.shape[:2]
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(w, x1 + padding + 1)
    y1 = min(h, y1 + padding + 1)
    return img.crop((x0, y0, x1, y1))


# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    sheet = Image.open(SHEET_PATH).convert("RGB")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Sheet size: {sheet.size}")
    print(f"Output dir: {OUT_DIR}")
    print()

    saved = []
    for row_idx, char_id in enumerate(CHARACTERS):
        y0 = ROW_EDGES[row_idx]
        y1 = ROW_EDGES[row_idx + 1]

        for col_idx, direction in enumerate(DIRECTIONS):
            x0 = COL_EDGES[col_idx]
            x1 = COL_EDGES[col_idx + 1]

            cell = sheet.crop((x0, y0, x1, y1))
            cell_rgba = remove_background(cell)
            cell_trimmed = auto_trim(cell_rgba)

            # Directional sprite: {id}-{direction}.png
            fname = f"{char_id}-{direction}.png"
            out_path = OUT_DIR / fname
            cell_trimmed.save(out_path, "PNG")
            saved.append(fname)
            print(f"  OK {fname}  ({cell_trimmed.size[0]}x{cell_trimmed.size[1]})")

        # Also overwrite the base {id}.png (used as sprite_sheet fallback)
        # with the front-left view (facing-S / default)
        base_fname = f"{char_id}.png"
        # Re-slice front-left for the base sprite
        x0b = COL_EDGES[0]
        x1b = COL_EDGES[1]
        base_cell    = sheet.crop((x0b, y0, x1b, y1))
        base_rgba    = remove_background(base_cell)
        base_trimmed = auto_trim(base_rgba)
        base_path    = OUT_DIR / base_fname
        base_trimmed.save(base_path, "PNG")
        print(f"  OK {base_fname}  (base/fallback, {base_trimmed.size[0]}x{base_trimmed.size[1]})")
        print()

    print(f"Done — {len(saved)} directional sprites + 7 base sprites saved to:")
    print(f"  {OUT_DIR}")


if __name__ == "__main__":
    main()
