#!/usr/bin/env python3
"""Stage an existing Godot Web export for a static host with gzip headers.

The source export is never modified. Use a new or empty destination directory.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import shutil


def prepare(source, destination):
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if destination == source or source in destination.parents:
        raise ValueError('Destination must be outside the source export')
    if destination.exists() and any(destination.iterdir()):
        raise ValueError('Destination must be empty')
    required = ['index.html', 'index.js', 'index.wasm', 'index.pck']
    for name in required:
        if not (source/name).is_file() or not (source/name).stat().st_size:
            raise ValueError(f'Missing export: {name}')
    if (source/'index.wasm').read_bytes()[:4] != b'\0asm':
        raise ValueError('Source wasm is not an uncompressed Godot export')
    destination.mkdir(parents=True, exist_ok=True)
    for path in source.iterdir():
        if path.is_file():
            shutil.copy2(path, destination/path.name)
    original = (source/'index.wasm').read_bytes()
    compressed = gzip.compress(original, compresslevel=9, mtime=0)
    assert gzip.decompress(compressed) == original
    (destination/'index.wasm').write_bytes(compressed)
    (destination/'_headers').write_text(
        '/index.wasm\n  Content-Type: application/wasm\n  Content-Encoding: gzip\n'
        '/*\n  Cache-Control: no-cache\n', encoding='utf-8')
    report = {'wasm_original_bytes': len(original), 'wasm_hosted_bytes': len(compressed),
              'wasm_sha256': hashlib.sha256(original).hexdigest(),
              'files': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in destination.iterdir() if p.is_file()}}
    (destination/'build-manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k != 'files'}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('destination')
    args = parser.parse_args()
    prepare(args.source, args.destination)
