# Ashvale v03 — chapel approach

Original static environment meshes guided by the painterly planes of Arcane and the exaggerated, weathered forms of No Rest for the Wicked. Those are visual influences, not a claim of matched fidelity. No extracted assets are used. User delegated design and prompt decisions.

## Visual criteria

- Pointed gate reads as the dominant silhouette at the tactical camera; crooked lanterns frame its opening.
- Warm cut-stone edges separate from dark slate, while amber lamps create focal accents against cool shadows.
- Distinct construction for stone, forged metal, timber and bark; avoid a single material across every object.
- Broad surfaces and material marks remain readable when viewed from above. Fine detail is secondary.
- Keep open floor around the entry for tactical readability. The model does not define walkability.

## Scale and inferred construction

The repository contract is a 2 m tile and 1 m elevation step. The floor piece remains 2 m square with thickness below the origin. Gate opening is authored at about 2.2 m between its inner spring points; crown about 4.9 m high. Gate footprint is approximately 4.2 m wide, so treat it as scenery spanning multiple cells rather than a 2 m wall replacement. Buttress approximately 3.6 m; tree about 3.8 m; lantern about 2.6 m; barricade about 2 m wide. Exact bounds and triangle counts are in the manifest.

All designs, proportions, concealed surfaces and wear patterns are inferred. No matching orthographic reference views were supplied, so no silhouette-IoU or measured likeness claim is made. This pass targets stronger architecture and surface direction; final reference-level paintwork, damage variation and production camera approval remain outstanding.

## Material production

Slate albedo generated with built-in ImageGen: flat base-color swatch for original painterly dark fantasy stone; broad angular dry-brush and scumbled slate pigment; charcoal blue-green base, desaturated warm-gray marks, rare muted ochre; no white veins, masonry grid, scene, perspective, lettering or directional light. The resulting image is retained in textures/chapel-painted-slate.png and embedded in exported GLBs. Seamlessness is not asserted. Other surfaces use authored broad vertex-color planes and standard glTF materials. This is not a unique sculpt-to-low-poly normal bake.

## Iteration

The form-pass render is preserved under review/01-form-pass.png. Its surfaces read too clean and uniform. The second pass adds slate paint, corrects arch moulding overlaps and fuses the tree branch junctions. Review the actual exported-mesh render as well as the source render: a concept image is not evidence of mesh quality.
