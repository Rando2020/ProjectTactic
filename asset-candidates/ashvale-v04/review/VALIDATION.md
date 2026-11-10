# v04 validation

Nine reusable meshes passed clean Blender GLB reimport and mesh QA with zero errors. Ten GLBs including the assembled scene passed container, UV, mesh and vertex-color checks. Models were visually reviewed in source and clean-reimport material renders; a wireframe scene and banner/timber closeups are included.

Fixed during this pass: wood end-face UVs collapsed under vertical projection, so caps now use a separate planar projection. Internal gate shaft/base overlaps were offset to remove coplanar faces. The dense banner hem initially folded back through itself; reduced tear amplitude preserves monotonic vertical progression while retaining torn edges.

Accepted warnings: UV overlap intentionally shares paint regions; this layout is not suitable for a unique normal bake. glTF split vertices preserve hard normals, UVs and per-face paint; no loose vertices. Small amounts of hidden opposing geometry remain in masonry and lantern joins. Floor pivots are at the nominal walking surface, with thickness extending to -0.3 m. Counts are recorded in export-checks.json.

Godot 4.6.2 Compatibility headless import and tests passed: ten GLBs instantiate, scene initializes and orbit updates. Sandbox certificate-store warning does not prevent offline checks. Manual keyboard controls, production-version import, runtime performance and combat integration remain unverified.

Art remains a candidate: shared texture repetition, regular structural rhythm, static cloth, no LODs or collision proxies. Images show actual exported 3D assets, not generated final-scene concepts. No quantitative claim of matching the reference titles.
