"""Asset/manifest contract for four-character isometric hero idle set v02."""
import hashlib
import json
from pathlib import Path
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
ASSET_DIR = GODOT / "assets/characters/iso-v02"
HEROES = {"zane": "swordsman", "mira": "mage", "lyra": "rogue", "kael": "dragoon"}
FACE_TO_ISO = {"front": "sw", "right": "se", "back": "ne", "left": "nw"}


class HeroIsometricV02Contract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((GODOT / "data/asset_manifest.json").read_text(encoding="utf-8"))

    def test_manifest_and_fallbacks(self):
        characters = self.manifest["characters"]
        for unit_id, role in HEROES.items():
            with self.subTest(hero=unit_id):
                entry = characters[unit_id]
                self.assertEqual(set(entry["directions"]), set(FACE_TO_ISO))
                for facing, diagonal in FACE_TO_ISO.items():
                    spec = entry["directions"][facing]
                    expected = f"res://assets/characters/iso-v02/character-{role}-idle-{diagonal}-v02.png"
                    self.assertEqual(spec["path"], expected)
                    self.assertTrue(spec["fallback_path"].startswith("res://assets/"))
                    self.assertTrue((GODOT / spec["fallback_path"].removeprefix("res://")).is_file())

    def test_transparent_256px_sprites_with_common_foot_line(self):
        for unit_id, role in HEROES.items():
            digests = set()
            for diagonal in FACE_TO_ISO.values():
                path = ASSET_DIR / f"character-{role}-idle-{diagonal}-v02.png"
                with self.subTest(hero=unit_id, direction=diagonal):
                    self.assertTrue(path.is_file(), str(path))
                    self.assertGreater(path.stat().st_size, 12000)
                    self.assertLess(path.stat().st_size, 200000)
                    content = path.read_bytes()
                    self.assertTrue(content.startswith(b"\x89PNG\r\n\x1a\n"), str(path))
                    digests.add(hashlib.sha256(content).hexdigest())
                    with Image.open(path) as img:
                        self.assertEqual(img.size, (256, 256))
                        self.assertIn(img.mode, ("RGBA", "LA"))
                        alpha = img.getchannel("A")
                        self.assertEqual(alpha.getpixel((0, 0)), 0)
                        self.assertEqual(alpha.getpixel((255, 255)), 0)
                        bbox = alpha.getbbox()
                        self.assertIsNotNone(bbox)
                        self.assertGreaterEqual(bbox[3], 238)
                        self.assertLessEqual(bbox[3], 247)
                        self.assertGreater(bbox[2] - bbox[0], 90)
            self.assertEqual(len(digests), 4, f"{unit_id} views should not duplicate one image")


if __name__ == "__main__":
    unittest.main()
