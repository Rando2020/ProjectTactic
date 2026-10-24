"""Packaging behavior using actual bytes, never Godot/network mocks."""
import hashlib
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from urllib.parse import urlsplit, parse_qs

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('prepare_web', ROOT / 'tools/prepare_playable_web.py')
prepare_web = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare_web)


class Scripts(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.sources = []
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        if tag == 'script' and 'src' in dict(attrs):
            self.sources.append(dict(attrs)['src'])


class PackagingTests(unittest.TestCase):
    def test_fresh_json_digest_and_versioned_bootstrap_preserve_physical_names(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            pck = b'GDPC' + b'x' * (3 * 1024 * 1024 + 17)
            (directory / 'index.pck').write_bytes(pck)
            (directory / 'index.wasm').write_bytes(b'\0asm\1\0\0\0')
            (directory / 'index.html').write_text('<script src="index.js"></script>')
            prepare_web.prepare(directory)
            self.assertTrue((directory / 'asset-parts.json').exists(), 'fresh data manifest is missing')
            manifest = json.loads((directory / 'asset-parts.json').read_text())
            entry = manifest['index.pck']
            self.assertEqual(entry['size'], len(pck))
            self.assertEqual(entry['sha256'], hashlib.sha256(pck).hexdigest())
            self.assertEqual(entry['parts'], ['index.pck.part0', 'index.pck.part1'])
            self.assertEqual(b''.join((directory / name).read_bytes() for name in entry['parts']), pck)
            legacy = (directory / 'asset-parts.js').read_text()
            self.assertEqual(json.loads(legacy.removeprefix('window.TACTICS_ASSETS = ').strip().removesuffix(';')), manifest)
            scripts = Scripts((directory / 'index.html').read_text()).sources
            wrapper = [s for s in scripts if urlsplit(s).path == 'compressed-wasm-loader.js']
            self.assertEqual(len(wrapper), 1)
            expected = hashlib.sha256((directory / 'compressed-wasm-loader.js').read_bytes()).hexdigest()
            self.assertEqual(parse_qs(urlsplit(wrapper[0]).query), {'v': [expected]})
            self.assertLess(scripts.index(wrapper[0]), scripts.index('index.js'))


if __name__ == '__main__':
    unittest.main()
