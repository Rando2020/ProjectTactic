"""Contract tests for the exported asset, including deliberately corrupted real GLBs.

The absence of a shipping variant is an intentional RED, not a skipped acceptance.
Run: python3 -m unittest tools.test_zane_impact_asset -v
"""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'godot/assets/3d/characters/zane_v2/zane_v2.glb'
OUT = ROOT / 'godot/assets/3d/characters/zane_impact_v1'
MODEL = OUT / 'zane_impact_v1.glb'
MANIFEST = OUT / 'presentation.json'
VALIDATOR = ROOT / 'tools/validate_zane_impact_asset.py'


def unpack_glb(data):
    length = struct.unpack_from('<I', data, 12)[0]
    doc = json.loads(data[20:20 + length])
    offset = 20 + length
    blen = struct.unpack_from('<I', data, offset)[0]
    return doc, bytearray(data[offset + 8:offset + 8 + blen])


def pack_glb(doc, binary):
    js = json.dumps(doc, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    binary += b'\0' * (-len(binary) % 4)
    return struct.pack('<III', 0x46546c67, 2, 28 + len(js) + len(binary)) + struct.pack('<II', len(js), 0x4e4f534a) + js + struct.pack('<II', len(binary), 0x004e4942) + binary


class ZaneImpactAssetTests(unittest.TestCase):
    def test_00_required_shipping_outputs_exist(self):
        for path in (MODEL, MANIFEST, VALIDATOR):
            self.assertTrue(path.is_file(), f'missing required variant output: {path.relative_to(ROOT)}')

    def setUp(self):
        if not all(p.is_file() for p in (MODEL, MANIFEST, VALIDATOR)):
            if self._testMethodName != 'test_00_required_shipping_outputs_exist':
                self.skipTest('variant absent: explicit required-output test is RED')
            return
        spec = importlib.util.spec_from_file_location('zane_asset_validator', VALIDATOR)
        self.v = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.v)
        self.doc, self.binary = unpack_glb(MODEL.read_bytes())
        self.manifest = json.loads(MANIFEST.read_text())

    def validate_mutation(self, mutate=None, manifest_mutate=None, baseline=None):
        doc, binary, manifest = copy.deepcopy(self.doc), bytearray(self.binary), copy.deepcopy(self.manifest)
        if mutate:
            mutate(doc, binary)
        data = pack_glb(doc, binary)
        manifest['model_sha256'] = hashlib.sha256(data).hexdigest()
        if manifest_mutate:
            manifest_mutate(manifest)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'model.glb').write_bytes(data)
            (root / 'presentation.json').write_text(json.dumps(manifest))
            base = BASE
            if baseline is not None:
                base = root / 'base.glb'
                base.write_bytes(baseline)
            return self.v.validate(base, root / 'model.glb', root / 'presentation.json')

    def reject(self, mutate=None, manifest_mutate=None, baseline=None):
        with self.assertRaises(self.v.ValidationError):
            self.validate_mutation(mutate, manifest_mutate, baseline)

    @staticmethod
    def node(doc, name):
        return next(n for n in doc['nodes'] if n.get('name') == name)

    @staticmethod
    def alter_accessor(doc, binary, index, component=0, delta=.1):
        a = doc['accessors'][index]
        bv = doc['bufferViews'][a['bufferView']]
        offset = bv.get('byteOffset', 0) + a.get('byteOffset', 0) + component * 4
        old = struct.unpack_from('<f', binary, offset)[0]
        struct.pack_into('<f', binary, offset, old + delta)

    def test_valid_variant_differs_in_only_approved_animation_keys(self):
        report = self.v.validate(BASE, MODEL, MANIFEST)
        self.assertEqual(report['changed_clips'], ['walk', 'slash', 'cast'])
        self.assertEqual(report['bone_count'], 16)
        self.assertEqual(report['sockets'], ['Kael_v2_cast_socket', 'Kael_v2_weapon_socket', 'Kael_v2_shield_socket'])
        self.assertEqual(report['status'], 'compatible')

    def test_missing_model_is_rejected(self):
        with self.assertRaises(self.v.ValidationError):
            self.v.validate(BASE, OUT / 'absent.glb', MANIFEST)

    def test_corrupt_baseline_hash_is_rejected(self):
        self.reject(baseline=BASE.read_bytes()[:-1] + b'X')

    def test_incorrect_manifest_baseline_hash_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m.update(baseline_sha256='0' * 64))

    def test_corrupt_variant_hash_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m.update(model_sha256='0' * 64))

    def test_bone_name_difference_is_rejected(self):
        self.reject(lambda d, b: self.node(d, 'spine').update(name='wrong_spine'))

    def test_bone_parent_difference_is_rejected(self):
        self.reject(lambda d, b: self.node(d, 'pelvis')['children'].remove(next(i for i, n in enumerate(d['nodes']) if n.get('name') == 'spine')))

    def test_bone_order_difference_is_rejected(self):
        def change(d, b):
            d['skins'][0]['joints'][0:2] = reversed(d['skins'][0]['joints'][0:2])
        self.reject(change)

    def test_rest_transform_difference_is_rejected(self):
        self.reject(lambda d, b: self.node(d, 'pelvis')['translation'].__setitem__(1, .8))

    def test_skin_inverse_bind_difference_is_rejected(self):
        self.reject(lambda d, b: self.alter_accessor(d, b, d['skins'][0]['inverseBindMatrices']))

    def test_socket_transform_difference_is_rejected(self):
        self.reject(lambda d, b: self.node(d, 'Kael_v2_cast_socket')['translation'].__setitem__(0, .2))

    def test_socket_parent_difference_is_rejected(self):
        self.reject(lambda d, b: self.node(d, 'hand.L').pop('children'))

    def test_unapproved_clip_change_is_rejected(self):
        def change(d, b):
            a = next(a for a in d['animations'] if a['name'] == 'idle')
            self.alter_accessor(d, b, a['samplers'][1]['output'])
        self.reject(change)

    def test_missing_required_clip_is_rejected(self):
        self.reject(lambda d, b: d['animations'].pop())

    def test_extra_clip_is_rejected(self):
        self.reject(lambda d, b: d['animations'].append(dict(d['animations'][0], name='new_gameplay_callback')))

    def test_changed_clip_duration_is_rejected(self):
        def change(d, b):
            a = next(a for a in d['animations'] if a['name'] == 'walk')
            self.alter_accessor(d, b, a['samplers'][0]['input'], delta=.02)
        self.reject(change)

    def test_root_motion_is_rejected(self):
        def change(d, b):
            a = next(a for a in d['animations'] if a['name'] == 'walk')
            c = next(c for c in a['channels'] if d['nodes'][c['target']['node']]['name'] == 'root' and c['target']['path'] == 'translation')
            self.alter_accessor(d, b, a['samplers'][c['sampler']]['output'])
        self.reject(change)

    def test_inconsistent_marker_seconds_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m['source_markers'].update(cast_release=22 / 24))

    def test_inconsistent_marker_frames_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m['marker_frames'].update(slash_contact=15))

    def test_unmeasured_48_pixel_step_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m['gait_calibration']['step_canvas_px'].update(N=48))

    def test_runtime_timing_drift_is_rejected(self):
        self.reject(manifest_mutate=lambda m: m['runtime'].update(prepare=.21))

    def test_compatibility_report_hash_is_verified(self):
        self.reject(manifest_mutate=lambda m: m.update(compatibility_report_sha256='0' * 64))


if __name__ == '__main__':
    unittest.main()
