"""Independent delivery-contract checks for the original Zane impact cue pack.

These checks deliberately do not certify that a sound is pleasant or impactful;
listen to the actual cues and action-level mix before approving the pack.
"""
from array import array
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'godot/assets/audio/zane_impact_v1'
GENERATOR = ROOT / 'tools/generate_zane_impact_audio.py'
# Keep the expected interface independent of the production generator.
CONTRACT = {
    'step_a': (0.16, -10.0), 'step_b': (0.16, -10.0),
    'sword_load': (0.18, -12.0), 'sword_release': (0.18, -7.0),
    'sword_hit': (0.28, -5.0), 'fire_charge': (0.20, -10.0),
    'fire_release': (0.26, -5.0), 'fire_hit': (0.48, -5.0),
    'fire_miss': (0.26, -12.0), 'fire_immune': (0.28, -11.0),
}


class ZaneImpactAudioTests(unittest.TestCase):
    def manifest(self):
        path = PACK / 'manifest.json'
        self.assertTrue(path.is_file(), 'Missing original Zane cue pack: manifest.json')
        return json.loads(path.read_text(encoding='utf-8'))

    def decoded(self):
        manifest = self.manifest()
        for cue_id, cue in manifest['cues'].items():
            path = ROOT / 'godot' / cue['path'].removeprefix('res://')
            self.assertTrue(path.is_file(), f'Missing cue WAV: {path}')
            self.assertNotEqual(path.read_bytes()[:7], b'version', 'LFS pointer is not hydrated WAV')
            with wave.open(str(path), 'rb') as wav:
                frames = wav.readframes(wav.getnframes())
                pcm = array('h', frames)
                if sys.byteorder != 'little':
                    pcm.byteswap()
                yield cue_id, cue, path, wav.getparams(), [x / 32768 for x in pcm]

    def test_exact_manifest_interface(self):
        manifest = self.manifest()
        self.assertEqual(set(manifest), {'schema_version', 'profile_id', 'cues'})
        self.assertEqual(manifest['schema_version'], 1)
        self.assertEqual(manifest['profile_id'], 'zane_impact_v1')
        self.assertEqual(set(manifest['cues']), set(CONTRACT))
        for cue_id, cue in manifest['cues'].items():
            self.assertEqual(set(cue), {'path', 'gain_db', 'duration_s', 'sha256'})
            self.assertEqual(cue['path'], 'res://assets/audio/zane_impact_v1/' + cue_id.replace('_', '-') + '.wav')
            self.assertIsInstance(cue['gain_db'], float)
            self.assertEqual(cue['gain_db'], CONTRACT[cue_id][1])

    def test_all_hashes_describe_actual_wav_bytes(self):
        for cue_id, cue, path, _, _ in self.decoded():
            with self.subTest(cue=cue_id):
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), cue['sha256'])

    def test_format_is_mono_pcm16_48000_without_loop_metadata(self):
        for cue_id, _, path, params, _ in self.decoded():
            with self.subTest(cue=cue_id):
                self.assertEqual((params.nchannels, params.sampwidth, params.framerate, params.comptype), (1, 2, 48000, 'NONE'))
                raw = path.read_bytes()
                self.assertEqual(raw[:4], b'RIFF')
                # Writer emits only fmt/data, so loop/metadata cannot sneak in.
                self.assertEqual(len(raw), 44 + params.nframes * 2)
                self.assertNotIn(b'smpl', raw[12:44])

    def test_manifest_durations_are_exact_and_within_independent_maxima(self):
        for cue_id, cue, _, params, _ in self.decoded():
            with self.subTest(cue=cue_id):
                self.assertEqual(cue['duration_s'], params.nframes / params.framerate)
                self.assertGreater(cue['duration_s'], 0.05)
                self.assertLessEqual(cue['duration_s'], CONTRACT[cue_id][0])

    def test_all_cues_have_headroom_and_no_clipped_samples(self):
        for cue_id, _, _, _, samples in self.decoded():
            with self.subTest(cue=cue_id):
                peak = max(map(abs, samples))
                self.assertGreater(peak, 0.1, 'Silence/placeholder does not satisfy sound contract')
                self.assertLessEqual(peak, 10 ** (-3.0 / 20))
                self.assertFalse(any(abs(x) >= 32767 / 32768 for x in samples))

    def test_dc_and_click_prone_endpoints_are_absent(self):
        for cue_id, _, _, _, samples in self.decoded():
            with self.subTest(cue=cue_id):
                self.assertLess(abs(sum(samples) / len(samples)), 0.001)
                self.assertEqual(samples[0], 0.0)
                self.assertEqual(samples[-1], 0.0)
                self.assertLess(max(map(abs, samples[:48] + samples[-48:])), 0.025)
                for window in [samples[:96], samples[-96:]]:
                    self.assertLess(max(abs(a - b) for a, b in zip(window, window[1:])), 0.04)

    def test_total_wav_bytes_are_under_one_megabyte(self):
        paths = [row[2] for row in self.decoded()]
        self.assertEqual(set(paths), set(PACK.glob('*.wav')))
        self.assertLess(sum(path.stat().st_size for path in paths), 1_000_000)

    def test_cues_are_distinct_and_alternating_steps_are_not_relabelled(self):
        hashes = [row[1]['sha256'] for row in self.decoded()]
        self.assertEqual(len(set(hashes)), 10)

    def test_generator_reproduces_exact_pack_twice(self):
        self.manifest()
        self.assertTrue(GENERATOR.is_file(), 'Missing deterministic source generator')
        with tempfile.TemporaryDirectory(prefix='zane-audio-test-') as tmp:
            first = Path(tmp) / 'first'
            second = Path(tmp) / 'second'
            for target in [first, second]:
                result = subprocess.run([sys.executable, str(GENERATOR), '--output-dir', str(target)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual((target / 'manifest.json').read_bytes(), (PACK / 'manifest.json').read_bytes())
                for cue_id in CONTRACT:
                    name = cue_id.replace('_', '-') + '.wav'
                    self.assertEqual((target / name).read_bytes(), (PACK / name).read_bytes(), name)
            self.assertEqual((first / 'manifest.json').read_bytes(), (second / 'manifest.json').read_bytes())

    def test_preview_uses_one_action_level_fire_tail_not_three_hits(self):
        self.manifest()
        self.assertTrue(GENERATOR.is_file(), 'Missing deterministic source generator')
        with tempfile.TemporaryDirectory(prefix='zane-preview-test-') as tmp:
            output = Path(tmp) / 'pack'
            previews = Path(tmp) / 'previews'
            result = subprocess.run([sys.executable, str(GENERATOR), '--output-dir', str(output), '--preview-dir', str(previews)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            events = json.loads((previews / 'preview-events.json').read_text())
            self.assertEqual(events['fire_recipient_count'], 3)
            self.assertEqual(events['fire_sequence'], [
                {'cue_id': 'fire_charge', 'start_s': 0.3},
                {'cue_id': 'fire_release', 'start_s': 0.5},
                {'cue_id': 'fire_hit', 'start_s': 0.72},
            ])
            with wave.open(str(previews / 'fire-sequence.wav'), 'rb') as wav:
                self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, 48000))
                self.assertGreater(wav.getnframes(), 48000)
                actual = array('h', wav.readframes(wav.getnframes()))
                if sys.byteorder != 'little':
                    actual.byteswap()
            expected = [0.0] * len(actual)
            manifest = json.loads((output / 'manifest.json').read_text())
            for event in events['fire_sequence']:
                cue = manifest['cues'][event['cue_id']]
                with wave.open(str(output / Path(cue['path']).name), 'rb') as wav:
                    source = array('h', wav.readframes(wav.getnframes()))
                    if sys.byteorder != 'little':
                        source.byteswap()
                start = round(event['start_s'] * 48000)
                gain = 10 ** (cue['gain_db'] / 20)
                for index, value in enumerate(source):
                    expected[start + index] += value * gain
            # Quantization differs by <= 2 LSB: the generator mixes float sources,
            # whereas this independent check starts with delivered PCM16 sources.
            self.assertLessEqual(max(abs(value - expect) for value, expect in zip(actual, expected)), 2.0)

    def test_provenance_and_authorship_are_documented(self):
        self.manifest()
        self.assertTrue((PACK / 'README.md').is_file(), 'Missing original synthesis provenance')
        readme = (PACK / 'README.md').read_text(encoding='utf-8')
        for required in ['deterministic', 'No external samples', '48', 'physical', 'gain_db', 'generate_zane_impact_audio.py']:
            self.assertIn(required, readme)


if __name__ == '__main__':
    unittest.main()
