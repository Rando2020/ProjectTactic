# Hub and Currency System Design

This document defines the first Godot implementation pass for ProjectTactic's roguelite hub and persistent currency loop. The goal is not a card system yet. The near-term loop is: enter the hub, start a descent, clear randomized or semi-randomized stages, receive boons and currencies, defeat bosses, return to the hub, spend permanent resources, and choose harder modifiers for better rewards.

## Hub responsibilities

The hub is the safe base between runs. It should let the player:

- View persistent currencies.
- Spend currencies on permanent upgrades.
- Unlock job tiers and future job routes.
- Upgrade summon or Guardian-aligned boon pools.
- Unlock and select heat-style difficulty modifiers.
- Start a new descent.

The first implementation uses a menu-driven `HubScene.tscn` controlled by `HubManager.gd`. Later, this can become a navigable town or camp scene.

## Currency model

### Job Points

JP is earned through playing battles and remains the primary Final Fantasy Tactics-like job progression resource. JP should be used for job levels, ability unlocks, and job prerequisites. JP is character or unit progression, not the main roguelite meta-currency.

### Soul Shards

Soul Shards are the baseline meta-currency. They are awarded after stages and can buy broad upgrades such as HP, physical power, magic power, inventory slots, or other long-term improvements.

### Obsidian

Obsidian is rarer and should come from elite enemies, bosses, harder rooms, and heat modifiers. It is used for job unlocks, advanced tier progression, and rare hub upgrades.

### Glyphs

Glyphs are used to unlock or improve the boon pool. They can support Guardian resonance, rarity improvements, reroll unlocks, or future boon synergy systems.

### Boss Tokens

Boss Tokens gate meaningful long-term progression. They should unlock advanced jobs, ascended jobs, Guardian evolutions, and higher heat tiers. Repeated boss clears should matter, but higher heat clears should matter more.

### Guardian Sigils

Guardian Sigils are summon-specific currencies such as `phoenix-sigils` and `titan-sigils`. These are earned from Guardian-aligned rooms, Guardian boon choices, elite followers, or boss rewards. They upgrade summon-specific boon pools and make future runs feel more tailored.

### Run Aether

Run Aether is a temporary run-only currency. It is spent during a descent on healing, mid-run upgrades, rerolls, shops, or temporary advantages. If unspent at run end, it can convert into a small amount of Soul Shards.

## First hub vendors

### Body Training

Permanent stat upgrades. Initial options:

- Max HP: +15 HP to all player units.
- Physical Power: +2 physical power.
- Magic Power: +2 magic power.

### Job Reliquary

Long-term job unlock gates. Initial flags:

- `advanced-jobs-unlocked`
- `ascended-jobs-unlocked`

Future versions should connect these flags to actual job tree visibility and unlock requirements.

### Guardian Shrine

Summon-aligned progression. Initial flags:

- `guardian-phoenix-rank-1`
- `guardian-titan-rank-1`

Future versions should use these flags to add or upgrade boons in the reward pool.

### Heat Altar

Optional difficulty for better rewards. Initial heat unlocks:

- Heat I: stronger enemies, higher rewards.
- Heat II: more elite pressure, higher rewards.

## Boss progression

Bosses should appear at predictable run milestones, such as every third stage. Boss victories award Boss Tokens and higher-tier currency. Boss clear counts and heat clear levels should unlock higher job tiers and Guardian upgrades.

Recommended first boss rules:

- First clear: unlocks basic heat and the first advanced job gate.
- Second clear: unlocks more Guardian resonance options.
- Higher heat clear: increases Boss Token payout and accelerates ascended unlocks.

## Implementation files

- `godot/scenes/HubScene.tscn`
- `godot/scripts/ui/HubManager.gd`
- `godot/scripts/roguelite/Currency.gd`
- `godot/scripts/roguelite/MetaProgression.gd`
- `godot/scripts/roguelite/RunManager.gd`
- `godot/project.godot`

## Known placeholders

- Purchases currently store flags and upgrade tiers, but advanced job systems are not fully connected yet.
- Guardian upgrades currently store unlock flags, but do not yet alter boon pools.
- Stage rewards need to be connected to final battle result flow and future randomized stage generation.
- Enemy heat scaling and elite spawn scaling still need implementation.

## Next implementation steps

1. Add victory reward hooks so completed stages award meta-currencies through `MetaProgression`.
2. Show meta reward breakdowns on `ResultsScreen.gd`.
3. Apply permanent stat upgrades to player units at spawn time.
4. Add heat scaling to enemies and rewards.
5. Add randomized stage and enemy generation.
6. Connect job unlock flags to the job tree.
