# Vows and Sigils

Vows are the run's divine alignment. They lean the reward pool toward one Guardian and one element, so choosing Ignareth makes fire and burn-adjacent rewards more common without guaranteeing them.

Sigils are the run's practical fighting style. They are less elemental and lean the pool toward physical, magical, support, range, flank, or momentum rewards.

The intended player choice is:

- Pick one Vow before the run: elemental god, identity, and broad reward bias.
- Pick one Sigil before the run: job/style bias that can pair with any Vow.
- Clear floors to grant Vow/Sigil XP. Higher levels strengthen weighting rather than hard-locking builds.

Current implementation:

- `VowSigilSystem.gd` owns the Vow/Sigil data, weighting, XP thresholds, and loadout bonus output.
- `RunState.gd` stores equipped Vow/Sigil ids, levels, and XP, and saves/loads them.
- `BoonSystem.gd` accepts an optional loadout bonus and uses it to weighted-pick boon offers.
- `StageSelect.gd` has a simple start-run picker.
- `BattleScene.gd` grants loadout XP after completed battle nodes.

Design direction:

- Vows should feel mythic and elemental.
- Sigils should feel tactical and job-related.
- The combination should create build gravity, not a fixed build path.

First style boon wave:

- Vanguard: Bulwark, Counterstance.
- Arcanist: Reservoir, Overflow.
- Duelist: Footwork, Execution.
- Ranger: Sightline, Broadhead.
- Cantor: Litany, Grace.
- Marauder: Shove, Cleave.

These reuse existing battle hooks where possible, so they already affect combat/run bonuses: movement, max Temper, Surge, reaction echo, piercing lines, knockback, cleave, execute damage, sustain, and once-per-battle survival.

Limited boon lanes:

- Movement is the first limited lane.
- A run can hold 2 movement boons at once.
- Taking a third movement boon opens a replacement prompt instead of stacking automatically.
- This keeps movement choices sharp: extra Move, move-before-attack damage, and kill-move effects compete for space.

Run build summary UI:

- Stage Select now shows the active Vow, Sigil, levels, and XP toward the next level.
- The same panel shows active limited-lane pressure, starting with Movement `current/limit`.
- A full lane is highlighted, so replacement pressure is visible before the next boon choice.
