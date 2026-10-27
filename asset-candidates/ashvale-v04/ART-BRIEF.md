# v04 art direction and provenance

Continue toward an original painterly dark-fantasy setting informed by Arcane's expressive planes and No Rest for the Wicked's weight and aged construction. Do not extract or reproduce their game assets. The user delegated prompt and design decisions.

This pass addresses the v03 render's sterile pale trim, plain timber, regular paving and sparse dressing. Prioritize material-specific wear, restrained ochre limestone, dark blue slate, aged timber and oxblood cloth. Large paint marks should read from the tactical camera without photographic noise.

All proportions, damage, backs and banner design are authored. The known project contract is meters, 2 m tiles and 1 m elevation increments; no new elevation module is added here. No matched orthographic reference was supplied, so no measured likeness or silhouette-IoU claim.

## Image-generation prompts

Limestone: flat, equally lit albedo swatch of weathered limestone for original painterly dark-fantasy Gothic architecture. Muted medium-value warm gray / gray ochre; angular drybrush patches, charcoal discoloration, occasional chipped chalk flecks; no large white areas, masonry outlines, objects, perspective, lettering, shadows or directional lighting. Broad and medium pigment shapes, little micro-noise.

Timber: flat, equally lit albedo swatch; long vertical hand-painted grain in medium-dark desaturated umber, charcoal and gray-brown; sparse warm worn ridges, elongated knots and gray remnants of aged paint. No separate planks, grid, perspective, shadows, objects, lettering or tiny noisy fibers.

Slate: retained from v03, generated with built-in ImageGen as flat charcoal blue-green painterly slate with broad gray and sparse ochre pigment marks. All three swatches were generated with built-in ImageGen. No external asset downloads. Seamlessness has not been proven; UVs reuse regions for a shared-material approach.

Geometry, vertex tint, cloth folds, emblem and material assembly were authored in Blender. Texture images use sRGB base color; they are not normal maps. Standard glTF roughness/metallic and emission settings carry to exports. No Cycles-only procedural nodes are needed at runtime.

## Remaining visual work

Break repeated structural damage with authored variants; develop more deliberate hero-surface paint rather than broad shared swatches; improve banner hem / emblem at close-up; assess lighting against the actual game camera. The environment is static. Character likeness and animation work remain in the separate v02 candidate, unchanged by this pass.
