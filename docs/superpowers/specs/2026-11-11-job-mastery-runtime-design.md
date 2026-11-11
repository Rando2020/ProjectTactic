# Earned job mastery: first runtime slice

Continue the existing class work using the eight jobs in `JobTreeData`, not the older aspirational job rosters. Its mastery threshold is 800 historical JP per job. Mastered jobs remain earned after a class switch.

Implement the catalog's Squire move (+1) and counter-chance (+15 percentage points), Warder physical damage reduction (25%), and Luminary healing bonus (+30%). These become battle-local projections of saved job history, not new save fields. Do not grant mastery to fresh characters, enemies, or unknown job IDs. Repeated spawning cannot accumulate bonuses. Forecast, resolution, character-sheet Move and actual movement must agree. Healing multiplies the authored base amount, then adds the existing flat run bonus and caps to missing HP. Physical reduction applies before Temper absorption and stacks multiplicatively with existing Protect/Defend.

Use the existing Godot factory and shared combat formula in both campaign and courtyard. Keep probability rolls, action admission, costs, presentation and skill ownership intact. Do not change chance eligibility or add extra random draws.

Alternative: activate all descriptive mastery promises at once. Rejected for this slice because Cover extension, auto-SURGE, resonance echo and similar effects require their own contracts. Alternative: add new design-only jobs. Deferred because that does not fix existing class gameplay.

Explicitly pending: Warder Cover extension, Luminary holy auto-SURGE and all other catalog mastery effects. No claim that classes/passives/skills are complete. No new artwork in this slice.
