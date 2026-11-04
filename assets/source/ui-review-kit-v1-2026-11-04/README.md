# ProjectTactic UI interaction review kit

**Status: isolated, source-ready UI prototype; not connected to gameplay.**

This kit fills four catalog slots with editable Godot controls rather than flattened artwork: confirmation, enemy inspection, final facing and context hints. It extends the existing Blooming charcoal/gold language with distinct keyboard focus, 48 px minimum action controls and explicit text states.

## Included
- `review-theme.tres`: native Godot theme, five button states, panel styling and readable text colors.
- `components/*.tscn`: four reusable static components. All buttons deliberately have no gameplay bindings.
- `review.tscn`: native Godot specimen combining all four components, at 1280×900.
- `icons/*.svg`: original 32 px confirm, cancel, inspect, facing and warning icons. Labels remain live text.
- `review.html`: responsive interactive design specimen. Its local state changes are examples, not gameplay.
- `state-contract.json`: UI states, hints and invariants for the eventual combat-controller adapter.

Open `project.godot` in Godot 4.6.3 and run, or open `review.html` in a browser. The HTML specimen demonstrates confirmation messages, enemy-inspection return state and facing selection. Native scene buttons are intentionally unbound.

## Integration contract
1. Controller owns the active actor and pending selection. UI never directly mutates combat state.
2. Move/target click creates a preview; only Confirm emits intent. Controller revalidates resources, ownership and targets at confirmation time.
3. Enemy inspector reads the inspected unit separately from the active actor. Closing returns to the previous selection and pending preview.
4. Wait opens facing selection, and only confirmed facing ends the turn. Cancel has no cost. Camera-relative direction mapping is required.
5. Hints are derived from current state every transition. Invalid actions have a reason, not only disabled color.
6. During resolution disable duplicate confirmation. Confirmation failure must preserve usable recovery controls and display the new reason.
7. Keep current right-side tester panel separate and collapsible; this specimen is not a replacement for diagnostics.

## Accessibility and layout
- 48 logical px minimum controls; 18 px base text; no text baked into icons.
- Focus is a 3 px mint outline, distinct from gold hover; the HTML facing example includes selected text and a border, not color alone.
- HTML warnings use an icon, text and edge stripe. HP/MP are labeled numerically.
- No flashing or required motion. HTML uses semantic buttons, labels and polite status announcements.
- HTML stacks at widths under 760 px. Native scene is currently a desktop specimen only; mobile/controller/screen-reader certification is not claimed.
- Use the engine's default font until distribution rights for any custom font are established.

## Verification and limitations
- Four Python contract tests pass.
- Godot 4.6.3 imports and launches the native scene headlessly.
- Native checks pass: 11 buttons, minimum 48 px height, keyboard focus, distinct focus/hover styles, no gameplay bindings, all action button bottom edges at or above the 900 px viewport boundary (not a full bounds or overflow test).
- Text/background contrast is measured in `review/contrast.json`.
- A browser screenshot attempt was blocked by the execution environment's socket restriction, including after an approved elevated retry. No browser-rendered screenshot or click-through acceptance is claimed.
- Native headless layout checks do not establish visual acceptance. Check actual rendering, focus order, text scaling and camera overlays before integration.
- Fixture names, stats, coordinates and warnings are examples, not current game data.

## Source basis and provenance
Native implementation follows existing project AppointedTheme.gd and [Blooming theme at 8d5284e](https://github.com/Rando2020/ProjectTactic/blob/8d5284e239f7573715bd507de21bf45f5896bc20/godot/assets/environments/blooming-ruins-v2/bloom-theme.tres). Requirements are from the [merged production catalog](https://github.com/Rando2020/ProjectTactic/tree/3b1958e28e60b4f15593f242e8127a67e46a19b3/assets/source/production-catalog-2026-11-04). New SVGs, scene layouts and specimen code are original project work. No external art or font is bundled. This source-only kit does not modify gameplay files or the live deployment. Publication into the source catalog is not gameplay integration or visual acceptance.

## Source import boundary
The kit is an independent Godot project. Its `res://` paths assume this folder is the project root; remap resources before copying components into the game project. The HTML demonstrates sample transitions, not full state-machine enforcement: it does not gate confirmations by state or lock repeated confirmation. `state-contract.json` describes the proposed controller contract, not implemented gameplay.
