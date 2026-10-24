#!/usr/bin/env python3
"""Package a Godot Web export into small static assets for constrained hosts."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path


def prepare(directory: Path):
    root = Path(__file__).resolve().parents[1]
    manifest = {}
    for name, mime in [('index.wasm', 'application/wasm'), ('index.pck', 'application/octet-stream')]:
        source = directory / name
        if not source.exists():
            raise RuntimeError(f'Missing fresh export {source}; export before packaging')
        raw = source.read_bytes()
        packed = gzip.compress(raw, compresslevel=9, mtime=0) if name.endswith('.wasm') else raw
        parts = []
        for i in range(0, len(packed), 3 * 1024 * 1024):
            part = f'{name}.part{i // (3 * 1024 * 1024)}'
            (directory / part).write_bytes(packed[i:i + 3 * 1024 * 1024])
            parts.append(part)
        manifest[name] = {'parts': parts, 'gzip': name.endswith('.wasm'), 'type': mime, 'size': len(raw)}
        if name.endswith('.pck'):
            manifest[name]['sha256'] = hashlib.sha256(raw).hexdigest()
        source.unlink()  # Generated export only; exact bytes retained in parts.
    old = directory / 'index.wasm.gzip'
    if old.exists():
        old.unlink()
    (directory / 'asset-parts.js').write_text('window.TACTICS_ASSETS = ' + json.dumps(manifest) + ';\n')
    (directory / 'asset-parts.json').write_text(json.dumps(manifest) + '\n')
    loader = (root / 'web/compressed-wasm-loader.js').read_bytes()
    loader_version = hashlib.sha256(loader).hexdigest()
    html = directory / 'index.html'
    text = html.read_text()
    script = ('<script src="asset-parts.js"></script>\n'
              f'<script src="compressed-wasm-loader.js?v={loader_version}"></script>')
    text = text.replace('<script src="index.js"></script>', script + '\n<script src="index.js"></script>')
    if script not in text:
        raise RuntimeError('Godot loader marker changed')
    text = text.replace('<title>ProjectTactic</title>', '<title>The Appointed | Tactical Descent</title>')
    html.write_text(text)
    (directory / 'compressed-wasm-loader.js').write_bytes(loader)
    print('Prepared playable Web export:', directory)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    prepare(parser.parse_args().directory)
