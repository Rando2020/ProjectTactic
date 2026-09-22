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

- Broad defensive mass with damaged civic shield architecture.
- Combat-facing art role for the current `null_drake` tank gameplay ID.
- Low, heavy stance with high HP and Temper implied through width and layered protection.
- Large battered rectangular shield with a missing section that creates readable negative space.
- Short cleaver or broken civic blade held close to the body.
- Thick ash cloth and weathered iron, with the same empty face-plane family language as Lancer and Cantor.
- Reads through width, weight, and shield shape before color.
- No dragon head, tail, wings, claws, scales, horns, spear, or caster focus.

### Hollow Stray

- Mobile irregular skirmisher for the current `storm_imp` gameplay ID.
- Lean asymmetrical silhouette with scavenged light equipment and a forward-ready stance.
- Split ash-cloth mantle with one short trailing panel, leaving both legs clearly visible.
- Compact broken civic relay or forked conductor held close to one hand, with the other hand open and readable.
- Violet-black seams and restrained cold-blue conductor marks imply unstable Ether without an active lightning effect.
- Reads through asymmetry, speed, and magical skirmisher intent before color.
- No horns, tail, wings, hovering pose, claws, imp anatomy, spear, heavy shield, or active spell burst.

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

## Hollow Bulwark idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield enemy idle sprite

Primary request: Create one original Hollow Bulwark as an individual transparent asset. Match the accepted Hollow Lancer and Hollow Cantor references in camera, adult scale, empty-identity language, weathered material treatment, tonal range, southwest lighting, and painterly pixel-adjacent edges. Replace their narrow and medium silhouettes with a broad low defensive mass suitable for a slow high-HP melee tank.

Subject: adult people-shaped remnant; smooth empty face plane under a low damaged helm or split hood; broad shoulders; layered ash cloth under heavy worn iron; large battered rectangular civic shield held beside the torso, with one missing corner or deliberate cutout that creates readable negative space; short cleaver or broken civic blade held close to the body; repeated insignia rubbed smooth; restrained violet-black seams at shield fractures and armor gaps; small muted rust-red enemy accent.

Combat-role evidence: this art maps to gameplay ID `null_drake`, whose current role is explicitly tanky melee with role `tank`, high HP and Temper, movement 3, speed 5, physical attacks, and block-and-positioning teaching intent. Express those mechanics through mass, stance, and shield architecture only. Do not introduce draconic anatomy from the legacy name.

Composition: fixed three-quarter isometric tactical view from approximately 30 degrees above; body and attention facing down-left; low braced idle stance; both feet visible and separated on one bottom-center baseline; shield creates width but does not cover the face plane or both feet; all equipment inside frame.

Output: one enemy only; genuinely transparent background; intended for normalization to 128 × 128 and display at 95 px over a 96 × 48 tile.

Avoid: dragon head, reptile anatomy, tail, wings, claws, scales, horns, spear, polearm, staff, caster focus, giant weapon, full-body shield wall, glowing barrier, skull, zombie anatomy, gore, glossy demonic armor, neon aura, floor, cast shadow, pedestal, scenery, text, border, UI, contact sheet, multiple poses, cropped shield, watermark.

## Hollow Stray idle generation prompt

Use case: stylized-concept

Asset type: one production-ready tactical RPG battlefield enemy idle sprite

Primary request: Create one original Hollow Stray as an individual transparent asset. Match the accepted Hollow Lancer, Hollow Cantor, and Hollow Bulwark references in camera, adult scale, empty-identity language, weathered material treatment, tonal range, southwest lighting, and painterly pixel-adjacent edges. Replace their reach, ritual, and tank silhouettes with a lean asymmetrical magical skirmisher built for rapid flanking.

Subject: adult people-shaped remnant; smooth empty face plane under a broken shallow hood that does not obscure the head shape; light worn iron on one shoulder and opposite forearm; split ash-cloth mantle with one short trailing panel; both legs exposed and readable; compact broken civic relay or forked conductor held close to one hand; other hand open; rubbed insignia; violet-black seams concentrated along one arm and the conductor; restrained cold-blue marks on the conductor; small muted rust-red enemy accent.

Combat-role evidence: this art maps to gameplay ID `storm_imp`, whose role is explicitly fast flanker with movement 4, jump 2, speed 10, HP 75, Magic 42, Ether 80, Thunderstrike chain damage, and Void Pulse silence. Express speed, magical threat, and irregular arrival through lean asymmetry, light equipment, and a compact conductor only. Do not use the legacy imp anatomy, hovering pose, horns, tail, or active lightning.

Composition: fixed three-quarter isometric tactical view from approximately 30 degrees above; body and attention facing down-left; forward-ready but stationary idle stance; both feet visible and separated on one bottom-center baseline; one shoulder slightly advanced; clear negative space between conductor, open hand, mantle, torso, and legs; all equipment inside frame.

Output: one enemy only; genuinely transparent background; intended for normalization to 128 × 128 and display at 95 px over a 96 × 48 tile.

Avoid: horns, tail, wings, hovering, imp anatomy, claws, exposed monster skin, active lightning bolt, chain-lightning effect, void blast, spell cloud, spear, polearm, staff, shield, heavy armor, skull, zombie anatomy, gore, glossy demonic armor, neon aura, floor, cast shadow, pedestal, scenery, text, border, UI, contact sheet, multiple poses, cropped cloth, watermark.

## File names

`enemy-hollow-{role}-{idle|attack}-v01.png` and `enemy-hollow-{role}-elite-{idle|attack}-v01.png`.

## Acceptance and rejection gates

Accept only when:

- Cantor reads as a caster or conductor in grayscale at 95 px.
- Camera, scale, foot anchor, and family materials match the Lancer.
- Empty face, chest focus, free hand, and both feet remain separable.
- Silhouette does not read as a spear user, knight, zombie, or generic robed mage.
- Alpha background is genuinely transparent.
- Bulwark reads as a slow defensive melee tank in grayscale at 95 px.
- Shield, empty face plane, torso, weapon hand, and both feet remain separately readable.
- Bulwark is broader than Cantor without becoming a boss-scale silhouette.
- Hollow Stray reads as a fast magical skirmisher in color and grayscale at 95 px.
- Empty face plane, conductor, open hand, short mantle panel, torso, and both feet remain separately readable.
- Hollow Stray is leaner and more asymmetrical than Cantor without copying Lancer's spear diagonal.

Reject when:

- The output includes a floor, shadow, glow pool, scenery, or opaque background.
- Role depends on floating notes, particles, or violet glow.
- Face becomes a skull, mouth, or gore cavity.
- Equipment touches the canvas boundary.
- Robes collapse into one illegible black column.
- Bulwark reads as a dragon, lancer, caster, or oversized fortress.
- Shield hides the face plane, both feet, or the entire torso.
- Hollow Stray reads as a horned imp, hovering creature, spear user, armored knight, or active spell effect.
- Mantle or conductor merges with both legs or touches the canvas edge.

## Runtime mapping decision

- `mira` maps to `character-arcanist`.
- `void_cultist` maps to `enemy-hollow-cantor`.
- `null_drake` maps to `enemy-hollow-bulwark` based on its explicit tanky-melee role, high HP and Temper, low mobility, and block-and-positioning intent.
- `storm_imp` maps to `enemy-hollow-stray` based on its explicit fast-flanker role, movement 4, jump 2, speed 10, high Magic and Ether, chain lightning, and silence control.
- `enemy-hollow-lancer` remains reserved until a compatible gameplay unit is introduced.
- The legacy display name Null Drake remains a taxonomy mismatch to resolve separately.
- The legacy Storm Imp creature description remains a taxonomy mismatch to resolve separately; the Hollow Stray art intentionally excludes imp anatomy.

## Review checklist

- Base and elite rank readable in grayscale
- Family resemblance without cloned silhouettes
- Feet, scale, camera, and light match the hero contract
- Readable against grass, road, and stone at normal browser zoom
- No collision with HP bar, team indicator, or tactical overlay
