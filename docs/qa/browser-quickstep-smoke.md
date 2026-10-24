# Scout Quickstep browser-smoke extension

## Released evidence (2026-10-24)

The original local checkpoint below was subsequently integrated and released in
PR #75, main `f900b54a2417d6192e5111f9239e8a4a10dfd371`, tree
`ed32741c360c27f3d5eb2c1cb4f47367b1bc6bec`.
[Godot Validate 40095725695](https://github.com/Rando2020/ProjectTactic/actions/runs/40095725695)
on final PR head `1f00ccae4ba72605a1991949440ee41a951027be` passed 11 real
clicks plus stationary hover and 14 checkpoints, including rendered MP 65 and
original Lyra identity after the second move. The production menu-layout and
resource-refresh repairs are included; the harness checks two newer frames after
mouseMoved and presses the original coordinate, rather than following reflow.
No captured browser errors were reported. This is bounded CI input evidence,
not a full manual encounter or acceptance of the next starter-identity candidate.
See [delivery provenance](../production/delivery-ledger.md).

## Original frozen scope (historical)

Base: `115e2abecb80fc82375df69ef4400e0093fc9b23` (reviewed Scout integration).
Isolated checkout `projecttactic-scout-browser-qa`, branch
`qa/browser-quickstep-smoke`; prior QA and source checkouts remain untouched.
This is for the following Scout slice, not a change to the released checkpoint.

The existing seven browser clicks and their menu-Cancel, target-Cancel, first-Move,
resource, highlight, geometry, console/error and screenshot checks remain. Four
additional CDP mouse clicks perform Ability → Quickstep → Move → second legal tile.
There are no direct gameplay calls, game-state setters or signal shortcuts.

## Read-only observer schema v2

The inherited QA observer remains outside `res://` until temporary QA staging.
It adds actual rendered button label text, Attack control state/geometry, the
existing player-turn serial and a roster. Keys are stringified Godot instance IDs,
not display/archetype names; current-unit observations carry the same identity.
The original Lyra instance can therefore be followed after another actor becomes
active, including when names collide. The schema contains no action API/callbacks.

Quickstep is selected by the unique actual `Quickstep` menu label, not menu index.
After recovery, the harness requires the same turn and instance, unchanged
position/HP, exactly 5 MP spent, action spent, Move reopened, and Attack/Ability
disabled. Opening the second Move range must not spend additional resources.
After the second legal tile click, the finite wait requires a newer player turn
and the original instance at that destination with its post-Quickstep MP intact.
**HP is deliberately not compared after handoff:** later enemy/terrain damage is
not evidence of a Quickstep HP cost. Current-manager action flags belong to the
new active unit and are likewise not used for the original actor after handoff.

Additional configured screenshot checkpoints:
- `quickstep-menu-open.png`
- `quickstep-action-spent-move-reopened.png`
- `quickstep-second-movement-range.png`
- `quickstep-second-movement-ended-turn.png`

## Verification

- RED observer contract: 10 failures for missing schema/identity/roster/labels/
  Attack control; GREEN: zero failures. Includes descendant-label extraction and
  repeated observations preserving every roster unit.
- Python RED: missing Quickstep assertion/label helpers, then missing extension
  driver. GREEN: 40 tests across the full suite (26 browser/staging tests).
- The sequence unit test uses a scripted transport to inspect the actual CDP
  requests: four mouseMoved/Pressed/Released triplets and the observed rectangle/
  tile coordinates. It is a harness unit test, **not browser gameplay evidence**.
- Mutation cases reject duplicate/missing Quickstep labels, wrong cost/action/
  movement gates, early handoff, wrong/missing original instance, wrong destination
  or later extra MP cost. Simulated later HP damage and a colliding archetype ID
  do not create false attribution.
- Native aggregate: formula209, execution56, spell-outcome184, CT130, progression73,
  Cancel/move17, Silence58, Scout122, Scout-outcome115, Kael113, Mira115, Zane116,
  shared-rig2622, recovered15, readability2465, playable427; terrain10 cycles.
  All pass, no runtime script errors. Existing shutdown ObjectDB/resource
  diagnostics remain visible in spell-outcome (2), Cancel/move (1), Scout-outcome
  (1), and playable-loop (3) fixtures; this test-only change does not suppress them.
- Production GDScript66 loaded; static stability passes with 19 existing warnings.
- Production → QA → cleaned production Web exports pass. Production PCKs are
  byte-identical: 16,833,148 bytes, SHA-256
  `144f7fac90d4c36bddd50eb7b64f174e1a43af971ea9bfa418b6f36e5b5aad89`.
  Neither includes QA bridge paths/symbol; QA PCK includes the observer. Project
  bytes restore exactly, staging is absent, and production sources are unchanged.
  Final Web packaging validates WASM/PCK bytes, subpath loading and native passthrough.

Evidence logs: `build/qa-local/` in the isolated checkout. Only SHA-256-verified
local baseline bytes hydrated the 218 LFS assets; no new download/dependency.

## Original acceptance boundary (historical; later CI evidence above)

The prior Cancel/first-Move browser trial passed according to the parent handoff.
**This Quickstep extension has not executed in a browser or produced new gameplay
screenshots.** No local browser/GUI retry, browser installation, source publication,
workflow dispatch, merge, deployment, story/save change or other-checkout mutation
occurred. Independent review and a later separately authorized CI trial are still
required. Native/unit/export results are not exported-input or visual acceptance.
