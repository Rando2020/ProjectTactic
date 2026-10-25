# Zane impact v1 — editable/reproducible source

## Immutable recovered inputs

The user-provided `Original-Characters-Prototype-Checkpoint/Zane-v2/` was inspected visually before authoring. Copies are versioned here; recovered originals were never edited.

| Input | SHA-256 |
|---|---|
| `source/zane_v2.blend` | `374b52c41275feeb45b1df49ad240fc2923de3d4be8636a74a054c0c925131af` |
| `source/original_build_zane.py` | `276696b68912613dc9a4c19f97b4e35372655a40f4d90f9095716f50e31348eb` |
| Frozen runtime original GLB | `9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5` |

The original builder is included byte-identically for provenance, **not invoked** by the variant: its historical shared-source dependencies are already embedded in the copied complete `.blend`. The new builder loads that verified original scene, refines only Zane mesh/material planes, calls the separate `author_actions.py` pass, exports only rig descendants with nine NLA tracks, saves an editable variant `.blend`, and derives the manifest from the actual exported bytes.

The editable source preserves original approved action references under `_original_reference` names; only the nine NLA tracks export. Six frozen actions, rig data, skin binds and sockets are not edited. Offline two-link pose solves are baked to the existing bones—there is no runtime IK, foot locking, constraint or simulation dependency.

## Rebuild (Blender4.3.2, Python3 with NumPy)

From repository root:

```sh
mkdir -p /tmp/zane-impact-xdg/config /tmp/zane-impact-xdg/cache /tmp/zane-impact-xdg/data
XDG_CONFIG_HOME=/tmp/zane-impact-xdg/config \
XDG_CACHE_HOME=/tmp/zane-impact-xdg/cache \
XDG_DATA_HOME=/tmp/zane-impact-xdg/data \
blender -b -t 2 --python assets/source/zane-impact-v1/build_zane.py
python3 tools/validate_zane_impact_asset.py --report /tmp/zane-impact-compatibility.json
python3 -m unittest tools.test_zane_impact_asset -v
```

Output GLB: `669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90`. A fresh local rebuild was byte-identical. Blender serialization of `.blend` may vary; the checked-in editable source SHA is `eba9f0cce135345fe9ce4c7b9197b63a97f999947c6346f7a6212e735a7df6d9`. Original source hashes are asserted by the builder. Runtime manifest hashes are regenerated, not pasted constants.

## Export-only visual and clearance QA

```sh
# Use the same writable XDG environment as above.
blender -b -t 2 --python assets/source/zane-impact-v1/validate_export.py -- --report /tmp/zane-impact-clearance.json
blender -b -t 2 --python assets/source/zane-impact-v1/render_review.py -- --output /tmp/zane-impact-renders
blender -b -t 2 --python assets/source/zane-impact-v1/render_review.py -- --gait-segments --output /tmp/zane-impact-gait
```

`validate_export.py` imports the **GLB**, samples every clip at96Hz, evaluates actual mesh floor clearance, and ray-tests every blade mesh edge against body triangles, excluding intentional hand.R grip. Initial RED found early lift/upper-arm crossings; the outward lift arc now clears all nine clips. It is a conservative supplement to visual review, not complete self-collision.

`render_review.py` also imports the **GLB**, uses shipping camera size3.2/pitch30/yaw45, and renders160px squares. Display a full square at138.24px to reproduce the local footprint. Four facings, idle/load/contact/follow/recoil/recovery and gait samples are included; `--baseline` renders the untouched original at identical settings. `--gait-segments` renders64px/0.50s and192px/1.00s distance-matched samples. These are offline Blender export captures, not Godot gameplay acceptance.

No third-party art, source textures, paid services, import caches, films, old asset edits or GDScript adapters belong to this task. Native/browser gameplay captures and remote publication verification are separate integration gates. The two new editable `.blend` files and runtime variant use narrowly scoped raw-Git attributes so this reviewed pack is self-contained; existing asset policies remain unchanged.
