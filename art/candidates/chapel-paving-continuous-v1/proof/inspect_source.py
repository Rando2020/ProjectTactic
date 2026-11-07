"""Read-only image inspection. Never edits the generated source pixels."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / "source/chapel-paving-continuous-v1.png"
img = Image.open(p)
img.verify()
img = Image.open(p)
a = np.asarray(img.convert("RGB"), dtype=float)
horizontal = abs(a[:, 1:] - a[:, :-1]).mean()
vertical = abs(a[1:] - a[:-1]).mean()
x_wrap = abs(a[:, 0] - a[:, -1]).mean()
y_wrap = abs(a[0] - a[-1]).mean()
report = {
    "source": str(p.relative_to(ROOT)),
    "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
    "size": list(img.size),
    "mode": img.mode,
    "mean_rgb": a.mean(axis=(0,1)).round(3).tolist(),
    "wrap_mean_absolute_channel_difference_8bit": {
        "left_right": round(float(x_wrap),6),
        "top_bottom": round(float(y_wrap),6),
    },
    "interior_adjacent_pixel_difference_8bit": {
        "x": round(float(horizontal),6), "y": round(float(vertical),6),
    },
    "wrap_to_interior_ratio": {
        "x": round(float(x_wrap/horizontal),6),
        "y": round(float(y_wrap/vertical),6),
    },
    "exact_boundary_match": bool(np.array_equal(a[:,0],a[:,-1]) and np.array_equal(a[0],a[-1])),
    "interpretation": "Diagnostic statistics only. Low average edge difference does not prove joint continuity or invisible seams. Not certified seamless.",
    "status": "candidate; no runtime integration or visual acceptance",
}
assert img.size == (1254,1254)
assert img.mode == "RGB"
assert report["sha256"] == "35967a6cfa7639469110a25e60799573fd5459d47720633ccb8b928eae88576c"
out=ROOT / "evidence/source-inspection.json"
out.write_text(json.dumps(report,indent=2)+"\n")
print(json.dumps(report,indent=2))
