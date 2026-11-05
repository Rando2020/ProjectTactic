# Blooming ground transition

Goal: remove the visible road/stone cell boundary while preserving the existing tactical board, stairs, elevation, selections, and source art. This is an isolated opt-in scene patch, not a deployment or wall-asset integration.

Root cause: the shader uses world coordinates, but the soil blend runs only for `surface==1`. Its road-side mask is fully soil at the common edge of (6,6)/(6,7), while the stone side is forced to paving.

Chosen approach: evaluate one shared world-space soil field on ordinary lower-floor tops. The material derives the soil-plane uniform by transforming `BASE_TILE_TOP_Y` through the actual terrain root (model y=.26 becomes world y=0). Keep upper landing, side faces, and surface 3 stairs unchanged. Do not replace geometry or repack textures. A new texture or merged mesh would add work without addressing this material gate.

The lower garden mask is bounded inside the court. Keep the full two-cell stair lanes centered at model x=5 and x=17 with half-width 2, derived from columns 2–3 and 8–9 at 2 model units per cell. Keep lower perimeter cell centers paved. Let irregular soil edges cross logical cell boundaries. Terrain tags remain authoritative for gameplay and are unchanged.

Verification: first capture the current material-dependent mismatch with actual renderer tests, then require identical lower-ground output for the same world patch under surface 0 and 1. Compare upper landing, stairs, side faces, and protected path-center renders against a frozen original shader. Capture the actual integrated scene before/after with selection highlights, and run existing geometry, path, lifecycle, and combat/UI tests. Source PNG hashes and map/grid code must remain identical. Native rendering is distinct from browser performance, which is not claimed.
