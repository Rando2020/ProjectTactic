"""Read-only PNG validation for the Zane NE correction candidate.

No pixel rewriting, trimming, mirroring, resampling, or alpha repair occurs.
"""
from pathlib import Path
from PIL import Image
import hashlib
import json

ROOT = Path(__file__).resolve().parent
EXPECTED = {
    "references/zane-se-approved-reference.png": "d299d45c28f164620beee1d88871edea780ce4ad3c4873f1bea86735b64ab236",
    "references/zane-sw-candidate.png": "cb19662628e53dc09075739cd021205453795e9c117d8fb531f0be9320a7e457",
    "references/zane-ne-candidate.png": "f8a512493aa5b013574a99ce1575e50ebfcd3e5b06bc71d9a3cbfeab21468836",
    "references/zane-nw-candidate.png": "34611d7e1190ab06df24cd229bd7850e10651cf3dabb286163bec5ef899d73db",
    "output/zane-ne-lowered-sword-candidate-v02.png": "07f9d08356739d5ac3a0084f216e8c988abf5889d295da8127fb1e0ce94c63b8",
}
report = {"schema_version": 1, "candidate_accepted": False, "production_ready": False, "files": []}
for rel, expected in EXPECTED.items():
    path = ROOT / rel
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    assert actual == expected, f"Unexpected source pixels: {rel}"
    im = Image.open(path)
    assert im.mode == "RGBA" and im.size == (1254, 1254), rel
    alpha = im.getchannel("A")
    hist = alpha.histogram()
    box = alpha.point(lambda a: 255 if a >= 128 else 0).getbbox()
    border = [alpha.getpixel((x, y)) for x in range(im.width) for y in (0, im.height - 1)]
    border += [alpha.getpixel((x, y)) for y in range(1, im.height - 1) for x in (0, im.width - 1)]
    assert hist[0] / (im.width * im.height) > 0.70, f"Insufficient actual transparency: {rel}"
    assert max(border) < 128, f"Visible silhouette clipped at border: {rel}"
    report["files"].append({
        "file": rel, "sha256": actual, "mode": im.mode, "dimensions": list(im.size),
        "alpha_zero_pixels": hist[0], "alpha_zero_percent": round(100 * hist[0] / (im.width * im.height), 4),
        "alpha_255_pixels": hist[255], "alpha_1_to_254_pixels": sum(hist[1:255]),
        "bounds_alpha_ge_128": list(box), "nonzero_border_pixels": sum(v > 0 for v in border),
        "maximum_border_alpha": max(border), "visible_border_clipping": False,
    })
report["limitations"] = [
    "Real transparency is verified; this is not a fake checkerboard or opaque background.",
    "The new candidate has one very faint nonzero border pixel; these were preserved and not silently repaired.",
    "The original approved front and old SW also contain faint alpha outside their primary silhouettes.",
    "Technical pass does not approve costume, pose, anatomy, real gameplay scale, animation, or calibrated boot pivots.",
    "No runtime, PR, merge, deployment, or existing asset was modified.",
]
print(json.dumps(report, indent=2))
