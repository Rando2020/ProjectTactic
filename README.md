# Vaelthar: Eidolon Chronicles

A browser RPG built in React. Final Fantasy Tactics × Chrono Trigger × Birth by Sleep.

## Play It

```bash
npm install
npm run dev
```

Open http://localhost:5173

## Build for Deployment

```bash
npm run build
```

Output goes to `/dist` — deploy anywhere static (Netlify, Vercel, GitHub Pages).

---

## Game Systems

### ⚡ SURGE / DEFLECT Timing
- **SURGE**: When you cast a spell or attack, a glowing button flashes at the bottom of the screen. Click it during the window to deal **+45% bonus damage** on that hit.
- **DEFLECT**: When an enemy announces an attack, a shield button appears for 500ms. Click it to halve their damage.
- Each element has a **unique timing rhythm** — Thunder fires 4 rapid bursts, Ice fires one slow massive hit, Fire fires 3 medium hits, Wind fires 3 fast slashes, etc.

### 🟧 TEMPER / 🟪 ETHER (Character Armor)
Two separate armor values appear directly in the character section beside HP/MP:
- **Temper** (orange) = physical defense. Protects against Bleed, Knockdown, Slow, Weaken, Berserk.
- **Ether** (purple) = magical defense. Protects against Burn, Freeze, Stun, Silence, Curse, Blind.
- Armor reduces status chance by up to 85% when full. At zero armor, full base chance applies.
- Hits strip armor automatically. **+15% damage bonus** when hitting a target with 0 armor.
- Character sheets now track: `temper`, `maxTemper`, `ether`, `maxEther`, current job, job levels, unlocked jobs, mastered jobs, and ascended jobs.

### 🧬 Character Level System
Character level uses XP and improves global stats, armor caps, and job eligibility. Job level is separate.

| Character Level | XP Required |
|---:|---:|
| 1 | 0 |
| 2 | 100 |
| 3 | 240 |
| 4 | 420 |
| 5 | 650 |
| 10 | 2550 |
| 15 | 5700 |
| 20 | 10100 |
| 25 | 16150 |
| 30 | 24540 |

### ⚜ Job Level System
Each character tracks JP per job. Job levels unlock related jobs and ascended classes.

| Job Level | JP Required | Title |
|---:|---:|---|
| 0 | 0 | Untrained |
| 1 | 30 | Initiate |
| 2 | 90 | Apprentice |
| 3 | 180 | Adept |
| 4 | 320 | Specialist |
| 5 | 520 | Veteran |
| 6 | 800 | Master |
| 7 | 1200 | Transcendent |
| 8 | 1700 | Mythic |

### 🔥 Elemental Surface Reactions
Apply surface states (Wet, Burning, Frozen, Cursed, Blessed) and then hit with a compatible element:
- 💧 + ❄ = **FREEZE** (hard to resist, Ether barely helps)
- 💧 + ⚡ = **ELECTRIFY** (same)
- 🧊 + ⚡ = **SHATTER** (×1.75 damage + shatter armor)
- 🔥 + 💧 = **Extinguish** (remove burn, apply wet)
- 💜 + ✨ = **Holy Purge** (×1.6 damage + party heal)
- ✨ + 🌑 = **Null Corrupt** (×1.6 damage + drain Ether)

### ⚡ 2-Way + 3-Way Elemental Combos
Chain different elements within 7 seconds to trigger massive combo attacks. 19 two-way combos, 10 three-way combos.

### 📖 32 Guardians (8 elements × 4 tiers)
- **Primal Guardian** (T1): Ignareth, Glacielle, Torvahk, Nerevan, Gorveth, Sylvara, Luminarch, Vaelthorn
- **Aspect** (T2), **Echo** (T3), **Shard** (T4) for each element
- Unlocked via Resonant JP level progression (Lv1 through Lv7)
- **Bahamut equivalent (Vaelthorn) requires 920 JP** — endgame grind target
- Summons use the elemental timing system too — calling Torvahk fires 4 rapid thunder strikes

### 💜 Resonance Window
When a corrupted Guardian drops to ≤20% HP, their Void Anchor is exposed. ATB pauses. Use Zane's **RESONATE** action (30 MP, 82% success for Resonant jobs) to shatter it. Success: Guardian freed, party healed, +50% JP bonus. Fail twice: Guardian goes BERSERK.

### 🔱 Limit Break
Each character has a gold gauge that fills when they take damage. At 100%, they can unleash a class-specific Limit Break:
- **Warder**: 3 hits all enemies, each strips 45 Temper
- **Arcanist**: Fire+Ice+Thunder simultaneously → forces TRI-NOVA combo
- **Resonant**: Grand Resonance — calls strongest available Guardian free
- **Luminary**: Full HP, max Ether, purge all, party Blessed
- ... unique per all 18 jobs

### ⚜ 18 Job Classes (9 Base + 9 Ascended)
Base classes: Warder, Arcanist, Resonant, Luminary, Skywarden, Chronist, Oathbound, Voidcaller, Null Resonant

Each base job maps to an **Ascended** version through character level + related job levels:

| Base Job | Ascended Job | Unlock Requirement |
|---|---|---|
| Warder | Null Breaker | Character Lv. 12, Warder Lv. 5, Skywarden Lv. 2, Oathbound Lv. 2 |
| Arcanist | Etherweaver | Character Lv. 12, Arcanist Lv. 5, Chronist Lv. 3, Voidcaller Lv. 2 |
| Resonant | Primal Binder | Character Lv. 14, Resonant Lv. 6, Luminary Lv. 2, Voidcaller Lv. 2, freed any Primal Guardian |
| Luminary | Seraph | Character Lv. 12, Luminary Lv. 5, Resonant Lv. 2, Oathbound Lv. 3 |
| Skywarden | Drake Ascendant | Character Lv. 12, Skywarden Lv. 5, Warder Lv. 3, Arcanist Lv. 2 |
| Chronist | Time Sovereign | Character Lv. 13, Chronist Lv. 5, Arcanist Lv. 3, Resonant Lv. 2 |
| Oathbound | Aegis Vow | Character Lv. 13, Oathbound Lv. 5, Warder Lv. 3, Luminary Lv. 3 |
| Voidcaller | Abyssal Magister | Character Lv. 14, Voidcaller Lv. 5, Arcanist Lv. 3, Null Resonant Lv. 3 |
| Null Resonant | Eclipse Harbinger | Character Lv. 18, Null Resonant Lv. 6, Voidcaller Lv. 4, Resonant Lv. 4, freed Vaelthorn |

Examples:
- **Null Breaker** requires more than Warder grinding. It needs Warder Lv. 5, plus Skywarden and Oathbound cross-training.
- **Etherweaver** requires Arcanist mastery, but also Chronist timing knowledge and Voidcaller Ether-break training.
- **Eclipse Harbinger** is an endgame hybrid gated by Null Resonant, Voidcaller, Resonant, and story progress.

### 🧪 Items (Vaelthar-named)
- **Vitae Draught** — restore 200 HP
- **Resonance Phial** — restore 90 Ether
- **Ironcore Shard** — restore 90 Temper
- **Soul Ember** — revive KO'd ally at 60% HP
- **Null Bane** — cleanse all statuses

---

## File Structure

```
vaelthar-chronicles/
├── index.html
├── package.json
├── vite.config.js
├── docs/
│   └── systems/
│       └── character-progression.md
└── src/
    ├── main.jsx
    ├── App.jsx
    └── game/
        ├── VaeltharChronicles.jsx   ← current self-contained game component
        └── data/
            └── progression.js       ← character, armor, level, and job unlock data
```

---

## Enemy Waves

| Wave | Enemies | Notable |
|------|---------|---------|
| 1 | Null Drake | Intro wave, easy |
| 2 | Void Golem + Storm Imp | Dual enemies, armor test |
| 3 | **Ignareth [ENRAGED]** + Null Shade | First corrupted Guardian — Resonance Window available |
| 4 | **Nerevan + Sylvara + Luminarch** [corrupted] | Three Guardians, Resonance all three |
| 5 | **OMEGA NULL** | Final boss — regenerates Ether every action, strips armor aggressively |

---

## Lore

The **Null Conclave** excavated a pre-world ruin and found **Void Anchors** — shards of pure Null older than the elements. Driven into a Guardian's core, they corrupt its Ether from within. The Guardian feels only pain. It can't tell friend from foe.

You are a **Resonant** — one of the few whose Ether resonates with a Guardian's. Your job isn't to defeat them. It's to reach them through the corruption, shatter the Void Anchor, and bring them home.

**Omega Null** is not a Guardian. It is every Void Anchor ever planted, fused into a single weapon. It regenerates Ether because it *is* corrupted Ether, crystallized.
