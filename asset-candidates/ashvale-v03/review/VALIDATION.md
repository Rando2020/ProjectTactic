# v03 checks and limitations

Six reusable models passed mesh QA with zero errors after clean GLB reimport. Seven GLBs including the assembled scene passed container, mesh, UV and vertex-color checks. The assembled scene is not run as one connected mesh: separate scenery placements are intentional.

Arch moulding end caps initially overlapped stone end faces; the mouldings were shortened. Tree branch intersections were fused, and detached remesh fragments removed. Non-floor assets were grounded at zero. Floor thickness intentionally extends to -0.3 m.

Accepted warnings: stacked UV regions intentionally share material space, not a unique normal bake. glTF splits vertices at hard normals/UV/color boundaries; loose-vertex counts remain zero. A small number of hidden opposing faces remain at masonry and lantern joins as a candidate optimization item. Detailed counts are in export-checks.json.

Godot 4.6.2 Compatibility headless import and scene test passed: seven models instantiate, preview initializes, camera orbit updates. The sandbox reports inability to read the root certificate store; offline import and verification complete. This does not verify production-version behavior, manual controls or performance.

Actual source and clean GLB reimport renders were reviewed, including a wireframe view. The form-pass image records the earlier clean-surface iteration. Geometry and paint have improved, but trim remains relatively clean, masonry repetition is visible, and final painterly art direction has not been approved against a matching reference view. No quantitative reference-likeness claim. No LODs, navigation, collisions or animations in this static environment pack.
