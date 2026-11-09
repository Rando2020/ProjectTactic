"""Run with python test_extraction.py; validates preserved sources and frames."""
import hashlib
import json
import unittest

import numpy as np
from PIL import Image

import extract_frames as extract


def load_image(path):
    with Image.open(path) as image:
        return image.copy()


class ExtractionTests(unittest.TestCase):
    def test_eight_originals_preserved_byte_exact(self):
        sources = json.loads((extract.ROOT / "sources.json").read_text())
        self.assertEqual(len(sources), 8)
        self.assertEqual({s["set"] for s in sources}, {"compact", "painterly"})
        for source in sources:
            path = extract.ROOT / source["path"]
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), source["sha256"])
            image = load_image(path)
            self.assertEqual((image.size, image.mode), ((1254, 1254), "RGBA"))

    def test_frames_are_complete_transparent_and_hash_checked(self):
        manifest = json.loads((extract.ROOT / "frames.json").read_text())
        self.assertEqual(manifest["canvas"], [800, 800])
        self.assertEqual(manifest["foot_anchor"], [400, 740])
        self.assertEqual(len(manifest["frames"]), 16)
        for entry in manifest["frames"]:
            path = extract.ROOT / entry["path"]
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry["sha256"])
            image = load_image(path)
            self.assertEqual((image.size, image.mode), ((800, 800), "RGBA"))
            self.assertEqual(image.getchannel("A").getextrema(), (0, 255))
            left, top, right, bottom = image.getbbox()
            self.assertGreater(left, 0)
            self.assertGreater(top, 0)
            self.assertLess(right, 800)
            self.assertLess(bottom, 800)
            self.assertGreater(bottom - top, 500)

    def test_mirror_fallbacks_are_explicit_and_anchor_preserving(self):
        manifest = json.loads((extract.ROOT / "frames.json").read_text())
        mirrored = [entry for entry in manifest["frames"] if entry["mirrored"]]
        self.assertEqual(len(mirrored), 5)
        for entry in mirrored:
            folder = extract.ROOT / "compact" / "frames" / entry["role"]
            original = load_image(folder / (entry["derived_from"] + ".png"))
            expected = extract.mirrored_at_anchor(original)
            actual = load_image(folder / (entry["direction"] + ".png"))
            self.assertTrue(np.array_equal(np.array(expected), np.array(actual)))

    def test_portraits_are_crops_of_same_front_identity(self):
        for role in extract.SPECS:
            folder = extract.ROOT / "compact" / "frames" / role
            portrait = load_image(folder / "portrait.png")
            expected = load_image(folder / "E.png").crop((235, 115, 565, 445))
            self.assertTrue(np.array_equal(np.array(portrait), np.array(expected)))

    def test_regeneration_is_byte_deterministic(self):
        before = (extract.ROOT / "frames.json").read_bytes()
        extract.generate()
        self.assertEqual((extract.ROOT / "frames.json").read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
