# Job Stats Reference Table

This document provides the exact stat values and growth curves for all jobs, derived from the Job Identity Pass. Use this as the implementation guide for `UnitStats.gd` resources.

## Base Jobs

### WARDER

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1 | 28 | 6 | 4 | 2 | 7 | 50 | 20 | 0 | -15 | 100 | 40 | 1 |
| 3 | 32 | 6 | 4 | 2 | 7 | 53 | 21 | 0 | -15 | 103 | 42 | 1 |
| 5 | 36 | 7 | 4 | 2 | 7 | 56 | 21 | 0 | -15 | 107 | 44 | 1 |
| 7 | 40 | 7 | 4 | 2 | 7 | 59 | 22 | 0 | -15 | 111 | 46 | 1 |
| 11 | 48 | 8 | 4 | 2 | 7 | 65 | 23 | 0 | -15 | 118 | 50 | 1 |

**Stats per Level**:
- HP: +2
- MP: +0.3
- Physical: +1.2
- Magic: +0.2
- Max Temper: +1.5
- All others: no scaling

---

### ARCANIST

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1 | 14 | 80 | 3 | 2 | 6 | 15 | 60 | -10 | 15 | 20 | 80 | 3 |
| 3 | 15 | 85 | 3 | 2 | 6 | 16 | 63 | -10 | 15 | 20 | 83 | 3 |
| 5 | 16 | 90 | 3 | 2 | 6 | 18 | 66 | -10 | 15 | 20 | 86 | 3 |
| 7 | 18 | 95 | 3 | 2 | 6 | 20 | 69 | -10 | 15 | 20 | 89 | 3 |
| 11 | 21 | 105 | 3 | 2 | 6 | 24 | 75 | -10 | 15 | 20 | 95 | 3 |

**Stats per Level**:
- HP: +0.5
- MP: +2
- Physical: +1.5
- Magic: +1.5
- Ether: +1.5
- All others: no scaling

---

### RESONANT

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1 | 22 | 70 | 4 | 2 | 7 | 25 | 50 | 0 | 0 | 60 | 100 | 2 |
| 3 | 24 | 73 | 4 | 2 | 7 | 27 | 52 | 0 | 0 | 63 | 104 | 2 |
| 5 | 26 | 76 | 4 | 2 | 7 | 29 | 54 | 0 | 0 | 67 | 108 | 2 |
| 7 | 28 | 79 | 4 | 2 | 7 | 31 | 56 | 0 | 0 | 70 | 112 | 2 |
| 11 | 32 | 85 | 4 | 2 | 7 | 35 | 60 | 0 | 0 | 77 | 120 | 2 |

**Stats per Level**:
- HP: +1
- MP: +1.5
- Physical: +1
- Magic: +1
- Max Temper: +1
- Max Ether: +2
- All others: no scaling

---

### LUMINARY

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1 | 20 | 80 | 4 | 2 | 8 | 20 | 55 | -10 | 10 | 40 | 90 | 3 |
| 3 | 22 | 85 | 4 | 2 | 8 | 21 | 58 | -10 | 10 | 41 | 93 | 3 |
| 5 | 24 | 90 | 4 | 2 | 8 | 23 | 61 | -10 | 10 | 42 | 96 | 3 |
| 7 | 26 | 95 | 4 | 2 | 8 | 24 | 64 | -10 | 10 | 43 | 99 | 3 |
| 11 | 30 | 105 | 4 | 2 | 9 | 27 | 70 | -10 | 10 | 45 | 105 | 3 |

**Stats per Level**:
- HP: +0.8
- MP: +2
- Physical: +1
- Magic: +1.3
- Max Temper: +0.2
- Max Ether: +1.5
- Speed: +0.1
- All others: no scaling

---

## Advanced Job

### SKYWARDEN (Warder advancement, Lv. 3+)

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1* | 30 | 8 | 5 | 4 | 8 | 52 | 22 | -5 | -15 | 70 | 50 | 1 |
| 5 | 36 | 9 | 5 | 4 | 8 | 58 | 23 | -5 | -15 | 78 | 54 | 1 |
| 7 | 40 | 9 | 5 | 4 | 8 | 62 | 24 | -5 | -15 | 82 | 56 | 1 |
| 11 | 48 | 10 | 5 | 4 | 9 | 70 | 25 | -5 | -15 | 90 | 60 | 1 |

*Skywarden starts at player's Warder level when unlocked at Lv. 3

**Stats per Level**:
- HP: +1.5
- MP: +0.3
- Jump: +0.4
- Speed: +0.1
- Physical: +1.2
- Magic: +0.2
- Max Temper: +1
- Ether: +0.5
- All others: no scaling

---

## Ascended Jobs

### NULL BREAKER (Warder advancement, Lv. 5+)

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1* | 35 | 8 | 4 | 3 | 7 | 58 | 22 | 10 | -15 | 120 | 60 | 1 |
| 5 | 40 | 9 | 4 | 3 | 7 | 66 | 23 | 10 | -15 | 135 | 64 | 1 |
| 7 | 44 | 9 | 4 | 3 | 7 | 72 | 24 | 10 | -15 | 145 | 66 | 1 |
| 11 | 52 | 10 | 4 | 3 | 7 | 84 | 26 | 10 | -15 | 160 | 70 | 1 |

*NULL BREAKER starts at player's Warder level when unlocked at Lv. 5

**Stats per Level**:
- HP: +2.5
- MP: +0.3
- Physical: +1.5
- Magic: +0.2
- Max Temper: +2.5
- Ether: +1.2
- All others: no scaling

---

### ETHERWEAVER (Arcanist advancement, Lv. 5+)

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1* | 14 | 100 | 3 | 2 | 6 | 15 | 75 | -10 | 25 | 20 | 120 | 3 |
| 5 | 16 | 112 | 3 | 2 | 6 | 18 | 81 | -10 | 25 | 20 | 130 | 3 |
| 7 | 18 | 120 | 3 | 2 | 6 | 20 | 86 | -10 | 25 | 20 | 138 | 3 |
| 11 | 21 | 135 | 3 | 2 | 6 | 24 | 97 | -10 | 25 | 20 | 150 | 3 |

*ETHERWEAVER starts at player's Arcanist level when unlocked at Lv. 5

**Stats per Level**:
- HP: +0.5
- MP: +3
- Physical: +1.5
- Magic: +2
- Max Ether: +2.5
- All others: no scaling

---

### PRIMAL BINDER (Resonant advancement, Lv. 6+)

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1* | 26 | 75 | 4 | 3 | 7 | 28 | 65 | 0 | 0 | 60 | 130 | 2 |
| 5 | 29 | 82 | 4 | 3 | 7 | 31 | 70 | 0 | 0 | 65 | 140 | 2 |
| 7 | 32 | 88 | 4 | 3 | 7 | 34 | 75 | 0 | 0 | 68 | 148 | 2 |
| 11 | 38 | 100 | 4 | 3 | 7 | 40 | 85 | 0 | 0 | 75 | 160 | 2 |

*PRIMAL BINDER starts at player's Resonant level when unlocked at Lv. 6

**Stats per Level**:
- HP: +1.5
- MP: +1.5
- Physical: +1
- Magic: +1.5
- Max Temper: +1
- Max Ether: +3
- All others: no scaling

---

### SERAPH (Luminary advancement, Lv. 5+)

| Level | HP | MP | Move | Jump | Speed | Physical | Magic | Phys Res | Mag Res | Temper | Ether | Atk Range |
|-------|----|----|------|------|-------|----------|-------|----------|---------|--------|-------|-----------|
| 1* | 24 | 100 | 4 | 2 | 9 | 22 | 70 | -5 | 20 | 50 | 110 | 3 |
| 5 | 27 | 112 | 4 | 2 | 9 | 24 | 76 | -5 | 20 | 52 | 118 | 3 |
| 7 | 30 | 120 | 4 | 2 | 9 | 26 | 81 | -5 | 20 | 53 | 126 | 3 |
| 11 | 36 | 135 | 4 | 2 | 10 | 30 | 92 | -5 | 20 | 55 | 138 | 3 |

*SERAPH starts at player's Luminary level when unlocked at Lv. 5

**Stats per Level**:
- HP: +1
- MP: +2.5
- Physical: +1
- Magic: +1.5
- Max Temper: +0.3
- Max Ether: +2
- Speed: +0.2
- All others: no scaling

---

## Stat Summary by Category

### Highest HP at Each Tier
- **Base**: Warder (28 base → 48 at Lv.11)
- **Advanced**: Skywarden (30 base → 48 at Lv.11)
- **Ascended**: NULL BREAKER (35 base → 52 at Lv.11) ⭐ Tankiest

### Highest MP at Each Tier
- **Base**: Luminary / Arcanist / Resonant (70-80 base → 105+ at Lv.11)
- **Advanced**: Skywarden (8 base, minimal casting)
- **Ascended**: Etherweaver (100 base → 135 at Lv.11) ⭐ Most casts

### Highest Ether at Each Tier
- **Base**: Luminary (90 base → 105 at Lv.11)
- **Advanced**: Skywarden (50 base → 60 at Lv.11)
- **Ascended**: Primal Binder (130 base → 160 at Lv.11) ⭐ Most summons

### Highest Magic at Each Tier
- **Base**: Arcanist (60 base → 75 at Lv.11)
- **Advanced**: Skywarden (22 base, low magic)
- **Ascended**: Etherweaver (75 base → 97 at Lv.11) ⭐ Strongest spells

### Highest Physical at Each Tier
- **Base**: Warder (50 base → 65 at Lv.11)
- **Advanced**: Skywarden (52 base → 70 at Lv.11)
- **Ascended**: NULL BREAKER (58 base → 84 at Lv.11) ⭐ Strongest attacks

---

## Notes for Implementation

1. **Fractional Growth**: Store growth values with decimals (Python/GDScript can handle `HP: +2.0` naturally)

2. **Rounding**: When displaying stats to players, round up (so 20.8 → 21), but keep decimals in backend

3. **Resource Pools**: Always round MP, Temper, Ether to integers for UX

4. **Resistances**: Never exceed +50 (resistance hard cap) or -50 (vulnerability hard cap)

5. **Attack Range**: Standard is 1 (melee). Ranged jobs are 2-3. No job should exceed 4.

6. **Movement**: Standard is 4. Advanced/Ascended may have +1. Never exceed 5.

7. **Jump**: Standard is 2. Jobs emphasizing jump (Skywarden) reach 4. Never exceed 5.

8. **Speed**: Standard is 6-7. Speed tiers matter more for pacing than raw stat value.

---

## Version History

- **v1.0** (Job Identity Pass Release): Initial stat tables derived from identity framework
