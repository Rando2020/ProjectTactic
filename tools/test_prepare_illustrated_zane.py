"""Regression tests for the isolated painted sprite delivery tool."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_illustrated_zane import ArtValidationError, CANVAS, DIRECTIONS, export_assets, normalize_sprite


class TestIllustratedZanePreparation(unittest.TestCase):
    @staticmethod
    def valid_sprite() -> Image.Image:
        image = Image.new("RGBA", (100, 160), (0, 0, 0, 0))
        for x in range(35, 65):
            for y in range(15, 158):
                image.putpixel((x, y), (80, 50, 45, 255))
        return image

    def test_normalized_sprite_canvas_and_foot_anchor(self):
        image = normalize_sprite(self.valid_sprite())
        self.assertEqual(image.size, CANVAS)
        bound = image.getchannel("A").getbbox()
        self.assertEqual(bound[3], CANVAS[1] - 4)
        self.assertEqual(image.getpixel((0, 0))[3], 0)

    def test_opaque_collage_rejected(self):
        with self.assertRaises(ArtValidationError):
            normalize_sprite(Image.new("RGBA", (128, 180), (40, 40, 40, 255)))

    def test_too_small_sprite_rejected(self):
        with self.assertRaises(ArtValidationError):
            normalize_sprite(Image.new("RGBA", (32, 32), (0, 0, 0, 0)))

    def test_five_outputs_and_no_unrequested_changes(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            portrait = root / "portrait.png"
            Image.new("RGB", (300, 300), (35, 42, 49)).save(portrait)
            inputs = {}
            for direction in DIRECTIONS:
                p = root / f"{direction}.png"
                self.valid_sprite().save(p)
                inputs[direction] = p
            out = root / "export"
            result = export_assets(portrait, inputs, out)
            self.assertEqual(len(result), 5)
            self.assertTrue(all(p.is_file() for p in result))
            self.assertEqual(len(list(out.iterdir())), 5)

    def test_group_validation_happens_before_writes(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            portrait = root / "portrait.png"
            Image.new("RGB", (300, 300)).save(portrait)
            inputs = {}
            for direction in DIRECTIONS:
                p = root / f"{direction}.png"
                image = self.valid_sprite() if direction != "right" else Image.new("RGB", (100, 160))
                image.save(p)
                inputs[direction] = p
            dest = root / "output"
            with self.assertRaises(ArtValidationError):
                export_assets(portrait, inputs, dest)
            self.assertFalse(dest.exists())


if __name__ == "__main__":
    unittest.main()
