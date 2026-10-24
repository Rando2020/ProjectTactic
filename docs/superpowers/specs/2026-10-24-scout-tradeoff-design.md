# Scout movement/action tradeoff

## Intent and scope
Make the existing exposed Scout kit truthful: escape costs the damage opportunity, and Long Shot's declared dead zone applies to both teams. Base: `21f43db37ca4ad0fb9aa8cdfdca2fbf184906ef1`. Work only on isolated `scout-tradeoff-2026-10-24`; no publication, merge, deploy, GUI, story, CT, saves, progression, weapon/loot system, other skill implementation or support-AI expansion.

## Source facts
Quickstep is a physical self buff, range 0, 5 MP, in Scout's ability list and Lyra's loadout. Its entire promise is “Move again immediately. Can't act after.” Its current magnitude-2 status has no effect consumer; it promises no speed buff. Long Shot declares power 60, 0 MP and range 3–5 using `attack_range_min/max`, while player highlighting currently ignores the minimum alias. Self casts immediately resolve on selection. The manager owns the player movement/action gates; Unit also exposes `has_moved/has_acted`. Existing presentation admits a primary action before awaiting contact and prevents normal repeated input.

## Approaches
Use a dedicated action-economy dispatch in the existing manager, not a timed status or new movement-point resource. A status introduces expiry/consumption complexity without any promised ongoing benefit; a new resource changes the game's economy. Normalize existing range aliases at the AbilityDB boundary rather than special-casing Long Shot's numbers in player/AI logic.

## Contract
- Quickstep is offered/accepted only for the active living player with the ability equipped, sufficient MP, movement already used and action unused. Reject before spending on early, acted, repeated or insufficient-MP use.
- Revalidate at contact. Spend exactly 5 MP once, consume the action, reopen one ordinary movement. Reset movement flags, not stats; no status/speed buff, free attack, new resource or AI support behavior.
- Immediate self selection remains. The button and forecast explicitly show 5 MP, one movement and action cost. Post-action movement preview says movement ends the turn. Wait forfeits the remaining move; normal turn end and next-turn reset remain unchanged.
- Long Shot keeps existing power/cost/access. Canonical `min_range` and `range` preserve its 3–5 geometry for highlighting, preview, player input, AI selection/intent legality and contact legality. Area secondary targets remain outside primary-target range enforcement.
- Test actual Battle.tscn/UI signal paths headlessly, including double clicks, cancellation, insufficient MP at contact, target movement at contact, normal next-turn reset and forecast/execution agreement.

## Verification
Observe failing regression tests first; then targeted tests, existing complete gameplay contract runner, static GDScript checks, headless parse, narrative and HUD/presentation contracts. Record pre-existing warnings separately. No claims of GUI/browser or live balance testing.
