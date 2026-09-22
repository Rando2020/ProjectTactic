# Enemy Pack: Hollows and Elites v01

- Asset ID: `enemy-hollows-and-elites`
- Intended use: first vertical-slice enemy silhouettes
- Generation tool: transparent-capable image generator with character-reference support
- Generation date: 2026-09-22 for the idle pilot
- Status: runtime-tested prompt contract

## Production objective

Create an original enemy family called Hollows for the Godot Web battlefield. Hollows are people-shaped remnants whose solved emotions left deliberate absences in armor, cloth, faces, and posture. Their horror comes from missing identity rather than gore.

Generate one role and one pose per output. Contact sheets, pose grids, lineups, captions, and environment plates are automatic rejections.

## Shared family and rendering contract

- Materials: worn iron, ash cloth, cracked leather, civic insignia rubbed smooth.
- Identity treatment: an empty readable face plane or deliberate facial absence, never a skull or exposed anatomy.
- Accent: restrained violet-black seams plus a small muted rust-red enemy marker.
- Rendering: painterly pixel-adjacent finish, crisp outer contour, simplified internal detail.
- Light: soft southwest key light from upper left with cool ambient shadow.
- Proportions: grounded adult, neither zombie nor oversized demon.
- Camera: fixed three-quarter isometric battlefield view, elevated approximately 30 degrees.
- Enemy facing: body and attention face down-left toward the opposing squad.
- Family resemblance comes from missing face planes, rubbed insignia, ash cloth, and violet seams, not cloned armor.

## Exact runtime output contract

- Output one genuinely transparent PNG with one enemy only.
- Normalize to an exact 128 × 128 canvas.
- Keep every visible pixel within x 8 to 120 and y 4 to 124.
- Place both feet on the same baseline at y 120 to 124.
- Center the midpoint between the feet at x 64, tolerance 6 px.
- Preserve transparent space beneath the feet. Do not draw a floor, shadow, pedestal, glow pool, or tile.
- Keep weapons, cloth, and effects at least 4 px from every canvas edge.
- Base enemies must remain readable at 95 × 95 and distinguishable in grayscale.
- Avoid isolated thin details that disappear after reduction.
- Rank and combat role must read through silhouette before glow or color.

## Accepted style reference

`godot/assets/characters/enemy-hollow-lancer-idle-v01.png` is the accepted Hollow-family reference for camera, missing-identity treatment, weathered materials, tonal range, southwest lighting, and enemy scale. New Hollows must share that family language without copying the Lancer's spear, helmet crest, long diagonal silhouette, or exact armor layout.

## Role specifications

### Hollow Lancer

- Narrow aggressive reach silhouette with a practical spear.
- Currently reserved for a future lancer-compatible gameplay unit.
- Do not map it to Void Cultist, Null Drake, or Storm Imp solely to consume the asset.

### Hollow Cantor

- Mid-range ritual caster whose posture implies a voice that has been erased.
- Medium vertical silhouette, narrower than Bulwark and less diagonal than Lancer.
- Layered ash-cloth mantle and weathered light iron around shoulders and forearms.
- Empty face plane framed by a split cowl.
- Compact broken chime, tuning fork, or civic resonance frame held near the sternum.
- One clearly readable free hand positioned as if conducting a restrained cadence.
- Violet-black seams concentrate around the throat, sternum, and focus.
- No spear, staff, giant book, microphone, musical notes, open screaming mouth, or large aura.

### Hollow Bulwark

- Broad defensive mass with damaged shield architecture.
- Reads through width and weight.

### Hollow Stray

- Mobile irregular silhouette with scavenged light equipment.
- Reads through asymmetry and forward motion.

### Elites

Lancer and Cantor elites add silhouette mass, one broken pale-gold halo fragment, and one additional readable armor feature. Elite status must remain readable in grayscale before any glow.

## Hollow Cantor idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield enemy idle sprite

Primary request: Create one original Hollow Cantor as an individual transparent asset. Match the accepted Hollow Lancer reference in camera, adult scale, missing-identity language, weathered material treatment, tonal range, southwest lighting, and painterly pixel-adjacent edges, while replacing the Lancer's diagonal reach with a compact ritual-caster silhouette.

Subject: adult people-shaped remnant; split ash-cloth cowl framing a smooth empty face plane; layered ash mantle; worn light iron shoulders and forearms; rubbed civic insignia; compact broken chime, tuning fork, or resonance frame held near the sternum; one clearly readable free hand conducting a restrained cadence; deliberate gaps in cloth and armor; violet-black seams around throat and chest; small muted rust-red enemy accent.

Composition: fixed three-quarter isometric tactical view from approximately 30 degrees above; facing down-left; restrained idle stance; entire figure visible; both feet on one bottom-center baseline; equipment fully inside frame.

Output: one enemy only; genuinely transparent background; intended for normalization to 128 × 128 and display at 95 px.

Avoid: spear, polearm, staff, giant book, microphone, musical-note symbols, open screaming mouth, skull, zombie anatomy, gore, horns, wings, glossy demonic armor, neon aura, floor, cast shadow, pedestal, scenery, text, border, UI, contact sheet, multiple poses, cropped cloth, watermark.

## File names

`enemy-hollow-{role}-{idle|attack}-v01.png` and `enemy-hollow-{role}-elite-{idle|attack}-v01.png`.

## Acceptance and rejection gates

Accept only when:

- Cantor reads as a caster or conductor in grayscale at 95 px.
- Camera, scale, foot anchor, and family materials match the Lancer.
- Empty face, chest focus, free hand, and both feet remain separable.
- Silhouette does not read as a spear user, knight, zombie, or generic robed mage.
- Alpha background is genuinely transparent.

Reject when:

- The output includes a floor, shadow, glow pool, scenery, or opaque background.
- Role depends on floating notes, particles, or violet glow.
- Face becomes a skull, mouth, or gore cavity.
- Equipment touches the canvas boundary.
- Robes collapse into one illegible black column.

## Runtime mapping decision

- `mira` maps to `character-arcanist`.
- `void_cultist` maps to `enemy-hollow-cantor`.
- `enemy-hollow-lancer` remains reserved until a compatible gameplay unit is introduced.
- Do not force Hollow roles onto Null Drake or Storm Imp without a separate gameplay and narrative review.

## Review checklist

- Base and elite rank readable in grayscale
- Family resemblance without cloned silhouettes
- Feet, scale, camera, and light match the hero contract
- Readable against grass, road, and stone at normal browser zoom
- No collision with HP bar, team indicator, or tactical overlay
