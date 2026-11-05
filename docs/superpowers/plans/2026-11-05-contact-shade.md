# Courtyard contact shade implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan, then request independent review.

**Goal:** Ground ten existing props with subtle receiver-aware shade.
**Architecture:** Existing decoration data supplies compact world-space contacts to the cached terrain shader. Matching-height ordinary tops receive a bounded soft mask; every other output remains unchanged.
**Tech Stack:** Godot 4.6.3 GDScript and spatial shader, existing painted PNGs.
**Spec:** ../specs/2026-11-05-contact-shade-design.md

## Global Constraints
- Separate isolated branch based on #107; no existing PR changes or deployment.
- Ten contacts only: six cypresses, three columns/piers, one pot grouping.
- No new or edited image assets, geometry, map, grid, placements, gameplay, or UI.
- At most 18% darkening, maximum rather than cumulative overlap.
- Ground height comes from the actual terrain root transform.

## Review Focus
- No shade on vertical faces, stairs, mismatched support height, or outside footprint.
- Zero contacts preserve #107 exactly.
- Reconfigure/rebuild neither duplicates nor loses contacts; cached viewport refreshes.
- Edge props must not cast into void or onto wrong-height surfaces.
- Paired scene images must improve grounding without obvious discs or reduced highlight readability.

## Task 1: Receiver-aware contact shading

Files: modify BloomingTerrain.gd and BloomingSurface.gdshader under demos/isometric-2v2/prototypes/blooming; add tests/blooming_contact/{ContractTest,RenderedTest,Capture}.{gd,tscn} and README; extend existing isometric CI after local verification.

Interface: terrain `contact_points` stores at most16 Vector4(x,z,world_height,radius) values; `_sync_contacts()` sends count/points to cached materials and refreshes UPDATE_ONCE. Shader `contact_count`, `contact_points[16]`, `contact_strength=.18`; count zero is identical to base. Capture's `--without-contacts` changes test-instance uniforms only.

- [x] Add renderer tests: matching-height top must darken; zero, distant, wrong-height, side, and stair outputs identical; duplicate mask must not darken further. Add real-terrain contract for count10, supported heights, radius bounds, no mutation/duplicates.
- [x] Run baseline regression and record intended failures without parser/shader errors. Run baseline geometry431 and existing ground contract8.
- [x] Implement small profiles and uniform synchronization; soft radial max mask after existing color. Exclude stairs and sides. No other production changes.
- [x] Run renderer and contracts to green, then existing ground13 and supported headless suites. Capture paired overview/highlights; inspect close supported-prop regions and report any drawback.
- [ ] Extend CI for the new contract/render/capture artifacts. Independent read-only review; fix blocking regressions before publishing separate draft. Verify tree identity, CI and downloaded artifact if published.
