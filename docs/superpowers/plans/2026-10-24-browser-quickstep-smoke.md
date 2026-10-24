# Browser Quickstep smoke implementation plan

**Goal:** Extend the existing Cancel/first-move browser checks with real Quickstep
and a second legal move, without changing production gameplay or observer inclusion.
**Spec/design:** Parent-approved read-only schema v2, 24 October 2026. The inherited
QA-only observer adds rendered labels, Attack control geometry/state, existing
player-turn serial, and a roster keyed by stringified Godot instance identity.
Current active-unit snapshots also carry that identity. No action APIs or game
setters; roster IDs do not rely on potentially colliding unit/display names.
**Baseline:** `115e2abecb80fc82375df69ef4400e0093fc9b23`.
**Checkout:** `projecttactic-scout-browser-qa`, branch `qa/browser-quickstep-smoke`.
**Tech:** Existing Python/CDP/websocket client and Godot 4.6.3. No new dependencies.

## Design choices and constraints
- Preserve all prior seven browser clicks, console/error collection, geometry waits,
  screenshots, cleanup and production-pack guards.
- Select Quickstep by actual UI label text, rather than menu index or a game call.
- After its recovery, require the same actor instance/turn/position/HP, exactly
  5 MP spent, action spent, movement reopened, and Attack/Ability disabled.
- Click real Move and one observed legal tile. Wait finitely for a newer player
  turn and the original instance's final roster position/MP. Never compare HP
  after handoff: subsequent terrain/enemy damage is not a Quickstep cost.
- Alternatives rejected: current-active-unit-only snapshots lose Lyra at handoff;
  display/unit-name roster keys can collide; signal-driving tests bypass browser
  input; duplicating native recovery/duplicate tests exceeds this bounded smoke.
- No production/source/story/save mutations in other checkouts; no browser/GUI
  retry, installation, publication, merge or deployment. Future CI requires review.

## Implementation steps
- [x] Add RED Python invariants/identity/label tests and headless observer schema
  assertions; record exact failures before implementation.
- [x] Add only the approved schema-v2 read-only observer fields and update contract.
- [x] Extend harness with bounded Quickstep and second-move stages, screenshot
  checkpoints and coverage declaration; use only CDP mouse events.
- [x] Run all Python tests, relevant native aggregate/observer checks and Web
  exports. Compare clean production packs before/after QA staging byte-for-byte.
- [x] Freeze local commit/tree for independent review; browser extension remains
  unexecuted until later authorized CI.

## Evidence
- Existing prior QA branch preserved. New checkout hydrated 218 assets only after
  verifying SHA-256 against the frozen source's LFS pointers; initial import passed.

- Observer RED10 → GREEN0; Python missing-helper/driver RED → GREEN40 full-suite tests, including four CDP input triplets, instance-key preservation/name collision and post-handoff HP non-attribution.
- Full native aggregate passed, including Scout122 and Scout-outcome115. Script66/static stability passed; preexisting shutdown resource diagnostics retained and documented.
- Production pack before/after staging: 16,833,148 bytes, identical SHA-256 144f7fac90d4c36bddd50eb7b64f174e1a43af971ea9bfa418b6f36e5b5aad89, bridge excluded from production/present in QA; project restored and stage absent.
- Browser extension remains unexecuted; no publication/merge/deploy. Parent owns independent review and future CI authorization.
