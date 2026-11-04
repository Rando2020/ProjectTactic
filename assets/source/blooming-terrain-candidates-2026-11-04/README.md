# Blooming Ruins terrain/prop candidates

This isolated source package extends the existing art kit. It does not modify runtime assets or establish visual approval.

## Reuse first

The existing Blooming Ruins v2 manifest at commit `8d5284e239f7573715bd507de21bf45f5896bc20` already contains four material quadrants, six foliage cutouts, four architecture cutouts, four props and a distant backdrop. It includes a low wall and rubble, so this package focuses on a corner, a broken end and a decorative ground scatter rather than another generic wall/tile.

Source manifest: https://github.com/Rando2020/ProjectTactic/blob/8d5284e239f7573715bd507de21bf45f5896bc20/godot/assets/environments/blooming-ruins-v2/manifest.json

The material reference is the existing November 4 broken-pillar candidate, not an approved production reference: https://github.com/Rando2020/ProjectTactic/blob/3b1958e28e60b4f15593f242e8127a67e46a19b3/assets/source/production-catalog-2026-11-04/candidates/chapel-broken-pillar.png

## New candidates

- `chapel-low-wall-corner-v1.png`: low L corner; intended to keep character silhouettes clear.
- `chapel-low-wall-broken-end-v1.png`: one-axis terminating wall with localized breakage.
- `chapel-stone-scatter-clean-v2.png`: preferred decorative ground scatter of cream chips, moss and lilac flowers.
- `chapel-stone-soil-scatter-v1.png`: superseded study. Its faint dust does not form a reliable stone/soil transition.

All were generated with the built-in image tool on November 4, 2026. Original bytes are preserved. Prompts and image measurements accompany the package.

## Before integration

These cutouts are single-camera illustrations, not rotation-ready geometry. Do not mirror or rotate their rasters and claim that another camera view has been authored. The 96×48 logical tile projection is a target alignment contract, not a guarantee that generated edges exactly obey it.

Collision and occupancy must be decided by gameplay data, never inferred from alpha. Pivot and occupancy fields are deliberately unset until scene registration. Wall joining, seams, scene scale, hidden-unit readability and native game-size tests remain required. The ground decoration should not hide movement/targeting overlays.

This source-only package does not change live gameplay or integrate the candidates into runtime. Publishing or merging it does not establish visual approval.

## Independent visual and technical QA

The wall pair coheres with the cream stone/lavender shade palette. The corner has capped ends, not modular sockets. The broken end has a taller wall span at comparable stone size, so the pair must not be advertised as directly joinable. Establish shared heights, capstone dimensions and anchors before an assembly test.

All four files are 1774×887 RGBA. No substantial edge clipping was found. The two wall files contain alpha=1 residue on a few canvas-edge pixels; naive nonzero-alpha trimming will retain excess margins. Low-alpha colored RGB fringes are not opaque borders. Measurements include visible bounds at alpha>=128, nonzero bounds and low-alpha counts without altering originals.

The cleaned scatter is a loose decorative V, not a seamless tile, autotile mask or validated terrain-blend system. The HTML review displays source PNGs over light/dark backgrounds and a reference grid; its small previews do not establish engine scale. No captured browser screenshot is included.
