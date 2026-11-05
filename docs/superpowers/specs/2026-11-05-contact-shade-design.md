# Ground existing courtyard props

Goal: make existing vegetation and stone props feel attached to the courtyard without adding or moving assets, changing gameplay, or altering #107's soil blend.

Chosen proposal: a restrained world-space contact mask in the existing terrain shader, supplied from the actual support positions of six cypresses, three columns/piers, and one pot grouping. Begin with a maximum 18% darkening and small per-prop radii. Apply only to ordinary upward-facing terrain at the matching support height. Use the maximum overlapping mask, not cumulative blackening. Zero contacts must produce identical pixels to #107. Exclude stairs, sides, the arch, low wall, banners, ivy, and bushes in this first pass; their support geometry is less certain.

Alternatives considered: projected 2D shadows could bleed over cliffs; additional clipped 3D shadow meshes would add geometry/rendering complexity for a fixed cached terrain; full relighting would conflict with baked painted art. The shader mask is the smallest receiver-aware approach and stays inside terrain pixels, beneath highlights and units.

Source of truth: exact existing decoration cells, terrain root transform, and grid heights. Keep source atlases, manifests, map/grid, decorations, and actor placements unchanged. Build on #107 in a new isolated branch, with no mutation of existing branches or deployment.

Implementation: keep compact contact profiles/data beside BloomingTerrain decoration setup, synchronize material uniforms after garden creation and rebuild, then apply the soft mask after existing surface coloring. Limit array capacity explicitly. Rebuild/configure must not duplicate contacts; the existing render-once viewport must refresh.

Verification: first add a rendered regression that fails without contact shading. Prove local top darkening with identical distant pixels, wrong-height surfaces, sides, stairs, and zero-contact output. Check ten contact supports and repeated rebuilds. Run geometry, current ground regressions, and supported gameplay/HUD tests. Capture actual before/after overview and highlights with a test-only toggle; inspect close views for dark discs, overhangs, or reduced readability. Independent review before a separate draft. Retain only if the paired render is a clear improvement.
