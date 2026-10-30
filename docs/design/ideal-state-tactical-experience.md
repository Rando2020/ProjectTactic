# ProjectTactic: Ideal-State Tactical Experience

Status: **proposed design target**, not implementation or deployed claim  
Date: 2026-10-25  
Runtime owner: `godot/` (Godot Web). React under `src/` is reference, not the production authority.

## Product promise

Every turn gives the player an understandable, consequential tactical choice; every committed action produces a satisfying, truthful response; every completed encounter changes the next decision. Prioritize one finished-feeling encounter over multiplying unreviewed content or effects.

### Non-negotiable product pillars

1. **Readability before spectacle:** clearly distinguish available actions, legal destinations, terrain elevations, hazards, threats, target protections and resulting HP/Temper/Ether.
2. **Tactical depth from interactions:** positioning, facing, height, turn order, armor pressure, status, elemental ground effects and job synergies produce emergent alternatives to raw damage.
3. **Fast agency:** players can inspect, cancel and compare targets without resource costs; animation never makes the game feel unresponsive.
4. **Narrative cohesion:** Recurrence themes inform objectives, costs and aftermath; never reduce love/grief or identity to superficial buff terminology.
5. **Evidence before production acceptance:** native Godot tests and browser input tests are distinct from human visual/audio/balance approval.

## Reality boundary and sources

Current README identifies the Godot 4.6.3 release via PR #75 and `f900b54a`; deployed identity must be rechecked against public `build-info.json` at acceptance. The runtime already has shared formula/resolver forecasts, CT turn prediction, facing/height math, Temper/Ether armor, skills, enemy intents, battle choreography, limited accessible UI sizing, a route/boon/run flow and browser-local encounter checkpoints. Review:
- `README.md`
- `docs/systems/playable-tactics-loop.md`
- `docs/systems/combat-math-contract.md`
- `docs/qa/combat-choreography-2026-10-23.md`
- `docs/production/delivery-ledger.md`
- `docs/JOB_SYSTEM_SPEC.md`

Do **not** silently treat old React source or aspirational job/ability documents as deployed behavior. 3D characters remain opt-in candidate presentation, not a proven replacement for default sprites. The Zane Fire ability is currently the existing three-tile fan with 12 MP cost, not a standalone fireball.

## I. Ideal battle screen

### Desktop 16:9 information hierarchy

- **Top strip, approximately 8-10% of height:** battlefield name and objective at left, *single authoritative* next-actors CT timeline centered, settings/pause at right. Preview forecasted CT changes only when backed by the current turn-order rules.
- **Center stage, approximately 70-78% of width:** board, characters, directional facings, terrain layers, movement paths, attack/fan/area footprints and enemy intent overlays. Battlefield must remain the focal area at 1366x768, 1600x900 and 4K.
- **Context rail, approximately 22-30% of width:** selected unit, status, physical/magical armor, Move/Attack/Ability/Item/Wait commands, hover forecast and target inspection. No permanently overlapping second timeline or duplicate floating loadout.
- **Bottom micro-caption, only when useful:** short consequence callout, e.g. `Back attack +30% • Breaks 12 Temper • Fire reaches 2 targets`. Distinguish guaranteed from chance-based outcomes.
- **Camera:** stable isometric camera, smooth cursor-linked pan and two simple zoom presets. Avoid exaggerated battle-camera motion that hides targeting alignment.
- **Never obscure:** occupied tiles, target destination, future danger tiles, actor silhouettes, HP bars or objective tiles.
- **Density controls:** Compact / Standard / Large UI separate from rendering quality; maintain legible text at 4K and browser zoom 150%; reduced motion and color-independent overlays.

### Focus/state behavior

```text
Battle Ready
 ├── Inspect → back to Battle Ready (free)
 ├── Move → Preview Path → Commit Move → Battle Ready (move spent)
 ├── Attack/Ability → Legal Targets → Consequence Forecast → Commit
 │                                                      └→ Resolving
 │                                                        └→ Battle Ready (action spent)
 ├── Wait → Facing / End Turn → CT Advances
 └── Pause / Settings → resume same battle state
Enemy Ready → Telegraph/Act → Resolve → CT Advances → Next Ready Actor
Objective Complete → Results → Reward Choice → Route Choice → Next Encounter
```

An action may precede movement or vice versa when each remains available. Cancel from target/forecast spends nothing. Current Quickstep behavior is a documented exception: 5 MP and an action to reopen ordinary movement, **not** a free second action. During choreography, commands are locked only for the authoritative action-resolution window.

### Interaction contract

| Player intent | Visual feedback | System guarantee |
| --- | --- | --- |
| Hover/select ally | Unit focus, legal move tiles, clear move/action availability | No hidden commit |
| Hover destination | Connected path, elevation and opportunity/hazard warnings if supported | Pathfinding source determines validity |
| Hover enemy | Target card, range/facing/height context, expected damage and armor losses | Same CombatFormula/ForecastCalculator path as resolver |
| Preview spell | Exact current AoE footprint, elements and terrain reactions where determinable | Probabilities clearly marked; never promise an unknown future state |
| Preview CT | Current next actors and rules-consistent tentative changed ordering | Recompute for haste/slow, don't pretend future unknown actions are fixed |
| Commit action | Immediate accepted input cue, anticipation → travel/contact → hit feedback → recovery | One resource debit, one resolved outcome, no delayed duplicate hits |
| Inspect enemy intent | Identified target/area, ability and certainty legend | Must match documented AI decision snapshot; recalc when state changes |
| End turn | Facing confirmation if needed, CT strip advances | No accidental extra action |

Use icon shapes, text and patterns in addition to color; keyboard/controller/touch semantics should converge on the same intent methods, not separate combat implementations.

## II. Ideal tactical combat system

### Core decision calculus

A good turn asks the player to balance **position, initiative, armor break, environment and next-turn safety**:
1. Can I move to a flank/high tile without ending inside an incoming danger area?
2. Should I strip Temper/Ether, deal HP damage, apply status or reposition an enemy?
3. Can this action create an environmental advantage for a second unit?
4. Does the action shift future CT sequencing or expose my party?
5. Is the result worth the MP, action and board control sacrificed?

Keep underlying shared math authoritative. From `combat-math-contract.md`, higher physical positions improve damage by +10% per height step (up to 30%); rear attacks use x1.30 damage; the engine's preview must show actual formula outcomes rather than invent a variance band. Distinguish projected damage from HP actually removed due to caps or immunity.

### Armor identity

- **Temper:** physical defense layer; shield-breaking, suppression and physical control opportunities.
- **Ether:** magical defense layer; spell-focused pressure and resistance to thematic corruption/status pressure.
- **HP:** actual survival. Display distinct bars/segments and labeled breakdown in forecast.
- Elemental resistances and status eligibility remain independent. An immune damage result must not imply universal status immunity.

### Telegraph-driven AI (readable, not omniscient)

- Bruiser: pressure vulnerable targets and lane control.
- Cantor/caster: threaten clusters and elemental combinations.
- Guardian: objective pressure and map alteration.
- UI distinguishes `Committed intent` (current snapshot, if locked by AI) from `Likely threat` (prediction only). If intent can change in response to player movement, never label it guaranteed.
- A single quick toggle reveals threat areas; hovering an enemy expands intent details without removing selected hero context.

### Meaningful environmental reactions

Use interactions already represented in the codebase before adding new types. Proposed test interactions: water + ice creates hazardous traversal, fire + combustible ground changes cover/safety, a caster's AoE forces displacement and height/edge pressure. Any new reaction must specify:
- Trigger and tile preconditions
- Target set and elevation rules
- Turn duration, expiration, visual state and interaction order
- Damage/armor/status resolution ownership
- Forecast wording for certain versus conditional consequences
- AI awareness rules
- Test cases and original assets

Resist new terrain rules that aren't visible at default zoom.

### Battle feel / animation contract

`Read → Commit → Anticipate → Travel → Contact → React → Settle`

- Read: highlighted shape plus forecast visible before commit.
- Commit: instant input acknowledgment, appropriate voice/SFX only if available.
- Anticipate: 0.10-0.25 s target animation budget; custom character silhouettes matter more than particles.
- Travel: weapon or projectile follows actual path and elevation.
- Contact: restrained impact pause, directional recoil, element-appropriate flash and distinct HP/armor feedback.
- React: terrain/status updates and target outcome animate once, after canonical resolver results.
- Settle: camera returns to same legible board framing quickly; reduced-motion path preserves informational feedback.

Animation timings are **starting tuning targets**, not claims about current runtime or guaranteed frame timings. Never create a second damage/resolution implementation in VFX scripts. Current sprites remain fallback until any shared-rig candidate passes gameplay-scale silhouette, animation and browser performance review.

## III. Worked example: one tactically rich 3-turn encounter

**Ashvale anchor skirmish**, as a *new proposed test fixture*, not deployed content:
- Allies: Kael (physical Warder), Zane (existing Fire fan), Mira (caster/support); one fourth ally can be present for the canonical formation.
- Foes: a Hollow Lancer positioned to guard an anchor, a Hollow Cantor in back, and a protecting melee enemy.
- Terrain: elevated ruined step, narrow choke, one authored fire-reactive area, two safe routes.
- Objective: **disable the anchor before its charge completes** or defeat all foes, depending on acceptance test mode.
- Pressure: the Lancer threatens a lane; the Cantor signals its probable casting area.

Turn 1: Kael considers an adjacent safe attack or a flank from elevation. The forecast shows the current hit and armor/HP breakdown plus flank/elevation modifiers. An enemy threat overlay helps evaluate safe ending tiles.

Turn 2: Zane considers whether his existing three-tile Fire fan catches the Lancer and adjacent material. Target overlay distinguishes hit targets from changed terrain; resource cost stays 12 MP. Do not silently substitute the aspirational Fireball skill.

Turn 3: Mira must choose whether to finish the softened target, counter the Cantor's area threat or support the anchor objective. Two viable plans should emerge, with observable consequences and no universally dominant move.

A successful design test is when players can describe **two sensible choices and their tradeoff**, not merely identify which button deals the most damage.

## IV. Ideal job/progression system

Jobs are about tactical *verbs*, not just higher stats:

| Job | Unique verb | Example choice |
| --- | --- | --- |
| Warder | Hold / intercept | Protect a route or expose self to flank |
| Arcanist | Prime / detonate | Spend MP to set up an environmental combination |
| Chronist | Accelerate / delay | Change which ally/enemy acts next |
| Skywarden | Traverse / isolate | Take altitude to disrupt backline safety |
| Luminary | Restore / cleanse | Heal now or protect against upcoming status |
| Resonant | Bind / disrupt | Prioritize map objective over direct damage |

Ascended jobs should combine established verbs instead of invalidate base jobs. Every unlock preview shows job prerequisites, missing conditions, JP price, learnable skills, **a sample tactical use**, and what changes on the battlefield. Only label an ability `available` when runtime behavior exists; others are `planned`.

## V. Ideal roguelite results, rewards and narrative

**Results UX:** finish with concise outcome animation, meaningful contribution highlights (armor broken, danger avoided, healing actually applied, objective completed), JP/gold gain and one high-stakes next choice. Do not reward meaningless action spam.

**Reward choice:** 3 contrasting options, each with a concrete synergy preview for current jobs/party, a cost and a tradeoff. Proposed categories: weapon trait, a temporary run boon, or a route/narrative opportunity. Avoid unearned power escalation across runs.

**Recurrence integration:** anchor/Guardian decisions can represent *Choice and Regret*, *Love and Grief*, etc., but the narrative must preserve moral ambiguity. A choice may save an ally now while changing the later world state. Present effects truthfully, leave emotional consequences for narrative, and do not make every theme a simple damage multiplier.

## VI. Accessible, responsive presentation

- Desktop first. Explicit target validation: 1366x768, 1600x900, 1920x1080, 3840x2160 with Standard and High presentation.
- 4K font/UI scaling independent of resolution; avoid shrinking legibility through aggressive camera zoom.
- At reduced motion, suppress flash intensity, zoom kicks and screenshake but keep attack consequence text, silhouettes and audio optional.
- Full keyboard control with short visible key hints; controller navigation maintains the same logical selection; touch may be a later acceptance lane.
- Telegraphs and team colors must also differ by text, glyph and pattern. Tooltips cannot be the only source of essential information.

## VII. Roadmap: prioritize finish over breadth

### Slice A: Trustworthy tactical choices (first)

One coherent encounter with a single top CT strip, open battlefield, contextual action rail, accessible selection, consistent hit/armor/HP forecasts, correct telegraphs and clear move/action lifecycle. Preserve existing mechanics and saves. Ship to an isolated preview only after native and browser input tests.

### Slice B: Impact identity

One Kael melee and one Zane Fire sequence with silhouette-consistent assets, distinct restrained contact feedback, camera discipline, and reduced-motion route. Keep sprites as fallback; only introduce shared-rig rendering if browser A/B evidence justifies it.

### Slice C: Tactical consequence and reward

Add **one** testable authored terrain combo and anchor objective, then one post-battle reward choice with an observable effect on the very next encounter. Keep the canonical run/retry/checkpoint contract intact.

### Slice D: Expand after player validation

Implement polished job unlock/ability discovery and narrative choices before multiplying jobs, maps, enemy families or cinematic effects.

## VIII. Acceptance gates for first vertical slice

**Functional**
- Selection, path preview, target cancel and action-before-move remain consistent.
- Forecast and resolved outcomes share one formula path, including height, facing, resistances and Temper/Ether.
- Enemy intent legends do not misrepresent future decisions as commitments.
- CT strip reflects actual turn order, including current haste/slow and legal Quickstep tradeoff.
- No VFX-driven duplicate HP loss, resource cost or effect.
- Victory, reward, next battle and refresh/Continue retain their current documented checkpoint behavior.

**Visual**
- No persistent HUD panel covers target/hero at 1366x768, 1600x900 or 4K.
- Actual targets remain legible when damage forecast, telegraphs and AoE previews coexist.
- A new player can distinguish ally/enemy, range, facing, height, safe/unsafe tile, HP/Temper/Ether and selected action without reading a manual.
- Character effects support silhouettes rather than obscure them.
- Reduced-motion and larger UI remain usable.

**Evidence**
- Unit/native Godot tests, Web export and GitHub Actions pass with no new regression.
- Real browser pointer hover, click, keyboard cancel and complete attack animation are recorded separately from native tests.
- Human tester completes the encounter, selects a reward and starts the next encounter, describing at least two deliberate tactical tradeoffs.
- Record screenshots/video from *the same build* used for acceptance, plus build ref and settings.

## Integration boundaries and follow-up tickets

**Canonical runtime directories:** `godot/scripts/battle/`, `godot/scripts/ui/`, `godot/scripts/presentation/`, `godot/data/`, with authored original assets under `godot/assets/`. Keep production Godot as the authority; only reference React for ideas. Keep gameplay, camera, VFX and UI separated.

Suggested reviewable PR order:
1. `feature/tactical-hud-focus`: one CT strip, objective, contextual forecast and overlay hierarchy.
2. `feature/encounter-impact-pass`: targeted Kael/Zane action feedback, reduced-motion review and sound mix.
3. `feature/anchor-encounter-choice`: one authored environment/objective fixture, existing rule integration, enemy intent and reward follow-through.

**Risks:** unreadable 4K scaling, partial UI overlap, changing ability rules during a presentation pass, mismatched forecasts, unresolved resource diagnostics, art identity drift, and 3D WebGL/browser performance. Mitigate with independent functional and visual gates, known fallback sprites, and no change to live/public deployment without explicit approval.
