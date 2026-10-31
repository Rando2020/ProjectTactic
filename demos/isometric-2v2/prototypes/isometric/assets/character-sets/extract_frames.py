"""Deterministic extraction of approved compact sheets; never modifies originals.

Requires Pillow, NumPy and SciPy. Run from any directory. No generation/inpainting.
"""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps
from scipy.ndimage import label, distance_transform_edt

ROOT = Path(__file__).resolve().parent
CANVAS = (800, 800)
ANCHOR = (400, 740)
BODY_HEIGHT = 600
# Source pixel anchors were inspected against visible hair/boot soles. Seeds sit
# inside each separate figure. Rear E/W below are physical image positions.
SPECS = {
    "swordsman": {
        "E": {"seed": [360, 250], "foot": [370, 632], "head_y": 31},
        "W": {"seed": [360, 850], "foot": [349, 1185], "head_y": 624},
        "N": {"seed": [950, 850], "foot": [943, 1209], "head_y": 628},
    },
    "mage": {
        "E": {"seed": [370, 250], "foot": [386, 610], "head_y": 60},
        "W": {"seed": [370, 850], "foot": [389, 1213], "head_y": 626},
        "N": {"seed": [950, 850], "foot": [961, 1215], "head_y": 626},
    },
    "rogue": {
        "E": {"seed": [360, 250], "foot": [345, 642], "head_y": 47},
        "W": {"seed": [360, 850], "foot": [319, 1215], "head_y": 633},
    },
    "dragoon": {
        "E": {"seed": [360, 250], "foot": [380, 620], "head_y": 74},
        "W": {"seed": [360, 850], "foot": [332, 1185], "head_y": 631},
        "N": {"seed": [950, 850], "foot": [975, 1202], "head_y": 638},
    },
}


def mirrored_at_anchor(frame):
    # Pillow's mirror maps x=400 to399 on an even-sized canvas. Translate one
    # transparent-edge pixel so all directions retain the exact same anchor.
    mirrored = ImageOps.mirror(frame)
    result = Image.new("RGBA", CANVAS)
    result.alpha_composite(mirrored, (1, 0))
    return result


def generate():
    entries = []
    for role, poses in SPECS.items():
        source = ROOT / "compact" / "originals" / f"{role}.png"
        original = Image.open(source).convert("RGBA")
        rgba = np.array(original)
        regions, _ = label(rgba[:, :, 3] > 0, np.ones((3, 3)))
        counts = np.bincount(regions.ravel())
        major = np.flatnonzero(counts > 10000)
        major = major[major != 0]
        core = np.isin(regions, major)
        distances, nearest = distance_transform_edt(~core, return_indices=True)
        owner = regions[nearest[0], nearest[1]]
        frames = {}
        for direction, spec in poses.items():
            sx, sy = spec["seed"]
            region = int(regions[sy, sx])
            assert region in major, (role, direction, region)
            # Include detached antialias/weapon fragments near their own figure;
            # never take pixels belonging to another major figure.
            keep = (owner == region) & (distances <= 32)
            isolated = rgba.copy()
            isolated[~keep] = 0
            frame = Image.fromarray(isolated)
            bounds = frame.getbbox()
            frame = frame.crop(bounds)
            scale = BODY_HEIGHT / (spec["foot"][1] - spec["head_y"])
            size = tuple(round(v * scale) for v in frame.size)
            frame = frame.resize(size, Image.Resampling.NEAREST)
            foot = [(spec["foot"][i] - bounds[i]) * scale for i in range(2)]
            offset = [round(ANCHOR[i] - foot[i]) for i in range(2)]
            assert min(offset) >= 0 and all(offset[i] + size[i] <= CANVAS[i] for i in range(2)), (role, direction, offset, size)
            result = Image.new("RGBA", CANVAS)
            result.alpha_composite(frame, tuple(offset))
            frames[direction] = result
            entries.append({"role": role, "direction": direction, "source_bounds": list(bounds), "source_foot_anchor": spec["foot"], "source_head_y": spec["head_y"], "scale": scale, "mirrored": False})
        frames["S"] = mirrored_at_anchor(frames["E"])
        entries.append({"role": role, "direction": "S", "mirrored": True, "derived_from": "E", "limitation": "Missing opposing front view; handedness is provisional."})
        if role == "rogue":
            frames["N"] = mirrored_at_anchor(frames["W"])
            entries.append({"role": role, "direction": "N", "mirrored": True, "derived_from": "W", "limitation": "Right-hand figures touch in original; mirrored rear avoids cutting or including neighbor."})
        target = ROOT / "compact" / "frames" / role
        target.mkdir(parents=True, exist_ok=True)
        for direction, frame in frames.items():
            frame.save(target / f"{direction}.png", optimize=True)
        # A crop of the same front pose, not a new character/identity portrait.
        frames["E"].crop((235, 115, 565, 445)).save(target / "portrait.png", optimize=True)
    for entry in entries:
        path = f"compact/frames/{entry['role']}/{entry['direction']}.png"
        entry.update(path=path, sha256=hashlib.sha256((ROOT / path).read_bytes()).hexdigest())
    manifest = {"canvas": list(CANVAS), "foot_anchor": list(ANCHOR), "normalized_head_to_sole_height": BODY_HEIGHT, "logical_view_mapping": {"N": "NE", "E": "SE", "S": "SW", "W": "NW"}, "frames": entries}
    (ROOT / "frames.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


if __name__ == "__main__":
    print(json.dumps({"frames": len(generate()["frames"]), "canvas": CANVAS, "foot_anchor": ANCHOR}))
