import struct
import tempfile
from pathlib import Path
import unittest

from check_zane_visual_capture_manifest import REQUIRED, validate


def png_bytes(width, height, marker):
    import zlib

    def chunk(name, data):
        return struct.pack('>I', len(data)) + name + data + struct.pack('>I', zlib.crc32(name + data))

    raw = bytes([0]) + bytes([marker, marker ^ 7, marker ^ 13]) * width
    scanlines = raw * height
    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(scanlines))
            + chunk(b'IEND', b''))


class ZaneCaptureManifestTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.manifest = {'asset_profile': 'zane_painterly_v1', 'model_sha256': 'a' * 64,
                         'source_kind': 'godot_native', 'captures': []}
        for i, (quality, direction, phase) in enumerate(sorted(REQUIRED)):
            name = f'{quality}-{direction}-{phase}.png'
            (self.root / name).write_bytes(png_bytes(260, 300, i + 1))
            self.manifest['captures'].append(
                {'quality': quality, 'direction': direction, 'phase': phase, 'file': name}
            )

    def test_accepts_unique_complete_grid(self):
        result = validate(self.manifest, self.root)
        self.assertTrue(result['passed'], result['errors'])
        self.assertEqual(result['verified_count'], 16)

    def test_missing_direction_fails(self):
        self.manifest['captures'].pop()
        self.assertFalse(validate(self.manifest, self.root)['passed'])

    def test_identical_capture_fails(self):
        a, b = self.manifest['captures'][:2]
        (self.root / b['file']).write_bytes((self.root / a['file']).read_bytes())
        self.assertFalse(validate(self.manifest, self.root)['passed'])

    def test_path_escape_rejected(self):
        self.manifest['captures'][0]['file'] = '../outside.png'
        result = validate(self.manifest, self.root)
        self.assertFalse(result['passed'])
        self.assertTrue(any('escapes' in x for x in result['errors']))

    def test_profile_provenance_rejected(self):
        self.manifest['source_kind'] = 'concept_image'
        self.assertFalse(validate(self.manifest, self.root)['passed'])

    def test_corrupt_png_rejected(self):
        p = self.root / self.manifest['captures'][0]['file']
        p.write_bytes(b'hello')
        self.assertFalse(validate(self.manifest, self.root)['passed'])


if __name__ == '__main__':
    unittest.main()
