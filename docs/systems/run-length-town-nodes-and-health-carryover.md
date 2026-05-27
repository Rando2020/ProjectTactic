# Run Length, Town Nodes, and Health Carryover

This note captures the current roguelite run-structure direction so it can be integrated after the core battle loop is stable.

## Design Stance

Do not jump straight from 10 floors to 50 floors. A tactics battle asks for more attention than a quick card encounter, so a 50-floor run risks becoming exhausting before the systems are deep enough to support it.

Recommended first target:

- 3 acts
- 7 to 8 floors per act
- 20 to 25 floors total
- act breaks that escalate terrain, enemy types, elite rules, and boss pressure

Only consider 50-floor runs after 25-floor runs feel rich, varied, and meaningfully different from each other.

## Why Runs May Feel Short

If 10 floors feels too quick, the cause is probably one of these:

- Build ramp is too fast: the player reaches their power ceiling before the boss.
- Decisions are too shallow: route nodes do not create enough meaningful tradeoffs.
- Health and resources reset too freely: each battle feels isolated instead of part of one expedition.
- Bosses do not test the specific build the player made.

Longer run length helps only after those are addressed.

## Health Carryover

Health should carry from floor to floor. This is a high-priority change because it makes run routing, healing nodes, defensive builds, and sustain jobs matter.

Initial rule:

- Unit HP persists after battle.
- Dead or defeated units remain unavailable or wounded until revived by a town node, item, boon, or special event.
- After a normal battle, each surviving unit recovers only a small amount automatically, such as 10% to 20% max HP.
- MP, ether, and other casting resources should probably reset at first so the first balance pass focuses on HP pressure only.

Design result:

- Sanctums and infirmaries become real decisions.
- Clerics, guardians, lifesteal, shields, regen, and defensive vows gain strategic value.
- Taking damage on a battle you still win matters.

## Core Town Nodes

Town nodes should not be simple breaks. Each one should ask the player to trade recovery, information, power, party flexibility, or long-term safety.

### Sanctum

Heals the party and allows one boon upgrade.

Good choices:

- Heal all units for a fixed percent.
- Revive one defeated unit.
- Upgrade one boon rarity or level.

Why it works:

- Creates tension between survival and build scaling.

### Armory

Spend gold to improve one unit's run stats.

Good choices:

- Upgrade weapon damage.
- Upgrade armor or resistance.
- Add a small job-linked bonus.

Why it works:

- Forces the question of who gets invested in.

### Tavern

Recruit, swap, or temporarily hire party members.

Good choices:

- Swap one active unit for a new recruit.
- Hire a mercenary for 1 to 3 floors.
- Pick 3 of 4 party members before the next act.

Why it works:

- Adds mid-run composition pivots and makes runs feel different.

### Vault

Bank one reward into meta-progression.

Good choices:

- Preserve one boon, sigil XP chunk, currency bundle, or rare material even on death.
- Sacrifice current-run power for permanent progress.

Why it works:

- Makes losses feel less punishing.

### Oracle

Reveal information and reshape routing.

Good choices:

- Reveal the next 3 floors.
- Reveal the next boss gimmick.
- Let the player reroute one branch.

Why it works:

- Makes information itself feel like a reward.

## Expanded Town Node Backlog

### Recovery Towns

- Infirmary: heal HP, cleanse injuries, revive a unit, no boon upgrades.
- Bathhouse: modest full-party recovery plus temporary morale.
- Shrine of Mercy: full heal, but enemies gain a modifier on the next floor.

### Power Investment Towns

- Training Yard: spend gold or JP for a temporary stat boost.
- Academy: upgrade or sidegrade one learned job ability.
- Relic Smith: upgrade, reroll, or fuse sigils.
- Enchanter: add an elemental tag to a weapon or ability for the run.

### Party and Build Pivot Towns

- Guildhall: hire a temporary specialist.
- Pilgrim Camp: change active vow at a cost to vow XP.
- Mirror Hall: respec one unit's job or ability loadout.
- Barracks: change deployment size for the next battle.

### Information Towns

- Scout Post: reveal enemy types, terrain hazards, or elite affixes.
- Cartographer: add a shortcut or hidden node to the map.
- Archivist: identify unknown boons, relics, or boss rules before choosing.

### Risk Reward Towns

- Black Market: rare items and sigils at cursed prices.
- Gambler's Den: wager gold, HP, or a boon for a random reward.
- Witch Hut: gain a strong boon paired with a curse.
- Arena: optional hard fight for premium rewards.
- Debt Broker: take gold now, pay through harder future floors or reduced rewards.

### Meta and Safety Towns

- Memorial: preserve some XP or job progress from a fallen unit.
- Waystone: create a one-time checkpoint or retry anchor.
- Courier Post: send currency or materials home, weakening the current run but improving account progress.

## Suggested Implementation Order

1. Add HP carryover between floors.
2. Add a basic town-node screen/framework.
3. Implement Sanctum and Armory.
4. Make gold spending matter.
5. Add Tavern once party composition choices are ready.
6. Add Oracle or Scout Post to make route choice smarter.
7. Extend run length to 20 to 25 floors with 3 act breaks.
8. Add Vault after meta-progression rewards are mature enough to preserve.

## Open Balance Questions

- How much HP should surviving units recover automatically after battle?
- Should defeated units be unavailable, revived at 1 HP, or enter an injury state?
- How often should town nodes appear per act?
- Should town nodes compete with boon/combat nodes, or appear at fixed act checkpoints?
- Should party size be fixed per run, per act, or adjustable through towns?
