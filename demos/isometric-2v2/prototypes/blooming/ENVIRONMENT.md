# Blooming environment integration

This is a fixed-camera 2.5D presenter, not the PR96 independent encounter.

- Real textured 3D floor/retaining/stair geometry is projected using the existing PracticeTerrain3D orthographic camera. Units and painted architecture/foliage are depth-sorted 2D cutouts.
- Logical board12×11, projection128×64, height32px. Upper landing y0–2 at height4. Stair columns2–3 and8–9 use y5/4/3 heights1/2/3. Three physical treads per logical cell; central tread is the authoritative unit foot height. There are nine narrow treads per flight, not the source preview's eight.
- `surface_polygons(cell)` returns the separate actual tread top footprints. Use those for targeting. `surface_polygon(cell)` is their convex hull, intended only for bounds/tests.
- `pick_cell(point)` selects the foremost rendered top surface. Movement/occupancy/height legality stay in TacticalGrid/GridSystem. Stair-adjacent hidden pockets(1,4),(7,4) are blocked, not click-through tiles.
- Decor follows source manifest crop rectangles and pivots; source-alpha cutoff0.5 removes sheet backdrop halos. It fades to0.30 for a known visible Unit whose head lies behind the painted rectangle, then restores. This conservative rectangle test may fade an arch even when the head is within its opening; it is not a new visibility/FOW system.
- `configure(grid)` must be called after assigning `grid.terrain_view`. Repeat calls rebuild without duplicate decor. Presenter disposal also disposes its cutouts.
- Zane(3,8), Kael(2,9), Imp(6,7), Cultist(8,2); four units retain the existing combat/AI systems.

Source art copied unmodified from user-provided draft PR96 head8d5284e239f7573715bd507de21bf45f5896bc20. No Encounter script imported. Original PR files and v11 demo remain preserved. No audio changes.

GeometryTest.tscn: 431 checks pass (actual camera projection, all walkable center picks, every narrow tread, known-unit fade/restore, repeat configure, upper-lip ivy anchor). Headless checks do not establish rendering quality; integrated native captures are owned by the main coordinator.
