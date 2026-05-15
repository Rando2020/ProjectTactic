# Ruleset Contracts
Formal definitions. AI agents implement these exactly.

## Turn Economy
- CT per tick: `unit.ct += get_effective_speed()`; threshold = 100
- Haste: 1.25x speed. Slow: 0.75x. Stun: skip act, CT still accumulates
- Per turn: Move once + Act once, any order. Undo move before acting.

## Movement
- Square grid, cardinal. Move cost = terrain.move_cost + max(0, height_diff - jump)
- blocks_movement=true or cost > move = impassable. Units block tiles.

## Combat
- raw = physical * power_factor
- height: 1.15 downhill / 0.9 uphill / 1.0 flat
- flank: 1.3 back / 1.15 side / 1.0 front
- armor_absorbed = min(armor, damage * 0.35); hp_damage = max(1, damage - absorbed * 0.25)
- Temper=0: +15% physical. Ether=0: +15% magical.
- Counter: 25% chance melee, non-counter, non-ranged hits.

## Statuses
- Tick at end of affected unit's turn. Same status: refresh duration.
- bleed=12dmg/t, burning=15/t, poison=8/t (pure). regen=20hp/t.
- stun/petrify block all. immobilize blocks movement.

## JP Awards
action_used=6, weakness=+4, status=+4, armor_break=+6, reaction=+8, clear=+18, boss=+35

## JP Levels: 30/90/180/320/520/800 cumulative

## Victory
- defeat_all: all enemies dead | protect_unit: protected unit survives | reach_tile: player reaches it
- survive_turns: N turns with party alive | destroy_anchor: void anchor destroyed
