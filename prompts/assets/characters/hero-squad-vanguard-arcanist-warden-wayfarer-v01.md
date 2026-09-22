# Hero Squad: Vanguard, Arcanist, Warden, Wayfarer v01

- Asset IDs: `character-vanguard`, `character-arcanist`, `character-warden`, `character-wayfarer`
- Intended use: battlefield idle and action silhouettes, future portraits
- Generation tool: transparent-capable image generator with character-reference support
- Generation date: 2026-09-22 for the idle pilot
- Status: runtime-tested prompt contract

## Production objective

Create original tactical sprites that remain readable in the Godot Web battle, not standalone character illustrations. The final runtime canvas is 128 × 128 transparent PNG, while Godot displays player units at approximately 80 px maximum dimension over a 96 × 48 isometric tile.

Generate one role and one pose per output. Contact sheets, pose grids, turnarounds, captions, and environment plates are automatic rejections.

## Shared world and rendering contract

- Civilization: survivors recovering fragments of erased identity.
- Materials: weathered medieval-fantasy iron, practical cloth, worn leather, restrained pale-gold repair seams.
- Palette: charcoal and parchment base with one role accent.
- Rendering: painterly pixel-adjacent finish, crisp outer contour, simplified internal detail, no photoreal pores or noisy micro-texture.
- Light: soft southwest key light from upper left, cool ambient shadow, no rim-light halo.
- Proportions: grounded adult, approximately seven heads tall, neither chibi nor superheroic.
- Camera: fixed three-quarter isometric battlefield view, camera elevated approximately 30 degrees.
- Player facing: body and attention face down-right toward the battlefield center.

## Exact runtime output contract

- Output one genuinely transparent PNG with one character only.
- Normalize to an exact 128 × 128 canvas.
- Keep every visible pixel within x 8 to 120 and y 4 to 124.
- Place both feet on the same baseline at y 120 to 124.
- Center the midpoint between the feet at x 64, tolerance 6 px.
- Preserve transparent space beneath the feet. Do not draw a floor, shadow, pedestal, glow pool, or tile.
- Keep weapons, cloth, hair, and effects at least 4 px from every canvas edge.
- The complete silhouette must remain identifiable when reduced to 80 × 80.
- Avoid isolated one-pixel features, fine facial dependence, or low-contrast edges.
- Use shape, stance, and equipment before accent color to communicate role.

## Accepted style reference

`godot/assets/characters/character-vanguard-idle-v01.png` is the accepted player reference for camera, material weathering, tonal range, edge treatment, and adult scale. New heroes must look as though they belong to the same squad without copying the Vanguard's face, armor arrangement, cloak shape, or triangular silhouette.

## Role specifications

### Vanguard

- Forward-driving duelist.
- Asymmetric half-plate, scarred short cloak, practical sword.
- Broad triangular stance.
- Restrained cool-blue player accent.

### Arcanist

- Deliberate memory scholar and battlefield caster.
- Narrow vertical silhouette that contrasts with the Vanguard.
- Layered knee-length robe-coat over light practical armor.
- Compact palm-sized focus device held close to the torso, shaped like a repaired memory lens or folding astrolabe.
- One hand controls the focus while the other remains readable and relaxed.
- Controlled violet accent limited to the focus, one cloth panel, and small seam details.
- No long staff, giant book, wide cape, floating orbitals, or large spell effect.
- Expression is observant and self-possessed, not theatrical.

### Warden

- Protective field anchor and practical guardian.
- Widest stable hero silhouette, but still contained within one battlefield tile.
- Worn medium tower shield with a clipped or rounded top, held beside the torso rather than covering it.
- Short practical mace or reinforced baton kept close to the body.
- Layered heavy cloth beneath weathered iron plates, with visible knee and shoulder articulation.
- Moss and iron-blue accent limited to shield cloth, binding, and one shoulder detail.
- Calm braced stance with bent knees and clearly separated feet.
- No oversized fantasy shield, full body wall, giant hammer, cape wings, or glowing barrier.

### Wayfarer

- Mobile scout, ranged controller, and survivor for the current `lyra` gameplay ID.
- Lean open silhouette with travel wraps, light shoulder protection, and a short weathered cloak panel that cannot merge with the legs.
- Compact recurved bow held low across the body, with a small hip quiver and one clearly readable free hand.
- Forward-ready weight and separated feet communicate movement without using a running pose.
- Faded rust and muted teal accents limited to bow wrapping, scarf, and one cloth panel.
- Reads as an experienced pathfinder through equipment economy and alert posture, not exposed skin or exaggerated fantasy styling.
- No longbow taller than the character, dual blades, hood covering the face, floor shadow, drawn arrow, or active attack effect.

## Arcanist idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield idle sprite

Primary request: Create the original Arcanist from The Appointed hero squad as one individual transparent asset. Match the accepted Vanguard reference in camera, adult scale, material weathering, tonal range, southwest lighting, and painterly pixel-adjacent edge treatment, while preserving a distinct narrow vertical silhouette.

Subject: deliberate adult memory scholar; layered charcoal and parchment knee-length robe-coat over light weathered armor; compact repaired memory-lens or folding-astrolabe focus held near the torso; one hand controlling it and one hand clearly visible; observant human face; restrained violet accent on the focus and one cloth panel; small pale-gold repair seams.

Composition: fixed three-quarter isometric battlefield view from approximately 30 degrees above; facing down-right; restrained ready idle stance; entire figure visible; both feet on one bottom-center baseline; all cloth and equipment inside the frame.

Output: one character only; genuinely transparent background; intended for normalization to 128 × 128 and display at 80 px.

Avoid: floor, cast shadow, pedestal, scenery, aura cloud, spell burst, floating runes, staff, giant book, wide cape, text, border, UI, contact sheet, multiple poses, cropped clothing, celebrity likeness, anime exaggeration, chibi proportions, glossy armor, watermark.

## Warden idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield idle sprite

Primary request: Create the original Warden from The Appointed hero squad as one individual transparent asset. Match the accepted Vanguard and Arcanist references in camera, adult scale, weathered material rendering, tonal range, southwest lighting, and painterly pixel-adjacent edge treatment. Make the Warden the broadest and most stable hero silhouette without copying the Vanguard's triangular duelist stance.

Subject: grounded adult protective field anchor; worn medium tower shield with clipped or rounded top held beside the torso so the head, chest, and shield rim remain separately readable; short practical mace or reinforced baton kept close to the body; layered charcoal heavy cloth under weathered iron plates; articulated knees and shoulders; restrained moss and iron-blue accents; small pale-gold repair seams; calm vigilant human face.

Composition: fixed three-quarter isometric battlefield view from approximately 30 degrees above; body and attention facing down-right; low braced ready stance with bent knees; both feet visible and separated on one bottom-center baseline; shield creates width but does not hide the full torso; all equipment inside the frame.

Output: one character only; genuinely transparent background; intended for normalization to 128 × 128 and display at 80 px over a 96 × 48 tile.

Avoid: full body wall, oversized shield, shield wider than the character is tall, giant hammer, long spear, cape wings, glowing barrier, magic dome, floor, cast shadow, pedestal, scenery, aura cloud, text, border, UI, contact sheet, multiple poses, cropped equipment, celebrity likeness, anime exaggeration, chibi proportions, glossy armor, watermark.

## Wayfarer idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield idle sprite

Primary request: Create the original Wayfarer from The Appointed hero squad as one individual transparent asset. Match the accepted Vanguard, Arcanist, and Warden references in camera, adult scale, material weathering, tonal range, southwest lighting, and painterly pixel-adjacent edge treatment. Preserve a lean open diagonal silhouette that remains distinct from the Vanguard's broad sword stance and the Arcanist's vertical robe silhouette.

Subject: alert adult pathfinder and ranged battlefield controller; practical travel wraps over light weathered armor; one short asymmetric cloak panel that does not merge with the legs; compact recurved bow held low across the body without a drawn arrow; small hip quiver; one clearly visible free hand; restrained faded-rust scarf and muted-teal bow wrapping; pale-gold repair seams; focused human face visible beneath swept-back hair or a shallow open hood.

Combat-role evidence: this art maps to gameplay ID `lyra`, a Scout with movement 4, jump 2, speed 9, physical ranged attacks, minimum range 2, Pin Shot slow, Long Shot, Quickstep, Rain of Arrows, Smoke Screen, and Shadow Step progression. Express mobility, range control, and terrain awareness through a compact bow, economical equipment, and an alert forward-ready stance. Do not depict an attack in progress.

Composition: fixed three-quarter isometric battlefield view from approximately 30 degrees above; body and attention facing down-right; relaxed but forward-ready idle stance; both feet visible and separated on one bottom-center baseline; bow and quiver fully inside frame; clear negative space between bow, torso, free hand, cloak, and legs.

Output: one character only; genuinely transparent background; intended for normalization to 128 × 128 and display at 80 px over a 96 × 48 tile.

Avoid: drawn arrow, attack pose, arrow volley, smoke cloud, teleport effect, longbow taller than the character, crossbow, dual blades, giant hooked weapon, face-obscuring hood, wide cape, floor, cast shadow, pedestal, scenery, aura, text, border, UI, contact sheet, multiple poses, cropped equipment, celebrity likeness, anime exaggeration, chibi proportions, glossy armor, watermark.

## File names

`character-{role}-{idle|action}-v01.png`.

## Acceptance and rejection gates

Accept only when:

- Role reads as Arcanist in grayscale at 80 px.
- Camera and foot anchor match the Vanguard.
- Head, hands, compact focus, and both feet remain separable.
- Violet remains an accent rather than the primary silhouette.
- Alpha background is genuinely transparent.
- Warden reads as a protector in grayscale at 80 px.
- Shield, head, torso, weapon hand, and both feet remain separately readable.
- Warden is broader than Arcanist without exceeding the accepted tile-scale silhouette.
- Wayfarer reads as a mobile ranged scout in color and grayscale at 80 px.
- Bow, head, free hand, short cloak panel, quiver, and both feet remain separately readable.
- Wayfarer remains leaner than Vanguard and Warden without collapsing into Arcanist's vertical silhouette.

Reject when:

- The output reads as a portrait, concept-art plate, or standing front-view illustration.
- A floor, shadow, glow pool, or opaque background is present.
- The pose depends on particles or color to read.
- Equipment touches the canvas boundary.
- Robes merge into one dark, illegible column.
- Warden's shield hides the head, both feet, or entire torso.
- Warden reads as a boss, siege object, or oversized paladin.
- Wayfarer reads as a melee rogue, static archer tower, hooded assassin, or active attack pose.
- Bow, cloak, or quiver touches the canvas edge or merges with both legs.

## Review checklist

- Shared squad world, distinct role silhouette
- Consistent camera, scale, baseline, and southwest light
- Human and specific face without celebrity resemblance
- Readable at 80 px on grass, road, and stone
- No collision with HP bar, team indicator, or tile overlays
