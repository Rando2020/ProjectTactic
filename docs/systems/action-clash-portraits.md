# Action clash portraits: accepted-action overlay (candidate)

Status: **feature branch only**; not merged or deployed. Runtime: Godot 4.6.3.

## Player experience

After a basic melee/ranged hit or a cast action is accepted, a compact dark/gold portrait strip displays:
- The attacking/casting unit, with its portrait or the canonical sprite fallback.
- The defender's portrait, name and red-accent frame for single-target actions.
- The actual ability display name and a short context label (MELEE, RANGED, SPELL; basic strikes may identify the target-facing flank).
- AoE spells cast at a tile deliberately label the target **AREA** rather than falsely presenting one of several possible defenders.

This is a **light accent**, not a blocking cutscene: about 0.7 seconds for ordinary actions, fading independently of the authoritative attack animation. Boss-targeted actions get a slightly longer display. No camera zoom or audio is introduced in this first pass. A session's existing reduced-Zane-motion setting suppresses the fade animation (the card still appears and disappears). Global reduced-motion preference is a later settings task.

## Source and architecture

- `godot/scripts/battle/BattleManager.gd`: emits `action_clash_started(context)` *after* `ActionLifecycle.begin` accepts an action and before `VFXManager.present_action`. No change to turn order, MP/HP math, ability admission, counterattack rules, saves or the resolver. The event is a read-only snapshot.
- `godot/scripts/battle/BattleUI.gd`: subscribes to the new signal, creates a presentation child and relays the snapshot. The existing hover forecasts and portraits are untouched.
- `godot/scripts/ui/ActionClashOverlay.gd`: draws a mouse-transparent CanvasLayer child containing framed portraits and names. It keeps clear of the persistent right rail at desktop sizes and uses `UISettings` for responsive sizing. Retriggering an action replaces the previous accent without stacking timers.
- `godot/tests/test_action_clash_overlay.gd`: asserts display/fallback, AoE label, reentrancy, reduced-motion entry, and safe-area boundaries at 1280x720, 1366x768, 1600x900 and 4K.
- `tools/check_playable_loop.py`: runs the new focused test alongside existing contracts.

The overlay prefers `UnitData.portrait`, then `UnitData.sprite_sheet`, then the `AssetRegistry` character candidates for the unit ID, then a readable initial. Portraits are never silently generated from other characters. A portrait asset can be added later without changing the signaling contract.

## Acceptance path

1. Hydrate existing LFS assets, import under Godot 4.6.3, and run:
   `godot --headless --path godot --script res://tests/test_action_clash_overlay.gd`
2. Run `python tools/check_playable_loop.py` and the Web export/Actions checks, inspect errors and shutdown diagnostics.
3. In actual browser gameplay, validate **Kael melee → Hollow Lancer**, **Zane Fire fan → AREA**, a ranged hit, enemy attack, an AoE with multiple targets and a boss attack. Verify portrait identity is consistent with unit art and does not interfere with hover/keyboard cancel.
4. Capture 1366x768, 1600x900 and 4K gameplay images, including Standard/Large text at 150% browser zoom. Review contrast, timing, battlefield overlap and reduced motion.
5. Compare active on-screen combat with and without accents in a short human playtest. If portraits obscure the hit, switch to a narrower lower-corner layout or show the banner only for named/signature abilities.

## Known limitations / risk

- Portrait identity assets may not be authored/imported for every actor. Some classes will show the battlefield sprite or initials until approved portrait resources are attached to UnitData or the manifest.
- Area/multi-target spells show AREA, not a rotating gallery of recipients. Future work could add a count badge from the existing target set if correctness is guaranteed by the resolver.
- Counterattacks currently use their direct resolver path instead of `_present_action`; this pass intentionally does not add a second cinematic for counters.
- The card is intentionally click-through and does not delay gameplay. Very short actions may finish while the strip is still fading; judge that by browser footage before adding synchronized timing.
- Current preferences expose a session-only reduced Zane impact motion setting, not a global reduced-clash toggle. Extend `UISettings` only after a full settings acceptance pass.
- Automated tests do not prove visual fidelity, responsiveness under GPU load, art consistency or perceived combat quality. Keep the normal battle UI and sprite fallbacks.

## Next recommended slice

Once the first pass is browser-approved, create **one** original character portrait pack for Kael, Zane and a Hollow Lancer, with verified visual identity, neutral/attack/hurt expressions, and exact resource mapping. Then pilot a boss/signature diagonal split on a separate PR, keeping standard attacks on the compact strip.
