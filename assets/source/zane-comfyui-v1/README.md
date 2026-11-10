# Zane ComfyUI source model v1

User-supplied original `ComfyUI_00001.glb`, uploaded 2026-10-28. Losslessly packaged as `zane-comfyui-v1.glb.xz.part001` through `.part015`; extraction produces the exact original GLB bytes. No geometry, texture or material edits.

## Inspection
- Binary glTF 2.0; header length matches the 59,764,984-byte file.
- 1 mesh, 1 material, 3 embedded images, no external buffer/image dependencies.
- 457,328 vertices and 699,886 indexed triangles.
- No skin/skeleton and no animation clips.
- SHA-256: ef64a48342e6909a5a407bdd78ea98b1f5644fbf561881b09966aa554880b4f5

## Integration status
Source candidate only. Outside the Godot project to avoid adding this large unoptimized asset to the browser export. Existing Zane assets, runtime manifest and 2.5D demo remain unchanged. This upload does not assert visual acceptance, rig compatibility or animation readiness.

## Storage
The 45,892,888-byte XZ archive is split into 15 ordinary Git blobs to fit the connector transport limit. The original GLB exceeds the connected tool's base64 transfer limit, and this route does not supply Git LFS object upload. Do not repeatedly commit large revised exports here; move future source revisions to a functioning LFS workflow. The original file is preserved.

## Extract
Download this directory or check out this branch. Run `python extract_model.py` from any directory, or `py extract_model.py` on Windows from this folder. The script joins all 15 parts, decompresses them, verifies SHA-256, then writes `zane-comfyui-v1.glb` alongside the parts. It refuses to overwrite an existing output.

## Next
Inspect the model visually against approved Zane art, check materials and scale, then create an optimized derivative or render directional sprites. Rigging and animation are separate work. No merge or deployment is included.
