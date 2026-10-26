#!/usr/bin/env python3
"""Check Zane visual-review coverage and screenshot integrity.

A passing manifest never proves likeness, renderer provenance or valid animation.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

DIRECTIONS = ('N', 'E', 'S', 'W')
QUALITIES = ('standard', 'high')
PHASES = ('idle', 'walk', 'slash', 'cast', 'hit')
REQUIRED = {(quality, direction, 'idle') for quality in QUALITIES for direction in DIRECTIONS}
REQUIRED |= {(quality, 'S', phase) for quality in QUALITIES for phase in PHASES}
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def inspect_png(path: Path) -> dict:
    with path.open('rb') as stream:
        header = stream.read(24)
    if len(header) != 24 or not header.startswith(PNG_SIGNATURE) or header[12:16] != b'IHDR':
        raise ValueError('not a PNG with an IHDR')
    width, height = struct.unpack('>II', header[16:24])
    if width < 256 or height < 256 or width > 16384 or height > 16384:
        raise ValueError(f'out-of-range image dimensions {width}x{height}')
    return {'width': width, 'height': height, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def validate(manifest: dict, captures_dir: Path) -> dict:
    errors = []
    expected = manifest.get('model_sha256')
    if manifest.get('asset_profile') != 'zane_painterly_v1':
        errors.append('asset_profile must be zane_painterly_v1')
    if not isinstance(expected, str) or len(expected) != 64 or any(c not in '0123456789abcdef' for c in expected):
        errors.append('model_sha256 must be a lowercase 64-digit SHA-256 string')
    if manifest.get('source_kind') not in ('godot_native', 'godot_web'):
        errors.append('source_kind must identify godot_native or godot_web')
    captures = manifest.get('captures')
    if not isinstance(captures, list):
        return {'passed': False, 'errors': errors + ['captures must be a list'], 'files': []}
    observed = set()
    digests = set()
    processed = []
    for number, entry in enumerate(captures):
        if not isinstance(entry, dict):
            errors.append(f'capture {number}: not an object')
            continue
        key = (entry.get('quality'), entry.get('direction'), entry.get('phase'))
        if key not in REQUIRED:
            errors.append(f'capture {number}: unexpected quality/direction/phase {key}')
            continue
        if key in observed:
            errors.append(f'capture {number}: duplicate capture key {key}')
            continue
        observed.add(key)
        rel = entry.get('file')
        if not isinstance(rel, str) or not rel.lower().endswith('.png'):
            errors.append(f'capture {number}: file must be a relative PNG path')
            continue
        base = captures_dir.resolve()
        target = (captures_dir / rel).resolve()
        if not target.is_relative_to(base) or target == base:
            errors.append(f'capture {number}: path escapes captures directory')
            continue
        try:
            dimensions = inspect_png(target)
        except (OSError, ValueError) as exc:
            errors.append(f'capture {number}: {exc}')
            continue
        digest = dimensions['sha256']
        if digest in digests:
            errors.append(f'capture {number}: byte-identical duplicate capture')
        digests.add(digest)
        processed.append({'key': list(key), 'file': rel, **dimensions})
    missing = sorted(REQUIRED - observed)
    if missing:
        errors.append(f'missing direction/phase/quality captures: {missing}')
    return {
        'passed': not errors, 'errors': errors,
        'required_count': len(REQUIRED), 'verified_count': len(processed),
        'files': processed,
        'limitations': 'Coverage/file integrity only; not visual similarity, genuine provenance, animation correctness or browser acceptance.'
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('--captures-dir', type=Path)
    p.add_argument('--output', type=Path)
    args = p.parse_args()
    try:
        source = json.loads(args.manifest.read_text(encoding='utf-8'))
        if not isinstance(source, dict):
            raise ValueError('manifest must be JSON object')
        report = validate(source, args.captures_dir or args.manifest.parent)
    except (OSError, ValueError) as exc:
        report = {'passed': False, 'errors': [str(exc)]}
    payload = json.dumps(report, indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding='utf-8')
    else:
        print(payload)
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
