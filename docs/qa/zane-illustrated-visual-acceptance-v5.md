# Zane V5 visual acceptance contract

**Scope:** capture completeness and art review for the existing `zane_painterly_v1` candidate. No production renderer or asset replacement in this PR.

## Why this gate is needed

Offline painted art can look much better than a rigged character at one angle while being unusable for directional gameplay. The local V5 four-facing study confirmed this asymmetry: south/front and north/rear were extracted from the original reference; east/west were geometry-derived placeholders from an obsolete V3. None is an approved production capture. Do not mix V5 local reference images into the Godot runtime.

## Authoritative capture procedure

Use Godot 4.6.3 with the repo's **existing** `Practice: Zane vs Storm Imp` path, the actual `zane_painterly_v1` model and the frozen viewport camera (ortho size 3.2, pitch 30°, yaw 45°, target Y 0.95). Keep the existing footprint 138.24 and actual render settings: Standard 192, High 384, linear texture filtering with existing High 4x MSAA. Collect genuine screenshots for:

- N/E/S/W at idle in **both** Standard and High.
- S at walk, slash, cast, hit in **both** Standard and High.
- For each action also record frame/time and whether that clip was actually selected by Godot. Mark static posing separately from animation playback.
- Include observed model SHA-256, profile, source_kind, game build SHA and observer platform. Capture and save with identical camera/tile footing; do not infer visual quality from exported frame resolution.
- Include motion footage for the sword, cast, full walk cycle and defeat on a separate manual acceptance pass. A fixed set of 16 captures cannot prove continuous behavior.

A machine-checkable manifest is expected at `build/zane-visual-v5/manifest.json`. `tools/check_zane_visual_capture_manifest.py` checks 16 key combinations, nonempty valid PNG headers, plausible dimensions, safe paths, unique files and obvious duplicate bytes. The manifest's source_kind remains **self-declared**, so a passing validator does not prove the screenshot came from the real game.

Example (partial; add all 16 captures):
```json
{
  "asset_profile": "zane_painterly_v1",
  "model_sha256": "14c7497613c45f58edd949c7c258a1b220e3d29d95e118ba2557dea98b411e20",
  "source_kind": "godot_native",
  "build_sha": "<actual checked-out commit>",
  "captures": [
    {"quality":"standard","direction":"S","phase":"idle","file":"standard-S-idle.png"},
    {"quality":"high","direction":"N","phase":"idle","file":"high-N-idle.png"}
  ]
}
```

Run:
```sh
python tools/check_zane_visual_capture_manifest.py build/zane-visual-v5/manifest.json \
  --output build/zane-visual-v5/validation.json
python -m unittest discover -s tools -p test_check_zane_visual_capture_manifest.py
```

## Review rubric

Use evidence from actual Godot rather than a composite concept image. Evaluate at original battle footprint plus a documented close crop. Record pass/fail and specific image references for: face and hair, scarf volume, armor shape, coat silhouette and cloth bends, sword/right-versus-left consistency, colors under production lighting, foot/selection alignment, visible cast release, no ghosting on movement, anti-aliasing, legibility above dark/light terrain, runtime performance (dense battle) and fallback after unavailable resources.

Prioritize (1) character silhouette, (2) facial/hair identity, (3) cloth/plate geometry, (4) palette and material, (5) VFX, then fine ornament. Separate hard pass/fail functional constraints from subjective art direction notes.

## Acceptance boundaries

- The existing imported and source art hashes remain the authority until a new reviewed asset is deliberately frozen.
- No image-derived side sprite, old V3 mesh, AI concept render or local CSS animation counts as native or WebGL2 gameplay evidence.
- A `passed` manifest means capture **coverage and file integrity only**. Human/native/browser visual signoff still required.
- No merge, release, deployment or automatic production switch is authorized by this documentation.
