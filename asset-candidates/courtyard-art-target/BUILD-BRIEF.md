# Ruined garden courtyard — art target v01

Status: concept for visual review, not a playable environment or a Blender render. Generated with the built-in image-generation tool using the existing Act 1 flowering ground and ruined wall illustrations as references. The generated image does not supply meshes, materials, collision or measured dimensions.

## What to preserve in the 3D build

One continuous courtyard with ochre earth and interrupted cream flagstones. Lavender-grey stone faces, chipped edges, broad painted surface variation and irregular lilac flower clusters tie it to the existing illustrations. The open middle and two separate low-wall cover positions make the layout readable. A broad stair connects to the terrace and arch at the rear.

Proposed scale is roughly 16 metres across, with a 1 metre terrace rise. These dimensions are a design proposal; the image is not a dimensioned plan. Use a fixed orthographic three-quarter camera for the first quality comparison. Keep foreground plants and wall edges from concealing playable cells. Remove the concept's foreground depth-of-field blur from gameplay.

## Next production slice

Build a small section containing one broken wall end, adjoining worn flagstones, exposed soil, and a flowering plant cluster. Finish its geometry, UVs, painted materials and in-engine lighting before assembling the courtyard. Compare an actual Godot screenshot against the reference at gameplay scale. Do not substitute another untextured primitive kit or a second concept image for this mesh milestone.

Model stone with visibly different outlines, tapered and fractured faces, and deliberate edge chips. Put brushwork and fine cracks into textures. Build foliage with tapered leaf silhouettes and clustered flower cards or economical geometry; avoid evenly spaced identical tufts. Keep ground transitions continuous through material blending and decals, with variation across reused pieces. The first slice should establish the material and lighting recipe for the rest of the scene.

Only after that section looks convincing should we expand the modular set: several wall and flagstone variants, stair assembly, broken arch, rubble, grass/flower clusters, and the continuous ground mesh. Measure performance in Godot before assigning final texture sizes, foliage density and triangle budgets.

## NOVA integration

Keep TacticalGrid authoritative for movement, occupancy, elevation and cover. Overlay its cell highlights onto the continuous environment; visible paving need not align with cell edges. Preserve the existing 0.82 metre presentation height step or migrate all terrain/unit/cursor projection together. A metre-based source scene needs an explicit adapter. Existing Sprite2D units can remain in the current presentation pipeline, but depth occlusion behind 3D walls needs deliberate handling.

The current Act 1 grid bridge remains a technical test. This concept does not replace its meshes, change production gameplay, or establish that the final target quality has been achieved.

## Visual review before mesh expansion

- Does this scene's palette and level of surface detail fit the game?
- Are clear ground routes readable without a permanently visible grid?
- In the actual mesh slice, do silhouette, material breakup and lighting hold up at the same camera angle?
- Does the actual scene retain its quality from another angle, without relying on projected concept art?

## Generation prompt

Create a polished art-direction concept for an original playable 3D tactics-game environment: a small ruined garden courtyard, approximately 16 metres across. Both supplied images are visual REFERENCES only: preserve the warm cream chipped masonry, violet-grey shaded rock, ochre dirt, olive grasses and clustered pale lilac/pink flowers. Elevate the craft to rich painterly 3D environment art inspired by Arcane and No Rest for the Wicked: hand-painted material variation, broad sculpted planes, deliberate asymmetric weathering, art-directed light, restrained fine detail. This is a single coherent scene seen from a fixed elevated orthographic three-quarter GAMEPLAY CAMERA, looking down about 45 degrees, all traversable ground clearly legible. Full-frame landscape composition, no white background, no diagram, no inset panels, no lettering, no UI. A broad worn flagstone approach enters from foreground and opens into an irregular continuous courtyard with ochre soil showing through missing paving. At the far edge, a shallow terrace one metre higher is reached by broad five-step worn stairs; a broken stone arch and partial ruined wall frame that terrace. Short crumbling walls form two clearly separated flank cover positions, while broad clear routes connect the courtyard and stairs. Foreground vegetation frames rather than hides the playable floor. Natural irregular flower clusters and long tapered leaves nestle in wall crevices, not identical repeating tufts. Chunky masonry has chipped corners, fractures, asymmetrical edges, weathered cream tops, muted lavender sides and painterly brushwork. Ground and walls must feel embedded together in a continuous landscape, not individual square boardgame tiles, not cubes, not a floating toy diorama. Focus on one small richly crafted location, no vast distant city or fantasy vista. Warm late afternoon side lighting, cool purple ambient shadows, readable soft contact shadows, no blown out whites. No characters. Aim for a credible environment art target that could be built in Blender and Godot, not a photograph or loose watercolor. Important: the path, flank routes and stair connection should remain visually readable beneath the surface detail.
